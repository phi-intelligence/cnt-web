# CNT Media Platform - Complete Application Analysis

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application combining:
- **Spotify-like** media consumption (podcasts, music, movies)
- **Instagram/Facebook-like** social features (community posts, comments, likes)
- **Real-time communication** (LiveKit for meetings, live streaming, voice agent)
- **Content creation tools** (audio/video editing, document management)

**Deployment Architecture:**
- **Frontend (Web)**: Flutter/Dart deployed on AWS Amplify
- **Backend**: FastAPI (Python) on AWS EC2 (eu-west-2) with Docker
- **Database**: PostgreSQL (AWS RDS) in production, SQLite for local dev
- **Media Storage**: AWS S3 + CloudFront CDN
- **Real-time**: LiveKit server for meetings/streaming/voice agent
- **Infrastructure**: AWS ALB, Auto Scaling, ElastiCache (Redis)

---

## 1. Application Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         User Browser                             │
│                    (Flutter Web App)                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ HTTPS
                            │
        ┌───────────────────┴───────────────────┐
        │                                         │
        ▼                                         ▼
┌───────────────┐                      ┌──────────────────┐
│ AWS Amplify   │                      │  AWS ALB          │
│ (Frontend)    │                      │  (Load Balancer)  │
│               │                      │                   │
│ christnew-    │                      │ Port 80/443       │
│ tabernacle.com│                      └─────────┬─────────┘
└───────────────┘                                │
                                                 │
                                                 ▼
                                    ┌────────────────────────┐
                                    │   EC2 Instance        │
                                    │  (52.56.78.203)       │
                                    │                       │
                                    │  ┌─────────────────┐  │
                                    │  │  Nginx         │  │
                                    │  │  (Reverse      │  │
                                    │  │   Proxy)       │  │
                                    │  └────────┬────────┘  │
                                    │           │            │
                                    │  ┌────────▼────────┐  │
                                    │  │ Docker Network  │  │
                                    │  │ (cnt-network)   │  │
                                    │  └────────┬────────┘  │
                                    │           │            │
                                    │  ┌────────┴────────┐  │
                                    │  │                 │  │
                                    │  ▼                 ▼  │
                                    │ ┌──────────┐  ┌──────┐│
                                    │ │ Backend  │  │LiveKit││
                                    │ │ Container│  │Server ││
                                    │ │ :8000    │  │:7880  ││
                                    │ └────┬─────┘  └───┬───┘│
                                    │      │            │    │
                                    │      ▼            │    │
                                    │ ┌──────────┐     │    │
                                    │ │Voice Agent│     │    │
                                    │ │ Container │     │    │
                                    │ └───────────┘     │    │
                                    └─────────┬─────────┴────┘
                                              │
                    ┌────────────────────────┼────────────────────┐
                    │                        │                    │
                    ▼                        ▼                    ▼
            ┌──────────────┐        ┌──────────────┐    ┌──────────────┐
            │ PostgreSQL   │        │ ElastiCache  │    │  S3 +        │
            │ (RDS)        │        │ (Redis)      │    │  CloudFront  │
            │              │        │              │    │              │
            │ cntdb        │        │ cnt-redis-   │    │ cnt-web-media│
            │ :5432        │        │ cluster      │    │ + CDN        │
            └──────────────┘        └──────────────┘    └──────────────┘
