// lib/core/theme/app_theme.dart
// ============================================================================
// APP_THEME.DART (FIXED - CardTheme → CardThemeData)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sidrive/core/utils/responsive_mobile.dart';
import 'package:sidrive/config/app_colors.dart';
import 'package:sidrive/config/app_radius.dart';
import 'package:sidrive/config/app_spacing.dart';
import 'package:sidrive/config/app_elevation.dart';

class AppTheme {
  // ---------------------------------------------------------------------------
  // LIGHT THEME
  // ---------------------------------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    platform: TargetPlatform.iOS,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.primaryLightVariant,
      secondary: AppColors.secondaryLight,
      secondaryContainer: AppColors.secondaryLightVariant,
      surface: AppColors.surfaceLight,
      error: AppColors.errorLight,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryLight,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundLight,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryLight,
        size: 24,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
    ),

    // FIXED: CardTheme → CardThemeData
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: AppElevation.small,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      margin: EdgeInsets.all(AppSpacing.cardMargin),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: Colors.white,
        elevation: AppElevation.small,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(14),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryLight,
        side: BorderSide(color: AppColors.primaryLight, width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.borderLight, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.errorLight, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.errorLight, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        color: AppColors.textSecondaryLight,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        color: AppColors.textSecondaryLight,
      ),
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        color: AppColors.errorLight,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.dividerLight,
      thickness: 1,
      space: 1,
    ),

    iconTheme: IconThemeData(
      color: AppColors.textPrimaryLight,
      size: AppSpacing.iconSizeMedium,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(32),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(28),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(24),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(24),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryLight,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(20),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(16),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryLight,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(16),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryLight,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryLight,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(10),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryLight,
      ),
    ),
  );

  // ---------------------------------------------------------------------------
  // DARK THEME
  // ---------------------------------------------------------------------------
  static ThemeData darkTheme = ThemeData(
    platform: TargetPlatform.iOS,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryDark,
      primaryContainer: AppColors.primaryDarkVariant,
      secondary: AppColors.secondaryDark,
      secondaryContainer: AppColors.secondaryDarkVariant,
      surface: AppColors.surfaceDark,
      error: AppColors.errorDark,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimaryDark,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,

    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.backgroundDark,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: AppColors.textPrimaryDark,
        size: 24,
      ),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
    ),

    // FIXED: CardTheme → CardThemeData
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: AppElevation.small,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      margin: EdgeInsets.all(AppSpacing.cardMargin),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: AppElevation.small,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(14),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryDark,
        side: BorderSide(color: AppColors.primaryDark, width: 1.5),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
        textStyle: TextStyle(
          fontFamily: 'Inter',
          fontSize: ResponsiveMobile.scaledFont(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.borderDark, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.borderDark, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.primaryDark, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.errorDark, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.small),
        borderSide: BorderSide(color: AppColors.errorDark, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        color: AppColors.textSecondaryDark,
      ),
      hintStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        color: AppColors.textSecondaryDark,
      ),
      errorStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        color: AppColors.errorDark,
      ),
    ),

    dividerTheme: DividerThemeData(
      color: AppColors.dividerDark,
      thickness: 1,
      space: 1,
    ),

    iconTheme: IconThemeData(
      color: AppColors.textPrimaryDark,
      size: AppSpacing.iconSizeMedium,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(32),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(28),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(24),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(24),
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimaryDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(20),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Poppins',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(18),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      titleMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(16),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      titleSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimaryDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(16),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimaryDark,
      ),
      bodySmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondaryDark,
      ),
      labelLarge: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(14),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
      ),
      labelMedium: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(12),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
      ),
      labelSmall: TextStyle(
        fontFamily: 'Inter',
        fontSize: ResponsiveMobile.scaledFont(10),
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondaryDark,
      ),
    ),
  );
}