# CNT Media Platform - Complete Web Application Analysis

**Date:** December 2024  
**Status:** Comprehensive Analysis Complete  
**Focus:** Web Application (Flutter Web on AWS Amplify)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Web Frontend Structure](#web-frontend-structure)
4. [Backend API Structure](#backend-api-structure)
5. [Database Schema](#database-schema)
6. [Media Storage & CDN](#media-storage--cdn)
7. [Authentication & Authorization](#authentication--authorization)
8. [Web Application Features](#web-application-features)
9. [State Management](#state-management)
10. [API Integration](#api-integration)
11. [Deployment Architecture](#deployment-architecture)
12. [Environment Configuration](#environment-configuration)
13. [Key Connections & Data Flow](#key-connections--data-flow)
14. [Feature Implementation Status](#feature-implementation-status)

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application with a production-ready web frontend built with Flutter Web and deployed on AWS Amplify.

### Technology Stack

- **Web Frontend**: Flutter/Dart (Web) - Deployed on AWS Amplify
- **Backend**: FastAPI (Python 3.11+) - Running on AWS EC2 (eu-west-2)
- **Database**: PostgreSQL (AWS RDS production) / SQLite (local development)
- **Media Storage**: AWS S3 (`cnt-web-media`) + CloudFront CDN
- **Real-time**: LiveKit (meetings, streaming, voice agent)
- **AI Services**: OpenAI GPT-4o-mini, Deepgram Nova-3 (STT), Deepgram Aura-2 (TTS)

### Key Metrics

- **Web Screens**: 40+ screens
- **Backend Routes**: 24 route files
- **API Endpoints**: 100+ endpoints
- **Database Tables**: 21 tables
- **State Providers**: 14 providers
- **Services**: 10 services

### Deployment Status

- ✅ **Web Frontend**: Production (AWS Amplify)
- ✅ **Backend API**: Production (AWS EC2)
- ✅ **Database**: Production (AWS RDS PostgreSQL)
- ✅ **Media Storage**: Production (S3 + CloudFront)
- 🚧 **Mobile App**: In development (code complete)

---

## Architecture Overview

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Cloud Infrastructure                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │   AWS         │      │   AWS         │                   │
│  │   Amplify     │──────│   EC2         │                   │
│  │   (Web App)   │ HTTPS│   (Backend)   │                   │
│  └──────────────┘      └───────┬───────┘                   │
│         │                      │                             │
│         │                      │                             │
│         │              ┌────────▼────────┐                   │
│         │              │   AWS RDS      │                   │
│         │              │   PostgreSQL   │                   │
│         │              └────────────────┘                   │
│         │                                                    │
│         │              ┌─────────────────┐                  │
│         └──────────────│   CloudFront   │                  │
│                        │      CDN        │                  │
│                        └────────┬────────┘                  │
│                                 │                            │
│                        ┌────────▼────────┐                 │
│                        │   AWS S3        │                  │
│                        │   cnt-web-media │                  │
│                        └─────────────────┘                  │
│                                                               │
│  ┌──────────────┐      ┌──────────────┐                   │
│  │   LiveKit    │      │   OpenAI      │                   │
│  │   Server     │      │   Deepgram    │                   │
│  └──────────────┘      └──────────────┘                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

### Component Communication Flow

1. **User Request Flow**:
   - User → AWS Amplify (Web App) → AWS EC2 (Backend API) → AWS RDS (Database)
   - Media requests: User → CloudFront CDN → S3 Bucket

2. **File Upload Flow**:
   - User → Web App → Backend API → S3 Bucket → CloudFront URL returned

3. **Real-time Communication**:
   - Web App ↔ WebSocket (Socket.io) ↔ Backend
   - Web App ↔ LiveKit WebSocket ↔ LiveKit Server

---

## Web Frontend Structure

### Directory Structure

```
web/frontend/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── config/
│   │   └── app_config.dart          # Environment configuration
│   ├── constants/
│   │   └── app_constants.dart       # App constants
│   ├── navigation/
│   │   ├── app_router.dart          # Main router setup
│   │   ├── app_routes.dart          # Route definitions
│   │   ├── main_navigation.dart    # Navigation logic
│   │   └── web_navigation.dart     # Web-specific navigation
│   ├── screens/
│   │   ├── web/                     # 40+ web-specific screens
│   │   ├── admin/                   # Admin screens
│   │   ├── community/               # Community screens
│   │   ├── creation/                # Content creation
│   │   ├── editing/                 # Audio/video editors
│   │   ├── live/                    # Live streaming
│   │   ├── meeting/                 # Video meetings
│   │   └── voice/                   # Voice agent
│   ├── providers/                   # 14 state providers
│   ├── services/                    # 10 API services
│   ├── models/                      # Data models
│   ├── widgets/                     # Reusable widgets
│   ├── theme/                       # Theme configuration
│   └── utils/                       # Utility functions
├── assets/
│   └── images/                      # Static images
└── web/
    ├── index.html                   # HTML entry point
    └── manifest.json                # PWA manifest
```

### Web Screens (40 Total)

#### Core Screens
- `home_screen_web.dart` - Main landing with hero carousel, featured content
- `landing_screen_web.dart` - Public landing page
- `about_screen_web.dart` - About page

#### Content Screens
- `podcasts_screen_web.dart` - Audio/video podcast listing
- `movies_screen_web.dart` - Movie catalog
- `movie_detail_screen_web.dart` - Movie details with preview
- `movie_preview_screen_web.dart` - Movie preview player
- `music_screen_web.dart` - Music player
- `video_podcast_detail_screen_web.dart` - Video podcast details
- `audio_player_full_screen_web.dart` - Full-screen audio player
- `bible_stories_screen_web.dart` - Bible stories viewer

#### Community Screens
- `community_screen_web.dart` - Social feed (Instagram-like)
- `prayer_screen_web.dart` - Prayer requests
- `join_prayer_screen_web.dart` - Join prayer session

#### Creation Screens
- `create_screen_web.dart` - Content creation hub
- `video_editor_screen_web.dart` - **Professional video editor**
- `video_recording_screen_web.dart` - Record video
- `video_preview_screen_web.dart` - Preview before publishing

#### Live/Meeting Screens
- `live_screen_web.dart` - Live streaming hub
- `stream_screen_web.dart` - Stream viewer
- `live_stream_options_screen_web.dart` - Stream setup
- `meetings_screen_web.dart` - Meeting list
- `meeting_options_screen_web.dart` - Meeting options
- `meeting_room_screen_web.dart` - LiveKit meeting room

#### User Screens
- `profile_screen_web.dart` - User profile
- `library_screen_web.dart` - User library
- `favorites_screen_web.dart` - User favorites
- `downloads_screen_web.dart` - Offline downloads
- `notifications_screen_web.dart` - Notifications

#### Voice Screens
- `voice_agent_screen_web.dart` - AI voice assistant
- `voice_chat_screen_web.dart` - Voice chat interface

#### Admin Screens
- `admin_dashboard_web.dart` - Admin dashboard
- `admin_login_screen_web.dart` - Admin login

#### Other Screens
- `search_screen_web.dart` - Search functionality
- `support_screen_web.dart` - Support tickets
- `discover_screen_web.dart` - Content discovery
- `not_found_screen_web.dart` - 404 page
- `offline_screen_web.dart` - Offline mode
- `user_login_screen_web.dart` - User login
- `register_screen_web.dart` - User registration

### Key Web Features

#### 1. Video Editor (`video_editor_screen_web.dart`)

**Professional video editing capabilities:**

- **Trim Video**: Set start/end times with visual timeline
- **Audio Management**: Remove, add, or replace audio tracks
- **Text Overlays**: Add customizable text overlays at specific timestamps
  - Position (x, y coordinates)
  - Font family, size, color
  - Background color, alignment
  - Start/end times
- **Video Player**: Full-screen preview with controls
- **State Persistence**: Saves editor state to localStorage
- **Blob URL Handling**: Uploads blob URLs to backend for persistence
- **Draft System**: Auto-saves editing progress

**UI Layout:**
- **Tabs**: Trim, Music, Text
- **Video Preview**: Large responsive preview area
- **Timeline**: Visual timeline with playhead and overlay bars
- **Controls**: Editing controls below preview

#### 2. Audio Editor (`audio_editor_screen.dart`)

**Features:**
- **Trim Audio**: Set start/end times
- **Merge Audio**: Combine multiple files
- **Fade Effects**: Fade in, fade out, or both
- **Audio Player**: Play/pause, seek, volume control
- **State Persistence**: Saves to localStorage

#### 3. Home Screen (`home_screen_web.dart`)

**Features:**
- **Hero Carousel**: Featured movies with parallax effects
- **Content Sections**: Audio podcasts, video podcasts, movies
- **Bible Reader**: Integrated Bible document viewer
- **Meeting Section**: Quick access to meetings
- **Live Stream Section**: Active streams
- **Responsive Design**: Adapts to screen size

#### 4. Community Screen (`community_screen_web.dart`)

**Instagram-like social feed:**
- **Post Types**: Image posts, text posts (auto-converted to quote images)
- **Categories**: Testimony, prayer request, question, announcement, general
- **Interactions**: Like, comment, share
- **Infinite Scroll**: Loads more posts as user scrolls
- **Real-time Updates**: WebSocket notifications

---

## Backend API Structure

### Backend Directory Structure

```
backend/
├── app/
│   ├── main.py                      # FastAPI app entry point
│   ├── config.py                    # Configuration settings
│   ├── database/
│   │   └── connection.py            # Database connection
│   ├── models/                      # 21 SQLAlchemy models
│   ├── routes/                      # 24 route files
│   ├── services/                    # 15 service files
│   ├── schemas/                     # Pydantic schemas
│   ├── middleware/
│   │   └── auth_middleware.py       # JWT authentication
│   ├── websocket/
│   │   └── socket_io_handler.py    # WebSocket handler
│   └── agents/
│       └── voice_agent.py           # LiveKit voice agent
├── media/                           # Local media storage (dev only)
├── migrations/                      # Alembic migrations
└── requirements.txt                  # Python dependencies
```

### Backend Routes (24 Files)

1. **auth.py** - Authentication (login, register, Google OAuth, OTP)
2. **users.py** - User management
3. **artists.py** - Artist profiles and follow system
4. **podcasts.py** - Audio/video podcasts
5. **movies.py** - Movie content
6. **music.py** - Music tracks
7. **community.py** - Community posts, likes, comments
8. **playlists.py** - User playlists
9. **upload.py** - File upload endpoints
10. **audio_editing.py** - Audio editing operations
11. **video_editing.py** - Video editing operations
12. **live_stream.py** - Live streaming
13. **livekit_voice.py** - Voice agent endpoints
14. **voice_chat.py** - Voice chat
15. **documents.py** - PDF documents (Bible)
16. **donations.py** - Donation transactions
17. **bank_details.py** - Creator payment info
18. **support.py** - Support tickets
19. **categories.py** - Content categories
20. **bible_stories.py** - Bible stories
21. **notifications.py** - User notifications
22. **admin.py** - Admin dashboard and moderation
23. **admin_google_drive.py** - Google Drive bulk upload
24. **events.py** - Events management
25. **device_tokens.py** - Push notification tokens
26. **content_drafts.py** - Content drafts

### Backend Services (15 Files)

1. **auth_service.py** - Authentication logic
2. **artist_service.py** - Artist profile management
3. **media_service.py** - Media file operations (S3/local)
4. **video_editing_service.py** - FFmpeg video processing
5. **audio_editing_service.py** - FFmpeg audio processing
6. **thumbnail_service.py** - Thumbnail generation
7. **quote_image_service.py** - Quote image generation
8. **livekit_service.py** - LiveKit integration
9. **payment_service.py** - Stripe/PayPal integration
10. **google_drive_service.py** - Google Drive integration
11. **ai_service.py** - OpenAI integration
12. **username_service.py** - Username generation
13. **email_service.py** - AWS SES email
14. **notification_service.py** - Push notifications
15. **firebase_push_service.py** - Firebase Cloud Messaging

### Key API Endpoints

#### Authentication (`/api/v1/auth`)
- `POST /login` - Email/password login
- `POST /register` - User registration
- `POST /google-login` - Google OAuth
- `POST /send-otp` - Send OTP verification
- `POST /verify-otp` - Verify OTP code
- `POST /register-with-otp` - Register with verified email
- `POST /check-username` - Username availability

#### Content (`/api/v1`)
- `GET/POST /podcasts` - List/create podcasts
- `GET/POST /movies` - List/create movies
- `GET/POST /music` - List/create music tracks
- `GET /bible-stories` - List Bible stories
- `GET /documents` - List documents

#### Community (`/api/v1/community`)
- `GET/POST /posts` - List/create posts
- `POST /posts/{id}/like` - Like/unlike post
- `POST /posts/{id}/comments` - Add comment
- `GET /posts/{id}/comments` - Get comments

#### Upload (`/api/v1/upload`)
- `POST /audio` - Upload audio file
- `POST /video` - Upload video file
- `POST /image` - Upload image
- `POST /profile-image` - Upload avatar
- `POST /thumbnail` - Upload thumbnail
- `POST /temporary-audio` - Upload temp audio (editing)
- `POST /document` - Upload PDF (admin only)
- `GET /media/duration` - Get media duration
- `GET /thumbnail/defaults` - Get default thumbnails

#### Editing (`/api/v1`)
- `POST /audio-editing/trim` - Trim audio
- `POST /audio-editing/merge` - Merge audio files
- `POST /audio-editing/fade-in-out` - Fade effects
- `POST /video-editing/trim` - Trim video
- `POST /video-editing/remove-audio` - Remove audio track
- `POST /video-editing/add-audio` - Add audio track
- `POST /video-editing/replace-audio` - Replace audio track
- `POST /video-editing/add-text-overlays` - Add text overlays
- `POST /video-editing/apply-filters` - Apply filters

#### Live/Voice (`/api/v1`)
- `GET/POST /live/streams` - List/create streams
- `POST /live/streams/{id}/join` - Join stream
- `POST /livekit/voice/token` - Get voice agent token
- `POST /livekit/voice/room` - Create voice room
- `GET /livekit/voice/rooms` - List voice rooms

#### Admin (`/api/v1/admin`)
- `GET /dashboard` - Admin stats
- `GET /pending` - Pending content
- `POST /approve/{type}/{id}` - Approve content
- `POST /reject/{type}/{id}` - Reject content

---

## Database Schema

### Core Tables (21 Total)

#### 1. **users** - User Accounts
```sql
- id (PK, Integer)
- username (String, unique, nullable) - Auto-generated
- name (String, required)
- email (String, unique, required)
- avatar (String, nullable) - Profile image URL
- password_hash (String, nullable) - For email/password auth
- is_admin (Boolean, default: False)
- phone (String, nullable)
- date_of_birth (DateTime, nullable)
- bio (Text, nullable)
- google_id (String, unique, nullable) - Google OAuth
- auth_provider (String, default: 'email') - 'email', 'google', 'both'
- created_at, updated_at (DateTime)
```

**Relationships:**
- One-to-many: `podcasts`, `support_messages`, `notifications`, `community_posts`
- One-to-one: `artist`, `bank_details`, `payment_account`

#### 2. **artists** - Creator Profiles
```sql
- id (PK, Integer)
- user_id (FK → users.id, unique, required)
- artist_name (String, nullable) - Defaults to user.name
- cover_image (String, nullable) - Banner image
- bio (Text, nullable)
- social_links (JSON, nullable) - Social media URLs
- followers_count (Integer, default: 0)
- total_plays (Integer, default: 0)
- is_verified (Boolean, default: False)
- created_at, updated_at (DateTime)
```

**Auto-created** when user uploads content

#### 3. **podcasts** - Audio/Video Podcasts
```sql
- id (PK, Integer)
- title (String, required)
- description (Text, nullable)
- audio_url (String, nullable) - S3 path: audio/{uuid}.{ext}
- video_url (String, nullable) - S3 path: video/{uuid}.{ext}
- cover_image (String, nullable) - Thumbnail URL
- creator_id (FK → users.id, nullable)
- category_id (FK → categories.id, nullable)
- duration (Integer, nullable) - Seconds
- status (String, default: "pending") - pending, approved, rejected
- plays_count (Integer, default: 0)
- created_at (DateTime)
```

**Approval Workflow**: Non-admin posts require approval

#### 4. **movies** - Full-Length Movies
```sql
- id (PK, Integer)
- title, description, video_url, cover_image (String)
- preview_url (String, nullable) - Pre-generated preview clip
- preview_start_time, preview_end_time (Integer, nullable)
- director, cast (String/Text, nullable)
- release_date (DateTime, nullable)
- rating (Float, nullable) - User rating 0-10
- category_id, creator_id (FK)
- duration (Integer, nullable) - Seconds
- status (String, default: "pending")
- plays_count (Integer, default: 0)
- is_featured (Boolean, default: False) - Hero carousel
- created_at (DateTime)
```

#### 5. **community_posts** - Social Media Posts
```sql
- id (PK, Integer)
- user_id (FK → users.id, required)
- title (String, required)
- content (Text, required)
- image_url (String, nullable) - Photo or generated quote image
- category (String, required) - testimony, prayer_request, question, announcement, general
- post_type (String, default: 'image') - 'image' or 'text'
- is_approved (Integer, default: 0) - 0=False, 1=True
- likes_count, comments_count (Integer, default: 0)
- created_at (DateTime)
```

**Text Posts**: Auto-converted to styled quote images

#### 6. **comments** - Post Comments
```sql
- id (PK, Integer)
- post_id (FK → community_posts.id)
- user_id (FK → users.id)
- content (Text, required)
- created_at (DateTime)
```

#### 7. **likes** - Post Likes
```sql
- id (PK, Integer)
- post_id (FK → community_posts.id)
- user_id (FK → users.id)
- created_at (DateTime)
- UNIQUE constraint on (post_id, user_id)
```

#### 8. **playlists** - User Playlists
```sql
- id (PK, Integer)
- user_id (FK → users.id, required)
- name (String, required)
- description (Text, nullable)
- cover_image (String, nullable)
- created_at (DateTime)
```

#### 9. **playlist_items** - Playlist Content
```sql
- id (PK, Integer)
- playlist_id (FK → playlists.id)
- content_type (String) - "podcast", "music", etc.
- content_id (Integer) - ID of content item
- position (Integer) - Order in playlist
```

#### 10. **music_tracks** - Music Content
```sql
- id (PK, Integer)
- title, artist, album, genre (String)
- audio_url (String, required) - S3 path
- cover_image (String, nullable)
- duration (Integer, nullable)
- lyrics (Text, nullable)
- is_featured, is_published (Boolean)
- plays_count (Integer, default: 0)
- created_at (DateTime)
```

#### 11. **bank_details** - Creator Payment Info
```sql
- id (PK, Integer)
- user_id (FK → users.id, unique, required)
- account_number (String, required) - Should be encrypted
- ifsc_code, swift_code, bank_name, account_holder_name, branch_name (String)
- is_verified (Boolean, default: False)
- created_at, updated_at (DateTime)
```

#### 12. **payment_accounts** - Payment Gateway Accounts
```sql
- id (PK, Integer)
- user_id (FK → users.id, unique)
- provider (String) - 'stripe', 'paypal'
- account_id (String)
- is_active (Boolean)
```

#### 13. **donations** - Donation Transactions
```sql
- id (PK, Integer)
- user_id, recipient_id (FK → users.id)
- amount (Float)
- currency (String)
- status (String) - pending, completed, failed
- payment_method (String)
- created_at (DateTime)
```

#### 14. **live_streams** - Meeting/Stream Records
```sql
- id (PK, Integer)
- user_id (FK → users.id)
- title, description (String)
- status (String)
- room_name (String) - LiveKit room name
- started_at, ended_at (DateTime)
```

#### 15. **document_assets** - PDF Documents (Bible, etc.)
```sql
- id (PK, Integer)
- title (String)
- file_url (String) - S3 path: documents/{filename}.pdf
- file_type (String)
- file_size (Integer)
```

**Admin-only uploads**

#### 16. **support_messages** - Support Tickets
```sql
- id (PK, Integer)
- user_id (FK → users.id)
- subject, message (String/Text)
- status (String)
- admin_response (Text, nullable)
- created_at (DateTime)
```

#### 17. **bible_stories** - Bible Story Content
```sql
- id (PK, Integer)
- title, scripture_reference, content (String/Text)
- audio_url, cover_image (String, nullable)
- created_at (DateTime)
```

#### 18. **notifications** - User Notifications
```sql
- id (PK, Integer)
- user_id (FK → users.id)
- type (String) - enum type
- title, message (String)
- data (JSON, nullable)
- is_read (Boolean, default: False)
- created_at (DateTime)
```

#### 19. **categories** - Content Categories
```sql
- id (PK, Integer)
- name (String)
- type (String) - podcast, music, community, etc.
```

#### 20. **email_verification** - Email Verification Tokens
```sql
- id (PK, Integer)
- email (String)
- otp_code (String)
- expires_at (DateTime)
- verified (Boolean, default: False)
```

#### 21. **artist_followers** - Follow Relationships
```sql
- id (PK, Integer)
- artist_id (FK → artists.id)
- user_id (FK → users.id)
- created_at (DateTime)
- UNIQUE constraint on (artist_id, user_id)
```

---

## Media Storage & CDN

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
- Example: `http://localhost:8002/media/audio/file.mp3`

**Production Mode**:
- Files served from CloudFront
- Direct S3 path mapping (no `/media/` prefix)
- Example: `https://d126sja5o8ue54.cloudfront.net/audio/file.mp3`

**Frontend Handling** (`api_service.dart`):
- Detects full URLs (http://, https://) and returns as-is
- Strips `media/` prefix in production
- Adds CloudFront base URL for relative paths

---

## Authentication & Authorization

### Authentication Methods

#### 1. **Email/Password Login**
- **Endpoint**: `POST /api/v1/auth/login`
- **Input**: `username_or_email` + `password`
- **Returns**: JWT access token (30-minute expiration)
- **Storage**: `localStorage` (web)
- **Features**:
  - Accepts both username and email for login
  - Generic error messages for security

#### 2. **Google OAuth**
- **Endpoint**: `POST /api/v1/auth/google-login`
- **Supports**: Both `id_token` and `access_token`
- **Auto-creates** user account if first login
- **Links** to existing account if email matches
- **Avatar Handling**: Downloads Google profile picture and uploads to S3
- **Returns**: JWT token and user data

#### 3. **User Registration**
- **Endpoint**: `POST /api/v1/auth/register`
- **Required**: `email`, `password`, `name`
- **Optional**: `phone`, `date_of_birth`, `bio`
- **Auto-generates** unique `username` via `username_service.py`
- **Returns**: JWT token and user data

#### 4. **OTP-Based Registration**
- **Endpoints**:
  - `POST /api/v1/auth/send-otp` - Send verification code
  - `POST /api/v1/auth/verify-otp` - Verify code
  - `POST /api/v1/auth/register-with-otp` - Register with verified email

### Token Management

- **Expiration**: 30 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Refresh**: Not implemented (user re-authenticates)
- **Middleware**: `auth_middleware.py` validates tokens on protected routes
- **Storage**: `localStorage` (web)
- **Auto-logout**: Token expiration check every 5 minutes

### Authorization

- **Protected Routes**: Require JWT token in `Authorization: Bearer <token>` header
- **Admin Routes**: Require `is_admin=True` in user record
- **Content Approval**: Non-admin posts require admin approval

---

## Web Application Features

### 1. Content Consumption

#### Podcasts
- **Audio Podcasts**: Play audio with full-screen player
- **Video Podcasts**: Play video with full-screen player
- **Features**: Play/pause, seek, volume, playlist queue
- **Play Count**: Tracks plays automatically

#### Movies
- **Movie Catalog**: Browse featured and all movies
- **Movie Details**: View details, cast, director, rating
- **Preview Clips**: Optional pre-generated preview clips
- **Full Playback**: Full-length movie playback

#### Music
- **Music Player**: Play music tracks
- **Playlist Support**: Add to playlists
- **Lyrics**: Display lyrics if available

#### Bible Reader
- **PDF Viewer**: View Bible PDF documents
- **Bible Stories**: Audio/video Bible stories
- **Scripture References**: Link to specific verses

### 2. Content Creation

#### Audio Podcast Creation
1. **Record or Upload**: Record via browser or upload file
2. **Preview**: Preview audio before publishing
3. **Edit**: Trim, merge, fade effects
4. **Upload**: Upload to backend → S3
5. **Publish**: Create podcast record (status: "pending")

#### Video Podcast Creation
1. **Record or Upload**: Record via camera or upload file
2. **Preview**: Preview video before publishing
3. **Edit**: Trim, audio management, text overlays
4. **Thumbnail**: Auto-generated or custom thumbnail
5. **Upload**: Upload to backend → S3
6. **Publish**: Create podcast record (status: "pending")

#### Video Editor Features
- **Trim**: Set start/end times with visual timeline
- **Audio Management**: Remove, add, replace audio tracks
- **Text Overlays**: Add customizable text overlays
  - Position (x, y)
  - Font, size, color
  - Background, alignment
  - Start/end times
- **Filters**: Brightness, contrast, saturation (web only)
- **State Persistence**: Auto-saves to localStorage
- **Draft System**: Auto-saves editing progress

#### Audio Editor Features
- **Trim**: Set start/end times
- **Merge**: Combine multiple files
- **Fade Effects**: Fade in, fade out, or both
- **State Persistence**: Auto-saves to localStorage

### 3. Community Features

#### Social Feed
- **Post Types**: Image posts, text posts (auto-converted to quote images)
- **Categories**: Testimony, prayer request, question, announcement, general
- **Interactions**: Like, comment, share
- **Infinite Scroll**: Loads more posts as user scrolls
- **Real-time Updates**: WebSocket notifications

#### Quote Image Generation
- **Automatic**: Text posts automatically converted to styled quote images
- **Templates**: Predefined styles with backgrounds, fonts, colors
- **Storage**: Saved to S3: `images/quotes/quote_{post_id}_{hash}.jpg`

### 4. Real-Time Features

#### Live Streaming
- **Broadcaster**: Host live streams
- **Viewer**: Watch live streams
- **LiveKit Integration**: Uses LiveKit for streaming

#### Video Meetings
- **Instant Meetings**: Create instant meetings
- **Scheduled Meetings**: Schedule future meetings
- **Meeting Room**: Full LiveKit meeting room interface
- **Features**: Video, audio, screen share, chat

#### Voice Agent
- **AI Assistant**: Voice-based AI assistant
- **OpenAI Integration**: GPT-4o-mini for responses
- **Deepgram Integration**: STT (Nova-3) and TTS (Aura-2)
- **LiveKit Integration**: Real-time voice communication

### 5. Admin Features

#### Admin Dashboard
- **Statistics**: User count, content count, pending approvals
- **Content Moderation**: Approve/reject posts, podcasts, movies
- **User Management**: View and manage users
- **Support Tickets**: Handle support messages

#### Content Approval Workflow
1. User creates content (status: "pending")
2. Admin reviews in dashboard
3. Admin approves or rejects
4. Approved content visible to all users

### 6. User Features

#### Profile
- **Edit Profile**: Update name, bio, avatar
- **Artist Profile**: Auto-created when user uploads content
- **Follow System**: Follow/unfollow artists

#### Library
- **Playlists**: Create and manage playlists
- **Favorites**: Save favorite content
- **Downloads**: Offline downloads (web: limited support)

#### Notifications
- **Real-time**: WebSocket-based notifications
- **Types**: Content approval, likes, comments, follows
- **Mark as Read**: Mark notifications as read

---

## State Management

### Providers (14 Total)

1. **AuthProvider** - Authentication state
   - User data
   - Authentication status
   - Token management
   - Auto-logout on expiration

2. **AppState** - Global app state
   - App initialization
   - Theme mode
   - Navigation state

3. **MusicProvider** - Music playback
   - Current track
   - Playlist queue
   - Play/pause state

4. **AudioPlayerState** - Audio player state
   - Current audio
   - Playback position
   - Volume

5. **CommunityProvider** - Community posts
   - Post list
   - Like/comment state
   - Real-time updates

6. **UserProvider** - User data
   - Current user profile
   - User settings

7. **PlaylistProvider** - Playlists
   - User playlists
   - Playlist items

8. **FavoritesProvider** - Favorites
   - Favorite content
   - Add/remove favorites

9. **SupportProvider** - Support tickets
   - Support messages
   - Ticket status

10. **DocumentsProvider** - Documents
    - Bible documents
    - Document assets

11. **NotificationProvider** - Notifications
    - Notification list
    - Unread count

12. **ArtistProvider** - Artist profiles
    - Artist data
    - Follow status

13. **SearchProvider** - Search functionality
    - Search results
    - Search history

14. **EventProvider** - Events
    - Event list
    - Event attendance

### Provider Pattern

- **ChangeNotifier**: All providers extend `ChangeNotifier`
- **Consumer**: Widgets consume providers via `Consumer<T>`
- **MultiProvider**: All providers registered in `AppRouter`
- **State Persistence**: Some providers persist state to localStorage

---

## API Integration

### API Service (`api_service.dart`)

**Key Features:**
- **Base URL**: Configured via `--dart-define=API_BASE_URL`
- **Authentication**: Automatic token injection
- **Error Handling**: 401 handling with auto-logout
- **Media URL Resolution**: Handles CloudFront URLs
- **Timeout**: 10-second timeout for requests

**Media URL Handling:**
```dart
String getMediaUrl(String? path) {
  // 1. Return full URLs directly
  if (path.startsWith('http://') || path.startsWith('https://')) {
    return path;
  }
  
  // 2. Strip legacy 'media/' prefix in production
  if (cleanPath.startsWith('media/')) {
    if (isDev) {
      return '$mediaBaseUrl/$cleanPath';
    } else {
      cleanPath = cleanPath.substring(6); // Remove 'media/'
      return '$mediaBaseUrl/$cleanPath';
    }
  }
  
  // 3. CloudFront URL maps directly to S3 paths
  return '$mediaBaseUrl/$cleanPath';
}
```

### Service Files (10 Total)

1. **api_service.dart** - Main API client
2. **auth_service.dart** - Authentication API calls
3. **google_auth_service.dart** - Google OAuth
4. **audio_editing_service.dart** - Audio editing API
5. **video_editing_service.dart** - Video editing API
6. **livekit_meeting_service.dart** - LiveKit meetings
7. **livekit_voice_service.dart** - Voice agent
8. **websocket_service.dart** - WebSocket connection
9. **donation_service.dart** - Payment processing
10. **download_service.dart** - Offline downloads

### WebSocket Service

**Features:**
- **Connection**: Auto-connects on app start
- **Events**: Real-time notifications
- **Reconnection**: Auto-reconnects on disconnect
- **Error Handling**: Graceful error handling

---

## Deployment Architecture

### Web Frontend (AWS Amplify)

**Configuration:**
- **App Domain**: `d1poes9tyirmht.amplifyapp.com`
- **Branch**: `main`
- **Build Spec**: `amplify.yml`
- **Framework**: Flutter Web

**Build Process:**
1. Clone Flutter SDK
2. Install dependencies (`flutter pub get`)
3. Build web (`flutter build web --release`)
4. Deploy to Amplify

**Environment Variables** (set in Amplify console):
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - CloudFront URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - WebSocket URL
- `ENVIRONMENT` - `production`
- `GOOGLE_CLIENT_ID` - Google OAuth client ID

### Backend (AWS EC2)

**Configuration:**
- **Instance**: EC2 (eu-west-2)
- **Public IP**: 52.56.78.203
- **Domain**: `api.christnewtabernacle.com`
- **Database**: RDS PostgreSQL
- **SSH Key**: `christnew.pem`

**Deployment:**
```bash
ssh -i christnew.pem ubuntu@52.56.78.203
cd ~/cnt-web-deployment/backend
git pull
docker restart cnt-backend
```

**Docker Containers:**
1. **cnt-backend** - FastAPI backend (port 8000)
2. **cnt-livekit-server** - LiveKit server (ports 7880-7881, 50100-50200/udp)
3. **cnt-voice-agent** - Voice agent (port 8000)

### Media Storage (AWS S3 + CloudFront)

**S3 Bucket:**
- **Name**: `cnt-web-media`
- **Region**: `eu-west-2`
- **Access**: CloudFront OAC + EC2 IP whitelist

**CloudFront:**
- **URL**: `https://d126sja5o8ue54.cloudfront.net`
- **Distribution ID**: `E3ER061DLFYFK8`
- **OAC ID**: `E1LSA9PF0Z69X7`

---

## Environment Configuration

### Web Frontend (Build-time `--dart-define`)

**Amplify Build Command**:
```bash
flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
  --dart-define=ENVIRONMENT=production \
  --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
```

**Configuration File** (`app_config.dart`):
- Reads from `String.fromEnvironment()`
- Defaults to empty string if not set
- Used throughout app for API calls

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

---

## Key Connections & Data Flow

### 1. User Registration Flow

```
User → Web App → POST /api/v1/auth/register
                ↓
         Backend validates
                ↓
         Generate username
                ↓
         Hash password
                ↓
         Create user record
                ↓
         Return JWT token
                ↓
         Web App stores token
                ↓
         User authenticated
```

### 2. Content Upload Flow

```
User → Web App → Select file
                ↓
         Upload to backend
                ↓
         POST /api/v1/upload/video
                ↓
         Backend validates file
                ↓
         Upload to S3
                ↓
         Generate thumbnail (if video)
                ↓
         Return CloudFront URL
                ↓
         Web App creates podcast record
                ↓
         POST /api/v1/podcasts
                ↓
         Status: "pending"
                ↓
         Admin approves
                ↓
         Content visible to all
```

### 3. Video Editing Flow

```
User → Web App → Load video
                ↓
         Initialize editor
                ↓
         User applies edits (trim, overlays, etc.)
                ↓
         POST /api/v1/video-editing/trim
                ↓
         Backend processes with FFmpeg
                ↓
         Upload edited video to S3
                ↓
         Return new CloudFront URL
                ↓
         Web App updates preview
                ↓
         User can apply more edits
                ↓
         Final edited video ready
                ↓
         User publishes
```

### 4. Real-time Notification Flow

```
Backend Event → Notification Service
                    ↓
         Create notification record
                    ↓
         Emit WebSocket event
                    ↓
         Web App receives event
                    ↓
         NotificationProvider updates
                    ↓
         UI shows notification
```

### 5. Media URL Resolution Flow

```
Backend returns path: "audio/file.mp3"
                    ↓
         Web App calls getMediaUrl()
                    ↓
         Check if full URL → No
                    ↓
         Check if starts with "media/" → Yes (in dev)
                    ↓
         Production: Strip "media/" prefix
                    ↓
         Add CloudFront base URL
                    ↓
         Return: "https://d126sja5o8ue54.cloudfront.net/audio/file.mp3"
                    ↓
         Image/Video widget loads URL
```

---

## Feature Implementation Status

### ✅ Fully Implemented

1. **Authentication** - Email/password, Google OAuth, OTP
2. **Content Consumption** - Podcasts, movies, music, Bible
3. **Content Creation** - Audio/video podcast creation
4. **Video Editing** - Trim, audio, overlays, filters
5. **Audio Editing** - Trim, merge, fade
6. **Community Posts** - Image/text posts with quote generation
7. **Social Features** - Likes, comments, follows
8. **Live Streaming** - Broadcaster and viewer
9. **Video Meetings** - LiveKit integration
10. **Voice Agent** - AI voice assistant
11. **Admin Dashboard** - Content moderation
12. **Playlists** - User playlists
13. **Notifications** - Real-time notifications
14. **Search** - Content search

### ⚠️ Partially Implemented

1. **Offline Downloads** - Limited support on web
2. **Payment Integration** - Configured but optional
3. **Push Notifications** - WebSocket only (no browser push)

### 🚧 In Progress

1. **Mobile App** - Code complete, pending store submission

---

## Summary

The CNT Media Platform web application is a **production-ready** Flutter Web application with:

- ✅ **40+ screens** covering all features
- ✅ **14 state providers** for comprehensive state management
- ✅ **10 API services** for backend integration
- ✅ **Professional video editor** with advanced features
- ✅ **Real-time features** via WebSocket and LiveKit
- ✅ **Cloud-native architecture** with S3 and CloudFront
- ✅ **Complete authentication** system
- ✅ **Admin moderation** system
- ✅ **Social features** with community posts

The application is fully deployed and operational on AWS infrastructure, with all core features implemented and tested.

---

**Document Created**: December 2024  
**Status**: Complete Web Application Analysis  
**Next Steps**: Ready for feature fixes and enhancements













