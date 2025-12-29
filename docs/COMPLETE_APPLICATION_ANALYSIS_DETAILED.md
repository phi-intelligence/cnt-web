# CNT Media Platform - Complete Application Analysis

**Date:** December 2024  
**Status:** Comprehensive Analysis of Web and Mobile Applications  
**Focus:** Web Application (Primary) + Mobile Application (Secondary)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Technology Stack](#technology-stack)
3. [Application Architecture](#application-architecture)
4. [Database Schema - Complete Details](#database-schema)
5. [Backend Structure - Complete Analysis](#backend-structure)
6. [Web Frontend Structure - Complete Analysis](#web-frontend-structure)
7. [Mobile Frontend Structure - Complete Analysis](#mobile-frontend-structure)
8. [S3 & CloudFront Integration](#s3-cloudfront-integration)
9. [Authentication & Authorization](#authentication-authorization)
10. [API Endpoints - Complete Reference](#api-endpoints)
11. [File Upload Flows](#file-upload-flows)
12. [Content Creation Workflows](#content-creation-workflows)
13. [Real-Time Features](#real-time-features)
14. [Admin Dashboard](#admin-dashboard)
15. [Deployment Architecture](#deployment-architecture)
16. [Environment Configuration](#environment-configuration)
17. [Key Services & Providers](#key-services-providers)
18. [Screen Inventory](#screen-inventory)

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application providing:

- **Content Consumption**: Podcasts (audio/video), movies, music, Bible reader
- **Content Creation**: Professional audio/video editing tools, upload workflows
- **Social Features**: Community posts (Instagram-like), likes, comments, follows
- **Real-Time Communication**: Video meetings (LiveKit), live streaming, AI voice assistant
- **Admin System**: Complete moderation dashboard with 7+ admin pages

### Production Status

- ✅ **Web Application**: Production-ready, deployed on AWS Amplify
- ✅ **Backend API**: Production-ready, running on AWS EC2 (eu-west-2)
- ✅ **Database**: PostgreSQL on AWS RDS
- ✅ **Media Storage**: S3 + CloudFront CDN
- 🚧 **Mobile Application**: Code complete, pending store submission

---

## Technology Stack

### Backend
- **Framework**: FastAPI (Python 3.11+)
- **ORM**: SQLAlchemy (async)
- **Database**: PostgreSQL (production) / SQLite (local dev)
- **File Storage**: AWS S3 + CloudFront CDN
- **Real-Time**: LiveKit (meetings, streaming, voice agent)
- **AI Services**: OpenAI GPT-4o-mini, Deepgram Nova-3 (STT), Deepgram Aura-2 (TTS)
- **Media Processing**: FFmpeg (audio/video editing)
- **Image Processing**: PIL/Pillow (quote image generation)

### Web Frontend
- **Framework**: Flutter Web
- **State Management**: Provider pattern
- **Routing**: GoRouter
- **Storage**: localStorage / sessionStorage (web)
- **Deployment**: AWS Amplify

### Mobile Frontend
- **Framework**: Flutter (iOS & Android)
- **State Management**: Provider pattern
- **Storage**: flutter_secure_storage
- **Status**: Development complete, pending store submission

### Infrastructure
- **Backend Hosting**: AWS EC2 (eu-west-2, IP: 52.56.78.203)
- **Web Hosting**: AWS Amplify
- **Database**: AWS RDS PostgreSQL
- **Media Storage**: AWS S3 (`cnt-web-media`) + CloudFront CDN
- **Domain**: christnewtabernacle.com

---

## Application Architecture

### High-Level Architecture

```
┌─────────────────┐
│  Web Frontend   │  (Flutter Web on AWS Amplify)
│  (Flutter/Dart)  │
└────────┬────────┘
         │ HTTPS
         │
┌────────▼────────┐
│  Backend API    │  (FastAPI on AWS EC2)
│  (Python)       │
└────────┬────────┘
         │
    ┌────┴────┬──────────────┬──────────────┐
    │         │              │              │
┌───▼───┐ ┌──▼───┐    ┌─────▼─────┐  ┌────▼────┐
│  RDS  │ │  S3  │    │ CloudFront│  │ LiveKit │
│Postgres│ │Bucket│    │    CDN    │  │ Server  │
└───────┘ └──────┘    └───────────┘  └─────────┘
```

### Request Flow

1. **User Request** → Web Frontend (Amplify)
2. **API Call** → Backend API (EC2) via HTTPS
3. **Database Query** → PostgreSQL (RDS)
4. **File Upload** → S3 Bucket (via backend)
5. **Media Delivery** → CloudFront CDN
6. **Real-Time** → LiveKit Server

---

## Database Schema - Complete Details

### Core Tables (21 Total)

#### 1. **users** - User Accounts
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    username VARCHAR UNIQUE,          -- Auto-generated unique username
    name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    avatar VARCHAR,                   -- Profile image URL (S3/CloudFront)
    password_hash VARCHAR,            -- For email/password auth
    is_admin BOOLEAN DEFAULT FALSE,
    phone VARCHAR,
    date_of_birth TIMESTAMP,
    bio TEXT,
    google_id VARCHAR UNIQUE,        -- Google OAuth ID
    auth_provider VARCHAR DEFAULT 'email',  -- 'email', 'google', 'both'
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

**Relationships:**
- One-to-many: `podcasts`, `support_messages`, `notifications`, `community_posts`, `hosted_events`
- One-to-one: `artist`, `bank_details`, `payment_account`
- Many-to-many: `event_attendances` (via EventAttendee)

#### 2. **artists** - Creator Profiles
```sql
CREATE TABLE artists (
    id INTEGER PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id),
    artist_name VARCHAR,              -- Defaults to user.name if not set
    cover_image VARCHAR,             -- Banner/header image (S3/CloudFront)
    bio TEXT,
    social_links JSON,                -- Social media URLs object
    followers_count INTEGER DEFAULT 0,
    total_plays INTEGER DEFAULT 0,    -- Aggregate podcast plays
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

**Auto-created** when user uploads content  
**Follow System**: `artist_followers` table tracks relationships

#### 3. **podcasts** - Audio/Video Podcasts
```sql
CREATE TABLE podcasts (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    audio_url VARCHAR,               -- Relative path: audio/{uuid}.{ext}
    video_url VARCHAR,                -- Relative path: video/{uuid}.{ext}
    cover_image VARCHAR,              -- Thumbnail URL (S3: images/thumbnails/podcasts/...)
    creator_id INTEGER REFERENCES users(id),
    category_id INTEGER REFERENCES categories(id),
    duration INTEGER,                 -- Duration in seconds
    status VARCHAR DEFAULT 'pending', -- pending, approved, rejected
    plays_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Approval Workflow**: Non-admin posts require admin approval

#### 4. **movies** - Full-Length Movies
```sql
CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    description TEXT,
    video_url VARCHAR NOT NULL,      -- Full movie video (S3: video/{uuid}.{ext})
    cover_image VARCHAR,              -- Poster/thumbnail (S3: images/movies/{uuid}.{ext})
    preview_url VARCHAR,              -- Pre-generated preview clip (S3: video/previews/{uuid}.{ext})
    preview_start_time INTEGER,       -- Preview window start (seconds)
    preview_end_time INTEGER,         -- Preview window end (seconds)
    director VARCHAR,
    cast TEXT,                        -- JSON array or comma-separated
    release_date TIMESTAMP,
    rating FLOAT,                     -- User rating 0-10
    category_id INTEGER REFERENCES categories(id),
    creator_id INTEGER REFERENCES users(id),
    duration INTEGER,                 -- Total duration in seconds
    status VARCHAR DEFAULT 'pending',
    plays_count INTEGER DEFAULT 0,
    is_featured BOOLEAN DEFAULT FALSE, -- For hero carousel
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 5. **music_tracks** - Music Content
```sql
CREATE TABLE music_tracks (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    artist VARCHAR,
    album VARCHAR,
    genre VARCHAR,
    audio_url VARCHAR NOT NULL,       -- S3 path: audio/{uuid}.{ext}
    cover_image VARCHAR,              -- Album art (S3: images/{uuid}.{ext})
    duration INTEGER,
    lyrics TEXT,
    is_featured BOOLEAN DEFAULT FALSE,
    is_published BOOLEAN DEFAULT FALSE,
    plays_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 6. **community_posts** - Social Media Posts
```sql
CREATE TABLE community_posts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    title VARCHAR NOT NULL,
    content TEXT NOT NULL,
    image_url VARCHAR,                -- Photo URL or generated quote image URL
    category VARCHAR NOT NULL,         -- testimony, prayer_request, question, announcement, general
    post_type VARCHAR DEFAULT 'image', -- 'image' or 'text'
    is_approved INTEGER DEFAULT 0,     -- 0=False, 1=True (SQLite boolean)
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Text Posts**: Auto-converted to styled quote images via `quote_image_service.py`
- Generated images saved to: `images/quotes/quote_{post_id}_{hash}.jpg`
- Uses PIL/Pillow with predefined templates

#### 7. **comments** - Post Comments
```sql
CREATE TABLE comments (
    id INTEGER PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES community_posts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 8. **likes** - Post Likes
```sql
CREATE TABLE likes (
    id INTEGER PRIMARY KEY,
    post_id INTEGER NOT NULL REFERENCES community_posts(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(post_id, user_id)          -- Prevents duplicate likes
);
```

#### 9. **playlists** - User Playlists
```sql
CREATE TABLE playlists (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id),
    name VARCHAR NOT NULL,
    description TEXT,
    cover_image VARCHAR,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 10. **playlist_items** - Playlist Content
```sql
CREATE TABLE playlist_items (
    id INTEGER PRIMARY KEY,
    playlist_id INTEGER NOT NULL REFERENCES playlists(id),
    content_type VARCHAR NOT NULL,    -- "podcast", "music", etc.
    content_id INTEGER NOT NULL,      -- ID of content item
    position INTEGER                  -- Order in playlist
);
```

#### 11. **bank_details** - Creator Payment Info
```sql
CREATE TABLE bank_details (
    id INTEGER PRIMARY KEY,
    user_id INTEGER UNIQUE NOT NULL REFERENCES users(id),
    account_number VARCHAR NOT NULL,  -- Should be encrypted
    ifsc_code VARCHAR,
    swift_code VARCHAR,
    bank_name VARCHAR,
    account_holder_name VARCHAR,
    branch_name VARCHAR,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP
);
```

**Purpose**: Creator payment information for revenue sharing

#### 12. **payment_accounts** - Payment Gateway Accounts
```sql
CREATE TABLE payment_accounts (
    id INTEGER PRIMARY KEY,
    user_id INTEGER UNIQUE REFERENCES users(id),
    provider VARCHAR,                 -- 'stripe', 'paypal'
    account_id VARCHAR,
    is_active BOOLEAN
);
```

#### 13. **donations** - Donation Transactions
```sql
CREATE TABLE donations (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    recipient_id INTEGER REFERENCES users(id),
    amount FLOAT,
    currency VARCHAR,
    status VARCHAR,                   -- pending, completed, failed
    payment_method VARCHAR,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 14. **live_streams** - Meeting/Stream Records
```sql
CREATE TABLE live_streams (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    title VARCHAR,
    description TEXT,
    status VARCHAR,
    room_name VARCHAR,                -- LiveKit room name
    started_at TIMESTAMP,
    ended_at TIMESTAMP
);
```

#### 15. **document_assets** - PDF Documents (Bible, etc.)
```sql
CREATE TABLE document_assets (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    file_url VARCHAR NOT NULL,        -- S3 path: documents/{filename}.pdf
    file_type VARCHAR,
    file_size INTEGER,
    created_at TIMESTAMP DEFAULT NOW()
);
```

**Admin-only uploads**

#### 16. **support_messages** - Support Tickets
```sql
CREATE TABLE support_messages (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    subject VARCHAR,
    message TEXT,
    status VARCHAR,
    admin_response TEXT,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 17. **bible_stories** - Bible Story Content
```sql
CREATE TABLE bible_stories (
    id INTEGER PRIMARY KEY,
    title VARCHAR NOT NULL,
    scripture_reference VARCHAR,
    content TEXT,
    audio_url VARCHAR,                 -- S3 path: audio/{uuid}.{ext}
    cover_image VARCHAR,               -- S3 path: images/{uuid}.{ext}
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 18. **notifications** - User Notifications
```sql
CREATE TABLE notifications (
    id INTEGER PRIMARY KEY,
    user_id INTEGER REFERENCES users(id),
    type VARCHAR,                      -- enum type
    title VARCHAR,
    message TEXT,
    data JSON,                         -- Additional data
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 19. **categories** - Content Categories
```sql
CREATE TABLE categories (
    id INTEGER PRIMARY KEY,
    name VARCHAR NOT NULL,
    type VARCHAR                        -- podcast, music, community, etc.
);
```

#### 20. **email_verification** - Email Verification Tokens
```sql
CREATE TABLE email_verification (
    id INTEGER PRIMARY KEY,
    email VARCHAR NOT NULL,
    otp_code VARCHAR NOT NULL,
    expires_at TIMESTAMP NOT NULL,
    verified BOOLEAN DEFAULT FALSE
);
```

#### 21. **artist_followers** - Follow Relationships
```sql
CREATE TABLE artist_followers (
    id INTEGER PRIMARY KEY,
    artist_id INTEGER NOT NULL REFERENCES artists(id),
    user_id INTEGER NOT NULL REFERENCES users(id),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(artist_id, user_id)
);
```

### Additional Tables

- **refresh_tokens** - JWT refresh tokens
- **device_tokens** - Push notification device tokens
- **content_drafts** - Draft content (unpublished)
- **favorites** - User favorites
- **events** - Event management
- **event_attendees** - Event attendance tracking

---

## Backend Structure - Complete Analysis

### Directory Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app entry point
│   ├── config.py                  # Settings & configuration
│   ├── agents/
│   │   └── voice_agent.py         # LiveKit voice agent
│   ├── database/
│   │   └── connection.py         # Database connection & session management
│   ├── middleware/
│   │   └── auth_middleware.py     # JWT authentication middleware
│   ├── models/                    # SQLAlchemy models (21 files)
│   │   ├── user.py
│   │   ├── podcast.py
│   │   ├── movie.py
│   │   ├── community.py
│   │   └── ... (18 more)
│   ├── routes/                    # API route handlers (24 files)
│   │   ├── auth.py
│   │   ├── upload.py
│   │   ├── podcasts.py
│   │   ├── community.py
│   │   └── ... (20 more)
│   ├── schemas/                   # Pydantic schemas (11 files)
│   │   ├── auth.py
│   │   ├── podcast.py
│   │   └── ... (9 more)
│   ├── services/                  # Business logic (15 files)
│   │   ├── media_service.py       # S3 upload/download
│   │   ├── auth_service.py        # Authentication logic
│   │   ├── video_editing_service.py
│   │   ├── audio_editing_service.py
│   │   └── ... (11 more)
│   └── websocket/
│       └── socket_io_handler.py  # WebSocket/Socket.io handlers
├── migrations/                    # Alembic migrations
├── scripts/                      # Utility scripts
├── media/                         # Local media storage (dev only)
├── Dockerfile
├── requirements.txt
└── .env                           # Environment variables
```

### Key Backend Files

#### `app/main.py`
- FastAPI application initialization
- CORS configuration
- Static file mounting (dev only)
- Voice agent process management
- Socket.io integration
- Startup/shutdown events

#### `app/config.py`
- Environment variable management
- Settings class with defaults
- Database URL, S3 config, LiveKit config
- CORS origins configuration

#### `app/database/connection.py`
- Async SQLAlchemy engine creation
- Lazy initialization (prevents import-time DB connection)
- PostgreSQL and SQLite support
- Session factory management

### Route Files (24 Total)

1. **auth.py** - Authentication (login, register, Google OAuth, OTP)
2. **users.py** - User management
3. **artists.py** - Artist profiles, follow system
4. **podcasts.py** - Podcast CRUD, listing
5. **movies.py** - Movie CRUD, listing
6. **music.py** - Music track management
7. **community.py** - Community posts, likes, comments
8. **playlists.py** - Playlist management
9. **upload.py** - File upload endpoints (audio, video, image, document)
10. **audio_editing.py** - Audio editing (trim, merge, fade)
11. **video_editing.py** - Video editing (trim, audio, overlays, filters)
12. **live_stream.py** - Live streaming endpoints
13. **livekit_voice.py** - Voice agent endpoints
14. **voice_chat.py** - Voice chat endpoints
15. **documents.py** - PDF document management
16. **bible_stories.py** - Bible story content
17. **support.py** - Support ticket system
18. **admin.py** - Admin dashboard, moderation
19. **admin_google_drive.py** - Google Drive bulk upload
20. **notifications.py** - User notifications
21. **events.py** - Event management
22. **device_tokens.py** - Push notification tokens
23. **content_drafts.py** - Draft content management
24. **favorites.py** - User favorites
25. **media.py** - Media metadata endpoints

### Service Files (15 Total)

1. **media_service.py** - S3 upload/download, file management
2. **auth_service.py** - Password hashing, JWT token creation
3. **artist_service.py** - Artist profile management
4. **video_editing_service.py** - FFmpeg video processing
5. **audio_editing_service.py** - FFmpeg audio processing
6. **thumbnail_service.py** - Thumbnail generation
7. **quote_image_service.py** - Quote image generation (PIL/Pillow)
8. **livekit_service.py** - LiveKit room/token management
9. **ai_service.py** - OpenAI integration
10. **username_service.py** - Unique username generation
11. **email_service.py** - AWS SES email sending
12. **payment_service.py** - Stripe/PayPal integration
13. **google_drive_service.py** - Google Drive API
14. **notification_service.py** - Push notifications
15. **refresh_token_service.py** - Refresh token management

---

## Web Frontend Structure - Complete Analysis

### Directory Structure

```
web/frontend/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── config/
│   │   └── app_config.dart        # Environment configuration
│   ├── navigation/
│   │   ├── app_router.dart        # GoRouter setup
│   │   ├── app_routes.dart        # Route definitions
│   │   └── web_navigation.dart    # Web navigation helpers
│   ├── screens/
│   │   ├── web/                   # Web-specific screens (41 files)
│   │   ├── admin/                 # Admin screens (12 files)
│   │   ├── creation/              # Content creation (8 files)
│   │   ├── editing/                # Audio/video editors (2 files)
│   │   ├── community/              # Community features (2 files)
│   │   ├── live/                   # Live streaming (5 files)
│   │   ├── meeting/                # Video meetings (5 files)
│   │   ├── voice/                  # Voice agent (1 file)
│   │   ├── bible/                  # Bible reader (3 files)
│   │   ├── events/                 # Events (4 files)
│   │   ├── support/                # Support (1 file)
│   │   └── drafts/                 # Drafts (1 file)
│   ├── services/
│   │   ├── api_service.dart        # REST API client (3736 lines)
│   │   ├── auth_service.dart       # Authentication
│   │   ├── google_auth_service.dart
│   │   ├── websocket_service.dart  # Real-time notifications
│   │   ├── audio_editing_service.dart
│   │   ├── video_editing_service.dart
│   │   ├── livekit_meeting_service.dart
│   │   ├── livekit_voice_service.dart
│   │   ├── donation_service.dart
│   │   ├── download_service.dart
│   │   └── web_storage_service.dart # localStorage/sessionStorage
│   ├── providers/                 # State management (14 providers)
│   │   ├── auth_provider.dart
│   │   ├── app_state.dart
│   │   ├── audio_player_provider.dart
│   │   ├── music_provider.dart
│   │   ├── community_provider.dart
│   │   └── ... (9 more)
│   ├── models/                     # Data models
│   │   ├── api_models.dart
│   │   ├── content_item.dart
│   │   ├── artist.dart
│   │   └── ... (4 more)
│   ├── widgets/                    # Reusable widgets (56 files)
│   ├── theme/                      # Theme configuration
│   │   ├── app_theme.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_spacing.dart
│   └── utils/                      # Utility functions (21 files)
├── web/
│   ├── index.html
│   └── manifest.json
├── pubspec.yaml
└── amplify.yml                     # Amplify build configuration
```

### Key Frontend Files

#### `lib/main.dart`
- App entry point
- Initializes AppRouter

#### `lib/navigation/app_router.dart`
- Provider setup (14 providers)
- GoRouter configuration
- WebSocket initialization

#### `lib/services/api_service.dart` (3736 lines)
- Complete REST API client
- Media URL resolution (S3/CloudFront)
- Authentication header management
- Token refresh handling
- All API endpoints implemented

#### `lib/services/auth_service.dart`
- Login/logout
- Token storage (localStorage/sessionStorage)
- Token expiration checking
- Refresh token management
- "Remember Me" functionality

#### `lib/providers/auth_provider.dart`
- Authentication state management
- Auto-login on app start
- Token expiration monitoring
- Visibility change detection (web)

### Web Screens (41 Total in `screens/web/`)

#### Core Screens
1. `home_screen_web.dart` - Featured content, hero carousel
2. `landing_screen_web.dart` - Landing page
3. `about_screen_web.dart` - About page

#### Content Screens
4. `podcasts_screen_web.dart` - Podcast listing with filters
5. `movies_screen_web.dart` - Movie listing
6. `movie_detail_screen_web.dart` - Movie details with preview
7. `movie_preview_screen_web.dart` - Movie preview player
8. `music_screen_web.dart` - Music player
9. `video_podcast_detail_screen_web.dart` - Video podcast details
10. `audio_player_full_screen_web.dart` - Audio player

#### Community Screens
11. `community_screen_web.dart` - Social feed (Instagram-like)
12. `prayer_screen_web.dart` - Prayer requests
13. `join_prayer_screen_web.dart` - Join prayer

#### Creation Screens
14. `create_screen_web.dart` - Content creation hub
15. `video_editor_screen_web.dart` - Professional video editor
16. `video_recording_screen_web.dart` - Record video
17. `video_preview_screen_web.dart` - Preview before publishing

#### Live/Meeting Screens
18. `live_screen_web.dart` - Live streaming hub
19. `stream_screen_web.dart` - Stream viewer
20. `live_stream_options_screen_web.dart` - Stream setup
21. `meetings_screen_web.dart` - Meeting list
22. `meeting_options_screen_web.dart` - Meeting options
23. `meeting_room_screen_web.dart` - LiveKit meeting room

#### User Screens
24. `profile_screen_web.dart` - User profile
25. `library_screen_web.dart` - User library
26. `favorites_screen_web.dart` - User favorites
27. `downloads_screen_web.dart` - Offline downloads
28. `notifications_screen_web.dart` - Notifications

#### Voice Screens
29. `voice_agent_screen_web.dart` - AI voice assistant
30. `voice_chat_screen_web.dart` - Voice chat

#### Admin Screens
31. `admin_dashboard_web.dart` - Admin dashboard
32. `admin_login_screen_web.dart` - Admin login

#### Other Screens
33. `search_screen_web.dart` - Search functionality
34. `support_screen_web.dart` - Support tickets
35. `bible_stories_screen_web.dart` - Bible stories
36. `discover_screen_web.dart` - Content discovery
37. `not_found_screen_web.dart` - 404 page
38. `offline_screen_web.dart` - Offline mode
39. `user_login_screen_web.dart` - User login
40. `register_screen_web.dart` - User registration
41. `bank_details_screen_web.dart` - Bank details form

### Additional Screens (Outside `screens/web/`)

- **Admin**: 12 admin pages (pending, approved, users, posts, etc.)
- **Creation**: 8 creation screens (audio/video recording, preview)
- **Editing**: 2 editor screens (audio, video)
- **Community**: 2 screens (create post, comments)
- **Live**: 5 live streaming screens
- **Meeting**: 5 meeting screens
- **Voice**: 1 voice agent screen
- **Bible**: 3 Bible reader screens
- **Events**: 4 event screens
- **Support**: 1 support screen
- **Drafts**: 1 drafts screen

**Total Web Screens: ~90+ screens**

---

## Mobile Frontend Structure - Complete Analysis

### Directory Structure

```
mobile/frontend/
├── lib/
│   ├── main.dart
│   ├── screens/
│   │   ├── mobile/                # Mobile-specific screens (18 files)
│   │   ├── admin/                 # Admin screens (14 files)
│   │   ├── creation/              # Content creation (6 files)
│   │   ├── editing/               # Audio/video editors (2 files)
│   │   ├── community/             # Community (2 files)
│   │   ├── live/                  # Live streaming (4 files)
│   │   ├── meeting/               # Video meetings (5 files)
│   │   ├── voice/                 # Voice agent (1 file)
│   │   ├── bible/                 # Bible reader (3 files)
│   │   ├── events/                 # Events (4 files)
│   │   └── support/               # Support (1 file)
│   ├── services/                  # API services (similar to web)
│   ├── providers/                 # State management (13 providers)
│   └── ... (similar structure to web)
├── .env                           # Environment configuration
└── pubspec.yaml
```

### Mobile Screens (18 Total in `screens/mobile/`)

1. `home_screen_mobile.dart` - Layered UI with carousel
2. `discover_screen_mobile.dart` - Content discovery
3. `podcasts_screen_mobile.dart` - Podcast listing
4. `music_screen_mobile.dart` - Music player
5. `community_screen_mobile.dart` - Social feed
6. `create_screen_mobile.dart` - Content creation hub
7. `library_screen_mobile.dart` - User library
8. `profile_screen_mobile.dart` - User profile
9. `search_screen_mobile.dart` - Search functionality
10. `live_screen_mobile.dart` - Live streaming
11. `meeting_options_screen_mobile.dart` - Meeting options
12. `bible_stories_screen_mobile.dart` - Bible stories
13. `quote_create_screen_mobile.dart` - Quote post creation
14. `voice_chat_modal.dart` - Voice agent modal
15. `downloads_screen_mobile.dart` - Offline downloads
16. `favorites_screen_mobile.dart` - User favorites
17. `notifications_screen_mobile.dart` - Notifications
18. `about_screen_mobile.dart` - About page

### Mobile Navigation

**Bottom Tab Navigation** (5 tabs):
1. **Home** - Featured content, podcasts, movies carousel
2. **Search** - Content discovery
3. **Create** - Content creation hub (audio/video/quote)
4. **Community** - Social feed with posts
5. **Profile** - User profile, settings, library

---

## S3 & CloudFront Integration

### S3 Bucket Configuration

- **Bucket Name**: `cnt-web-media`
- **Region**: `eu-west-2` (London)
- **CloudFront URL**: `https://d126sja5o8ue54.cloudfront.net`
- **Distribution ID**: `E3ER061DLFYFK8`
- **OAC ID**: `E1LSA9PF0Z69X7`

### S3 Folder Structure

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

### Access Control

**Bucket Policy**:
1. **CloudFront OAC Access**: Public reads via CloudFront distribution
2. **EC2 Server IP Access**: Direct S3 access from EC2 (52.56.78.203) for uploads

**Backend S3 Access**:
- Uses `boto3` client with AWS credentials from `.env`
- Required environment variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION=eu-west-2`
  - `S3_BUCKET_NAME=cnt-web-media`

**Permissions Required**:
- `s3:PutObject` - Upload files
- `s3:GetObject` - Read/download files
- `s3:ListBucket` - List objects

### Media URL Resolution

**Development Mode**:
- Local files served from `/media` endpoint
- Paths include `/media/` prefix

**Production Mode**:
- Files served from CloudFront
- Direct S3 path mapping (no `/media/` prefix)
- Frontend handles URL resolution via `api_service.dart`:
  ```dart
  String getMediaUrl(String? path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;  // Already full URL
    }
    // Strip legacy 'media/' prefix if present
    String cleanPath = path.startsWith('media/') 
      ? path.substring(6) 
      : path;
    // CloudFront URL maps directly to S3 paths
    return '$mediaBaseUrl/$cleanPath';
  }
  ```

---

## Authentication & Authorization

### Authentication Methods

#### 1. Email/Password Login
- **Endpoint**: `POST /api/v1/auth/login`
- **Input**: `username_or_email` + `password`
- **Returns**: JWT access token + refresh token
- **Storage**: 
  - Web: localStorage (if "Remember Me") or sessionStorage
  - Mobile: flutter_secure_storage

#### 2. Google OAuth
- **Endpoint**: `POST /api/v1/auth/google-login`
- **Supports**: Both `id_token` and `access_token`
- **Auto-creates** user account if first login
- **Links** to existing account if email matches
- **Avatar Handling**: Downloads Google profile picture and uploads to S3

#### 3. User Registration
- **Endpoint**: `POST /api/v1/auth/register`
- **Required**: `email`, `password`, `name`
- **Optional**: `phone`, `date_of_birth`, `bio`
- **Auto-generates** unique `username` via `username_service.py`

#### 4. OTP-Based Registration
- **Endpoints**:
  - `POST /api/v1/auth/send-otp` - Send verification code
  - `POST /api/v1/auth/verify-otp` - Verify code
  - `POST /api/v1/auth/register-with-otp` - Register with verified email

### Token Management

- **Access Token Expiration**: 30 minutes (configurable)
- **Refresh Token Expiration**: 30 days (configurable)
- **Refresh Token Rotation**: Enabled (new refresh token on each refresh)
- **Storage**:
  - Web: localStorage/sessionStorage based on "Remember Me"
  - Mobile: flutter_secure_storage

### Authorization

- **Middleware**: `auth_middleware.py` validates tokens on protected routes
- **Admin Routes**: Additional `is_admin` check
- **User Context**: `get_current_user` dependency provides user object

---

## API Endpoints - Complete Reference

### Authentication (`/api/v1/auth`)
- `POST /login` - Email/password login
- `POST /register` - User registration
- `POST /google-login` - Google OAuth
- `POST /send-otp` - Send OTP verification code
- `POST /verify-otp` - Verify OTP code
- `POST /register-with-otp` - Register with verified email
- `POST /check-username` - Username availability
- `GET /google-client-id` - Get OAuth client ID
- `POST /refresh-token` - Refresh access token

### Content
- `GET /podcasts` - List podcasts (with filters)
- `POST /podcasts` - Create podcast
- `GET /podcasts/{id}` - Get podcast details
- `GET /movies` - List movies
- `POST /movies` - Create movie
- `GET /movies/{id}` - Get movie details
- `GET /music` - List music tracks
- `POST /music` - Create music track

### Community
- `GET /community/posts` - List posts
- `POST /community/posts` - Create post
- `GET /community/posts/{id}` - Get post details
- `POST /community/posts/{id}/like` - Like/unlike post
- `POST /community/posts/{id}/comments` - Add comment
- `GET /community/posts/{id}/comments` - Get comments

### Upload
- `POST /upload/audio` - Upload audio file
- `POST /upload/video` - Upload video file
- `POST /upload/image` - Upload image
- `POST /upload/profile-image` - Upload avatar
- `POST /upload/thumbnail` - Upload thumbnail
- `POST /upload/temporary-audio` - Upload temp audio (editing)
- `POST /upload/document` - Upload PDF (admin only)
- `GET /upload/media/duration` - Get media duration
- `GET /upload/thumbnail/defaults` - Get default thumbnails

### Editing
- `POST /audio-editing/trim` - Trim audio
- `POST /audio-editing/merge` - Merge audio files
- `POST /audio-editing/fade-in` - Fade in effect
- `POST /audio-editing/fade-out` - Fade out effect
- `POST /audio-editing/fade-in-out` - Fade in/out
- `POST /video-editing/trim` - Trim video
- `POST /video-editing/remove-audio` - Remove audio track
- `POST /video-editing/add-audio` - Add audio track
- `POST /video-editing/replace-audio` - Replace audio track
- `POST /video-editing/add-text-overlays` - Add text overlays
- `POST /video-editing/apply-filters` - Apply filters

### Artists
- `GET /artists/me` - Get current user's artist profile
- `PUT /artists/me` - Update artist profile
- `POST /artists/me/cover-image` - Upload cover image
- `GET /artists/{id}` - Get artist profile
- `GET /artists/{id}/podcasts` - Get artist podcasts
- `POST /artists/{id}/follow` - Follow artist
- `DELETE /artists/{id}/follow` - Unfollow artist

### Live/Voice
- `GET /live/streams` - List streams
- `POST /live/streams` - Create stream
- `POST /live/streams/{id}/join` - Join stream
- `POST /live/streams/{id}/livekit-token` - Get LiveKit token
- `POST /livekit/voice/token` - Get voice agent token
- `POST /livekit/voice/room` - Create voice room
- `DELETE /livekit/voice/room/{name}` - Delete voice room
- `GET /livekit/voice/rooms` - List voice rooms
- `GET /livekit/voice/health` - Voice agent health

### Admin
- `GET /admin/dashboard` - Admin stats
- `GET /admin/pending` - Pending content
- `POST /admin/approve/{type}/{id}` - Approve content
- `POST /admin/reject/{type}/{id}` - Reject content

### Other Endpoints
- Playlists, Support, Categories, Bible Stories, Documents, Donations, Bank Details, Notifications, Events, Device Tokens, Content Drafts, Favorites, Media

**Total API Endpoints: 100+**

---

## File Upload Flows

### 1. Audio Podcast Upload

**Flow**:
1. User selects "Audio Podcast" from Create screen
2. Options: **Record audio** OR **Upload file**
3. If recording: Uses MediaRecorder API (web) or `record` package (mobile)
4. If uploading: File picker (MP3, WAV, WebM, M4A, AAC, FLAC)
5. Preview screen shows duration, allows editing
6. Upload to backend: `POST /api/v1/upload/audio`
   - Backend validates file type
   - Generates unique filename: `{uuid}.{ext}`
   - Saves to S3: `audio/{uuid}.{ext}`
   - Gets duration using FFprobe
   - Optional thumbnail upload
7. Returns: `{filename, url, file_path, duration, thumbnail_url}`
8. Create podcast record: `POST /api/v1/podcasts`
9. Status: "pending" (requires admin approval unless user is admin)

### 2. Video Podcast Upload

**Flow**:
1. User selects "Video Podcast" from Create screen
2. Options: **Record video** OR **Choose from gallery**
3. If recording: Uses MediaRecorder API (web) or `camera` package (mobile)
4. If gallery: File picker for video files
5. Preview screen shows video, allows editing
6. Upload to backend: `POST /api/v1/upload/video`
   - Backend validates file type
   - Generates unique filename: `{uuid}.{ext}`
   - Saves to S3: `video/{uuid}.{ext}` (multipart upload for large files)
   - Gets duration using FFprobe
   - Auto-generates thumbnail if `generate_thumbnail=true`
7. Thumbnail Generation:
   - Extracts frame at 45 seconds (or 10% of duration for shorter videos)
   - Saves to S3: `images/thumbnails/podcasts/generated/{uuid}.jpg`
8. Returns: `{filename, url, file_path, duration, thumbnail_url}`
9. Create podcast record: `POST /api/v1/podcasts`
10. Status: "pending" (requires admin approval)

### 3. Image Upload (Community Posts)

**Flow**:
1. User creates post from Community screen
2. Select "Image Post" type
3. Choose photo from gallery or take photo
4. Add caption (title + content)
5. Upload image: `POST /api/v1/upload/image`
   - Backend validates file type
   - Generates unique filename: `{uuid}.{ext}`
   - Saves to S3: `images/{uuid}.{ext}`
6. Returns: `{filename, url, content_type}`
7. Create post: `POST /api/v1/community/posts`
8. Status: "pending" (requires admin approval)

### 4. Text Post (Quote Image Generation)

**Flow**:
1. User creates post, selects "Text Post" type
2. Enter text content
3. Create post: `POST /api/v1/community/posts` (no image yet)
4. Backend detects `post_type='text'`
5. Calls `generate_quote_image()` service
6. Service:
   - Selects random template from `quote_templates.py`
   - Renders text with PIL/Pillow
   - Wraps text to fit within image bounds
   - Calculates optimal font size
   - Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
   - Updates post with `image_url`
7. Returns CloudFront URL

**Templates**: Predefined styles with backgrounds, fonts, colors

### 5. Profile Image Upload

**Flow**:
1. User edits profile
2. Select new avatar image
3. Upload: `POST /api/v1/upload/profile-image`
4. Backend saves to S3: `images/profiles/profile_{uuid}.{ext}`
5. Updates user record with new `avatar` URL

---

## Content Creation Workflows

### Audio Podcast Creation

1. **Record/Upload** → Audio file
2. **Preview** → Shows duration, allows editing
3. **Edit** (optional) → Trim, merge, fade effects
4. **Add Details** → Title, description, category, thumbnail
5. **Upload** → Final file to S3
6. **Create Record** → Database entry with "pending" status
7. **Admin Approval** → Admin reviews and approves/rejects

### Video Podcast Creation

1. **Record/Upload** → Video file
2. **Preview** → Shows video, allows editing
3. **Edit** (optional) → Trim, audio management, text overlays
4. **Add Details** → Title, description, category, thumbnail
5. **Upload** → Final file to S3 (multipart for large files)
6. **Thumbnail Generation** → Auto-generated if not provided
7. **Create Record** → Database entry with "pending" status
8. **Admin Approval** → Admin reviews and approves/rejects

### Community Post Creation

1. **Choose Type** → Image post or Text post
2. **If Image**: Upload image → S3
3. **If Text**: Enter text → Auto-generate quote image
4. **Add Caption** → Title + content
5. **Select Category** → testimony, prayer_request, question, etc.
6. **Create Post** → Database entry with "pending" status
7. **Admin Approval** → Admin reviews and approves/rejects

---

## Real-Time Features

### LiveKit Integration

**Services**:
- **Meetings**: Video conferencing rooms
- **Live Streaming**: Broadcast and viewer interfaces
- **Voice Agent**: AI voice assistant

**Endpoints**:
- `POST /livekit/voice/token` - Get voice agent token
- `POST /live/streams/{id}/livekit-token` - Get meeting token

**Backend Service**: `livekit_service.py`
- Room creation
- Token generation
- Participant management

### WebSocket (Socket.io)

**Service**: `websocket_service.dart` (frontend) + `socket_io_handler.py` (backend)

**Features**:
- Real-time notifications
- Live updates (likes, comments)
- Connection management

---

## Admin Dashboard

### Admin Pages (12 Total)

1. **admin_dashboard_page.dart** - Dashboard with stats
2. **admin_pending_page.dart** - Pending content moderation
3. **admin_approved_page.dart** - Approved content management
4. **admin_posts_page.dart** - Community posts moderation
5. **admin_audio_page.dart** - Audio podcast management
6. **admin_video_page.dart** - Video podcast management
7. **admin_users_page.dart** - User management
8. **admin_support_page.dart** - Support ticket handling
9. **admin_documents_page.dart** - PDF document management
10. **bulk_upload_screen.dart** - Google Drive bulk upload
11. **admin_tools_page.dart** - Admin tools
12. **admin_content_page.dart** - Content management

### Admin Features

- **Content Moderation**: Approve/reject podcasts, movies, posts
- **User Management**: View users, manage permissions
- **Support Tickets**: Respond to user support messages
- **Bulk Upload**: Upload content from Google Drive
- **Statistics**: Dashboard with key metrics

---

## Deployment Architecture

### Backend (AWS EC2)

- **Instance**: EC2 (eu-west-2)
- **Public IP**: 52.56.78.203
- **Domain**: christnewtabernacle.com
- **Database**: RDS PostgreSQL
- **SSH Key**: `christnew.pem` (root folder)

**Deployment**:
```bash
ssh -i christnew.pem ubuntu@52.56.78.203
cd ~/cnt-web-deployment
git pull
sudo systemctl restart cnt-backend
```

**Docker Containers** (on EC2):
- `cnt-backend` - FastAPI backend
- `cnt-livekit-server` - LiveKit server
- `cnt-voice-agent` - Voice agent process

### Web Frontend (AWS Amplify)

- **App Domain**: `d1poes9tyirmht.amplifyapp.com`
- **Branch**: `main`
- **Build Spec**: `amplify.yml`
- **Framework**: Flutter Web

**Build Command**:
```bash
flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
  --dart-define=ENVIRONMENT=production
```

### Mobile Frontend

- **Status**: In development
- **Build**: `flutter build apk --release --dart-define=ENVIRONMENT=production`
- **Configuration**: `.env` file

### Media Storage (AWS S3 + CloudFront)

- **Bucket**: `cnt-web-media` (eu-west-2)
- **CloudFront**: `d126sja5o8ue54.cloudfront.net`
- **Access**: OAC + EC2 IP whitelist

---

## Environment Configuration

### Backend Configuration (`backend/.env`)

**Required**:
```env
DATABASE_URL=postgresql+asyncpg://user:pass@host:5432/db
SECRET_KEY=random_string_for_jwt
S3_BUCKET_NAME=cnt-web-media
CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key
AWS_REGION=eu-west-2
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY=your_api_key
LIVEKIT_API_SECRET=your_api_secret
OPENAI_API_KEY=your_openai_key
DEEPGRAM_API_KEY=your_deepgram_key
ENVIRONMENT=production
```

**Optional**:
```env
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
STRIPE_SECRET_KEY=your_stripe_key
STRIPE_PUBLISHABLE_KEY=your_stripe_publishable_key
PAYPAL_CLIENT_ID=your_paypal_id
PAYPAL_CLIENT_SECRET=your_paypal_secret
REDIS_URL=your_redis_url
CORS_ORIGINS=https://domain1.com,https://domain2.com
```

### Web Configuration (Build-time `--dart-define`)

**Amplify Build Command** (see `amplify.yml`):
- `API_BASE_URL`
- `MEDIA_BASE_URL`
- `LIVEKIT_WS_URL`
- `LIVEKIT_HTTP_URL`
- `WEBSOCKET_URL`
- `ENVIRONMENT=production`
- `GOOGLE_CLIENT_ID`

### Mobile Configuration (`mobile/frontend/.env`)

**Production**:
```env
ENVIRONMENT=production
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
WEBSOCKET_URL=wss://api.christnewtabernacle.com
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
```

**Development**: Auto-detects localhost (or 10.0.2.2 on Android emulator)

---

## Key Services & Providers

### Frontend Services

1. **api_service.dart** - REST API client (3736 lines)
2. **auth_service.dart** - Authentication
3. **google_auth_service.dart** - Google OAuth
4. **websocket_service.dart** - Real-time notifications
5. **audio_editing_service.dart** - Audio editing API calls
6. **video_editing_service.dart** - Video editing API calls
7. **livekit_meeting_service.dart** - LiveKit meetings
8. **livekit_voice_service.dart** - Voice agent
9. **donation_service.dart** - Payment processing
10. **download_service.dart** - Offline downloads
11. **web_storage_service.dart** - localStorage/sessionStorage

### Frontend Providers (State Management)

1. **auth_provider.dart** - Authentication state
2. **app_state.dart** - Global app state
3. **audio_player_provider.dart** - Audio playback state
4. **music_provider.dart** - Music playback
5. **community_provider.dart** - Community posts
6. **user_provider.dart** - User data
7. **playlist_provider.dart** - Playlists
8. **favorites_provider.dart** - User favorites
9. **support_provider.dart** - Support tickets
10. **documents_provider.dart** - Documents/Bible
11. **notification_provider.dart** - Push notifications
12. **artist_provider.dart** - Artist profiles
13. **event_provider.dart** - Events
14. **search_provider.dart** - Search functionality

---

## Screen Inventory

### Web Screens: ~90+ screens
- **Web-specific**: 41 screens
- **Admin**: 12 screens
- **Creation**: 8 screens
- **Editing**: 2 screens
- **Community**: 2 screens
- **Live**: 5 screens
- **Meeting**: 5 screens
- **Voice**: 1 screen
- **Bible**: 3 screens
- **Events**: 4 screens
- **Support**: 1 screen
- **Drafts**: 1 screen
- **Other**: ~5 screens

### Mobile Screens: ~60+ screens
- **Mobile-specific**: 18 screens
- **Admin**: 14 screens
- **Creation**: 6 screens
- **Editing**: 2 screens
- **Community**: 2 screens
- **Live**: 4 screens
- **Meeting**: 5 screens
- **Voice**: 1 screen
- **Bible**: 3 screens
- **Events**: 4 screens
- **Support**: 1 screen
- **Other**: ~5 screens

---

## Summary

### ✅ Production Ready Components

- **Backend API** (AWS EC2) - ✅ Fully functional
- **Web Frontend** (AWS Amplify) - ✅ Production-ready
- **Database** (AWS RDS PostgreSQL) - ✅ Configured
- **Media Storage** (S3 + CloudFront) - ✅ Fully integrated
- **Authentication System** - ✅ JWT + Google OAuth
- **All Core Features** - ✅ Implemented
- **Admin Dashboard** - ✅ Complete
- **Real-Time Features** - ✅ LiveKit integrated

### 🚧 Pending

- **Mobile App Deployment** - Code complete, pending store submission

### 📊 Statistics

- **Database Tables**: 21
- **API Endpoints**: 100+
- **Backend Routes**: 24 files
- **Backend Services**: 15 files
- **Web Screens**: ~90+
- **Mobile Screens**: ~60+
- **Frontend Providers**: 14 (web), 13 (mobile)
- **Frontend Services**: 11

---

**Document Created**: December 2024  
**Status**: Complete comprehensive analysis  
**Next Steps**: Ready for task planning and implementation

