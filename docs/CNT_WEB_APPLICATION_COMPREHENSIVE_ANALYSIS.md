# CNT Media Platform - Complete Web Application Analysis

**Analysis Date:** December 12, 2025  
**Focus:** Web Frontend Application (Production on AWS Amplify)  
**Status:** Production-Ready

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application with a production-ready web frontend deployed on AWS Amplify and a FastAPI backend running on AWS EC2. The application provides content consumption, creation, social features, and real-time communication capabilities.

### Key Architecture Points

- **Web Frontend:** Flutter Web (Dart) - 39+ web-specific screens
- **Backend:** FastAPI (Python) on AWS EC2 (52.56.78.203)
- **Database:** PostgreSQL (AWS RDS) / SQLite (local dev)
- **Media Storage:** AWS S3 (`cnt-web-media`) + CloudFront CDN
- **Real-time:** LiveKit (meetings, streaming, voice agent)
- **State Management:** Provider pattern (13 providers)

---

## 1. Web Frontend Architecture

### 1.1 Technology Stack

**Framework & Language:**
- Flutter Web (Dart 3.0+)
- Material Design with custom theming
- GoRouter for navigation

**Key Dependencies (`pubspec.yaml`):**
- `provider: ^6.1.1` - State management
- `http: ^1.1.0` - REST API calls
- `socket_io_client: ^2.0.3+1` - WebSocket for notifications
- `just_audio: ^0.9.36` - Audio playback
- `video_player: ^2.8.2` - Video playback
- `livekit_client: ^2.1.0` - Real-time communication
- `go_router: ^13.0.0` - Navigation
- `google_sign_in: ^6.2.1` - OAuth
- `camera: ^0.10.5+2` - Camera/recording (web support)

### 1.2 Project Structure

```
web/frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   └── app_config.dart          # Environment-based configuration
│   ├── constants/
│   │   └── app_constants.dart       # App constants
│   ├── navigation/
│   │   ├── app_router.dart          # GoRouter setup with 13 providers
│   │   ├── app_routes.dart          # Route definitions
│   │   └── web_navigation.dart      # Web-specific navigation
│   ├── providers/                   # 13 state management providers
│   │   ├── auth_provider.dart       # Authentication state
│   │   ├── app_state.dart           # Global app state
│   │   ├── audio_player_provider.dart
│   │   ├── music_provider.dart
│   │   ├── community_provider.dart
│   │   ├── search_provider.dart
│   │   ├── user_provider.dart
│   │   ├── playlist_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── support_provider.dart
│   │   ├── documents_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── artist_provider.dart
│   │   └── event_provider.dart
│   ├── services/                    # 10 service files
│   │   ├── api_service.dart         # Main API service (2864 lines!)
│   │   ├── auth_service.dart        # Authentication
│   │   ├── websocket_service.dart   # Real-time notifications
│   │   ├── audio_editing_service.dart
│   │   ├── video_editing_service.dart
│   │   ├── google_auth_service.dart
│   │   ├── livekit_meeting_service.dart
│   │   ├── livekit_voice_service.dart
│   │   ├── donation_service.dart
│   │   └── download_service.dart
│   ├── screens/
│   │   ├── web/                     # 39 web-specific screens
│   │   ├── editing/                 # Audio/video editors
│   │   ├── admin/                   # Admin screens
│   │   └── ...                      # Shared screens
│   ├── models/                      # Data models
│   ├── widgets/                     # Reusable widgets
│   ├── utils/                       # Utilities
│   └── theme/                       # App theming
├── assets/
│   └── images/                      # Static images
└── web/
    ├── index.html                   # HTML entry point
    └── manifest.json                # PWA manifest
```

### 1.3 Web Screens (39 Total)

**Core Screens:**
- `landing_screen_web.dart` - Landing page
- `home_screen_web.dart` - Home dashboard with featured content
- `about_screen_web.dart` - About page

**Content Screens:**
- `podcasts_screen_web.dart` - Podcast listing
- `movies_screen_web.dart` - Movie listing
- `movie_detail_screen_web.dart` - Movie details
- `video_podcast_detail_screen_web.dart` - Video podcast details
- `music_screen_web.dart` - Music player
- `audio_player_full_screen_web.dart` - Full-screen audio player

