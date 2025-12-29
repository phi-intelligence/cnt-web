# CNT Media Platform - Complete Application Analysis

## Executive Summary

The **Christ New Tabernacle (CNT) Media Platform** is a comprehensive Christian media application built with Flutter (mobile/web) and FastAPI (backend). It provides a Spotify-like media consumption experience combined with social features (Instagram/Facebook-like) and real-time communication capabilities (LiveKit).

**Key Technologies:**
- **Frontend (Mobile)**: Flutter/Dart - iOS & Android apps
- **Frontend (Web)**: Flutter/Dart - Web application deployed on AWS Amplify
- **Backend**: FastAPI (Python) with SQLAlchemy ORM
- **Database**: PostgreSQL (production via AWS RDS), SQLite (local development)
- **Media Storage**: AWS S3 + CloudFront CDN
- **Backend Hosting**: AWS EC2 (eu-west-2)
- **Real-time**: LiveKit (meetings, live streaming, voice agent)
- **AI Services**: OpenAI GPT-4o-mini, Deepgram (STT/TTS)

---

## 1. Database Schema Analysis

### 1.1 Core User Models

#### Users Table (`users`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `username` (String, unique, nullable) - Auto-generated unique username
  - `name` (String, required)
  - `email` (String, unique, required)
  - `avatar` (String, nullable) - Profile image URL
  - `password_hash` (String, nullable) - For email/password auth
  - `is_admin` (Boolean, default: False)
  - `phone` (String, nullable)
  - `date_of_birth` (DateTime, nullable)
  - `bio` (Text, nullable)
  - `google_id` (String, unique, nullable) - For Google OAuth
  - `auth_provider` (String, default: 'email') - 'email', 'google', or 'both'
  - `created_at`, `updated_at` (DateTime)

#### Artists Table (`artists`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `user_id` (Integer, ForeignKey to users, unique, required)
  - `artist_name` (String, nullable) - Defaults to user.name if not set
  - `cover_image` (String, nullable) - Banner/header image
  - `bio` (Text, nullable)
  - `social_links` (JSON, nullable) - Social media URLs object
  - `followers_count` (Integer, default: 0)
  - `total_plays` (Integer, default: 0) - Aggregate podcast plays
  - `is_verified` (Boolean, default: False)
  - `created_at`, `updated_at` (DateTime)

**Relationship**: Auto-created when user uploads content
**Follow System**: `artist_followers` table tracks user-artist follow relationships

---

### 1.2 Content Models

#### Podcasts Table (`podcasts`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `title` (String, required)
  - `description` (Text, nullable)
  - `audio_url` (String, nullable) - Relative path to audio file
  - `video_url` (String, nullable) - Relative path to video file
  - `cover_image` (String, nullable) - Thumbnail URL
  - `creator_id` (Integer, ForeignKey to users, nullable)
  - `category_id` (Integer, ForeignKey to categories, nullable)
  - `duration` (Integer, nullable) - Duration in seconds
  - `status` (String, default: "pending") - pending, approved, rejected
  - `plays_count` (Integer, default: 0)
  - `created_at` (DateTime)

**Approval Workflow**: Non-admin posts require approval, admin posts auto-approved

#### Movies Table (`movies`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `title`, `description`, `video_url`, `cover_image` (String)
  - `preview_url` (String, nullable) - Optional pre-generated preview clip
  - `preview_start_time`, `preview_end_time` (Integer, nullable) - Preview window in seconds
  - `director`, `cast` (String/Text, nullable)
  - `release_date` (DateTime, nullable)
  - `rating` (Float, nullable) - User rating 0-10
  - `category_id`, `creator_id` (Integer, ForeignKey)
  - `duration` (Integer, nullable) - Total duration in seconds
  - `status` (String, default: "pending")
  - `plays_count` (Integer, default: 0)
  - `is_featured` (Boolean, default: False) - For hero carousel
  - `created_at` (DateTime)

