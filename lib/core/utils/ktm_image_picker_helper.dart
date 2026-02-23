// ============================================================================
// KTM_IMAGE_PICKER_HELPER.DART - NO CROP VERSION
// Static helper untuk pick KTM image (TANPA CROP - PASTI BERHASIL!)
// ✅ FIX: Hapus loading dialog sebelum kamera → tidak crash lagi
// ============================================================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sidrive/core/utils/image_utils.dart';

class KtmImagePickerHelper {
  // =========================================================================
  // SHOW IMAGE SOURCE DIALOG (Camera or Gallery)
  // =========================================================================
  static void showImageSourceDialog({
    required BuildContext context,
    required Function(File) onImageSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 20),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                const Text(
                  'Ambil Foto KTM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pilih sumber foto untuk KTM kamu',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 24),

                // Camera & Gallery side by side
                Row(
                  children: [
                    // ── Kamera ──
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(context, ImageSource.camera, onImageSelected);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F9FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF5DADE2).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 36,
                                color: Color(0xFF5DADE2),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Foto Langsung',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1D4ED8),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Gunakan kamera',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ── Galeri ──
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          _pickImage(context, ImageSource.gallery, onImageSelected);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFF10B981).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_library_rounded,
                                size: 36,
                                color: Color(0xFF10B981),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Upload Foto',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF065F46),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Dari galeri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Cancel
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // PICK IMAGE - TANPA CROP! (PASTI BERHASIL!)
  // ✅ FIX: Loading dialog DIHAPUS dari sebelum kamera dibuka.
  //
  // PENJELASAN KENAPA CRASH SEBELUMNYA:
  // Dulu ada loading dialog yang ditampilkan SEBELUM kamera terbuka.
  // Saat kamera Android terbuka, Flutter membekukan activity-nya.
  // Saat kamera kembali (user klik OK), loadingContext yang disimpan
  // sudah tidak valid (stale), sehingga Navigator.pop(loadingContext!)
  // menyebabkan crash.
  //
  // SOLUSI: Kamera/galeri itu sendiri sudah memblokir layar, tidak
  // perlu loading dialog tambahan sebelum kamera terbuka.
  // Loading hanya ditampilkan SESUDAH foto dipilih jika dibutuhkan.
  // =========================================================================
  static Future<void> _pickImage(
    BuildContext context,
    ImageSource source,
    Function(File) onImageSelected,
  ) async {
    try {
      print('📸 Step 1: Starting image pick from $source');

      // ✅ FIX: Langsung buka kamera/galeri TANPA loading dialog dulu.
      // Kamera/galeri itu sendiri sudah "memblokir" layar user.
      final File? pickedFile = await ImageUtils.pickImage(source: source);

      print('📸 Step 2: Image picked - ${pickedFile != null ? 'SUCCESS' : 'CANCELLED'}');

      // User cancelled
      if (pickedFile == null) {
        print('⚠️ User cancelled image picking');
        return;
      }

      // ✅ Cek context masih valid setelah kembali dari kamera
      if (!context.mounted) {
        print('⚠️ Context no longer mounted after camera return');
        return;
      }

      // Delay kecil untuk UI settle setelah kembali dari kamera/galeri
      await Future.delayed(const Duration(milliseconds: 300));

      print('📸 Step 3: Calling callback with image (NO CROP)');

      // Call callback dengan file asli (TANPA CROP!)
      onImageSelected(pickedFile);

      print('✅ Image successfully passed to callback');

    } catch (e, stackTrace) {
      print('❌ ========== ERROR ==========');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      print('==============================');

      // Show error to user - cek context masih valid dulu
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memproses foto: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}