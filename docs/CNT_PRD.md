# Christ New Tabernacle (CNT) Platform - Product Requirements Document (PRD)

## Document Overview

This document serves as the comprehensive Product Requirement Document for the Christ New Tabernacle (CNT) platform, a Flutter-based Christian media platform designed to support content creation, consumption, and community engagement.

**Document Purpose:** This PRD is structured to be easily readable by LLMs (Large Language Models) for future analysis and updates. It serves as the backbone of the codebase for all future development and modifications.

**Last Updated:** December 2, 2025

---

## 1. Executive Summary

### 1.1 Platform Purpose

Christ New Tabernacle is a full-stack media platform enabling Christian content creation, community engagement, and real-time communication. It functions as a Spotify-like service for Christian media, combined with social features similar to Instagram/Facebook, and includes real-time meeting and live streaming capabilities.

### 1.2 Technology Stack

| Component | Technology |
|-----------|------------|
| **Web Frontend** | Flutter (Dart) - Web Application |
| **Mobile Frontend** | Flutter (Dart) - iOS & Android |
| **Backend** | FastAPI (Python) with SQLAlchemy ORM |
| **Database** | PostgreSQL (production via AWS RDS) |
| **Real-time Services** | LiveKit (meetings, live streaming, voice agent) |
| **Media Storage** | AWS S3 with CloudFront CDN |
| **AI Services** | OpenAI GPT-4o-mini, Deepgram (STT/TTS) |
| **Web Deployment** | AWS Amplify |
| **Backend Deployment** | AWS EC2 (eu-west-2) |

### 1.3 Key Files

| Purpose | File Path |
|---------|-----------|
| Backend Entry | `backend/app/main.py` |
| Backend Config | `backend/app/config.py` |
| Web Frontend Entry | `web/frontend/lib/main.dart` |
| Web Frontend Config | `web/frontend/lib/config/app_config.dart` |
| Mobile Frontend Entry | `mobile/frontend/lib/main.dart` |
| Mobile Frontend Config | `mobile/frontend/lib/config/environment.dart` |
| Mobile Environment | `mobile/frontend/.env` (from `env.example`) |
| Amplify Build Config | `amplify.yml` |
| S3 Bucket Policy | `s3-bucket-policy.json` |
| Deployment SSH Key | `christnew.pem` (root folder) |

### 1.4 Important Note

This is a local codebase with a production version running with live production keys. Any modifications to the local code must be mirrored in the production codebase. The application uses `.env` files for configuration - **NO hardcoded URLs are allowed**.

---

## 2. System Architecture

### 2.1 Backend Structure

```
backend/app/
├── main.py           # FastAPI application entry point
├── config.py         # Environment configuration (Pydantic Settings)
├── database/         # Database connection and session management
│   ├── __init__.py
│   └── connection.py
├── models/           # SQLAlchemy ORM models
│   ├── user.py
│   ├── podcast.py
│   ├── movie.py
│   ├── music.py
│   ├── community.py
│   ├── artist.py
│   ├── bank_details.py
│   ├── payment_account.py
│   ├── donation.py
│   ├── live_stream.py
│   ├── document_asset.py
│   ├── support_message.py
│   ├── category.py
│   ├── bible_story.py
│   └── playlist.py
├── routes/           # API endpoint handlers
│   ├── auth.py
│   ├── admin.py
│   ├── artists.py
│   ├── podcasts.py
│   ├── movies.py
│   ├── music.py
│   ├── community.py
│   ├── live_stream.py
│   ├── livekit_voice.py
│   ├── voice_chat.py
│   ├── upload.py
│   ├── video_editing.py
│   ├── audio_editing.py
│   ├── documents.py
│   ├── donations.py
│   ├── bank_details.py
│   ├── support.py
│   ├── users.py
│   ├── categories.py
│   ├── bible_stories.py
│   ├── playlists.py
│   └── admin_google_drive.py
├── schemas/          # Pydantic request/response schemas
├── services/         # Business logic services
│   ├── auth_service.py
│   ├── artist_service.py
│   ├── media_service.py
│   ├── video_editing_service.py
│   ├── audio_editing_service.py
│   ├── thumbnail_service.py
│   ├── quote_image_service.py
│   ├── livekit_service.py
│   ├── payment_service.py
│   ├── google_drive_service.py
│   ├── ai_service.py
│   └── username_service.py
├── middleware/       # Authentication middleware
│   └── auth_middleware.py
├── agents/           # LiveKit voice agent
│   └── voice_agent.py
└── websocket/        # Socket.IO handlers
    └── socket_io_handler.py
```