```

### 1.2 Technology Stack

**Frontend:**
- **Framework**: Flutter 3.x (Dart)
- **State Management**: Provider pattern
- **UI**: Material Design with custom Christian-themed color scheme
- **Real-time**: Socket.io client, LiveKit client
- **Deployment**: AWS Amplify

**Backend:**
- **Framework**: FastAPI (Python 3.11)
- **ORM**: SQLAlchemy 2.0 (async)
- **Database**: PostgreSQL 17.6 (production), SQLite (local)
- **Real-time**: Socket.io with Redis adapter
- **Authentication**: JWT tokens (access + refresh)
- **Deployment**: Docker containers on EC2

**Infrastructure:**
- **Compute**: AWS EC2 (t3.large instances)
- **Load Balancing**: Application Load Balancer (ALB)
- **Auto Scaling**: Auto Scaling Group (1-3 instances)
- **Database**: AWS RDS PostgreSQL
- **Cache**: AWS ElastiCache Redis (cache.t3.micro)
- **Storage**: AWS S3 + CloudFront CDN
- **Domain**: christnewtabernacle.com

**AI/Real-time Services:**
- **LiveKit**: Real-time video/audio communication
- **OpenAI**: GPT-4o-mini for voice agent LLM
- **Deepgram**: Speech-to-Text and Text-to-Speech
- **Silero**: Voice Activity Detection (VAD)

---

## 2. Backend Architecture

### 2.1 Backend Structure

```
backend/
├── app/
│   ├── main.py                 # FastAPI app entry point
│   ├── config.py               # Settings and environment config
│   ├── database/               # Database connection and session management
│   ├── models/                 # SQLAlchemy ORM models (28 tables)
│   ├── routes/                 # API route handlers (25 route modules)
│   ├── schemas/                # Pydantic request/response schemas
│   ├── services/               # Business logic services
│   ├── middleware/              # Custom middleware
│   ├── websocket/              # Socket.io handlers
│   └── agents/                 # LiveKit voice agent
├── migrations/                 # Alembic database migrations
├── scripts/                    # Utility scripts
├── Dockerfile                  # Container image definition
└── requirements.txt            # Python dependencies
```

### 2.2 Database Schema

**Core Tables (28 total):**

1. **Users & Authentication:**
   - `users` - User accounts (email, Google OAuth, profile)
   - `refresh_tokens` - JWT refresh token storage
   - `email_verification` - Email verification codes
   - `device_tokens` - Push notification device tokens

2. **Content:**
   - `podcasts` - Audio/video podcasts
   - `movies` - Full-length movies and animated Bible stories
   - `music` - Music tracks
   - `categories` - Content categorization
   - `playlists` - User playlists
   - `playlist_items` - Playlist content items
   - `favorites` - User favorites
   - `content_drafts` - Draft content before publishing

3. **Community:**
   - `community_posts` - Social media posts (testimonies, prayers, etc.)
   - `comments` - Post comments
   - `likes` - Post likes

4. **Live Features:**
   - `live_streams` - Live streaming sessions
   - `events` - Scheduled events/meetings
   - `event_attendees` - Event participation

5. **Monetization:**
   - `donations` - Donation transactions
   - `payment_accounts` - Stripe Connect accounts
   - `bank_details` - User bank information
   - `platform_settings` - Commission settings

6. **Support & Admin:**
   - `support_messages` - Support tickets
   - `notifications` - User notifications
   - `artists` - Artist profiles
   - `artist_followers` - Artist following relationships

7. **Documents:**
   - `document_assets` - PDF documents (Bible, etc.)
   - `bible_stories` - Bible story content

**Key Relationships:**
- Users → Podcasts (creator)
- Users → Community Posts
- Users → Artists (one-to-one)
- Users → Payment Accounts (one-to-one)
- Users → Bank Details (one-to-one)
- Community Posts → Comments (one-to-many)
- Community Posts → Likes (many-to-many)
- Playlists → Playlist Items (one-to-many)

### 2.3 API Endpoints

**Base URL**: `/api/v1`

**Authentication (`/api/v1/auth`):**
- `POST /login` - Email/password login
- `POST /register` - User registration
- `POST /refresh` - Refresh access token
- `POST /logout` - Logout
- `POST /google-login` - Google OAuth login
- `POST /send-otp` - Send OTP for registration
- `POST /verify-otp` - Verify OTP
- `POST /register-with-otp` - Register with OTP
- `POST /check-username` - Check username availability
- `GET /google-client-id` - Get Google OAuth client ID

**Content Endpoints:**
- **Podcasts** (`/api/v1/podcasts`): GET list, GET by ID, POST create, POST bulk, DELETE
- **Movies** (`/api/v1/movies`): GET list, GET featured, GET animated Bible stories, GET by ID, POST, PUT, DELETE, GET similar
- **Music** (`/api/v1/music/tracks`): GET list, GET by ID, POST create
- **Categories** (`/api/v1/categories`): GET list
- **Playlists** (`/api/v1/playlists`): GET list, GET by ID, POST create, POST add items
- **Favorites** (`/api/v1/favorites`): GET, POST, DELETE, GET check status
- **Documents** (`/api/v1/documents`): GET list, GET by ID, POST, PATCH, DELETE
- **Bible Stories** (`/api/v1/bible-stories`): GET list, GET by ID

**Community (`/api/v1/community`):**
- `GET /posts` - List community posts
- `POST /posts` - Create post
- `POST /posts/{id}/regenerate-quote-image` - Regenerate quote image
- `POST /posts/{id}/like` - Like/unlike post
- `GET /posts/{id}/comments` - Get comments
- `POST /posts/{id}/comments` - Add comment

**Live Features:**
- **Live Streams** (`/api/v1/live`): GET streams, POST create, PUT update, DELETE, POST join, POST end, POST get LiveKit token
- **LiveKit Voice** (`/api/v1/livekit`): POST voice token, POST create room, DELETE room, GET rooms, GET health
- **Voice Chat** (`/api/v1/voice-chat`): Voice chat endpoints

**Media Upload (`/api/v1/upload`):**
- `POST /audio` - Upload audio file
- `POST /video` - Upload video file
- `POST /movie` - Upload movie
- `POST /image` - Upload image
- `POST /profile-image` - Upload profile image
- `POST /document` - Upload document
- `POST /thumbnail` - Upload thumbnail
- `POST /thumbnail/generate-from-video` - Generate thumbnail
- `GET /thumbnail/defaults` - Get default thumbnails
- `GET /media/duration` - Get media duration
- `POST /draft/audio` - Upload draft audio
- `POST /draft/video` - Upload draft video
- `POST /draft/image` - Upload draft image

**Media Editing:**
- **Audio Editing** (`/api/v1/audio-editing`): POST trim, merge, fade-in, fade-out, fade-in-out
- **Video Editing** (`/api/v1/video-editing`): POST trim, remove-audio, add-audio, replace-audio, apply-filters, add-text-overlays, rotate

**Users (`/api/v1/users`):**
- `GET /me` - Get current user
- `PUT /me` - Update current user
- `GET /{user_id}/public` - Get public user profile

**Artists (`/api/v1/artists`):**
- `GET /me` - Get current artist profile
- `GET /{artist_id}` - Get artist by ID
- `GET /by-user/{user_id}` - Get artist by user ID
- `PUT /me` - Update artist profile
- `POST /me/cover-image` - Upload cover image
- `GET /{artist_id}/podcasts` - Get artist podcasts
- `POST /{artist_id}/follow` - Follow artist
- `DELETE /{artist_id}/follow` - Unfollow artist
- `GET /{artist_id}/followers` - Get followers

**Events (`/api/v1/events`):**
- `POST /` - Create event
- `GET /` - List events
- `GET /{event_id}` - Get event
- `PUT /{event_id}` - Update event
- `DELETE /{event_id}` - Delete event
- `POST /{event_id}/join` - Join event
- `DELETE /{event_id}/leave` - Leave event
- `GET /{event_id}/attendees` - Get attendees
- `PUT /{event_id}/attendees/{user_id}` - Update attendee status
- `GET /my/hosted` - Get hosted events
- `GET /my/attending` - Get attending events

**Donations (`/api/v1/donations`):**
- `POST /create-payment-intent` - Create Stripe payment intent
- `POST /confirm/{payment_intent_id}` - Confirm payment
- `POST /` - Create donation record
- `GET /received` - Get received donations
- `GET /sent` - Get sent donations
- `GET /admin/all` - Get all donations (admin)

**Stripe Connect (`/api/v1/stripe-connect`):**
- `POST /create-account` - Create Stripe Connect account
- `POST /create-onboarding-link` - Create onboarding link
- `GET /account-status` - Get account status
- `GET /account-status/{target_user_id}` - Get account status for user
- `GET /dashboard-link` - Get Stripe dashboard link

**Bank Details (`/api/v1/bank-details`):**
- `POST /` - Create bank details
- `GET /` - Get bank details
- `PUT /` - Update bank details
- `DELETE /` - Delete bank details

**Support (`/api/v1/support`):**
- `POST /messages` - Create support message
- `GET /messages/me` - Get my messages
- `GET /messages` - Get all messages (admin)
- `GET /messages/stats` - Get support stats
- `POST /messages/{id}/reply` - Reply to message
- `POST /messages/{id}/close` - Close ticket

**Notifications (`/api/v1/notifications`):**
- `GET /` - Get notifications
- `GET /unread-count` - Get unread count
- `POST /read` - Mark as read
- `POST /read-all` - Mark all as read
- `DELETE /{notification_id}` - Delete notification
- `DELETE /` - Delete all notifications

**Device Tokens (`/api/v1/device-tokens`):**
- `POST /register` - Register device token
- `DELETE /` - Unregister device token
- `GET /my-tokens` - Get my tokens

**Admin (`/api/v1/admin`):**
- `GET /dashboard` - Admin dashboard stats
- `GET /pending` - Get pending content
- `POST /approve/{content_type}/{content_id}` - Approve content
- `POST /reject/{content_type}/{content_id}` - Reject content
- `DELETE /{content_type}/{content_id}` - Delete content
- `GET /content` - Get all content with filters
- `POST /sync-images-to-posts` - Sync images to posts
- `GET /users` - List users
- `GET /users/{user_id}` - Get user
- `PATCH /users/{user_id}/admin` - Make user admin
- `DELETE /users/{user_id}` - Delete user
- `POST /movies/{movie_id}/regenerate-thumbnail` - Regenerate thumbnail
- `POST /movies/regenerate-all-thumbnails` - Regenerate all thumbnails
- `GET /settings/commission` - Get commission settings
- `PUT /settings/commission` - Update commission settings

**Admin Google Drive (`/api/v1/admin/google-drive`):**
- `GET /google-drive/auth-url` - Get auth URL
- `GET /google-drive/picker-token` - Get picker token
- `GET /google-drive/callback` - OAuth callback
- `GET /google-drive/files` - List files
- `POST /google-drive/import/{file_id}` - Import file

**Search (`/api/v1/search`):**
- `GET /` - Search across content

**Media (`/api/v1/media`):**
- `GET /proxy` - Proxy media requests
- `GET /signed-url` - Get signed S3 URL

**Content Drafts (`/api/v1/content-drafts`):**
- `POST /` - Create draft
- `GET /` - List drafts
- `GET /{draft_id}` - Get draft
- `PUT /{draft_id}` - Update draft
- `DELETE /{draft_id}` - Delete draft
- `GET /type/{draft_type}` - Get drafts by type

### 2.4 Authentication & Security

**JWT Token System:**
- **Access Token**: Short-lived (30 minutes), used for API requests
- **Refresh Token**: Long-lived (30 days), used to refresh access tokens
- **Token Rotation**: Enabled (new refresh token on each refresh)
- **Storage**: Refresh tokens stored in database

**Authentication Methods:**
1. **Email/Password**: Traditional login with password hashing (bcrypt)
2. **Google OAuth**: OAuth 2.0 flow with Google
3. **OTP Registration**: One-time password for email verification

**CORS Configuration:**
- Production: Restricted to specific domains
  - `https://christnewtabernacle.com`
  - `https://www.christnewtabernacle.com`
  - `https://main.d1poes9tyirmht.amplifyapp.com`
  - `https://d1poes9tyirmht.amplifyapp.com`
