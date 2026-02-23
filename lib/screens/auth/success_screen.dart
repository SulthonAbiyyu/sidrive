import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'dart:async';
import 'dart:math' as math;

// ============================================================================
// SUCCESS SCREEN - ✅ FIXED! SESUAI FLOW BARU
// Flow: Register → Upload Dokumen (untuk driver/umkm) → Dashboard
// User bisa masuk dashboard meskipun pending, tapi tidak bisa terima order
// ============================================================================
class SuccessScreen extends StatefulWidget {
  final List<String> roles;

  const SuccessScreen({
    super.key,
    required this.roles,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  Timer? _redirectTimer;
  int _countdown = 5;

  late AnimationController _iconController;
  late AnimationController _contentController;
  late AnimationController _pulseController;

  late Animation<double> _iconScaleAnim;
  late Animation<double> _iconOpacityAnim;
  late Animation<Offset> _contentSlideAnim;
  late Animation<double> _contentFadeAnim;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startRedirectTimer();
  }

  void _setupAnimations() {
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _iconScaleAnim = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    _iconOpacityAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: const Interval(0, 0.4)),
    );

    _contentSlideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    _contentFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _iconController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _contentController.forward();
    });
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _iconController.dispose();
    _contentController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startRedirectTimer() {
    // ✅ LOGIC BARU: SEMUA ROLE LANGSUNG KE DASHBOARD
    // Customer langsung aktif, Driver/UMKM pending tapi tetap bisa masuk dashboard

    _redirectTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;

    _redirectTimer?.cancel();

    // ✅ FIX: Gunakan helper untuk konsistensi priority
    String route;

    if (widget.roles.contains('customer')) {
      route = '/customer/dashboard';
    } else if (widget.roles.contains('driver')) {
      route = '/driver/dashboard';
    } else if (widget.roles.contains('umkm')) {
      route = '/umkm/dashboard';
    } else {
      route = '/login'; // Fallback
    }

    // ✅ FIX: Tambahkan error handling untuk navigation
    try {
      Navigator.pushNamedAndRemoveUntil(
        context,
        route,
        (route) => false,
      );
    } catch (e) {
      debugPrint('❌ Error navigating to $route: $e');
      // Fallback ke login kalau route error
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  void _skipCountdown() {
    _redirectTimer?.cancel();
    _navigateToDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final screenH = ResponsiveMobile.screenHeight(context);
    final isSmall = ResponsiveMobile.isVerySmallPhone(context) ||
        ResponsiveMobile.isPhone(context);

    // Cek apakah ada driver atau umkm (perlu upload dokumen)
    final hasDriverOrUmkm =
        widget.roles.contains('driver') || widget.roles.contains('umkm');
    final hasCustomer = widget.roles.contains('customer');

    // Tentukan pesan berdasarkan kombinasi role
    String message;
    String subtitle;
    IconData icon;
    bool isPending;

    if (hasCustomer && !hasDriverOrUmkm) {
      // ✅ HANYA CUSTOMER
      message = 'Selamat Bergabung!';
      subtitle = 'Akun Customer kamu sudah aktif\ndan siap digunakan sekarang!';
      icon = Icons.check_circle_rounded;
      isPending = false;
    } else if (hasDriverOrUmkm) {
      // ✅ ADA DRIVER/UMKM (bisa kombinasi dengan customer)
      message = 'Pendaftaran Berhasil!';

      // Build subtitle dinamis
      List<String> pendingRoles = [];
      if (widget.roles.contains('driver')) pendingRoles.add('Driver');
      if (widget.roles.contains('umkm')) pendingRoles.add('UMKM');

      String rolesText = pendingRoles.join(' & ');

      if (hasCustomer) {
        subtitle =
            'Role Customer sudah aktif!\nUpload dokumen $rolesText di Profile\nuntuk aktivasi penuh.';
      } else {
        subtitle =
            'Upload dokumen $rolesText di Profile\nuntuk mengaktifkan akun kamu.';
      }

      icon = Icons.upload_file_rounded;
      isPending = true;
    } else {
      // Default (seharusnya tidak pernah terjadi)
      message = 'Pendaftaran Berhasil!';
      subtitle = 'Role: ${widget.roles.join(", ").toUpperCase()}';
      icon = Icons.check_circle_rounded;
      isPending = false;
    }

    // Color palette
    final primaryColor = isPending
        ? const Color(0xFFFF8C42)
        : const Color(0xFF4CAF82);
    final primaryLight = isPending
        ? const Color(0xFFFFB27A)
        : const Color(0xFF74D4A6);
    final gradientEnd = const Color(0xFFF7F8FC);

    return Scaffold(
      backgroundColor: gradientEnd,
      body: Stack(
        children: [
          // ── Background gradient blobs ──
          Positioned(
            top: -screenH * 0.08,
            right: -60.w,
            child: _GradientBlob(color: primaryLight, size: 260.r),
          ),
          Positioned(
            top: screenH * 0.12,
            left: -80.w,
            child: _GradientBlob(
              color: primaryLight.withOpacity(0.35),
              size: 200.r,
            ),
          ),
          Positioned(
            bottom: -40.h,
            right: -30.w,
            child: _GradientBlob(
              color: primaryColor.withOpacity(0.12),
              size: 180.r,
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: ResponsiveMobile.wp(context, 6),
                vertical: isSmall ? 16.h : 24.h,
              ),
              child: Column(
                children: [
                  SizedBox(height: isSmall ? 20.h : screenH * 0.04),

                  // ── Animated Icon Section ──
                  ScaleTransition(
                    scale: _iconScaleAnim,
                    child: FadeTransition(
                      opacity: _iconOpacityAnim,
                      child: _IconHero(
                        icon: icon,
                        primaryColor: primaryColor,
                        primaryLight: primaryLight,
                        pulseAnim: _pulseAnim,
                        isPending: isPending,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 24.h : 32.h),

                  // ── Title & Subtitle ──
                  SlideTransition(
                    position: _contentSlideAnim,
                    child: FadeTransition(
                      opacity: _contentFadeAnim,
                      child: Column(
                        children: [
                          Text(
                            message,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.titleSize(context) + 4,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A1D2E),
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 10.h),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: ResponsiveMobile.bodySize(context),
                              color: const Color(0xFF6B7280),
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 20.h : 28.h),

                  // ── Role Cards ──
                  SlideTransition(
                    position: _contentSlideAnim,
                    child: FadeTransition(
                      opacity: _contentFadeAnim,
                      child: _RoleCardsSection(
                        roles: widget.roles,
                        primaryColor: primaryColor,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 16.h : 24.h),

                  // ── Countdown Timer ──
                  SlideTransition(
                    position: _contentSlideAnim,
                    child: FadeTransition(
                      opacity: _contentFadeAnim,
                      child: _CountdownCard(
                        countdown: _countdown,
                        hasDriverOrUmkm: hasDriverOrUmkm,
                        primaryColor: primaryColor,
                        totalSeconds: 5,
                      ),
                    ),
                  ),

                  SizedBox(height: isSmall ? 16.h : 20.h),

                  // ── CTA Button ──
                  SlideTransition(
                    position: _contentSlideAnim,
                    child: FadeTransition(
                      opacity: _contentFadeAnim,
                      child: _DashboardButton(
                        onPressed: _skipCountdown,
                        primaryColor: primaryColor,
                        primaryLight: primaryLight,
                        context: context,
                      ),
                    ),
                  ),

                  // ── Warning for driver/umkm ──
                  if (hasDriverOrUmkm) ...[
                    SizedBox(height: 14.h),
                    SlideTransition(
                      position: _contentSlideAnim,
                      child: FadeTransition(
                        opacity: _contentFadeAnim,
                        child: _WarningNote(context: context),
                      ),
                    ),
                  ],

                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ICON HERO WIDGET
// ============================================================================
class _IconHero extends StatelessWidget {
  final IconData icon;
  final Color primaryColor;
  final Color primaryLight;
  final Animation<double> pulseAnim;
  final bool isPending;

  const _IconHero({
    required this.icon,
    required this.primaryColor,
    required this.primaryLight,
    required this.pulseAnim,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    final size = ResponsiveMobile.isTablet(context) ? 140.r : 110.r;

    return ScaleTransition(
      scale: pulseAnim,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: size + 40.r,
            height: size + 40.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.08),
            ),
          ),
          // Middle ring
          Container(
            width: size + 16.r,
            height: size + 16.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryColor.withOpacity(0.14),
            ),
          ),
          // Inner circle (gradient)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [primaryLight, primaryColor],
                center: Alignment.topLeft,
                radius: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 24.r,
                  offset: Offset(0, 10.h),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: size * 0.48,
              color: Colors.white,
            ),
          ),
          // Decorative sparkle dots
          ..._buildSparkles(size, primaryColor),
        ],
      ),
    );
  }

  List<Widget> _buildSparkles(double size, Color color) {
    final positions = [
      {'angle': -0.6, 'r': size * 0.72, 'sz': 8.0},
      {'angle': 0.9, 'r': size * 0.68, 'sz': 6.0},
      {'angle': 2.4, 'r': size * 0.75, 'sz': 9.0},
      {'angle': -2.1, 'r': size * 0.70, 'sz': 5.0},
    ];

    return positions.map((p) {
      final angle = p['angle'] as double;
      final radius = p['r'] as double;
      final sz = p['sz'] as double;
      return Transform.translate(
        offset: Offset(
          math.cos(angle) * radius,
          math.sin(angle) * radius,
        ),
        child: Container(
          width: sz,
          height: sz,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.6),
          ),
        ),
      );
    }).toList();
  }
}

// ============================================================================
// ROLE CARDS SECTION
// ============================================================================
class _RoleCardsSection extends StatelessWidget {
  final List<String> roles;
  final Color primaryColor;

  const _RoleCardsSection({
    required this.roles,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.w,
                height: 18.h,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Role Terdaftar',
                style: TextStyle(
                  fontSize: ResponsiveMobile.subtitleSize(context) - 1,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1D2E),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          ...roles.asMap().entries.map((entry) {
            final i = entry.key;
            final role = entry.value;
            return Column(
              children: [
                _RoleItem(role: role, primaryColor: primaryColor),
                if (i < roles.length - 1)
                  Divider(
                    height: 16.h,
                    color: const Color(0xFFF0F0F5),
                  ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

class _RoleItem extends StatelessWidget {
  final String role;
  final Color primaryColor;

  const _RoleItem({required this.role, required this.primaryColor});

  @override
  Widget build(BuildContext context) {
    IconData roleIcon;
    String roleLabel;
    String roleStatus;
    Color statusBg;
    Color statusText;
    Color iconBg;

    switch (role) {
      case 'customer':
        roleIcon = Icons.person_rounded;
        roleLabel = 'Customer';
        roleStatus = 'Aktif';
        statusBg = const Color(0xFFE8F8F0);
        statusText = const Color(0xFF1B9E5E);
        iconBg = const Color(0xFFE8F8F0);
        break;
      case 'driver':
        roleIcon = Icons.motorcycle_rounded;
        roleLabel = 'Driver';
        roleStatus = 'Perlu Dokumen';
        statusBg = const Color(0xFFFFF3E5);
        statusText = const Color(0xFFD4700A);
        iconBg = const Color(0xFFFFF3E5);
        break;
      case 'umkm':
        roleIcon = Icons.storefront_rounded;
        roleLabel = 'UMKM';
        roleStatus = 'Perlu Dokumen';
        statusBg = const Color(0xFFFFF3E5);
        statusText = const Color(0xFFD4700A);
        iconBg = const Color(0xFFFFF3E5);
        break;
      default:
        roleIcon = Icons.account_circle_rounded;
        roleLabel = role;
        roleStatus = '-';
        statusBg = const Color(0xFFF0F0F5);
        statusText = const Color(0xFF6B7280);
        iconBg = const Color(0xFFF0F0F5);
    }

    return Row(
      children: [
        Container(
          width: 42.r,
          height: 42.r,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(roleIcon, size: 22.sp, color: statusText),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(
            roleLabel,
            style: TextStyle(
              fontSize: ResponsiveMobile.bodySize(context),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1D2E),
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            roleStatus,
            style: TextStyle(
              fontSize: ResponsiveMobile.captionSize(context),
              fontWeight: FontWeight.w700,
              color: statusText,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// COUNTDOWN CARD
// ============================================================================
class _CountdownCard extends StatelessWidget {
  final int countdown;
  final bool hasDriverOrUmkm;
  final Color primaryColor;
  final int totalSeconds;

  const _CountdownCard({
    required this.countdown,
    required this.hasDriverOrUmkm,
    required this.primaryColor,
    required this.totalSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = countdown / totalSeconds;
    final subText = hasDriverOrUmkm
        ? 'Kamu tetap bisa masuk dashboard. Upload dokumen di Profile ya!'
        : 'Akun kamu sudah siap — selamat menikmati!';

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular countdown
          SizedBox(
            width: 52.r,
            height: 52.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 52.r,
                  height: 52.r,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 3.5,
                    backgroundColor: primaryColor.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation(primaryColor),
                  ),
                ),
                Text(
                  '$countdown',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.subtitleSize(context),
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menuju Dashboard...',
                  style: TextStyle(
                    fontSize: ResponsiveMobile.bodySize(context),
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1D2E),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subText,
                  style: TextStyle(
                    fontSize: ResponsiveMobile.captionSize(context),
                    color: const Color(0xFF6B7280),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// DASHBOARD BUTTON
// ============================================================================
class _DashboardButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Color primaryColor;
  final Color primaryLight;
  final BuildContext context;

  const _DashboardButton({
    required this.onPressed,
    required this.primaryColor,
    required this.primaryLight,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: ResponsiveMobile.minTouchTargetSize(context) + 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryLight, primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.38),
              blurRadius: 16.r,
              offset: Offset(0, 6.h),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ke Dashboard',
                style: TextStyle(
                  fontSize: ResponsiveMobile.subtitleSize(context),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 8.w),
              const Icon(Icons.arrow_forward_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// WARNING NOTE
// ============================================================================
class _WarningNote extends StatelessWidget {
  final BuildContext context;

  const _WarningNote({required this.context});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFFBD38D), width: 1),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: const Color(0xFFD97706),
            size: 18.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Kamu belum bisa terima order sebelum dokumen diverifikasi admin.',
              style: TextStyle(
                fontSize: ResponsiveMobile.captionSize(context),
                color: const Color(0xFF92400E),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// GRADIENT BLOB (decorative background element)
// ============================================================================
class _GradientBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GradientBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.45),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}