### 2.2 Web Frontend Structure

```
web/frontend/lib/
├── main.dart              # Application entry point
├── config/
│   └── app_config.dart    # Environment via --dart-define
├── models/                # Data models
├── screens/
│   ├── admin/             # Admin dashboard pages (7 pages)
│   ├── artist/            # Artist profile screens
│   ├── audio/             # Audio player screens
│   ├── bible/             # Bible reader screens
│   ├── community/         # Community post screens
│   ├── creation/          # Content creation screens
│   ├── editing/           # Audio/video editing screens
│   ├── live/              # Live streaming screens
│   ├── meeting/           # Meeting screens
│   ├── support/           # Support ticket screens
│   ├── video/             # Video player screens
│   ├── voice/             # Voice mode screens
│   └── web/               # Web-specific screens (35+ pages)
├── services/              # API and business services
├── providers/             # State management (Provider pattern)
├── widgets/               # Reusable UI components
├── theme/                 # Styling constants
└── utils/                 # Utility functions
```

### 2.3 Mobile Frontend Structure

```
mobile/frontend/lib/
├── main.dart              # Application entry point
├── config/
│   └── environment.dart   # Environment via .env file
├── models/                # Data models
├── screens/
│   ├── admin/             # Admin dashboard pages (7 pages)
│   ├── artist/            # Artist profile screens
│   ├── audio/             # Audio player screens
│   ├── bible/             # Bible reader screens
│   ├── community/         # Community post screens
│   ├── creation/          # Content creation screens
│   ├── editing/           # Audio/video editing screens
│   ├── live/              # Live streaming screens
│   ├── meeting/           # Meeting screens (5 screens)
│   ├── support/           # Support ticket screens
│   ├── video/             # Video player screens
│   ├── voice/             # Voice mode screens
│   └── mobile/            # Mobile-specific screens (14 screens)
├── services/              # API and business services (10 services)
├── providers/             # State management (13 providers)
├── widgets/               # Reusable UI components
├── theme/                 # Styling constants
└── utils/                 # Utility functions
```

---

## 3. Environment Configuration

### 3.1 Backend Configuration

**File:** `backend/app/config.py`

Uses Pydantic Settings with `.env` file support.

```python
# Required Environment Variables
DATABASE_URL          # postgresql+asyncpg://user:pass@host:5432/db
SECRET_KEY            # JWT signing key (random string)
S3_BUCKET_NAME        # AWS S3 bucket name (cnt-web-media)
CLOUDFRONT_URL        # https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL        # wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL      # https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY       # LiveKit API key
LIVEKIT_API_SECRET    # LiveKit API secret
OPENAI_API_KEY        # OpenAI API key
DEEPGRAM_API_KEY      # Deepgram API key

# Optional Environment Variables
GOOGLE_CLIENT_ID      # Google OAuth client ID
GOOGLE_CLIENT_SECRET  # Google OAuth secret
STRIPE_SECRET_KEY     # Stripe secret key
STRIPE_PUBLISHABLE_KEY # Stripe publishable key
PAYPAL_CLIENT_ID      # PayPal client ID
PAYPAL_CLIENT_SECRET  # PayPal client secret
REDIS_URL             # Redis/ElastiCache URL
CORS_ORIGINS          # Comma-separated allowed origins
ENVIRONMENT           # 'production' or 'development'
```

### 3.2 Web Frontend Configuration

**File:** `web/frontend/lib/config/app_config.dart`

All configuration via `--dart-define` flags at build time. **NO hardcoded URLs.**

```dart
class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String mediaBaseUrl = String.fromEnvironment('MEDIA_BASE_URL');
  static const String livekitWsUrl = String.fromEnvironment('LIVEKIT_WS_URL');
  static const String livekitHttpUrl = String.fromEnvironment('LIVEKIT_HTTP_URL');
  static const String websocketUrl = String.fromEnvironment('WEBSOCKET_URL');
  static const String environment = String.fromEnvironment('ENVIRONMENT');
}
```