- Development: `*` (all origins)

**Security Headers:**
- Proxy headers middleware for ALB (X-Forwarded-Proto, X-Forwarded-For)
- CORS headers on all responses (including errors)
- HTTPS enforcement via ALB

### 2.5 Real-time Communication

**Socket.io:**
- **Purpose**: Real-time notifications, live updates
- **Adapter**: Redis adapter for multi-instance support
- **Redis URL**: `redis://cnt-redis-cluster.h94cmg.0001.euw2.cache.amazonaws.com:6379`
- **Events**: User notifications, live stream updates, community interactions

**LiveKit:**
- **Purpose**: Video meetings, live streaming, voice agent
- **Server**: Running in Docker container on EC2
- **WebSocket**: `wss://livekit.christnewtabernacle.com` (proxied via Nginx)
- **HTTP API**: `http://livekit-server:7881` (internal)
- **RTP Ports**: 50100-50200 (UDP) for media streams
- **Configuration**: `livekit-server/livekit.yaml`
- **Redis**: Connected to ElastiCache for multi-instance support

**Voice Agent:**
- **Framework**: LiveKit Agents
- **STT**: Deepgram
- **TTS**: Deepgram
- **LLM**: OpenAI GPT-4o-mini
- **VAD**: Silero (Voice Activity Detection)
- **Features**: Prewarm for low latency, turn detection, noise cancellation
- **Container**: Separate Docker container (`cnt-voice-agent`)

