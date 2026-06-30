import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment configuration for CNT Web.
///
/// Precedence: --dart-define > .env > development defaults.
class Environment {
  static bool _initialized = false;

  // Compile-time --dart-define values (must be const, not called at runtime)
  static const String _dartEnvironment = String.fromEnvironment('ENVIRONMENT');
  static const String _dartApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _dartWebSocketUrl = String.fromEnvironment('WEBSOCKET_URL');
  static const String _dartMediaBaseUrl = String.fromEnvironment('MEDIA_BASE_URL');
  static const String _dartLiveKitWsUrl = String.fromEnvironment('LIVEKIT_WS_URL');
  static const String _dartLiveKitHttpUrl = String.fromEnvironment('LIVEKIT_HTTP_URL');
  static const String _dartStripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static const String _devApiBaseUrl = 'http://localhost:8002/api/v1';
  static const String _devWebSocketUrl = 'ws://localhost:8002';
  static const String _devMediaBaseUrl = 'http://localhost:8002';
  static const String _devLiveKitWsUrl = 'ws://localhost:7880';
  static const String _devLiveKitHttpUrl = 'http://localhost:7881';

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      debugPrint('Environment: loaded .env');
    } catch (e) {
      debugPrint('Environment: .env not found, using defaults');
    }

    _initialized = true;

    debugPrint('CNT Web configuration:');
    debugPrint('  ENVIRONMENT: $environment');
    debugPrint('  API_BASE_URL: $apiBaseUrl');
    debugPrint('  WEBSOCKET_URL: $webSocketUrl');
    debugPrint('  MEDIA_BASE_URL: $mediaBaseUrl');
  }

  static String get environment {
    if (_dartEnvironment.isNotEmpty) return _dartEnvironment.toLowerCase();

    final dotenvValue = dotenv.maybeGet('ENVIRONMENT');
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue.toLowerCase();
    }

    return 'development';
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static String get apiBaseUrl =>
      _resolveUrl(_dartApiBaseUrl, 'API_BASE_URL', _devApiBaseUrl);

  static String get webSocketUrl =>
      _resolveUrl(_dartWebSocketUrl, 'WEBSOCKET_URL', _devWebSocketUrl);

  static String get mediaBaseUrl =>
      _resolveUrl(_dartMediaBaseUrl, 'MEDIA_BASE_URL', _devMediaBaseUrl);

  static String get livekitWsUrl =>
      _resolveUrl(_dartLiveKitWsUrl, 'LIVEKIT_WS_URL', _devLiveKitWsUrl);

  static String get livekitHttpUrl =>
      _resolveUrl(_dartLiveKitHttpUrl, 'LIVEKIT_HTTP_URL', _devLiveKitHttpUrl);

  static String get stripePublishableKey {
    if (_dartStripePublishableKey.isNotEmpty) return _dartStripePublishableKey;

    final dotenvValue = dotenv.maybeGet('STRIPE_PUBLISHABLE_KEY');
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;

    return '';
  }

  static String _resolveUrl(
    String dartDefine,
    String envKey,
    String devDefault,
  ) {
    if (dartDefine.isNotEmpty) return dartDefine;

    final dotenvValue = dotenv.maybeGet(envKey);
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;

    return devDefault;
  }
}
