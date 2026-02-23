// lib/core/responsive_mobile.dart
// ============================================================================
// RESPONSIVE_MOBILE.DART (VERSI FINAL - MOBILE FOCUS)
// - Untuk aplikasi mobile (HP kecil -> besar) dan tablet portrait/landscape.
// - Semua fungsi dijelaskan secara inline (bahasa Indonesia).
// - Tujuan: satu sumber kebenaran untuk semua aturan responsive UI/UX mobile.
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// ---------------------------------------------------------------------------
/// BREAKPOINTS MOBILE / TABLET
/// - Breakpoint adalah guideline; boleh disesuaikan project-wide via init.
/// - Urutannya: verySmallPhone < phone < largePhone < smallTablet < tablet
/// ---------------------------------------------------------------------------
class MobileBreakpoints {
  static const double verySmallPhone = 320;  // contoh: very old/compact phones
  static const double phone = 360;           // small phone (baseline)
  static const double largePhone = 412;      // typical large phones
  static const double smallTablet = 600;     // small tablets (portrait)
  static const double tablet = 840;          // larger tablets (portrait)
}

/// ---------------------------------------------------------------------------
/// CONFIG (boleh override via ResponsiveMobile.init jika perlu)
/// - designSize: ukuran design di Figma (default: 390x844 iPhone-like)
/// ---------------------------------------------------------------------------
class MobileResponsiveConfig {
  // Semua property harus final agar instance bisa const.
  final Size designSize;
  final bool minTextAdapt;
  final bool splitScreenMode;

  // Const constructor — wajib jika mau inisialisasi dengan `const`.
  const MobileResponsiveConfig({
    this.designSize = const Size(390, 844),
    this.minTextAdapt = true,
    this.splitScreenMode = true,
  });
}

/// ---------------------------------------------------------------------------
/// MAIN CLASS: ResponsiveMobile
/// - Semua helper static untuk UI/UX mobile ada di sini.
/// - Sediakan fungsi yang aman dipanggil dari mana saja (widget, services).
/// ---------------------------------------------------------------------------
class ResponsiveMobile {
  /// Internal config immutable (default). Bisa di-override lewat init() nanti.
  static MobileResponsiveConfig _config = const MobileResponsiveConfig();

  /// -------------------------------------------------------------------------
  /// INIT
  /// - Panggil sekali jika ingin mengubah designSize atau ScreenUtil behaviour.
  /// - Biasanya dipanggil di ScreenUtilInit.builder di main.dart; contoh di comment bawah.
  /// -------------------------------------------------------------------------
  static void init({MobileResponsiveConfig? config}) {
    // LAKUKAN INI JIKA PERLU override default config.
    if (config != null) {
      _config = config;
    }
  }

  /// -------------------------------------------------------------------------
  /// MAIN NOTES:
  /// - PASTIKAN ScreenUtilInit sudah dipanggil di root app (main.dart), contoh:
  /// ```
  /// ScreenUtilInit(
  ///   designSize: ResponsiveMobile._config.designSize,
  ///   minTextAdapt: ResponsiveMobile._config.minTextAdapt,
  ///   splitScreenMode: ResponsiveMobile._config.splitScreenMode,
  ///   builder: (context, child) {
  ///     // Optional: ResponsiveMobile.init(customConfig) jika perlu.
  ///     return MaterialApp(..., home: child);
  ///   },
  ///   child: const MyHomePage(),
  /// );
  /// ```
  /// - Setelah ScreenUtilInit, kamu bisa banyak panggil ResponsiveMobile.* di seluruh code.
  /// -------------------------------------------------------------------------

  /// -------------------------------------------------------------------------
  /// DEVICE TYPE DETECTION (mobile-focused)
  /// - Gunakan untuk memilih layout/ukuran/komponen berbeda.
  /// -------------------------------------------------------------------------
  static bool isVerySmallPhone(BuildContext context) {
    // Very small: width < 320
    final screenW = MediaQuery.of(context).size.width;
    return screenW < MobileBreakpoints.verySmallPhone;
  }

  static bool isPhone(BuildContext context) {
    // Phone: antara 320..359 (atau >= baseline small)
    final screenW = MediaQuery.of(context).size.width;
    return screenW >= MobileBreakpoints.verySmallPhone && screenW < MobileBreakpoints.phone;
  }

  static bool isStandardPhone(BuildContext context) {
    // Standard phone: 360..411
    final screenW = MediaQuery.of(context).size.width;
    return screenW >= MobileBreakpoints.phone && screenW < MobileBreakpoints.largePhone;
  }

