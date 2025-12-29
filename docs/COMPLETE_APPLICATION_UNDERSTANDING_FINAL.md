# CNT Media Platform - Complete Application Understanding

**Date:** December 2024  
**Status:** Comprehensive analysis of all application components, architecture, and connections  
**Focus:** Web application (Flutter Web) + Backend (FastAPI) + Database (PostgreSQL/SQLite) + AWS Infrastructure

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [System Architecture](#system-architecture)
3. [Database Schema - Complete Details](#database-schema)
4. [Backend Architecture - Detailed](#backend-architecture)
5. [Frontend Architecture (Web) - Detailed](#frontend-architecture)
6. [API Endpoints - Complete Reference](#api-endpoints)
7. [Media Storage & S3 Integration](#media-storage)
8. [Authentication & Authorization](#authentication)
9. [Real-Time Features](#realtime-features)
10. [Deployment Configuration](#deployment)
11. [Environment Configuration](#environment-config)
12. [Key Workflows & Data Flows](#workflows)
13. [Code Structure & Organization](#code-structure)

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application with the following architecture:

### Technology Stack

**Backend:**
- **Framework**: FastAPI (Python 3.11+)
- **Database**: PostgreSQL (production via AWS RDS) / SQLite (local development)
- **ORM**: SQLAlchemy 2.0 (async support)
- **Migrations**: Alembic
- **Hosting**: AWS EC2 (eu-west-2, IP: 52.56.78.203)
- **Container**: Docker (running as separate containers)

**Frontend (Web):**
- **Framework**: Flutter Web (Dart)
- **State Management**: Provider pattern
- **Routing**: GoRouter
- **Hosting**: AWS Amplify
- **Build**: Flutter build web with `--dart-define` flags

**Media Storage:**
- **Primary**: AWS S3 bucket `cnt-web-media` (eu-west-2)
- **CDN**: CloudFront distribution `E3ER061DLFYFK8`
- **CloudFront URL**: `https://d126sja5o8ue54.cloudfront.net`
- **Access**: OAC (Origin Access Control) for public reads, EC2 IP for backend writes

**Real-Time Services:**
- **LiveKit**: Meetings, live streaming, voice agent
- **WebSocket**: Socket.io for notifications

**AI Services:**
- **OpenAI**: GPT-4o-mini for voice agent
- **Deepgram**: Nova-3 (STT), Aura-2 (TTS)

### Current Deployment Status

**✅ Production Ready:**
- Backend API (EC2 with Docker)
- Web Frontend (AWS Amplify)
- Database (AWS RDS PostgreSQL)
- Media Storage (S3 + CloudFront)
- All core features implemented

**🚧 In Development:**
- Mobile app (code complete, pending store submission)

---

## System Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Amplify (Web Frontend)                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Flutter Web App (Dart)                               │  │
│  │  - 40+ web screens                                    │  │
│  │  - 13 state providers                                 │  │
│  │  - API service layer                                  │  │
│  │  - WebSocket client                                   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ HTTPS API Calls
                            │ WebSocket (Socket.io)
                            │
┌───────────────────────────▼──────────────────────────────────┐
│              AWS EC2 (eu-west-2) - Backend                   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  FastAPI Application (Python)                        │   │
│  │  - 24 route modules                                  │   │
│  │  - 15 service modules                                │   │
│  │  - 27 database models                                │   │
│  │  - Socket.io WebSocket server                        │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  LiveKit Server (Docker Container)                  │   │
│  │  - Ports: 7880-7881 (WS/HTTP)                        │   │
│  │  - Ports: 50100-50200 (UDP - RTC)                    │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Voice Agent (Docker Container)                     │   │
│  │  - LiveKit agent for AI voice assistant              │   │
│  │  - OpenAI + Deepgram integration                     │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
                            │
                            │ Database Connection
                            │ S3 Uploads
                            │
┌───────────────────────────▼──────────────────────────────────┐
│              AWS RDS PostgreSQL (Production)                │
│  - 27 database tables                                       │
│  - Async SQLAlchemy connections                            │
└──────────────────────────────────────────────────────────────┘

┌───────────────────────────▼──────────────────────────────────┐
│              AWS S3 + CloudFront (Media Storage)             │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  S3 Bucket: cnt-web-media (eu-west-2)                │   │
│  │  - audio/          (podcast audio files)             │   │
│  │  - video/          (podcast video files)             │   │
│  │  - images/         (thumbnails, profiles, quotes)     │   │
│  │  - documents/     (PDF documents)                    │   │
│  │  - animated-bible-stories/                           │   │
│  └──────────────────────────────────────────────────────┘   │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  CloudFront Distribution: E3ER061DLFYFK8            │   │
│  │  - OAC for secure public access                      │   │
│  │  - CDN caching for performance                       │   │
│  │  - URL: https://d126sja5o8ue54.cloudfront.net         │   │
│  └──────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

### Request Flow

**Web Frontend → Backend:**
1. User action in Flutter Web app
2. API call via `ApiService` (Dart HTTP client)
3. Request to EC2 backend: `https://api.christnewtabernacle.com/api/v1/...`
4. FastAPI route handler processes request
5. Database query via SQLAlchemy async session
6. Response returned to frontend

**File Upload Flow:**
1. User selects file in web app
2. File uploaded via multipart/form-data to `/api/v1/upload/*`
3. Backend receives file via FastAPI `UploadFile`
4. `MediaService` saves to S3 (production) or local (development)
5. CloudFront URL returned to frontend
6. Frontend displays media using CloudFront URL

**Real-Time Flow:**
1. WebSocket connection via Socket.io
2. Backend emits events (notifications, updates)
3. Frontend `WebSocketService` listens and updates state
4. UI updates via Provider pattern

---

## Database Schema - Complete Details

### Core Tables (27 Total Models)

#### User Management (3 tables)

**1. users** - User Accounts
```python
- id (PK, Integer)
- username (String, unique, nullable) - Auto-generated unique username
- name (String, required)
- email (String, unique, required)
- avatar (String, nullable) - Profile image URL (S3/CloudFront)
- password_hash (String, nullable) - For email/password auth
- is_admin (Boolean, default: False)
- phone (String, nullable)
- date_of_birth (DateTime, nullable)
- bio (Text, nullable)
- google_id (String, unique, nullable) - Google OAuth ID
- auth_provider (String, default: 'email') - 'email', 'google', 'both'
- created_at, updated_at (DateTime)
```

**Relationships:**
- One-to-many: `podcasts`, `support_messages`, `notifications`, `community_posts`, `hosted_events`
- One-to-one: `artist`, `bank_details`, `payment_account`
- Many-to-many: `event_attendances` (via `EventAttendee`), `refresh_tokens`, `device_tokens`

**2. refresh_tokens** - Token Refresh System
```python
- id (PK, Integer)
- user_id (FK → users.id)
- token (String, unique)
- expires_at (DateTime)
- created_at (DateTime)
```

**3. device_tokens** - Push Notification Tokens
```python
- id (PK, Integer)
- user_id (FK → users.id)
- token (String, unique)
- platform (String) - 'ios', 'android', 'web'
- created_at (DateTime)
```

#### Content Models (6 tables)

**4. podcasts** - Audio/Video Podcasts
```python
- id (PK, Integer)
- title (String, required)
- description (Text, nullable)
- audio_url (String, nullable) - S3 path: audio/{uuid}.{ext}
- video_url (String, nullable) - S3 path: video/{uuid}.{ext}
- cover_image (String, nullable) - Thumbnail URL
- creator_id (FK → users.id, nullable)
- category_id (FK → categories.id, nullable)
- duration (Integer, nullable) - Duration in seconds
- status (String, default: "pending") - pending, approved, rejected
- plays_count (Integer, default: 0)
- created_at (DateTime)
```

**5. movies** - Full-Length Movies
```python
- id (PK, Integer)
- title, description, video_url, cover_image (String)
- preview_url (String, nullable) - Pre-generated preview clip
- preview_start_time, preview_end_time (Integer, nullable)
- director, cast (String/Text, nullable)
- release_date (DateTime, nullable)
- rating (Float, nullable) - User rating 0-10
- category_id, creator_id (FK)
- duration (Integer, nullable)
- status (String, default: "pending")
- plays_count (Integer, default: 0)
- is_featured (Boolean, default: False)
- created_at (DateTime)
```

**6. music_tracks** - Music Content
```python
- id (PK, Integer)
- title, artist, album, genre (String)
- audio_url (String, required)
- cover_image (String, nullable)
- duration (Integer, nullable)
- lyrics (Text, nullable)
- is_featured, is_published (Boolean)
- plays_count (Integer, default: 0)
- created_at (DateTime)
```

**7. document_assets** - PDF Documents (Bible, etc.)
```python
- id (PK, Integer)
- title (String, required)
- file_url (String, required) - S3 path: documents/{filename}.pdf
- file_type (String, default: 'pdf')
- file_size (Integer)
- created_at (DateTime)
```

**8. bible_stories** - Bible Story Content
```python
- id (PK, Integer)
- title, scripture_reference, content (String/Text)
- audio_url, cover_image (String, nullable)
- created_at (DateTime)
```

**9. content_drafts** - Draft Content Storage
```python
- id (PK, Integer)
- user_id (FK → users.id)
- content_type (String) - 'podcast', 'movie', 'post'
- content_data (JSON/Text) - Serialized draft data
- created_at, updated_at (DateTime)
```

#### Community/Social Models (3 tables)

**10. community_posts** - Social Media Posts
```python
- id (PK, Integer)
- user_id (FK → users.id, required)
- title (String, required)
- content (Text, required)
- image_url (String, nullable) - Photo URL or generated quote image
- category (String, required) - testimony, prayer_request, question, announcement, general
- post_type (String, default: 'image') - 'image' or 'text'
- is_approved (Integer, default: 0) - 0=False, 1=True (SQLite boolean)
- likes_count, comments_count (Integer, default: 0)
- created_at (DateTime)
```

**11. comments** - Post Comments
```python
- id (PK, Integer)
- post_id (FK → community_posts.id)
- user_id (FK → users.id)
- content (Text, required)
- created_at (DateTime)
```

**12. likes** - Post Likes
```python
- id (PK, Integer)
- post_id (FK → community_posts.id)
- user_id (FK → users.id)
- created_at (DateTime)
- UNIQUE(post_id, user_id) - Prevents duplicate likes
```

#### Artist & Follow System (2 tables)

**13. artists** - Creator Profiles
```python
- id (PK, Integer)
- user_id (FK → users.id, unique, required)
- artist_name (String, nullable) - Defaults to user.name if not set
- cover_image (String, nullable) - Banner image URL
- bio (Text, nullable)
- social_links (JSONB, nullable) - Social media URLs object
- followers_count (Integer, default: 0)
- total_plays (Integer, default: 0) - Aggregate podcast plays
- is_verified (Boolean, default: False)
- created_at, updated_at (DateTime)
```

**14. artist_followers** - Follow Relationships
```python
- id (PK, Integer)
- artist_id (FK → artists.id)
- user_id (FK → users.id)
- created_at (DateTime)
- UNIQUE(artist_id, user_id) - Prevents duplicate follows
```

#### Playlist System (2 tables)

**15. playlists** - User Playlists
```python
- id (PK, Integer)
- user_id (FK → users.id, required)
- name (String, required)
- description (Text, nullable)
- cover_image (String, nullable)
- created_at (DateTime)
```

**16. playlist_items** - Playlist Content
```python
- id (PK, Integer)
- playlist_id (FK → playlists.id)
- content_type (String) - "podcast", "music", etc.
- content_id (Integer) - ID of content item
- position (Integer) - Order in playlist
```

#### Payment/Financial Models (3 tables)

**17. bank_details** - Creator Payment Info
```python
- id (PK, Integer)
- user_id (FK → users.id, unique, required)
- account_number (String, required) - Should be encrypted
- ifsc_code, swift_code, bank_name, account_holder_name, branch_name (String)
- is_verified (Boolean, default: False)
- created_at, updated_at (DateTime)
```

**18. payment_accounts** - Payment Gateway Accounts
```python
- id (PK, Integer)
- user_id (FK → users.id, unique)
- provider (String) - 'stripe', 'paypal'
- account_id (String)
- is_active (Boolean)
```

**19. donations** - Donation Transactions
```python
- id (PK, Integer)
- user_id, recipient_id (FK → users.id)
- amount (Float)
- currency (String)
- status (String) - pending, completed, failed
- payment_method (String)
- created_at (DateTime)
```

#### Real-Time & Live Features (2 tables)

**20. live_streams** - Meeting/Stream Records
```python
- id (PK, Integer)
- user_id (FK → users.id)
- title, description (String)
- status (String) - active, ended, scheduled
- room_name (String) - LiveKit room name
- started_at, ended_at (DateTime)
- created_at (DateTime)
```

#### Support & Notifications (2 tables)

**21. support_messages** - Support Tickets
```python
- id (PK, Integer)
- user_id (FK → users.id)
- subject, message (String/Text)
- status (String) - open, in_progress, resolved, closed
- admin_response (Text, nullable)
- created_at (DateTime)
```

**22. notifications** - User Notifications
```python
- id (PK, Integer)
- user_id (FK → users.id)
- type (String) - enum type
- title, message (String)
- data (JSONB, nullable) - Additional data
- is_read (Boolean, default: False)
- created_at (DateTime)
```

#### Event System (2 tables)

**23. events** - Event Management
```python
- id (PK, Integer)
- host_id (FK → users.id)
- title, description (String/Text)
- start_time, end_time (DateTime)
- location (String, nullable)
- latitude, longitude (Float, nullable) - For map display
- category (String, nullable)
- created_at, updated_at (DateTime)
```

**24. event_attendees** - Event Attendance
```python
- id (PK, Integer)
- event_id (FK → events.id)
- user_id (FK → users.id)
- status (String) - 'going', 'maybe', 'not_going'
- created_at (DateTime)
- UNIQUE(event_id, user_id)
```

#### Other Models (3 tables)

**25. categories** - Content Categories
```python
- id (PK, Integer)
- name (String, required)
- type (String) - podcast, music, community, etc.
```

**26. email_verification** - Email Verification Tokens
```python
- id (PK, Integer)
- email (String, required)
- otp_code (String, required)
- expires_at (DateTime, required)
- verified (Boolean, default: False)
- created_at (DateTime)
```

**27. favorites** - User Favorites
```python
- id (PK, Integer)
- user_id (FK → users.id)
- content_type (String) - 'podcast', 'movie', 'music'
- content_id (Integer)
- created_at (DateTime)
- UNIQUE(user_id, content_type, content_id)
```

---

## Backend Architecture - Detailed

### Directory Structure

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py                    # FastAPI app initialization
│   ├── config.py                  # Settings and configuration
│   │
│   ├── database/
│   │   ├── __init__.py
│   │   └── connection.py         # Database connection (async SQLAlchemy)
│   │
│   ├── models/                    # SQLAlchemy ORM models (27 files)
│   │   ├── user.py
│   │   ├── podcast.py
│   │   ├── movie.py
│   │   ├── music.py
│   │   ├── community.py
│   │   ├── artist.py
│   │   ├── playlist.py
│   │   ├── bank_details.py
│   │   ├── payment_account.py
│   │   ├── donation.py
│   │   ├── live_stream.py
│   │   ├── document_asset.py
│   │   ├── support_message.py
│   │   ├── bible_story.py
│   │   ├── notification.py
│   │   ├── category.py
│   │   ├── email_verification.py
│   │   ├── event.py
│   │   ├── device_token.py
│   │   ├── content_draft.py
│   │   ├── refresh_token.py
│   │   └── favorite.py
│   │
│   ├── routes/                     # API route handlers (24 files)
│   │   ├── __init__.py            # Router aggregation
│   │   ├── auth.py                # Authentication endpoints
│   │   ├── users.py               # User management
│   │   ├── podcasts.py            # Podcast CRUD
│   │   ├── movies.py              # Movie CRUD
│   │   ├── music.py               # Music CRUD
│   │   ├── community.py           # Community posts, likes, comments
│   │   ├── artists.py             # Artist profiles, follows
│   │   ├── playlists.py           # Playlist management
│   │   ├── upload.py              # File upload endpoints
│   │   ├── audio_editing.py       # Audio editing operations
│   │   ├── video_editing.py       # Video editing operations
│   │   ├── live_stream.py         # Live streaming
│   │   ├── livekit_voice.py       # Voice agent
│   │   ├── voice_chat.py          # Voice chat
│   │   ├── documents.py           # PDF documents
│   │   ├── donations.py           # Donations
│   │   ├── bank_details.py        # Bank details
│   │   ├── bible_stories.py       # Bible stories
│   │   ├── support.py             # Support tickets
│   │   ├── categories.py         # Categories
│   │   ├── notifications.py       # Notifications
│   │   ├── admin.py               # Admin dashboard
│   │   ├── admin_google_drive.py  # Google Drive bulk upload
│   │   ├── events.py              # Events
│   │   ├── device_tokens.py       # Push notifications
│   │   ├── content_drafts.py      # Content drafts
│   │   └── favorites.py           # User favorites
│   │
│   ├── services/                   # Business logic services (15 files)
│   │   ├── auth_service.py        # Authentication logic
│   │   ├── username_service.py    # Username generation
│   │   ├── media_service.py       # S3/local file operations
│   │   ├── thumbnail_service.py  # Thumbnail generation
│   │   ├── quote_image_service.py # Quote image generation
│   │   ├── audio_editing_service.py # FFmpeg audio processing
│   │   ├── video_editing_service.py  # FFmpeg video processing
│   │   ├── artist_service.py      # Artist profile logic
│   │   ├── livekit_service.py     # LiveKit integration
│   │   ├── ai_service.py          # OpenAI integration
│   │   ├── payment_service.py     # Stripe/PayPal
│   │   ├── email_service.py       # AWS SES email
│   │   ├── notification_service.py # Notification logic
│   │   ├── google_drive_service.py # Google Drive API
│   │   ├── refresh_token_service.py # Token refresh logic
│   │   └── firebase_push_service.py # Firebase push notifications
│   │
│   ├── schemas/                    # Pydantic request/response models
│   │   ├── auth.py
│   │   ├── user.py
│   │   ├── podcast.py
│   │   ├── movie.py
│   │   ├── music.py
│   │   ├── playlist.py
│   │   ├── artist.py
│   │   ├── donation.py
│   │   ├── document.py
│   │   ├── event.py
│   │   ├── content_draft.py
│   │   └── support.py
│   │
│   ├── middleware/
│   │   └── auth_middleware.py     # JWT token validation
│   │
│   ├── agents/
│   │   └── voice_agent.py         # LiveKit voice agent
│   │
│   └── websocket/
│       └── socket_io_handler.py   # Socket.io event handlers
│
├── migrations/                     # Alembic database migrations
│   ├── env.py
│   ├── script.py.mako
│   └── versions/                   # Migration files
│
├── scripts/                        # Utility scripts
│   ├── upload_media_to_s3.py
│   ├── create_audio_podcasts_from_s3.py
│   ├── generate_video_thumbnails.py
│   └── ...
│
├── media/                          # Local media storage (development only)
│   ├── audio/
│   ├── video/
│   ├── images/
│   └── documents/
│
├── Dockerfile                      # Backend container
├── requirements.txt                # Python dependencies
├── .env                           # Environment variables (not in git)
└── alembic.ini                    # Alembic configuration
```

### Key Backend Components

#### 1. **FastAPI Application** (`app/main.py`)

**Features:**
- CORS middleware (production: restricted origins, dev: all)
- Static file mounting (development only)
- Proxy headers middleware (for ALB/nginx)
- Socket.io integration
- Voice agent auto-start (can be disabled for Docker)
- Health check endpoint

**Startup Events:**
- Initialize voice agent (if not disabled)
- Seed Bible document

**Shutdown Events:**
- Stop voice agent gracefully

#### 2. **Database Connection** (`app/database/connection.py`)

**Features:**
- Lazy initialization (engine created on first use)
- Async SQLAlchemy support
- PostgreSQL (production) and SQLite (development)
- Connection pooling for PostgreSQL
- Async session factory

**Connection String Format:**
- PostgreSQL: `postgresql+asyncpg://user:pass@host:5432/db`
- SQLite: `sqlite+aiosqlite:///./local.db`

#### 3. **Media Service** (`app/services/media_service.py`)

**Features:**
- S3 uploads (production) or local storage (development)
- Automatic CloudFront URL generation
- Support for audio, video, images, documents
- Thumbnail directory management
- Quote images directory

**S3 Integration:**
- Uses `boto3` client
- Credentials from environment variables
- Uploads to `cnt-web-media` bucket
- Returns CloudFront URLs

#### 4. **Authentication Middleware** (`app/middleware/auth_middleware.py`)

**Features:**
- JWT token validation
- Extracts user from token
- Dependency injection for protected routes
- Token expiration checking

---

## Frontend Architecture (Web) - Detailed

### Directory Structure

```
web/frontend/
├── lib/
│   ├── main.dart                  # App entry point
│   │
│   ├── config/
│   │   └── app_config.dart        # Environment configuration
│   │
│   ├── navigation/
│   │   ├── app_router.dart        # GoRouter setup
│   │   ├── app_routes.dart        # Route definitions
│   │   ├── main_navigation.dart  # Navigation wrapper
│   │   └── web_navigation.dart   # Web-specific navigation
│   │
│   ├── screens/
│   │   ├── web/                   # Web-specific screens (40 files)
│   │   │   ├── home_screen_web.dart
│   │   │   ├── landing_screen_web.dart
│   │   │   ├── podcasts_screen_web.dart
│   │   │   ├── movies_screen_web.dart
│   │   │   ├── music_screen_web.dart
│   │   │   ├── community_screen_web.dart
│   │   │   ├── create_screen_web.dart
│   │   │   ├── video_editor_screen_web.dart
│   │   │   ├── live_screen_web.dart
│   │   │   ├── meetings_screen_web.dart
│   │   │   ├── voice_agent_screen_web.dart
│   │   │   ├── profile_screen_web.dart
│   │   │   ├── admin_dashboard_web.dart
│   │   │   └── ... (27 more screens)
│   │   │
│   │   ├── editing/               # Shared editing screens
│   │   │   ├── audio_editor_screen.dart
│   │   │   └── video_editor_screen.dart
│   │   │
│   │   ├── creation/             # Content creation screens
│   │   │   ├── audio_podcast_create_screen.dart
│   │   │   ├── video_podcast_create_screen.dart
│   │   │   └── ...
│   │   │
│   │   ├── community/            # Community screens
│   │   │   ├── create_post_screen.dart
│   │   │   └── comment_screen.dart
│   │   │
│   │   ├── admin/                # Admin screens (12 files)
│   │   │   └── ...
│   │   │
│   │   └── ... (other shared screens)
│   │
│   ├── services/                  # API and service layer (10 files)
│   │   ├── api_service.dart      # Main API client (3000+ lines)
│   │   ├── auth_service.dart     # Authentication
│   │   ├── google_auth_service.dart
│   │   ├── websocket_service.dart # Socket.io client
│   │   ├── audio_editing_service.dart
│   │   ├── video_editing_service.dart
│   │   ├── livekit_meeting_service.dart
│   │   ├── livekit_voice_service.dart
│   │   ├── donation_service.dart
│   │   └── download_service.dart
│   │
│   ├── providers/                # State management (13 files)
│   │   ├── app_state.dart        # Global app state
│   │   ├── auth_provider.dart    # Authentication state
│   │   ├── user_provider.dart    # User data
│   │   ├── audio_player_provider.dart
│   │   ├── music_provider.dart
│   │   ├── community_provider.dart
│   │   ├── playlist_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── search_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── support_provider.dart
│   │   ├── documents_provider.dart
│   │   ├── artist_provider.dart
│   │   └── event_provider.dart
│   │
│   ├── models/                    # Data models
│   │   ├── api_models.dart
│   │   ├── content_item.dart
│   │   ├── artist.dart
│   │   ├── document_asset.dart
│   │   ├── support_message.dart
│   │   ├── content_draft.dart
│   │   ├── event.dart
│   │   └── text_overlay.dart
│   │
│   ├── widgets/                   # Reusable widgets (51 files)
│   │   └── ...
│   │
│   ├── utils/                     # Utility functions (21 files)
│   │   └── ...
│   │
│   ├── theme/                     # Theming
│   │   ├── app_theme.dart
│   │   ├── app_theme_data.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart
│   │   └── app_animations.dart
│   │
│   └── constants/
│       └── app_constants.dart
│
├── assets/
│   └── images/                    # Static images
│
├── web/
│   ├── index.html                 # HTML entry point
│   ├── manifest.json              # PWA manifest
│   └── icons/                     # App icons
│
├── pubspec.yaml                   # Dart dependencies
└── build/                         # Build output (gitignored)
```

### Key Frontend Components

#### 1. **App Router** (`lib/navigation/app_router.dart`)

**Features:**
- GoRouter for navigation
- Route guards (authentication required)
- Deep linking support
- Web-specific routing

**Route Structure:**
- `/` - Landing page
- `/home` - Home screen
- `/podcasts` - Podcast listing
- `/movies` - Movie listing
- `/community` - Community feed
- `/create` - Content creation
- `/profile` - User profile
- `/admin/*` - Admin routes
- `/live/*` - Live streaming routes
- `/meetings/*` - Meeting routes
- `/voice/*` - Voice agent routes

#### 2. **API Service** (`lib/services/api_service.dart`)

**Features:**
- Centralized API client
- Automatic token injection
- Token expiration handling
- Media URL resolution (CloudFront/local)
- Error handling and retry logic

**Media URL Resolution:**
- Detects full URLs (returns as-is)
- Strips `media/` prefix in production
- Keeps `media/` prefix in development
- Handles CloudFront URLs

#### 3. **Auth Service** (`lib/services/auth_service.dart`)

**Features:**
- JWT token storage (flutter_secure_storage)
- Token expiration checking
- Auto-logout on expiration
- Login, register, Google OAuth
- User data caching
- Token refresh support

#### 4. **State Management** (Provider Pattern)

**Providers:**
- `AuthProvider` - Authentication state
- `AppState` - Global app state
- `AudioPlayerState` - Audio playback
- `MusicProvider` - Music playback
- `CommunityProvider` - Community posts
- `UserProvider` - User data
- `PlaylistProvider` - Playlists
- `FavoritesProvider` - Favorites
- `SearchProvider` - Search functionality
- `NotificationProvider` - Notifications
- `SupportProvider` - Support tickets
- `DocumentsProvider` - PDF documents
- `ArtistProvider` - Artist profiles
- `EventProvider` - Events

---

## API Endpoints - Complete Reference

### Authentication (`/api/v1/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/login` | Email/password login | No |
| POST | `/register` | User registration | No |
| POST | `/google-login` | Google OAuth login | No |
| POST | `/send-otp` | Send OTP verification code | No |
| POST | `/verify-otp` | Verify OTP code | No |
| POST | `/register-with-otp` | Register with verified email | No |
| POST | `/check-username` | Check username availability | No |
| GET | `/google-client-id` | Get Google OAuth client ID | No |
| POST | `/refresh-token` | Refresh access token | No |

### Content (`/api/v1`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/podcasts` | List podcasts | No |
| POST | `/podcasts` | Create podcast | Yes |
| GET | `/podcasts/{id}` | Get podcast details | No |
| GET | `/movies` | List movies | No |
| POST | `/movies` | Create movie | Yes |
| GET | `/movies/{id}` | Get movie details | No |
| GET | `/music` | List music tracks | No |
| POST | `/music` | Create music track | Yes |

### Community (`/api/v1/community`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/posts` | List community posts | No |
| POST | `/posts` | Create post | Yes |
| GET | `/posts/{id}` | Get post details | No |
| POST | `/posts/{id}/like` | Like/unlike post | Yes |
| POST | `/posts/{id}/comments` | Add comment | Yes |
| GET | `/posts/{id}/comments` | Get comments | No |

### Upload (`/api/v1/upload`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/audio` | Upload audio file | Yes |
| POST | `/video` | Upload video file | Yes |
| POST | `/image` | Upload image | Yes |
| POST | `/profile-image` | Upload profile image | Yes |
| POST | `/thumbnail` | Upload thumbnail | Yes |
| POST | `/temporary-audio` | Upload temp audio (editing) | Yes |
| POST | `/document` | Upload PDF (admin only) | Yes (Admin) |
| GET | `/media/duration` | Get media duration | No |
| GET | `/thumbnail/defaults` | Get default thumbnails | No |

### Editing (`/api/v1`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/audio-editing/trim` | Trim audio | Yes |
| POST | `/audio-editing/merge` | Merge audio files | Yes |
| POST | `/audio-editing/fade-in` | Fade in effect | Yes |
| POST | `/audio-editing/fade-out` | Fade out effect | Yes |
| POST | `/audio-editing/fade-in-out` | Fade in/out | Yes |
| POST | `/video-editing/trim` | Trim video | Yes |
| POST | `/video-editing/remove-audio` | Remove audio track | Yes |
| POST | `/video-editing/add-audio` | Add audio track | Yes |
| POST | `/video-editing/replace-audio` | Replace audio track | Yes |
| POST | `/video-editing/add-text-overlays` | Add text overlays | Yes |
| POST | `/video-editing/apply-filters` | Apply filters | Yes |

### Artists (`/api/v1/artists`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/me` | Get current user's artist profile | Yes |
| PUT | `/me` | Update artist profile | Yes |
| POST | `/me/cover-image` | Upload cover image | Yes |
| GET | `/{id}` | Get artist profile | No |
| GET | `/{id}/podcasts` | Get artist podcasts | No |
| POST | `/{id}/follow` | Follow artist | Yes |
| DELETE | `/{id}/follow` | Unfollow artist | Yes |

### Live/Voice (`/api/v1`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/live/streams` | List streams | No |
| POST | `/live/streams` | Create stream | Yes |
| POST | `/live/streams/{id}/join` | Join stream | Yes |
| POST | `/live/streams/{id}/livekit-token` | Get LiveKit token | Yes |
| POST | `/livekit/voice/token` | Get voice agent token | Yes |
| POST | `/livekit/voice/room` | Create voice room | Yes |
| DELETE | `/livekit/voice/room/{name}` | Delete voice room | Yes |
| GET | `/livekit/voice/rooms` | List voice rooms | Yes |
| GET | `/livekit/voice/health` | Voice agent health | No |

### Admin (`/api/v1/admin`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| GET | `/dashboard` | Admin stats | Yes (Admin) |
| GET | `/pending` | Pending content | Yes (Admin) |
| POST | `/approve/{type}/{id}` | Approve content | Yes (Admin) |
| POST | `/reject/{type}/{id}` | Reject content | Yes (Admin) |

### Other Endpoints

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
- `/api/v1/content-drafts/*` - Content drafts
- `/api/v1/device-tokens/*` - Push notification tokens

---

## Media Storage & S3 Integration

### S3 Bucket Structure

**Bucket Name:** `cnt-web-media`  
**Region:** `eu-west-2` (London)  
**CloudFront Distribution:** `E3ER061DLFYFK8`  
**CloudFront URL:** `https://d126sja5o8ue54.cloudfront.net`

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

**Bucket Policy:**
1. **CloudFront OAC Access**: Public reads via CloudFront distribution
2. **EC2 Server IP Access**: Direct S3 access from EC2 (52.56.78.203) for uploads

**Backend S3 Access:**
- Uses `boto3` client
- Credentials from environment variables
- Uploads to `cnt-web-media` bucket
- Returns CloudFront URLs

**Permissions Required:**
- `s3:PutObject` - Upload files
- `s3:GetObject` - Read/download files
- `s3:ListBucket` - List objects

### CloudFront Configuration

**Distribution ID:** `E3ER061DLFYFK8`  
**OAC ID:** `E1LSA9PF0Z69X7`  
**Origin:** S3 bucket `cnt-web-media`  
**Caching:** Standard caching with TTL

**URL Format:**
- Production: `https://d126sja5o8ue54.cloudfront.net/{path}`
- Example: `https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3`

---

## Authentication & Authorization

### Authentication Methods

#### 1. **Email/Password Login**

**Endpoint:** `POST /api/v1/auth/login`

**Request:**
```json
{
  "username_or_email": "user@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user_id": 1,
  "username": "john_doe",
  "email": "user@example.com",
  "name": "John Doe",
  "is_admin": false
}
```

**Token Storage:**
- Web: `flutter_secure_storage` (encrypted)
- Token expiration: 30 minutes
- Auto-logout on expiration

#### 2. **Google OAuth**

**Endpoint:** `POST /api/v1/auth/google-login`

**Request:**
```json
{
  "id_token": "google_id_token_here"
}
```

**Flow:**
1. Frontend gets Google ID token via `google_sign_in` package
2. Sends to backend
3. Backend verifies token with Google
4. Creates user if first login
5. Links to existing account if email matches
6. Downloads Google profile picture and uploads to S3
7. Returns JWT token

#### 3. **User Registration**

**Endpoint:** `POST /api/v1/auth/register`

**Request:**
```json
{
  "email": "user@example.com",
  "password": "password123",
  "name": "John Doe",
  "phone": "+1234567890",
  "date_of_birth": "1990-01-01",
  "bio": "User bio"
}
```

**Features:**
- Auto-generates unique username via `username_service.py`
- Password hashing with bcrypt
- Returns JWT token immediately

#### 4. **Token Refresh**

**Endpoint:** `POST /api/v1/auth/refresh-token`

**Features:**
- Refresh token rotation (configurable)
- 30-day expiration for refresh tokens
- Automatic token refresh in frontend

### Authorization

**JWT Token Structure:**
```json
{
  "sub": "user_id",
  "exp": 1234567890,
  "iat": 1234567890
}
```

**Token Validation:**
- Middleware: `app/middleware/auth_middleware.py`
- Dependency: `get_current_user` for protected routes
- Expiration checking in frontend and backend

**Protected Routes:**
- All upload endpoints
- Content creation endpoints
- User profile endpoints
- Admin endpoints (requires `is_admin=True`)

---

## Real-Time Features

### LiveKit Integration

**Server:**
- Docker container on EC2
- Ports: 7880-7881 (WebSocket/HTTP), 50100-50200 (UDP RTC)
- Configuration: `livekit-server/livekit.yaml`

**Features:**
1. **Video Meetings:**
   - Create/join meeting rooms
   - Multi-participant video/audio
   - Screen sharing
   - Recording (optional)

2. **Live Streaming:**
   - Broadcaster interface
   - Viewer interface
   - Real-time chat

3. **Voice Agent:**
   - AI voice assistant
- OpenAI GPT-4o-mini for responses
   - Deepgram Nova-3 for STT
   - Deepgram Aura-2 for TTS
   - LiveKit agent framework

**Token Generation:**
- Backend generates LiveKit access tokens
- Tokens include room permissions
- Frontend uses tokens to connect

### WebSocket (Socket.io)

**Server:** FastAPI with Socket.io integration  
**Client:** Flutter `socket_io_client` package

**Events:**
- Notifications
- Real-time updates
- Community post updates

---

## Deployment Configuration

### Backend (EC2)

**SSH Access:**
```bash
ssh -i christnew.pem ubuntu@52.56.78.203
```

**Docker Containers:**
```bash
# Backend API
docker run -d --name cnt-backend \
  -p 8000:8000 \
  -v $(pwd)/.env:/app/.env \
  cnt-web-deployment_backend:latest

# LiveKit Server
docker run -d --name cnt-livekit-server \
  -p 7880-7881:7880-7881 \
  -p 50100-50200:50100-50200/udp \
  livekit/livekit-server:latest

# Voice Agent
docker run -d --name cnt-voice-agent \
  -v $(pwd)/.env:/app/.env \
  cnt-web-deployment_voice-agent
```

### Web Frontend (AWS Amplify)

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
        - flutter build web --release --no-source-maps \
          --dart-define=API_BASE_URL=$API_BASE_URL \
          --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
          --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
          --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
          --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
          --dart-define=ENVIRONMENT=production
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

---

## Environment Configuration

### Backend Environment Variables

**Required:**
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY` - JWT signing key
- `S3_BUCKET_NAME` - S3 bucket name
- `CLOUDFRONT_URL` - CloudFront distribution URL
- `AWS_ACCESS_KEY_ID` - AWS access key
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region (eu-west-2)
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `LIVEKIT_API_KEY` - LiveKit API key
- `LIVEKIT_API_SECRET` - LiveKit API secret
- `OPENAI_API_KEY` - OpenAI API key
- `DEEPGRAM_API_KEY` - Deepgram API key
- `ENVIRONMENT` - "production" or "development"

**Optional:**
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `GOOGLE_CLIENT_SECRET` - Google OAuth secret
- `STRIPE_SECRET_KEY` - Stripe secret key
- `PAYPAL_CLIENT_ID` - PayPal client ID
- `CORS_ORIGINS` - Comma-separated allowed origins
- `DISABLE_VOICE_AGENT_AUTO_START` - Disable voice agent auto-start
- `REFRESH_TOKEN_EXPIRE_DAYS` - Refresh token expiration (default: 30)
- `REFRESH_TOKEN_ROTATION` - Enable token rotation (default: true)

### Frontend Environment Variables (Build-time)

**Amplify Environment Variables:**
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - CloudFront URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - Socket.io WebSocket URL
- `ENVIRONMENT` - "production"
- `GOOGLE_CLIENT_ID` - Google OAuth client ID

**Local Development:**
- Set via `--dart-define` flags when running `flutter run -d chrome`
- Or use `AppConfig` class with default values

---

## Key Workflows & Data Flows

### 1. User Registration & Login

```
1. User visits web app
2. Clicks "Register"
3. Enters email, password, name
4. Frontend calls POST /api/v1/auth/register
5. Backend:
   - Validates input
   - Hashes password
   - Generates unique username
   - Creates user record
   - Returns JWT token
6. Frontend stores token in secure storage
7. User is logged in
```

### 2. Content Creation (Audio Podcast)

```
1. User clicks "Create" → "Audio Podcast"
2. User selects file or records audio
3. Frontend uploads to POST /api/v1/upload/audio
4. Backend:
   - Validates file
   - Saves to S3: audio/{uuid}.{ext}
   - Gets duration via FFprobe
   - Returns CloudFront URL
5. User adds title, description, category
6. Frontend calls POST /api/v1/podcasts
7. Backend:
   - Creates podcast record (status: "pending")
   - Auto-creates artist profile if needed
8. Admin approves (if user is not admin)
9. Podcast becomes visible to all users
```

### 3. Community Post Creation

```
1. User clicks "Create Post"
2. User selects "Image Post" or "Text Post"
3. If image:
   - User selects image
   - Frontend uploads to POST /api/v1/upload/image
   - Backend saves to S3: images/{uuid}.{ext}
4. If text:
   - User enters text
   - Frontend calls POST /api/v1/community/posts
   - Backend generates quote image
   - Saves to S3: images/quotes/quote_{post_id}_{hash}.jpg
5. Frontend creates post via POST /api/v1/community/posts
6. Backend:
   - Creates post record (is_approved: 0)
   - Returns post data
7. Admin approves
8. Post becomes visible in feed
```

### 4. Video Editing Workflow

```
1. User uploads video
2. User clicks "Edit"
3. Frontend loads video editor
4. User applies edits (trim, overlays, etc.)
5. For each edit:
   - Frontend calls editing endpoint (e.g., POST /api/v1/video-editing/trim)
   - Backend:
     - Downloads from S3 (if production)
     - Processes with FFmpeg
     - Uploads processed file to S3
     - Returns new CloudFront URL
   - Frontend updates preview
6. User clicks "Save"
7. Frontend updates podcast record with new video URL
```

---

## Code Structure & Organization

### Backend Code Organization

**Separation of Concerns:**
- **Models**: Database schema (SQLAlchemy)
- **Schemas**: Request/response validation (Pydantic)
- **Routes**: API endpoints (FastAPI)
- **Services**: Business logic
- **Middleware**: Cross-cutting concerns (auth, CORS)

**Async/Await Pattern:**
- All database operations are async
- All route handlers are async
- Uses `AsyncSession` from SQLAlchemy

**Error Handling:**
- HTTPException for API errors
- Try/except blocks in services
- Proper error messages to frontend

### Frontend Code Organization

**Separation of Concerns:**
- **Screens**: UI components
- **Services**: API and external service integration
- **Providers**: State management
- **Models**: Data models
- **Widgets**: Reusable UI components
- **Utils**: Utility functions

**State Management:**
- Provider pattern for reactive state
- Centralized state in providers
- UI rebuilds on state changes

**Navigation:**
- GoRouter for declarative routing
- Route guards for authentication
- Deep linking support

---

## Summary

This document provides a complete understanding of the CNT Media Platform application, including:

✅ **Complete architecture** - Backend, frontend, database, AWS infrastructure  
✅ **Database schema** - All 27 tables with relationships  
✅ **API endpoints** - Complete reference of all endpoints  
✅ **File upload flow** - S3 integration and CloudFront CDN  
✅ **Authentication** - JWT, Google OAuth, OTP registration, token refresh  
✅ **Real-time features** - LiveKit integration, WebSocket  
✅ **Deployment** - EC2 backend, Amplify frontend, Docker containers  
✅ **Code structure** - Organization and patterns  

The application is **production-ready** with all core features implemented and deployed on AWS infrastructure.

---

**Document Created:** Complete application analysis  
**Last Updated:** December 2024  
**Status:** ✅ Complete understanding achieved  