---

## 3. Frontend Architecture

### 3.1 Frontend Structure

```
web/frontend/
├── lib/
│   ├── main.dart              # App entry point
│   ├── config/                # Configuration
│   │   └── app_config.dart     # Environment variables
│   ├── constants/             # App constants
│   ├── layouts/               # Layout components
│   │   └── web_layout.dart     # Main web layout with sidebar
│   ├── models/                 # Data models (9 files)
│   ├── navigation/             # Routing
│   │   └── app_router.dart     # GoRouter configuration
│   ├── providers/              # State management (15 providers)
│   ├── screens/                # Screen components (107 files)
│   │   ├── web/                # Web-specific screens
│   │   ├── admin/              # Admin screens
│   │   ├── audio/              # Audio player screens
│   │   ├── video/              # Video player screens
│   │   └── creation/           # Content creation screens
│   ├── services/               # API and external services (14 services)
│   ├── theme/                  # Design system
│   │   ├── app_colors.dart     # Color palette
│   │   ├── app_typography.dart # Typography
│   │   └── app_spacing.dart    # Spacing system
│   ├── utils/                  # Utility functions (22 files)
│   └── widgets/                 # Reusable widgets (59 files)
│       ├── web/                 # Web-specific widgets
│       ├── shared/              # Shared widgets
│       ├── media/               # Media widgets
│       └── [specialized]/       # Specialized widget folders
├── assets/                      # Images and assets
├── web/                         # Web-specific files
│   ├── index.html              # HTML entry point
│   └── manifest.json            # PWA manifest
└── pubspec.yaml                 # Dependencies
```