#### Music Tracks Table (`music_tracks`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `title`, `artist`, `album`, `genre` (String)
  - `audio_url` (String, required)
  - `cover_image` (String, nullable)
  - `duration` (Integer, nullable)
  - `lyrics` (Text, nullable)
  - `is_featured`, `is_published` (Boolean)
  - `plays_count` (Integer, default: 0)
  - `created_at` (DateTime)

#### Playlists Table (`playlists`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `user_id` (Integer, ForeignKey to users, required)
  - `name` (String, required)
  - `description` (Text, nullable)
  - `cover_image` (String, nullable)
  - `created_at` (DateTime)

#### Playlist Items Table (`playlist_items`)
- Links content to playlists
- `content_type` (String) - "podcast", "music", etc.
- `content_id` (Integer) - ID of the content item
- `position` (Integer) - Order in playlist

---

### 1.3 Community/Social Models

#### Community Posts Table (`community_posts`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `user_id` (Integer, ForeignKey to users, required)
  - `title` (String, required)
  - `content` (Text, required)
  - `image_url` (String, nullable) - Photo URL or generated quote image URL
  - `category` (String, required) - testimony, prayer_request, question, announcement, general
  - `post_type` (String, default: 'image') - 'image' or 'text'
  - `is_approved` (Integer, default: 0) - 0=False, 1=True (SQLite boolean)
  - `likes_count`, `comments_count` (Integer, default: 0)
  - `created_at` (DateTime)

**Text Posts**: Automatically converted to styled quote images via `quote_image_service.py`

#### Comments Table (`comments`)
- Links to community posts
- `post_id`, `user_id` (Integer, ForeignKey)
- `content` (Text, required)
- `created_at` (DateTime)

#### Likes Table (`likes`)
- Links users to posts they liked
- `post_id`, `user_id` (Integer, ForeignKey)
- `created_at` (DateTime)
- **Unique constraint** on (post_id, user_id) to prevent duplicates

---

### 1.4 Payment/Financial Models

#### Bank Details Table (`bank_details`)
- **Primary Key**: `id` (Integer)
- **Fields**:
  - `user_id` (Integer, ForeignKey to users, unique, required)
  - `account_number` (String, required) - Should be encrypted
  - `ifsc_code`, `swift_code`, `bank_name`, `account_holder_name`, `branch_name` (String)
  - `is_verified` (Boolean, default: False)
  - `created_at`, `updated_at` (DateTime)

**Purpose**: Creator payment information for revenue sharing

#### Payment Accounts Table (`payment_accounts`)
- Alternative payment gateway accounts (Stripe, PayPal)
- `user_id` (Integer, ForeignKey, unique)
- `provider` (String) - 'stripe', 'paypal'
- `account_id` (String)
- `is_active` (Boolean)

#### Donations Table (`donations`)
- Tracks donation transactions
- `user_id`, `recipient_id` (Integer, ForeignKey)
- `amount` (Float)
- `currency` (String)
- `status` (String) - pending, completed, failed
- `payment_method` (String)
- `created_at` (DateTime)

---

### 1.5 Other Models

#### Categories Table (`categories`)
- `id`, `name` (String), `type` (String) - podcast, music, community, etc.

#### Live Streams Table (`live_streams`)
- Meeting/stream records
- Links to LiveKit rooms
- `user_id`, `title`, `description`, `status`, `room_name`, `started_at`, `ended_at`

#### Document Assets Table (`document_assets`)
- PDF documents (Bible, etc.)
- `title`, `file_url`, `file_type`, `file_size`
- Admin-only uploads

#### Support Messages Table (`support_messages`)
- Support ticket system
- `user_id`, `subject`, `message`, `status`, `admin_response`, `created_at`

#### Bible Stories Table (`bible_stories`)
- `title`, `scripture_reference`, `content`, `audio_url`, `cover_image`, `created_at`

#### Notifications Table (`notifications`)
- User notifications
- `user_id`, `type` (enum), `title`, `message`, `data` (JSON), `is_read`, `created_at`

---

## 2. Authentication & User Registration

### 2.1 Authentication Methods

1. **Email/Password Login**
   - Endpoint: `POST /api/v1/auth/login`
   - Accepts `email` or `username` + `password`
   - Returns JWT access token (30-minute expiration)
   - Token stored in secure storage (flutter_secure_storage)

