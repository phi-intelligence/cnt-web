import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

/// Platform detection utilities - Web Only Deployment
class PlatformUtils {
  PlatformUtils._();

  /// Always returns false (iOS not supported in web deployment)
  static bool get isIOS => false;

  /// Always returns false (Android not supported in web deployment)
  static bool get isAndroid => false;

  /// Always returns true (web only deployment)
  static bool get isWeb => true;

  /// Always returns false (mobile not supported)
  static bool get isMobile => false;

  /// Always returns 'web'
  static String get platformName => 'web';

  /// Get API URL - uses AppConfig
  static String get apiUrl => AppConfig.apiBaseUrl;

  /// Get bottom tab bar height (web default)
  static double get bottomTabBarHeight => 60.0;

  /// Get bottom tab bar padding (web default)
  static EdgeInsets get bottomTabBarPadding => const EdgeInsets.only(top: 8, bottom: 8);
}

