// ============================================================================
// PRODUCT_STORAGE_SERVICE.DART (NEW FILE - JANGAN TIMPA storage_service.dart!)
// Service untuk upload/delete FOTO PRODUK ke Supabase Storage
// Bucket: product-images (PUBLIC)
// ============================================================================

import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;

class ProductStorageService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _bucketName = 'product-images';

  // =========================================================================
  // UPLOAD FOTO PRODUK
  // =========================================================================
  
  /// Upload single foto produk
  /// Returns: Public URL jika berhasil, null jika gagal
  Future<String?> uploadProductPhoto({
    required File file,
    required String idUmkm,
    required String idProduk,
  }) async {
    try {
      print('📸 [PRODUCT_STORAGE] Uploading product photo...');
      print('📸 [PRODUCT_STORAGE] File: ${file.path}');

      // Generate unique filename dengan struktur folder: umkm/produk/timestamp.ext
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(file.path);
      final fileName = '$idUmkm/$idProduk/${timestamp}$extension';
      
      print('📸 [PRODUCT_STORAGE] Filename: $fileName');

      // Upload to Supabase Storage
      await _supabase.storage
          .from(_bucketName)
          .upload(
            fileName,
            file,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Get public URL
      final publicUrl = _supabase.storage
          .from(_bucketName)
          .getPublicUrl(fileName);

      print('✅ [PRODUCT_STORAGE] Upload success! URL: $publicUrl');
      return publicUrl;

    } catch (e, stackTrace) {
      print('❌ [PRODUCT_STORAGE] Upload error: $e');
      print('📚 [PRODUCT_STORAGE] Stack trace: $stackTrace');
      return null;
    }
  }

  /// Upload multiple foto produk (untuk add produk baru)
  /// Returns: List of public URLs
  Future<List<String>> uploadMultipleProductPhotos({
    required List<File> files,
    required String idUmkm,
    required String idProduk,
  }) async {
    List<String> uploadedUrls = [];

    print('📸 [PRODUCT_STORAGE] Uploading ${files.length} photos...');

    for (int i = 0; i < files.length; i++) {
      print('📸 [PRODUCT_STORAGE] Processing file ${i + 1}/${files.length}');
      
      final url = await uploadProductPhoto(
        file: files[i],
        idUmkm: idUmkm,
        idProduk: idProduk,
      );

      if (url != null) {
        uploadedUrls.add(url);
        print('✅ [PRODUCT_STORAGE] File ${i + 1} uploaded');
      } else {
        print('❌ [PRODUCT_STORAGE] File ${i + 1} failed');
      }
    }

    print('📸 [PRODUCT_STORAGE] Upload complete: ${uploadedUrls.length}/${files.length} success');
    return uploadedUrls;
  }

  // =========================================================================
  // DELETE FOTO PRODUK
  // =========================================================================

  /// Delete foto produk by URL
  Future<bool> deleteProductPhoto(String photoUrl) async {
    try {
      print('🗑️ [PRODUCT_STORAGE] Deleting photo: $photoUrl');

      // Extract path from URL
      // URL format: https://xxx.supabase.co/storage/v1/object/public/product-images/path/to/file.jpg
      // We need: path/to/file.jpg
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      final bucketIndex = pathSegments.indexOf(_bucketName);
      if (bucketIndex == -1 || bucketIndex == pathSegments.length - 1) {
        print('❌ [PRODUCT_STORAGE] Invalid URL format');
        return false;
      }

      final filePath = pathSegments.sublist(bucketIndex + 1).join('/');
      print('🗑️ [PRODUCT_STORAGE] File path: $filePath');

      // Delete from storage
      await _supabase.storage
          .from(_bucketName)
          .remove([filePath]);

      print('✅ [PRODUCT_STORAGE] Photo deleted');
      return true;

    } catch (e, stackTrace) {
      print('❌ [PRODUCT_STORAGE] Delete error: $e');
      print('📚 [PRODUCT_STORAGE] Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete multiple foto produk
  Future<void> deleteMultipleProductPhotos(List<String> photoUrls) async {
    print('🗑️ [PRODUCT_STORAGE] Deleting ${photoUrls.length} photos...');

    for (var url in photoUrls) {
      await deleteProductPhoto(url);
    }

    print('✅ [PRODUCT_STORAGE] Bulk delete complete');
  }

  /// Delete all photos in a product folder (untuk delete produk)
  Future<bool> deleteProductFolder({
    required String idUmkm,
    required String idProduk,
  }) async {
    try {
      print('🗑️ [PRODUCT_STORAGE] Deleting product folder: $idUmkm/$idProduk');

      // List all files in folder
      final files = await _supabase.storage
          .from(_bucketName)
          .list(path: '$idUmkm/$idProduk');

      if (files.isEmpty) {
        print('ℹ️ [PRODUCT_STORAGE] No files to delete');
        return true;
      }

      // Build file paths
      final filePaths = files
          .map((file) => '$idUmkm/$idProduk/${file.name}')
          .toList();

      print('🗑️ [PRODUCT_STORAGE] Deleting ${filePaths.length} files...');

      // Delete all files
      await _supabase.storage
          .from(_bucketName)
          .remove(filePaths);

      print('✅ [PRODUCT_STORAGE] Product folder deleted');
      return true;

    } catch (e, stackTrace) {
      print('❌ [PRODUCT_STORAGE] Delete folder error: $e');
      print('📚 [PRODUCT_STORAGE] Stack trace: $stackTrace');
      return false;
    }
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  /// Generate temporary ID untuk upload foto sebelum produk dibuat
  String generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Validate file size (max 5MB per foto)
  bool validateFileSize(File file) {
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    
    print('📸 [PRODUCT_STORAGE] File size: ${mb.toStringAsFixed(2)} MB');
    
    if (mb > 5) {
      print('❌ [PRODUCT_STORAGE] File too large (max 5MB)');
      return false;
    }
    
    return true;
  }

  /// Validate file type (only images)
  bool validateFileType(File file) {
    final extension = path.extension(file.path).toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    
    print('📸 [PRODUCT_STORAGE] File extension: $extension');
    
    if (!validExtensions.contains(extension)) {
      print('❌ [PRODUCT_STORAGE] Invalid file type (only jpg, jpeg, png, webp)');
      return false;
    }
    
    return true;
  }
}