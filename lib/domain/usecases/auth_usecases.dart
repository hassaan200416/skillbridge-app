
// auth_usecases.dart
//
// Purpose: Domain-layer use-cases encapsulating all authentication business logic.
// Responsibilities:
//   - Orchestrate calls to [AuthRepository] with pre/post-condition guards.
//   - Enforce business rules (e.g. email must be verified before profile setup).
//   - Return typed results — never throw exceptions to callers.
//   - Remain framework-agnostic (no Flutter or Riverpod imports).
// Dependencies:
//   - data/repositories/auth_repository.dart
//   - data/models/user_model.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase();

  Future<(UserModel?, Failure?)> call({
    required String email,
    required String password,
    required String fullName,
    UserRole role = UserRole.customer,
  }) async {
    try {
      final user = await AuthRepository.instance.register(
        email: email,
        password: password,
        name: fullName,
        role: role,
      );
      return (user, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class SignInUseCase {
  const SignInUseCase();

  Future<(UserModel?, Failure?)> call({
    required String email,
    required String password,
  }) async {
    try {
      final user = await AuthRepository.instance.login(
        email: email,
        password: password,
      );
      return (user, null);
    } on Failure catch (e) {
      return (null, e);
    }
  }
}

class SignOutUseCase {
  const SignOutUseCase();

  Future<Failure?> call() async {
    try {
      await AuthRepository.instance.logout();
      return null;
    } on Failure catch (e) {
      return e;
    }
  }
}

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase();

  Future<(UserModel?, Failure?)> call() async {
    final user = await AuthRepository.instance.getCurrentUser();
    return (user, null);
  }
}

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase();

  Future<Failure?> call(String email) async {
    try {
      await AuthRepository.instance.sendPasswordResetEmail(email);
      return null;
    } on Failure catch (e) {
      return e;
    }
  }
}