2. **Google OAuth**
   - Endpoint: `POST /api/v1/auth/google-login`
   - Supports both `id_token` and `access_token`
   - Auto-creates user account if first login
   - Links to existing account if email matches

3. **User Registration**
   - Endpoint: `POST /api/v1/auth/register`
   - Required: `email`, `password`, `name`
   - Optional: `phone`, `date_of_birth`, `bio`
   - Auto-generates unique `username` via `username_service.py`
   - Returns JWT token and user data

### 2.2 Username Generation

- Automatic unique username generation on registration
- Format: Based on name + random suffix if needed
- Check availability: `POST /api/v1/auth/check-username`

### 2.3 Token Management

- **Storage**: flutter_secure_storage (mobile), localStorage (web)
- **Expiration**: 30 minutes (configurable via `ACCESS_TOKEN_EXPIRE_MINUTES`)
- **Refresh**: Not implemented (user re-authenticates)
- **Middleware**: `auth_middleware.py` validates tokens on protected routes

---

## 3. S3 Bucket Structure & File Uploads

### 3.1 S3 Bucket Configuration

- **Bucket Name**: `cnt-web-media`
- **Region**: `eu-west-2` (London)
- **Access Method**: 
  - CloudFront OAC (Origin Access Control) for public reads
  - Server IP (52.56.78.203) for backend uploads
- **CloudFront URL**: `https://d126sja5o8ue54.cloudfront.net`
- **Distribution ID**: `E3ER061DLFYFK8`
- **OAC ID**: `E1LSA9PF0Z69X7`

### 3.2 S3 Folder Structure

```
cnt-web-media/
├── audio/                      # Audio podcast files
│   └── {uuid}.{ext}           # MP3, WAV, WebM, etc.
├── video/                      # Video podcast files
│   ├── {uuid}.{ext}           # MP4, WebM, etc.
│   └── previews/              # Short preview clips (optional)
├── images/
│   ├── quotes/                # Generated quote images
│   │   └── quote_{post_id}_{hash}.jpg
│   ├── thumbnails/
│   │   ├── podcasts/
│   │   │   ├── custom/        # User-uploaded thumbnails
│   │   │   └── generated/     # Auto-generated from video
│   │   └── default/           # Default thumbnail templates (1-12.jpg)
│   ├── movies/                # Movie posters/cover images
│   └── {uuid}.{ext}           # General images (community posts, etc.)
├── documents/                 # PDF documents (Bible, etc.)
│   └── {filename}.pdf
└── animated-bible-stories/    # Video files for Bible stories
    └── *.mp4
```

### 3.3 Upload Mechanisms

#### Development Mode (Local)
- Files stored in `backend/media/` directory
- Backend serves via `/media` endpoint
- Same folder structure as S3

#### Production Mode (S3)
- Files uploaded via `boto3` client
- Uses `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` from EC2 .env
- Uploads directly to S3 bucket
- Returns CloudFront URL

### 3.4 Upload Endpoints

1. **Audio Upload**: `POST /api/v1/upload/audio`
   - Requires authentication
   - Optional thumbnail upload
   - Returns: `filename`, `url`, `file_path`, `duration`, `thumbnail_url`

2. **Video Upload**: `POST /api/v1/upload/video`
   - Requires authentication
   - Auto-generates thumbnail if `generate_thumbnail=true`
   - Returns: `filename`, `url`, `file_path`, `duration`, `thumbnail_url`

3. **Image Upload**: `POST /api/v1/upload/image`
   - Requires authentication
   - Returns: `filename`, `url`, `content_type`

4. **Profile Image**: `POST /api/v1/upload/profile-image`
   - Updates user avatar
   - Saves to `images/profiles/` subfolder

5. **Thumbnail Upload**: `POST /api/v1/upload/thumbnail`
   - Custom thumbnail for podcasts
   - Saves to `images/thumbnails/podcasts/custom/`

6. **Temporary Audio**: `POST /api/v1/upload/temporary-audio`
   - For editing workflows (no bank details required)
   - Saves as `temp_{uuid}.{ext}`

