import 'package:flutter/material.dart';

class AdminBreakpoints {
  static const double tablet = 1024;
  static const double laptop = 1366;
  static const double desktop = 1920;
}

class ResponsiveAdmin {
  // ============================================================================
  // DEVICE DETECTION (Desktop fokus)
  // ============================================================================
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AdminBreakpoints.tablet && width < AdminBreakpoints.laptop;
  }
  
  static bool isLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AdminBreakpoints.laptop && width < AdminBreakpoints.desktop;
  }
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= AdminBreakpoints.desktop;
  
  // ============================================================================
  // LAYOUT DIMENSIONS (Fixed sizes for desktop)
  // ============================================================================
  
  /// Sidebar width - Fixed 280px seperti di gambar
  static double sidebarWidth(BuildContext context) => 280;
  
  /// Page padding - Fixed 32px
  static EdgeInsets pagePadding(BuildContext context) => const EdgeInsets.all(32);
  
  /// Card padding
  static EdgeInsets cardPadding(BuildContext context) => const EdgeInsets.all(24);
  
  /// Section spacing
  static double sectionSpacing() => 24;
  
  // ============================================================================
  // GRID SYSTEM (Sesuai layout gambar)
  // ============================================================================
  
  /// Main content width ratio
  static double mainContentFlex() => 0.65; // 65% untuk konten utama
  static double sideContentFlex() => 0.35; // 35% untuk sidebar kanan
  
  // ============================================================================
  // SPACING (Fixed values)
  // ============================================================================
  static double spaceXS() => 4;
  static double spaceSM() => 8;
  static double spaceMD() => 16;
  static double spaceLG() => 24;
  static double spaceXL() => 32;
  static double space2XL() => 48;
  
  // ============================================================================
  // TYPOGRAPHY (Fixed sizes)
  // ============================================================================
  static double fontH1() => 32;
  static double fontH2() => 24;
  static double fontH3() => 20;
  static double fontH4() => 18;
  static double fontBody() => 14;
  static double fontCaption() => 12;
  static double fontSmall() => 11;
  
  // ============================================================================
  // BORDER RADIUS
  // ============================================================================
  static double radiusSM() => 8;
  static double radiusMD() => 12;
  static double radiusLG() => 16;
  static double radiusXL() => 24;
  
  // ============================================================================
  // SHADOWS
  // ============================================================================
  static List<BoxShadow> shadowSM(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMD(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLG(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.16),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}