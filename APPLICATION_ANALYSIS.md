# CNT Media Platform - Complete Application Analysis

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application combining:
- **Spotify-like** media consumption (podcasts, music, movies)
- **Instagram/Facebook-like** social features (community posts, comments, likes)
- **Real-time communication** (LiveKit for meetings, live streaming, voice agent)
- **Content creation tools** (audio/video editing, quote generation)
- **Admin dashboard** for content moderation and user management

---

## 1. Technology Stack

### Frontend (Web)
- **Framework**: Flutter/Dart (Web deployment)
- **State Management**: Provider pattern
- **Routing**: GoRouter
- **Deployment**: AWS Amplify
- **Build**: Flutter Web with environment variables via `--dart-define`

### Backend
- **Framework**: FastAPI (Python 3.11+)
- **ORM**: SQLAlchemy 2.0 (async)
- **Database**: 
  - Production: PostgreSQL (AWS RDS)
  - Development: SQLite
- **Migrations**: Alembic
- **Deployment**: AWS EC2 (eu-west-2) via Docker
- **Server**: Uvicorn (ASGI)

### Infrastructure
- **Media Storage**: AWS S3 + CloudFront CDN
- **Database**: AWS RDS (PostgreSQL)
- **Backend Hosting**: AWS EC2 (52.56.78.203)
- **Frontend Hosting**: AWS Amplify
- **Real-time**: LiveKit Server (Docker container)
- **CDN**: CloudFront (d126sja5o8ue54.cloudfront.net)

### External Services
- **AI/ML**: OpenAI GPT-4o-mini, Deepgram (STT/TTS)
- **Authentication**: Google OAuth, JWT tokens
- **Payments**: Stripe, PayPal
- **Push Notifications**: Firebase Admin SDK
- **Email**: AWS SES

---

## 2. Application Architecture

### 2.1 Backend Architecture

```
backend/
├── app/
│   ├── main.py                 # FastAPI app entry, Socket.io setup
│   ├── config.py               # Settings and environment config
│   ├── database/               # Database connection and models
│   │   ├── connection.py       # Async engine, session management
│   │   └── __init__.py
│   ├── models/                 # SQLAlchemy ORM models (23 models)
│   ├── routes/                 # API route handlers (26 route modules)
│   ├── services/               # Business logic services (15 services)
│   ├── schemas/                # Pydantic request/response schemas
│   ├── middleware/             # Auth middleware, CORS
│   ├── agents/                 # LiveKit voice agent
│   └── websocket/              # Socket.io handlers
├── migrations/                 # Alembic database migrations
├── scripts/                    # Utility scripts
└── Dockerfile                  # Container definition
```

### 2.2 Frontend Architecture

```
web/frontend/
├── lib/
│   ├── main.dart               # App entry point
│   ├── config/                 # App configuration
│   ├── navigation/             # Routing (GoRouter)
│   ├── providers/              # State management (14 providers)
│   ├── services/               # API and external services (12 services)
│   ├── screens/                # UI screens (100+ screens)
│   │   ├── web/                # Web-specific screens
│   │   ├── admin/              # Admin dashboard screens
│   │   ├── creation/           # Content creation workflows
│   │   └── ...
│   ├── widgets/                # Reusable UI components (56 widgets)
│   ├── models/                 # Data models
│   ├── theme/                  # Design system (colors, typography)
│   └── utils/                  # Utility functions
└── web/                        # Web-specific assets
```

---

## 3. Database Schema

### 3.1 Core Models (23 Total)

#### User Management
- **User**: Core user model with email, username, Google OAuth, admin flag
- **RefreshToken**: JWT refresh token storage
- **DeviceToken**: Push notification device tokens
- **EmailVerification**: Email verification codes

#### Content Models
- **Podcast**: Audio/video podcasts (title, description, audio_url, video_url, cover_image)
- **MusicTrack**: Music tracks (title, artist, album, audio_url, lyrics)
- **Movie**: Faith movies (title, video_url, preview_url, cover_image, duration)
- **BibleStory**: Animated Bible stories
- **DocumentAsset**: PDF documents (Bible, etc.)
- **Category**: Content categorization

#### Social Features
- **CommunityPost**: Instagram-like posts (text, image, category, likes_count, comments_count)
- **Comment**: Post comments
- **Like**: Post likes
- **Event**: Community events with location
- **EventAttendee**: Event attendance tracking