**Community Screens:**
- `community_screen_web.dart` - Social feed (Instagram-like)
- `prayer_screen_web.dart` - Prayer requests
- `join_prayer_screen_web.dart` - Join prayer

**Creation Screens:**
- `create_screen_web.dart` - Content creation hub
- `video_recording_screen_web.dart` - Record video
- `video_preview_screen_web.dart` - Preview before publish
- `video_editor_screen_web.dart` - **Professional video editor (138KB)**

**Live/Meeting Screens:**
- `live_screen_web.dart` - Live streaming hub
- `stream_screen_web.dart` - Stream viewer
- `live_stream_options_screen_web.dart` - Stream setup
- `meetings_screen_web.dart` - Meeting list
- `meeting_options_screen_web.dart` - Meeting options
- `meeting_room_screen_web.dart` - LiveKit meeting room

**User Screens:**
- `profile_screen_web.dart` - User profile
- `library_screen_web.dart` - User library
- `favorites_screen_web.dart` - Favorites
- `downloads_screen_web.dart` - Downloads
- `notifications_screen_web.dart` - Notifications

**Voice Screens:**
- `voice_agent_screen_web.dart` - AI voice assistant
- `voice_chat_screen_web.dart` - Voice chat

**Admin Screens:**
- `admin_dashboard_web.dart` - Admin dashboard
- `admin_login_screen_web.dart` - Admin login

**Other Screens:**
- `search_screen_web.dart` - Search functionality
- `discover_screen_web.dart` - Content discovery
- `bible_stories_screen_web.dart` - Bible stories
- `support_screen_web.dart` - Support tickets
- `user_login_screen_web.dart` - User login
- `register_screen_web.dart` - Registration
- `not_found_screen_web.dart` - 404 page
- `offline_screen_web.dart` - Offline mode

### 1.4 State Management (13 Providers)

All providers use the `ChangeNotifier` pattern:

1. **AuthProvider** - Authentication state, user session
2. **AppState** - Global application state
3. **AudioPlayerProvider** - Audio playback state (play/pause, current track, queue)
4. **MusicProvider** - Music library management
5. **CommunityProvider** - Community posts, likes, comments
6. **SearchProvider** - Search functionality
7. **UserProvider** - User profile data
8. **PlaylistProvider** - User playlists
9. **FavoritesProvider** - User favorites
10. **SupportProvider** - Support tickets
11. **DocumentsProvider** - Documents/Bible
12. **NotificationProvider** - User notifications
13. **ArtistProvider** - Artist profiles
14. **EventProvider** - Events management

### 1.5 Services (10 Files)

#### **api_service.dart** (2864 lines)
Main API service handling all REST API calls:
- **Media URL Resolution:** Complex logic to handle S3/CloudFront URLs
  - Detects full URLs (http/https) and returns as-is
  - Strips `media/` prefix in production (CloudFront direct mapping)
  - Keeps `media/` prefix in development (backend serves from `/media`)
  - Handles relative paths (images/, audio/, video/, documents/)
- **Content APIs:** Podcasts, movies, music CRUD
- **Community APIs:** Posts, likes, comments
- **Upload APIs:** Audio, video, image uploads
- **User APIs:** Profile, settings

#### **auth_service.dart**
- JWT token management (storage in localStorage)
- Token expiration checking
- Login/logout/registration
- Google OAuth integration

#### **websocket_service.dart**
- Socket.io client connection
- Real-time notifications
- Auto-reconnection logic

#### **audio_editing_service.dart** & **video_editing_service.dart**
- Audio/video editing API calls
- Trim, merge, fade, overlays
- Media URL resolution for edited files

#### **livekit_meeting_service.dart** & **livekit_voice_service.dart**
- LiveKit integration for meetings
- Voice agent connection
- Token generation

### 1.6 Media URL Handling

**Critical Logic in `api_service.dart:getMediaUrl()`:**