  static bool isLargePhone(BuildContext context) {
    // Large phone: 412..599
    final screenW = MediaQuery.of(context).size.width;
    return screenW >= MobileBreakpoints.largePhone && screenW < MobileBreakpoints.smallTablet;
  }

  static bool isSmallTablet(BuildContext context) {
    // Small tablet: 600..839
    final screenW = MediaQuery.of(context).size.width;
    return screenW >= MobileBreakpoints.smallTablet && screenW < MobileBreakpoints.tablet;
  }

  static bool isTablet(BuildContext context) {
    // Tablet: width >= tablet breakpoint
    final screenW = MediaQuery.of(context).size.width;
    return screenW >= MobileBreakpoints.tablet;
  }

  static Orientation orientation(BuildContext context) {
    // Kembalikan orientation saat ini (portrait/landscape)
    return MediaQuery.of(context).orientation;
  }

  /// -------------------------------------------------------------------------
  /// RAW SCREEN DIMENSIONS
  /// - screenWidth/logical pixels dan screenHeight
  /// - devicePixelRatio berguna untuk memilih asset jika ingin manual
  /// -------------------------------------------------------------------------
  static double screenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  static double screenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  static double devicePixelRatio(BuildContext context) => MediaQuery.of(context).devicePixelRatio;

  /// -------------------------------------------------------------------------
  /// PERCENTAGE HELPERS (recommended)
  /// - wp(context, 50) => 50% dari lebar layar (recommended untuk responsive)
  /// - hp(context, 30) => 30% dari tinggi layar
  /// -------------------------------------------------------------------------
  static double wp(BuildContext context, double percent) {
    // Pastikan percent antara 0..100 agar predictable
    assert(percent >= 0 && percent <= 100, 'wp: percent harus antara 0 dan 100');
    return screenWidth(context) * (percent / 100);
  }

  static double hp(BuildContext context, double percent) {
    assert(percent >= 0 && percent <= 100, 'hp: percent harus antara 0 dan 100');
    return screenHeight(context) * (percent / 100);
  }

  /// -------------------------------------------------------------------------
  /// SCREENUTIL SCALED HELPERS (safe wrappers)
  /// - Gunakan bila project pakai flutter_screenutil.
  /// - Jangan buat variabel global bernama `w` / `h` karena bentrok dengan extensions.
  /// - Fungsi ini hanya "alias" yang aman dan jelas.
  /// -------------------------------------------------------------------------
  static double scaledW(double size) => size.w; // lebar di designScale -> scaled
  static double scaledH(double size) => size.h; // tinggi di designScale -> scaled
  static double scaledFont(double size) => size.sp;
  static double scaledSP(double size) => size.sp; // font scaled
  static double scaledR(double size) => size.r; // radius scaled

  /// -------------------------------------------------------------------------
  /// SAFE AREA HELPERS
  /// - Mempermudah menambahkan padding agar UI tidak tertutup notch/gesture bar.
  /// -------------------------------------------------------------------------
  static double topSafeArea(BuildContext context) => MediaQuery.of(context).padding.top;
  static double bottomSafeArea(BuildContext context) => MediaQuery.of(context).padding.bottom;
  static double leftSafeArea(BuildContext context) => MediaQuery.of(context).padding.left;
  static double rightSafeArea(BuildContext context) => MediaQuery.of(context).padding.right;

  /// -------------------------------------------------------------------------
  /// TEXT & ACCESSIBILITY
  /// - adjustedFontSize menghormati user textScaleFactor tetapi membatasi growth
  /// - agar UX tetap terjaga (tidak putus/overflow). Batasi di 1.8x default.
  /// -------------------------------------------------------------------------
  static double adjustedFontSize(BuildContext context, double designFontSize, {double maxScale = 1.8}) {
    // designFontSize diasumsikan dalam design pixels (mis. 14/16/20)
    // 1) scale via ScreenUtil.sp
    final double scaled = scaledSP(designFontSize);
    // 2) ambil textScaleFactor user
    final double tsf = MediaQuery.of(context).textScaleFactor;
    // 3) batasi agar tidak ekstrem (UX perusahaan biasanya batasi)
    final double applied = tsf.clamp(1.0, maxScale);
    return scaled * applied;
  }

  /// Convenience text sizes (gunakan ini agar konsisten)
  static double titleSize(BuildContext context) => adjustedFontSize(context, 20);
  static double subtitleSize(BuildContext context) => adjustedFontSize(context, 16);
  static double bodySize(BuildContext context) => adjustedFontSize(context, 14);
  static double captionSize(BuildContext context) => adjustedFontSize(context, 12);