#### User Content
- **Playlist**: User-created playlists
- **PlaylistItem**: Playlist content items
- **Favorite**: User favorites
- **ContentDraft**: Draft content (audio, video, images)

#### Live Features
- **LiveStream**: Live streaming sessions (LiveKit room_name, status, viewer_count)

#### Monetization
- **Artist**: Artist profiles for content creators
- **ArtistFollower**: Artist follow relationships
- **BankDetails**: User bank account details
- **PaymentAccount**: Stripe Connect accounts
- **Donation**: Donation transactions

#### Support & Admin
- **SupportMessage**: User support tickets
- **Notification**: User notifications
- **PlatformSettings**: Platform-wide settings

### 3.2 Database Relationships

```
User (1) ──< (N) Podcast
User (1) ──< (N) CommunityPost
User (1) ──< (N) Playlist
User (1) ──< (1) BankDetails
User (1) ──< (1) PaymentAccount
User (1) ──< (1) Artist
User (1) ──< (N) Event (as host)
User (1) ──< (N) EventAttendee

CommunityPost (1) ──< (N) Comment
CommunityPost (1) ──< (N) Like

Playlist (1) ──< (N) PlaylistItem
```

---

## 4. API Structure

### 4.1 API Routes (26 Route Modules)

**Authentication & Users**
- `/api/v1/auth/*` - Login, register, Google OAuth, OTP, token refresh
- `/api/v1/users/*` - User profiles, updates
- `/api/v1/device-tokens/*` - Push notification tokens

**Content**
- `/api/v1/podcasts/*` - Podcast CRUD, search, categories
- `/api/v1/music/*` - Music tracks
- `/api/v1/movies/*` - Movie library
- `/api/v1/documents/*` - PDF documents (Bible)
- `/api/v1/bible-stories/*` - Animated Bible stories
- `/api/v1/categories/*` - Content categories

**Social Features**
- `/api/v1/community/*` - Posts, comments, likes
- `/api/v1/events/*` - Community events
- `/api/v1/artists/*` - Artist profiles

**User Content**
- `/api/v1/playlists/*` - Playlist management
- `/api/v1/favorites/*` - Favorites
- `/api/v1/content-drafts/*` - Draft management

**Live Features**
- `/api/v1/live/*` - Live streaming
- `/api/v1/livekit/*` - LiveKit token generation
- `/api/v1/voice-chat/*` - Voice agent chat

**Content Creation**
- `/api/v1/upload/*` - File uploads
- `/api/v1/audio-editing/*` - Audio processing
- `/api/v1/video-editing/*` - Video processing

**Monetization**
- `/api/v1/donations/*` - Donations
- `/api/v1/bank-details/*` - Bank account management
- `/api/v1/stripe-connect/*` - Stripe Connect onboarding

**Admin**
- `/api/v1/admin/*` - Admin dashboard, content moderation
- `/api/v1/admin/google-drive/*` - Google Drive integration

**Utilities**
- `/api/v1/search/*` - Global search
- `/api/v1/media/*` - Media URL resolution
- `/api/v1/notifications/*` - Notifications
- `/api/v1/support/*` - Support tickets

### 4.2 Authentication Flow

1. **Login/Register**: Email/username + password or Google OAuth
2. **Token Generation**: JWT access token (30 min) + refresh token (30 days)
3. **Token Refresh**: Automatic refresh when access token expires
4. **Token Storage**: 
   - Web: Browser localStorage (via WebStorageService)
   - Mobile: Secure storage (FlutterSecureStorage)

### 4.3 WebSocket (Socket.io)

- **Real-time notifications**: User notifications
- **Live stream updates**: Viewer counts, comments
- **Community updates**: New posts, comments, likes

---

## 5. Media Storage Architecture

### 5.1 Storage Strategy

**Development Mode**:
- Local file system: `./media/` directory
- Served via FastAPI static files: `/media/*`
- Structure:
  ```
  media/
  ├── audio/              # Podcast audio files
  ├── video/              # Podcast video files
  │   └── previews/       # Video preview clips
  ├── images/
  │   ├── thumbnails/     # Generated/custom thumbnails
  │   ├── movies/         # Movie posters
  │   ├── profiles/       # User avatars
  │   └── quotes/         # Generated quote images
  ├── documents/          # PDF documents
  ├── movies/             # Movie video files
  └── animated-bible-stories/  # Bible story videos
  ```

**Production Mode**:
- AWS S3 bucket: `cnt-web-media` (or `cnt-media-bucket`)
- CloudFront CDN: `https://d126sja5o8ue54.cloudfront.net`
- Same folder structure in S3
- URLs: `{CLOUDFRONT_URL}/{path}`

