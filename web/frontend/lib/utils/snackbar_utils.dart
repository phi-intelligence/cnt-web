import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Utility class for consistent snackbar behavior across the application
/// Ensures all error and success messages have appropriate durations
class SnackbarUtils {
  SnackbarUtils._();

  /// Show an error snackbar with 5-second duration
  /// Use this for error messages that need to be visible but auto-dismiss
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorMain,
        duration: duration ?? const Duration(seconds: 5),
        action: action,
      ),
    );
  }

  /// Show a success snackbar with 3-second duration
  /// Use this for success messages
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.successMain,
        duration: duration ?? const Duration(seconds: 3),
        action: action,
      ),
    );
  }

  /// Show an info snackbar with 4-second duration
  /// Use this for informational messages
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warmBrown,
        duration: duration ?? const Duration(seconds: 4),
        action: action,
      ),
    );
  }

  /// Show a warning snackbar with 5-second duration
  /// Use this for warning messages
  static void showWarning(
    BuildContext context,
    String message, {
    Duration? duration,
    SnackBarAction? action,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: duration ?? const Duration(seconds: 5),
        action: action,
      ),
    );
  }
}