### 3.2 Key Frontend Features

**State Management (Provider Pattern):**
- `AuthProvider` - Authentication state
- `AppStateProvider` - Global app state
- `AudioPlayerProvider` - Audio playback state
- `MusicProvider` - Music library
- `CommunityProvider` - Social features
- `SearchProvider` - Search functionality
- `UserProvider` - User profile
- `PlaylistProvider` - Playlist management
- `FavoritesProvider` - Favorites
- `SupportProvider` - Support tickets
- `DocumentsProvider` - Document management
- `NotificationProvider` - Notifications

**Services:**
- `ApiService` - Main API communication (4789 lines)
- `AuthService` - Authentication handling
- `WebSocketService` - Real-time communication
- `AudioEditingService` - Audio processing
- `VideoEditingService` - Video processing
- `LiveKitMeetingService` - Video conferencing
- `LiveKitVoiceService` - Voice chat
- `DonationService` - Payment processing
- `GoogleAuthService` - Google OAuth

**Main Screens:**
1. **Landing/Login** - Landing page with integrated login
2. **Home** - Dashboard with content sections
3. **Search** - Content search with filters
4. **Create** - Content creation hub
5. **Community** - Social posts and interactions
6. **Podcasts** - Podcast library
7. **Movies** - Movie collection
8. **Music** - Music library
9. **Profile** - User profile and settings
10. **Admin Dashboard** - Admin features

**Design System:**
- **Colors**: Warm brown/cream Christian theme
  - Primary: `#8B7355` (Warm Brown)
  - Accent: `#D4A574` (Golden Yellow)
  - Background: `#F7F5F2` (Cream)
- **Typography**: Google Fonts (Inter)
- **Layout**: Sidebar navigation (280px) + flexible content area

### 3.3 Frontend Configuration

**Environment Variables (set during Amplify build):**
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - Media CDN URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - Socket.io WebSocket URL
- `ENVIRONMENT` - Environment (production/development)
- `GOOGLE_CLIENT_ID` - Google OAuth client ID

**Build Process (Amplify):**
1. Clone Flutter SDK
2. `flutter pub get`
3. `flutter build web --release` with dart-define flags
4. Deploy `build/web` directory

---

## 4. Infrastructure & Deployment

### 4.1 AWS Infrastructure

**EC2 Instances:**
- **Instance Type**: t3.large (2 vCPU, 8GB RAM)
- **Region**: eu-west-2 (London)
- **Running Instances**: 2 (one active, one in ASG)
  - `i-03106a794959d37ab`: 52.56.78.203 (172.31.33.228) - **Active**
  - `i-03c688b8cb17b7070`: 13.40.177.14 (172.31.0.134) - **Standby**

**Application Load Balancer (ALB):**
- **Name**: `cnt-backend-alb`
- **DNS**: `cnt-backend-alb-1668183912.eu-west-2.elb.amazonaws.com`
- **Type**: Application Load Balancer (internet-facing)
- **Status**: Active
- **Listeners**:
  - Port 80 (HTTP) → Forward to target group
  - Port 443 (HTTPS) → Forward to target group

