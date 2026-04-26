
// ---------------------------------------------------------------------------
// storage_service.dart
//
// Purpose: Handles all file upload/download operations with Supabase Storage.
// Enforces folder structure: {bucket}/{userId}/{filename}
// This ensures RLS storage policies work correctly.
//
// Responsibilities:
//   - Upload avatar images
//   - Upload service images (up to 5 per service)
//   - Upload portfolio images
//   - Delete images
//   - Generate public URLs
//
// ---------------------------------------------------------------------------

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide StorageException;
import '../core/errors/exceptions.dart';
import 'supabase_service.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  final _supabase = SupabaseService.instance;
  final _picker = ImagePicker();

  // Bucket names matching our SQL schema
  static const String _avatarBucket = 'avatars';
  static const String _serviceImageBucket = 'service-images';
  static const String _portfolioBucket = 'portfolio-images';

  // ── Image Picking ──────────────────────────────────────────────────────────

  /// Pick a single image from gallery or camera
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int imageQuality = 85,
  }) async {
    try {
      return await _picker.pickImage(
        source: source,
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
    } catch (e) {
      throw StorageException('Failed to pick image: $e');
    }
  }

  /// Pick multiple images from gallery (for service images)
  Future<List<XFile>> pickMultipleImages({
    int maxImages = 5,
    int imageQuality = 85,
  }) async {
    try {
      final images = await _picker.pickMultiImage(
        imageQuality: imageQuality,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      // Limit to maxImages
      return images.take(maxImages).toList();
    } catch (e) {
      throw StorageException('Failed to pick images: $e');
    }
  }

  // ── Upload Operations ──────────────────────────────────────────────────────

  /// Upload user avatar — returns public URL
  /// Path: avatars/{userId}/avatar.{ext}
  Future<String> uploadAvatar({
    required String userId,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      bucket: _avatarBucket,
      path: '$userId/avatar.${_getExtension(imageFile.name)}',
      imageFile: imageFile,
    );
  }

  /// Upload a single service image — returns public URL
  /// Path: service-images/{userId}/{serviceId}_{index}.{ext}
  Future<String> uploadServiceImage({
    required String userId,
    required String serviceId,
    required int index,
    required XFile imageFile,
  }) async {
    return _uploadFile(
      bucket: _serviceImageBucket,
      path: '$userId/${serviceId}_$index.${_getExtension(imageFile.name)}',
      imageFile: imageFile,
    );
  }

  /// Upload multiple service images — returns list of public URLs
  Future<List<String>> uploadServiceImages({
    required String userId,
    required String serviceId,
    required List<XFile> imageFiles,
  }) async {
    final urls = <String>[];
    for (int i = 0; i < imageFiles.length; i++) {
      final url = await uploadServiceImage(
        userId: userId,
        serviceId: serviceId,
        index: i,
        imageFile: imageFiles[i],
      );
      urls.add(url);
    }
    return urls;
  }

  /// Upload portfolio image — returns public URL
  /// Path: portfolio-images/{userId}/{timestamp}.{ext}
  Future<String> uploadPortfolioImage({
    required String userId,
    required XFile imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return _uploadFile(
      bucket: _portfolioBucket,
      path: '$userId/$timestamp.${_getExtension(imageFile.name)}',
      imageFile: imageFile,
    );
  }

  // ── Delete Operations ──────────────────────────────────────────────────────

  /// Delete a file by its public URL
  Future<void> deleteByUrl(String bucket, String publicUrl) async {
    try {
      // Extract path from public URL
      final uri = Uri.parse(publicUrl);
      final pathSegments = uri.pathSegments;
      // URL format: .../storage/v1/object/public/{bucket}/{path}
      final bucketIndex = pathSegments.indexOf(bucket);
      if (bucketIndex == -1) return;
      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      await _supabase.storage.from(bucket).remove([filePath]);
    } catch (e) {
      throw StorageException('Failed to delete file: $e');
    }
  }

  // ── Private Helpers ────────────────────────────────────────────────────────

  /// Core upload method — handles both web and mobile
  Future<String> _uploadFile({
    required String bucket,
    required String path,
    required XFile imageFile,
  }) async {
    try {
      late Uint8List bytes;
      bytes = await imageFile.readAsBytes();

      await _supabase.storage.from(bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          contentType: _getContentType(imageFile.name),
          upsert: true, // Overwrite if exists (for avatar updates)
        ),
      );

      return _supabase.storage.from(bucket).getPublicUrl(path);
    } on StorageException catch (e) {
      throw StorageException('Upload failed: ${e.message}');
    } catch (e) {
      throw StorageException('Upload failed: $e');
    }
  }

  String _getExtension(String filename) {
    final parts = filename.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'jpg';
  }

  String _getContentType(String filename) {
    final ext = _getExtension(filename);
    switch (ext) {
      case 'png':  return 'image/png';
      case 'webp': return 'image/webp';
      default:     return 'image/jpeg';
    }
  }
}