### 5.2 Media Service

The `MediaService` class handles:
- **File Upload**: S3 multipart upload for large files (>100MB)
- **Thumbnail Generation**: FFmpeg-based thumbnail extraction
- **Video Preview Generation**: Short preview clips (15 seconds)
- **Duration Detection**: FFprobe for media duration
- **WebM Handling**: Special processing for browser-recorded WebM files

---

## 6. LiveKit Integration

### 6.1 LiveKit Server

**Docker Container**: `livekit/livekit-server:latest`
- **Ports**: 
  - 7880: WebSocket (frontend connections)
  - 7881: HTTP API (backend operations)
  - 50100-50200/udp: RTP (video/audio streams)

**Configuration**: `livekit-server/livekit.yaml`

### 6.2 Use Cases

1. **Video Meetings**: Multi-participant video conferencing
   - Route: `/api/v1/livekit/meeting-token`
   - Frontend: `LiveKitMeetingService`

2. **Live Streaming**: Real-time broadcasting
   - Route: `/api/v1/live/*`
   - Model: `LiveStream` (room_name, status, viewer_count)

3. **Voice Agent**: AI voice assistant
   - Agent: `CNTVoiceAssistant` (app/agents/voice_agent.py)
   - STT: Deepgram
   - TTS: Deepgram
   - LLM: OpenAI GPT-4o-mini
   - Route: `/api/v1/livekit/voice-token`
   - Frontend: `LiveKitVoiceService`

### 6.3 Voice Agent Architecture

```
User (Frontend)
  ↓ WebSocket
LiveKit Server
  ↓ Agent Connection
Voice Agent Container (cnt-voice-agent)
  ├── Deepgram STT (Speech-to-Text)
  ├── OpenAI LLM (GPT-4o-mini)
  └── Deepgram TTS (Text-to-Speech)
```

**Features**:
- Prewarm for low latency
- Turn detection (VAD)
- Noise cancellation
- Preemptive generation
- Interruption handling

---

## 7. Frontend Services

### 7.1 Core Services

**ApiService** (`services/api_service.dart`):
- Main HTTP client
- Environment-aware URL construction
- Automatic token refresh
- Error handling and retries

**AuthService** (`services/auth_service.dart`):
- Login/logout
- Token management
- Token expiration checking
- Google OAuth

**WebSocketService** (`services/websocket_service.dart`):
- Socket.io client
- Real-time notifications
- Connection management

### 7.2 Media Services

**AudioEditingService**: Audio processing workflows
**VideoEditingService**: Video processing workflows
**DownloadService**: Content downloading

### 7.3 External Services

**LiveKitMeetingService**: Video conferencing
**LiveKitVoiceService**: Voice agent chat
**GoogleAuthService**: Google OAuth
**DonationService**: Payment processing
**StripeConnectService**: Stripe Connect integration

---

## 8. State Management (Provider Pattern)

### 8.1 Providers (14 Total)

- **AuthProvider**: Authentication state, user session
- **AppState**: Global app state
- **AudioPlayerState**: Audio playback (global player)
- **MusicProvider**: Music library
- **CommunityProvider**: Social features
- **SearchProvider**: Search functionality
- **UserProvider**: User profiles
- **PlaylistProvider**: Playlist management
- **FavoritesProvider**: Favorites
- **SupportProvider**: Support tickets
- **DocumentsProvider**: Document management
- **NotificationProvider**: Notifications
- **ArtistProvider**: Artist profiles
- **EventProvider**: Events

---

## 9. Deployment Configuration

### 9.1 Backend (EC2)

**Docker Containers** (3 containers):
1. **cnt-backend**: FastAPI application
   - Image: `cnt-web-deployment_backend:latest`
   - Port: 8000
   - Command: `uvicorn app.main:app --host 0.0.0.0 --port 8000`

2. **cnt-livekit-server**: LiveKit server
   - Image: `livekit/livekit-server:latest`
   - Ports: 7880 (WS), 7881 (HTTP), 50100-50200/udp (RTP)

3. **cnt-voice-agent**: AI voice agent
   - Image: `cnt-web-deployment_voice-agent`
   - Command: `python -m app.agents.voice_agent dev`