**Target Group:**
- **Name**: `cnt-backend-tg`
- **Port**: 8000
- **Protocol**: HTTP
- **Health Check**: `/health` endpoint
- **Interval**: 30 seconds
- **Healthy Threshold**: 5
- **Unhealthy Threshold**: 2
- **Target Health**:
  - `i-03106a794959d37ab`: Healthy
  - `i-03c688b8cb17b7070`: NotInUse (standby)

**Auto Scaling Group:**
- **Name**: `cnt-backend-asg`
- **Min Size**: 1
- **Max Size**: 3
- **Desired Capacity**: 1
- **Target Group**: `cnt-backend-tg`

**RDS Database:**
- **Instance**: `cntdb`
- **Engine**: PostgreSQL 17.6
- **Status**: Available
- **Endpoint**: `cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com`
- **Port**: 5432
- **Connection String**: `postgresql+asyncpg://cntadmin:Christnew321@cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com:5432/cntdb`

**ElastiCache (Redis):**
- **Cluster**: `cnt-redis-cluster`
- **Engine**: Redis 7.1.0
- **Node Type**: cache.t3.micro
- **Status**: Available
- **Endpoint**: `cnt-redis-cluster.h94cmg.0001.euw2.cache.amazonaws.com:6379`
- **Purpose**: Socket.io adapter, session caching

**S3 Bucket:**
- **Name**: `cnt-web-media`
- **Region**: eu-west-2
- **Purpose**: Media file storage (audio, video, images, documents)

**CloudFront Distribution:**
- **Distribution ID**: `E3ER061DLFYFK8`
- **Domain**: `d126sja5o8ue54.cloudfront.net`
- **Origin**: `cnt-web-media.s3.eu-west-2.amazonaws.com`
- **Status**: Deployed
- **Purpose**: CDN for media files

**Amplify:**
- **App**: Frontend web application
- **Domain**: `christnewtabernacle.com` (and Amplify subdomain)
- **Build**: Flutter web build with environment variables

### 4.2 Docker Configuration

**Containers on EC2:**

1. **Backend Container** (`cnt-backend`):
   - **Image**: `cnt-web-deployment_backend:latest`
   - **Port**: 8000 (exposed to host)
   - **Network**: `cnt-network`
   - **Command**: `uvicorn app.main:app --host 0.0.0.0 --port 8000`
   - **Status**: Running (Up 56 minutes)
   - **Environment**: Production config with all API keys

2. **LiveKit Server** (`cnt-livekit-server`):
   - **Image**: `livekit/livekit-server:latest`
   - **Ports**: 
     - 7880 (WebSocket) - exposed
     - 7881 (HTTP API) - exposed
     - 50100-50200 (UDP RTP) - exposed
   - **Network**: `bridge` (default)
   - **Status**: Running (Up 32 hours, healthy)
   - **Config**: `/etc/livekit.yaml` (mounted from host)

3. **Voice Agent** (`cnt-voice-agent`):
   - **Image**: `8e2c9eeb3c85` (built from backend Dockerfile)
   - **Port**: 8000 (internal only, not exposed)
   - **Network**: `cnt-network`
   - **Command**: `python -m app.agents.voice_agent dev`
   - **Status**: Running (Up About an hour, healthy)
   - **Purpose**: AI voice assistant using LiveKit Agents

**Docker Networks:**
- **cnt-network**: Custom bridge network
  - Used by: `cnt-backend`, `cnt-voice-agent`
  - Purpose: Internal container communication
- **bridge**: Default Docker network
  - Used by: `cnt-livekit-server`
  - Purpose: Host network access for LiveKit

**Container Communication:**
- Backend → LiveKit: `http://livekit-server:7881` (internal)
- Voice Agent → LiveKit: `ws://livekit-server:7880` (internal)
- Frontend → LiveKit: `wss://livekit.christnewtabernacle.com` (external via Nginx)

### 4.3 Nginx Configuration

**LiveKit Nginx Config** (`/etc/nginx/sites-enabled/livekit`):
- **Domain**: `livekit.christnewtabernacle.com`
- **SSL**: Let's Encrypt (managed by Certbot)
- **Proxy**: `http://localhost:7880` (LiveKit WebSocket)
- **WebSocket Support**: Enabled with long timeouts (7 days)
- **Purpose**: SSL termination and WebSocket proxying for LiveKit

