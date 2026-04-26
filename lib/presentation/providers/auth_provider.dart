
// ---------------------------------------------------------------------------
// auth_provider.dart
//
// Purpose: Riverpod state management for authentication.
// Drives all auth-related UI: login, register, profile, role-based routing.
//
// Key providers:
//   - authStateProvider: stream of Supabase auth events
//   - currentUserProvider: current logged-in UserModel
//   - authNotifierProvider: actions (login, register, logout)
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/notification_model.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../core/errors/failures.dart';
import 'service_provider.dart';

// ── Auth State Stream ─────────────────────────────────────────────────────

/// Streams Supabase auth events (signIn, signOut, tokenRefreshed).
/// Used by go_router redirect to react to auth changes.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return AuthRepository.instance.authStateChanges;
});

// ── Current User ──────────────────────────────────────────────────────────

/// Holds the currently authenticated user's profile.
/// Null when logged out. Automatically refreshes on auth state change.
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

/// FutureProvider that loads the current user from the database.
/// Called once after successful login or on app startup.
final loadCurrentUserProvider = FutureProvider<UserModel?>((ref) async {
  return await AuthRepository.instance.getCurrentUser();
});

// ── Auth Actions ──────────────────────────────────────────────────────────

/// State class for auth operation results
class AuthState2 {
  final bool isLoading;
  final Failure? error;
  final UserModel? user;
  final bool isSuccess;

  const AuthState2({
    this.isLoading = false,
    this.error,
    this.user,
    this.isSuccess = false,
  });

  AuthState2 copyWith({
    bool? isLoading,
    Failure? error,
    UserModel? user,
    bool? isSuccess,
  }) {
    return AuthState2(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      user: user ?? this.user,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState2> {
  AuthNotifier(this._ref) : super(const AuthState2());

  final Ref _ref;
  final _repo = AuthRepository.instance;

  /// Registers a new user
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    state = const AuthState2(isLoading: true);
    try {
      final user = await _repo.register(
        email: email,
        password: password,
        name: name,
        role: role,
      );
      _ref.read(currentUserProvider.notifier).state = user;
      state = AuthState2(isSuccess: true, user: user);
      return true;
    } on Failure catch (f) {
      state = AuthState2(error: f);
      return false;
    } catch (e) {
      state = AuthState2(error: ServerFailure(e.toString()));
      return false;
    }
  }

  /// Logs in an existing user
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState2(isLoading: true);
    try {
      final user = await _repo.login(
          email: email, password: password);

      // Clear stale state from any previous session
      _ref.read(currentUserProvider.notifier).state = null;

      // Invalidate all cached provider data
      _ref.invalidate(featuredServicesProvider);
      _ref.invalidate(recentServicesProvider);

      // Set fresh user
      _ref.read(currentUserProvider.notifier).state = user;
      state = AuthState2(isSuccess: true, user: user);
      return true;
    } on Failure catch (f) {
      state = AuthState2(error: f);
      return false;
    } catch (e) {
      state = AuthState2(error: ServerFailure(e.toString()));
      return false;
    }
  }

  /// Logs out the current user
  Future<void> logout() async {
    await _repo.logout();
    // Clear user state completely on logout
    _ref.read(currentUserProvider.notifier).state = null;
    // Reset auth state
    state = const AuthState2();
  }

  /// Updates profile and refreshes currentUserProvider
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? city,
    String? bio,
    int? experienceYears,
    String? serviceArea,
    XFile? newAvatarImage,
  }) async {
    state = const AuthState2(isLoading: true);
    try {
      final user = await _repo.updateProfile(
        userId: userId,
        name: name,
        phone: phone,
        city: city,
        bio: bio,
        experienceYears: experienceYears,
        serviceArea: serviceArea,
        newAvatarImage: newAvatarImage,
      );
      _ref.read(currentUserProvider.notifier).state = user;
      state = AuthState2(isSuccess: true, user: user);

      // Self-notification (no DB enum for "general" — use platform announcement)
      try {
        await NotificationRepository.instance.createNotification(
          userId: userId,
          type: NotificationType.platformAnnouncement,
          title: 'Profile updated',
          body: 'Your profile has been updated successfully.',
        );
      } catch (_) {
        // Non-critical if RLS or network fails
      }

      return true;
    } on Failure catch (f) {
      state = AuthState2(error: f);
      return false;
    } catch (e) {
      state = AuthState2(error: ServerFailure(e.toString()));
      return false;
    }
  }

  /// Sends password reset email
  Future<bool> sendPasswordReset(String email) async {
    state = const AuthState2(isLoading: true);
    try {
      await _repo.sendPasswordResetEmail(email);
      state = const AuthState2(isSuccess: true);
      return true;
    } on Failure catch (f) {
      state = AuthState2(error: f);
      return false;
    } catch (e) {
      state = AuthState2(error: ServerFailure(e.toString()));
      return false;
    }
  }

  void clearError() {
    if (state.error != null || state.isLoading) {
      state = const AuthState2();
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState2>((ref) {
  return AuthNotifier(ref);
});
