import '../config/app_config.dart';

/// Platform detection utilities - Web Only Deployment
class PlatformHelper {
  /// Always returns true for web deployment
  static bool isWebPlatform() {
    return true;  // Always web in this deployment
  }
  
  /// Always returns false (mobile not supported in web deployment)
  static bool isMobilePlatform() {
    return false;
  }
  
  /// Check if running on iOS (always false for web)
  static bool isIOS() {
    return false;
  }
  
  /// Check if running on Android (always false for web)
  static bool isAndroid() {
    return false;
  }
  
  /// Get screen type based on width
  static ScreenType getScreenType(double width) {
    if (width < 600) {
      return ScreenType.mobile;
    } else if (width < 1024) {
      return ScreenType.tablet;
    } else {
      return ScreenType.desktop;
    }
  }
  
  /// Get base URL for API calls - uses AppConfig
  static String getApiBaseUrl() {
    return AppConfig.apiBaseUrl;
  }
  
  /// Get WebSocket URL - uses AppConfig
  static String getWebSocketUrl() {
    return AppConfig.websocketUrl;
  }
}

/// Screen type enum
enum ScreenType {
  mobile,
  tablet,
  desktop,
}

