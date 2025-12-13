# CNT Media Platform - Complete Application Understanding

**Date:** December 12, 2025  
**Purpose:** Comprehensive understanding of the complete CNT Media Platform for future development tasks  
**Status:** Production-ready web application, mobile in development

---

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a full-stack Christian media application combining content consumption (Spotify-like), social features (Instagram/Facebook-like), and real-time communication (LiveKit). The web application is production-ready and deployed on AWS Amplify, with the backend running on AWS EC2.

### Technology Stack

**Frontend (Web):**
- Flutter Web (Dart 3.0+)
- Deployed on AWS Amplify
- URL: https://d1poes9tyirmht.amplifyapp.com
- State Management: Provider (13 providers)
- Navigation: GoRouter
- Media Players: just_audio, video_player
- Real-time: LiveKit Client, Socket.io

**Backend:**
- FastAPI (Python 3.11+)
- Deployed on AWS EC2 (52.56.78.203, eu-west-2)
- Running in Docker containers
- SSH: `ssh -i christnew.pem ubuntu@52.56.78.203`
- Path: `~/cnt-web-deployment/backend`

**Database:**
- PostgreSQL (AWS RDS - production)
- SQLite (local development)
- 21 tables with full relationships

**Media Storage:**
- AWS S3 bucket: `cnt-web-media`
- CloudFront CDN: https://d126sja5o8ue54.cloudfront.net
- Distribution ID: E3ER061DLFYFK8
- OAC ID: E1LSA9PF0Z69X7

**Real-time Services:**
- LiveKit Server (meetings, streaming, voice agent)
- WebSocket (notifications)

**AI Services:**
- OpenAI GPT-4o-mini (voice agent)
- Deepgram Nova-3 (STT), Aura-2 (TTS)

---

## 1. Database Schema (21 Tables)

### 1.1 Core User Tables

#### `users`
```sql
- id (PK, Integer)
- username (String, unique, nullable) - Auto-generated
- name (String, required)
- email (String, unique, required)
- avatar (String, nullable) - S3/CloudFront URL
- password_hash (String, nullable)
- is_admin (Boolean, default: False)
- phone, date_of_birth, bio (nullable)
- google_id (String, unique, nullable)
- auth_provider (String, default: 'email') - 'email', 'google', 'both'
- created_at, updated_at (DateTime)
```

**Relationships:**
- One-to-many: podcasts, support_messages, notifications, community_posts
- One-to-one: artist, bank_details, payment_account

#### `artists`
```sql
- id (PK, Integer)
- user_id (FK → users.id, unique, required)
- artist_name (String, nullable) - Defaults to user.name
- cover_image (String, nullable) - Banner image
- bio (Text, nullable)
- social_links (JSON, nullable)
- followers_count (Integer, default: 0)
- total_plays (Integer, default: 0)
- is_verified (Boolean, default: False)
- created_at, updated_at (DateTime)
```

**Auto-created** when user uploads content

#### `artist_followers`
```sql
- id (PK, Integer)
- artist_id (FK → artists.id)
- user_id (FK → users.id)
- created_at (DateTime)
- UNIQUE constraint on (artist_id, user_id)
```

### 1.2 Content Tables

#### `podcasts`
```sql
- id (PK, Integer)
- title (String, required)
- description (Text, nullable)
- audio_url (String, nullable) - S3: audio/{uuid}.{ext}
- video_url (String, nullable) - S3: video/{uuid}.{ext}
- cover_image (String, nullable) - S3: images/thumbnails/...
- creator_id (FK → users.id)
- category_id (FK → categories.id)
- duration (Integer, nullable) - Seconds
- status (String, default: "pending") - pending, approved, rejected
- plays_count (Integer, default: 0)
- created_at (DateTime)
```

**Approval Workflow:** Non-admin posts require admin approval

#### `movies`
```sql
- id (PK, Integer)
- title, description, video_url, cover_image
- preview_url (String, nullable)
- preview_start_time, preview_end_time (Integer, nullable)
- director, cast (String/Text, nullable)
- release_date (DateTime, nullable)
- rating (Float, nullable) - 0-10
- category_id, creator_id (FK)
- duration (Integer, nullable)
- status (String, default: "pending")
- plays_count (Integer, default: 0)
- is_featured (Boolean, default: False)
- created_at (DateTime)
```

#### `music_tracks`
```sql
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

#### `playlists` & `playlist_items`
```sql
playlists:
- id, user_id, name, description, cover_image, created_at