**Amplify Build Command (from `amplify.yml`):**
```bash
flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
  --dart-define=ENVIRONMENT=production
```

### 3.3 Mobile Frontend Configuration

**File:** `mobile/frontend/lib/config/environment.dart`

All configuration via `.env` file. **NO hardcoded URLs.**

```dart
class Environment {
  // URL Resolution Priority:
  // 1. --dart-define (for CI/CD builds)
  // 2. .env file values
  // 3. Development defaults (localhost/10.0.2.2)
  
  static String get apiBaseUrl { /* ... */ }
  static String get webSocketUrl { /* ... */ }
  static String get mediaBaseUrl { /* ... */ }
  static String get liveKitWsUrl { /* ... */ }
  static String get liveKitHttpUrl { /* ... */ }
}
```

**Mobile `.env` File (from `env.example`):**
```bash
# Production Configuration
ENVIRONMENT=production
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
WEBSOCKET_URL=wss://api.christnewtabernacle.com
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com

# Development (auto-detected when ENVIRONMENT=development)
# Uses localhost:8002 or 10.0.2.2:8002 (Android emulator)
```

**Mobile Build Command:**
```bash
# Production build
flutter build apk --release --dart-define=ENVIRONMENT=production

# Development build (uses .env file defaults)
flutter run -d <device_id>
```

---

## 4. AWS Infrastructure

### 4.1 S3 Media Storage

| Setting | Value |
|---------|-------|
| Bucket Name | `cnt-web-media` |
| Region | `eu-west-2` (London) |
| Access | Via CloudFront OAC + Server IP |

**S3 Bucket Policy (`s3-bucket-policy.json`):**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowCloudFrontOACAccess",
      "Effect": "Allow",
      "Principal": {"Service": "cloudfront.amazonaws.com"},
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::cnt-web-media/*",
      "Condition": {
        "StringEquals": {
          "AWS:SourceArn": "arn:aws:cloudfront::649159624630:distribution/E3ER061DLFYFK8"
        }
      }
    },
    {
      "Sid": "AllowServerIPAccess",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::cnt-web-media/*",
      "Condition": {
        "IpAddress": {"aws:SourceIp": "52.56.78.203/32"}
      }
    }
  ]
}
```

### 4.2 CloudFront CDN

| Setting | Value |
|---------|-------|
| Distribution ID | `E3ER061DLFYFK8` |
| Domain | `d126sja5o8ue54.cloudfront.net` |
| Origin | `cnt-web-media.s3.eu-west-2.amazonaws.com` |
| Origin Path | `` (empty - direct S3 mapping) |
| OAC ID | `E1LSA9PF0Z69X7` |

**URL Structure:**
- CloudFront: `https://d126sja5o8ue54.cloudfront.net/images/quotes/quote_1.jpg`
- Maps to S3: `s3://cnt-web-media/images/quotes/quote_1.jpg`

### 4.3 EC2 Backend Server

| Setting | Value |
|---------|-------|
| Public IP | `52.56.78.203` |
| Domain | `christnewtabernacle.com` |
| Region | `eu-west-2` (London) |
| Instance | Private VPC (`172.31.33.228`) |

### 4.4 RDS Database

| Setting | Value |
|---------|-------|
| Engine | PostgreSQL |
| Endpoint | `cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com` |
| Database | `cntdb` |
| Connection | `postgresql+asyncpg://` |

### 4.5 Amplify Web Hosting

| Setting | Value |
|---------|-------|
| App Domain | `d1poes9tyirmht.amplifyapp.com` |
| Branch | `main` |
| Build Spec | `amplify.yml` |
| Framework | Flutter Web |

---

## 5. Feature Specifications

### 5.1 Authentication System

**Implementation Files:**
- Backend: `backend/app/routes/auth.py`, `backend/app/services/auth_service.py`
- Mobile: `mobile/frontend/lib/services/auth_service.dart`
- Web: `web/frontend/lib/services/auth_service.dart`

#### Features

| Feature | Description |
|---------|-------------|
| Email/Password Login | JWT-based authentication with username or email |
| User Registration | With automatic unique username generation |
| Google OAuth | Social login integration |
| Token Management | 30-minute access token expiration (configurable) |
| Admin Roles | Separate admin authentication flow |

#### API Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/api/v1/auth/login` | POST | No | Email/password login |
| `/api/v1/auth/register` | POST | No | New user registration |
| `/api/v1/auth/google-login` | POST | No | Google OAuth login |
| `/api/v1/auth/check-username` | POST | No | Username availability check |
| `/api/v1/auth/google-client-id` | GET | No | Get Google OAuth client ID |

---

### 5.2 Content Consumption

#### 5.2.1 Podcasts (Audio/Video)

**Files:** `backend/app/routes/podcasts.py`, `**/screens/podcasts_screen.dart`

| Feature | Description |
|---------|-------------|
| List Podcasts | Approved only for non-admin, all for admin |
| Create Podcast | Requires authentication and bank details |
| Auto-thumbnail | Generated from video if not provided |
| Play Count | Tracks number of plays |

#### 5.2.2 Movies

**Files:** `backend/app/routes/movies.py`, `**/screens/movie_detail_screen.dart`

| Feature | Description |
|---------|-------------|
| Featured Movies | For hero carousel display |
| Similar Movies | Recommendations based on category |
| Preview Clips | With configurable timestamps |

#### 5.2.3 Music Tracks

**Files:** `backend/app/routes/music.py`, `**/screens/music_screen.dart`

| Feature | Description |
|---------|-------------|
| List Tracks | With genre and artist filtering |
| Track Playback | Individual track streaming |

#### 5.2.4 Bible Reader

**Files:** `backend/app/routes/documents.py`, `**/screens/bible/`

| Feature | Description |
|---------|-------------|
| PDF Management | Upload, list, view PDF documents |
| Auto-seeding | Holy Bible (KJV) seeded at startup |
| Admin Upload | Only admins can upload new documents |

---

### 5.3 Community Features (Social)

**Files:** `backend/app/routes/community.py`, `backend/app/services/quote_image_service.py`

#### Features

| Feature | Description |
|---------|-------------|
| Image Posts | Upload photos with captions |
| Text Posts | Written posts converted to quote images |
| Like System | Toggle like/unlike with count tracking |
| Comments | Nested comment threads on posts |
| Approval Workflow | Admin approval required for non-admin posts |

#### Quote Image Generation

The `quote_image_service.py` generates styled images from text content:
- Uploads to S3: `images/quotes/quote_{id}_{hash}.jpg`
- Returns CloudFront URL: `https://cloudfront.net/images/quotes/quote_{id}.jpg`
- **No `/media/` prefix** (direct S3 path mapping)

