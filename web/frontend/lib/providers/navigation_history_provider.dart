import 'package:flutter/foundation.dart';

/// Manages navigation history, deep link detection, and exit confirmation
/// for consistent back button behavior across web and mobile platforms.
///
/// This provider tracks:
/// - Initial route on app startup to detect deep links
/// - Synthetic navigation history for deep links
/// - "Press back again to exit" confirmation state
class NavigationHistoryProvider extends ChangeNotifier {
  String? _initialRoute;
  bool _isDeepLink = false;
  int _backPressCount = 0;
  DateTime? _lastBackPress;
  List<String> _syntheticHistory = [];

  /// Route mappings for building synthetic navigation history
  /// Maps detail routes to their logical parent chain
  final Map<String, List<String>> _routeParentMap = {
    '/movie/': ['/home', '/movies'],
    '/podcast/': ['/home', '/podcasts'],
    '/events/': ['/home', '/events'],
    '/artist/': ['/home', '/profile'],
    '/edit/video': ['/home', '/create'],
    '/edit/audio': ['/home', '/create'],
    '/preview/video': ['/home', '/create'],
    '/preview/audio': ['/home', '/create'],
    '/live-stream/start': ['/home', '/live-stream/options'],
  };

  /// Initialize navigation history with the initial route
  /// Call this once when the app starts to detect deep links
  void initializeWithRoute(String route) {
    if (_initialRoute == null) {
      _initialRoute = route;
      _isDeepLink = _isDetailRoute(route);

      if (_isDeepLink) {
        _buildSyntheticHistory(route);
      }

      if (kDebugMode) {
        print('NavigationHistory: Initialized with route=$route, isDeepLink=$_isDeepLink');
        if (_syntheticHistory.isNotEmpty) {
          print('NavigationHistory: Synthetic history=$_syntheticHistory');
        }
      }
    }
  }

  /// Check if a route is a detail/deep page that needs synthetic history
  bool _isDetailRoute(String route) {
    // Skip auth routes
    if (route == '/' || route.startsWith('/login') || route.startsWith('/register')) {
      return false;
    }

    // Skip main navigation routes
    if (route == '/home' || route == '/create' || route == '/community' ||
        route == '/profile' || route == '/notifications' || route == '/podcasts' ||
        route == '/movies' || route == '/about' || route == '/bible' ||
        route == '/events') {
      return false;
    }

    // Check if route matches any detail route patterns
    return route.startsWith('/movie/') ||
           route.startsWith('/podcast/') ||
           (route.startsWith('/events/') && route != '/events') ||
           (route.startsWith('/artist/') && route != '/artist/manage') ||
           route.startsWith('/edit/video') ||
           route.startsWith('/edit/audio') ||
           route.startsWith('/preview/video') ||
           route.startsWith('/preview/audio') ||
           route == '/live-stream/start';
  }

  /// Build synthetic navigation history for a deep link route
  void _buildSyntheticHistory(String route) {
    _syntheticHistory.clear();

    // Find matching route pattern
    for (final entry in _routeParentMap.entries) {
      if (route.startsWith(entry.key)) {
        _syntheticHistory = List.from(entry.value);
        break;
      }
    }

    if (kDebugMode && _syntheticHistory.isNotEmpty) {
      print('NavigationHistory: Built synthetic history for $route: $_syntheticHistory');
    }
  }

  /// Get the parent route from synthetic history
  /// Returns null if no synthetic history available
  String? getParentRoute(String currentRoute) {
    if (_syntheticHistory.isNotEmpty) {
      final parent = _syntheticHistory.removeLast();
      if (kDebugMode) {
        print('NavigationHistory: Navigating to synthetic parent: $parent (remaining: $_syntheticHistory)');
      }
      notifyListeners();
      return parent;
    }
    return null;
  }

  /// Check if we should show exit confirmation
  /// Returns true if on home screen with no synthetic history
  bool shouldShowExitConfirmation(String currentRoute) {
    return currentRoute == '/home' && _syntheticHistory.isEmpty;
  }

  /// Handle back press with double-tap to exit logic
  /// Returns true if should exit, false if should show toast
  bool handleBackPress(String currentRoute) {
    if (!shouldShowExitConfirmation(currentRoute)) {
      return true; // Not on home, allow normal back navigation
    }

    final now = DateTime.now();

    // Check if this is a second press within timeout
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      // First press or timeout expired
      _backPressCount = 1;
      _lastBackPress = now;
      if (kDebugMode) {
        print('NavigationHistory: First back press on home, showing toast');
      }
      return false; // Don't exit, show toast
    } else {
      // Second press within 2 seconds
      if (kDebugMode) {
        print('NavigationHistory: Second back press within timeout, exiting');
      }
      return true; // Allow exit
    }
  }

  /// Reset back press count (e.g., when navigating away from home)
  void resetBackPressCount() {
    _backPressCount = 0;
    _lastBackPress = null;
    if (kDebugMode) {
      print('NavigationHistory: Reset back press count');
    }
    notifyListeners();
  }

  /// Clear synthetic history (when user navigates normally)
  void clearSyntheticHistory() {
    if (_syntheticHistory.isNotEmpty) {
      _syntheticHistory.clear();
      if (kDebugMode) {
        print('NavigationHistory: Cleared synthetic history');
      }
      notifyListeners();
    }
  }

  /// Get debug info for testing
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialRoute': _initialRoute,
      'isDeepLink': _isDeepLink,
      'syntheticHistory': _syntheticHistory,
      'backPressCount': _backPressCount,
      'lastBackPress': _lastBackPress?.toIso8601String(),
    };
  }
}
