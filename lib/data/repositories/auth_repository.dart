
// ---------------------------------------------------------------------------
// auth_repository.dart
//
// Purpose: Handles all authentication and user profile operations.
// Single source of truth for auth state in SkillBridge.
//
// Responsibilities:
//   - User registration with role selection
//   - Login, logout, session management
//   - Email verification state
//   - User profile CRUD
//   - Admin operations on users
//
// Architecture:
//   - Never throws exceptions — always returns Failure on error
//   - All Supabase calls go through SupabaseService
//   - Returns Either-style: throws Failure or returns value
//   - UI layer only sees UserModel and Failure, never raw Supabase types
//
// ---------------------------------------------------------------------------

import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthException, StorageException;
import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../services/supabase_service.dart';
import '../../services/storage_service.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _supabase = SupabaseService.instance;
  final _storage = StorageService.instance;

  // ── Registration ──────────────────────────────────────────────────────────

  /// Registers a new user with email, password, name, and role.
  ///
  /// Flow:
  ///   1. Create Supabase Auth user with metadata
  ///   2. Trigger handle_new_user() creates public.users row automatically
  ///   3. Return the created UserModel
  ///
  /// Throws [AuthFailure] on auth errors, [ServerFailure] on db errors.
  Future<UserModel> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role.value,
        },
      );

      if (response.user == null) {
        throw const AuthFailure('Registration failed. Please try again.');
      }

      // Wait for the handle_new_user trigger to create the profile row.
      // Retry up to 5 times with 500ms delay between attempts.
      UserModel? profile;
      for (int attempt = 0; attempt < 5; attempt++) {
        await Future.delayed(const Duration(milliseconds: 600));
        try {
          profile = await _getUserById(response.user!.id);
          break; // Success — exit retry loop
        } on NotFoundFailure {
          // Profile not created yet — retry
          if (attempt == 4) {
            // Last attempt failed — create profile manually as fallback
            await _createProfileManually(
              userId: response.user!.id,
              email: email,
              name: name,
              role: role,
            );
            profile = await _getUserById(response.user!.id);
          }
          continue;
        }
      }

      return profile!;
    } on AuthFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      throw ServerFailure('Registration failed: $e');
    }
  }

  /// Manual fallback profile creation if trigger fails
  Future<void> _createProfileManually({
    required String userId,
    required String email,
    required String name,
    required UserRole role,
  }) async {
    try {
      await _supabase.from('users').upsert({
        'id': userId,
        'email': email,
        'name': name,
        'role': role.value,
        'is_verified': false,
        'is_suspended': false,
        'is_profile_complete': false,
      });
    } catch (_) {
      // Ignore — will be caught by outer try-catch
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────

  /// Signs in with email and password.
  /// Throws [AuthFailure] if credentials are wrong or account is suspended.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw const AuthFailure('Login failed. Please check your credentials.');
      }

      final profile = await _getUserById(response.user!.id);

      // Check suspension at app level — RLS also blocks at DB level
      if (profile.isSuspended) {
        await logout();
        throw const PermissionFailure(
          'Your account has been suspended. Please contact support.',
        );
      }

      return profile;
    } on AuthFailure {
      rethrow;
    } on PermissionFailure {
      rethrow;
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      throw ServerFailure('Login failed: $e');
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  /// Signs out the current user and clears the session.
  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (_) {
      // Always succeed — local state is cleared regardless
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  /// Sends a password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } on AuthException catch (e) {
      throw AuthFailure(_mapAuthError(e.message));
    } catch (e) {
      throw ServerFailure('Failed to send reset email: $e');
    }
  }

  // ── Current User ──────────────────────────────────────────────────────────

  /// Returns the current user's profile from the database.
  /// Returns null if not logged in.
  Future<UserModel?> getCurrentUser() async {
    try {
      final userId = _supabase.currentUserId;
      if (userId == null) return null;
      return await _getUserById(userId);
    } catch (_) {
      return null;
    }
  }

  /// Stream of auth state changes — drives the auth provider.
  Stream<AuthState> get authStateChanges => _supabase.authStateChanges;

  // ── Profile Operations ────────────────────────────────────────────────────

  /// Updates the current user's profile.
  /// Handles avatar upload if a new image is provided.
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? city,
    String? bio,
    int? experienceYears,
    String? serviceArea,
    XFile? newAvatarImage,
  }) async {
    try {
      String? avatarUrl;

      // Upload new avatar if provided
      if (newAvatarImage != null) {
        avatarUrl = await _storage.uploadAvatar(
          userId: userId,
          imageFile: newAvatarImage,
        );
      }

      // Build update map — only include non-null fields
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (city != null) updates['city'] = city;
      if (bio != null) updates['bio'] = bio;
      if (experienceYears != null) updates['experience_years'] = experienceYears;
      if (serviceArea != null) updates['service_area'] = serviceArea;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      // Mark profile as complete if required fields are present
      if (name != null && name.isNotEmpty) {
        updates['is_profile_complete'] = true;
      }

      await _supabase.from('users').update(updates).eq('id', userId);

      return await _getUserById(userId);
    } on PermissionFailure {
      rethrow;
    } catch (e) {
      throw ServerFailure('Failed to update profile: $e');
    }
  }

  /// Adds a portfolio image URL to the provider's portfolio_urls array
  Future<UserModel> addPortfolioImage({
    required String userId,
    required String imageUrl,
  }) async {
    try {
      // Use Postgres array append
      await _supabase.client.rpc('append_portfolio_url', params: {
        'user_id': userId,
        'url': imageUrl,
      });
      return await _getUserById(userId);
    } catch (e) {
      // Fallback: fetch current urls and append manually
      final user = await _getUserById(userId);
      final updatedUrls = [...user.portfolioUrls, imageUrl];
      await _supabase.from('users')
          .update({'portfolio_urls': updatedUrls})
          .eq('id', userId);
      return await _getUserById(userId);
    }
  }

  // ── Admin Operations ──────────────────────────────────────────────────────

  /// Admin: suspend or unsuspend a user account
  Future<UserModel> setUserSuspension({
    required String targetUserId,
    required bool suspend,
    String? reason,
  }) async {
    try {
      await _supabase.from('users').update({
        'is_suspended': suspend,
        'suspension_reason': suspend ? reason : null,
        'suspended_at': suspend ? DateTime.now().toIso8601String() : null,
      }).eq('id', targetUserId);

      return await _getUserById(targetUserId);
    } catch (e) {
      throw ServerFailure('Failed to update suspension: $e');
    }
  }

  /// Admin: grant or revoke verified badge
  Future<UserModel> setVerifiedStatus({
    required String targetUserId,
    required bool isVerified,
  }) async {
    try {
      await _supabase.from('users')
          .update({'is_verified': isVerified})
          .eq('id', targetUserId);
      return await _getUserById(targetUserId);
    } catch (e) {
      throw ServerFailure('Failed to update verified status: $e');
    }
  }

  /// Admin: change a user's role
  Future<UserModel> setUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async {
    try {
      await _supabase.from('users')
          .update({'role': newRole.value})
          .eq('id', targetUserId);
      return await _getUserById(targetUserId);
    } catch (e) {
      throw ServerFailure('Failed to update role: $e');
    }
  }

  /// Get all users — admin only (RLS enforces this)
  Future<List<UserModel>> getAllUsers({
    String? searchQuery,
    UserRole? roleFilter,
    bool? suspendedFilter,
    int page = 0,
    int pageSize = 20,
  }) async {
    try {
      var query = _supabase.from('users')
          .select()
          .order('created_at', ascending: false)
          .range(page * pageSize, (page + 1) * pageSize - 1);

      final data = await query as List<dynamic>;
      return data
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .where((user) {
            if (searchQuery != null && searchQuery.isNotEmpty) {
              final q = searchQuery.toLowerCase();
              if (!user.name.toLowerCase().contains(q) &&
                  !user.email.toLowerCase().contains(q)) {
                return false;
              }
            }
            if (roleFilter != null && user.role != roleFilter) return false;
            if (suspendedFilter != null && user.isSuspended != suspendedFilter) {
              return false;
            }
            return true;
          })
          .toList();
    } catch (e) {
      throw ServerFailure('Failed to fetch users: $e');
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Fetches a user profile by ID from public.users
  Future<UserModel> _getUserById(String userId) async {
    try {
      final data = await _supabase.from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(Map<String, dynamic>.from(data));
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw const NotFoundFailure('User profile not found.');
      }
      throw ServerFailure('Failed to fetch user: ${e.message}');
    } catch (e) {
      throw ServerFailure('Failed to fetch user: $e');
    }
  }

  /// Maps Supabase auth error messages to user-friendly strings
  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Incorrect email or password.';
    }
    if (lower.contains('email already registered') ||
        lower.contains('already been registered')) {
      return 'This email is already registered. Please login instead.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email before logging in.';
    }
    if (lower.contains('too many requests')) {
      return 'Too many attempts. Please wait a few minutes and try again.';
    }
    if (lower.contains('password should be')) {
      return 'Password must be at least 6 characters.';
    }
    return message;
  }
}
