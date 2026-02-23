import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/auth_service.dart';
import 'package:sidrive/services/ktm_barcode_service.dart';
import 'package:sidrive/services/ktm_verification_service.dart';
import 'package:sidrive/core/widgets/custom_button.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/screens/welcome_screen.dart'; 
import 'package:sidrive/core/utils/ktm_image_picker_helper.dart'; 



class NimVerificationMultiScreen extends StatefulWidget {
  final List<String> roles;
  const NimVerificationMultiScreen({super.key, required this.roles});

  @override
  State<NimVerificationMultiScreen> createState() => _NimVerificationMultiScreenState();
}

class _NimVerificationMultiScreenState extends State<NimVerificationMultiScreen> {
  final _nimController = TextEditingController();
  final _authService = AuthService();
  final _ktmVerificationService = KtmVerificationService();
  
  bool _isVerified = false;
  bool _isLoading = false;
  
  String _verificationMode = 'manual'; // 'manual', 'barcode_scanning', 'upload_pending'
  File? _selectedKtmPhoto;

  // 🔥 Retry System
  int _scanAttempts = 0;
  static const int _maxScanAttempts = 3;
  List<String> _failedScanReasons = [];

  @override
  void initState() {
    super.initState();
    _checkExistingVerification();
  }

  @override
  void dispose() {
    _nimController.dispose();
    _selectedKtmPhoto = null;
    super.dispose();
  }