  /// -------------------------------------------------------------------------
  /// TOUCH TARGET / TAP SIZE (UX)
  /// - Standar UX: minimal 44–48 px touch target (Apple/Material)
  /// - Kita sediakan helper agar tombol tidak terlalu kecil pada device kecil.
  /// -------------------------------------------------------------------------
  static double minTouchTargetSize(BuildContext context) {
    // Gunakan scaled value untuk respect device DPI; gunakan min 44 logical pixels.
    final base = 48.0;
    // skala sedikit berdasarkan device width: pada very small phones biarkan 44
    final screenW = screenWidth(context);
    if (screenW < MobileBreakpoints.phone) return 44.0;
    if (screenW < MobileBreakpoints.largePhone) return 46.0;
    return base; // >= largePhone -> 48
  }

  /// -------------------------------------------------------------------------
  /// IMAGE/ASSET GUIDANCE
  /// - Rekomendasi: sediakan 1x/2x/3x di folder assets (Flutter otomatis pilih).
  /// - Jika punya naming custom, gunakan chooseAssetVariant() untuk manual.
  /// -------------------------------------------------------------------------
  static String chooseAssetVariant(BuildContext context, {
    required String baseName,
    required Map<String, String> variants, // e.g. {'1x': 'hero_1x.png', '2x': 'hero_2x.png'}
  }) {
    final dpr = devicePixelRatio(context);
    if (dpr >= 3 && variants.containsKey('3x')) return variants['3x']!;
    if (dpr >= 2 && variants.containsKey('2x')) return variants['2x']!;
    return variants['1x'] ?? variants.values.first;
  }

  /// -------------------------------------------------------------------------
  /// LAYOUT HELPERS (widget selection)
  /// - ResponsiveWidget: pilih widget sesuai device type (phone/tablet)
  /// - builder: LayoutBuilder based (lebih kuat untuk decisions by constraints)
  /// -------------------------------------------------------------------------
  static Widget responsiveWidget({
    required BuildContext context,
    required Widget phone,            // widget untuk phone / small devices
    Widget? largePhone,               // optional widget untuk large phones
    Widget? tablet,                   // optional widget untuk tablet
  }) {
    // Pilih berdasarkan urutan fallback: tablet -> largePhone -> phone
    if (isTablet(context)) return tablet ?? largePhone ?? phone;
    if (isLargePhone(context)) return largePhone ?? phone;
    return phone;
  }

  static Widget responsiveBuilder({
    required BuildContext context,
    required Widget Function(BuildContext c, BoxConstraints cons) phone,
    Widget Function(BuildContext c, BoxConstraints cons)? largePhone,
    Widget Function(BuildContext c, BoxConstraints cons)? tablet,
  }) {
    // Menggunakan LayoutBuilder agar kita bisa memutuskan by constraints (parent width)
    return LayoutBuilder(
      builder: (c, cons) {
        final parentWidth = cons.maxWidth;
        if (parentWidth >= MobileBreakpoints.tablet) {
          return tablet != null ? tablet(c, cons) : (largePhone != null ? largePhone(c, cons) : phone(c, cons));
        }
        if (parentWidth >= MobileBreakpoints.largePhone) {
          return largePhone != null ? largePhone(c, cons) : phone(c, cons);
        }
        return phone(c, cons);
      },
    );
  }

  /// -------------------------------------------------------------------------
  /// SPACING / PADDING HELPERS (konversi berdasarkan screen width / scale)
  /// - Gunakan fungsi ini agar spacing konsisten di seluruh project.
  /// -------------------------------------------------------------------------
  static EdgeInsets horizontalPadding(BuildContext context, double percentWidth) {
    // percentWidth: persen dari screenWidth (0..100)
    final px = wp(context, percentWidth);
    return EdgeInsets.symmetric(horizontal: px);
  }

  static EdgeInsets verticalPadding(BuildContext context, double percentHeight) {
    final py = hp(context, percentHeight);
    return EdgeInsets.symmetric(vertical: py);
  }

  static EdgeInsets allScaledPadding(double designPx) {
    // gunakan ScreenUtil.r untuk scaling radius/spacing
    return EdgeInsets.all(scaledR(designPx));
  }

  static Widget hSpace(double designPx) => SizedBox(width: scaledW(designPx));
  static Widget vSpace(double designPx) => SizedBox(height: scaledH(designPx));

