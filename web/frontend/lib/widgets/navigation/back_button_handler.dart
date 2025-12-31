import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/navigation_history_provider.dart';

/// Root-level back button handler that intercepts all back button presses
/// and implements consistent navigation behavior across web and mobile.
///
/// This widget should wrap the entire app via MaterialApp.router.builder.
/// It handles:
/// - Synthetic navigation history for deep links
/// - "Press back again to exit" confirmation on home screen
/// - Fallback to GoRouter's native navigation
class BackButtonHandler extends StatelessWidget {
  final Widget child;

  const BackButtonHandler({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: kIsWeb, // Don't intercept on web, let browser handle it
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // Already handled by system

        await _handleBackNavigation(context);
      },
      child: child,
    );
  }

  Future<void> _handleBackNavigation(BuildContext context) async {
    if (!context.mounted) return;

    final router = GoRouter.of(context);
    final navHistory = context.read<NavigationHistoryProvider>();
    final currentLocation = router.routerDelegate.currentConfiguration.uri.path;

    debugPrint('BackButtonHandler: Handling back from $currentLocation');

    // Step 1: Check for synthetic parent route (for deep links)
    final parentRoute = navHistory.getParentRoute(currentLocation);
    if (parentRoute != null) {
      debugPrint('BackButtonHandler: Navigating to synthetic parent: $parentRoute');
      router.go(parentRoute);
      return;
    }

    // Step 2: Check for exit confirmation on home screen
    if (navHistory.shouldShowExitConfirmation(currentLocation)) {
      final shouldExit = navHistory.handleBackPress(currentLocation);

      if (!shouldExit) {
        // Show toast: "Press back again to exit"
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      } else {
        // Exit app (double-tap confirmed)
        debugPrint('BackButtonHandler: Exiting app');
        SystemNavigator.pop();
        return;
      }
    }

    // Step 3: Use GoRouter's native navigation
    if (router.canPop()) {
      debugPrint('BackButtonHandler: Using GoRouter.pop()');
      router.pop();
    } else {
      // Fallback: Go to home if can't pop
      debugPrint('BackButtonHandler: Fallback to /home');
      if (currentLocation != '/home') {
        router.go('/home');
      }
    }
  }
}
