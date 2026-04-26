// storage_repository.dart
//
// Purpose: Data-layer contract and Supabase implementation for file storage.
// Responsibilities:
//   - Upload, retrieve, and delete files in Supabase Storage buckets.
//   - Handle avatar uploads (profiles bucket) and service images (services bucket).
//   - Return public URLs after successful uploads.
//   - Map exceptions to [StorageFailure].
// Dependencies:
//   - services/storage_service.dart
//   - core/errors/failures.dart

import '../../core/errors/failures.dart';

abstract class StorageRepository {
  /// Uploads [bytes] to [bucket]/[path] and returns the public URL.
  Future<(String?, Failure?)> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  });

  /// Deletes the file at [bucket]/[path].
  Future<Failure?> deleteFile({
    required String bucket,
    required String path,
  });

  /// Returns the public URL for a stored file.
  String getPublicUrl({required String bucket, required String path});
}

class SupabaseStorageRepository implements StorageRepository {
  const SupabaseStorageRepository();

  @override
  Future<(String?, Failure?)> uploadFile({
    required String bucket,
    required String path,
    required List<int> bytes,
    String contentType = 'image/jpeg',
  }) async {
    // Placeholder: wire through StorageService implementation.
    throw UnimplementedError();
  }

  @override
  Future<Failure?> deleteFile({
    required String bucket,
    required String path,
  }) async {
    // Placeholder: wire through StorageService implementation.
    throw UnimplementedError();
  }

  @override
  String getPublicUrl({required String bucket, required String path}) {
    // Placeholder: wire through StorageService implementation.
    throw UnimplementedError();
  }
}