playlist_items:
- id, playlist_id, content_type, content_id, position
```

### 1.3 Community/Social Tables

#### `community_posts`
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

**Text Posts:** Auto-converted to styled quote images via `quote_image_service.py`

#### `comments`
```sql
- id, post_id, user_id, content, created_at
```

#### `likes`
```sql
- id, post_id, user_id, created_at
- UNIQUE constraint on (post_id, user_id)
```

### 1.4 Payment/Financial Tables

#### `bank_details`
```sql
- id, user_id (unique), account_number, ifsc_code, swift_code
- bank_name, account_holder_name, branch_name
- is_verified, created_at, updated_at
```

#### `payment_accounts`
```sql
- id, user_id (unique), provider, account_id, is_active
```

#### `donations`
```sql
- id, user_id, recipient_id, amount, currency
- status, payment_method, created_at
```

### 1.5 Other Tables

- `categories` - Content categories
- `live_streams` - Meeting/stream records
- `document_assets` - PDF documents (Bible, etc.)
- `support_messages` - Support tickets
- `bible_stories` - Bible story content
- `notifications` - User notifications
- `email_verification` - OTP verification
- `events` - Event management
- `event_attendees` - Event attendance
- `device_tokens` - Push notification tokens

---

## 2. S3 Bucket Structure

### Bucket Configuration
- **Name:** `cnt-web-media`
- **Region:** `eu-west-2` (London)
- **CloudFront:** https://d126sja5o8ue54.cloudfront.net

### Folder Structure
```
cnt-web-media/
├── audio/                      # Audio podcast files
│   └── {uuid}.{ext}           # MP3, WAV, WebM, M4A, AAC, FLAC
│
├── video/                      # Video podcast files
│   ├── {uuid}.{ext}           # MP4, WebM
│   └── previews/              # Preview clips
│
├── images/
│   ├── quotes/                # Generated quote images
│   │   └── quote_{post_id}_{hash}.jpg
│   ├── thumbnails/
│   │   ├── podcasts/
│   │   │   ├── custom/       # User-uploaded
│   │   │   └── generated/    # Auto-generated from video
│   │   └── default/          # Default templates (1-12.jpg)
│   ├── movies/               # Movie posters
│   ├── profiles/             # User avatars
│   └── {uuid}.{ext}          # Community post images
│
├── documents/                 # PDF documents
│   └── {filename}.pdf
│
└── animated-bible-stories/   # Bible story videos
    └── *.mp4
```

### Access Control
- **CloudFront OAC:** Public reads via CDN
- **EC2 IP Access:** Direct S3 access from 52.56.78.203
- **Backend:** Uses boto3 with AWS credentials from .env

---

## 3. Backend Architecture

### 3.1 API Routes (24 files)

Located in `backend/app/routes/`:

1. **auth.py** - Authentication (login, register, Google OAuth, OTP)
2. **users.py** - User management
3. **artists.py** - Artist profiles and follow system
4. **podcasts.py** - Podcast CRUD operations
5. **movies.py** - Movie management
6. **music.py** - Music track management
7. **community.py** - Community posts, likes, comments
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

### 3.2 Services (17 files)

Located in `backend/app/services/`:

1. **auth_service.py** - Password hashing, JWT tokens
2. **artist_service.py** - Artist profile management
3. **media_service.py** - File upload to S3, duration detection
4. **video_editing_service.py** - FFmpeg video editing
5. **audio_editing_service.py** - FFmpeg audio editing
6. **thumbnail_service.py** - Thumbnail generation
7. **quote_image_service.py** - Quote image generation (PIL/Pillow)
8. **quote_templates.py** - Quote image templates
9. **livekit_service.py** - LiveKit token generation
10. **payment_service.py** - Stripe/PayPal integration
11. **google_drive_service.py** - Google Drive uploads
12. **ai_service.py** - OpenAI integration
13. **username_service.py** - Unique username generation
14. **email_service.py** - AWS SES email sending
15. **firebase_push_service.py** - Push notifications
16. **notification_service.py** - Notification management
17. **jitsi_service.py** - Legacy (not used)

### 3.3 Key Endpoints

#### Authentication
- `POST /api/v1/auth/login` - Email/password login
- `POST /api/v1/auth/register` - User registration
- `POST /api/v1/auth/google-login` - Google OAuth
- `POST /api/v1/auth/send-otp` - Send OTP
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/check-username` - Check availability

#### Content
- `GET/POST /api/v1/podcasts` - List/create podcasts
- `GET/POST /api/v1/movies` - List/create movies
- `GET/POST /api/v1/music` - List/create music

