import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Runtime environment configuration for CNT Web.
///
/// Precedence: `--dart-define` > `.env` asset > error if required keys missing.
///
/// Local dev: keep `web/frontend/.env` (gitignored) and run `flutter run -d chrome`.
/// Production (Amplify): values come from `--dart-define`; bundled `.env` is only a stub.
class Environment {
  static bool _initialized = false;
  static bool _dotenvLoaded = false;

  static const String _dartEnvironment = String.fromEnvironment('ENVIRONMENT');
  static const String _dartApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _dartWebSocketUrl = String.fromEnvironment('WEBSOCKET_URL');
  static const String _dartMediaBaseUrl = String.fromEnvironment('MEDIA_BASE_URL');
  static const String _dartLiveKitWsUrl = String.fromEnvironment('LIVEKIT_WS_URL');
  static const String _dartLiveKitHttpUrl = String.fromEnvironment('LIVEKIT_HTTP_URL');
  static const String _dartStripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');

  static const List<String> _requiredKeys = [
    'API_BASE_URL',
    'WEBSOCKET_URL',
    'MEDIA_BASE_URL',
    'LIVEKIT_WS_URL',
    'LIVEKIT_HTTP_URL',
  ];

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await dotenv.load(fileName: '.env');
      _dotenvLoaded = true;
      if (kDebugMode) {
        debugPrint('Environment: loaded .env asset');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Environment: .env asset not loaded ($e)');
      }
    }

    _initialized = true;
    _validateRequired();

    if (kDebugMode) {
      debugPrint('CNT Web configuration:');
      debugPrint('  ENVIRONMENT: $environment');
      debugPrint('  API_BASE_URL: $apiBaseUrl');
      debugPrint('  WEBSOCKET_URL: $webSocketUrl');
      debugPrint('  MEDIA_BASE_URL: $mediaBaseUrl');
      debugPrint('  LIVEKIT_WS_URL: $livekitWsUrl');
      debugPrint('  LIVEKIT_HTTP_URL: $livekitHttpUrl');
    }
  }

  static void _validateRequired() {
    final missing = <String>[];
    for (final key in _requiredKeys) {
      if (_resolve(key).isEmpty) {
        missing.add(key);
      }
    }

    if (missing.isEmpty) return;

    throw StateError(
      'Missing required configuration: ${missing.join(', ')}. '
      'Create web/frontend/.env from env.example, or pass --dart-define flags. '
      'Production CI uses --dart-define from Amplify env vars.',
    );
  }

  static String? _dotenvGet(String key) {
    if (!_dotenvLoaded || !dotenv.isInitialized) return null;
    return dotenv.maybeGet(key);
  }

  static String _resolve(String key) {
    switch (key) {
      case 'API_BASE_URL':
        return _resolveValue(_dartApiBaseUrl, key);
      case 'WEBSOCKET_URL':
        return _resolveValue(_dartWebSocketUrl, key);
      case 'MEDIA_BASE_URL':
        return _resolveValue(_dartMediaBaseUrl, key);
      case 'LIVEKIT_WS_URL':
        return _resolveValue(_dartLiveKitWsUrl, key);
      case 'LIVEKIT_HTTP_URL':
        return _resolveValue(_dartLiveKitHttpUrl, key);
      default:
        return '';
    }
  }

  /// `--dart-define` wins over `.env` when both are set.
  static String _resolveValue(String dartDefine, String envKey) {
    if (dartDefine.isNotEmpty) return dartDefine;
    final dotenvValue = _dotenvGet(envKey);
    if (dotenvValue != null && dotenvValue.isNotEmpty) return dotenvValue;
    return '';
  }

  static String get environment {
    if (_dartEnvironment.isNotEmpty) return _dartEnvironment.toLowerCase();
    final dotenvValue = _dotenvGet('ENVIRONMENT');
    if (dotenvValue != null && dotenvValue.isNotEmpty) {
      return dotenvValue.toLowerCase();
    }
    return 'development';
  }

  static bool get isProduction => environment == 'production';
  static bool get isDevelopment => environment == 'development';

  static String get apiBaseUrl => _resolve('API_BASE_URL');
  static String get webSocketUrl => _resolve('WEBSOCKET_URL');
  static String get mediaBaseUrl => _resolve('MEDIA_BASE_URL');
  static String get livekitWsUrl => _resolve('LIVEKIT_WS_URL');
  static String get livekitHttpUrl => _resolve('LIVEKIT_HTTP_URL');

  static String get stripePublishableKey {
    if (_dartStripePublishableKey.isNotEmpty) return _dartStripePublishableKey;
    return _dotenvGet('STRIPE_PUBLISHABLE_KEY') ?? '';
  }
}