7. **Document Upload**: `POST /api/v1/upload/document`
   - Admin-only
   - PDF documents only
   - Saves to `documents/`

### 3.5 EC2 Backend S3 Access

**Configuration**:
- Backend uses `boto3` client initialized on startup
- Credentials from environment variables:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `AWS_REGION=eu-west-2`
  - `S3_BUCKET_NAME=cnt-web-media`

**Permissions Required**:
- `s3:PutObject` - Upload files
- `s3:GetObject` - Read/download files (for editing)
- `s3:ListBucket` - List objects (for thumbnail defaults)

**Current Setup**: EC2 has direct S3 access via IAM credentials

---

## 4. Mobile Application Structure

### 4.1 Navigation

**Main Bottom Tab Navigation** (5 tabs):
1. **Home** - Featured content, podcasts, movies carousel
2. **Search** - Content discovery
3. **Create** - Content creation hub (audio/video/quote)
4. **Community** - Social feed with posts
5. **Profile** - User profile, settings, library

### 4.2 Mobile Screens

#### Core Screens (`screens/mobile/`)
- `home_screen_mobile.dart` - Layered UI with carousel and parallax
- `discover_screen_mobile.dart` - Content discovery
- `podcasts_screen_mobile.dart` - Podcast listing
- `music_screen_mobile.dart` - Music player
- `community_screen_mobile.dart` - Social feed
- `create_screen_mobile.dart` - Content creation hub
- `library_screen_mobile.dart` - User library
- `profile_screen_mobile.dart` - User profile
- `search_screen_mobile.dart` - Search functionality
- `live_screen_mobile.dart` - Live streaming
- `meeting_options_screen_mobile.dart` - Meeting options
- `bible_stories_screen_mobile.dart` - Bible stories
- `quote_create_screen_mobile.dart` - Quote post creation
- `voice_chat_modal.dart` - Voice agent modal
- `downloads_screen_mobile.dart` - Offline downloads
- `favorites_screen_mobile.dart` - User favorites
- `notifications_screen_mobile.dart` - Notifications

#### Content Creation (`screens/creation/`)
- `audio_podcast_create_screen.dart` - Choose record or upload
- `audio_recording_screen.dart` - Record audio
- `audio_preview_screen.dart` - Preview before publishing
- `video_podcast_create_screen.dart` - Choose record or gallery
- `video_recording_screen.dart` - Record video
- `video_preview_screen.dart` - Preview before publishing

#### Audio/Video Players
- `audio_player_full_screen_new.dart` - Full-screen audio player
- `video_player_full_screen.dart` - Full-screen video player

#### Editing (`screens/editing/`)
- `audio_editor_screen.dart` - Trim, merge, fade audio
- `video_editor_screen.dart` - Trim, remove audio, add overlays

#### Community (`screens/community/`)
- `create_post_screen.dart` - Create image or text post
- `comment_screen.dart` - View/add comments

#### Live/Meeting (`screens/live/`, `screens/meeting/`)
- `live_stream_broadcaster.dart` - Host broadcast interface
- `live_stream_viewer.dart` - Viewer interface
- `stream_creation_screen.dart` - Setup stream
- `meeting_room_screen.dart` - LiveKit meeting room
- `join_meeting_screen.dart` - Join meeting
- `schedule_meeting_screen.dart` - Schedule future meeting

#### Admin (`screens/admin/`)
- 7 admin pages for content moderation and management

### 4.3 Mobile Providers (State Management)

Located in `lib/providers/`:
1. `app_state.dart` - Global app state
2. `auth_provider.dart` - Authentication state
3. `artist_provider.dart` - Artist profile management
4. `audio_player_provider.dart` - Audio playback state
5. `community_provider.dart` - Community posts
6. `documents_provider.dart` - Documents/Bible
7. `favorites_provider.dart` - User favorites
8. `music_provider.dart` - Music playback
9. `notification_provider.dart` - Push notifications
10. `playlist_provider.dart` - Playlists
11. `search_provider.dart` - Search functionality
12. `support_provider.dart` - Support tickets
13. `user_provider.dart` - User data