**Backend Nginx Config:**
- **Note**: No dedicated Nginx config found for backend
- **Reason**: Backend is accessed directly via ALB → EC2 port 8000
- **Alternative**: Backend may be accessed via ALB directly (no Nginx needed)

### 4.4 Network Flow

**Frontend → Backend:**
1. User browser → `christnewtabernacle.com` (Amplify)
2. Frontend makes API call → `API_BASE_URL` (ALB DNS)
3. ALB → Target Group → EC2:8000 (Backend container)

**Frontend → LiveKit:**
1. User browser → `wss://livekit.christnewtabernacle.com`
2. Nginx (EC2) → `localhost:7880` (LiveKit container)

**Backend → Database:**
1. Backend container → RDS endpoint:5432 (PostgreSQL)

**Backend → Redis:**
1. Backend container → ElastiCache endpoint:6379 (Redis)

**Backend → S3:**
1. Backend container → S3 API (boto3) → `cnt-web-media` bucket

**Media Delivery:**
1. User browser → CloudFront CDN → S3 bucket
2. CloudFront caches media files globally

**Voice Agent:**
1. Voice Agent container → LiveKit server (internal network)
2. LiveKit server → OpenAI API (external)
3. LiveKit server → Deepgram API (external)

### 4.5 Environment Variables (Production)

**Backend Container Environment:**
```
ENVIRONMENT=production
CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net
S3_BUCKET_NAME=cnt-web-media
DATABASE_URL=postgresql+asyncpg://cntadmin:Christnew321@cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com:5432/cntdb
OPENAI_API_KEY=sk-proj-...
DEEPGRAM_API_KEY=bfc440d4a7198f7c4a7441c2e2b3b1ca8725d6f9
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=http://livekit-server:7881
LIVEKIT_API_KEY=RvSL2BvFryECUIy2BELujY5E5mGUlSClNUZXPKWOJds
LIVEKIT_API_SECRET=NCXkii10fq8DZ7z7m5b_cOx52-bJNGW9jv-WfvbQCqI
CORS_ORIGINS=https://christnewtabernacle.com,https://www.christnewtabernacle.com,https://main.d1poes9tyirmht.amplifyapp.com,https://d1poes9tyirmht.amplifyapp.com
GOOGLE_CLIENT_ID=201135035530-52a8eiq39c0011gma0l0b6l1ekhho6bt.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=GOCSPX-...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_PUBLISHABLE_KEY=pk_test_...
FRONTEND_URL=https://christnewtabernacle.com
REDIS_URL=redis://cnt-redis-cluster.h94cmg.0001.euw2.cache.amazonaws.com:6379
```

---

## 5. Key Features & Functionality

### 5.1 Media Consumption
- **Podcasts**: Audio and video podcasts with categories
- **Movies**: Full-length movies and animated Bible stories
- **Music**: Music tracks with playlists
- **Documents**: PDF documents (Bible, etc.)
- **Playlists**: User-created playlists
- **Favorites**: Save favorite content
- **Search**: Full-text search across all content

### 5.2 Content Creation
- **Audio Podcasts**: Record, upload, edit audio
- **Video Podcasts**: Record, upload, edit video
- **Movies**: Upload full-length movies
- **Community Posts**: Text, image, and video posts
- **Quotes**: Create inspirational quote images
- **Drafts**: Save content as drafts before publishing

### 5.3 Social Features
- **Community Posts**: Testimonies, prayer requests, questions, announcements
- **Comments**: Threaded comments on posts
- **Likes**: Like/unlike posts
- **User Profiles**: Public user profiles
- **Artists**: Artist profiles with following system
- **Events**: Create and join events/meetings

### 5.4 Live Features
- **Live Streaming**: Real-time video streaming via LiveKit
- **Video Meetings**: Multi-participant video calls
- **Voice Chat**: Real-time voice communication
- **Voice Agent**: AI voice assistant for Christian content

### 5.5 Monetization
- **Donations**: Stripe payment processing
- **Stripe Connect**: Artist payment accounts
- **Bank Details**: User bank information storage
- **Commission Settings**: Platform commission configuration

### 5.6 Admin Features
- **Content Moderation**: Approve/reject user content
- **User Management**: User roles, permissions, deletion
- **Analytics Dashboard**: Usage statistics
- **Support System**: Ticket management
- **Google Drive Integration**: Import content from Google Drive

### 5.7 Notifications
- **Real-time Notifications**: Socket.io for live updates
- **Push Notifications**: Firebase Cloud Messaging (device tokens)
- **Email Notifications**: AWS SES for email delivery