**Environment Variables** (`.env` on EC2):
- `ENVIRONMENT=production`
- `DATABASE_URL=postgresql+asyncpg://...` (RDS)
- `S3_BUCKET_NAME=cnt-web-media`
- `CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net`
- `LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com`
- `LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com`
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
- `OPENAI_API_KEY`, `DEEPGRAM_API_KEY`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- `CORS_ORIGINS=https://main.d1poes9tyirmht.amplifyapp.com,...`

### 9.2 Frontend (Amplify)

**Build Configuration** (`amplify.yml`):
- Flutter SDK installation
- Build command with environment variables:
  ```bash
  flutter build web --release \
    --dart-define=API_BASE_URL=$API_BASE_URL \
    --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
    --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
    --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
    --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
    --dart-define=ENVIRONMENT=production \
    --dart-define=GOOGLE_CLIENT_ID=$GOOGLE_CLIENT_ID
  ```

**Environment Variables** (`amplify-env-vars.json`):
- `API_BASE_URL`: `https://api.christnewtabernacle.com/api/v1`
- `MEDIA_BASE_URL`: `https://d126sja5o8ue54.cloudfront.net`
- `LIVEKIT_WS_URL`: `wss://livekit.christnewtabernacle.com`
- `LIVEKIT_HTTP_URL`: `https://livekit.christnewtabernacle.com`
- `WEBSOCKET_URL`: `wss://api.christnewtabernacle.com`
- `GOOGLE_CLIENT_ID`: Google OAuth client ID

---

## 10. Key Features

### 10.1 Media Consumption
- **Audio Podcasts**: Streaming, playlists, favorites
- **Video Podcasts**: Video playback, thumbnails
- **Music Library**: Music tracks with lyrics
- **Movies**: Full-length faith movies with previews
- **Bible Stories**: Animated Bible story videos
- **Documents**: PDF Bible reader

### 10.2 Social Features
- **Community Posts**: Instagram-like posts (text, images)
- **Comments & Likes**: Social interactions
- **Events**: Community events with location
- **User Profiles**: Customizable profiles
- **Following**: Artist follow system

### 10.3 Content Creation
- **Audio Podcasts**: Record, edit, upload audio
- **Video Podcasts**: Record, edit, upload video
- **Quotes**: Generate inspirational quote images
- **Live Streaming**: Real-time broadcasting
- **Drafts**: Save work-in-progress content

### 10.4 Real-time Features
- **Video Meetings**: Multi-participant video calls (LiveKit)
- **Live Streaming**: Real-time broadcasts
- **Voice Agent**: AI voice assistant chat
- **Real-time Notifications**: Socket.io notifications
- **Live Comments**: Real-time stream comments

### 10.5 Admin Features
- **Content Moderation**: Approve/reject posts, podcasts
- **User Management**: User roles, permissions
- **Analytics Dashboard**: Usage statistics
- **Support System**: Ticket management
- **Google Drive Integration**: Bulk content import

### 10.6 Monetization
- **Donations**: User-to-user and organization donations
- **Stripe Connect**: Artist payment accounts
- **Bank Details**: Payment account management

---

## 11. Security & Authentication

### 11.1 Authentication Methods
1. **Email/Username + Password**: Bcrypt hashing
2. **Google OAuth**: Google Sign-In integration
3. **OTP (One-Time Password)**: Email-based verification

### 11.2 Token Management
- **Access Token**: JWT, 30-minute expiration
- **Refresh Token**: 30-day expiration, rotation enabled
- **Token Storage**: Secure storage (web: localStorage, mobile: secure storage)
- **Auto-refresh**: Proactive refresh 5 minutes before expiration

### 11.3 Security Features
- **CORS**: Production-specific origins
- **Password Hashing**: Bcrypt
- **JWT Signing**: HS256 algorithm
- **HTTPS**: All production endpoints
- **Input Validation**: Pydantic schemas

---

## 12. Database Migrations

**Alembic Migrations** (`backend/migrations/versions/`):
- `000_initial_schema.py`: Initial database schema
- `002_add_username_to_users.py`: Username column
- `003_add_user_registration_fields.py`: Registration fields
- `004_add_post_approval_and_type.py`: Post moderation
- `005_add_artist_model.py`: Artist profiles
- `006_add_device_tokens.py`: Push notifications
- `007_add_content_drafts.py`: Draft system
- `008_add_refresh_tokens.py`: Token refresh
- `aee808aa6fbf_add_email_verification_and_notification_.py`: Email verification

**SQL Migrations**:
- `add_events_tables.sql`: Events schema
- `add_event_coordinates.sql`: Event location
- `add_animated_bible_stories_category.sql`: Bible stories category