### 4.4 Mobile Services

Located in `lib/services/`:
1. `api_service.dart` - REST API calls, media URL handling
2. `auth_service.dart` - Authentication (login, register, Google OAuth)
3. `websocket_service.dart` - Real-time notifications
4. `donation_service.dart` - Payment processing
5. `download_service.dart` - Offline downloads (SQLite cache)
6. `google_auth_service.dart` - Google OAuth
7. `livekit_meeting_service.dart` - LiveKit meetings
8. `livekit_voice_service.dart` - Voice agent
9. `video_editing_service.dart` - Video editing API calls
10. `audio_editing_service.dart` - Audio editing API calls

### 4.5 Media URL Handling

**File**: `mobile/frontend/lib/services/api_service.dart`

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

**Development**: Uses localhost URLs  
**Production**: Uses CloudFront URLs from `.env`

---

## 5. File Upload Features

### 5.1 Audio Podcast Upload

**Flow**:
1. User selects "Audio Podcast" from Create screen
2. Options: Record audio OR Upload file
3. If recording: Uses device microphone via `record` package
4. If uploading: File picker (MP3, WAV, WebM, etc.)
5. Preview screen shows duration, allows editing
6. Upload to backend: `POST /api/v1/upload/audio`
7. Backend saves to S3: `audio/{uuid}.{ext}`
8. Create podcast record: `POST /api/v1/podcasts`
9. Status: "pending" (requires admin approval unless user is admin)

**Requirements**:
- Authentication required
- Bank details optional (soft warning, not blocking)

### 5.2 Video Podcast Upload

**Flow**:
1. User selects "Video Podcast" from Create screen
2. Options: Record video OR Choose from gallery
3. If recording: Uses device camera via `camera` package
4. If gallery: Image picker for video files
5. Preview screen shows video, allows editing
6. Upload to backend: `POST /api/v1/upload/video`
7. Backend saves to S3: `video/{uuid}.{ext}`
8. Auto-generates thumbnail if not provided
9. Create podcast record: `POST /api/v1/podcasts`
10. Status: "pending" (requires admin approval)

**Thumbnail Generation**:
- Automatic from video at 45 seconds (or 10% of duration)
- Saved to `images/thumbnails/podcasts/generated/`
- User can upload custom thumbnail later

### 5.3 Image Upload (Community Posts)

**Flow**:
1. User creates post from Community screen
2. Select "Image Post" type
3. Choose photo from gallery or take photo
4. Add caption
5. Upload image: `POST /api/v1/upload/image`
6. Backend saves to S3: `images/{uuid}.{ext}`
7. Create post: `POST /api/v1/community/posts`
8. Status: "pending" (requires admin approval)

### 5.4 Text Post (Quote Image Generation)

**Flow**:
1. User creates post, selects "Text Post" type
2. Enter text content
3. Create post: `POST /api/v1/community/posts` (no image yet)
4. Backend detects `post_type='text'`
5. Calls `generate_quote_image()` service
6. Service:
   - Selects random template from `quote_templates.py`
   - Renders text with PIL/Pillow
   - Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
   - Updates post with `image_url`
7. Returns CloudFront URL

**Templates**: Predefined styles with backgrounds, fonts, colors

### 5.5 Profile Image Upload

**Flow**:
1. User edits profile
2. Select new avatar image
3. Upload: `POST /api/v1/upload/profile-image`
4. Backend saves to S3: `images/profiles/profile_{uuid}.{ext}`
5. Updates user record with new `avatar` URL

---

## 6. Content Creation Workflow

### 6.1 Podcast Creation Process

**Step 1: Record/Upload**
- Mobile: Record via device OR upload file
- Web: Record via browser OR upload file
- Temporary files stored for editing

**Step 2: Preview & Edit**
- Preview screen shows metadata (duration, file size)
- Option to edit (trim, fade, etc.)
- Editing uses backend FFmpeg services

**Step 3: Add Details**
- Title, description
- Category selection
- Thumbnail selection (default or custom)

**Step 4: Upload**
- Final file upload to S3
- Create podcast record in database
- Status: "pending" for non-admin users

