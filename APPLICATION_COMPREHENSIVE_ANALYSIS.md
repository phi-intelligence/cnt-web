# CNT Media Platform - Comprehensive Application Analysis

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a full-stack Christian media application combining:
- **Spotify-like** media streaming (audio/video podcasts, music, movies)
- **Instagram/Facebook-like** social features (community posts, comments, likes, profiles)
- **Real-time communication** (LiveKit meetings, live streaming, voice agent)
- **Content creation tools** (audio/video recording, editing, publishing)

**Deployment Architecture:**
- **Frontend (Web)**: Flutter Web app hosted on AWS Amplify
- **Backend**: FastAPI (Python 3.11) hosted on AWS EC2 (eu-west-2)
- **Database**: PostgreSQL (RDS in production), SQLite (local development)
- **Media Storage**: AWS S3 + CloudFront CDN
- **Real-time**: LiveKit server (meetings, streaming, voice agent)
- **Additional Services**: Redis (ElastiCache), Firebase (push notifications)

---

## 1. Backend Architecture (`backend/app`)

### 1.1 Technology Stack

**Core Framework:**
- **FastAPI** 0.104.1 - Modern async Python web framework
- **SQLAlchemy** 2.0.23 - Async ORM with declarative models
- **Alembic** 1.12.1 - Database migrations
- **Uvicorn** - ASGI server

**Database Drivers:**
- **asyncpg** 0.29.0 - PostgreSQL async driver
- **aiosqlite** 0.21.0 - SQLite async driver (development)
- **psycopg2-binary** 2.9.9 - Sync PostgreSQL (for migrations)

**Real-time Communication:**
- **Socket.IO** (python-socketio) - WebSocket signaling for real-time events
- **LiveKit** - WebRTC infrastructure for video/audio meetings and streaming
- **LiveKit Agents** - AI voice agent integration

**External Services:**
- **boto3** - AWS S3 media storage
- **OpenAI** - GPT-4o-mini for AI features
- **Deepgram** - Speech-to-text and text-to-speech
- **Stripe** - Payment processing
- **Firebase Admin SDK** - Push notifications
- **Google APIs** - OAuth authentication and Drive integration

### 1.2 Application Structure

```
backend/app/
├── main.py                 # FastAPI app entry point, Socket.IO setup
├── config.py               # Environment configuration (Settings class)
├── database/
│   ├── connection.py       # Database engine, session factory (lazy initialization)
│   └── __init__.py
├── models/                 # SQLAlchemy database models (24 models)
│   ├── user.py
│   ├── podcast.py
│   ├── community.py
│   ├── artist.py
│   ├── event.py
│   ├── live_stream.py
│   ├── movie.py
│   ├── music.py
│   ├── playlist.py
│   ├── notification.py
│   └── ... (14 more models)
├── routes/                 # API endpoint routers (27 route modules)
│   ├── auth.py
│   ├── podcasts.py
│   ├── community.py
│   ├── upload.py
│   ├── livekit_voice.py
│   ├── live_stream.py
│   ├── admin.py
│   └── ... (20 more routes)
├── services/               # Business logic services (15 service classes)
│   ├── media_service.py
│   ├── livekit_service.py
│   ├── auth_service.py
│   ├── notification_service.py
│   └── ... (11 more services)
├── schemas/                # Pydantic request/response schemas
├── middleware/             # Custom middleware (auth, CORS)
└── websocket/              # Socket.IO event handlers
```

### 1.3 Main Application (`main.py`)

**Key Features:**
- FastAPI app with CORS middleware (configurable origins)
- ProxyHeadersMiddleware for AWS ALB compatibility
- Global exception handler with CORS headers
- Static file serving (development only; production uses S3/CloudFront)
- Socket.IO integration with Redis adapter (multi-instance support)
- Voice agent process management (can be disabled for Docker deployments)
- Startup/shutdown event handlers

**Voice Agent Integration:**
- Runs as separate process (can be disabled with `DISABLE_VOICE_AGENT_AUTO_START=true`)
- Uses `app.agents.voice_agent` module
- Requires LiveKit, OpenAI, and Deepgram API keys

### 1.4 Database Models (24 Models)