---

### 5.4 Artist Feature

**Files:** `backend/app/routes/artists.py`, `**/screens/artist/`

#### Features

| Feature | Description |
|---------|-------------|
| Artist Profile | Auto-created when user uploads content |
| Follow System | Users can follow/unfollow artists |
| Cover Image | Custom artist branding image |
| Social Links | JSON field for multiple social platform links |

#### Mobile Artist Screens

| Screen | File |
|--------|------|
| Artist Profile | `mobile/frontend/lib/screens/artist/artist_profile_screen.dart` |
| Manage Profile | `mobile/frontend/lib/screens/artist/artist_profile_manage_screen.dart` |

---

### 5.5 Content Creation (Podcast Studio)

#### Video Podcast Creation

**Files:** `**/screens/creation/video_*`, `backend/app/routes/video_editing.py`

| Feature | API Endpoint | Description |
|---------|--------------|-------------|
| Trim | `/api/v1/video-editing/trim` | Cut start/end |
| Remove Audio | `/api/v1/video-editing/remove-audio` | Strip audio track |
| Add Audio | `/api/v1/video-editing/add-audio` | Add new audio track |
| Text Overlays | `/api/v1/video-editing/add-text-overlays` | Positioned text |

#### Audio Podcast Creation

**Files:** `**/screens/creation/audio_*`, `backend/app/routes/audio_editing.py`

| Feature | API Endpoint | Description |
|---------|--------------|-------------|
| Trim | `/api/v1/audio-editing/trim` | Cut audio segments |
| Merge | `/api/v1/audio-editing/merge` | Combine multiple files |
| Fade In/Out | `/api/v1/audio-editing/fade-in-out` | Fade effects |

---

### 5.6 Real-Time Communication

#### Meetings System

**Files:** `backend/app/routes/live_stream.py`, `**/screens/meeting/`

