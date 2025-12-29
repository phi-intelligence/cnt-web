import 'package:flutter/foundation.dart';

/// Centralized logger service to handle application logging.
///
/// Use this service instead of `print()` or `debugPrint()` to ensure
/// logs are only visible in debug/development modes and suppressed in production.
class LoggerService {
  /// Check if logging is enabled (not in release mode)
  static bool get _isLogEnabled => !kReleaseMode;

  /// Log an informational message
  static void i(String message) {
    if (_isLogEnabled) {
      debugPrint('ℹ️ INFO: $message');
    }
  }

  /// Log a warning message
  static void w(String message) {
    if (_isLogEnabled) {
      debugPrint('⚠️ WARN: $message');
    }
  }

  /// Log an error message with optional error object and stack trace
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    if (_isLogEnabled) {
      debugPrint('❌ ERROR: $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
  }

  /// Log a debug message (for development only)
  static void d(String message) {
    if (_isLogEnabled) {
      debugPrint('🔧 DEBUG: $message');
    }
  }
}
