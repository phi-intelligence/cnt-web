/// Application configuration for web deployment
/// All URLs and endpoints are configured via environment variables
class AppConfig {
  // API Configuration
  // REQUIRED: Set API_BASE_URL environment variable (e.g., --dart-define=API_BASE_URL=http://localhost:8002/api/v1)
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  
  // Media Configuration
  // REQUIRED: Set MEDIA_BASE_URL environment variable (e.g., --dart-define=MEDIA_BASE_URL=http://localhost:8002)
  static const String mediaBaseUrl = String.fromEnvironment(
    'MEDIA_BASE_URL',
    defaultValue: '',
  );
  
  // LiveKit Configuration
  // REQUIRED: Set LIVEKIT_WS_URL environment variable (e.g., --dart-define=LIVEKIT_WS_URL=ws://localhost:7880)
  static const String livekitWsUrl = String.fromEnvironment(
    'LIVEKIT_WS_URL',
    defaultValue: '',
  );
  
  // REQUIRED: Set LIVEKIT_HTTP_URL environment variable (e.g., --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881)
  static const String livekitHttpUrl = String.fromEnvironment(
    'LIVEKIT_HTTP_URL',
    defaultValue: '',
  );
  
  // WebSocket Configuration
  // REQUIRED: Set WEBSOCKET_URL environment variable (e.g., --dart-define=WEBSOCKET_URL=ws://localhost:8002)
  static const String websocketUrl = String.fromEnvironment(
    'WEBSOCKET_URL',
    defaultValue: '',
  );
  
  // Environment
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
}

