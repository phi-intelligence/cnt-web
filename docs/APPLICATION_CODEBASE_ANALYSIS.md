# CNT Media Platform - Complete Codebase Analysis

**Date:** December 2024  
**Status:** Comprehensive code-level analysis of the entire application  
**Focus:** Web Frontend (Flutter Web) + Backend (FastAPI) + Database (PostgreSQL/SQLite) + AWS Infrastructure

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Code Structure Overview](#code-structure-overview)
3. [Backend Architecture - Code Analysis](#backend-architecture-code)
4. [Frontend Architecture - Code Analysis](#frontend-architecture-code)
5. [Database Schema - All Tables](#database-schema-all-tables)
6. [API Routes - Complete Implementation](#api-routes-complete)
7. [Services Layer - Detailed Analysis](#services-layer)
8. [Authentication Flow - Code Implementation](#authentication-flow-code)
9. [Media Storage & URL Resolution - Implementation](#media-storage-implementation)
10. [State Management - Provider Pattern](#state-management-providers)
11. [Key Workflows - Code Implementation](#key-workflows-code)
12. [Deployment Configuration - Actual Setup](#deployment-configuration-actual)

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application with the following architecture:

### Technology Stack (Verified from Code)

**Backend:**
- **Framework**: FastAPI (Python 3.11+)
- **ORM**: SQLAlchemy 2.0 (async support)
- **Database**: PostgreSQL (production via AWS RDS) / SQLite (local development)
- **Storage**: AWS S3 + CloudFront CDN
- **Hosting**: AWS EC2 (eu-west-2, IP: 52.56.78.203)
- **Container**: Docker (3 containers: backend, LiveKit server, voice agent)

**Frontend (Web):**
- **Framework**: Flutter Web (Dart SDK >=3.0.0)
- **State Management**: Provider pattern (14 providers)
- **Routing**: GoRouter 13.0.0
- **Hosting**: AWS Amplify
- **Build**: Flutter build web with `--dart-define` flags

**Media Storage:**
- **S3 Bucket**: `cnt-web-media` (eu-west-2)
- **CloudFront**: Distribution serving media via CDN
- **URL Pattern**: `https://d126sja5o8ue54.cloudfront.net/{path}`

**Real-Time Services:**
- **LiveKit**: Meetings, live streaming, voice agent (Docker container)
- **WebSocket**: Socket.io for notifications

---

## Code Structure Overview

### Project Root Structure

```
cnt-web-deployment/
├── backend/                    # FastAPI backend
│   ├── app/
│   │   ├── main.py            # FastAPI app entry point
│   │   ├── config.py          # Settings (Pydantic BaseSettings)
│   │   ├── database/          # DB connection (lazy initialization)
│   │   ├── models/            # SQLAlchemy models (27 tables)
│   │   ├── routes/            # API route handlers (27 files)
│   │   ├── services/          # Business logic (15 files)
│   │   ├── schemas/           # Pydantic request/response models
│   │   ├── middleware/        # Auth middleware
│   │   ├── agents/            # Voice agent (LiveKit)
│   │   └── websocket/         # Socket.io handlers
│   ├── Dockerfile             # Backend container
│   ├── requirements.txt       # Python dependencies
│   └── .env                   # Environment variables (not in git)
│
├── web/frontend/              # Flutter Web application
│   ├── lib/
│   │   ├── main.dart         # App entry point
│   │   ├── config/           # AppConfig (env variables)
│   │   ├── navigation/       # GoRouter setup
│   │   ├── screens/          # UI screens (90+ files)
│   │   ├── services/         # API clients (11 files)
│   │   ├── providers/        # State management (14 files)
│   │   ├── models/           # Data models
│   │   ├── widgets/          # Reusable widgets (56 files)
│   │   ├── theme/            # Design system
│   │   └── utils/            # Utility functions (21 files)
│   ├── pubspec.yaml          # Dart dependencies
│   └── web/                  # Web assets (index.html, manifest.json)
│
├── mobile/frontend/           # Flutter Mobile (in development)
├── amplify.yml                # AWS Amplify build configuration
└── docker-compose*.yml        # Docker orchestration files
```

---

## Backend Architecture - Code Analysis

### Entry Point: `backend/app/main.py`

**Key Features:**
- FastAPI app initialization with CORS middleware
- Proxy headers middleware (for ALB/nginx)
- Static file mounting (development only)
- Socket.io integration (ASGIApp wrapper)
- Voice agent auto-start (can be disabled for Docker)
- Health check endpoints (`/`, `/health`)

**Startup Events:**
```python
@app.on_event("startup")
async def startup_event():
    # Start voice agent (if not disabled)
    # Seed Bible document (development only)
```

**Shutdown Events:**
```python
@app.on_event("shutdown")
async def shutdown_event():
    # Stop voice agent gracefully
```

### Configuration: `backend/app/config.py`

**Settings Class:** Uses Pydantic `BaseSettings` with `.env` file support

**Key Settings:**
- `DATABASE_URL` - PostgreSQL/SQLite connection string
- `S3_BUCKET_NAME` - S3 bucket name (`cnt-web-media`)
- `CLOUDFRONT_URL` - CloudFront distribution URL
- `SECRET_KEY` - JWT signing key
- `LIVEKIT_WS_URL`, `LIVEKIT_HTTP_URL` - LiveKit endpoints
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` - LiveKit credentials
- `OPENAI_API_KEY`, `DEEPGRAM_API_KEY` - AI service keys
- `CORS_ORIGINS` - Comma-separated allowed origins
- `ENVIRONMENT` - "production" or "development"

### Database Connection: `backend/app/database/connection.py`

**Lazy Initialization Pattern:**
- Engine created on first use (prevents import-time DB connection)
- Supports both PostgreSQL (asyncpg) and SQLite (aiosqlite)
- Connection pooling for PostgreSQL
- Async session factory (`AsyncSessionLocal`)

**Key Functions:**
- `get_engine()` - Creates async engine on first call
- `get_async_session_local()` - Creates session factory
- `get_db()` - FastAPI dependency for database sessions

### Database Models: `backend/app/models/`

**27 Total Models (Tables):**

1. **User Models (3):**
   - `User` - User accounts
   - `RefreshToken` - JWT refresh tokens
   - `DeviceToken` - Push notification tokens

2. **Content Models (6):**
   - `Podcast` - Audio/video podcasts
   - `Movie` - Full-length movies
   - `MusicTrack` - Music content
   - `DocumentAsset` - PDF documents
   - `BibleStory` - Bible story content
   - `ContentDraft` - Draft content storage

3. **Community Models (3):**
   - `CommunityPost` - Social media posts
   - `Comment` - Post comments
   - `Like` - Post likes

4. **Artist Models (2):**
   - `Artist` - Creator profiles
   - `ArtistFollower` - Follow relationships

5. **Playlist Models (2):**
   - `Playlist` - User playlists
   - `PlaylistItem` - Playlist content

6. **Payment Models (3):**
   - `BankDetails` - Creator payment info
   - `PaymentAccount` - Payment gateway accounts
   - `Donation` - Donation transactions

7. **Real-Time Models (1):**
   - `LiveStream` - Meeting/stream records

8. **Support Models (1):**
   - `SupportMessage` - Support tickets

9. **Other Models (6):**
   - `Notification` - User notifications
   - `Category` - Content categories
   - `EmailVerification` - Email verification tokens
   - `Event` - Event management
   - `EventAttendee` - Event attendance
   - `Favorite` - User favorites

### API Routes: `backend/app/routes/__init__.py`

**27 Route Modules Registered:**

1. `auth` - Authentication endpoints (`/api/v1/auth`)
2. `podcasts` - Podcast CRUD (`/api/v1/podcasts`)
3. `music` - Music CRUD (`/api/v1/music`)
4. `movies` - Movie CRUD (`/api/v1/movies`)
5. `playlists` - Playlist management (`/api/v1/playlists`)
6. `categories` - Categories (`/api/v1/categories`)
7. `community` - Community posts, likes, comments (`/api/v1/community`)
8. `support` - Support tickets (`/api/v1/support`)
9. `users` - User management (`/api/v1/users`)
10. `admin` - Admin dashboard (`/api/v1/admin`)
11. `upload` - File upload endpoints (`/api/v1/upload`)
12. `documents` - PDF documents (`/api/v1/documents`)
13. `donations` - Donations (`/api/v1/donations`)
14. `bank_details` - Bank details (`/api/v1/bank-details`)
15. `bible_stories` - Bible stories (`/api/v1/bible-stories`)
16. `audio_editing` - Audio editing (`/api/v1/audio-editing`)
17. `video_editing` - Video editing (`/api/v1/video-editing`)
18. `live_stream` - Live streaming (`/api/v1/live`)
19. `livekit_voice` - Voice agent (`/api/v1/livekit`)
20. `voice_chat` - Voice chat (`/api/v1/voice-chat`)
21. `admin_google_drive` - Google Drive bulk upload (`/api/v1/admin/google-drive`)
22. `artists` - Artist profiles (`/api/v1/artists`)
23. `notifications` - Notifications (`/api/v1/notifications`)
24. `events` - Events (`/api/v1/events`)
25. `device_tokens` - Push notifications (`/api/v1/device-tokens`)
26. `content_drafts` - Content drafts (`/api/v1/drafts`)
27. `favorites` - User favorites (`/api/v1/favorites`)
28. `media` - Media metadata (`/api/v1/media`)
29. `search` - Search functionality (`/api/v1/search`)

### Services Layer: `backend/app/services/`

**15 Service Files:**

1. **`auth_service.py`** - Authentication logic
   - Password hashing (bcrypt)
   - JWT token creation/decoding
   - Token expiration handling

2. **`username_service.py`** - Unique username generation
   - Generates unique usernames from names
   - Handles collisions with suffixes

3. **`media_service.py`** - S3/local file operations
   - File uploads (audio, video, images, documents)
   - S3 multipart uploads for large files
   - CloudFront URL generation
   - Local storage for development

4. **`thumbnail_service.py`** - Thumbnail generation
   - Video frame extraction (FFmpeg)
   - Thumbnail saving to S3/local

5. **`quote_image_service.py`** - Quote image generation
   - PIL/Pillow image generation
   - Text wrapping and sizing
   - Template selection

6. **`audio_editing_service.py`** - FFmpeg audio processing
   - Trim, merge, fade effects

7. **`video_editing_service.py`** - FFmpeg video processing
   - Trim, audio management, text overlays, filters

8. **`artist_service.py`** - Artist profile logic
   - Auto-creation on first content upload

9. **`livekit_service.py`** - LiveKit integration
   - Room creation
   - Token generation

10. **`ai_service.py`** - OpenAI integration
    - GPT-4o-mini for voice agent

11. **`payment_service.py`** - Stripe/PayPal integration

12. **`email_service.py`** - AWS SES email sending

13. **`notification_service.py`** - Notification logic

14. **`google_drive_service.py`** - Google Drive API

15. **`refresh_token_service.py`** - Refresh token management
    - Token rotation support
    - Expiration handling

### Authentication Middleware: `backend/app/middleware/auth_middleware.py`

**Key Dependencies:**
- `get_current_user()` - Validates JWT and returns User object
- `require_admin()` - Requires admin role
- `get_current_user_optional()` - Optional authentication

**Flow:**
1. Extract token from `Authorization: Bearer <token>` header
2. Decode JWT token
3. Extract user_id from `sub` claim
4. Query database for user
5. Return User object or raise 401

---

## Frontend Architecture - Code Analysis

### Entry Point: `web/frontend/lib/main.dart`

**Simple Entry Point:**
```dart
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const AppRouter();
  }
}
```

### App Router: `web/frontend/lib/navigation/app_router.dart`

**Key Features:**
- MultiProvider setup (14 providers)
- GoRouter configuration
- WebSocket initialization (post-frame callback)
- Theme setup (light/dark mode)

**Providers Registered:**
1. `AuthProvider` - Authentication state
2. `AppState` - Global app state
3. `MusicProvider` - Music playback
4. `CommunityProvider` - Community posts
5. `AudioPlayerState` - Audio playback state
6. `SearchProvider` - Search functionality
7. `UserProvider` - User data
8. `PlaylistProvider` - Playlists
9. `FavoritesProvider` - User favorites
10. `SupportProvider` - Support tickets
11. `DocumentsProvider` - PDF documents
12. `NotificationProvider` - Push notifications
13. `ArtistProvider` - Artist profiles
14. `EventProvider` - Events

### Routes: `web/frontend/lib/navigation/app_routes.dart`

**Route Structure:**
- `/` - Landing page (login)
- `/home` - Home screen
- `/podcasts` - Podcast listing
- `/movies` - Movie listing
- `/community` - Community feed
- `/create` - Content creation hub
- `/profile` - User profile
- `/admin/*` - Admin routes (admin-only)
- `/live/*` - Live streaming routes
- `/meetings/*` - Meeting routes
- `/voice/*` - Voice agent routes
- `/bible` - Bible reader
- `/events/*` - Event management
- `/my-drafts` - Content drafts

**Route Guards:**
- Authentication required for protected routes
- Admin-only routes check `isAdmin` flag
- Redirects to `/` if not authenticated
- Redirects to `/home` if authenticated and on landing page

### API Service: `web/frontend/lib/services/api_service.dart`

**Size:** 3736 lines (comprehensive REST API client)

**Key Features:**
- Singleton pattern
- Automatic token injection via `_getHeaders()`
- Token refresh on 401 errors
- Media URL resolution (CloudFront/local)
- Error handling and retry logic

**Media URL Resolution Logic:**
1. Check if already full URL (http/https) → return as-is
2. Convert S3 URLs to CloudFront URLs
3. Handle `/media/` prefix (strip in production, keep in dev)
4. Development: Add `/media/` prefix (backend serves from `/media`)
5. Production: Use direct CloudFront path

**Example:**
```dart
String getMediaUrl(String? path) {
  // Full URL → return as-is
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  // Production: Strip media/ prefix, use CloudFront
  // Development: Keep media/ prefix, use backend URL
  if (cleanPath.startsWith('media/')) {
    if (isDev) {
      return '$mediaBaseUrl/media/$cleanPath';
    } else {
      cleanPath = cleanPath.substring(6); // Remove 'media/'
      return '$mediaBaseUrl/$cleanPath';
    }
  }
}
```

### Auth Service: `web/frontend/lib/services/auth_service.dart`

**Storage:**
- Web: `WebStorageService` (localStorage/sessionStorage)
- Mobile: `FlutterSecureStorage` (encrypted)

**Key Methods:**
- `login()` - Email/password login
- `register()` - User registration
- `googleLogin()` - Google OAuth login
- `getToken()` - Get stored access token
- `getRefreshToken()` - Get stored refresh token
- `refreshAccessToken()` - Refresh expired token
- `logout()` - Clear tokens and user data
- `isTokenExpired()` - Check token expiration

**Token Storage Keys:**
- `auth_token` - JWT access token
- `refresh_token` - Refresh token
- `user_data` - Cached user information

### Auth Provider: `web/frontend/lib/providers/auth_provider.dart`

**Features:**
- Auto-login on app start
- Token expiration monitoring (every 5 minutes)
- Visibility change detection (web)
- Proactive token refresh (before expiration)
- State management for authentication

**Key Methods:**
- `checkAuthStatus()` - Check if user is logged in
- `login()` - Login with credentials
- `logout()` - Logout and clear state
- `_checkTokenExpiration()` - Monitor token expiration
- `_startTokenExpirationCheck()` - Periodic checks

---

## Database Schema - All Tables

### Complete Table List (27 Tables)

**1. users**
- Primary user accounts table
- Fields: id, username, name, email, avatar, password_hash, is_admin, phone, date_of_birth, bio, google_id, auth_provider, created_at, updated_at

**2. refresh_tokens**
- JWT refresh token storage
- Fields: id, user_id, token, expires_at, created_at

**3. device_tokens**
- Push notification device tokens
- Fields: id, user_id, token, platform, created_at

**4. podcasts**
- Audio/video podcasts
- Fields: id, title, description, audio_url, video_url, cover_image, creator_id, category_id, duration, status, plays_count, created_at

**5. movies**
- Full-length movies
- Fields: id, title, description, video_url, cover_image, preview_url, preview_start_time, preview_end_time, director, cast, release_date, rating, category_id, creator_id, duration, status, plays_count, is_featured, created_at

**6. music_tracks**
- Music content
- Fields: id, title, artist, album, genre, audio_url, cover_image, duration, lyrics, is_featured, is_published, plays_count, created_at

**7. documents**
- PDF documents (Bible, etc.)
- Fields: id, title, file_url, file_type, file_size, created_at

**8. bible_stories**
- Bible story content
- Fields: id, title, scripture_reference, content, audio_url, cover_image, created_at

**9. content_drafts**
- Draft content storage
- Fields: id, user_id, content_type, content_data, created_at, updated_at

**10. community_posts**
- Social media posts
- Fields: id, user_id, title, content, image_url, category, post_type, is_approved, likes_count, comments_count, created_at

**11. comments**
- Post comments
- Fields: id, post_id, user_id, content, created_at

**12. likes**
- Post likes
- Fields: id, post_id, user_id, created_at
- Unique constraint: (post_id, user_id)

**13. artists**
- Creator profiles
- Fields: id, user_id, artist_name, cover_image, bio, social_links, followers_count, total_plays, is_verified, created_at, updated_at

**14. artist_followers**
- Follow relationships
- Fields: id, artist_id, user_id, created_at
- Unique constraint: (artist_id, user_id)

**15. playlists**
- User playlists
- Fields: id, user_id, name, description, cover_image, created_at

**16. playlist_items**
- Playlist content
- Fields: id, playlist_id, content_type, content_id, position

**17. bank_details**
- Creator payment info
- Fields: id, user_id, account_number, ifsc_code, swift_code, bank_name, account_holder_name, branch_name, is_verified, created_at, updated_at

**18. payment_accounts**
- Payment gateway accounts
- Fields: id, user_id, provider, account_id, is_active

**19. donations**
- Donation transactions
- Fields: id, user_id, recipient_id, amount, currency, status, payment_method, created_at

**20. live_streams**
- Meeting/stream records
- Fields: id, user_id, title, description, status, room_name, started_at, ended_at, created_at

**21. support_messages**
- Support tickets
- Fields: id, user_id, subject, message, status, admin_response, created_at

**22. notifications**
- User notifications
- Fields: id, user_id, type, title, message, data, is_read, created_at

**23. categories**
- Content categories
- Fields: id, name, type

**24. email_verifications**
- Email verification tokens
- Fields: id, email, otp_code, expires_at, verified, created_at

**25. events**
- Event management
- Fields: id, host_id, title, description, start_time, end_time, location, latitude, longitude, category, created_at, updated_at

**26. event_attendees**
- Event attendance
- Fields: id, event_id, user_id, status, created_at
- Unique constraint: (event_id, user_id)

**27. favorites**
- User favorites
- Fields: id, user_id, content_type, content_id, created_at
- Unique constraint: (user_id, content_type, content_id)

---

## API Routes - Complete Implementation

### Authentication Routes (`/api/v1/auth`)

- `POST /login` - Email/password login
- `POST /register` - User registration
- `POST /google-login` - Google OAuth login
- `POST /send-otp` - Send OTP verification code
- `POST /verify-otp` - Verify OTP code
- `POST /register-with-otp` - Register with verified email
- `POST /check-username` - Check username availability
- `GET /google-client-id` - Get Google OAuth client ID
- `POST /refresh-token` - Refresh access token

### Content Routes

**Podcasts (`/api/v1/podcasts`):**
- `GET /` - List podcasts (with filters)
- `POST /` - Create podcast
- `GET /{id}` - Get podcast details

**Movies (`/api/v1/movies`):**
- `GET /` - List movies
- `POST /` - Create movie
- `GET /{id}` - Get movie details

**Music (`/api/v1/music`):**
- `GET /` - List music tracks
- `POST /` - Create music track

### Community Routes (`/api/v1/community`)

- `GET /posts` - List posts
- `POST /posts` - Create post
- `GET /posts/{id}` - Get post details
- `POST /posts/{id}/like` - Like/unlike post
- `POST /posts/{id}/comments` - Add comment
- `GET /posts/{id}/comments` - Get comments

### Upload Routes (`/api/v1/upload`)

- `POST /audio` - Upload audio file
- `POST /video` - Upload video file
- `POST /image` - Upload image
- `POST /profile-image` - Upload avatar
- `POST /thumbnail` - Upload thumbnail
- `POST /temporary-audio` - Upload temp audio (editing)
- `POST /document` - Upload PDF (admin only)
- `GET /media/duration` - Get media duration
- `GET /thumbnail/defaults` - Get default thumbnails

### Editing Routes

**Audio Editing (`/api/v1/audio-editing`):**
- `POST /trim` - Trim audio
- `POST /merge` - Merge audio files
- `POST /fade-in` - Fade in effect
- `POST /fade-out` - Fade out effect
- `POST /fade-in-out` - Fade in/out

**Video Editing (`/api/v1/video-editing`):**
- `POST /trim` - Trim video
- `POST /remove-audio` - Remove audio track
- `POST /add-audio` - Add audio track
- `POST /replace-audio` - Replace audio track
- `POST /add-text-overlays` - Add text overlays
- `POST /apply-filters` - Apply filters

### Artist Routes (`/api/v1/artists`)

- `GET /me` - Get current user's artist profile
- `PUT /me` - Update artist profile
- `POST /me/cover-image` - Upload cover image
- `GET /{id}` - Get artist profile
- `GET /{id}/podcasts` - Get artist podcasts
- `POST /{id}/follow` - Follow artist
- `DELETE /{id}/follow` - Unfollow artist

### Live/Voice Routes

**Live Streaming (`/api/v1/live`):**
- `GET /streams` - List streams
- `POST /streams` - Create stream
- `POST /streams/{id}/join` - Join stream
- `POST /streams/{id}/livekit-token` - Get LiveKit token

**Voice Agent (`/api/v1/livekit`):**
- `POST /voice/token` - Get voice agent token
- `POST /voice/room` - Create voice room
- `DELETE /voice/room/{name}` - Delete voice room
- `GET /voice/rooms` - List voice rooms
- `GET /voice/health` - Voice agent health

### Admin Routes (`/api/v1/admin`)

- `GET /dashboard` - Admin stats
- `GET /pending` - Pending content
- `POST /approve/{type}/{id}` - Approve content
- `POST /reject/{type}/{id}` - Reject content

### Other Routes

- `/api/v1/playlists/*` - Playlist management
- `/api/v1/users/*` - User management
- `/api/v1/support/*` - Support tickets
- `/api/v1/documents/*` - PDF documents
- `/api/v1/bible-stories/*` - Bible stories
- `/api/v1/notifications/*` - Notifications
- `/api/v1/events/*` - Events
- `/api/v1/donations/*` - Donations
- `/api/v1/bank-details/*` - Bank details
- `/api/v1/favorites/*` - User favorites
- `/api/v1/drafts/*` - Content drafts
- `/api/v1/device-tokens/*` - Push notification tokens
- `/api/v1/media/*` - Media metadata
- `/api/v1/search/*` - Search functionality

---

## Services Layer

### Media Service: `backend/app/services/media_service.py`

**Key Methods:**

1. **`save_audio_file(file, filename)`**
   - S3: Upload to `audio/{filename}`, return CloudFront URL
   - Local: Save to `media/audio/{filename}`, return `/media/audio/{filename}`

2. **`save_video_file(file, filename)`**
   - S3: Multipart upload for large files (>100MB)
   - Upload to `video/{filename}`, return CloudFront URL
   - Local: Stream to disk, return `/media/video/{filename}`

3. **`save_image_file(file, filename, subfolder=None)`**
   - S3: Upload to `images/{subfolder}/{filename}` or `images/{filename}`
   - Local: Save to appropriate directory

4. **`save_thumbnail_file(file, filename, type="custom")`**
   - Custom: `images/thumbnails/podcasts/custom/{filename}`
   - Generated: `images/thumbnails/podcasts/generated/{filename}`

5. **`save_quote_image(image_bytes, post_id, hash)`**
   - Saves to: `images/quotes/quote_{post_id}_{hash}.jpg`

6. **`get_duration(file_path)`**
   - Uses FFprobe to get media duration

**S3 Configuration:**
- Bucket: `cnt-web-media` (eu-west-2)
- CloudFront URL: From `settings.CLOUDFRONT_URL`
- Multipart upload threshold: 100MB
- Chunk size: 50MB

### Auth Service: `backend/app/services/auth_service.py`

**Key Methods:**

1. **`verify_password(plain_password, hashed_password)`**
   - Uses bcrypt for password verification

2. **`get_password_hash(password)`**
   - Uses bcrypt for password hashing

3. **`create_access_token(data: dict, expires_delta: timedelta)`**
   - Creates JWT token with expiration
   - Uses `SECRET_KEY` for signing
   - Default expiration: 30 minutes

4. **`decode_access_token(token: str)`**
   - Decodes and validates JWT token
   - Returns payload or None if invalid

---

## Authentication Flow - Code Implementation

### Backend Flow

**Login Endpoint (`POST /api/v1/auth/login`):**

1. Receive `username_or_email` and `password`
2. Find user by email or username
3. Verify password using `verify_password()`
4. Create access token using `create_access_token()`
5. Create refresh token (if rotation enabled)
6. Return tokens and user data

**Token Structure:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "refresh_token": "refresh_token_string",
  "token_type": "bearer",
  "user_id": 1,
  "username": "john_doe",
  "email": "user@example.com",
  "name": "John Doe",
  "is_admin": false
}
```

**Token Validation (`get_current_user` dependency):**

1. Extract token from `Authorization: Bearer <token>` header
2. Decode token using `decode_access_token()`
3. Extract `user_id` from `sub` claim
4. Query database for user
5. Return User object or raise 401

### Frontend Flow

**Login Process:**

1. User enters credentials
2. `AuthService.login()` calls `POST /api/v1/auth/login`
3. Store tokens in `WebStorageService` (localStorage/sessionStorage)
4. Store user data
5. `AuthProvider` updates state
6. Navigate to `/home`

**Token Refresh Process:**

1. `AuthProvider` checks token expiration (every 5 minutes)
2. If expires within 5 minutes, call `AuthService.refreshAccessToken()`
3. `refreshAccessToken()` calls `POST /api/v1/auth/refresh-token`
4. Update stored access token
5. If refresh fails, logout user

**Auto-Login on App Start:**

1. `AuthProvider.checkAuthStatus()` called in constructor
2. Check if token exists in storage
3. Validate token expiration
4. If valid, fetch user data
5. Update authentication state

---

## Media Storage & URL Resolution - Implementation

### S3 Bucket Structure

```
cnt-web-media/
├── audio/                          # Audio podcast files
│   └── {uuid}.{ext}               # MP3, WAV, WebM, M4A, AAC, FLAC
│
├── video/                          # Video podcast files
│   ├── {uuid}.{ext}               # MP4, WebM, etc.
│   └── previews/                  # Short preview clips (optional)
│
├── images/
│   ├── quotes/                    # Generated quote images
│   │   └── quote_{post_id}_{hash}.jpg
│   │
│   ├── thumbnails/
│   │   ├── podcasts/
│   │   │   ├── custom/           # User-uploaded thumbnails
│   │   │   └── generated/       # Auto-generated from video
│   │   └── default/              # Default templates (1-12.jpg)
│   │
│   ├── movies/                    # Movie posters/cover images
│   ├── profiles/                  # User profile images
│   └── {uuid}.{ext}               # General images (community posts)
│
├── documents/                      # PDF documents (Bible, etc.)
│   └── {filename}.pdf
│
└── animated-bible-stories/         # Video files for Bible stories
    └── *.mp4
```

### URL Resolution Logic

**Backend (`media_service.py`):**

- Production: Returns CloudFront URLs
  - Format: `{CLOUDFRONT_URL}/{path}`
  - Example: `https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3`

- Development: Returns local paths
  - Format: `/media/{path}`
  - Example: `/media/audio/abc123.mp3`

**Frontend (`api_service.dart` - `getMediaUrl()` method):**

1. **Full URL Check:**
   - If path starts with `http://` or `https://`, return as-is
   - Convert S3 URLs to CloudFront URLs if needed

2. **Development Mode:**
   - Add `/media/` prefix
   - Use backend URL (e.g., `http://localhost:8002/media/audio/file.mp3`)

3. **Production Mode:**
   - Strip `/media/` prefix if present
   - Use CloudFront URL directly (e.g., `https://cloudfront.net/audio/file.mp3`)

4. **Path Patterns:**
   - `images/`, `audio/`, `video/`, `documents/` → Direct CloudFront paths
   - `media/` prefix → Strip in production, keep in development
   - `assets/images/` → Convert to `images/`

---

## State Management - Provider Pattern

### Provider Structure

**14 Providers Registered in `app_router.dart`:**

1. **`AuthProvider`** (`auth_provider.dart`)
   - Authentication state
   - User data
   - Token management
   - Auto-login

2. **`AppState`** (`app_state.dart`)
   - Global app state
   - Theme settings
   - App-wide flags

3. **`AudioPlayerState`** (`audio_player_provider.dart`)
   - Currently playing audio
   - Playback state (playing, paused, stopped)
   - Playback position
   - Playlist queue

4. **`MusicProvider`** (`music_provider.dart`)
   - Music tracks
   - Music playback

5. **`CommunityProvider`** (`community_provider.dart`)
   - Community posts
   - Comments
   - Likes
   - Post creation/editing

6. **`SearchProvider`** (`search_provider.dart`)
   - Search queries
   - Search results
   - Search filters

7. **`UserProvider`** (`user_provider.dart`)
   - Current user data
   - User profile
   - User preferences

8. **`PlaylistProvider`** (`playlist_provider.dart`)
   - User playlists
   - Playlist items
   - Playlist management

9. **`FavoritesProvider`** (`favorites_provider.dart`)
   - User favorites
   - Favorite management

10. **`SupportProvider`** (`support_provider.dart`)
    - Support tickets
    - Ticket creation/management

11. **`DocumentsProvider`** (`documents_provider.dart`)
    - PDF documents
    - Bible reading state

12. **`NotificationProvider`** (`notification_provider.dart`)
    - User notifications
    - Notification state (read/unread)

13. **`ArtistProvider`** (`artist_provider.dart`)
    - Artist profiles
    - Follow relationships

14. **`EventProvider`** (`event_provider.dart`)
    - Events
    - Event attendance

### Provider Usage Pattern

**Accessing Providers:**
```dart
// Using Consumer
Consumer<AuthProvider>(
  builder: (context, authProvider, _) {
    if (authProvider.isAuthenticated) {
      return Text('Logged in as ${authProvider.user?['name']}');
    }
    return Text('Not logged in');
  },
)

// Using Provider.of
final authProvider = Provider.of<AuthProvider>(context);
```

---

## Key Workflows - Code Implementation

### 1. User Registration Flow

**Frontend:**
1. User fills registration form
2. `AuthService.register()` called
3. POST to `/api/v1/auth/register`
4. Store tokens and user data
5. Navigate to `/home`

**Backend (`routes/auth.py`):**
1. Validate input data
2. Check if email exists
3. Hash password using `get_password_hash()`
4. Generate unique username using `generate_unique_username()`
5. Create user record
6. Create access token
7. Return tokens and user data

### 2. Content Creation Flow (Audio Podcast)

**Frontend:**
1. User selects audio file
2. Upload via `POST /api/v1/upload/audio`
3. Get file URL and duration
4. User fills title, description, category
5. Create podcast via `POST /api/v1/podcasts`
6. Status: "pending" (requires admin approval)

**Backend:**
1. `routes/upload.py` - `upload_audio()` endpoint
   - Validate file type
   - Generate unique filename (UUID)
   - Save to S3/local via `media_service.save_audio_file()`
   - Get duration using FFprobe
   - Return file URL and metadata

2. `routes/podcasts.py` - `create_podcast()` endpoint
   - Validate input
   - Create podcast record (status: "pending")
   - Auto-create artist profile if needed
   - Return podcast data

### 3. Community Post Creation Flow

**Image Post:**
1. User selects image
2. Upload via `POST /api/v1/upload/image`
3. Get image URL
4. Create post via `POST /api/v1/community/posts`
5. Status: `is_approved = 0` (pending)

**Text Post (Quote Image Generation):**
1. User enters text content
2. Create post via `POST /api/v1/community/posts` (no image yet)
3. Backend detects `post_type='text'`
4. `quote_image_service.generate_quote_image()` called
5. Select random template
6. Render text with PIL/Pillow
7. Save to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
8. Update post with `image_url`
9. Return post data with CloudFront URL

**Backend (`routes/community.py`):**
- `create_post()` endpoint
- If `post_type='text'`, call `quote_image_service.generate_quote_image()`
- Save quote image to S3
- Update post record
- Return post data

---

## Deployment Configuration - Actual Setup

### Backend (EC2)

**Docker Containers (from `docker ps`):**

1. **`cnt-backend`** - FastAPI backend
   - Image: `cnt-web-deployment_backend:latest`
   - Port: `8000:8000`
   - Command: `uvicorn app.main:app --host 0.0.0.0 --port 8000`

2. **`cnt-livekit-server`** - LiveKit server
   - Image: `livekit/livekit-server:latest`
   - Ports: `7880-7881:7880-7881` (HTTP/WebSocket)
   - Ports: `50100-50200:50100-50200/udp` (RTC)

3. **`cnt-voice-agent`** - Voice agent process
   - Image: `cnt-web-deployment_voice-agent`
   - Runs LiveKit agent for AI voice assistant

**Environment Variables (`.env` on EC2):**
- `DATABASE_URL` - PostgreSQL connection string
- `S3_BUCKET_NAME` - `cnt-web-media`
- `CLOUDFRONT_URL` - CloudFront distribution URL
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` - AWS credentials
- `LIVEKIT_WS_URL`, `LIVEKIT_HTTP_URL` - LiveKit endpoints
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` - LiveKit credentials
- `OPENAI_API_KEY`, `DEEPGRAM_API_KEY` - AI service keys
- `SECRET_KEY` - JWT signing key
- `ENVIRONMENT=production`
- `DISABLE_VOICE_AGENT_AUTO_START=true` (runs as separate container)

### Frontend (AWS Amplify)

**Build Configuration (`amplify.yml`):**

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - git clone https://github.com/flutter/flutter.git -b stable --depth 1
        - export PATH="$PATH:$PWD/flutter/bin"
        - cd web/frontend
        - flutter pub get
    build:
      commands:
        - flutter build web --release --no-source-maps
          --dart-define=API_BASE_URL=$API_BASE_URL
          --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL
          --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL
          --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL
          --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL
          --dart-define=ENVIRONMENT=production
          --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
  artifacts:
    baseDirectory: web/frontend/build/web
    files:
      - '**/*'
```

**Amplify Environment Variables:**
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - CloudFront URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - Socket.io WebSocket URL
- `GOOGLE_CLIENT_ID` - Google OAuth client ID

### SSH Access

**EC2 Instance:**
- IP: `52.56.78.203`
- User: `ubuntu`
- Key: `christnew.pem` (root directory)
- Command: `ssh -i christnew.pem ubuntu@52.56.78.203`
- Working Directory: `~/cnt-web-deployment/backend`

---

## Summary

This document provides a complete code-level understanding of the CNT Media Platform, including:

✅ **Backend Architecture** - FastAPI structure, routes, services, models  
✅ **Frontend Architecture** - Flutter Web structure, providers, services, routing  
✅ **Database Schema** - All 27 tables with relationships  
✅ **API Endpoints** - Complete route registration and implementation  
✅ **Authentication** - JWT token flow, refresh tokens, middleware  
✅ **Media Storage** - S3 upload flow, CloudFront URL resolution  
✅ **State Management** - Provider pattern implementation  
✅ **Deployment** - Actual Docker setup, Amplify configuration  

The application is **production-ready** with all core features implemented and deployed on AWS infrastructure.

---

**Document Created:** December 2024  
**Last Updated:** Current Analysis  
**Status:** ✅ Complete code-level understanding achieved

