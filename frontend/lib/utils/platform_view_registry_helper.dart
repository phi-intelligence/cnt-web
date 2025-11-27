// Platform view registry helper with conditional imports
// This file provides platformViewRegistry for web, and a stub for other platforms

import 'platform_view_registry_stub.dart'
    if (dart.library.html) 'platform_view_registry_web.dart';

/// Platform view registry for registering HTML elements in Flutter web
/// On web: provides access to dart:ui_web's platformViewRegistry
/// On other platforms: provides a stub that throws UnsupportedError
final platformViewRegistry = getPlatformViewRegistry();

