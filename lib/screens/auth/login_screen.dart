// lib/screens/auth/login_screen.dart
// ============================================================================
// LOGIN_SCREEN.DART - ✅ FIXED!
// CREATIVE UI WITH CHARACTER PEEKING (NO SCROLL, PERFECT FIT)
// LOGIN LOGIC: User dengan pending_verification TETAP BISA MASUK DASHBOARD!
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart'; 
import 'package:sidrive/core/utils/validators.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/services/ktm_verification_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nimController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ktmService = KtmVerificationService();
  bool _rememberMe = false;
  bool _isPasswordVisible = false;
  

  @override
  void initState() {
    super.initState();
    if (StorageService.getRememberMe()) {
      final lastNim = StorageService.getLastNim();
      if (lastNim != null) {
        _nimController.text = lastNim;
        _rememberMe = true;
      }
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    try {
      final success = await authProvider.login(
        nim: _nimController.text.trim(),
        password: _passwordController.text,
        rememberMe: _rememberMe,
      );

      if (!mounted) return;

      if (success) {
        final availableRoles = authProvider.userRoles
          .where((r) => r.isActive)  // Ambil semua role aktif (termasuk pending!)
          .map((r) => r.role)
          .toList();
        
        // ⚠️ NOTE: availableRoles INCLUDE pending roles!
        // User dengan pending role BOLEH login, tapi tidak bisa terima order
        // Cek jumlah available roles untuk tentukan flow berikutnya
        if (availableRoles.length > 1) {
          // Multiple roles → tampilkan dialog pemilihan
          if (!mounted) return;
          _showRoleSelectionDialog(availableRoles);
        } else if (availableRoles.length == 1) {
          // Single role → langsung redirect
          _redirectBasedOnRole(availableRoles.first);
        } else {
          // Tidak ada role sama sekali → error
          _showErrorDialog('Tidak ada role yang tersedia untuk user ini');
        }
      } else {
        _showErrorDialog(authProvider.errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog(_parseErrorMessage(e.toString()));
    }
  }

  void _showRoleSelectionDialog(List<String> availableRoles) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveMobile.scaledW(320),
            maxHeight: ResponsiveMobile.screenHeight(context) * 0.6,
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveMobile.scaledR(20)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.account_circle,
                      size: ResponsiveMobile.scaledSP(28),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    SizedBox(width: ResponsiveMobile.scaledW(12)),
                    Expanded(
                      child: Text(
                        'Pilih Role',
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(20),
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(16)),
                
                // Description
                Text(
                  'Anda memiliki beberapa role. Pilih role yang ingin digunakan:',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(20)),
                
                // Role buttons
                ...availableRoles.map((role) {
                  IconData icon;
                  String label;
                  Color color;
                  
                  // ✅ FIX: Cek status role untuk kasih indicator
                  final authProvider = context.read<AuthProvider>();
                  final isActive = authProvider.isRoleActive(role);
                  
                  switch (role) {
                    case 'customer':
                      icon = Icons.person;
                      label = 'Customer';
                      color = Theme.of(context).colorScheme.primary;
                      break;
                    case 'driver':
                      icon = Icons.motorcycle;
                      label = isActive ? 'Driver' : 'Driver (Pending)';
                      color = Colors.green;
                      break;
                    case 'umkm':
                      icon = Icons.store;
                      label = isActive ? 'UMKM' : 'UMKM (Pending)';
                      color = Colors.orange;
                      break;
                    default:
                      icon = Icons.person;
                      label = role;
                      color = Colors.grey;
                  }
                  
                  return Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveMobile.scaledH(12)),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _selectRole(role);
                      },
                      icon: Icon(icon, size: ResponsiveMobile.scaledSP(22)),
                      label: Text(
                        label,
                        style: TextStyle(
                          fontSize: ResponsiveMobile.scaledFont(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: ResponsiveMobile.scaledH(16),
                          horizontal: ResponsiveMobile.scaledW(16),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            ResponsiveMobile.scaledR(12),
                          ),
                        ),
                        elevation: 2,
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectRole(String selectedRole) async {
    final authProvider = context.read<AuthProvider>();
    
    try {
      final success = await authProvider.switchRole(selectedRole);
      
      if (!success) {
        if (!mounted) return;
        _showErrorDialog(authProvider.errorMessage ?? 'Gagal memilih role. Silakan coba lagi.');
        return;
      }
      
      await authProvider.init();
      
      if (!mounted) return;
      
      _redirectBasedOnRole(selectedRole);
      
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Gagal memilih role: ${_parseErrorMessage(e.toString())}');
    }
  }

  // ============================================================================
  // ✅ FIX UTAMA: REDIRECT LOGIC YANG BENAR!
  // User dengan pending_verification TETAP BISA MASUK DASHBOARD!
  // ============================================================================
  void _redirectBasedOnRole(String role) {
    // ✅ TIDAK LAGI CEK STATUS! Semua role langsung ke dashboard masing-masing
    // Dashboard yang akan handle apakah user bisa terima order atau tidak
    
    String route;
    switch (role) {
      case 'customer':
        route = '/customer/dashboard';
        break;
      case 'driver':
        route = '/driver/dashboard';
        break;
      case 'umkm':
        route = '/umkm/dashboard';
        break;
      default:
        route = '/customer/dashboard'; // Fallback
    }
    
    Navigator.pushReplacementNamed(context, route);
  }

  // Error dialog yang informatif dan responsive
  void _showErrorDialog(String? errorMessage) {
    String title;
    String message;
    IconData icon;
    Color iconColor;

    // Parse error message untuk memberikan feedback yang tepat
    if (errorMessage == null || errorMessage.isEmpty) {
      title = 'Login Gagal';
      message = 'Terjadi kesalahan yang tidak diketahui. Silakan coba lagi.';
      icon = Icons.error_outline;
      iconColor = Colors.red;
    } else if (errorMessage.toLowerCase().contains('password') || 
               errorMessage.toLowerCase().contains('salah') ||
               errorMessage.toLowerCase().contains('incorrect')) {
      title = 'Password Salah';
      message = 'NIM atau password yang Anda masukkan salah. Silakan periksa kembali dan coba lagi.';
      icon = Icons.lock_outline;
      iconColor = Colors.orange;
    } else if (errorMessage.toLowerCase().contains('network') || 
               errorMessage.toLowerCase().contains('internet') ||
               errorMessage.toLowerCase().contains('connection')) {
      title = 'Tidak Ada Koneksi';
      message = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda dan coba lagi.';
      icon = Icons.wifi_off;
      iconColor = Colors.blue;
    } else if (errorMessage.toLowerCase().contains('not found') || 
               errorMessage.toLowerCase().contains('tidak ditemukan')) {
      title = 'Akun Tidak Ditemukan';
      message = 'NIM yang Anda masukkan tidak terdaftar. Silakan daftar terlebih dahulu.';
      icon = Icons.person_off_outlined;
      iconColor = Colors.grey;
    } else if (errorMessage.toLowerCase().contains('timeout')) {
      title = 'Koneksi Timeout';
      message = 'Server membutuhkan waktu terlalu lama untuk merespons. Silakan coba lagi.';
      icon = Icons.timer_off;
      iconColor = Colors.orange;
    } else {
      title = 'Login Gagal';
      message = errorMessage;
      icon = Icons.error_outline;
      iconColor = Colors.red;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(16)),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: ResponsiveMobile.scaledW(320),
          ),
          child: Padding(
            padding: EdgeInsets.all(ResponsiveMobile.scaledR(24)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: EdgeInsets.all(ResponsiveMobile.scaledR(16)),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: ResponsiveMobile.scaledSP(48),
                    color: iconColor,
                  ),
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(16)),
                
                // Title
                Text(
                  title,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(20),
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(12)),
                
                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.scaledFont(14),
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: ResponsiveMobile.scaledH(24)),
                
                // Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: ResponsiveMobile.scaledH(14),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          ResponsiveMobile.scaledR(12),
                        ),
                      ),
                    ),
                    child: Text(
                      'Tutup',
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(16),
                        fontWeight: FontWeight.w600,
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

  void _showApprovedVerificationDialog(String nim) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
          ),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.all(ResponsiveMobile.scaledR(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveMobile.scaledW(80),
                height: ResponsiveMobile.scaledW(80),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: const Color(0xFF10B981),
                  size: ResponsiveMobile.scaledW(50),
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              Text(
                'KTM Terverifikasi! ✅',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              
              Text(
                'Admin telah menyetujui KTM kamu (NIM: $nim).\n\nSilakan lanjutkan pendaftaran akun.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(14),
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(
                      context,
                      '/register/role-multi',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Lanjut ke Pendaftaran',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(15),
                      fontWeight: FontWeight.w600,
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

  // ============================================================================
  // POPUP: REJECTED ❌ (untuk login screen)
  // ============================================================================
  void _showRejectedVerificationDialog(String nim, String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
          ),
          backgroundColor: Colors.white,
          contentPadding: EdgeInsets.all(ResponsiveMobile.scaledR(24)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: ResponsiveMobile.scaledW(80),
                height: ResponsiveMobile.scaledW(80),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.cancel,
                  color: const Color(0xFFEF4444),
                  size: ResponsiveMobile.scaledW(50),
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),
              
              Text(
                'Verifikasi Ditolak ❌',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(20),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),
              
              Text(
                'Admin menolak verifikasi KTM kamu (NIM: $nim).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(14),
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(10)),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(ResponsiveMobile.scaledR(12)),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(10)),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: const Color(0xFFEF4444),
                          size: ResponsiveMobile.scaledW(18),
                        ),
                        SizedBox(width: ResponsiveMobile.scaledW(6)),
                        Text(
                          'Alasan Penolakan:',
                          style: TextStyle(
                            fontSize: ResponsiveMobile.scaledFont(13),
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: ResponsiveMobile.scaledH(6)),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: ResponsiveMobile.scaledFont(13),
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pushReplacementNamed(
                      context,
                      '/register/role-multi',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Upload Ulang KTM',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(15),
                      fontWeight: FontWeight.w600,
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

  void _showPendingVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(20)),
        ),
        child: Container(
          padding: EdgeInsets.all(ResponsiveMobile.scaledR(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pending Icon
              Container(
                width: ResponsiveMobile.scaledW(80),
                height: ResponsiveMobile.scaledW(80),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.hourglass_empty,
                  color: const Color(0xFFF59E0B),
                  size: ResponsiveMobile.scaledW(50),
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(20)),

              // Title
              Text(
                'Verifikasi Sedang Diproses ⏳',
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: ResponsiveMobile.scaledH(12)),

              // Message
              Text(
                'Anda tidak dapat mendaftar ulang karena verifikasi KTM Anda sedang dalam proses review oleh admin.\n\nMaksimal 1x24 jam. Mohon tunggu dan cek kembali di halaman welcome.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveMobile.scaledFont(14),
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              SizedBox(height: ResponsiveMobile.scaledH(24)),

              // Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: ResponsiveMobile.scaledH(14),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(ResponsiveMobile.scaledR(12)),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Mengerti',
                    style: TextStyle(
                      fontSize: ResponsiveMobile.scaledFont(15),
                      fontWeight: FontWeight.w600,
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

  String _parseErrorMessage(String error) {
    if (error.contains('Exception:')) {
      return error.split('Exception:').last.trim();
    }
    return error;
  }

  @override
  void dispose() {
    _nimController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            
            // PERHITUNGAN TINGGI YANG LEBIH PRESISI
            double topSpacerHeight;
            double characterSectionHeight;
            double bottomSpacerHeight;

            if (screenHeight < 680) {
              topSpacerHeight = screenHeight * 0.12;
              characterSectionHeight = screenHeight * 0.32;
              bottomSpacerHeight = screenHeight * 0.03;
            } else if (screenHeight < 750) {
              topSpacerHeight = screenHeight * 0.10;
              characterSectionHeight = screenHeight * 0.33;
              bottomSpacerHeight = screenHeight * 0.04;
            } else if (screenHeight < 850) {
              topSpacerHeight = screenHeight * 0.12;
              characterSectionHeight = screenHeight * 0.35;
              bottomSpacerHeight = screenHeight * 0.05;
            } else {
              topSpacerHeight = screenHeight * 0.14;
              characterSectionHeight = screenHeight * 0.36;
              bottomSpacerHeight = screenHeight * 0.05;
            }

            return Stack(
              children: [
                // BACKGROUND IMAGE
                Positioned.fill(
                  child: Image.asset(
                    AssetPaths.loginBackground,
                    fit: BoxFit.cover,
                  ),
                ),

                // FORM CONTENT
                SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // TOP SPACER
                            SizedBox(height: topSpacerHeight),

                            // ===== NIM FIELD =====
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(50),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'NIM',
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledFont(14),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveMobile.scaledH(6)),
                                  
                                  TextFormField(
                                    controller: _nimController,
                                    validator: Validators.nim,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(12),
                                    ],
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledFont(18),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      letterSpacing: 1.0,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan NIM Kamu',
                                      hintStyle: TextStyle(
                                        color: Colors.black45,
                                        fontSize: ResponsiveMobile.scaledFont(16),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: ResponsiveMobile.scaledH(10),
                                      ),
                                      errorStyle: TextStyle(
                                        fontSize: ResponsiveMobile.scaledFont(10),
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(2)),

                            // GARIS PEMISAH
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(60),
                              ),
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(10)),

                            // ===== PASSWORD FIELD =====
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(50),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'PASSWORD',
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledFont(14),
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black87,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: ResponsiveMobile.scaledH(6)),
                                  
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: !_isPasswordVisible,
                                    validator: Validators.password,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledFont(18),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                      letterSpacing: 2.0,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Masukkan Password',
                                      hintStyle: TextStyle(
                                        color: Colors.black45,
                                        fontSize: ResponsiveMobile.scaledFont(16),
                                        fontWeight: FontWeight.w400,
                                      ),
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      focusedErrorBorder: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveMobile.scaledW(12),
                                        vertical: ResponsiveMobile.scaledH(10),
                                      ),
                                      errorStyle: TextStyle(
                                        fontSize: ResponsiveMobile.scaledFont(10),
                                        color: Colors.red.shade700,
                                      ),
                                      suffixIconConstraints: BoxConstraints(
                                        minWidth: ResponsiveMobile.scaledW(40),
                                        minHeight: ResponsiveMobile.scaledH(40),
                                      ),
                                      suffixIcon: Padding(
                                        padding: EdgeInsets.only(right: ResponsiveMobile.scaledW(8)),
                                        child: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.black54,
                                          size: ResponsiveMobile.scaledSP(20),
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible = !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(2)),

                            // GARIS PEMISAH
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(60),
                              ),
                              child: Container(
                                height: 1.5,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.black54,
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(6)),

                            // REMEMBER ME
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (value) {
                                      setState(() {
                                        _rememberMe = value ?? false;
                                      });
                                    },
                                    activeColor: Colors.black87,
                                    checkColor: Colors.white,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    side: BorderSide(color: Colors.black45, width: 1.4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                SizedBox(width: ResponsiveMobile.scaledW(8)),
                                Text(
                                  'Ingat Saya',
                                  style: TextStyle(
                                    fontSize: ResponsiveMobile.scaledFont(12),
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),

                            // SPACER UNTUK ANIMASI
                            SizedBox(height: characterSectionHeight),

                            // SPACER ANTARA ANIMASI DAN TOMBOL
                            SizedBox(height: bottomSpacerHeight),

                            // ===== LOGIN BUTTON =====
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: ResponsiveMobile.scaledW(60),
                              ),
                              child: Consumer<AuthProvider>(
                                builder: (context, authProvider, _) {
                                  return SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: authProvider.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.black87,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(
                                          vertical: ResponsiveMobile.scaledH(14),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            ResponsiveMobile.scaledR(30),
                                          ),
                                        ),
                                        elevation: 8,
                                        shadowColor: Colors.black.withOpacity(0.4),
                                      ),
                                      child: authProvider.isLoading
                                          ? SizedBox(
                                              height: ResponsiveMobile.scaledH(20),
                                              width: ResponsiveMobile.scaledW(20),
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2.5,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : Text(
                                              'Login',
                                              style: TextStyle(
                                                fontSize: ResponsiveMobile.scaledFont(16),
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 2.0,
                                              ),
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(8)),

                            // LUPA PASSWORD
                            TextButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Fitur lupa password belum tersedia'),
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveMobile.scaledW(16),
                                  vertical: ResponsiveMobile.scaledH(2),
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(12),
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),

                            SizedBox(height: ResponsiveMobile.scaledH(4)),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum punya akun? ',
                                  style: TextStyle(
                                    fontSize: ResponsiveMobile.scaledFont(12),
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    // ✅ CEK DULU APAKAH ADA PENDING VERIFICATION
                                    final storedNim = StorageService.getString('pending_ktm_nim');
                                    
                                    if (storedNim != null && storedNim.isNotEmpty) {
                                      debugPrint('⚠️ [LOGIN] User has pending NIM: $storedNim');
                                      
                                      // Cek status dari database
                                      final status = await _ktmService.checkStatusByNim(storedNim);
                                      debugPrint('📊 [LOGIN] Status from DB: ${status?['status']}');
                                      
                                      if (status != null && status['status'] == 'pending') {
                                        // ⏳ Masih pending - tampilkan popup
                                        debugPrint('⏳ [LOGIN] Showing PENDING popup');
                                        _showPendingVerificationDialog();
                                        return;
                                      } else if (status != null && status['status'] == 'approved') {
                                        // ✅ Sudah approved - tampilkan popup & hapus NIM
                                        debugPrint('✅ [LOGIN] Showing APPROVED popup');
                                        await StorageService.remove('pending_ktm_nim');
                                        _showApprovedVerificationDialog(storedNim);
                                        return;
                                      } else if (status != null && status['status'] == 'rejected') {
                                        // ❌ Rejected - tampilkan popup & hapus NIM
                                        debugPrint('❌ [LOGIN] Showing REJECTED popup');
                                        await StorageService.remove('pending_ktm_nim');
                                        _showRejectedVerificationDialog(
                                          storedNim,
                                          status['rejection_reason'] ?? 'Foto KTM tidak valid',
                                        );
                                        return;
                                      }
                                    }
                                    
                                    // ✅ Tidak ada pending atau sudah approved/rejected - lanjut daftar
                                    debugPrint('➡️ [LOGIN] No pending verification, go to register');
                                    if (!mounted) return;
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/register/role-multi',
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: ResponsiveMobile.scaledW(4),
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Daftar',
                                    style: TextStyle(
                                      fontSize: ResponsiveMobile.scaledFont(12),
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveMobile.scaledH(20)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}