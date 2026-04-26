// ---------------------------------------------------------------------------
// failures.dart
//
// Purpose: Sealed Failure class hierarchy for consistent error handling.
// Every repository method returns either a success value or a Failure.
// Never throw exceptions from repositories — always return Failure.
//
// Usage:
//   final result = await authRepository.login(email, password);
//   result.fold(
//     (failure) => showError(failure.message),
//     (user) => navigateToDashboard(user),
//   );
//
// ---------------------------------------------------------------------------

/// Base sealed class for all application failures.
sealed class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Authentication failures — login, register, session expired
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Network failures — no internet, timeout
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}

/// Server failures — 500 errors, unexpected server responses
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Validation failures — invalid input before sending to server
class ValidationFailure extends Failure {
  final String field;
  const ValidationFailure(super.message, {required this.field});
}

/// Storage failures — file upload/download errors
class StorageFailure extends Failure {
  const StorageFailure(super.message);
}

/// Not found failures — requested resource does not exist
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// Permission failures — RLS policy blocked, suspended account
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Cache failures — local storage read/write errors
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}