**Core User & Auth:**
- `User` - User accounts (email/Google OAuth, username, profile)
- `RefreshToken` - JWT refresh token storage
- `DeviceToken` - FCM push notification tokens
- `EmailVerification` - Email verification codes

**Content Models:**
- `Podcast` - Audio/video podcasts (audio_url, video_url, cover_image)
- `MusicTrack` - Music library (audio_url, cover_image, lyrics)
- `Movie` - Full-length movies (video_url, preview_url, cover_image)
- `BibleStory` - Animated Bible stories
- `DocumentAsset` - PDF documents (Bible, etc.)
- `ContentDraft` - Unpublished content drafts

**Social & Community:**
- `CommunityPost` - Social media posts (text/image, categories)
- `Comment` - Post comments
- `Like` - Post likes
- `Artist` - Content creator profiles
- `ArtistFollower` - Artist follow relationships

**Playback & Organization:**
- `Playlist` - User-created playlists
- `PlaylistItem` - Playlist entries (podcasts, music)
- `Favorite` - User favorites

**Live & Events:**
- `LiveStream` - Live streaming sessions (LiveKit rooms)
- `Event` - Community events (location, date, attendees)
- `EventAttendee` - Event participation

**Monetization & Support:**
- `Donation` - Donations to artists/organization
- `BankDetails` - User bank account information
- `PaymentAccount` - Stripe Connect accounts
- `SupportMessage` - Support tickets

**System:**
- `Category` - Content categories
- `Notification` - In-app notifications
- `PlatformSettings` - Platform configuration

### 1.5 API Routes (`/api/v1`)

**Authentication (`/auth`):**
- `POST /login` - Username/email + password login
- `POST /register` - User registration (with OTP)
- `POST /google-login` - Google OAuth login
- `POST /refresh-token` - Refresh access token
- `POST /send-otp` - Send email OTP
- `POST /verify-otp` - Verify OTP
- `GET /me` - Current user profile

**Content (`/podcasts`, `/music`, `/movies`):**
- `GET /` - List content (with filters, pagination)
- `GET /{id}` - Get content details
- `POST /` - Create content (requires auth)
- `PUT /{id}` - Update content
- `DELETE /{id}` - Delete content

**Upload (`/upload`):**
- `POST /audio` - Upload audio file
- `POST /video` - Upload video file
- `POST /movie` - Upload movie file
- `POST /image` - Upload image
- `POST /document` - Upload document
- `POST /thumbnail` - Upload thumbnail
- `POST /temporary-audio` - Temporary audio for editing
- `GET /media/duration` - Get media duration

**Community (`/community`):**
- `GET /posts` - List posts (with filters)
- `GET /posts/{id}` - Get post details
- `POST /posts` - Create post
- `POST /posts/{id}/like` - Like/unlike post
- `POST /posts/{id}/comments` - Add comment
- `GET /posts/{id}/comments` - Get comments

**Live & Real-time (`/live`, `/livekit`):**
- `POST /streams` - Create live stream
- `GET /streams` - List live streams
- `POST /livekit/voice/token` - Get LiveKit voice token
- `POST /livekit/voice/room` - Create voice room

**Events (`/events`):**
- `GET /` - List events
- `GET /{id}` - Get event details
- `POST /` - Create event
- `POST /{id}/join` - Join event
- `DELETE /{id}/leave` - Leave event
- `GET /my/hosted` - User's hosted events
- `GET /my/attending` - User's attending events

**Admin (`/admin`):**
- `GET /dashboard` - Admin dashboard stats
- `GET /pending` - Pending content for approval
- `POST /approve/{content_type}/{id}` - Approve content
- `POST /reject/{content_type}/{id}` - Reject content
- `GET /users` - List users
- `PATCH /users/{id}/admin` - Set admin status
- `GET /settings/commission` - Get commission settings
- `PUT /settings/commission` - Update commission settings

**Additional Routes:**
- `/playlists`, `/artists`, `/favorites`, `/notifications`, `/search`, `/support`, `/donations`, `/stripe-connect`, `/documents`, `/bible-stories`, `/audio-editing`, `/video-editing`

### 1.6 Services Layer

