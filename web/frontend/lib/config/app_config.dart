import 'environment.dart';

/// Application configuration for web deployment.
/// Values are resolved at runtime from --dart-define, .env, or dev defaults.
class AppConfig {
  static String get apiBaseUrl => Environment.apiBaseUrl;
  static String get mediaBaseUrl => Environment.mediaBaseUrl;
  static String get livekitWsUrl => Environment.livekitWsUrl;
  static String get livekitHttpUrl => Environment.livekitHttpUrl;
  static String get websocketUrl => Environment.webSocketUrl;
  static String get environment => Environment.environment;
  static String get stripePublishableKey => Environment.stripePublishableKey;

  static const int organizationRecipientUserId = int.fromEnvironment(
    'ORGANIZATION_RECIPIENT_USER_ID',
    defaultValue: 1,
  );
}