```dart
String getMediaUrl(String? path) {
  // 1. Full URLs (http/https) → return as-is
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  // 2. CloudFront/S3 domains → add https:// if missing
  if (path.contains('cloudfront.net') || path.contains('.s3.')) {
    return path.startsWith('http') ? path : 'https://$path';
  }
  
  // 3. Handle 'media/' prefix
  if (cleanPath.startsWith('media/')) {
    if (isDevelopment) {
      // Dev: Keep media/ prefix (backend serves from /media)
      return '$mediaBaseUrl/$cleanPath';
    } else {
      // Prod: Strip media/ prefix (CloudFront maps directly to S3)
      cleanPath = cleanPath.substring(6);
      return '$mediaBaseUrl/$cleanPath';
    }
  }
  
  // 4. Direct S3 paths (images/, audio/, video/, documents/)
  if (cleanPath.startsWith('images/') || cleanPath.startsWith('audio/')...) {
    if (isDevelopment) {
      return '$mediaBaseUrl/media/$cleanPath';  // Add /media/ prefix
    } else {
      return '$mediaBaseUrl/$cleanPath';        // Direct CloudFront
    }
  }
}
```

**Development vs Production:**
- **Development:** `http://localhost:8002/media/audio/file.mp3`
- **Production:** `https://d126sja5o8ue54.cloudfront.net/audio/file.mp3`

---

## 2. Backend Architecture

### 2.1 Main Application (`main.py`)

**Key Features:**
- FastAPI application with Socket.io integration
- CORS middleware (production domains only)
- Static file serving (development only)
- Voice agent auto-start (can be disabled for Docker)
- Proxy headers middleware (for ALB/nginx)

**Startup Sequence:**
1. Initialize FastAPI app
2. Setup CORS middleware
3. Mount static files (dev only)
4. Include API routes (`/api/v1` prefix)
5. Initialize Socket.io
6. Start voice agent (if enabled)
7. Seed Bible document

### 2.2 Configuration (`config.py`)

**Environment Variables (via `.env`):**

```python
# Database
DATABASE_URL = postgresql+asyncpg://...

# Media Storage
S3_BUCKET_NAME = cnt-web-media
CLOUDFRONT_URL = https://d126sja5o8ue54.cloudfront.net
AWS_ACCESS_KEY_ID = ...
AWS_SECRET_ACCESS_KEY = ...
AWS_REGION = eu-west-2

# Security
SECRET_KEY = ...  # JWT signing
ACCESS_TOKEN_EXPIRE_MINUTES = 30

# LiveKit
LIVEKIT_WS_URL = wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL = https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY = ...
LIVEKIT_API_SECRET = ...

# AI Services
OPENAI_API_KEY = ...
DEEPGRAM_API_KEY = ...

# Google OAuth (optional)
GOOGLE_CLIENT_ID = ...
GOOGLE_CLIENT_SECRET = ...

# CORS
CORS_ORIGINS = https://main.d1poes9tyirmht.amplifyapp.com,https://d1poes9tyirmht.amplifyapp.com

# Environment
ENVIRONMENT = production
```

### 2.3 Database Connection (`database/connection.py`)

**Async SQLAlchemy Setup:**
- Lazy engine initialization
- PostgreSQL (production) or SQLite (development)
- Async session factory
- Connection pooling for PostgreSQL

**Database Models (21 tables):**
Located in `backend/app/models/`:
1. `user.py` - User accounts
2. `artist.py` - Creator profiles
3. `podcast.py` - Audio/video podcasts
4. `movie.py` - Full-length movies
5. `music.py` - Music tracks
6. `community.py` - Community posts, comments, likes
7. `playlist.py` - User playlists
8. `category.py` - Content categories
9. `live_stream.py` - Meeting/stream records
10. `document_asset.py` - PDF documents
11. `support_message.py` - Support tickets
12. `bible_story.py` - Bible stories
13. `notification.py` - User notifications
14. `bank_details.py` - Creator payment info
15. `payment_account.py` - Payment gateway accounts
16. `donation.py` - Donation transactions
17. `email_verification.py` - OTP verification
18. `event.py` - Events
19. `device_token.py` - Push notification tokens
20. `content_draft.py` - Draft content
21. And more...

### 2.4 API Routes (24 Route Files)

Located in `backend/app/routes/`:

