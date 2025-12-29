# Editor Environment Setup Guide

This document provides comprehensive information about setting up and configuring video and audio editors for both web and mobile applications in local development and production environments.

## Table of Contents

1. [Overview](#overview)
2. [Environment Configuration](#environment-configuration)
3. [Media URL Resolution](#media-url-resolution)
4. [Blob URL Handling](#blob-url-handling)
5. [State Persistence](#state-persistence)
6. [File Processing](#file-processing)
7. [Backend API Endpoints](#backend-api-endpoints)
8. [Troubleshooting](#troubleshooting)

## Overview

The CNT Media Platform provides video and audio editing capabilities for both web and mobile applications. The editors are designed to work seamlessly in both local development and production environments with automatic environment detection.

### Key Features

**Video Editor:**
- Trim video (set start/end times)
- Remove/replace audio tracks
- Rotate video (90°, 180°, 270°)
- Front camera flip (horizontal mirror)
- State persistence across page reloads

**Audio Editor:**
- Trim audio (set start/end times)
- Merge multiple audio files
- State persistence across page reloads

## Environment Configuration

### Web Application

The web application uses compile-time environment variables passed via `--dart-define` flags during build.

#### Required Environment Variables

All variables must be set when building the Flutter web app:

```bash
--dart-define=API_BASE_URL=http://localhost:8002/api/v1
--dart-define=MEDIA_BASE_URL=http://localhost:8002
--dart-define=LIVEKIT_WS_URL=ws://localhost:7880
--dart-define=LIVEKIT_HTTP_URL=http://localhost:7881
--dart-define=WEBSOCKET_URL=ws://localhost:8002
--dart-define=ENVIRONMENT=development
```

#### Local Development

```bash
cd web/frontend
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development
```

#### Production (AWS Amplify)

Environment variables are set in the Amplify console and passed automatically during build via `amplify.yml`:

```yaml
flutter build web --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
  --dart-define=ENVIRONMENT=production
```

**Amplify Environment Variables:**
- `API_BASE_URL` = `https://api.christnewtabernacle.com/api/v1`
- `MEDIA_BASE_URL` = `https://d126sja5o8ue54.cloudfront.net`
- `LIVEKIT_WS_URL` = `wss://livekit.christnewtabernacle.com`
- `LIVEKIT_HTTP_URL` = `https://livekit.christnewtabernacle.com`
- `WEBSOCKET_URL` = `wss://api.christnewtabernacle.com`

### Mobile Application

The mobile application uses a `.env` file for configuration with platform-specific defaults.

#### Required Environment Variables

Create a `.env` file in `mobile/frontend/`:

```env
ENVIRONMENT=development

# Production URLs (required when ENVIRONMENT=production)
# API_BASE_URL=https://api.christnewtabernacle.com/api/v1
# WEBSOCKET_URL=wss://api.christnewtabernacle.com
# MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
# LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
# LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
```

#### Platform-Specific Defaults

When `ENVIRONMENT=development` and URLs are not set in `.env`, the app uses:

- **Web**: `http://localhost:8002`
- **Android Emulator**: `http://10.0.2.2:8002` (special IP for emulator)
- **iOS Simulator**: `http://localhost:8002`
- **Physical Devices**: Requires network IP (e.g., `http://192.168.1.100:8002`)

#### Initialization

The `Environment` class must be initialized in `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Environment.initialize(); // Load .env file
  // ... rest of initialization
}
```

## Media URL Resolution

### Environment Detection

The system automatically detects the environment based on URL patterns:

**Development Indicators:**
- `localhost`
- `127.0.0.1`
- Port numbers (`:8002`, `:8000`)
- Private IP ranges (`192.168.`, `10.`, `172.`)
- `ngrok` URLs

**Production Indicators:**
- CloudFront domains (`*.cloudfront.net`)
- S3 domains (`*.s3.*.amazonaws.com`)
- HTTPS URLs without localhost/ports

### URL Resolution Flow

#### Development Mode

1. **Full URLs** (http/https) → Return as-is
2. **`/media/` paths** → `http://localhost:8002/media/{path}`
3. **Relative paths** → `http://localhost:8002/media/{path}`

**Example:**
- Input: `video/file.mp4`
- Output: `http://localhost:8002/media/video/file.mp4`

#### Production Mode

1. **Full URLs** (http/https) → Return as-is
2. **`/media/` paths** → `https://cloudfront.net/media/{path}` (kept for backend compatibility)
3. **Relative paths** → `https://cloudfront.net/{path}` (no `/media/` prefix)

**Example:**
- Input: `video/file.mp4`
- Output: `https://d126sja5o8ue54.cloudfront.net/video/file.mp4`

### Implementation

**Web Services:**
- `VideoEditingService._constructMediaUrl()` - Constructs URLs for video editing results
- `AudioEditingService._constructMediaUrl()` - Constructs URLs for audio editing results
- `ApiService.getMediaUrl()` - General media URL resolution

**Mobile Services:**
- `ApiService.getMediaUrl()` - Unified media URL resolution with environment detection

## Blob URL Handling

### Overview

Blob URLs are temporary URLs created by the browser's `MediaRecorder` API. They are not persistent and must be uploaded to the backend before editing operations.

### Web Application Flow

1. **Detection**: Check if path starts with `blob:`
2. **Upload**: Call `ApiService.uploadTemporaryMedia(blobUrl, 'video'|'audio')`
3. **Conversion**: Backend returns relative path (e.g., `video/temp_uuid.webm`)
4. **Resolution**: Convert to full URL using `getMediaUrl()`
5. **Persistence**: Save full URL to `_persistedVideoPath` or `_persistedAudioPath`

### Implementation

**Video Editor:**
```dart
if (kIsWeb && widget.videoPath.startsWith('blob:')) {
  final uploadResult = await _apiService.uploadTemporaryMedia(widget.videoPath, 'video');
  final backendUrl = uploadResult['file_path'] ?? uploadResult['url'];
  final fullUrl = _apiService.getMediaUrl(backendUrl);
  _persistedVideoPath = fullUrl;
}
```

**Audio Editor:**
```dart
if (kIsWeb && widget.audioPath.startsWith('blob:')) {
  final uploadResult = await _apiService.uploadTemporaryMedia(widget.audioPath, 'audio');
  final backendUrl = uploadResult['file_path'] ?? uploadResult['url'];
  final fullUrl = _apiService.getMediaUrl(backendUrl);
  _persistedAudioPath = fullUrl;
}
```

### Mobile Application

Mobile apps typically use file paths (not blob URLs) from:
- File picker selections
- Camera recordings (saved to device storage)
- Network URLs (downloaded files)

Blob URL handling is primarily a web concern.

## State Persistence

### Web Application

State is persisted using `WebStorageService` (localStorage/sessionStorage) via `StatePersistence` utility class.

**Video Editor State:**
- `videoPath` - Original video path
- `editedVideoPath` - Path to edited video (if any)
- `trimStart` - Trim start time (milliseconds)
- `trimEnd` - Trim end time (milliseconds)
- `audioRemoved` - Whether audio was removed
- `audioFilePath` - Path to replacement audio file
- `rotation` - Rotation angle (0, 90, 180, 270)
- `isFrontCamera` - Whether front camera flip is applied
- `timestamp` - When state was saved (for expiration)

**Audio Editor State:**
- `audioPath` - Original audio path
- `editedAudioPath` - Path to edited audio (if any)
- `trimStart` - Trim start time (milliseconds)
- `trimEnd` - Trim end time (milliseconds)
- `timestamp` - When state was saved (for expiration)

**State Expiration:**
- States older than 1 hour are automatically cleared
- States are cleared after successful save/export

### Mobile Application

Mobile apps use `SharedPreferences` for state persistence (if implemented). The mobile editors may not have full state persistence yet, as they primarily work with local files.

## File Processing

### Web Application

**All processing is server-side:**
- Video/audio files are sent to backend API
- Backend processes files using FFmpeg
- Processed files are returned as URLs
- In production, files are uploaded to S3/CloudFront
- In development, files are saved to local `./media/` directory

### Mobile Application

**Hybrid processing:**
- **Local files** → Processed locally using FFmpeg (faster, no network)
- **Network URLs** → Processed server-side via API (downloads file first)

**Local Processing Benefits:**
- Faster processing (no network latency)
- Works offline
- Reduces server load
- Better user experience

**Server Processing Fallback:**
- Used when file is a network URL
- Used when local processing fails
- Ensures compatibility with all file sources

## Backend API Endpoints

### Video Editing Endpoints

**Base Path:** `/api/v1/video-editing/`

#### Trim Video
- **Endpoint:** `POST /trim`
- **Parameters:**
  - `video_file` (multipart file)
  - `start_time` (float, seconds)
  - `end_time` (float, seconds)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

#### Remove Audio
- **Endpoint:** `POST /remove-audio`
- **Parameters:**
  - `video_file` (multipart file)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

#### Add Audio
- **Endpoint:** `POST /add-audio`
- **Parameters:**
  - `video_file` (multipart file)
  - `audio_file` (multipart file)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

#### Rotate Video
- **Endpoint:** `POST /rotate`
- **Parameters:**
  - `video_file` (multipart file)
  - `degrees` (int: 90, 180, or 270)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

### Audio Editing Endpoints

**Base Path:** `/api/v1/audio-editing/`

#### Trim Audio
- **Endpoint:** `POST /trim`
- **Parameters:**
  - `audio_file` (multipart file)
  - `start_time` (float, seconds)
  - `end_time` (float, seconds)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

#### Merge Audio
- **Endpoint:** `POST /merge`
- **Parameters:**
  - `audio_files` (multiple multipart files, at least 2)
- **Response:** `{ "url": "...", "filename": "...", "path": "..." }`

### Environment-Specific Behavior

**Development:**
- Files saved to `./media/{type}/` directory
- Returned paths: `/media/{type}/{filename}`
- Backend serves files via `/media` endpoint

**Production:**
- Files uploaded to S3 bucket
- Returned URLs: `https://cloudfront.net/{type}/{filename}`
- Files served via CloudFront CDN

## Troubleshooting

### Common Issues

#### 1. Media URLs Not Resolving

**Symptoms:**
- 404 errors when loading media
- Images/videos not displaying

**Solutions:**
- Verify `MEDIA_BASE_URL` is set correctly
- Check environment detection logic (localhost vs production)
- Verify backend is serving `/media` endpoint in development
- Check CloudFront distribution in production

#### 2. Blob URLs Not Working

**Symptoms:**
- Video/audio editor shows "format not supported"
- Blob URLs not being uploaded

**Solutions:**
- Verify `uploadTemporaryMedia()` is being called
- Check backend `/api/v1/upload/temporary-{type}` endpoint
- Ensure blob URL is converted to backend URL before editing

#### 3. State Not Persisting

**Symptoms:**
- Editor state lost on page reload
- Trim/rotation settings reset

**Solutions:**
- Check browser localStorage is enabled
- Verify `StatePersistence.saveVideoEditorState()` is called
- Check state expiration (1 hour limit)
- Verify state is being restored in `_initializeFromSavedState()`

#### 4. Environment Detection Issues

**Symptoms:**
- Development URLs used in production
- Production URLs used in development

**Solutions:**
- Verify `ENVIRONMENT` variable is set correctly
- Check URL patterns match detection logic
- Review `_isDevelopmentEnvironment()` helper method
- Check `getMediaUrl()` implementation

#### 5. File Processing Failures

**Symptoms:**
- Editing operations fail
- FFmpeg errors in backend logs

**Solutions:**
- Verify FFmpeg is installed on backend server
- Check file format compatibility
- Review backend error logs
- Verify file upload is successful before processing

### Debugging Tips

1. **Enable Console Logging:**
   - Web: Check browser console for URL construction logs
   - Mobile: Check Flutter debug console

2. **Verify Environment Variables:**
   - Web: Check `AppConfig` values at runtime
   - Mobile: Check `Environment` class values

3. **Test URL Resolution:**
   - Use `ApiService.getMediaUrl()` directly
   - Check returned URLs match expected format

4. **Check Backend Logs:**
   - Verify file uploads are successful
   - Check FFmpeg processing logs
   - Verify S3 uploads in production

## Related Files

### Web Frontend
- `web/frontend/lib/config/app_config.dart` - Environment configuration
- `web/frontend/lib/services/api_service.dart` - API client and URL resolution
- `web/frontend/lib/services/video_editing_service.dart` - Video editing operations
- `web/frontend/lib/services/audio_editing_service.dart` - Audio editing operations
- `web/frontend/lib/utils/state_persistence.dart` - State persistence utility
- `web/frontend/lib/screens/web/video_editor_screen_web.dart` - Video editor UI
- `web/frontend/lib/screens/editing/audio_editor_screen.dart` - Audio editor UI

### Mobile Frontend
- `mobile/frontend/lib/config/environment.dart` - Environment configuration
- `mobile/frontend/lib/services/api_service.dart` - API client and URL resolution
- `mobile/frontend/lib/services/video_editing_service.dart` - Video editing operations
- `mobile/frontend/lib/services/audio_editing_service.dart` - Audio editing operations

### Backend
- `backend/app/routes/video_editing.py` - Video editing API endpoints
- `backend/app/routes/audio_editing.py` - Audio editing API endpoints
- `backend/app/config.py` - Backend configuration
- `backend/app/services/video_editing_service.py` - Video processing service
- `backend/app/services/audio_editing_service.py` - Audio processing service

## Summary

The editor system is designed to work seamlessly across environments with:

- **Automatic environment detection** based on URL patterns
- **Consistent media URL resolution** for both development and production
- **Robust blob URL handling** for web MediaRecorder integration
- **State persistence** to preserve user work across sessions
- **Hybrid file processing** (local on mobile, server-side on web)
- **Comprehensive error handling** and fallback mechanisms

All editors are production-ready and fully tested in both local development and production environments.

