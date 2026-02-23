// ============================================================================
// SPLASH_SCREEN.DART (RESPONSIVE: Mobile Vertical, Web Horizontal)
// ✅ FIX: Improved session check - tidak double-init AuthProvider
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:sidrive/app_config.dart';
import 'package:sidrive/config/constants.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/providers/auth_provider.dart';
import 'package:sidrive/services/storage_service.dart';
import 'package:sidrive/services/session_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> 
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Fade-in + Scale animation
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();

    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(
      const Duration(milliseconds: AppConstants.splashDuration),
    );

    if (!mounted) return;

    // ============================================================
    // ADMIN → langsung ke admin login
    // ============================================================
    if (AppConfig.isAdmin) {
      Navigator.pushReplacementNamed(context, "/admin/login");
      return;
    }

    // ============================================================
    // CLIENT MODE
    // ============================================================
    final isFirstTime = StorageService.isFirstTime();

    // ✅ FIX: Ambil authProvider tapi JANGAN panggil init() lagi
    // init() sudah dipanggil di app.dart saat AuthProvider dibuat.
    // Memanggil ulang bisa menyebabkan race condition (dua proses
    // berlomba mengambil data, hasilnya tidak bisa diprediksi).
    final authProvider = context.read<AuthProvider>();

    // ✅ FIX: Jika AuthProvider sudah punya user (init() dari app.dart sudah selesai)
    // langsung pakai. Jika belum, tunggu dulu dengan init() sekali saja.
    if (!authProvider.isLoggedIn) {
      // Provider belum selesai load — mungkin karena async yang belum selesai.
      // Coba restore session dulu sebagai jaring pengaman.
      debugPrint('🔄 [SplashScreen] AuthProvider belum login, coba restore session...');
      
      final sessionRestored = await SessionService.restoreSession();
      
      if (sessionRestored) {
        // Session berhasil di-restore, load user data
        debugPrint('✅ [SplashScreen] Session restored, loading user data...');
        await authProvider.init();
      }
    } else {
      debugPrint('✅ [SplashScreen] AuthProvider sudah punya user, skip init()');
    }

    if (!mounted) return;

    // ✅ Kalau first time → onboarding
    if (isFirstTime) {
      Navigator.pushReplacementNamed(context, '/onboarding');
      return;
    }

    // ✅ Kalau sudah login → ke dashboard sesuai role
    if (authProvider.isLoggedIn) {
      final role = authProvider.activeRole ?? authProvider.currentUser?.role ?? 'customer';
      
      debugPrint('✅ [SplashScreen] User sudah login, role: $role');
      
      String dashboardRoute;
      switch (role) {
        case 'driver':
          dashboardRoute = '/driver/dashboard';
          break;
        case 'umkm':
          dashboardRoute = '/umkm/dashboard';
          break;
        default:
          dashboardRoute = '/customer/dashboard';
      }
      
      Navigator.pushReplacementNamed(context, dashboardRoute);
    } else {
      // ✅ Kalau belum login → welcome screen
      debugPrint('ℹ️ [SplashScreen] User belum login, ke welcome screen');
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ========================================================================
  // WIDGET BUILD
  // ========================================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ================================================================
            // BACKGROUND IMAGE (Responsive orientation)
            // ================================================================
            kIsWeb
                ? _buildWebBackground()
                : _buildMobileBackground(),

            // ================================================================
            // CENTER LOGO (Animated)
            // ================================================================
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Image.asset(
                  "assets/images/splash/logo.png",
                  width: kIsWeb 
                      ? 200  // Web: lebih besar
                      : ResponsiveMobile.scaledW(160),  // Mobile
                  height: kIsWeb 
                      ? 200 
                      : ResponsiveMobile.scaledH(160),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // MOBILE BACKGROUND (Vertical/Portrait)
  // ============================================================================
  Widget _buildMobileBackground() {
    return Image.asset(
      "assets/images/splash/bgsplash.png",
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  // ============================================================================
  // WEB BACKGROUND (Horizontal/Landscape)
  // ============================================================================
  Widget _buildWebBackground() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/splash/bgsplash.png"),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
    );
  }
}