1. **auth.py** - Authentication (login, register, Google OAuth, OTP)
2. **users.py** - User management
3. **podcasts.py** - Podcast CRUD
4. **movies.py** - Movie management
5. **music.py** - Music tracks
6. **community.py** - Community posts, likes, comments
7. **artists.py** - Artist profiles and follow system
8. **playlists.py** - Playlist management
9. **upload.py** - File upload endpoints
10. **audio_editing.py** - Audio editing operations
11. **video_editing.py** - Video editing operations
12. **live_stream.py** - Live streaming
13. **livekit_voice.py** - Voice agent integration
14. **voice_chat.py** - Voice chat
15. **documents.py** - Document management
16. **donations.py** - Payment processing
17. **bank_details.py** - Creator payment info
18. **support.py** - Support tickets
19. **categories.py** - Content categories
20. **bible_stories.py** - Bible stories
21. **notifications.py** - User notifications
22. **admin.py** - Admin dashboard and moderation
23. **admin_google_drive.py** - Google Drive integration
24. **events.py** - Event management
25. **device_tokens.py** - Push notification tokens
26. **content_drafts.py** - Draft content management

### 2.5 Services (17 Service Files)

Located in `backend/app/services/`:

1. **media_service.py** - S3/local file uploads
2. **auth_service.py** - Password hashing, JWT tokens
3. **thumbnail_service.py** - Thumbnail generation
4. **quote_image_service.py** - Quote image generation (PIL/Pillow)
5. **quote_templates.py** - Quote image templates
6. **video_editing_service.py** - FFmpeg video editing
7. **audio_editing_service.py** - FFmpeg audio editing
8. **livekit_service.py** - LiveKit token generation
9. **ai_service.py** - OpenAI integration
10. **username_service.py** - Unique username generation
11. **email_service.py** - AWS SES email sending
12. **payment_service.py** - Stripe/PayPal integration
13. **google_drive_service.py** - Google Drive uploads
14. **artist_service.py** - Artist profile management
15. **firebase_push_service.py** - Push notifications
16. **notification_service.py** - Notification management
17. **jitsi_service.py** - Legacy (not used)

### 2.6 Media Service (`services/media_service.py`)

**Key Features:**
- **Dual Storage:** S3 (production) or local (development)
- **File Types:** Audio, video, images, documents
- **S3 Upload:** Uses `boto3` to upload directly to S3
- **CloudFront URLs:** Returns CloudFront URLs in production
- **Local URLs:** Returns `/media/...` paths in development
- **Duration Detection:** Uses FFprobe for media duration

**S3 Folder Structure:**
```
cnt-web-media/
├── audio/                    # Audio podcasts
├── video/                    # Video podcasts
│   └── previews/            # Preview clips
├── images/
│   ├── quotes/              # Generated quote images
│   ├── thumbnails/
│   │   ├── podcasts/
│   │   │   ├── custom/     # User-uploaded
│   │   │   └── generated/  # Auto-generated
│   │   └── default/        # Default templates
│   ├── movies/             # Movie posters
│   └── profiles/           # User avatars
├── documents/              # PDF documents
└── animated-bible-stories/ # Bible story videos
```

---

## 3. Database Schema

### 3.1 Core Tables

#### **users**
```sql
- id (PK)
- username (unique, nullable, auto-generated)
- name, email (unique, required)
- avatar (S3/CloudFront URL)
- password_hash (nullable)
- is_admin (boolean)
- phone, date_of_birth, bio (nullable)
- google_id (unique, nullable)
- auth_provider ('email', 'google', 'both')
- created_at, updated_at
```

#### **artists**
```sql
- id (PK)
- user_id (FK → users, unique, required)
- artist_name (nullable, defaults to user.name)
- cover_image (S3/CloudFront URL)
- bio, social_links (JSON)
- followers_count, total_plays
- is_verified
- created_at, updated_at
```

#### **podcasts**
```sql
- id (PK)
- title (required)
- description, audio_url, video_url, cover_image
- creator_id (FK → users)
- category_id (FK → categories)
- duration (seconds)
- status ('pending', 'approved', 'rejected')
- plays_count
- created_at
```

