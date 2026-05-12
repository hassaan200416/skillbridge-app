// User repository contract and placeholder Supabase implementation.
// This file defines the user profile data operations used by the app and the
// admin tools. The current class is still a stub, so the methods describe the
// intended data flow but do not yet implement the database calls.
//
// Once completed, this layer should handle profile reads and updates, user
// listing, provider filtering, and toggling active state without widgets
// talking to Supabase directly.

import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';

abstract class UserRepository {
  /// Loads one user profile by ID.
  Future<(UserModel?, Failure?)> getUserById(String id);

  /// Saves updates to one user profile.
  Future<(UserModel?, Failure?)> updateProfile(UserModel user);

  /// Loads users for admin lists and search screens.
  Future<(List<UserModel>, Failure?)> getAllUsers({
    String? role,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  });

  /// Enables or disables a user account.
  Future<Failure?> setUserActiveState(String id, {required bool isActive});

  /// Loads providers, optionally narrowed by city.
  Future<(List<UserModel>, Failure?)> getProviders({String? city});
}

class SupabaseUserRepository implements UserRepository {
  const SupabaseUserRepository();

  @override
  Future<(UserModel?, Failure?)> getUserById(String id) async {
    // Placeholder: repository implementation pending.
    throw UnimplementedError();
  }

  @override
  Future<(UserModel?, Failure?)> updateProfile(UserModel user) async {
    // Placeholder: repository implementation pending.
    throw UnimplementedError();
  }

  @override
  Future<(List<UserModel>, Failure?)> getAllUsers({
    String? role,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    // Placeholder: repository implementation pending.
    throw UnimplementedError();
  }

  @override
  Future<Failure?> setUserActiveState(String id,
      {required bool isActive}) async {
    // Placeholder: repository implementation pending.
    throw UnimplementedError();
  }

  @override
  Future<(List<UserModel>, Failure?)> getProviders({String? city}) async {
    // Placeholder: repository implementation pending.
    throw UnimplementedError();
  }
}