#### Upload
- `POST /api/v1/upload/audio` - Upload audio
- `POST /api/v1/upload/video` - Upload video
- `POST /api/v1/upload/image` - Upload image
- `POST /api/v1/upload/profile-image` - Upload avatar
- `POST /api/v1/upload/thumbnail` - Upload thumbnail
- `POST /api/v1/upload/temporary-audio` - Temp audio for editing

#### Editing
- `POST /api/v1/audio-editing/trim` - Trim audio
- `POST /api/v1/audio-editing/merge` - Merge audio
- `POST /api/v1/audio-editing/fade-in-out` - Fade effects
- `POST /api/v1/video-editing/trim` - Trim video
- `POST /api/v1/video-editing/add-audio` - Add audio track
- `POST /api/v1/video-editing/remove-audio` - Remove audio
- `POST /api/v1/video-editing/add-text-overlays` - Text overlays

#### Community
- `GET/POST /api/v1/community/posts` - List/create posts
- `POST /api/v1/community/posts/{id}/like` - Like/unlike
- `POST /api/v1/community/posts/{id}/comments` - Add comment

#### Admin
- `GET /api/v1/admin/dashboard` - Admin stats
- `POST /api/v1/admin/approve/{type}/{id}` - Approve content
- `POST /api/v1/admin/reject/{type}/{id}` - Reject content

---

## 4. Web Frontend Architecture

### 4.1 Screens (39 web-specific screens)

Located in `web/frontend/lib/screens/web/`:

#### Core Screens
- `landing_screen_web.dart` - Landing page (65KB)
- `home_screen_web.dart` - Home dashboard (35KB)
- `about_screen_web.dart` - About page (20KB)

#### Content Screens
- `podcasts_screen_web.dart` - Podcast listing
- `movies_screen_web.dart` - Movie listing
- `movie_detail_screen_web.dart` - Movie details (28KB)
- `video_podcast_detail_screen_web.dart` - Video podcast details (29KB)
- `music_screen_web.dart` - Music player
- `audio_player_full_screen_web.dart` - Full-screen audio player (30KB)

#### Community Screens
- `community_screen_web.dart` - Social feed (15KB)
- `prayer_screen_web.dart` - Prayer requests
- `join_prayer_screen_web.dart` - Join prayer

#### Creation Screens
- `create_screen_web.dart` - Content creation hub (12KB)
- `video_recording_screen_web.dart` - Record video (26KB)
- `video_preview_screen_web.dart` - Preview before publish (40KB)
- `video_editor_screen_web.dart` - **Professional video editor (138KB)**

#### Live/Meeting Screens
- `live_screen_web.dart` - Live streaming hub (14KB)
- `stream_screen_web.dart` - Stream viewer
- `live_stream_options_screen_web.dart` - Stream setup
- `meetings_screen_web.dart` - Meeting list
- `meeting_options_screen_web.dart` - Meeting options
- `meeting_room_screen_web.dart` - LiveKit meeting room

#### User Screens
- `profile_screen_web.dart` - User profile (42KB)
- `library_screen_web.dart` - User library (17KB)
- `favorites_screen_web.dart` - Favorites
- `downloads_screen_web.dart` - Downloads
- `notifications_screen_web.dart` - Notifications

#### Voice Screens
- `voice_agent_screen_web.dart` - AI voice assistant (22KB)
- `voice_chat_screen_web.dart` - Voice chat

#### Admin Screens
- `admin_dashboard_web.dart` - Admin dashboard
- `admin_login_screen_web.dart` - Admin login (11KB)

#### Other Screens
- `search_screen_web.dart` - Search (15KB)
- `discover_screen_web.dart` - Content discovery
- `bible_stories_screen_web.dart` - Bible stories
- `support_screen_web.dart` - Support tickets
- `user_login_screen_web.dart` - User login (11KB)
- `register_screen_web.dart` - Registration (27KB)
- `not_found_screen_web.dart` - 404 page
- `offline_screen_web.dart` - Offline mode

### 4.2 State Management (13 Providers)

Located in `web/frontend/lib/providers/`:

1. **auth_provider.dart** - Authentication state (10KB)
2. **app_state.dart** - Global app state
3. **audio_player_provider.dart** - Audio playback (13KB)
4. **music_provider.dart** - Music library (5KB)
5. **community_provider.dart** - Community posts (5KB)
6. **search_provider.dart** - Search functionality (5KB)
7. **user_provider.dart** - User data (3KB)
8. **playlist_provider.dart** - Playlists
9. **favorites_provider.dart** - Favorites
10. **support_provider.dart** - Support tickets (4KB)
11. **documents_provider.dart** - Documents
12. **notification_provider.dart** - Notifications
13. **artist_provider.dart** - Artist profiles (6KB)

### 4.3 Services (10 files)

Located in `web/frontend/lib/services/`:

1. **api_service.dart** - REST API calls (100KB, 2864 lines)
2. **auth_service.dart** - Authentication (16KB)
3. **audio_editing_service.dart** - Audio editing API (12KB)
4. **video_editing_service.dart** - Video editing API (11KB)
5. **websocket_service.dart** - Real-time notifications (7KB)
6. **google_auth_service.dart** - Google OAuth (7KB)
7. **livekit_meeting_service.dart** - LiveKit meetings (10KB)
8. **livekit_voice_service.dart** - Voice agent (13KB)
9. **donation_service.dart** - Payments
10. **download_service.dart** - Offline downloads (5KB)

### 4.4 Navigation

**Router:** GoRouter-based navigation
**File:** `lib/navigation/app_router.dart`

**Key Features:**
- Multi-provider setup (13 providers)
- WebSocket initialization on startup
- Theme support (light/dark)
- Route guards for authentication

---

## 5. Key Features

### 5.1 Content Consumption

**Podcasts:**
- Audio and video podcasts
- Play counts tracking
- Artist profiles with follow system
- Category filtering
- Approval workflow for non-admin users

**Movies:**
- Full-length movies
- Preview clips
- Featured movies carousel
- Rating system
- Category filtering

**Music:**
- Music tracks with lyrics
- Album and genre organization
- Continuous playback
- Playlist support

**Bible Reader:**
- PDF document viewer
- Bible stories with audio
- Animated Bible stories

### 5.2 Content Creation

**Audio Podcast Creation:**
1. Record via browser MediaRecorder OR upload file
2. Preview with duration display
3. Edit (trim, merge, fade in/out)
4. Add title, description, category
5. Upload to S3
6. Submit for approval (non-admin users)

**Video Podcast Creation:**
1. Record via browser camera OR upload file
2. Preview with video player
3. Edit (trim, audio management, text overlays)
4. Auto-generate thumbnail from video
5. Upload to S3
6. Submit for approval

**Audio Editor Features:**
- Trim: Set start/end times
- Merge: Combine multiple files
- Fade In/Out: Volume effects
- State persistence (localStorage)
- Blob URL handling

**Video Editor Features:**
- Trim: Cut segments with timeline
- Audio: Remove/add/replace audio tracks
- Text Overlays: Add text at timestamps with customization
- State persistence
- Blob URL handling
- Timeline visualization

### 5.3 Social Features

**Community Posts:**
- Image posts (upload photos)
- Text posts (auto-generated quote images)
- Like/unlike functionality
- Comments system
- Post categories (testimony, prayer_request, question, announcement, general)
- Approval workflow

**Artist System:**
- Auto-created artist profiles
- Follow/unfollow artists
- Follower counts
- Total plays tracking
- Artist bio and social links
- Cover images

### 5.4 Real-Time Features

**LiveKit Integration:**
- Video meetings
- Live streaming (broadcaster/viewer)
- Voice agent (AI assistant)
- Token-based authentication

**WebSocket:**
- Real-time notifications
- Socket.io integration
- Auto-reconnection

### 5.5 Admin Features

**Admin Dashboard:**
- Content moderation (approve/reject)
- User management
- Support ticket handling
- Statistics dashboard
- Google Drive bulk upload

**Moderation Workflow:**
- Pending content review
- Approve/reject actions
- Status tracking
- Admin-only access

---

## 6. Deployment Architecture

### 6.1 Web Frontend (AWS Amplify)

**URL:** https://d1poes9tyirmht.amplifyapp.com

**Build Configuration** (`amplify.yml`):
```yaml
- Flutter SDK installation
- flutter pub get
- flutter build web --release
  --dart-define=API_BASE_URL=$API_BASE_URL
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL
  --dart-define=ENVIRONMENT=production
```

**Environment Variables:**
- API_BASE_URL: https://api.christnewtabernacle.com/api/v1
- MEDIA_BASE_URL: https://d126sja5o8ue54.cloudfront.net
- LIVEKIT_WS_URL: wss://livekit.christnewtabernacle.com
- LIVEKIT_HTTP_URL: https://livekit.christnewtabernacle.com
- WEBSOCKET_URL: wss://api.christnewtabernacle.com

