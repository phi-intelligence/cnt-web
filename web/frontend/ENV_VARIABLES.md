# Frontend Environment Variables

The Flutter web frontend uses compile-time environment variables passed via `--dart-define` flags during build.

## Required Environment Variables

All environment variables must be set when building the Flutter web app. They are **required** and have no default values.

### API Configuration

```bash
--dart-define=API_BASE_URL=http://localhost:8002/api/v1
```

- **Description**: Base URL for the backend API
- **Local Development**: `http://localhost:8002/api/v1`
- **Production**: Your production API URL (e.g., `https://api.yourdomain.com/api/v1`)

### Media Base URL

```bash
--dart-define=MEDIA_BASE_URL=http://localhost:8002
```

- **Description**: Base URL for media files (images, audio, video)
- **Local Development**: `http://localhost:8002` (backend serves files via `/media` endpoint)
- **Production**: Your CloudFront distribution URL (e.g., `https://d126sja5o8ue54.cloudfront.net`)

### LiveKit Configuration

```bash
--dart-define=LIVEKIT_WS_URL=ws://localhost:7880
--dart-define=LIVEKIT_HTTP_URL=http://localhost:7881
```

- **Description**: LiveKit server URLs for video meetings and voice agent
- **Local Development**: 
  - `LIVEKIT_WS_URL=ws://localhost:7880`
  - `LIVEKIT_HTTP_URL=http://localhost:7881`
- **Production**: Your production LiveKit server URLs
  - `LIVEKIT_WS_URL=wss://livekit.yourdomain.com`
  - `LIVEKIT_HTTP_URL=https://livekit.yourdomain.com`

### WebSocket Configuration

```bash
--dart-define=WEBSOCKET_URL=ws://localhost:8002
```

- **Description**: WebSocket URL for real-time features (Socket.IO)
- **Local Development**: `ws://localhost:8002`
- **Production**: Your production WebSocket URL (e.g., `wss://api.yourdomain.com`)

### Environment

```bash
--dart-define=ENVIRONMENT=development
```

- **Description**: Application environment
- **Values**: `development` or `production`
- **Local Development**: `development`
- **Production**: `production`

## Build Commands

### Local Development

```bash
cd frontend
flutter build web --release \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development
```

### Production (AWS Amplify)

Environment variables are set in the Amplify console and passed automatically during build via `amplify.yml`.

See `amplify.yml` for the build configuration.

## Configuration File

Environment variables are read in `lib/config/app_config.dart`:

```dart
static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
```

**Important**: All environment variables are required. Empty strings will cause runtime errors if not set.

## Troubleshooting

### Missing Environment Variables

If you see errors about missing URLs or connection failures:

1. Verify all `--dart-define` flags are set during build
2. Check `lib/config/app_config.dart` for variable names
3. Ensure no hardcoded default values are overriding your settings

### Invalid URLs

- Ensure URLs don't have double protocols (e.g., `https://https://...`)
- Ensure WebSocket URLs use `ws://` (HTTP) or `wss://` (HTTPS), not `wss://https://...`
- Ensure HTTP URLs use `http://` or `https://`

### Development vs Production

- **Development**: Uses localhost URLs, backend serves media via `/media` endpoint
- **Production**: Uses CloudFront/S3 for media, production API URLs

## Related Files

- `lib/config/app_config.dart` - Configuration class
- `amplify.yml` - AWS Amplify build configuration
- `lib/services/api_service.dart` - API service using these URLs

