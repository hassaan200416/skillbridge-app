// user_repository.dart
//
// Purpose: Data-layer contract and Supabase implementation for user profiles.
// Responsibilities:
//   - Fetch and update user profile records in the `profiles` table.
//   - Support admin operations: list users, toggle active state.
//   - Map exceptions to [Failure] sealed types.
//   - NEVER be called directly from widgets — use via providers.
// Dependencies:
//   - services/supabase_service.dart
//   - data/models/user_model.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';

abstract class UserRepository {
  Future<(UserModel?, Failure?)> getUserById(String id);

  Future<(UserModel?, Failure?)> updateProfile(UserModel user);

  Future<(List<UserModel>, Failure?)> getAllUsers({
    String? role,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  });

  Future<Failure?> setUserActiveState(String id, {required bool isActive});

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