**Step 5: Approval**
- Admin reviews in Admin Dashboard
- Approve/Reject actions
- Approved podcasts visible to all users

### 6.2 Editing Capabilities

#### Audio Editing
- **Trim**: `POST /api/v1/audio-editing/trim` - Cut start/end
- **Merge**: `POST /api/v1/audio-editing/merge` - Combine files
- **Fade In/Out**: `POST /api/v1/audio-editing/fade-in-out`

#### Video Editing
- **Trim**: `POST /api/v1/video-editing/trim` - Cut segments
- **Remove Audio**: `POST /api/v1/video-editing/remove-audio`
- **Add Audio**: `POST /api/v1/video-editing/add-audio`
- **Text Overlays**: `POST /api/v1/video-editing/add-text-overlays`

**All editing uses FFmpeg on backend**

---

## 7. Cloud-Friendly Setup Analysis

### 7.1 Backend S3 Access ✅

**Current Status**: **PROPERLY CONFIGURED**

- EC2 backend has AWS credentials in `.env`
- Uses `boto3` client for S3 operations
- All file uploads go directly to S3
- CloudFront serves files via CDN

**Bucket Policy**:
- Allows CloudFront OAC access (public reads)
- Allows EC2 server IP (52.56.78.203) access
- Secure and cloud-native setup

### 7.2 User Upload Process ✅

**Status**: **FULLY FUNCTIONAL**

1. **Images**: Users can upload images easily
   - Community posts: Direct upload to S3
   - Profile images: Direct upload to S3
   - Works seamlessly in production

2. **Audio Podcasts**: Users can upload audio
   - Record or upload file
   - Backend uploads to S3: `audio/{uuid}.{ext}`
   - Returns CloudFront URL
   - Fully functional

3. **Video Podcasts**: Users can upload video
   - Record or upload from gallery
   - Backend uploads to S3: `video/{uuid}.{ext}`
   - Auto-generates thumbnails
   - Returns CloudFront URL
   - Fully functional

### 7.3 Media URL Resolution ✅

**Development Mode**:
- Local files served from `/media` endpoint
- Paths include `/media/` prefix

**Production Mode**:
- Files served from CloudFront
- Direct S3 path mapping (no `/media/` prefix)
- Frontend handles URL resolution correctly

### 7.4 Issues/Improvements

**Potential Issues**:
1. **No file size limits** enforced in frontend (backend may have limits)
2. **No progress indicators** for large video uploads (may timeout)
3. **Temporary files** may accumulate if upload fails mid-process

**Recommendations**:
1. Add upload progress indicators
2. Implement chunked uploads for large files
3. Add file size validation (frontend + backend)
4. Implement retry logic for failed uploads

---

## 8. Web Application Features (Reference)

### 8.1 Web Screens

Located in `web/frontend/lib/screens/web/`:
- 35+ web-specific screens
- Similar functionality to mobile
- Responsive design for desktop/tablet

### 8.2 Key Differences

- **Build**: Uses `--dart-define` flags (no `.env` file)
- **Deployment**: AWS Amplify
- **Media URLs**: Different handling (keeps `/media/` in dev)

---

## 9. Environment Configuration

### 9.1 Mobile App (.env)

**Production** (`mobile/frontend/.env`):
```env
ENVIRONMENT=production
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
WEBSOCKET_URL=wss://api.christnewtabernacle.com
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
```

**Development**: Auto-detects localhost (or 10.0.2.2 on Android emulator)

### 9.2 Backend (.env)

**Production** (`backend/.env`):
- `DATABASE_URL` - PostgreSQL connection string
- `S3_BUCKET_NAME=cnt-web-media`
- `CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net`
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- `SECRET_KEY` - JWT signing key
- `LIVEKIT_WS_URL`, `LIVEKIT_HTTP_URL`, `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`
- `OPENAI_API_KEY`, `DEEPGRAM_API_KEY`
- `ENVIRONMENT=production`

---

## 10. Key Features Summary

### 10.1 Content Consumption
- ✅ Podcasts (audio/video) with play counts
- ✅ Movies with preview clips
- ✅ Music tracks
- ✅ Bible reader (PDF viewer)
- ✅ Playlists
- ✅ Offline downloads (mobile)