#### **community_posts**
```sql
- id (PK)
- user_id (FK → users, required)
- title, content (required)
- image_url (photo or generated quote image)
- category ('testimony', 'prayer_request', 'question', 'announcement', 'general')
- post_type ('image', 'text')
- is_approved (0=False, 1=True)
- likes_count, comments_count
- created_at
```

### 3.2 Relationships

- **User → Podcasts:** One-to-many
- **User → Artist:** One-to-one (auto-created on first upload)
- **User → BankDetails:** One-to-one
- **User → SupportMessages:** One-to-many
- **Podcast → Category:** Many-to-one
- **CommunityPost → Comments:** One-to-many
- **CommunityPost → Likes:** Many-to-many (via `likes` table)

---

## 4. Authentication & Security

### 4.1 Authentication Methods

**1. Email/Password Login:**
- Endpoint: `POST /api/v1/auth/login`
- Accepts: `username_or_email` + `password`
- Returns: JWT token (30-minute expiration)
- Storage: `localStorage` (web)

**2. Google OAuth:**
- Endpoint: `POST /api/v1/auth/google-login`
- Supports: `id_token` or `access_token`
- Auto-creates user if first login
- Downloads and uploads Google avatar to S3
- Links to existing account if email matches

**3. User Registration:**
- Endpoint: `POST /api/v1/auth/register`
- Required: `email`, `password`, `name`
- Auto-generates unique username
- Returns: JWT token

**4. OTP Verification:**
- `POST /api/v1/auth/send-otp` - Send OTP
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/register-with-otp` - Register with verified email

### 4.2 JWT Token Management

- **Expiration:** 30 minutes (configurable)
- **Storage:** localStorage (web)
- **Validation:** Middleware checks on protected routes
- **Refresh:** Not implemented (user re-authenticates)

### 4.3 Security Features

- Password hashing with bcrypt
- JWT token validation middleware
- CORS restricted to production domains
- File type validation on uploads
- Unique filenames (UUID-based)
- S3 bucket policy restrictions
- Admin-only route protection

---

## 5. File Upload Workflow

### 5.1 Audio Upload Flow

1. User records or uploads audio file
2. Frontend validates file type
3. Upload to backend: `POST /api/v1/upload/audio`
4. Backend generates UUID filename: `{uuid}.{ext}`
5. **Production:** Uploads to S3: `audio/{uuid}.{ext}`
6. **Development:** Saves locally: `backend/media/audio/{uuid}.{ext}`
7. Backend gets duration using FFprobe
8. Returns CloudFront URL (production) or `/media/audio/...` (dev)
9. Frontend creates podcast record: `POST /api/v1/podcasts`
10. Status: "pending" (requires admin approval unless user is admin)

### 5.2 Video Upload Flow

1. User records or uploads video file
2. Frontend validates file type
3. Upload to backend: `POST /api/v1/upload/video`
4. Backend generates UUID filename
5. Uploads to S3: `video/{uuid}.{ext}`
6. Auto-generates thumbnail at 45 seconds (or 10% of duration)
7. Thumbnail saved to: `images/thumbnails/podcasts/generated/{uuid}.jpg`
8. Returns CloudFront URLs
9. Frontend creates podcast record

### 5.3 Image Upload (Community Posts)

1. User selects image or takes photo
2. Upload to backend: `POST /api/v1/upload/image`
3. Backend uploads to S3: `images/{uuid}.{ext}`
4. Returns CloudFront URL
5. Frontend creates community post: `POST /api/v1/community/posts`

### 5.4 Text Post (Quote Image Generation)

1. User enters text content
2. Create post: `POST /api/v1/community/posts` (post_type='text')
3. Backend detects `post_type='text'`
4. Calls `quote_image_service.generate_quote_image()`
5. Service:
   - Selects random template from `quote_templates.py`
   - Renders text with PIL/Pillow
   - Wraps text to fit image bounds
   - Calculates optimal font size
   - Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
   - Updates post with `image_url`
6. Returns CloudFront URL

---

## 6. Deployment Architecture

### 6.1 Web Frontend (AWS Amplify)

**Deployment:**
- **URL:** https://d1poes9tyirmht.amplifyapp.com
- **Build Spec:** `amplify.yml`
- **Branch:** `main` (auto-deploys on push)

**Build Process:**
```yaml
1. Clone Flutter SDK
2. cd web/frontend
3. flutter pub get
4. flutter build web --release --no-source-maps
   --dart-define=API_BASE_URL=$API_BASE_URL
   --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL
   --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL
   --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL
   --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL
   --dart-define=ENVIRONMENT=production
   --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
