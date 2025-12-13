import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_spacing.dart';

/// Complete theme data matching the React Native mobile app exactly
class AppThemeData {
  AppThemeData._();

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: AppColors.primaryMain,
    scaffoldBackgroundColor: AppColors.backgroundPrimary,
    colorScheme: ColorScheme.light(
      primary: AppColors.primaryMain,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.accentMain,
      onSecondary: AppColors.textInverse,
      tertiary: AppColors.secondaryMain,
      onTertiary: AppColors.foregroundPrimary,
      surface: AppColors.backgroundSecondary,
      onSurface: AppColors.foregroundPrimary,
      surfaceVariant: AppColors.backgroundSecondary,
      onSurfaceVariant: AppColors.foregroundPrimary,
      error: AppColors.errorMain,
      onError: AppColors.textInverse,
      outline: AppColors.borderPrimary,
      shadow: AppColors.foregroundPrimary.withValues(alpha: 0.1),
    ),
    
    // Card theme - Premium Soft Rounded
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 2,
      shadowColor: AppColors.foregroundPrimary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24), // Increased from medium (16) to 24
        side: BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      margin: EdgeInsets.all(AppSpacing.small),
    ),

    // Input decoration theme - Pill Shaped
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large, // Increased padding for pill shape
        vertical: AppSpacing.medium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30), // Full Pill Shape
        borderSide: BorderSide(color: AppColors.borderPrimary, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.borderPrimary, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.borderFocus, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.errorMain, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.errorMain, width: 2),
      ),
    ),

    // Text theme
    textTheme: TextTheme(
      displayLarge: AppTypography.heading1.copyWith(color: AppColors.textPrimary),
      displayMedium: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
      displaySmall: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
      headlineLarge: AppTypography.heading1.copyWith(color: AppColors.textPrimary),
      headlineMedium: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
      headlineSmall: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
      titleLarge: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
      titleMedium: AppTypography.body.copyWith(color: AppColors.textSecondary),
      titleSmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
      bodyLarge: AppTypography.body.copyWith(color: AppColors.textPrimary),
      bodyMedium: AppTypography.body.copyWith(color: AppColors.textSecondary),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
      labelLarge: AppTypography.label.copyWith(color: AppColors.textPrimary),
      labelMedium: AppTypography.label.copyWith(color: AppColors.textSecondary),
      labelSmall: AppTypography.caption.copyWith(color: AppColors.textTertiary),
    ),

    // App bar theme
    appBarTheme: const AppBarTheme(
      elevation: 0,
        backgroundColor: AppColors.backgroundPrimary,
        surfaceTintColor: AppColors.backgroundPrimary,
        foregroundColor: AppColors.textPrimary,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
    ),

    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.backgroundPrimary,
      selectedItemColor: AppColors.primaryMain,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: AppTypography.fontWeightMedium,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: AppTypography.fontSizeSM,
        fontWeight: AppTypography.fontWeightNormal,
      ),
      elevation: 2,
      type: BottomNavigationBarType.fixed,
    ),

    // Dialog theme - Soft Rounded
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.cardBackground,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)), // Increased radius
      ),
      titleTextStyle: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
      contentTextStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
    ),

    // Button themes - Pill Shaped (Stadium)
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMain,
        foregroundColor: AppColors.textInverse,
        elevation: 2,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: const StadiumBorder(), // Full Pill Shape
        textStyle: AppTypography.button,
        minimumSize: const Size(double.infinity, 48), // Taller touch target
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryMain,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
        shape: const StadiumBorder(), // Full Pill Shape
        side: const BorderSide(color: AppColors.primaryMain, width: 2),
        textStyle: AppTypography.button,
        minimumSize: const Size(double.infinity, 48),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryMain,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.small,
        ),
        shape: const StadiumBorder(), // Full Pill Shape
        textStyle: AppTypography.button,
        minimumSize: const Size(0, 48),
      ),
    ),

    // Icon theme
    iconTheme: const IconThemeData(
      color: AppColors.textSecondary,
      size: AppSpacing.iconSizeMedium,
    ),

    // Divider theme
    dividerTheme: const DividerThemeData(
      color: AppColors.borderSecondary,
      thickness: 1,
      space: 1,
    ),

    // Chip theme - Pill Shaped
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.backgroundSecondary,
      deleteIconColor: AppColors.textSecondary,
      disabledColor: AppColors.backgroundSecondary,
      elevation: 0,
      labelPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.tiny,
      ),
      labelStyle: AppTypography.bodySmall,
      padding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30), // Full Pill Shape
        side: const BorderSide(color: AppColors.borderPrimary, width: 1),
      ),
    ),

    // Bottom sheet theme
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(32), // large rounded top corners
        ),
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryMain,
    scaffoldBackgroundColor: Colors.black,
    colorScheme: ColorScheme.dark(
      primary: AppColors.primaryMain,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.accentMain,
      onSecondary: AppColors.textInverse,
      tertiary: AppColors.secondaryMain,
      onTertiary: AppColors.textInverse,
      surface: const Color(0xFF1A1D29),
      onSurface: Colors.white,
      background: Colors.black,
      onBackground: Colors.white,
      error: AppColors.errorMain,
      onError: AppColors.textInverse,
    ),
    // Dark Theme - Pill Oriented
    cardTheme: CardThemeData(
      color: const Color(0xFF1A1D29),
      elevation: 4,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(24)),
      ),
    ),
    // Input Decoration - Dark
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2A2D39),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
      ),
    ),
    // Button themes - Dark Pill
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryMain,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const StadiumBorder(),
        minimumSize: const Size(double.infinity, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryMain,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: const StadiumBorder(),
        side: const BorderSide(color: AppColors.primaryMain, width: 2),
         minimumSize: const Size(double.infinity, 48),
      ),
    ),
  );
}