**Media Services:**
- `MediaService` - File upload/download (S3 in production, local in dev)
- `ThumbnailService` - Thumbnail generation and management
- `AudioEditingService` - Audio processing (FFmpeg)
- `VideoEditingService` - Video processing (FFmpeg)

**Real-time Services:**
- `LiveKitService` - LiveKit token generation, room management
- Socket.IO handlers in `websocket/` - Real-time event broadcasting

**Auth & User Services:**
- `AuthService` (in routes/auth.py) - Password hashing, JWT tokens
- `RefreshTokenService` - Refresh token management
- `UsernameService` - Username generation and validation
- `EmailService` - Email sending (AWS SES)

**External Integrations:**
- `FirebasePushService` - Push notifications
- `GoogleDriveService` - Google Drive integration
- `AIService` - OpenAI integration
- `PaymentService` - Stripe/PayPal integration

**Business Logic:**
- `NotificationService` - In-app notifications
- `ArtistService` - Artist profile management

### 1.7 Database Configuration

**Connection Management:**
- Lazy initialization (engine created on first use)
- Async SQLAlchemy with asyncpg (PostgreSQL) or aiosqlite (SQLite)
- Connection pooling (PostgreSQL: pool_size=10, max_overflow=5)
- Environment-based URL: `DATABASE_URL` env variable

**Production:**
- PostgreSQL on AWS RDS
- Connection string: `postgresql+asyncpg://user:pass@host:5432/dbname`

**Development:**
- SQLite: `sqlite+aiosqlite:///local.db`
- Local file: `backend/local.db`

### 1.8 Media Storage

**Production (S3 + CloudFront):**
- All media files uploaded to AWS S3 bucket (`S3_BUCKET_NAME`)
- Served via CloudFront CDN (`CLOUDFRONT_URL`)
- Multipart upload for large files (>100MB)
- Directory structure:
  - `audio/` - Audio files
  - `video/` - Video files
  - `movies/` - Movie files
  - `animated-bible-stories/` - Kids content
  - `images/` - Images (profiles, thumbnails, quotes)
  - `documents/` - PDFs

**Development:**
- Local storage in `./media/` directory
- Served via FastAPI static file mounting (`/media`)

**Media Service:**
- `MediaService` class handles both S3 and local storage
- Automatic detection based on `ENVIRONMENT` env variable
- Returns CloudFront URLs in production, local paths in development

### 1.9 Authentication & Security

**JWT Tokens:**
- Access tokens (30 min expiry, configurable)
- Refresh tokens (30 days expiry, rotation enabled)
- HS256 algorithm with `SECRET_KEY`

**Authentication Methods:**
- Email/password (with OTP verification for registration)
- Google OAuth (via `GOOGLE_CLIENT_ID`)

**Middleware:**
- `get_current_user` - JWT token validation
- `get_current_user_optional` - Optional auth (for public endpoints)

**CORS:**
- Development: All origins (`*`)
- Production: Configurable via `CORS_ORIGINS` (comma-separated)

### 1.10 LiveKit Integration