---

## 6. Security & Best Practices

### 6.1 Security Measures
- **JWT Authentication**: Secure token-based auth
- **Password Hashing**: bcrypt for password storage
- **CORS**: Restricted origins in production
- **HTTPS**: Enforced via ALB and CloudFront
- **Environment Variables**: Sensitive data in environment, not code
- **Database**: Credentials in environment variables
- **API Keys**: Stored securely in environment

### 6.2 Scalability
- **Auto Scaling**: ASG scales 1-3 instances based on load
- **Load Balancing**: ALB distributes traffic
- **CDN**: CloudFront for global media delivery
- **Redis**: Caching and session management
- **Database**: RDS with connection pooling

### 6.3 Monitoring & Health Checks
- **ALB Health Checks**: `/health` endpoint every 30 seconds
- **Container Health Checks**: Docker health checks for containers
- **Target Health**: ALB monitors target health

---

## 7. Development Workflow

### 7.1 Local Development
- **Backend**: SQLite database, local media storage
- **Frontend**: Flutter web with local API URL
- **Docker Compose**: Available for local containerized setup
- **Environment**: `.env` file for local configuration

### 7.2 Production Deployment
- **Backend**: Docker containers on EC2
- **Frontend**: AWS Amplify (automatic builds on Git push)
- **Database**: RDS PostgreSQL
- **Media**: S3 + CloudFront

### 7.3 Database Migrations
- **Tool**: Alembic
- **Location**: `backend/migrations/`
- **Process**: Run migrations before deploying backend updates

---

## 8. API Communication Flow

### 8.1 Authentication Flow
1. User logs in → `POST /api/v1/auth/login`
2. Backend validates credentials → Returns access + refresh tokens
3. Frontend stores tokens → Includes in subsequent requests
4. Access token expires → Frontend uses refresh token
5. Backend validates refresh token → Returns new access token

### 8.2 Media Upload Flow
1. User selects file → Frontend validates file
2. Frontend uploads to → `POST /api/v1/upload/{type}`
3. Backend processes file → Uploads to S3
4. Backend creates database record → Returns content object
5. Frontend updates UI → Shows new content

### 8.3 Real-time Flow
1. User connects → Socket.io connection established
2. Backend sends events → User receives notifications
3. LiveKit connection → WebSocket to LiveKit server
4. Media streams → RTP over UDP (ports 50100-50200)

---

## 9. Known Configurations

### 9.1 Domain Configuration
- **Main Domain**: `christnewtabernacle.com`
- **LiveKit Subdomain**: `livekit.christnewtabernacle.com`
- **API**: Accessed via ALB DNS (not direct domain)

### 9.2 Port Configuration
- **Backend**: 8000 (HTTP)
- **LiveKit WebSocket**: 7880
- **LiveKit HTTP**: 7881
- **LiveKit RTP**: 50100-50200 (UDP)
- **PostgreSQL**: 5432
- **Redis**: 6379

### 9.3 Network Configuration
- **Backend & Voice Agent**: `cnt-network` (Docker bridge)
- **LiveKit**: `bridge` (default Docker network)
- **Communication**: Containers communicate via service names

---

## 10. Summary

The CNT Media Platform is a **production-ready, scalable Christian media application** with:

✅ **Complete Media Platform**: Podcasts, movies, music, documents  
✅ **Social Features**: Community posts, comments, likes, profiles  
✅ **Real-time Communication**: Live streaming, video meetings, voice chat  
✅ **AI Voice Agent**: Christian-focused AI assistant  
✅ **Content Creation**: Audio/video editing, upload, moderation  
✅ **Monetization**: Donations, Stripe Connect, commission system  
✅ **Admin Tools**: Content moderation, user management, analytics  
✅ **Scalable Infrastructure**: AWS ALB, Auto Scaling, CDN, RDS, Redis  
✅ **Production Security**: JWT auth, HTTPS, CORS, secure storage  

**Total API Endpoints**: ~150+ endpoints across 25 route modules  
**Database Tables**: 28 tables with complex relationships  
**Frontend Screens**: 107+ screen components  
**Docker Containers**: 3 containers (backend, LiveKit, voice agent)  
**AWS Services**: EC2, ALB, ASG, RDS, ElastiCache, S3, CloudFront, Amplify  

The application is **fully operational** and ready for feature enhancements, bug fixes, or optimizations.
