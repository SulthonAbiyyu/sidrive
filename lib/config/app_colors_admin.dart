import 'package:flutter/material.dart';

/// Modern Admin Color Palette - Inspired by Modern Dashboards
class AppColorsAdmin {
  // ============================================================================
  // PRIMARY COLORS (Purple Theme - Modern & Professional)
  // ============================================================================
  static const Color primaryPurple = Color(0xFF6C5CE7);
  static const Color primaryPurpleDark = Color(0xFF5F3DC4);
  static const Color primaryPurpleLight = Color(0xFF9B8FFF);
  
  // ============================================================================
  // LANDING PAGE COLORS (dari React CSS)
  // ============================================================================
  static const Color landingPrimary = Color(0xFF4BB6B7);      // dari CSS: #4bb6b7
  static const Color landingButton = Color(0xB31204D4);       // dari CSS: #1204d4b1
  static const Color landingBgLight = Color(0xFFF6F5F7);      // dari CSS: #f6f5f7
  static const Color landingInputBg = Color(0xFFEEEEEE);      // dari CSS: #eee
  static const Color landingTextDark = Color(0xFF333333);     // dari CSS: #333
  static const Color landingBorderLight = Color(0xFFDDDDDD);  // dari CSS: #ddd
  
  // Gradient untuk overlay (dari CSS linear-gradient)
  static const LinearGradient landingOverlayGradient = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0x662E5E6D),  // rgba(46, 94, 109, 0.4)
      Color(0x002E5E6D),  // rgba(46, 94, 109, 0)
    ],
    stops: [0.4, 1.0],
  );
  
  // Ghost button background
  static const Color ghostButtonBg = Color(0x33E1E1E1);  // rgba(225, 225, 225, 0.2)
  
  // ============================================================================
  // ACCENT COLORS (Vibrant & Energetic)
  // ============================================================================
  static const Color accentOrange = Color(0xFFFF8A5C);
  static const Color accentBlue = Color(0xFF5C9FFF);
  static const Color accentGreen = Color(0xFF51CF66);
  static const Color accentYellow = Color(0xFFFFD93D);
  static const Color accentPink = Color(0xFFFF6B9D);
  
  // ============================================================================
  // GRADIENT COLORS
  // ============================================================================
  static const LinearGradient purpleGradient = LinearGradient(
    colors: [primaryPurple, primaryPurpleLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient orangeGradient = LinearGradient(
    colors: [Color(0xFFFF8A5C), Color(0xFFFFB088)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF5C9FFF), Color(0xFF88B3FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF51CF66), Color(0xFF7FDD8F)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // ============================================================================
  // BACKGROUND COLORS
  // ============================================================================
  static const Color bgLight = Color(0xFFF8F9FC);
  static const Color bgDark = Color(0xFF1A1D2E);
  
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF252837);
  
  // ============================================================================
  // TEXT COLORS
  // ============================================================================
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  static const Color textTertiary = Color(0xFFA0AEC0);
  
  static const Color textPrimaryDark = Color(0xFFE2E8F0);
  static const Color textSecondaryDark = Color(0xFFA0AEC0);
  
  // ============================================================================
  // STATUS COLORS
  // ============================================================================
  static const Color success = Color(0xFF51CF66);
  static const Color warning = Color(0xFFFFB020);
  static const Color error = Color(0xFFFF6B6B);
  static const Color info = Color(0xFF5C9FFF);
  
  // ============================================================================
  // BORDER & DIVIDER
  // ============================================================================
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF3A3F5C);
  
  static const Color dividerLight = Color(0xFFEDF2F7);
  static const Color dividerDark = Color(0xFF2D3748);
  
  // ============================================================================
  // SHADOW COLORS
  // ============================================================================
  static Color shadowLight = const Color(0xFF6C5CE7).withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.3);
  
  // Shadow untuk landing card (dari CSS)
  static List<BoxShadow> landingCardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.25),
      blurRadius: 28,
      offset: const Offset(0, 14),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.22),
      blurRadius: 10,
      offset: const Offset(0, 10),
    ),
  ];
  
  // ============================================================================
  // CHART COLORS (Colorful & Modern)
  // ============================================================================
  static const List<Color> chartColors = [
    primaryPurple,
    accentOrange,
    accentGreen,
    accentBlue,
    accentYellow,
    accentPink,
  ];
  
  // ============================================================================
  // HELPER: Get Color by Theme
  // ============================================================================
  static Color getCardColor(bool isDark) => isDark ? cardDark : cardLight;
  static Color getBgColor(bool isDark) => isDark ? bgDark : bgLight;
  static Color getTextPrimary(bool isDark) => isDark ? textPrimaryDark : textPrimary;
  static Color getTextSecondary(bool isDark) => isDark ? textSecondaryDark : textSecondary;
  static Color getBorder(bool isDark) => isDark ? borderDark : borderLight;
  static Color getShadow(bool isDark) => isDark ? shadowDark : shadowLight;
}