**LiveKit Server:**
- Separate Docker container on EC2
- WebSocket URL: `LIVEKIT_WS_URL` (wss://...)
- HTTP API URL: `LIVEKIT_HTTP_URL` (https://...)
- API credentials: `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`

**Use Cases:**
- Video meetings (multi-participant)
- Live streaming
- Voice agent (AI-powered voice chat)

**Voice Agent:**
- Runs as separate process/container
- Uses OpenAI GPT-4o-mini + Deepgram (STT/TTS)
- Connects to LiveKit rooms automatically
- Can be disabled with `DISABLE_VOICE_AGENT_AUTO_START=true`

---

## 2. Frontend Architecture (`web/frontend`)

### 2.1 Technology Stack

**Framework:**
- **Flutter** (Web) - Dart-based UI framework
- **go_router** - Declarative routing with deep linking
- **Provider** - State management (ChangeNotifier pattern)

**HTTP & Networking:**
- `http` package - REST API calls
- `socket_io_client` - Socket.IO WebSocket client
- `livekit_client` - LiveKit WebRTC client

**Media & Playback:**
- `video_player` - Video playback
- `audioplayers` - Audio playback
- `flutter_stripe` - Stripe payment integration

**Storage:**
- `flutter_secure_storage` - Secure token storage (mobile)
- Custom `WebStorageService` - localStorage for web

**UI & Design:**
- Material Design 3
- Custom theme (warm brown/cream color scheme)
- Google Fonts (Inter)

### 2.2 Application Structure

```
web/frontend/lib/
├── main.dart                    # App entry point, font preloading
├── config/
│   └── app_config.dart          # Environment-based configuration
├── navigation/
│   ├── app_router.dart          # GoRouter setup, Provider integration
│   ├── app_routes.dart          # Route definitions (50+ routes)
│   └── web_navigation.dart      # Web navigation layout
├── screens/
│   ├── web/                     # Web-specific screens (41 files)
│   │   ├── landing_screen_web.dart
│   │   ├── home_screen_web.dart
│   │   ├── community_screen_web.dart
│   │   └── ... (38 more)
│   ├── admin/                   # Admin screens
│   ├── creation/                # Content creation workflows
│   ├── editing/                 # Audio/video editing
│   ├── events/                  # Event management
│   └── ... (other screen categories)
├── providers/                   # State management (15 providers)
│   ├── auth_provider.dart
│   ├── music_provider.dart
│   ├── community_provider.dart
│   ├── audio_player_provider.dart
│   └── ... (11 more)
├── services/                    # API and external services (14 services)
│   ├── api_service.dart         # Main REST API client (4700+ lines)
│   ├── auth_service.dart
│   ├── websocket_service.dart
│   ├── livekit_meeting_service.dart
│   ├── livekit_voice_service.dart
│   └── ... (9 more)
├── widgets/                     # Reusable UI components
│   ├── web/                     # Web-specific widgets
│   ├── shared/                  # Shared components
│   ├── admin/                   # Admin widgets
│   └── ... (other widget categories)
├── models/                      # Data models (Dart classes)
├── theme/                       # Design system
│   ├── app_colors.dart          # Color palette
│   ├── app_typography.dart      # Typography
│   └── app_theme.dart           # Theme configuration
└── utils/                       # Utility functions
```

### 2.3 Configuration (`app_config.dart`)

**Environment Variables (set via `--dart-define` in build):**
- `API_BASE_URL` - Backend API URL (required)
- `MEDIA_BASE_URL` - Media/CDN URL (required)
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL (required)
- `LIVEKIT_HTTP_URL` - LiveKit HTTP API URL (required)
- `WEBSOCKET_URL` - Socket.IO WebSocket URL (required)
- `ENVIRONMENT` - Environment name (default: production)
- `STRIPE_PUBLISHABLE_KEY` - Stripe publishable key
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- `ORGANIZATION_RECIPIENT_USER_ID` - Organization user ID for donations

**Amplify Build:**
- Variables set in Amplify console environment variables
- Passed to `flutter build web` via `--dart-define`

### 2.4 Routing (`app_routes.dart`)

**Main Routes:**
- `/` - Landing page (login/register)
- `/home` - Home dashboard
- `/create` - Content creation hub
- `/community` - Social feed
- `/profile` - User profile
- `/podcasts` - Podcast library
- `/movies` - Movie library
- `/events` - Events list
- `/bible` - Bible reader
- `/admin` - Admin dashboard (admin only)

**Content Routes:**
- `/podcast/:id` - Podcast detail/player
- `/movie/:id` - Movie detail/player
- `/artist/:artistId` - Artist profile
- `/events/:id` - Event detail

**Creation Routes:**
- `/create/audio` - Audio podcast creation
- `/create/video` - Video podcast creation
- `/create/movie` - Movie creation
- `/quote` - Quote creation

**Editor Routes:**
- `/edit/audio?path=...` - Audio editor
- `/edit/video?path=...` - Video editor
- `/preview/audio?uri=...` - Audio preview
- `/preview/video?uri=...` - Video preview

**Navigation:**
- Uses `go_router` for declarative routing
- Route guards for authentication/admin checks
- Navigation history tracking (`NavigationHistoryProvider`)
- No transitions (instant navigation)

### 2.5 State Management (Provider Pattern)

**Providers (15 total):**
1. `AuthProvider` - Authentication state, user info
2. `AppState` - Global app state
3. `MusicProvider` - Music library state
4. `CommunityProvider` - Community posts, comments, likes
5. `AudioPlayerState` - Audio playback state (current track, queue)
6. `SearchProvider` - Search functionality
7. `UserProvider` - User profile state
8. `PlaylistProvider` - Playlist management
9. `FavoritesProvider` - Favorites management
10. `SupportProvider` - Support tickets
11. `DocumentsProvider` - Document management
12. `NotificationProvider` - Notifications state
13. `ArtistProvider` - Artist profiles
14. `EventProvider` - Events state
15. `NavigationHistoryProvider` - Navigation history

**Provider Setup:**
- All providers registered in `AppRouter` via `MultiProvider`
- Access via `Provider.of<T>(context)` or `Consumer<T>`
- State persisted where needed (auth tokens, user preferences)

### 2.6 Services Layer

**API Service (`api_service.dart`):**
- Singleton pattern
- Handles all REST API calls to backend
- Automatic token refresh on 401 errors
- Environment-based URL configuration
- Comprehensive error handling
- Methods for all content types (podcasts, music, movies, community, etc.)

**Auth Service (`auth_service.dart`):**
- Token storage (web: localStorage, mobile: secure storage)
- Login/logout/register
- Token refresh logic
- User data storage
- "Remember Me" functionality (web)

**WebSocket Service (`websocket_service.dart`):**
- Socket.IO client connection
- Real-time event streams:
  - `live_stream_started`
  - `speak_permission_requested`
  - `new_notification`
- Auto-reconnection logic

**LiveKit Services:**
- `livekit_meeting_service.dart` - Video meeting management
- `livekit_voice_service.dart` - Voice agent interaction

**Additional Services:**
- `google_auth_service.dart` - Google OAuth
- `donation_service.dart` - Payment processing
- `audio_editing_service.dart` - Audio editing workflows
- `video_editing_service.dart` - Video editing workflows
- `download_service.dart` - Content downloading
- `stripe_connect_service.dart` - Stripe Connect integration

### 2.7 UI/UX Design System

**Color Palette (`app_colors.dart`):**
- Primary: Warm Brown (`#8B7355`), Golden Yellow (`#D4A574`)
- Background: Cream (`#F7F5F2`), Card Background (`#FCFAF8`)
- Text: Dark Brown (`#2D2520`), Medium (`#5A4F47`)

**Typography (`app_typography.dart`):**
- Google Fonts: Inter
- Semantic naming (heading1, heading2, body, caption)
- Responsive scaling

**Layout:**
- Sidebar navigation (280px fixed width)
- Responsive breakpoints (mobile, tablet, desktop)
- Bottom-mounted global audio player
- Card-based content display

### 2.8 Key Features

**Media Playback:**
- Global audio player (persistent across navigation)
- Video player (full-screen, inline)
- Playlist support
- Queue management
- Download for offline (web storage)

**Content Creation:**
- Audio recording (Web Audio API)
- Video recording (WebRTC)
- Audio/video editing workflows
- Preview before publishing
- Draft management

**Social Features:**
- Community posts (text, images)
- Comments and likes
- User profiles
- Artist profiles with following
- Notifications

**Real-time:**
- Live streaming viewing
- Video meetings (LiveKit)
- Voice agent chat
- Real-time notifications (Socket.IO)

---

## 3. Database Schema

### 3.1 Core Tables

**users**
- id, username, name, email, avatar, password_hash
- is_admin, phone, date_of_birth, bio
- google_id, auth_provider
- created_at, updated_at

**podcasts**
- id, title, description, audio_url, video_url, cover_image
- creator_id, category_id, duration, status
- plays_count, created_at

**community_posts**
- id, user_id, title, content, image_url
- category, post_type, is_approved
- likes_count, comments_count, created_at

**events**
- id, host_id, title, description, event_date
- location, latitude, longitude, max_attendees
- status, cover_image, created_at, updated_at

**live_streams**
- id, host_id, title, description, thumbnail
- room_name, status, viewer_count
- scheduled_start, started_at, ended_at, created_at

**movies**
- id, title, description, video_url, preview_url
- cover_image, director, cast, release_date, rating
- category_id, creator_id, duration, status
- plays_count, is_featured, created_at

**artists**
- id, user_id, artist_name, cover_image, bio
- social_links (JSON), followers_count, total_plays
- is_verified, created_at, updated_at

**playlists**
- id, user_id, name, description, cover_image, created_at

**playlist_items**
- id, playlist_id, content_type, content_id, position

**notifications**
- id, user_id, type, title, message, data (JSON)
- read, created_at

**donations**
- id, donor_id, recipient_id, amount, currency
- payment_method, status, transaction_id, created_at

### 3.2 Relationships

- User → Podcasts (one-to-many)
- User → CommunityPosts (one-to-many)
- User → Artist (one-to-one)
- Artist → ArtistFollower (one-to-many)
- CommunityPost → Comment (one-to-many)
- CommunityPost → Like (one-to-many)
- Playlist → PlaylistItem (one-to-many)
- Event → EventAttendee (one-to-many)
- User → Notifications (one-to-many)

### 3.3 Migrations

Migrations in `backend/migrations/versions/`:
- `000_initial_schema.py` - Initial database schema
- `002_add_username_to_users.py` - Username field
- `003_add_user_registration_fields.py` - Registration fields
- `005_add_artist_model.py` - Artist profiles
- `006_add_device_tokens.py` - Push notifications
- `007_add_content_drafts.py` - Draft system
- `008_add_refresh_tokens.py` - Refresh token table
- `009_add_platform_settings.py` - Platform config
- `010_add_event_approval_status.py` - Event approval
- `011_add_favorites_table.py` - Favorites
- `aee808aa6fbf_add_email_verification_and_notification_.py` - Email verification

---

## 4. Deployment Architecture

### 4.1 AWS Infrastructure

**Frontend (AWS Amplify):**
- Build pipeline: `amplify.yml`
- Environment variables set in Amplify console
- Automatic deployments on git push
- CDN distribution (Amplify managed)

**Backend (AWS EC2):**
- Instance: `52.56.78.203` (eu-west-2)
- SSH: `ssh -i christnew.pem ubuntu@52.56.78.203`
- Docker containers:
  - `cnt-backend` - FastAPI backend (port 8000)
  - `cnt-livekit-server` - LiveKit server (ports 7880-7881)
  - `cnt-voice-agent` - Voice agent service
- Nginx reverse proxy (likely)
- Process management: Docker (not docker-compose)

**Database (AWS RDS):**
- PostgreSQL database
- Connection via `DATABASE_URL` env variable

**Storage (AWS S3 + CloudFront):**
- S3 bucket: `cnt-media-bucket` (from config)
- CloudFront distribution for CDN
- CORS configured for web app

**Additional Services:**
- Redis (ElastiCache) - Socket.IO multi-instance coordination
- AWS SES - Email sending
- Firebase - Push notifications

### 4.2 Environment Configuration

**Backend (.env file on EC2):**
```
ENVIRONMENT=production
DATABASE_URL=postgresql+asyncpg://...
S3_BUCKET_NAME=cnt-media-bucket
CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://...
LIVEKIT_HTTP_URL=https://...
LIVEKIT_API_KEY=...
LIVEKIT_API_SECRET=...
OPENAI_API_KEY=...
DEEPGRAM_API_KEY=...
GOOGLE_CLIENT_ID=...
SECRET_KEY=...
CORS_ORIGINS=https://main.d1poes9tyirmht.amplifyapp.com,...
REDIS_URL=redis://...
```

**Frontend (Amplify environment variables):**
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - CloudFront URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - Socket.IO URL
- `GOOGLE_CLIENT_ID` - Google OAuth client ID
- Other variables as needed

### 4.3 Docker Deployment

**Backend Dockerfile:**
- Base: `python:3.11-slim`
- Installs: FFmpeg, Python dependencies
- Exposes port 8000
- CMD: `uvicorn app.main:app --host 0.0.0.0 --port 8000`

**Running Containers:**
- Backend: `docker run ... cnt-web-deployment_backend:latest`
- LiveKit: `docker run ... livekit/livekit-server:latest`
- Voice Agent: `docker run ... cnt-web-deployment_voice-agent`

**Note:** Using individual `docker` commands, not `docker-compose`

---

## 5. Key Features & Capabilities

### 5.1 Media Management

**Content Types:**
- Audio podcasts (MP3, WAV, etc.)
- Video podcasts (MP4, WebM, etc.)
- Full-length movies
- Music tracks
- Animated Bible stories
- Documents (PDF)

**Content Workflow:**
1. Upload media file
2. Generate/extract thumbnail
3. Create content record (pending status)
4. Admin approval (optional, configurable)
5. Publish (visible to users)

**Media Processing:**
- FFmpeg for duration extraction
- Thumbnail generation (video frames, custom uploads)
- Multipart upload for large files (S3)

### 5.2 Social Features

**Community Posts:**
- Text posts
- Image posts (Instagram-like)
- Categories: testimony, prayer_request, question, announcement, general
- Comments and likes
- Admin approval workflow

**User Profiles:**
- Customizable profiles
- Artist profiles (for content creators)
- Follower/following system (artists)
- Profile images, bios

### 5.3 Real-time Features

**Live Streaming:**
- Create live streams (LiveKit rooms)
- Real-time viewer count
- Socket.IO notifications for stream start

**Video Meetings:**
- Multi-participant video calls (LiveKit)
- Screen sharing support
- Meeting rooms with access tokens

**Voice Agent:**
- AI-powered voice chat
- OpenAI GPT-4o-mini integration
- Deepgram STT/TTS
- Conversational AI in voice calls

**Notifications:**
- In-app notifications (database)
- Push notifications (Firebase FCM)
- Real-time delivery (Socket.IO)
- Notification types: donations, content approval, comments, likes, followers

### 5.4 Content Creation Tools

**Audio Creation:**
- Web Audio API recording
- Audio editing workflows
- Upload existing audio files
- Preview before publishing

**Video Creation:**
- WebRTC camera recording
- Video editing workflows
- Upload existing video files
- Preview before publishing

**Quote Creation:**
- Text overlay on images
- Template system
- Image generation

### 5.5 Monetization

**Donations:**
- Donate to artists or organization
- Stripe payment processing
- Donation notifications
- Bank details for payout (Stripe Connect)

**Stripe Connect:**
- Artist onboarding
- Payment account management
- Commission settings (admin configurable)

### 5.6 Admin Features

**Content Moderation:**
- Approve/reject content
- Bulk operations
- Content statistics

**User Management:**
- User list and details
- Admin role assignment
- User deletion

**Platform Settings:**
- Commission settings
- Platform configuration

**Analytics:**
- Dashboard statistics
- Content metrics
- User metrics

---

## 6. Data Flow & Connections

### 6.1 User Authentication Flow

1. User enters credentials on landing page
2. Frontend calls `POST /api/v1/auth/login`
3. Backend validates credentials, generates JWT tokens
4. Frontend stores tokens (localStorage on web)
5. Subsequent requests include `Authorization: Bearer <token>`
6. Backend validates token via middleware
7. On token expiration, frontend uses refresh token

**Google OAuth Flow:**
1. User clicks "Sign in with Google"
2. Google OAuth popup
3. Frontend receives OAuth token
4. Frontend calls `POST /api/v1/auth/google-login`
5. Backend validates token, creates/updates user
6. Backend downloads Google avatar to S3
7. Returns JWT tokens

### 6.2 Media Upload Flow

1. User selects/records media file
2. Frontend calls `POST /api/v1/upload/{type}` (audio/video/image)
3. Backend `MediaService`:
   - Production: Uploads to S3, returns CloudFront URL
   - Development: Saves locally, returns `/media/...` path
4. Backend extracts metadata (duration, etc.)
5. Returns file URL and metadata
6. Frontend creates content record with file URL
7. Content saved with "pending" status
8. Admin approves (if moderation enabled)
9. Content becomes visible to users

### 6.3 Real-time Event Flow

**Socket.IO Events:**
1. Frontend connects to Socket.IO server (WebSocket)
2. Backend broadcasts events:
   - `live_stream_started` - New live stream
   - `speak_permission_requested` - Permission request
   - `new_notification` - New notification
3. Frontend listens via `WebSocketService` streams
4. UI updates in real-time

**LiveKit Flow:**
1. User requests meeting/stream
2. Backend generates LiveKit access token
3. Frontend connects to LiveKit server (WebRTC)
4. Media streaming via WebRTC (P2P/selective forwarding)
5. Voice agent joins room automatically (if enabled)

### 6.4 Notification Flow

1. Event occurs (donation, comment, like, etc.)
2. Backend `NotificationService` creates notification record
3. Backend sends push notification (Firebase FCM)
4. Backend emits Socket.IO `new_notification` event
5. Frontend receives event, updates notification list
6. User sees notification badge/count

---

## 7. Development Workflow

### 7.1 Local Development

**Backend:**
```bash
cd backend
python -m venv venv
source venv/bin/activate  # Linux/Mac
pip install -r requirements.txt
# Create .env file with local settings
uvicorn app.main:app --reload --port 8000
```

**Frontend:**
```bash
cd web/frontend
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8000/api/v1 ...
```

**Database:**
- Local SQLite: `backend/local.db`
- Or connect to PostgreSQL: Set `DATABASE_URL` in `.env`

**Media:**
- Local storage: `backend/media/`
- Served at `/media/` (FastAPI static files)

### 7.2 Production Deployment

**Backend (EC2):**
1. SSH to EC2 instance
2. Pull latest code (git)
3. Build Docker image: `docker build -t cnt-web-deployment_backend:latest .`
4. Stop old container: `docker stop cnt-backend`
5. Run new container: `docker run ... cnt-web-deployment_backend:latest`

**Frontend (Amplify):**
1. Push to git repository
2. Amplify automatically builds and deploys
3. Build uses environment variables from Amplify console

**Database Migrations:**
```bash
# On EC2 or local
cd backend
alembic upgrade head
```

---

## 8. Security Considerations

**Authentication:**
- JWT tokens with expiration
- Refresh token rotation
- Secure password hashing (bcrypt)
- Google OAuth integration

**Authorization:**
- Role-based access (admin vs user)
- Resource ownership checks
- Admin-only endpoints

**CORS:**
- Production: Whitelist specific origins
- Development: Allow all (for local testing)

**Data Protection:**
- Environment variables for secrets
- Secure token storage
- HTTPS in production (CloudFront, ALB)

**Media Security:**
- Authenticated uploads
- S3 bucket policies
- CloudFront signed URLs (if needed)

---

## 9. Known Architecture Notes

**Voice Agent:**
- Can run as separate process (main.py) or separate container
- Disabled in Docker deployments (`DISABLE_VOICE_AGENT_AUTO_START=true`)
- Requires LiveKit, OpenAI, Deepgram API keys

**Socket.IO:**
- Uses Redis adapter for multi-instance coordination
- Falls back to single-instance if Redis not available
- Events: `live_stream_started`, `speak_permission_requested`, `new_notification`

**Media Storage:**
- Production: S3 + CloudFront (all files)
- Development: Local `./media/` directory
- Automatic detection via `ENVIRONMENT` variable

**Database:**
- Lazy initialization (engine created on first use)
- Async SQLAlchemy (asyncpg/aiosqlite)
- Connection pooling for PostgreSQL

**CORS:**
- Configurable origins via `CORS_ORIGINS` (comma-separated)
- Development allows all origins
- Production restricts to Amplify domains

---

## 10. Summary

The CNT Media Platform is a comprehensive, production-ready application with:

- **Full-stack architecture**: Flutter Web frontend + FastAPI backend
- **Rich media support**: Audio, video, movies, documents
- **Social features**: Community posts, comments, likes, profiles
- **Real-time capabilities**: Live streaming, video meetings, voice agent
- **Content creation**: Recording, editing, publishing workflows
- **Monetization**: Donations, Stripe Connect integration
- **Admin tools**: Content moderation, user management, analytics
- **Scalable infrastructure**: AWS (EC2, RDS, S3, CloudFront, Amplify)
- **Production deployment**: Docker containers, environment-based configuration

The codebase is well-structured with clear separation of concerns, comprehensive error handling, and production-ready features like authentication, authorization, real-time updates, and media processing.

---

**Document Version:** 1.0  
**Last Updated:** 2025-01-03  
**Author:** AI Analysis