  // ============================================================================
  // CHECK - Cek apakah user sudah punya pending verification
  // ============================================================================
  Future<void> _checkExistingVerification() async {
    try {
      final userId = _authService.getUserId();
      
      if (userId != null) {
        final status = await _authService.getKtmVerificationStatus(userId);
        
        if (status != null && mounted) {
          if (status['status'] == 'pending') {
            setState(() => _verificationMode = 'upload_pending');
            _showPendingVerificationDialog();
          } else if (status['status'] == 'approved') {
            if (mounted) {
              Navigator.pushReplacementNamed(
                context,
                '/register/form-multi',
                arguments: widget.roles,
              );
            }
          } else if (status['status'] == 'rejected') {
            _showRejectedDialog(status['rejection_reason'] ?? 'Foto KTM tidak valid');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking verification: $e');
    }
  }

  // ============================================================================
  // TIER 1: BARCODE SCAN - Auto-Approve WITH RETRY
  // ============================================================================
  Future<void> _scanBarcode() async {
    if (_verificationMode == 'upload_pending') {
      _showErrorDialog('Verifikasi KTM Anda sedang direview oleh admin.');
      return;
    }

    if (_scanAttempts >= _maxScanAttempts) {
      _showMaxAttemptsDialog();
      return;
    }

    setState(() => _scanAttempts++);

    final status = await Permission.camera.request();
    
    if (status.isDenied || status.isPermanentlyDenied) {
      _showCameraPermissionDialog();
      return;
    }

    setState(() => _verificationMode = 'barcode_scanning');

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KtmBarcodeScannerWithGuidance(
          attemptNumber: _scanAttempts,
          maxAttempts: _maxScanAttempts,
          onBarcodeDetected: _verifyNimFromBarcode,
          onScanFailed: (reason) {
            if (mounted) {
              setState(() => _failedScanReasons.add(reason));
              _handleScanFailure(reason);
            }
          },
          onCancel: () {
            if (mounted) {
              setState(() => _verificationMode = 'manual');
            }
          },
        ),
      ),
    ).then((_) {
      if (mounted && _verificationMode == 'barcode_scanning') {
        setState(() => _verificationMode = 'manual');
      }
    });
  }

  void _handleScanFailure(String reason) {
    if (_scanAttempts >= _maxScanAttempts) {
      _showMaxAttemptsDialog();
    } else {
      _showScanFailureDialog(reason);
    }
  }

  // ============================================================================
  // VERIFY NIM FROM BARCODE
  // ============================================================================
  Future<void> _verifyNimFromBarcode(String nim) async {
    if (!mounted) return;
    
    final authProvider = context.read<AuthProvider>();

    setState(() => _isLoading = true);

    try {
      // STEP 1: Check NIM availability
      final isAvailable = await _authService.isNimAvailable(nim);
      
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNimAlreadyRegisteredDialog();
        }
        return;
      }

      // STEP 2: Validate NIM in database
      final success = await authProvider.checkNim(nim);
      
      if (!mounted) return;

      if (success) {
        setState(() {
          _isVerified = true;
          _nimController.text = nim;
          _verificationMode = 'approved';
          _isLoading = false;
        });
        
        debugPrint('✅ [BARCODE_VERIFY] Auto-approved: $nim');
      } else {
        final errorMsg = 'NIM tidak ditemukan di database mahasiswa aktif';
        if (mounted) {
          setState(() {
            _failedScanReasons.add(errorMsg);
            _isLoading = false;
          });
          _handleScanFailure(errorMsg);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _failedScanReasons.add(e.toString());
          _isLoading = false;
        });
        _handleScanFailure(_parseErrorMessage(e.toString()));
      }
    }
  }

  // ============================================================================
  // TIER 2: SHOW IMAGE SOURCE PICKER (STATIC HELPER!)
  // ============================================================================
  void _manualUploadKtm() {
    if (_nimController.text.isEmpty) {
      _showErrorDialog('Harap masukkan NIM terlebih dahulu');
      return;
    }
    
    // ✅ Pakai STATIC helper seperti profile_photo_dialog.dart
    KtmImagePickerHelper.showImageSourceDialog(
      context: context,
      onImageSelected: (File croppedFile) {
        // ✅ Callback ini dipanggil SETELAH berhasil crop
        if (mounted) {
          setState(() => _selectedKtmPhoto = croppedFile);
        }
      },
    );
  }

  // ============================================================================
  // SUBMIT MANUAL VERIFICATION
  // ============================================================================
  Future<void> _submitManualVerification() async {
    if (_selectedKtmPhoto == null) {
      _showErrorDialog('Harap pilih foto KTM terlebih dahulu');
      return;
    }

    if (_nimController.text.isEmpty) {
      _showErrorDialog('Harap masukkan NIM terlebih dahulu');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      
      // STEP 1: Check NIM availability
      debugPrint('🔍 Checking NIM availability...');
      final isAvailable = await _authService.isNimAvailable(_nimController.text);
      
      if (!isAvailable) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showNimAlreadyRegisteredDialog();
        }
        return;
      }

      // STEP 2: Validate NIM
      debugPrint('🔍 Validating NIM in database...');
      final isValid = await authProvider.checkNim(_nimController.text);
      
      if (!isValid) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showErrorDialog('NIM tidak ditemukan di database mahasiswa aktif');
        }
        return;
      }

      // STEP 3: Submit to verification service
      debugPrint('📤 Submitting verification request...');
      await _ktmVerificationService.submitVerificationRequest(
        idUser: _authService.getUserId(),
        nim: _nimController.text,
        ktmPhoto: _selectedKtmPhoto!,
        extractedName: authProvider.verifiedMahasiswa?.namaLengkap,
      );

      if (!mounted) return;

      // Success - update state
      setState(() {
        _verificationMode = 'upload_pending';
        _isLoading = false;
      });

      // SAVE NIM & ROLES to SharedPreferences
      await StorageService.setString('pending_ktm_nim', _nimController.text);
      await StorageService.setString('pending_ktm_roles', widget.roles.join(','));
      await StorageService.remove('ktm_rejection_acked');
      
      debugPrint('✅ Manual verification submitted successfully');

    } catch (e) {
      debugPrint('❌ Error submitting verification: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(_parseErrorMessage(e.toString()));
      }
    }
  }

  // ============================================================================
  // HELPER - Parse error message
  // ============================================================================
  String _parseErrorMessage(String error) {
    if (error.contains('StorageException')) {
      return 'Gagal upload foto. Pastikan koneksi internet stabil.';
    }
    if (error.contains('PostgrestException')) {
      return 'Gagal menyimpan data. Silakan coba lagi.';
    }
    if (error.contains('SocketException')) {
      return 'Tidak ada koneksi internet';
    }
    return error.replaceAll('Exception:', '').trim();
  }

  // ============================================================================
  // DIALOGS
  // ============================================================================
  
  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Error', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

 
  void _showPendingVerificationDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // ── Orange Gradient Background ──
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6F00), Color(0xFFFFA726), Color(0xFFFFCC02)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),

                // ── Decorative Circles ──
                Positioned(
                  top: -30,
                  right: -30,
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: -30,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06),
                    ),
                  ),
                ),

                // ── Content ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.pending_actions_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Title
                      const Text(
                        'Sedang Diproses',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '⏳  Menunggu Review Admin',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info Box
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildPendingInfoRow(
                              Icons.cloud_upload_rounded,
                              'KTM Berhasil Diupload',
                              'Foto KTM kamu sudah kami terima',
                            ),
                            const SizedBox(height: 14),
                            Divider(color: Colors.white.withOpacity(0.2), height: 1),
                            const SizedBox(height: 14),
                            _buildPendingInfoRow(
                              Icons.manage_search_rounded,
                              'Sedang Direview Admin',
                              'Tim kami memverifikasi data KTM kamu',
                            ),
                            const SizedBox(height: 14),
                            Divider(color: Colors.white.withOpacity(0.2), height: 1),
                            const SizedBox(height: 14),
                            _buildPendingInfoRow(
                              Icons.timer_rounded,
                              'Estimasi Waktu',
                              'Maksimal 1×24 jam kerja',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Notice
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.notifications_active_rounded,
                                color: Colors.white, size: 18),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Cek halaman welcome secara berkala untuk melihat status verifikasi kamu.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Button — fungsi tetap sama
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          },
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.home_rounded, color: Color(0xFFFF6F00), size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Kembali ke Welcome',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFFFF6F00),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showRejectedDialog(String reason) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Verifikasi Ditolak', style: TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Verifikasi KTM Anda ditolak oleh admin.\n',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const Text('Alasan:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(
                  reason,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Silakan upload foto KTM yang baru dan pastikan:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _buildRequirement('Foto jelas dan tidak blur'),
              _buildRequirement('Semua informasi terbaca'),
              _buildRequirement('Tidak ada bagian yang terpotong'),
              _buildRequirement('KTM asli dan masih berlaku'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await StorageService.setBool('ktm_rejection_acked', true);
                if (mounted) {
                  Navigator.pop(context);
                  setState(() => _verificationMode = 'manual');
                }
              },
              child: const Text('Upload Ulang', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showNimAlreadyRegisteredDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('NIM Sudah Terdaftar', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'NIM yang Anda masukkan sudah terdaftar di sistem.\n\nJika Anda merasa ini adalah kesalahan, silakan hubungi admin untuk bantuan lebih lanjut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showCameraPermissionDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.camera_alt, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Izin Kamera', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'Aplikasi memerlukan izin kamera untuk scan barcode KTM.\n\nSilakan berikan izin kamera di pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showScanFailureDialog(String reason) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Scan Gagal', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Alasan: $reason'),
            const SizedBox(height: 16),
            Text(
              'Percobaan $_scanAttempts dari $_maxScanAttempts',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            if (_scanAttempts < _maxScanAttempts)
              const Text(
                'Tips untuk scan berikutnya:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            if (_scanAttempts < _maxScanAttempts) ...[
              const SizedBox(height: 8),
              _buildTipItem('Pastikan barcode jelas terlihat'),
              _buildTipItem('Jarak optimal 10-15 cm'),
              _buildTipItem('Pencahayaan cukup terang'),
              _buildTipItem('Hindari pantulan cahaya'),
            ],
          ],
        ),
        actions: [
          if (_scanAttempts < _maxScanAttempts)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _scanBarcode();
              },
              child: const Text('Coba Lagi', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showMaxAttemptsDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Batas Percobaan', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Anda telah mencapai batas maksimal $_maxScanAttempts kali percobaan scan barcode.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            const Text(
              'Silakan gunakan metode manual dengan mengupload foto KTM Anda untuk proses verifikasi.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alasan gagal scan:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (_failedScanReasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._failedScanReasons.take(3).map((reason) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 4),
                child: Text('• $reason', style: const TextStyle(fontSize: 12)),
              )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _verificationMode = 'manual';
                _scanAttempts = 0;
                _failedScanReasons.clear();
              });
            },
            child: const Text('Upload Manual', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, size: 16, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // BUILD UI
  // ============================================================================
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              
              // ── HEADER ──
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verifikasi NIM',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Scan barcode atau upload KTM',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── STATUS CARDS ──
              if (_verificationMode == 'upload_pending')
                _buildPendingCard()
              else if (_isVerified)
                _buildApprovedCard(authProvider)
              else ...[
                // ── TIER 1: BARCODE SCAN ──
                _buildBarcodeCard(),
                
                const SizedBox(height: 24),
                
                // ── DIVIDER ──
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ATAU',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // ── TIER 2: MANUAL UPLOAD ──
                _buildManualUploadCard(),
              ],

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBarcodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5DADE2), Color(0xFF3498DB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5DADE2).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚡ SCAN BARCODE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tercepat & Otomatis',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildFeature(Icons.bolt, 'Verifikasi Instan', 'Langsung approved tanpa menunggu'),
                const SizedBox(height: 12),
                _buildFeature(Icons.security, 'Aman & Akurat', 'Membaca barcode asli KTM'),
                const SizedBox(height: 12),
                _buildFeature(Icons.timer, 'Hemat Waktu', 'Proses hanya 5-10 detik'),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (_scanAttempts < _maxScanAttempts) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                onPressed: _isLoading ? null : _scanBarcode,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Color(0xFF3498DB)),
                    const SizedBox(width: 8),
                    Text(
                      _scanAttempts > 0 
                          ? 'Coba Scan Lagi ($_scanAttempts/$_maxScanAttempts)'
                          : 'MULAI SCAN',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3498DB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Batas scan tercapai ($_maxScanAttempts kali). Gunakan upload manual.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildManualUploadCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.upload_file,
                  color: Color(0xFF10B981),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📤 UPLOAD MANUAL',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review admin 1x24 jam',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // NIM Input
          TextField(
            controller: _nimController,
            enabled: !_isLoading,
            keyboardType: TextInputType.number,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: 'NIM',
              hintText: 'Contoh: 2141720001',
              counterText: '',
              prefixIcon: const Icon(Icons.badge),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Photo Preview atau Upload Button
          if (_selectedKtmPhoto != null) ...[
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedKtmPhoto!,
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedKtmPhoto = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isLoading ? null : _submitManualVerification,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'SUBMIT VERIFIKASI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Color(0xFF10B981),
                    size: 32,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Pastikan foto KTM:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement('Jelas dan tidak blur'),
                  _buildRequirement('Semua informasi terbaca'),
                  _buildRequirement('Tidak ada bagian terpotong'),
                  _buildRequirement('KTM asli & masih berlaku'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                onPressed: _isLoading ? null : _manualUploadKtm,
                icon: const Icon(Icons.camera_alt, color: Color(0xFF10B981)),
                label: const Text(
                  'PILIH FOTO KTM',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          // ── Background Gradient ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF6F00), Color(0xFFFFA726), Color(0xFFFFCC02)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative Circles Background ──
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),

          // ── Content ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // ✅ FIX: shrink-wrap konten
              children: [
                const SizedBox(height: 8), // ✅ ganti Spacer

                // ── Animated Icon Area ──
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.pending_actions_rounded,
                    color: Colors.white,
                    size: 60,
                  ),
                ),

                const SizedBox(height: 28),

                // ── Title ──
                const Text(
                  'Sedang Diproses',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⏳  Menunggu Review Admin',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ── Info Cards ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildPendingInfoRow(
                        Icons.cloud_upload_rounded,
                        'KTM Berhasil Diupload',
                        'Foto KTM kamu sudah kami terima dengan baik',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.2), height: 1),
                      const SizedBox(height: 16),
                      _buildPendingInfoRow(
                        Icons.manage_search_rounded,
                        'Sedang Direview Admin',
                        'Tim kami akan memverifikasi data KTM kamu',
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.2), height: 1),
                      const SizedBox(height: 16),
                      _buildPendingInfoRow(
                        Icons.timer_rounded,
                        'Estimasi Waktu',
                        'Maksimal 1×24 jam kerja',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Notice Box ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Cek halaman welcome secara berkala untuk melihat status verifikasi kamu.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24), // ✅ ganti Spacer

                // ── Button ──
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    onPressed: () {
                      WelcomeScreen.triggerStatusRefresh();
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.home_rounded, color: Color(0xFFFF6F00), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Kembali ke Welcome',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFFF6F00),
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingInfoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildApprovedCard(AuthProvider authProvider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 72,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '🎉 NIM TERVERIFIKASI!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Nama', authProvider.verifiedMahasiswa?.namaLengkap ?? '-'),
                  const SizedBox(height: 8),
                  _buildInfoRow('Prodi', authProvider.verifiedMahasiswa?.programStudi ?? '-'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Lanjut Daftar →',
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/register/form-multi',
                  arguments: widget.roles,
                );
              },
              backgroundColor: Colors.green,
              textColor: Colors.white,
              enable3DEffect: true,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// BARCODE SCANNER WITH GUIDANCE
// ============================================================================
class KtmBarcodeScannerWithGuidance extends StatefulWidget {
  final int attemptNumber;
  final int maxAttempts;
  final Function(String nim) onBarcodeDetected;
  final Function(String reason) onScanFailed;
  final VoidCallback? onCancel;

  const KtmBarcodeScannerWithGuidance({
    super.key,
    required this.attemptNumber,
    required this.maxAttempts,
    required this.onBarcodeDetected,
    required this.onScanFailed,
    this.onCancel,
  });

  @override
  State<KtmBarcodeScannerWithGuidance> createState() => _KtmBarcodeScannerWithGuidanceState();
}

class _KtmBarcodeScannerWithGuidanceState extends State<KtmBarcodeScannerWithGuidance> {
  bool _showTips = true;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Scanner
        KtmBarcodeScanner(
          onBarcodeDetected: widget.onBarcodeDetected,
          onCancel: widget.onCancel,
        ),
        
        // Tips overlay
        if (_showTips)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: Container(
                color: Colors.black.withOpacity(0.7),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tips_and_updates, color: Color(0xFF5DADE2), size: 28),
                            SizedBox(width: 12),
                            Text(
                              'TIPS SCAN BARCODE',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildTip(Icons.straighten, 'Jarak optimal: 10-15 cm dari KTM'),
                        _buildTip(Icons.lightbulb_outline, 'Pencahayaan cukup terang'),
                        _buildTip(Icons.settings_overscan, 'Pegang HP dengan stabil'),
                        _buildTip(Icons.center_focus_strong, 'Barcode harus jelas & fokus'),
                        _buildTip(Icons.wb_sunny_outlined, 'Hindari pantulan cahaya'),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5DADE2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => setState(() => _showTips = false),
                            child: const Text(
                              'MULAI SCAN',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
  
  Widget _buildTip(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.green, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}