| Feature | Description |
|---------|-------------|
| Instant Meetings | Create and join immediately |
| Scheduled Meetings | Set future start time |
| Room Management | Create/delete/list LiveKit rooms |
| Token Generation | JWT tokens for room access |

#### Live Streaming

**Files:** `**/screens/live/`

| Screen | Description |
|--------|-------------|
| `live_stream_broadcaster.dart` | Host broadcasting interface |
| `live_stream_viewer.dart` | Viewer interface |
| `stream_creation_screen.dart` | Stream setup |

---

### 5.7 Voice Mode (AI Assistant)

**Files:** `backend/app/agents/voice_agent.py`, `**/screens/voice/`

#### Architecture

| Component | Technology | Purpose |
|-----------|------------|---------|
| Framework | LiveKit Agents SDK | Voice pipeline management |
| LLM | OpenAI GPT-4o-mini | Conversation AI |
| STT | Deepgram Nova-3 | Speech-to-text |
| TTS | Deepgram Aura-2-Andromeda | Text-to-speech |

#### Room Naming

Voice agent only joins rooms with `voice-agent-` prefix.

---

### 5.8 Admin Dashboard

**Files:** `backend/app/routes/admin.py`, `**/screens/admin/`

#### Admin Pages

| Page | File | Purpose |
|------|------|---------|
| Dashboard | `admin_dashboard_page.dart` | Overview statistics |
| Audio | `admin_audio_page.dart` | Audio podcast management |
| Video | `admin_video_page.dart` | Video podcast management |
| Posts | `admin_posts_page.dart` | Community post moderation |
| Users | `admin_users_page.dart` | User management |
| Support | `admin_support_page.dart` | Support ticket handling |
| Documents | `admin_documents_page.dart` | Bible/document management |

---

## 6. Mobile-Specific Implementation

### 6.1 Mobile Screens

Located in `mobile/frontend/lib/screens/mobile/`:

| Screen | Description |
|--------|-------------|
| `home_screen_mobile.dart` | Layered UI with carousel and parallax effects |
| `discover_screen_mobile.dart` | Content discovery |
| `podcasts_screen_mobile.dart` | Podcast listing |
| `music_screen_mobile.dart` | Music player |
| `community_screen_mobile.dart` | Social feed |
| `create_screen_mobile.dart` | Content creation hub |
| `library_screen_mobile.dart` | User library |
| `profile_screen_mobile.dart` | User profile |
| `search_screen_mobile.dart` | Search functionality |
| `live_screen_mobile.dart` | Live streaming |
| `meeting_options_screen_mobile.dart` | Meeting options |
| `bible_stories_screen_mobile.dart` | Bible stories |
| `quote_create_screen_mobile.dart` | Quote post creation |
| `voice_chat_modal.dart` | Voice agent modal |

### 6.2 Mobile Providers

Located in `mobile/frontend/lib/providers/`:

| Provider | Purpose |
|----------|---------|
| `app_state.dart` | Global app state |
| `auth_provider.dart` | Authentication state |
| `artist_provider.dart` | Artist profile management |
| `audio_player_provider.dart` | Audio playback state |
| `community_provider.dart` | Community posts |
| `documents_provider.dart` | Documents/Bible |
| `favorites_provider.dart` | User favorites |
| `music_provider.dart` | Music playback |
| `notification_provider.dart` | Push notifications |
| `playlist_provider.dart` | Playlists |
| `search_provider.dart` | Search functionality |
| `support_provider.dart` | Support tickets |
| `user_provider.dart` | User data |

### 6.3 Mobile Services

Located in `mobile/frontend/lib/services/`:

| Service | Purpose |
|---------|---------|
| `api_service.dart` | REST API calls, media URL handling |
| `auth_service.dart` | Authentication |
| `websocket_service.dart` | Real-time notifications |
| `donation_service.dart` | Payment processing |
| `download_service.dart` | Offline downloads |
| `google_auth_service.dart` | Google OAuth |
| `livekit_meeting_service.dart` | LiveKit meetings |
| `livekit_voice_service.dart` | Voice agent |
| `video_editing_service.dart` | Video editing |
| `audio_editing_service.dart` | Audio editing |

### 6.4 Mobile Media URL Handling

**File:** `mobile/frontend/lib/services/api_service.dart`