5. Deploy build/web/ directory
```

**Environment Variables (Amplify Console):**
- `API_BASE_URL`: https://api.christnewtabernacle.com/api/v1
- `MEDIA_BASE_URL`: https://d126sja5o8ue54.cloudfront.net
- `LIVEKIT_WS_URL`: wss://livekit.christnewtabernacle.com
- `LIVEKIT_HTTP_URL`: https://livekit.christnewtabernacle.com
- `WEBSOCKET_URL`: wss://api.christnewtabernacle.com
- `GOOGLE_CLIENT_ID`: ...

### 6.2 Backend (AWS EC2)

**Instance Details:**
- **IP:** 52.56.78.203
- **Region:** eu-west-2 (London)
- **SSH:** `ssh -i christnew.pem ubuntu@52.56.78.203`
- **Path:** `~/cnt-web-deployment/backend`
- **Domain:** api.christnewtabernacle.com

**Docker Containers:**
```bash
docker ps
# cnt-backend (port 8000)
# cnt-livekit-server (7880-7881, 50100-50200 UDP)
# cnt-voice-agent
```

**Backend Configuration (`.env`):**
- `DATABASE_URL`: PostgreSQL connection string
- `S3_BUCKET_NAME`: cnt-web-media
- `CLOUDFRONT_URL`: https://d126sja5o8ue54.cloudfront.net
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- `SECRET_KEY`: JWT signing key
- `LIVEKIT_*`: LiveKit configuration
- `OPENAI_API_KEY`, `DEEPGRAM_API_KEY`
- `ENVIRONMENT`: production

### 6.3 Database (AWS RDS)

- **Type:** PostgreSQL
- **Connection:** Via `DATABASE_URL` environment variable
- **Local Dev:** SQLite at `backend/local.db`

### 6.4 Media Storage (AWS S3 + CloudFront)

**S3 Bucket:**
- **Name:** `cnt-web-media`
- **Region:** `eu-west-2`
- **Access:** CloudFront OAC + EC2 IP whitelist

**CloudFront:**
- **URL:** https://d126sja5o8ue54.cloudfront.net
- **Distribution ID:** E3ER061DLFYFK8
- **OAC ID:** E1LSA9PF0Z69X7

**Access Control:**
- **Public Reads:** Via CloudFront OAC
- **Backend Writes:** Direct S3 access from EC2 (52.56.78.203)

---

## 7. Key Features

### 7.1 Content Consumption

- ✅ Audio/video podcasts with play counts
- ✅ Full-length movies with preview clips
- ✅ Music tracks with lyrics
- ✅ Bible reader (PDF viewer)
- ✅ Playlists
- ✅ Artist profiles with follow system
- ✅ Category filtering

### 7.2 Content Creation

- ✅ Audio podcast recording/upload
- ✅ Video podcast recording/upload
- ✅ Audio editing (trim, merge, fade in/out)
- ✅ Video editing (trim, audio management, text overlays, filters)
- ✅ Community posts (images)
- ✅ Quote posts (auto-generated images)

### 7.3 Social Features

- ✅ Community feed (Instagram-like)
- ✅ Like/unlike posts
- ✅ Comments on posts
- ✅ Artist follow system
- ✅ User profiles

### 7.4 Real-Time Features

- ✅ Live streaming (broadcaster/viewer)
- ✅ Video meetings (LiveKit)
- ✅ Voice agent (AI assistant)
- ✅ Real-time notifications (WebSocket)

### 7.5 Admin Features

- ✅ Content moderation (approve/reject)
- ✅ User management
- ✅ Support ticket handling
- ✅ Statistics dashboard
- ✅ Google Drive bulk upload

---

## 8. Environment Configuration

### 8.1 Frontend Configuration

**Build-time (`--dart-define`):**
- No `.env` file (web uses compile-time constants)
- Configuration via `app_config.dart` reading from `String.fromEnvironment()`
- Amplify sets environment variables that become `--dart-define` flags

### 8.2 Backend Configuration

**Runtime (`.env` file):**
- All configuration via environment variables
- `.env` file loaded via `pydantic-settings`
- Production: `.env` file on EC2
- Development: `.env` file locally

---

## 9. API Endpoints Summary

### Authentication
- `POST /api/v1/auth/login` - Email/password login
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/google-login` - Google OAuth
- `POST /api/v1/auth/send-otp` - Send OTP
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/check-username` - Check username availability

### Content
- `GET/POST /api/v1/podcasts` - List/create podcasts
- `GET/POST /api/v1/movies` - List/create movies
- `GET/POST /api/v1/music` - List/create music tracks

### Upload
- `POST /api/v1/upload/audio` - Upload audio file
- `POST /api/v1/upload/video` - Upload video file
- `POST /api/v1/upload/image` - Upload image
- `POST /api/v1/upload/profile-image` - Upload avatar
- `POST /api/v1/upload/thumbnail` - Upload thumbnail
- `POST /api/v1/upload/temporary-audio` - Temp audio for editing

### Editing
- `POST /api/v1/audio-editing/trim` - Trim audio
- `POST /api/v1/audio-editing/merge` - Merge audio
- `POST /api/v1/audio-editing/fade-in-out` - Fade effects
- `POST /api/v1/video-editing/trim` - Trim video
- `POST /api/v1/video-editing/add-audio` - Add audio track
- `POST /api/v1/video-editing/remove-audio` - Remove audio
- `POST /api/v1/video-editing/add-text-overlays` - Text overlays

### Community
- `GET/POST /api/v1/community/posts` - List/create posts
- `POST /api/v1/community/posts/{id}/like` - Like/unlike
- `POST /api/v1/community/posts/{id}/comments` - Add comment

### Admin
- `GET /api/v1/admin/dashboard` - Admin stats
- `POST /api/v1/admin/approve/{type}/{id}` - Approve content
- `POST /api/v1/admin/reject/{type}/{id}` - Reject content

---

## 10. Known Issues & Recommendations

### 10.1 Current Issues

1. ⚠️ No upload progress indicators for large files
2. ⚠️ No explicit file size limits in frontend
3. ⚠️ Temporary files may accumulate on failed uploads
4. ⚠️ No retry logic for failed uploads
5. ⚠️ No chunked uploads (may timeout on large files)

### 10.2 Recommendations

1. ✅ Add upload progress bars
2. ✅ Implement chunked uploads for large files
3. ✅ Add file size validation (frontend + backend)
4. ✅ Add retry logic for failed uploads
5. ✅ Cleanup temporary files on upload failure
6. ✅ Add upload queue for multiple files

---

## 11. Development Workflow

### 11.1 Local Development

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8002
```