---

## 13. Development Workflow

### 13.1 Local Backend Setup
```bash
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
cp env.example .env
# Configure .env for local development
uvicorn app.main:app --reload --port 8002
```

### 13.2 Local Frontend Setup
```bash
cd web/frontend
flutter pub get
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=ENVIRONMENT=development
```

### 13.3 Docker Development
```bash
docker-compose up -d
# Starts: backend, livekit-server, voice-agent
```

---

## 14. File Structure Summary

### Backend Files
- **Models**: 23 SQLAlchemy models
- **Routes**: 26 route modules (~100+ endpoints)
- **Services**: 15 service classes
- **Migrations**: 9 Alembic migrations + SQL scripts

### Frontend Files
- **Screens**: 100+ screen widgets
- **Widgets**: 56 reusable components
- **Services**: 12 service classes
- **Providers**: 14 state management providers
- **Models**: Data model classes

---

## 15. Environment-Specific Behavior

### Development
- **Database**: SQLite (`local.db`)
- **Media**: Local file system (`./media/`)
- **CORS**: All origins allowed
- **Static Files**: Served via FastAPI `/media` endpoint

### Production
- **Database**: PostgreSQL (AWS RDS)
- **Media**: AWS S3 + CloudFront
- **CORS**: Specific allowed origins
- **Static Files**: CloudFront CDN
- **HTTPS**: All endpoints use HTTPS

---

## 16. API Endpoints Summary

**Total Endpoints**: ~150+ API endpoints across 26 route modules

**Key Endpoint Categories**:
- Authentication: 10+ endpoints
- Content: 50+ endpoints (podcasts, music, movies, documents)
- Social: 20+ endpoints (community, events, artists)
- Live: 10+ endpoints (streaming, meetings, voice)
- Admin: 30+ endpoints (moderation, management)
- Utilities: 20+ endpoints (search, upload, media)

---

## 17. Integration Points

1. **AWS S3**: Media file storage
2. **CloudFront**: CDN for media delivery
3. **AWS RDS**: PostgreSQL database
4. **LiveKit**: Real-time communication
5. **OpenAI**: LLM for voice agent
6. **Deepgram**: STT/TTS for voice agent
7. **Google OAuth**: Authentication
8. **Stripe**: Payment processing
9. **Firebase**: Push notifications
10. **AWS SES**: Email sending

---

## 18. Current Deployment Status

### Backend (EC2: 52.56.78.203)
- ✅ FastAPI backend running (port 8000)
- ✅ LiveKit server running (ports 7880-7881)
- ✅ Voice agent running (healthy)
- ✅ Docker containers: 3 active

### Frontend (Amplify)
- ✅ Web app deployed
- ✅ Environment variables configured
- ✅ Build pipeline: Flutter Web

### Database (RDS)
- ✅ PostgreSQL production database
- ✅ Migrations applied

### Media Storage
- ✅ S3 bucket configured
- ✅ CloudFront distribution active
- ✅ CORS configured

---

## 19. Known Architecture Patterns

1. **Repository Pattern**: Services abstract database operations
2. **Dependency Injection**: FastAPI dependency system
3. **Provider Pattern**: Flutter state management
4. **Service Layer**: Business logic separation
5. **Schema Validation**: Pydantic for request/response
6. **Async/Await**: Full async backend operations
7. **WebSocket**: Real-time bidirectional communication
8. **CDN Strategy**: CloudFront for media delivery

---

## 20. Next Steps for Development

When working on this application, consider:

1. **Database**: Check migrations before schema changes
2. **Media**: Understand S3 vs local storage logic
3. **Authentication**: Token refresh flow is critical
4. **Environment**: Always check ENVIRONMENT variable
5. **CORS**: Production has strict CORS policies
6. **LiveKit**: Separate container for voice agent
7. **Docker**: Backend uses Docker (not docker-compose in production)
8. **Frontend**: Environment variables via `--dart-define`

---

## Conclusion

This is a **production-ready, full-stack media platform** with:
- ✅ Comprehensive content management
- ✅ Real-time features (LiveKit)
- ✅ Social networking capabilities
- ✅ Content creation tools
- ✅ Admin moderation system
- ✅ Monetization features
- ✅ Scalable architecture (S3, RDS, CDN)
- ✅ Modern tech stack (FastAPI, Flutter, Docker)

The application is well-structured, follows best practices, and is ready for feature development and enhancements.