### 10.2 Content Creation
- ✅ Audio podcast recording/upload
- ✅ Video podcast recording/upload
- ✅ Audio editing (trim, merge, fade)
- ✅ Video editing (trim, overlays, audio)
- ✅ Community posts (images)
- ✅ Quote posts (auto-generated images)

### 10.3 Social Features
- ✅ Community feed (Instagram-like)
- ✅ Like/unlike posts
- ✅ Comments on posts
- ✅ Artist profiles with follow system
- ✅ User profiles

### 10.4 Real-Time Features
- ✅ Live streaming (broadcaster/viewer)
- ✅ Video meetings (LiveKit)
- ✅ Voice agent (AI assistant)
- ✅ Real-time notifications (WebSocket)

### 10.5 Admin Features
- ✅ Content moderation (approve/reject)
- ✅ User management
- ✅ Support ticket handling
- ✅ Bulk upload from Google Drive

---

## 11. Database Tables Summary

| Table | Primary Purpose |
|-------|----------------|
| `users` | User accounts and authentication |
| `artists` | Creator profiles (auto-created) |
| `artist_followers` | Follow relationships |
| `podcasts` | Audio/video podcast content |
| `movies` | Full-length movie content |
| `music_tracks` | Music content |
| `community_posts` | Social media posts |
| `likes` | Post likes |
| `comments` | Post comments |
| `categories` | Content categories |
| `playlists` | User playlists |
| `playlist_items` | Playlist content links |
| `bank_details` | Creator payment info |
| `payment_accounts` | Payment gateway accounts |
| `donations` | Donation transactions |
| `live_streams` | Meeting/stream records |
| `document_assets` | Bible/PDF documents |
| `support_messages` | Support tickets |
| `bible_stories` | Bible story content |
| `notifications` | User notifications |
| `email_verification` | Email verification tokens |

**Total: 21 tables**

---

## 12. API Routes Summary

### Authentication (`/api/v1/auth`)
- `POST /login` - Email/password login
- `POST /register` - User registration
- `POST /google-login` - Google OAuth
- `POST /check-username` - Username availability
- `GET /google-client-id` - Get OAuth client ID

### Content
- `GET/POST /podcasts` - List/create podcasts
- `GET/POST /movies` - List/create movies
- `GET/POST /music` - List/create music tracks

### Community
- `GET/POST /community/posts` - List/create posts
- `POST /community/posts/{id}/like` - Like/unlike
- `POST /community/posts/{id}/comments` - Add comment

### Upload
- `POST /upload/audio` - Upload audio file
- `POST /upload/video` - Upload video file
- `POST /upload/image` - Upload image
- `POST /upload/profile-image` - Upload avatar
- `POST /upload/thumbnail` - Upload thumbnail
- `GET /upload/media/duration` - Get media duration

### Editing
- `POST /video-editing/trim` - Trim video
- `POST /audio-editing/merge` - Merge audio

### Admin
- `GET /admin/dashboard` - Admin stats
- `POST /admin/approve/{type}/{id}` - Approve content
- `POST /admin/reject/{type}/{id}` - Reject content

**Full API documentation available in backend routes**

---

## 13. Security Considerations

### 13.1 Authentication
- ✅ JWT tokens with expiration
- ✅ Secure storage (flutter_secure_storage)
- ✅ Google OAuth integration

### 13.2 File Uploads
- ✅ Authentication required for uploads
- ✅ File type validation
- ✅ Unique filenames (UUID-based)
- ⚠️ No explicit file size limits documented

### 13.3 S3 Security
- ✅ Bucket policy restricts access
- ✅ CloudFront OAC for public reads
- ✅ EC2 IP whitelist for backend writes

### 13.4 CORS
- ✅ Production: Restricted to specific domains
- ✅ Development: Allows all (for local testing)

---

## 14. Testing & Local Development

### 14.1 Local Setup

**Backend**:
- SQLite database: `backend/local.db`
- Media folder: `backend/media/`
- Environment: `ENVIRONMENT=development`
- Local server: `http://localhost:8002`