**Web Frontend:**
```bash
cd web/frontend
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development
```

### 11.2 Deployment

**Web Frontend:**
- Push to GitHub
- Amplify auto-deploys from `main` branch
- Environment variables configured in Amplify console

**Backend:**
- SSH to EC2: `ssh -i christnew.pem ubuntu@52.56.78.203`
- Pull latest changes: `cd ~/cnt-web-deployment && git pull`
- Rebuild Docker containers
- Restart services

---

## 12. Summary

The CNT Media Platform web application is **production-ready** with:

✅ **Complete Backend API** - 24 route files, 17 services, 100+ endpoints  
✅ **Comprehensive Database** - 21 tables with full relationships  
✅ **Modern Web Frontend** - 39 screens, 13 providers, 10 services  
✅ **Cloud Infrastructure** - AWS EC2, RDS, S3, CloudFront, Amplify  
✅ **Media Management** - Upload, editing, streaming, storage  
✅ **Social Features** - Posts, likes, comments, follow system  
✅ **Real-Time Communication** - LiveKit meetings, streaming, voice agent  
✅ **Admin System** - Content moderation, user management  
✅ **Security** - JWT auth, Google OAuth, OTP verification  

**Ready for:** Feature enhancements, bug fixes, scaling

---

**Document Created:** Complete web application analysis  
**Status:** Production-ready  
**Last Updated:** December 12, 2025

