import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sidrive/config/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidrive/config/app_colors_admin.dart';
import 'package:sidrive/providers/admin_provider.dart';
import 'package:sidrive/screens/admin/admin_dashboard.dart';



/// ============================================================================
/// ADMIN LANDING SCREEN - 100% EXACT COPY FROM REACT
/// Split Screen Design dengan Animated Sliding Panel + Hover Effects
/// Left: Login Form | Right: Logo Only (Clean)
/// ============================================================================

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
  with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _rememberMe = false;
  bool _isButtonPressed = false;
  bool _isButtonHovered = false;
  bool _obscurePassword = true;
  String? _notificationMessage;
  bool _isSuccess = false;

  // ✅ FocusNode untuk password field agar Tab dari username langsung ke sini,
  // dan Enter di password langsung trigger login
  final _passwordFocusNode = FocusNode();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✅ Inisialisasi animasi controller dulu (belum forward)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    // ✅ FIX BLINK: Load data remember-me DULU, baru forward animasi.
    // Sebelumnya: animasi langsung forward → _loadRememberMe selesai → setState → rebuild → blink.
    // Sekarang: data siap dulu, widget render sekali dalam kondisi final, lalu fade in mulus.
    _loadRememberMeThenAnimate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  /// Load remember-me data, update state, lalu baru mulai animasi fade-in.
  /// Ini mencegah blink/glitch yang terjadi ketika setState dari async dipanggil
  /// di tengah-tengah animasi yang sudah berjalan.
  Future<void> _loadRememberMeThenAnimate() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('admin_remember_me') ?? false;
    final savedUsername = remember ? (prefs.getString('admin_username') ?? '') : '';

    if (!mounted) return;

    // Update state sekali — widget render dalam kondisi final (data sudah ada)
    setState(() {
      _rememberMe = remember;
      if (remember) _usernameController.text = savedUsername;
    });

    // Baru setelah data siap, mulai animasi fade-in → tidak ada rebuild di tengah animasi
    _animationController.forward();
  }

  Future<void> _saveRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setBool('admin_remember_me', true);
      await prefs.setString('admin_username', _usernameController.text.trim());
    } else {
      await prefs.remove('admin_remember_me');
      await prefs.remove('admin_username');
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _notificationMessage = 'Please fill in all fields correctly';
        _isSuccess = false;
      });
      // Hilangkan notif setelah 3 detik
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _notificationMessage = null);
        }
      });
      return;
    }

    await _saveRememberMe();

    final provider = Provider.of<AdminProvider>(context, listen: false);

    final success = await provider.login(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      // ✅ LOGIN BERHASIL
      setState(() {
        _notificationMessage = 'Login Successful! Redirecting...';
        _isSuccess = true;
      });
      
      // Auto redirect setelah 3 detik
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const AdminDashboard(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 500),
            ),
          );
        }
      });
    } else {
      // ❌ LOGIN GAGAL
      setState(() {
        _notificationMessage = provider.errorMessage ?? 
            'Invalid username or password';
        _isSuccess = false;
      });
      
      // Hilangkan notif setelah 5 detik
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _notificationMessage = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsAdmin.landingBgLight,
      // ✅ FIX BLINK: Hapus SingleChildScrollView + SizedBox(height: screenHeight).
      // MediaQuery.size di web bisa berubah antara frame pertama dan kedua (scrollbar,
      // browser chrome, dll) → container resize → blink visual.
      // LayoutBuilder menggunakan constraint dari parent yang STABLE sejak frame pertama.
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Hitung ukuran dari constraint yang stable — bukan dari MediaQuery
          final containerWidth = constraints.maxWidth > 768
              ? 768.0
              : constraints.maxWidth * 0.9;
          final containerHeight = constraints.maxHeight > 500
              ? 500.0
              : constraints.maxHeight * 0.8;

          return Stack(
            fit: StackFit.expand,
            children: [
              // ── BACKGROUND FULL LAYAR ──────────────────────────────────
              Image.asset(
                AssetPaths.loginAdminBackground,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
              ),
              // Group Names (Top Left Corner) — kosong, dipertahankan strukturnya
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Main Container (Centered)
              Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SizedBox(
                    width: containerWidth,
                    height: containerHeight,
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 768,
                        maxHeight: 500,
                        minHeight: 400,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: AppColorsAdmin.landingCardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Row(
                          children: [
                            // LEFT SIDE: Login Form (50%)
                            Expanded(
                              child: _buildLoginForm(),
                            ),

                            // RIGHT SIDE: Logo Only (50%)
                            Expanded(
                              child: Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF87CEEB),
                                      Color(0xFF4A90E2),
                                      Color(0xFF1E90FF),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Image.asset(
                                    AssetPaths.logo,
                                    width: 250,
                                    height: 250,
                                    fit: BoxFit.contain,
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
        },
      ),
    );
  }

  /// ========================================================================
  /// LEFT SIDE: Login Form
  /// ========================================================================
  Widget _buildLoginForm() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ← NOTIFICATION TEXT (MUNCUL DI ATAS TITLE)
            if (_notificationMessage != null)
              AnimatedOpacity(
                opacity: _notificationMessage != null ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _isSuccess 
                        ? const Color(0xFF10B981).withOpacity(0.1) 
                        : const Color(0xFFEF4444).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSuccess 
                          ? const Color(0xFF10B981) 
                          : const Color(0xFFEF4444),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error,
                        color: _isSuccess 
                            ? const Color(0xFF10B981) 
                            : const Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _notificationMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _isSuccess 
                                ? const Color(0xFF10B981) 
                                : const Color(0xFFEF4444),
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Title
            const Text(
              'Login hire',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1.5,
                color: AppColorsAdmin.landingTextDark,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 30),

            // Username Input
            _buildInputField(
              controller: _usernameController,
              hintText: 'Username',
              nextFocusNode: _passwordFocusNode,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),

            // Password Input
            _buildInputField(
              controller: _passwordController,
              hintText: 'Password',
              isPassword: true,
              obscureText: _obscurePassword,
              focusNode: _passwordFocusNode,
              onFieldSubmitted: _handleLogin, // ✅ Enter di password = login
              onTogglePassword: () {
                setState(() {
                  _obscurePassword = !_obscurePassword;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Remember Me & Forgot Password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Remember Me Checkbox
                Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() => _rememberMe = value ?? false);
                        },
                        activeColor: AppColorsAdmin.landingPrimary,
                        checkColor: Colors.white,
                        side: MaterialStateBorderSide.resolveWith(
                          (states) => BorderSide(
                            color: states.contains(MaterialState.selected)
                                ? AppColorsAdmin.landingPrimary
                                : AppColorsAdmin.landingTextDark.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColorsAdmin.landingTextDark,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ],
                ),

                // Forgot Password Link
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      // Handle forgot password
                    },
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColorsAdmin.landingTextDark,
                        fontFamily: 'Poppins',
                      ),
                      child: const Text('Forgot Password'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),

            // Login Button
            Consumer<AdminProvider>(
              builder: (context, provider, _) {
                return MouseRegion(
                  onEnter: (_) => setState(() => _isButtonHovered = true),
                  onExit: (_) => setState(() => _isButtonHovered = false),
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isButtonPressed = true),
                    onTapUp: (_) => setState(() => _isButtonPressed = false),
                    onTapCancel: () => setState(() => _isButtonPressed = false),
                    child: AnimatedScale(
                      scale: _isButtonPressed ? 0.95 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: double.infinity,
                        height: 45,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColorsAdmin.landingPrimary,
                            width: 1,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: provider.isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColorsAdmin.landingButton,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                            padding: EdgeInsets.zero,
                          ),
                          child: provider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: _isButtonHovered ? 3.0 : 1.0,
                                    fontFamily: 'Poppins',
                                    color: Colors.white,
                                  ),
                                  child: const Text('Login'),
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ========================================================================
  /// HELPER WIDGETS
  /// ========================================================================
  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onTogglePassword,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,       // Tab → pindah ke field berikutnya
    VoidCallback? onFieldSubmitted,  // Enter → aksi custom (misal: login)
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: isPassword ? obscureText : false,
      // ✅ Tab ke field berikutnya jika ada, Enter untuk submit jika tidak ada next
      textInputAction: nextFocusNode != null
          ? TextInputAction.next
          : TextInputAction.done,
      onFieldSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          onFieldSubmitted?.call();
        }
      },
      style: const TextStyle(
        fontSize: 14,
        color: AppColorsAdmin.landingTextDark,
        fontFamily: 'Poppins',
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: AppColorsAdmin.landingTextDark.withOpacity(0.5),
          fontFamily: 'Poppins',
        ),
        filled: true,
        fillColor: AppColorsAdmin.landingInputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 12,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: AppColorsAdmin.landingTextDark.withOpacity(0.5),
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        errorStyle: const TextStyle(
          fontSize: 11,
          height: 0.8,
          fontFamily: 'Poppins',
        ),
        errorMaxLines: 1,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: validator,
    );
  }
}