### 6.2 Backend (AWS EC2)

**Instance:** 52.56.78.203 (eu-west-2)
**SSH:** `ssh -i christnew.pem ubuntu@52.56.78.203`
**Path:** `~/cnt-web-deployment/backend`

**Docker Containers:**
```bash
docker ps
# cnt-backend (port 8000)
# cnt-livekit-server (7880-7881, 50100-50200 UDP)
# cnt-voice-agent
```

**Backend Configuration** (`.env`):
- DATABASE_URL: PostgreSQL connection string
- S3_BUCKET_NAME: cnt-web-media
- CLOUDFRONT_URL: https://d126sja5o8ue54.cloudfront.net
- AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
- SECRET_KEY: JWT signing key
- LIVEKIT_WS_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET
- OPENAI_API_KEY, DEEPGRAM_API_KEY
- ENVIRONMENT: production

### 6.3 Database (AWS RDS)

**Type:** PostgreSQL
**Connection:** Via DATABASE_URL environment variable
**Local Dev:** SQLite (local.db)

### 6.4 Media Storage (AWS S3 + CloudFront)

**S3 Bucket:** cnt-web-media
**CloudFront:** d126sja5o8ue54.cloudfront.net
**Access:**
- CloudFront OAC for public reads
- EC2 IP whitelist for backend writes

---

## 7. Authentication & Security

### 7.1 Authentication Methods

**Email/Password:**
- JWT tokens (30-minute expiration)
- Password hashing with bcrypt
- Secure storage (flutter_secure_storage)

**Google OAuth:**
- Google Sign-In integration
- Auto-account creation
- Avatar download and upload to S3

**OTP Verification:**
- Email-based OTP
- AWS SES for email delivery
- Expiration tracking

### 7.2 Security Features

- JWT token validation middleware
- CORS configuration (production domains only)
- File type validation on uploads
- Unique filenames (UUID-based)
- S3 bucket policy restrictions
- Admin-only routes protection

---

## 8. Media URL Handling

### Development Mode
```dart
// Local files served from /media endpoint
// Example: http://localhost:8002/media/audio/file.mp3
```

### Production Mode
```dart
// Files served from CloudFront
// Example: https://d126sja5o8ue54.cloudfront.net/audio/file.mp3
// Backend stores relative paths: audio/file.mp3
// Frontend constructs full CloudFront URLs
```

**Media URL Resolution Logic:**
1. Check if already full URL (http/https) → return as-is
2. Check if contains CloudFront/S3 domain → add https://
3. Strip legacy 'media/' prefix for production
4. Construct CloudFront URL from relative path

---

## 9. File Upload Workflow

### Audio Upload
1. User records or uploads audio file
2. Frontend validates file type
3. Upload to backend: `POST /api/v1/upload/audio`
4. Backend generates UUID filename
5. Backend uploads to S3: `audio/{uuid}.{ext}`
6. Backend gets duration with FFprobe
7. Returns CloudFront URL
8. Frontend creates podcast record

### Video Upload
1. User records or uploads video file
2. Frontend validates file type
3. Upload to backend: `POST /api/v1/upload/video`
4. Backend generates UUID filename
5. Backend uploads to S3: `video/{uuid}.{ext}`
6. Backend auto-generates thumbnail (45s mark)
7. Thumbnail saved to S3: `images/thumbnails/podcasts/generated/`
8. Returns CloudFront URLs
9. Frontend creates podcast record

### Image Upload (Community Posts)
1. User selects image or takes photo
2. Upload to backend: `POST /api/v1/upload/image`
3. Backend uploads to S3: `images/{uuid}.{ext}`
4. Returns CloudFront URL
5. Frontend creates community post

### Text Post (Quote Image)
1. User enters text content
2. Create post: `POST /api/v1/community/posts`
3. Backend detects post_type='text'
4. Backend generates quote image (PIL/Pillow)
5. Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
6. Updates post with image_url
7. Returns CloudFront URL

---

## 10. Editing Capabilities

### Audio Editing (FFmpeg)
- **Trim:** Cut start/end with precise timestamps
- **Merge:** Concatenate multiple audio files
- **Fade In:** Gradual volume increase
- **Fade Out:** Gradual volume decrease
- **Fade In/Out:** Both effects combined

