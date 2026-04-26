// ---------------------------------------------------------------------------
// exceptions.dart
//
// Purpose: Exception classes thrown internally by services/repositories.
// These are caught and converted to Failure objects before reaching the UI.
// The UI layer never sees raw exceptions — only Failure objects.
//
// ---------------------------------------------------------------------------

/// Base application exception
class AppException implements Exception {
  final String message;
  final String? code;
  const AppException(this.message, {this.code});

  @override
  String toString() => 'AppException($code): $message';
}

/// Thrown when Supabase Auth operations fail
class AuthException extends AppException {
  const AuthException(super.message, {super.code});
}

/// Thrown when network is unavailable
class NetworkException extends AppException {
  const NetworkException([super.message = 'No internet connection'])
      : super(code: 'NETWORK_ERROR');
}

/// Thrown when server returns an error
class ServerException extends AppException {
  const ServerException(super.message, {super.code});
}

/// Thrown when file operations fail
class StorageException extends AppException {
  const StorageException(super.message, {super.code});
}

/// Thrown when a requested resource is not found
class NotFoundException extends AppException {
  const NotFoundException(super.message)
      : super(code: 'NOT_FOUND');
}

/// Thrown when RLS blocks an operation or account is suspended
class PermissionException extends AppException {
  const PermissionException(super.message)
      : super(code: 'PERMISSION_DENIED');
}