  /// -------------------------------------------------------------------------
  /// COMMON PATTERNS / EXAMPLES
  /// - Sediakan contoh real usage supaya mudah copy-paste.
  /// -------------------------------------------------------------------------
  ///
  /// Example A: responsive login card width
  static double loginCardWidth(BuildContext context) {
    // Pada phone: full-width minus padding; pada tablet: batasi max width (mis. 480-600)
    final screenW = screenWidth(context);
    if (screenW >= MobileBreakpoints.tablet) return 560; // max width pada tablet
    // pada phone gunakan 88% lebar layar sebagai contoh
    return wp(context, 88);
  }

  /// Example B: hero image height (proporsional)
  static double heroImageHeight(BuildContext context) {
    // gunakan persentase tinggi layar, tapi batasi min/max
    final hPercent = isTablet(context) ? 40.0 : 28.0; // tablet lebih tinggi hero
    final computed = hp(context, hPercent);
    // batasi agar tidak terlalu kecil/besar
    return computed.clamp(160.0, 520.0);
  }

  /// -------------------------------------------------------------------------
  /// TESTING CHECKLIST UTILITY (string list) — untuk developer / QA
  /// - Bantu QA untuk mengecek layout di device-size umum tanpa menebak.
  /// -------------------------------------------------------------------------
  static List<String> testingChecklist() {
    return [
      'Very small phone (320x568) - single column',
      'Small phone (360x780) - baseline',
      'Large phone (412x915) - large handset',
      'Small tablet portrait (600x1024)',
      'Tablet landscape (840x1112)',
      'Orientation change (portrait <-> landscape)',
      'High text scale (textScaleFactor 1.4 - 1.8)',
      'Devices with notch / gesture bar (safe area)',
      'Low DPI vs high DPI (asset variant check)',
    ];
  }

  /// -------------------------------------------------------------------------
  /// USAGE CHEAT-SHEET (komentar pendek, gampang di copy)
  /// -------------------------------------------------------------------------
  /// - Percentage width:
  ///    Container(width: ResponsiveMobile.wp(context, 80))
  ///
  /// - Scaled size (design px -> scaled):
  ///    Container(width: ResponsiveMobile.scaledW(200))
  ///
  /// - Font that respects accessibility:
  ///    Text('Hello', style: TextStyle(fontSize: ResponsiveMobile.adjustedFontSize(context, 16)))
  ///
  /// - Responsive widget:
  ///    ResponsiveMobile.responsiveWidget(context: context, phone: MobileView(), tablet: TabletView())
  ///
  /// - Padding horizontal 6%:
  ///    Padding(padding: ResponsiveMobile.horizontalPadding(context, 6))
  ///
  /// -------------------------------------------------------------------------
}

/// ============================================================================
/// EXTRA: QUICK EXAMPLE - Responsive Login Page (KODE CONTOH, copy-paste)
/// - Ini contoh bagaimana pakai fungsi-fungsi di atas untuk membuat login page
/// - Bukan sempurna UI, tapi blueprint responsive + UX-friendly.
/// ============================================================================

/*

class ResponsiveLoginExample extends StatelessWidget {
  const ResponsiveLoginExample({super.key});

  @override
  Widget build(BuildContext context) {
    // contoh: card lebar responsif
    final cardW = ResponsiveMobile.loginCardWidth(context);
    final heroH = ResponsiveMobile.heroImageHeight(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: ResponsiveMobile.horizontalPadding(context, 4), // 4% horizontal padding
            child: Column(
              children: [
                SizedBox(height: 24.h),
                // hero image responsive
                SizedBox(
                  height: heroH,
                  child: Image.asset('assets/images/hero.png', fit: BoxFit.contain),
                ),
                SizedBox(height: 18.h),
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: cardW),
                    child: Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text('Welcome Back', style: TextStyle(fontSize: ResponsiveMobile.titleSize(context), fontWeight: FontWeight.bold)),
                            SizedBox(height: 12.h),
                            TextField(decoration: InputDecoration(labelText: 'Email')),
                            SizedBox(height: 12.h),
                            TextField(obscureText: true, decoration: InputDecoration(labelText: 'Password')),
                            SizedBox(height: 18.h),
                            SizedBox(
                              height: ResponsiveMobile.minTouchTargetSize(context),
                              child: ElevatedButton(onPressed: (){}, child: Text('Sign In', style: TextStyle(fontSize: ResponsiveMobile.bodySize(context)))),
                            ),
                            SizedBox(height: 12.h),
                            Row(
                              children: [
                                Expanded(child: OutlinedButton(onPressed: (){}, child: Text('Google'))),
                                SizedBox(width: 8.w),
                                Expanded(child: OutlinedButton(onPressed: (){}, child: Text('Apple'))),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

*/ 

// ============================================================================
// END OF FILE
// ============================================================================