**Mobile**:
- `.env` file with `ENVIRONMENT=development`
- Auto-uses localhost URLs
- Can test with Android emulator (10.0.2.2)

**Testing**:
- Can test all upload features locally
- Files saved to `backend/media/`
- Same folder structure as S3

---

## 15. Known Issues & Recommendations

### 15.1 Issues Found

1. **No upload progress indicators** for large files
2. **No explicit file size limits** in frontend
3. **Temporary files** may accumulate on failed uploads
4. **Bank details** warning but not enforced (may confuse users)

### 15.2 Recommendations

1. ✅ **Add upload progress bars** for better UX
2. ✅ **Implement chunked uploads** for large video files
3. ✅ **Add file size validation** (frontend + backend)
4. ✅ **Add retry logic** for failed uploads
5. ✅ **Cleanup temporary files** on upload failure
6. ✅ **Add upload queue** for multiple files

---

## 16. Conclusion

### 16.1 Overall Assessment

**The application is well-structured and cloud-friendly:**

✅ **S3 Integration**: Fully functional, all uploads go to S3  
✅ **CloudFront CDN**: Properly configured for media delivery  
✅ **EC2 Backend Access**: Has proper AWS credentials  
✅ **User Uploads**: Images, audio, video all work seamlessly  
✅ **Database**: Comprehensive schema with all necessary tables  
✅ **Authentication**: JWT + Google OAuth working  
✅ **Mobile App**: Complete feature set with proper navigation  

### 16.2 Upload Process Status

**Images**: ✅ Fully functional  
**Audio Podcasts**: ✅ Fully functional  
**Video Podcasts**: ✅ Fully functional  
**Profile Images**: ✅ Fully functional  
**Quote Images**: ✅ Auto-generated successfully  

### 16.3 Ready for Production

The application is **production-ready** with:
- Proper S3/CloudFront setup
- Secure authentication
- Complete upload workflows
- Admin moderation system
- Real-time features (LiveKit)

**Minor improvements recommended** (progress indicators, file size limits) but not blocking.

---

## 17. Mobile Application Production Status

### 17.1 Implementation Complete (December 8, 2024)

| Component | Status | Notes |
|-----------|--------|-------|
| Core Features (5 tabs) | ✅ Complete | Home, Search, Create, Community, Profile |
| Authentication | ✅ Complete | JWT + Google OAuth |
| Content Playback | ✅ Complete | Audio/video with continuous queue |
| Content Creation | ✅ Complete | Upload with actual API integration |
| Community Features | ✅ Complete | Posts, likes, comments |
| Events Feature | ✅ Complete | Map-based location picker |
| Admin Dashboard | ✅ Complete | Redesigned 4-tab navigation |
| Real-time Features | ✅ Complete | LiveKit meetings, streams, voice |
| UI/UX Polish | ✅ Complete | Pill design, consistent theme |
| Bug Fixes | ✅ Complete | Card heights, overflow issues fixed |

### 17.2 Recent Fixes

- ✅ Card height mismatch (Video/Movies/Animated cards white space)
- ✅ RenderFlex overflow issues
- ✅ Camera mirroring in prejoin screen
- ✅ File upload with actual API integration
- ✅ LiveKit service connection fixes
- ✅ PostgreSQL boolean comparison fixes

### 17.3 Pending for Store Submission

| Task | Status |
|------|--------|
| Android Keystore | 📋 Required |
| iOS Provisioning | 📋 Required |
| App Store Assets | 📋 Required |
| Privacy Policy URL | 📋 Required |
| Store Submissions | 📋 Pending |

### 17.4 Detailed Documentation

See `MOBILE_APPLICATION_COMPREHENSIVE_ANALYSIS.md` for complete mobile app documentation including:
- 14 state providers
- 50+ screens
- Full API integration (2400+ lines)
- Platform-specific configurations
- Build commands and deployment steps

---

**Document Created**: Based on complete codebase analysis  
**Last Updated**: December 8, 2024  
**Status**: ✅ Production-ready (Mobile app pending store submission)







