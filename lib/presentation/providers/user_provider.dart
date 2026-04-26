
// ---------------------------------------------------------------------------
// user_provider.dart
//
// Purpose: Providers for viewing other users' profiles.
// Separate from auth_provider which manages the current logged-in user.
//
// ---------------------------------------------------------------------------

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../core/errors/failures.dart';

/// Fetch any user profile by ID — used for provider profile screen
final userProfileProvider =
    FutureProvider.family<UserModel, String>((ref, userId) async {
  final users = await AuthRepository.instance.getAllUsers();
  final user = users.where((u) => u.id == userId).firstOrNull;
  if (user == null) throw const NotFoundFailure('User not found.');
  return user;
});

/// All users — admin only (RLS enforces this)
final allUsersProvider = FutureProvider<List<UserModel>>((ref) {
  return AuthRepository.instance.getAllUsers();
});

/// Admin actions on users
class AdminUserNotifier extends StateNotifier<bool> {
  AdminUserNotifier(this._ref) : super(false);

  final Ref _ref;
  final _repo = AuthRepository.instance;

  Future<bool> setUserSuspension({
    required String targetUserId,
    required bool suspend,
    String? reason,
  }) async {
    try {
      state = true;
      await _repo.setUserSuspension(
        targetUserId: targetUserId,
        suspend: suspend,
        reason: reason,
      );
      _ref.invalidate(allUsersProvider);
      state = false;
      return true;
    } on Failure {
      state = false;
      return false;
    }
  }

  Future<bool> setVerifiedStatus({
    required String targetUserId,
    required bool isVerified,
  }) async {
    try {
      state = true;
      await _repo.setVerifiedStatus(
        targetUserId: targetUserId,
        isVerified: isVerified,
      );
      _ref.invalidate(allUsersProvider);
      state = false;
      return true;
    } on Failure {
      state = false;
      return false;
    }
  }

  Future<bool> setUserRole({
    required String targetUserId,
    required UserRole newRole,
  }) async {
    try {
      state = true;
      await _repo.setUserRole(
        targetUserId: targetUserId,
        newRole: newRole,
      );
      _ref.invalidate(allUsersProvider);
      state = false;
      return true;
    } on Failure {
      state = false;
      return false;
    }
  }
}

final adminUserProvider =
    StateNotifierProvider<AdminUserNotifier, bool>((ref) {
  return AdminUserNotifier(ref);
});