### Video Editing (FFmpeg)
- **Trim:** Cut segments with timeline
- **Remove Audio:** Strip audio track
- **Add Audio:** Add new audio track
- **Replace Audio:** Replace existing audio
- **Text Overlays:** Add text at timestamps with:
  - Position (x, y coordinates)
  - Font family and size
  - Color and background color
  - Alignment (left, center, right)
  - Start/end times
- **Filters:** Brightness, contrast, saturation (web only)

---

## 11. Real-Time Communication

### LiveKit Features
- **Video Meetings:** Multi-participant video calls
- **Live Streaming:** Broadcaster and viewer modes
- **Voice Agent:** AI assistant with STT/TTS
- **Token Authentication:** Secure room access

### WebSocket Features
- **Notifications:** Real-time user notifications
- **Socket.io:** Bidirectional communication
- **Auto-reconnection:** Connection resilience

---

## 12. Dependencies

### Web Frontend (pubspec.yaml)
**Key Packages:**
- provider: ^6.1.1 (state management)
- http: ^1.1.0 (API calls)
- socket_io_client: ^2.0.3+1 (WebSocket)
- just_audio: ^0.9.36 (audio player)
- video_player: ^2.8.2 (video player)
- camera: ^0.10.5+2 (web recording)
- livekit_client: ^2.1.0 (real-time)
- go_router: ^13.0.0 (navigation)
- google_sign_in: ^6.2.1 (OAuth)
- flutter_stripe: ^10.1.1 (payments)

### Backend (requirements.txt)
**Key Packages:**
- fastapi (web framework)
- sqlalchemy (ORM)
- boto3 (AWS S3)
- python-jose (JWT)
- passlib (password hashing)
- livekit (real-time)
- openai (AI)
- deepgram-sdk (STT/TTS)
- pillow (image generation)
- ffmpeg-python (media editing)

---

## 13. Current Status

### Production Ready ✅
- Web frontend deployed on Amplify
- Backend running on EC2
- Database on AWS RDS
- Media storage on S3 + CloudFront
- All core features functional
- Admin moderation system
- Real-time features (LiveKit)

### In Development 🚧
- Mobile application (code complete, awaiting store submission)

### Known Issues ⚠️
- No upload progress indicators for large files
- No explicit file size limits in frontend
- Temporary files may accumulate on failed uploads

### Recommended Improvements 💡
1. Add upload progress bars
2. Implement chunked uploads for large files
3. Add file size validation
4. Add retry logic for failed uploads
5. Cleanup temporary files on failure

---

## 14. Access Information

### Web Application
- **URL:** https://d1poes9tyirmht.amplifyapp.com
- **Admin Login:** Available at /admin-login

### Backend API
- **URL:** https://api.christnewtabernacle.com
- **Health Check:** https://api.christnewtabernacle.com/health
- **API Docs:** https://api.christnewtabernacle.com/docs

### EC2 Backend
- **SSH:** `ssh -i /home/phi/Phi-Intelligence/cnt-web-deployment/christnew.pem ubuntu@52.56.78.203`
- **Path:** `~/cnt-web-deployment/backend`
- **Logs:** Check Docker container logs

### Database
- **Production:** PostgreSQL on AWS RDS
- **Local:** SQLite at `backend/local.db`

### Media Storage
- **S3 Bucket:** cnt-web-media
- **CloudFront:** https://d126sja5o8ue54.cloudfront.net
- **AWS CLI:** Installed on local machine

---

## 15. Development Workflow

### Local Development

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

### Deployment

**Web Frontend:**
- Push to GitHub
- Amplify auto-deploys from main branch
- Environment variables configured in Amplify console

**Backend:**
- SSH to EC2
- Pull latest changes
- Rebuild Docker containers
- Restart services

---

## 16. Summary

The CNT Media Platform is a **production-ready, full-featured Christian media application** with:

✅ **Complete Backend API** - 24 route files, 17 services, 100+ endpoints  
✅ **Comprehensive Database** - 21 tables with full relationships  
✅ **Modern Web Frontend** - 39 screens, 13 providers, 10 services  
✅ **Cloud Infrastructure** - AWS EC2, RDS, S3, CloudFront, Amplify  
✅ **Media Management** - Upload, editing, streaming, storage  
✅ **Social Features** - Posts, likes, comments, follow system  
✅ **Real-Time Communication** - LiveKit meetings, streaming, voice agent  
✅ **Admin System** - Content moderation, user management  
✅ **Security** - JWT auth, Google OAuth, OTP verification  

**Ready for:** Feature enhancements, bug fixes, mobile app completion, scaling

---

**End of Document**