```dart
String getMediaUrl(String? path) {
  // 1. Return full URLs directly
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  // 2. Strip legacy 'media/' prefix
  if (cleanPath.startsWith('media/')) {
    cleanPath = cleanPath.substring(6);
  }
  
  // 3. CloudFront URL maps directly to S3 paths
  return '$mediaBaseUrl/$cleanPath';
}
```

---

## 7. Web-Specific Implementation

### 7.1 Web Screens

Located in `web/frontend/lib/screens/web/`:

| Category | Screens |
|----------|---------|
| **Core** | `home_screen_web.dart`, `landing_screen_web.dart`, `about_screen_web.dart` |
| **Content** | `podcasts_screen_web.dart`, `movies_screen_web.dart`, `music_screen_web.dart` |
| **Community** | `community_screen_web.dart`, `prayer_screen_web.dart` |
| **Creation** | `create_screen_web.dart`, `video_editor_screen_web.dart`, `video_recording_screen_web.dart` |
| **Live** | `live_screen_web.dart`, `stream_screen_web.dart`, `meetings_screen_web.dart` |
| **User** | `profile_screen_web.dart`, `library_screen_web.dart`, `favorites_screen_web.dart` |
| **Voice** | `voice_agent_screen_web.dart`, `voice_chat_screen_web.dart` |
| **Admin** | `admin_dashboard_web.dart`, `admin_login_screen_web.dart` |
| **Other** | `search_screen_web.dart`, `support_screen_web.dart`, `not_found_screen_web.dart` |

### 7.2 Web Media URL Handling

**File:** `web/frontend/lib/services/api_service.dart`

```dart
String getMediaUrl(String? path) {
  // Development vs Production handling
  final isDevelopment = mediaBaseUrl.contains('localhost');
  
  if (cleanPath.startsWith('media/')) {
    if (isDevelopment) {
      // Keep media/ prefix for local backend
      return '$mediaBaseUrl/$cleanPath';
    } else {
      // Strip media/ prefix for CloudFront
      cleanPath = cleanPath.substring(6);
      return '$mediaBaseUrl/$cleanPath';
    }
  }
  
  // Direct paths (images/, audio/, video/, etc.)
  if (isDevelopment) {
    return '$mediaBaseUrl/media/$cleanPath';  // Add prefix for local
  } else {
    return '$mediaBaseUrl/$cleanPath';  // Direct for CloudFront
  }
}
```

---

## 8. Third-Party Service Integration

### 8.1 LiveKit

| Aspect | Details |
|--------|---------|
| **Purpose** | Real-time video/audio communication |
| **Components** | Meetings, Live Streaming, Voice Agent |
| **SDK** | Python LiveKit SDK, Flutter LiveKit SDK |

**Configuration:**
```
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY=<api_key>
LIVEKIT_API_SECRET=<api_secret>
```

### 8.2 OpenAI & Deepgram

| Service | Purpose | Model |
|---------|---------|-------|
| OpenAI | Voice AI conversation | GPT-4o-mini |
| Deepgram STT | Speech-to-text | Nova-3 (en-US) |
| Deepgram TTS | Text-to-speech | Aura-2-Andromeda-en |

### 8.3 Payment Gateways

| Gateway | Purpose |
|---------|---------|
| Stripe | Primary payment processor |
| PayPal | Alternative payment method |

### 8.4 FFmpeg

| Aspect | Details |
|--------|---------|
| **Purpose** | Media processing |
| **Library** | ffmpeg-python |
| **Features** | Trim, merge, filter, transcode |

---

## 9. Deployment Configuration

### 9.1 Web Frontend (AWS Amplify)

**Build Process (`amplify.yml`):**
1. Clone Flutter SDK (stable branch)
2. Run `flutter pub get`
3. Build with `--dart-define` flags for all URLs
4. Deploy `frontend/build/web` directory

**Environment Variables (Amplify Console):**
- `API_BASE_URL`
- `MEDIA_BASE_URL`
- `LIVEKIT_WS_URL`
- `LIVEKIT_HTTP_URL`
- `WEBSOCKET_URL`

### 9.2 Mobile App

**Production Build:**
```bash
# Ensure .env file has production URLs
cd mobile/frontend
flutter build apk --release --dart-define=ENVIRONMENT=production
```

**Development Build:**
```bash
# .env with ENVIRONMENT=development (uses localhost defaults)
flutter run -d <device_id>
```

