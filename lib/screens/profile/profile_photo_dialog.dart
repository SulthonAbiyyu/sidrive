// lib/screens/page/profile_photo_dialog.dart
// ============================================================================
// PROFILE PHOTO DIALOG - Dialog untuk edit/hapus foto profile
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/core/utils/image_utils.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/providers/auth_provider.dart';

class ProfilePhotoDialog {
  // =========================================================================
  // SHOW FULL PHOTO (PERBESAR)
  // =========================================================================
  static void showFullPhoto({
    required BuildContext context,
    required String photoUrl,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
        child: Stack(
          children: [
            // Foto (tap untuk tutup)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(ResponsiveMobile.scaledW(40)),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade800,
                            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image,
                                size: ResponsiveMobile.scaledFont(60),
                                color: Colors.white54,
                              ),
                              SizedBox(height: ResponsiveMobile.scaledH(12)),
                              Text(
                                'Gagal memuat foto',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: ResponsiveMobile.scaledFont(14),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            
            // Tombol close
            Positioned(
              top: ResponsiveMobile.scaledH(10),
              right: ResponsiveMobile.scaledW(10),
              child: Material(
                color: Colors.black54,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: EdgeInsets.all(ResponsiveMobile.scaledW(8)),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: ResponsiveMobile.scaledFont(24),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // =========================================================================
  // SHOW EDIT/DELETE OPTIONS
  // =========================================================================
  static void showPhotoOptions({
    required BuildContext context,
    required bool hasPhoto,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ResponsiveMobile.scaledR(24)),
            topRight: Radius.circular(ResponsiveMobile.scaledR(24)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: EdgeInsets.only(top: ResponsiveMobile.scaledH(12)),
                width: ResponsiveMobile.scaledW(40),
                height: ResponsiveMobile.scaledH(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(2)),
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              // Title
              Text(
                'Foto Profile',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              // Options
              if (hasPhoto) ...[
                _buildOption(
                  context: context,
                  icon: Icons.edit,
                  title: 'Ubah Foto',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showImageSourceDialog(context);
                  },
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                _buildOption(
                  context: context,
                  icon: Icons.delete_outline,
                  title: 'Hapus Foto',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDeletePhoto(context);
                  },
                ),
              ] else ...[
                _buildOption(
                  context: context,
                  icon: Icons.add_a_photo,
                  title: 'Tambah Foto',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _showImageSourceDialog(context);
                  },
                ),
              ],
              
              SizedBox(height: ResponsiveMobile.scaledH(8)),
              
              // Cancel button
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // =========================================================================
  // BUILD OPTION ITEM
  // =========================================================================
  static Widget _buildOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveMobile.scaledW(20),
            vertical: ResponsiveMobile.scaledH(16),
          ),
          child: Row(
            children: [
              Container(
                width: ResponsiveMobile.scaledW(44),
                height: ResponsiveMobile.scaledW(44),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveMobile.scaledFont(22),
                ),
              ),
              SizedBox(width: ResponsiveMobile.scaledW(16)),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(16),
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: ResponsiveMobile.scaledFont(20),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // =========================================================================
  // SHOW IMAGE SOURCE DIALOG (Camera or Gallery)
  // =========================================================================
  static void _showImageSourceDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(ResponsiveMobile.scaledR(24)),
            topRight: Radius.circular(ResponsiveMobile.scaledR(24)),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: ResponsiveMobile.scaledH(12)),
                width: ResponsiveMobile.scaledW(40),
                height: ResponsiveMobile.scaledH(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(2)),
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              _buildOption(
                context: context,
                icon: Icons.camera_alt,
                title: 'Kamera',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(context, ImageSource.camera);
                },
              ),
              
              Divider(height: 1, color: Colors.grey.shade200),
              
              _buildOption(
                context: context,
                icon: Icons.photo_library,
                title: 'Galeri',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _pickAndUploadImage(context, ImageSource.gallery);
                },
              ),
              
              SizedBox(height: ResponsiveMobile.scaledH(8)),
              
              Container(
                width: double.infinity,
                margin: EdgeInsets.all(ResponsiveMobile.scaledW(16)),
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(14),
                    ),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                  ),
                  child: Text(
                    'Batal',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(15),
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // =========================================================================
  // PICK AND UPLOAD IMAGE
  // =========================================================================
  static Future<void> _pickAndUploadImage(
    BuildContext context,
    ImageSource source,
  ) async {
    BuildContext? dialogContext;
    
    
    // 🔥 SAVE AUTHPROVIDER EARLY - before any async!
    final authProvider = context.read<AuthProvider>();

    try {
      print('📸 Step 1: Picking image from $source');
      
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx;
          return WillPopScope(
            onWillPop: () async => false,
            child: Center(
              child: Container(
                padding: EdgeInsets.all(ResponsiveMobile.scaledW(20)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: ResponsiveMobile.scaledH(16)),
                    Text(
                      'Memproses foto...',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(14),
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
      
      // Pick image
      final File? pickedFile = await ImageUtils.pickImage(source: source);
      
      print('📸 Step 2: Image picked - ${pickedFile != null ? 'SUCCESS' : 'CANCELLED'}');
      
      // ✅ Close loading dengan dialogContext
      if (dialogContext != null && Navigator.canPop(dialogContext!)) {
        Navigator.pop(dialogContext!);
        dialogContext = null;
      }
      
      // User cancelled
      if (pickedFile == null) {
        print('⚠️ User cancelled image picking');
        return;
      }
      
      // ✅ Delay singkat biar UI settle
      await Future.delayed(const Duration(milliseconds: 200));
      
      
      print('📸 Step 3: Opening crop dialog');
      
      // Crop image
      final File? croppedFile = await ImageUtils.cropImage(
        imageFile: pickedFile,
        context: context,
      );
      
      print('📸 Step 4: Image cropped - ${croppedFile != null ? 'SUCCESS' : 'CANCELLED'}');
      
      // User cancelled crop
      if (croppedFile == null) {
        print('⚠️ User cancelled cropping');
        return;
      }
      
      // ✅ Delay lagi setelah crop
      await Future.delayed(const Duration(milliseconds: 200));
      
      print('📸 Step 5: Starting upload directly');

      
      print('📸 Step 6: Getting user ID');
      
      final userId = authProvider.currentUser?.idUser;
      
      if (userId == null) {
        print('❌ User ID is null');
        return;
      }
      
      print('📸 Step 7: Deleting old photo');
      
      // Delete old photo if exists
      final oldPhotoUrl = authProvider.currentUser?.fotoProfil;
      if (oldPhotoUrl != null && oldPhotoUrl.isNotEmpty) {
        await ImageUtils.deleteProfilePhoto(photoUrl: oldPhotoUrl);
        print('✅ Old photo deleted');
      }
      
      print('📸 Step 8: Uploading new photo');
      
      // Upload new photo
      final String? photoUrl = await ImageUtils.uploadProfilePhoto(
        imageFile: croppedFile,
        userId: userId,
      );
      
      if (photoUrl == null) {
        print('⚠️ Upload failed - context invalid');
        return;
      }
      
      print('📸 Step 9: Updating profile');
      
      // Update provider
      final success = await authProvider.updateProfilePhoto(photoUrl);
      // Show result
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success 
                ? '✅ Foto profile berhasil diperbarui' 
                : 'Gagal memperbarui foto profile'
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
      
    } catch (e, stackTrace) {
      print('❌ ========== ERROR ==========');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==============================');
      
      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
  
  // =========================================================================
  // CONFIRM DELETE PHOTO
  // =========================================================================
  static void _confirmDeletePhoto(BuildContext context) {
    // 🔥 SAVE AUTHPROVIDER EARLY
    final authProvider = context.read<AuthProvider>();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: ResponsiveMobile.scaledFont(28),
            ),
            SizedBox(width: ResponsiveMobile.scaledW(12)),
            Text(
              'Hapus Foto?',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(18),
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus foto profile?',
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(15),
            color: Colors.grey.shade700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Batal',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(15),
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deletePhoto(context, authProvider);
              await Future.delayed(const Duration(milliseconds: 300));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
              ),
            ),
            child: Text(
              'Hapus',
              style: TextStyle(
                fontSize: ResponsiveMobile.scaledFont(15),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // =========================================================================
  // DELETE PHOTO
  // =========================================================================
  static Future<void> _deletePhoto(
    BuildContext context,
    AuthProvider authProvider,
  ) async {
    try {
      print('🗑️ DELETE: Starting delete photo');
      
      final success = await authProvider.deleteProfilePhoto();
      print('🗑️ DELETE: About to call authProvider.deleteProfilePhoto...');
      try {
      } catch (e, st) {
        print('❌ DELETE CRASHED: $e');
        print('❌ STACK: $st');
        if (context.mounted) Navigator.pop(context);
        return;
      }

      print('🗑️ DELETE: Result = $success');

      
      if (context.mounted) {
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Foto profile berhasil dihapus'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menghapus foto profile'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}