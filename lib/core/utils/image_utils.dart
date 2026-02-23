// lib/core/utils/image_utils.dart
// ============================================================================
// IMAGE UTILITIES - Helper untuk upload & manage images
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  
  // =========================================================================
  // PICK IMAGE FROM GALLERY OR CAMERA
  // =========================================================================
  static Future<File?> pickImage({
    required ImageSource source,
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      
      if (pickedFile == null) return null;
      
      // ✅ REAL CONVERT HEIF/HEIC ke JPEG
      final String filePath = pickedFile.path.toLowerCase();
      if (filePath.endsWith('.heic') || filePath.endsWith('.heif')) {
        debugPrint('🔄 Converting HEIF/HEIC to JPEG (REAL CONVERSION)...');
        
        try {
          // Baca bytes
          final bytes = await File(pickedFile.path).readAsBytes();
          
          // Decode image (ini yang decode HEIF)
          final decodedImage = img.decodeImage(bytes);
          
          if (decodedImage == null) {
            debugPrint('❌ Failed to decode HEIF image');
            return File(pickedFile.path); // Fallback return original
          }
          
          // Encode ke JPEG
          final jpegBytes = img.encodeJpg(decodedImage, quality: 85);
          
          // Save ke temp file
          final tempDir = await getTemporaryDirectory();
          final jpegPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          final jpegFile = File(jpegPath);
          await jpegFile.writeAsBytes(jpegBytes);
          
          debugPrint('✅ REAL Converted to JPEG: $jpegPath');
          return jpegFile;
          
        } catch (e) {
          debugPrint('❌ Error converting HEIF: $e');
          return File(pickedFile.path); // Fallback
        }
      }
      
      return File(pickedFile.path);
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      return null;
    }
  }
  
  // =========================================================================
  // CROP IMAGE
  // =========================================================================
  static Future<File?> cropImage({
    required File imageFile,
    required BuildContext context,
  }) async {
    try {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: imageFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Sesuaikan Foto',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Sesuaikan Foto',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );
      
      if (croppedFile == null) return null;
      
      return File(croppedFile.path);
    } catch (e) {
      debugPrint('❌ Error cropping image: $e');
      return null;
    }
  }
  
  // =========================================================================
  // UPLOAD TO SUPABASE STORAGE
  // =========================================================================
  static Future<String?> uploadProfilePhoto({
    required File imageFile,
    required String userId,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ext = path.extension(imageFile.path);
      final fileName = 'profile_$userId\_$timestamp$ext';
      
      // Upload ke bucket 'avatars'
      await supabase.storage
          .from('avatars')
          .upload(
            fileName,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );
      
      // Get public URL
      final publicUrl = supabase.storage
          .from('avatars')
          .getPublicUrl(fileName);
      
      debugPrint('✅ Image uploaded: $publicUrl');
      return publicUrl;
      
    } catch (e) {
      debugPrint('❌ Error uploading image: $e');
      return null;
    }
  }
  
  // =========================================================================
  // DELETE FROM SUPABASE STORAGE
  // =========================================================================
  static Future<bool> deleteProfilePhoto({
    required String photoUrl,
  }) async {
    try {
      // Extract filename from URL
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      
      // URL format: .../storage/v1/object/public/avatars/filename
      // Kita ambil filename terakhir
      if (pathSegments.length < 2) return false;
      
      final fileName = pathSegments.last;
      
      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('avatars')
          .remove([fileName]);
      
      debugPrint('✅ Image deleted: $fileName');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error deleting image: $e');
      return false;
    }
  }
  
  // =========================================================================
  // UPDATE USER PROFILE PHOTO IN DATABASE
  // =========================================================================
  static Future<bool> updateUserProfilePhoto({
    required String userId,
    required String? photoUrl,
  }) async {
    try {
      final supabase = Supabase.instance.client;
      
      await supabase
          .from('users')
          .update({'foto_profil': photoUrl})
          .eq('id_user', userId);
      
      debugPrint('✅ Database updated: foto_profil = $photoUrl');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error updating database: $e');
      return false;
    }
  }
}