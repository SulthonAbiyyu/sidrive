// lib/screens/auth/register_form_screen.dart
// ============================================================================
// REGISTER_FORM_SCREEN.DART - CREATIVE UI WITH RIGHT LAYOUT
// DESIGN KONSEP:
// - Background: registerscreen.png (Karakter panda di KIRI)
// - SEMUA FORM DI KANAN (area kosong sebelah kanan karakter)
// - Form: NIM, Nama, No Telp, Password, Confirm Password
// - Garis underscore sebagai pemisah antar field
// - Button DAFTAR di bawah form dengan animasi 3D
// - Warna font: Menyesuaikan background
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/core/utils/validators.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // ✅ TAMBAH INI
import 'package:sidrive/services/storage_service.dart'; // ✅ TAMBAH INI
import 'package:sidrive/screens/auth/widgets/register_form/customer_terms_condition_widget.dart';

class RegisterFormScreen extends StatefulWidget {
  final List<String> roles;
  
  const RegisterFormScreen({
    super.key,
    required this.roles,
  });

  @override
  State<RegisterFormScreen> createState() => _RegisterFormScreenState();
}

class _RegisterFormScreenState extends State<RegisterFormScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _agreedToTerms = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  
  late AnimationController _buttonAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _namaController.text = authProvider.verifiedMahasiswa?.namaLengkap ?? '';
    
    // Setup animasi 3D untuk tombol
    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.02).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  // ============================================================================
  // ✅ FIX: CLEANUP AFTER REGISTRATION
  // Delete ktm_verification_requests dan clear localStorage
  // ============================================================================
  Future<void> _cleanupAfterRegistration(String nim) async {
    try {
      debugPrint('🧹 [CLEANUP] ================================');
      debugPrint('🧹 [CLEANUP] Starting cleanup for NIM: $nim');
      
      // 1. Delete from ktm_verification_requests
      try {
        final deleteResponse = await Supabase.instance.client
            .from('ktm_verification_requests')
            .delete()
            .eq('nim', nim)
            .select(); // ✅ TAMBAH .select() untuk verify delete berhasil
        
        debugPrint('✅ [CLEANUP] Delete response: $deleteResponse');
        debugPrint('✅ [CLEANUP] Deleted ktm_verification_requests for NIM: $nim');
      } catch (deleteError) {
        debugPrint('❌ [CLEANUP] Database delete error: $deleteError');
        // Continue anyway - jangan block registrasi
      }
      
      // 2. Clear localStorage
      try {
        await StorageService.remove('pending_ktm_nim');
        await StorageService.remove('pending_ktm_roles');
        debugPrint('✅ [CLEANUP] Cleared localStorage');
      } catch (storageError) {
        debugPrint('❌ [CLEANUP] Storage clear error: $storageError');
      }
      
      debugPrint('✅ [CLEANUP] Cleanup completed');
      debugPrint('🧹 [CLEANUP] ================================');
    } catch (e, stackTrace) {
      debugPrint('❌ [CLEANUP] General error during cleanup: $e');
      debugPrint('Stack trace: $stackTrace');
      // Don't throw error - cleanup failure shouldn't block registration success
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap setujui Syarat & Ketentuan'),
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    
    // ✅ FIX: Validasi verifiedMahasiswa tidak null
    if (authProvider.verifiedMahasiswa == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data mahasiswa tidak ditemukan. Silakan verifikasi NIM kembali.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final nim = authProvider.verifiedMahasiswa!.nim;
    
    final success = await authProvider.registerMultiRole(
      nim: nim,
      nama: _namaController.text.trim(),
      noTelp: _noTelpController.text.trim(),
      password: _passwordController.text,
      roles: widget.roles,
    );

    if (!mounted) return;

    if (success) {
      // ✅ FIX: Cleanup SEBELUM navigate
      await _cleanupAfterRegistration(nim);
      
      // ✅ FIX: Verify roles yang berhasil di-register dari database
      // Jangan pakai widget.roles karena bisa beda kalau ada error di backend
      final registeredRoles = authProvider.availableRoles;
      
      Navigator.pushReplacementNamed(
        context,
        '/register/success-multi',
        arguments: registeredRoles.isNotEmpty ? registeredRoles : widget.roles,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.errorMessage ?? 'Registrasi gagal',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _noTelpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // ============================================================
            // BACKGROUND IMAGE FULLSCREEN (Panda di kiri)
            // ============================================================
            Positioned.fill(
              child: Image.asset(
                AssetPaths.registerBackground,
                fit: BoxFit.cover,
              ),
            ),

            // ============================================================
            // FORM CONTENT - ALIGN KANAN (Karena karakter di kiri)
            // ============================================================
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerRight, // SEMUA DI KANAN
                child: Container(
                  width: ResponsiveMobile.scaledW(200), // Lebar area form
                  padding: EdgeInsets.symmetric(
                    horizontal: ResponsiveMobile.scaledW(20),
                    vertical: ResponsiveMobile.scaledH(24),
                  ),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // ================================================
                          // TITLE "DAFTAR"
                          // ================================================
                          Text(
                            'Daftar',
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(24),
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(8)),

                          // Info roles
                          Text(
                            widget.roles.join(", ").toUpperCase(),
                            style: TextStyle(
                              fontSize: ResponsiveMobile.scaledFont(11),
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(24)),

                          // ================================================
                          // NAMA LENGKAP FIELD
                          // ================================================
                          _buildFieldWithUnderline(
                            label: 'Nama',
                            controller: _namaController,
                            validator: Validators.name,
                            hintText: 'Nama Lengkap',
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(20)),

                          // ================================================
                          // NO. HP FIELD
                          // ================================================
                          _buildFieldWithUnderline(
                            label: 'No. HP',
                            controller: _noTelpController,
                            validator: Validators.phone,
                            hintText: 'Masukkan Ho. HP kamu',
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(13),
                            ],
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(20)),

                          // ================================================
                          // PASSWORD FIELD
                          // ================================================
                          _buildPasswordFieldWithUnderline(
                            label: 'Password',
                            controller: _passwordController,
                            validator: Validators.password,
                            hintText: 'Masukkan Password Kamu',
                            isVisible: _isPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(20)),

                          // ================================================
                          // CONFIRM PASSWORD FIELD
                          // ================================================
                          _buildPasswordFieldWithUnderline(
                            label: 'Konfirmasi',
                            controller: _confirmPasswordController,
                            validator: (value) => Validators.confirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            hintText: ' Masukkan Password Kamu Lagi',
                            isVisible: _isConfirmPasswordVisible,
                            onToggleVisibility: () {
                              setState(() {
                                _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                              });
                            },
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(16)),

                          // ================================================
                          // CHECKBOX SYARAT & KETENTUAN (TRANSPARENT SAAT UNCHECKED)
                          // ================================================
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  if (_agreedToTerms) {
                                    // Sudah setuju → tap lagi untuk batal
                                    setState(() => _agreedToTerms = false);
                                  } else {
                                    // Belum setuju → buka dialog S&K Customer
                                    final agreed = await showCustomerTermsConditionDialog(
                                      context: context,
                                    );
                                    if (!mounted) return;
                                    if (agreed) {
                                      setState(() => _agreedToTerms = true);
                                    }
                                  }
                                },
                                child: Container(
                                  width: ResponsiveMobile.scaledW(20),
                                  height: ResponsiveMobile.scaledH(20),
                                  decoration: BoxDecoration(
                                    color: _agreedToTerms ? Colors.orange : Colors.transparent,
                                    border: Border.all(
                                      color: _agreedToTerms ? Colors.orange : Colors.black38,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: _agreedToTerms
                                      ? Icon(
                                          Icons.check,
                                          size: ResponsiveMobile.scaledSP(16),
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                              SizedBox(width: ResponsiveMobile.scaledW(8)),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    if (_agreedToTerms) {
                                      setState(() => _agreedToTerms = false);
                                    } else {
                                      final agreed = await showCustomerTermsConditionDialog(
                                        context: context,
                                      );
                                      if (!mounted) return;
                                      if (agreed) {
                                        setState(() => _agreedToTerms = true);
                                      }
                                    }
                                  },
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: ResponsiveMobile.scaledFont(11),
                                        color: Colors.black87,
                                      ),
                                      children: [
                                        const TextSpan(text: 'Setuju '),
                                        TextSpan(
                                          text: 'Syarat & Ketentuan',
                                          style: TextStyle(
                                            color: Colors.teal.shade700,
                                            fontWeight: FontWeight.w700,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(24)),

                          // ================================================
                          // BUTTON DAFTAR DENGAN ANIMASI 3D
                          // ================================================
                          AnimatedBuilder(
                            animation: _buttonAnimationController,
                            builder: (context, child) {
                              return Transform(
                                transform: Matrix4.identity()
                                  ..setEntry(3, 2, 0.001) // perspective
                                  ..rotateX(_rotateAnimation.value)
                                  ..scale(_scaleAnimation.value),
                                alignment: Alignment.center,
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                      ResponsiveMobile.scaledR(12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withOpacity(0.4),
                                        blurRadius: 12 * (1 - _scaleAnimation.value + 0.05),
                                        offset: Offset(0, 8 * (1 - _scaleAnimation.value + 0.05)),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: authProvider.isLoading 
                                        ? null 
                                        : () async {
                                            await _buttonAnimationController.forward();
                                            await _buttonAnimationController.reverse();
                                            _register();
                                          },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
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
                                      elevation: 0,
                                    ),
                                    child: authProvider.isLoading
                                        ? SizedBox(
                                            height: ResponsiveMobile.scaledH(18),
                                            width: ResponsiveMobile.scaledW(18),
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          )
                                        : Text(
                                            'Daftar',
                                            style: TextStyle(
                                              fontSize: ResponsiveMobile.scaledFont(15),
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: ResponsiveMobile.scaledH(12)),

                          // Link ke Login
                          Center(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pushReplacementNamed(context, '/login');
                              },
                              child: Text(
                                'Sudah punya akun? Login',
                                style: TextStyle(
                                  fontSize: ResponsiveMobile.scaledFont(12),
                                  color: Colors.black87,
                                  decoration: TextDecoration.underline,
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

            // ============================================================
            // BACK BUTTON (TOP LEFT)
            // ============================================================
            Positioned(
              top: ResponsiveMobile.scaledH(16),
              left: ResponsiveMobile.scaledW(16),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Colors.black87,
                  size: ResponsiveMobile.scaledSP(24),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================================
  // HELPER: BUILD FIELD WITH UNDERLINE (NO BORDER, NO BOX)
  // ==========================================================================
  Widget _buildFieldWithUnderline({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(12),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveMobile.scaledH(6)),
        
        // Input Field (TANPA BOX HITAM)
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(14),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black38,
              fontSize: ResponsiveMobile.scaledFont(13),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveMobile.scaledH(8),
              horizontal: 0,
            ),
            errorStyle: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(10),
              color: Colors.red,
            ),
          ),
        ),
        
        // Underline
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black26,
                Colors.black54,
                Colors.black26,
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================================
  // HELPER: BUILD PASSWORD FIELD WITH UNDERLINE (NO BOX)
  // ==========================================================================
  Widget _buildPasswordFieldWithUnderline({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
    required String hintText,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(12),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        SizedBox(height: ResponsiveMobile.scaledH(6)),
        
        // Input Field (TANPA BOX HITAM)
        TextFormField(
          controller: controller,
          validator: validator,
          obscureText: !isVisible,
          style: TextStyle(
            fontSize: ResponsiveMobile.scaledFont(14),
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.black38,
              fontSize: ResponsiveMobile.scaledFont(13),
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.symmetric(
              vertical: ResponsiveMobile.scaledH(8),
              horizontal: 0,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                size: ResponsiveMobile.scaledSP(18),
                color: Colors.black54,
              ),
              onPressed: onToggleVisibility,
            ),
            errorStyle: TextStyle(
              fontSize: ResponsiveMobile.scaledFont(10),
              color: Colors.red,
            ),
          ),
        ),
        
        // Underline
        Container(
          height: 1.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.black26,
                Colors.black54,
                Colors.black26,
              ],
            ),
          ),
        ),
      ],
    );
  }
}