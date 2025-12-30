import 'package:flutter/material.dart';
import 'app_theme_data.dart';

/// Main theme export - uses the comprehensive theme data
class AppTheme {
  AppTheme._();

  /// Get light theme
  static ThemeData get lightTheme => AppThemeData.lightTheme;

  /// Get dark theme
  static ThemeData get darkTheme => AppThemeData.lightTheme; // Fallback to light theme as dark theme is disabled
}