### 9.3 Backend (AWS EC2)

**Deployment:**
```bash
ssh -i christnew.pem ubuntu@52.56.78.203
cd ~/cnt-web-deployment
git pull
sudo systemctl restart cnt-backend
```

---

## 10. Database Models Summary

| Model | Table | Primary Purpose |
|-------|-------|-----------------|
| User | users | User accounts and authentication |
| Podcast | podcasts | Audio/video podcast content |
| Movie | movies | Full-length movie content |
| MusicTrack | music_tracks | Music content |
| CommunityPost | community_posts | Social media posts |
| Like | likes | Post likes |
| Comment | comments | Post comments |
| Artist | artists | Creator profiles |
| ArtistFollower | artist_followers | Follow relationships |
| BankDetails | bank_details | Creator payment info |
| PaymentAccount | payment_accounts | Payment gateway accounts |
| Donation | donations | Donation transactions |
| LiveStream | live_streams | Meeting/stream records |
| DocumentAsset | document_assets | Bible/PDF documents |
| SupportMessage | support_messages | Support tickets |
| Category | categories | Content categories |
| Playlist | playlists | User playlists |

---

## 11. API Route Summary

### Authentication (`/api/v1/auth`)
- POST `/login`, `/register`, `/google-login`, `/check-username`
- GET `/google-client-id`

### Users (`/api/v1/users`)
- GET `/me`, `/{id}/public`
- PUT `/me`

### Content (`/api/v1/podcasts`, `/movies`, `/music`)
- GET, POST, DELETE operations

### Community (`/api/v1/community`)
- GET, POST `/posts`
- POST `/posts/{id}/like`, `/posts/{id}/comments`

### Artists (`/api/v1/artists`)
- GET, PUT `/me`
- POST `/me/cover-image`
- GET `/{id}`, `/{id}/podcasts`
- POST, DELETE `/{id}/follow`

### Live (`/api/v1/live`)
- GET, POST `/streams`
- POST `/streams/{id}/join`, `/streams/{id}/livekit-token`

### Voice (`/api/v1/livekit`)
- POST `/voice/token`, `/voice/room`
- DELETE `/voice/room/{name}`
- GET `/voice/rooms`, `/voice/health`

### Admin (`/api/v1/admin`)
- GET `/dashboard`, `/pending`, `/content`
- POST `/approve/{type}/{id}`, `/reject/{type}/{id}`

### Upload (`/api/v1/upload`)
- POST `/audio`, `/video`, `/image`, `/thumbnail`, `/document`
- GET `/thumbnail/defaults`, `/media/duration`

### Editing
- POST `/video-editing/trim`, `/remove-audio`, `/add-audio`, `/add-text-overlays`
- POST `/audio-editing/trim`, `/merge`, `/fade-in`, `/fade-out`

---

## 12. Known Implementation Notes

### 12.1 Migration History

| Change | Details |
|--------|---------|
| Jitsi Removed | Platform migrated from Jitsi to LiveKit |
| CloudFront OriginPath | Removed `/media` prefix - direct S3 mapping |

### 12.2 URL Handling Rules

| Environment | Media URL Pattern |
|-------------|-------------------|
| Development | `http://localhost:8002/media/images/...` |
| Production | `https://cloudfront.net/images/...` (no `/media/`) |

### 12.3 Development vs Production

| Aspect | Development | Production |
|--------|-------------|------------|
| Database | SQLite (optional) | PostgreSQL (RDS) |
| Media | Local filesystem | S3 + CloudFront |
| CORS | Allow all origins | Whitelist only |
| Media URLs | `/media/` prefix | Direct S3 paths |

---

## 13. Document Maintenance

### 13.1 Update Triggers

This PRD should be updated when:
- New features are added
- AWS infrastructure changes
- Environment configuration changes
- API endpoints are added/removed
- Third-party services are changed

### 13.2 Version History

| Date | Version | Changes |
|------|---------|---------|
| Initial | 1.0 | Complete codebase analysis |
| Dec 2, 2025 | 2.0 | Updated AWS config, mobile/web structure, CloudFront fix |

### 13.3 Document Info

**Last Updated:** December 2, 2025  
**Codebase Version:** Current production deployment  
**Document Format:** Structured for LLM readability
