/// Application configuration for web deployment
/// All URLs and endpoints are configured via environment variables
class AppConfig {
  // API Configuration
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://https://9b6e75b4bb03.ngrok-free.app/api/v1',
  );
  
  // Media Configuration
  static const String mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: 'https://media.yourdomain.com',
  );
  
  // LiveKit Configuration
  static const String livekitWsUrl = String.fromEnvironment(
    'LIVEKIT_WS_URL',
    defaultValue: 'wss://livekit.yourdomain.com',
  );
  
  static const String livekitHttpUrl = String.fromEnvironment(
    'LIVEKIT_HTTP_URL',
    defaultValue: 'https://livekit.yourdomain.com',
  );
  
  // WebSocket Configuration
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: 'wss://https://9b6e75b4bb03.ngrok-free.app',
  );
  
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
}

