import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/constants.dart';

/// Service for handling Supabase Storage operations
/// 
/// This service manages image uploads, downloads, and deletions
/// from the Supabase storage bucket. All operations are performed
/// on the 'item_images' bucket (configurable in constants.dart).
/// 
/// Usage:
/// - Upload: await SupabaseStorageService.instance.uploadImage(file, remotePath)
/// - Get URL: SupabaseStorageService.instance.getPublicUrl(path)
/// - Delete: await SupabaseStorageService.instance.deleteImage(path)
class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  static SupabaseStorageService get instance => _instance;
  
  SupabaseStorageService._internal();

  /// Get the Supabase storage client
  SupabaseStorageClient get _storage => Supabase.instance.client.storage;

  /// Upload an image file to Supabase Storage
  /// 
  /// [file] - The image file to upload
  /// [remotePath] - The path where the file will be stored in the bucket
  ///                Example: "images/user123/item456.jpg"
  /// 
  /// Returns the public URL of the uploaded file
  /// 
  /// Throws [StorageException] if upload fails
  /// Throws [FileSystemException] if file doesn't exist or can't be read
  Future<String> uploadImage(File file, String remotePath) async {
    try {
      // Validate file exists
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', file.path);
      }

      // Validate file size (optional - add size check if needed)
      final fileSize = await file.length();
      final maxSizeBytes = maxImageSizeMb * 1024 * 1024;
      if (fileSize > maxSizeBytes) {
        throw Exception('File size exceeds ${maxImageSizeMb}MB limit');
      }

      // Validate file extension
      final extension = getFileExtension(file.path);
      if (!allowedImageExtensions.contains(extension)) {
        throw Exception('Unsupported file type. Allowed: ${allowedImageExtensions.join(', ')}');
      }

      // Upload file to Supabase Storage
      // TODO: Change supabaseStorageBucket if you want a different bucket name
      await _storage.from(supabaseStorageBucket).upload(
        remotePath,
        file,
        fileOptions: const FileOptions(
          cacheControl: '3600', // Cache for 1 hour
          upsert: true, // Overwrite if file exists
        ),
      );

      // Get and return the public URL
      final publicUrl = getPublicUrl(remotePath);
      return publicUrl;

    } on StorageException catch (e) {
      // Handle Supabase storage specific errors
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      // Handle other errors (file system, network, etc.)
      throw Exception('Upload failed: $e');
    }
  }

  /// Get the public URL for a file in the storage bucket
  /// 
  /// [path] - The path of the file in the bucket
  /// 
  /// Returns the public URL string
  /// 
  /// Note: This works for public buckets. If your bucket is private,
  /// use createSignedUrl() instead for temporary access URLs.
  String getPublicUrl(String path) {
    try {
      // TODO: If your bucket is private, use this instead:
      // return await _storage.from(SUPABASE_STORAGE_BUCKET).createSignedUrl(path, 3600);
      
      return _storage.from(supabaseStorageBucket).getPublicUrl(path);
    } catch (e) {
      throw Exception('Failed to get public URL: $e');
    }
  }

  /// Create a signed URL for private bucket access (alternative to getPublicUrl)
  /// 
  /// [path] - The path of the file in the bucket
  /// [expiresIn] - URL expiration time in seconds (default: 1 hour)
  /// 
  /// Returns a signed URL that expires after the specified time
  Future<String> createSignedUrl(String path, {int expiresIn = 3600}) async {
    try {
      return await _storage.from(supabaseStorageBucket).createSignedUrl(path, expiresIn);
    } on StorageException catch (e) {
      throw Exception('Failed to create signed URL: ${e.message}');
    }
  }

  /// Delete an image from the storage bucket
  /// 
  /// [path] - The path of the file to delete
  /// 
  /// Throws [StorageException] if deletion fails
  Future<void> deleteImage(String path) async {
    try {
      await _storage.from(supabaseStorageBucket).remove([path]);
    } on StorageException catch (e) {
      throw Exception('Failed to delete image: ${e.message}');
    } catch (e) {
      throw Exception('Delete operation failed: $e');
    }
  }

  /// List files in a directory (useful for debugging or admin features)
  /// 
  /// [path] - The directory path to list (optional, defaults to root)
  /// 
  /// Returns a list of file objects
  Future<List<FileObject>> listFiles({String? path}) async {
    try {
      return await _storage.from(supabaseStorageBucket).list(path: path);
    } on StorageException catch (e) {
      throw Exception('Failed to list files: ${e.message}');
    }
  }

  /// Check if a file exists in the storage bucket
  /// 
  /// [path] - The path of the file to check
  /// 
  /// Returns true if file exists, false otherwise
  Future<bool> fileExists(String path) async {
    try {
      final files = await listFiles(path: path.split('/').sublist(0, path.split('/').length - 1).join('/'));
      final fileName = path.split('/').last;
      return files.any((file) => file.name == fileName);
    } catch (e) {
      return false;
    }
  }
}