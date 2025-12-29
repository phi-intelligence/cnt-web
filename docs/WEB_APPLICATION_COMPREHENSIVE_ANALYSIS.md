# CNT Media Platform - Web Application Comprehensive Analysis

**Date:** Current Analysis  
**Status:** Complete understanding of web application architecture, features, and implementation  
**Focus:** Web frontend only (Flutter Web deployed on AWS Amplify)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Application Architecture](#application-architecture)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [State Management](#state-management)
6. [Navigation & Routing](#navigation--routing)
7. [Screen Inventory](#screen-inventory)
8. [Key Features Analysis](#key-features-analysis)
9. [Services Layer](#services-layer)
10. [Widget Architecture](#widget-architecture)
11. [Design System](#design-system)
12. [API Integration](#api-integration)
13. [Media Handling](#media-handling)
14. [Authentication Flow](#authentication-flow)
15. [Content Creation Workflows](#content-creation-workflows)
16. [Community Features](#community-features)
17. [Admin Features](#admin-features)
18. [Real-time Features](#real-time-features)
19. [Deployment Configuration](#deployment-configuration)
20. [Known Issues & Areas for Improvement](#known-issues--areas-for-improvement)

---

## Executive Summary

The **CNT Media Platform Web Application** is a comprehensive Flutter Web application providing a Christian media consumption and creation platform. It features:

- **39+ Web-specific screens** with responsive design
- **13 State Providers** for comprehensive state management
- **10 Service classes** for API and external integrations
- **49+ Reusable widgets** organized by category
- **Professional video/audio editors** with full editing capabilities
- **Real-time features** via WebSocket and LiveKit
- **Complete admin dashboard** with 7 admin pages
- **Social features** (Instagram-like community feed)
- **Content management** (podcasts, movies, music, Bible content)

**Deployment:**
- **Hosting:** AWS Amplify
- **Backend:** AWS EC2 (52.56.78.203) - FastAPI
- **Database:** AWS RDS PostgreSQL (production), SQLite (local)
- **Media Storage:** AWS S3 + CloudFront CDN
- **Build:** Flutter Web with `--dart-define` environment variables

---

## Application Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Amplify (Web Hosting)             │
│  ┌───────────────────────────────────────────────────┐   │
│  │         Flutter Web Application                  │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │  │ Screens  │  │ Providers│  │ Services │      │   │
│  │  └──────────┘  └──────────┘  └──────────┘      │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          │ HTTPS/REST API
                          │ WebSocket
                          │
┌─────────────────────────────────────────────────────────┐
│              AWS EC2 (Backend Server)                   │
│  ┌───────────────────────────────────────────────────┐   │
│  │         FastAPI Backend                          │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐      │   │
│  │  │  Routes  │  │ Services │  │  Models  │      │   │
│  │  └──────────┘  └──────────┘  └──────────┘      │   │
│  └───────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                          │
                          │
┌─────────────────────────────────────────────────────────┐
│         AWS RDS PostgreSQL (Database)                   │
│         AWS S3 + CloudFront (Media Storage)             │
│         LiveKit Server (Real-time Communication)        │
└─────────────────────────────────────────────────────────┘
```

### Architecture Patterns

1. **Provider Pattern**: State management using Flutter's Provider package
2. **Service Layer**: Separation of API calls and business logic
3. **Repository Pattern**: Data access abstraction through services
4. **Widget Composition**: Reusable, composable UI components
5. **Route-based Navigation**: GoRouter for declarative routing

---

## Technology Stack

### Frontend
- **Framework:** Flutter Web (Dart)
- **State Management:** Provider
- **Routing:** GoRouter
- **HTTP Client:** http package
- **WebSocket:** Custom WebSocketService
- **Video Player:** video_player package
- **Audio Player:** Custom audio player implementation
- **Image Loading:** cached_network_image
- **File Picker:** file_picker package
- **Video Recording:** MediaRecorder API (browser)
- **Audio Recording:** Web Audio API (browser)

### Backend Integration
- **API Protocol:** REST (JSON)
- **Real-time:** WebSocket (Socket.IO)
- **Authentication:** JWT tokens
- **File Upload:** Multipart form data

### External Services
- **LiveKit:** Video meetings and live streaming
- **OpenAI:** GPT-4o-mini for voice agent
- **Deepgram:** Speech-to-text and text-to-speech
- **Google OAuth:** Authentication (optional)

---

## Project Structure

```
web/frontend/
├── lib/
│   ├── config/
│   │   └── app_config.dart              # Environment configuration
│   ├── constants/
│   │   └── app_constants.dart           # App constants
│   ├── layouts/
│   │   └── web_layout.dart              # Web layout wrapper
│   ├── models/
│   │   ├── api_models.dart              # API response models
│   │   ├── artist.dart                   # Artist model
│   │   ├── content_item.dart            # Content item model
│   │   ├── document_asset.dart          # Document model
│   │   ├── support_message.dart         # Support ticket model
│   │   └── text_overlay.dart            # Video overlay model
│   ├── navigation/
│   │   ├── app_router.dart              # Main router setup
│   │   ├── app_routes.dart              # Route definitions
│   │   ├── main_navigation.dart         # Navigation helper
│   │   └── web_navigation.dart          # Web navigation layout
│   ├── providers/                       # State management (13 providers)
│   │   ├── app_state.dart
│   │   ├── artist_provider.dart
│   │   ├── audio_player_provider.dart
│   │   ├── auth_provider.dart
│   │   ├── community_provider.dart
│   │   ├── documents_provider.dart
│   │   ├── favorites_provider.dart
│   │   ├── music_provider.dart
│   │   ├── notification_provider.dart
│   │   ├── playlist_provider.dart
│   │   ├── search_provider.dart
│   │   ├── support_provider.dart
│   │   └── user_provider.dart
│   ├── screens/                         # All screens (39+ web screens)
│   │   ├── admin/                       # Admin screens (7 pages)
│   │   ├── artist/                      # Artist profile screens
│   │   ├── audio/                       # Audio player screens
│   │   ├── bible/                        # Bible reader screens
│   │   ├── community/                   # Community screens
│   │   ├── creation/                     # Content creation screens
│   │   ├── editing/                      # Audio/video editors
│   │   ├── live/                         # Live streaming screens
│   │   ├── meeting/                      # Meeting screens
│   │   ├── support/                       # Support screens
│   │   ├── video/                        # Video player screens
│   │   ├── voice/                        # Voice agent screens
│   │   └── web/                          # Web-specific screens (39 files)
│   ├── services/                        # API and external services (10 services)
│   │   ├── api_service.dart              # Main API service (2800+ lines)
│   │   ├── audio_editing_service.dart
│   │   ├── auth_service.dart
│   │   ├── donation_service.dart
│   │   ├── download_service.dart
│   │   ├── google_auth_service.dart
│   │   ├── livekit_meeting_service.dart
│   │   ├── livekit_voice_service.dart
│   │   ├── video_editing_service.dart
│   │   └── websocket_service.dart
│   ├── theme/                           # Design system
│   │   ├── app_colors.dart               # Color palette
│   │   ├── app_spacing.dart              # Spacing constants
│   │   ├── app_theme.dart                # Theme configuration
│   │   └── app_typography.dart           # Typography system
│   ├── utils/                           # Utility functions
│   │   ├── bank_details_helper.dart
│   │   ├── dimension_utils.dart
│   │   ├── editor_responsive.dart
│   │   ├── format_utils.dart
│   │   ├── media_utils.dart
│   │   ├── platform_helper.dart
│   │   ├── platform_utils.dart
│   │   ├── responsive_grid_delegate.dart
│   │   ├── responsive_utils.dart
│   │   ├── state_persistence.dart        # Editor state persistence
│   │   ├── voice_responsive.dart
│   │   ├── web_audio_recorder.dart       # Web audio recording
│   │   └── web_video_recorder.dart       # Web video recording
│   ├── widgets/                         # Reusable widgets (49+ files)
│   │   ├── admin/                        # Admin widgets
│   │   ├── audio/                        # Audio widgets
│   │   ├── bible/                        # Bible widgets
│   │   ├── community/                    # Community widgets
│   │   ├── live_stream/                   # Live stream widgets
│   │   ├── meeting/                       # Meeting widgets
│   │   ├── notifications/                # Notification widgets
│   │   ├── shared/                       # Shared widgets
│   │   ├── voice/                        # Voice widgets
│   │   └── web/                           # Web-specific widgets
│   └── main.dart                         # Application entry point
├── assets/
│   └── images/                          # Static images
├── web/
│   ├── index.html                       # HTML entry point
│   └── icons/                           # App icons
├── pubspec.yaml                         # Dependencies
└── amplify.yml                          # AWS Amplify build config
```

---

## State Management

### Provider Architecture

The application uses **13 Provider classes** for state management:

#### 1. **AuthProvider** (`providers/auth_provider.dart`)
- **Purpose:** Authentication state management
- **State:**
  - `_user`: Current user data
  - `_isAuthenticated`: Authentication status
  - `_isLoading`: Loading state
  - `_error`: Error messages
- **Methods:**
  - `login()`: Email/password login
  - `googleLogin()`: Google OAuth login
  - `register()`: User registration
  - `registerWithOTP()`: OTP-based registration
  - `logout()`: User logout
  - `checkAuthStatus()`: Verify authentication
  - `checkUsername()`: Username availability
  - `sendOTP()` / `verifyOTP()`: OTP verification
- **Features:**
  - Automatic token expiration checking (every 5 minutes)
  - Auto-logout on token expiration
  - Token storage in localStorage

#### 2. **AppState** (`providers/app_state.dart`)
- **Purpose:** Global application state
- **State:** App-wide settings and preferences

#### 3. **AudioPlayerProvider** (`providers/audio_player_provider.dart`)
- **Purpose:** Audio playback state
- **State:**
  - Current playing track
  - Playback position
  - Playlist queue
  - Play/pause state
- **Features:**
  - Continuous playback across navigation
  - Queue management
  - Position tracking

#### 4. **MusicProvider** (`providers/music_provider.dart`)
- **Purpose:** Music library state
- **State:** Music tracks, playlists, favorites

#### 5. **CommunityProvider** (`providers/community_provider.dart`)
- **Purpose:** Community posts and social features
- **State:**
  - Posts list
  - Loading state
  - Pagination state
- **Features:**
  - Infinite scroll
  - Post creation
  - Like/comment management

#### 6. **UserProvider** (`providers/user_provider.dart`)
- **Purpose:** User profile and settings
- **State:** User data, preferences, library

#### 7. **PlaylistProvider** (`providers/playlist_provider.dart`)
- **Purpose:** Playlist management
- **State:** User playlists, playlist items

#### 8. **FavoritesProvider** (`providers/favorites_provider.dart`)
- **Purpose:** Favorites management
- **State:** Favorite content items

#### 9. **SearchProvider** (`providers/search_provider.dart`)
- **Purpose:** Search functionality
- **State:** Search results, filters, query

#### 10. **SupportProvider** (`providers/support_provider.dart`)
- **Purpose:** Support ticket management
- **State:** Support messages, ticket status

#### 11. **DocumentsProvider** (`providers/documents_provider.dart`)
- **Purpose:** Document/Bible content
- **State:** Documents, Bible stories

#### 12. **NotificationProvider** (`providers/notification_provider.dart`)
- **Purpose:** User notifications
- **State:** Notifications list, unread count
- **Features:**
  - Real-time notifications via WebSocket
  - Notification badges

#### 13. **ArtistProvider** (`providers/artist_provider.dart`)
- **Purpose:** Artist profile management
- **State:** Artist data, followers, content

### Provider Initialization

All providers are initialized in `app_router.dart`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => AppState()),
    ChangeNotifierProvider(create: (_) => MusicProvider()),
    ChangeNotifierProvider(create: (_) => CommunityProvider()),
    ChangeNotifierProvider(create: (_) => AudioPlayerState()),
    ChangeNotifierProvider(create: (_) => SearchProvider()),
    ChangeNotifierProvider(create: (_) => UserProvider()),
    ChangeNotifierProvider(create: (_) => PlaylistProvider()),
    ChangeNotifierProvider(create: (_) => FavoritesProvider()),
    ChangeNotifierProvider(create: (_) => SupportProvider()),
    ChangeNotifierProvider(create: (_) => DocumentsProvider()),
    ChangeNotifierProvider(create: (_) => NotificationProvider()),
    ChangeNotifierProvider(create: (_) => ArtistProvider()),
  ],
  child: ...
)
```

---

## Navigation & Routing

### Routing System

**Router:** GoRouter (declarative routing)

**Main Router File:** `navigation/app_routes.dart`

### Route Structure

#### Public Routes
- `/` - Landing page (login/register)
- `/login` - User login
- `/register` - User registration

#### Protected Routes (Require Authentication)
- `/home` - Home dashboard
- `/search` - Search functionality
- `/create` - Content creation hub
- `/community` - Community feed
- `/profile` - User profile
- `/podcasts` - Podcast library
- `/movies` - Movie library
- `/about` - About page

#### Admin Routes (Require Admin Role)
- `/admin` - Admin dashboard
- `/bulk-upload` - Bulk content upload

#### Dynamic Routes
- `/podcast/:id` - Podcast detail
- `/movie/:id` - Movie detail
- `/artist/:artistId` - Artist profile
- `/artist/manage` - Artist profile management
- `/player/audio/:podcastId` - Audio player
- `/player/video/:podcastId` - Video player

#### Editor Routes
- `/edit/video?path=...` - Video editor
- `/edit/audio?path=...` - Audio editor

#### Preview Routes
- `/preview/video?uri=...&source=...&duration=...&fileSize=...` - Video preview
- `/preview/audio?uri=...&source=...&duration=...&fileSize=...` - Audio preview

#### Meeting/Live Routes
- `/meetings` - Meeting options
- `/live-stream/options` - Live stream options
- `/live-stream/start` - Start live stream
- `/live-streams` - Live streams list

#### Special Routes
- `/quote` - Quote creation

### Navigation Layout

**Web Navigation Layout:** `navigation/web_navigation.dart`

**Features:**
- Sidebar navigation (280px fixed width)
- Main content area (flexible)
- Global audio player (bottom-mounted)
- Responsive design (collapsible sidebar on mobile)

### Route Guards

**Authentication Guard:**
- Checks `authProvider.isAuthenticated`
- Redirects to `/` if not authenticated
- Redirects to `/home` if authenticated and on landing page

**Admin Guard:**
- Checks `authProvider.isAdmin`
- Admin routes only accessible to admins

---

## Screen Inventory

### Web-Specific Screens (39 Total)

#### Core Screens (`screens/web/`)
1. **`landing_screen_web.dart`** - Landing page with login
2. **`home_screen_web.dart`** - Home dashboard
3. **`about_screen_web.dart`** - About page

#### Content Screens
4. **`podcasts_screen_web.dart`** - Podcast library
5. **`movies_screen_web.dart`** - Movie library
6. **`movie_detail_screen_web.dart`** - Movie details
7. **`video_podcast_detail_screen_web.dart`** - Video podcast details
8. **`music_screen_web.dart`** - Music player
9. **`discover_screen_web.dart`** - Content discovery
10. **`search_screen_web.dart`** - Search functionality

#### Community Screens
11. **`community_screen_web.dart`** - Social feed (Instagram-like)
12. **`prayer_screen_web.dart`** - Prayer requests
13. **`join_prayer_screen_web.dart`** - Join prayer

#### Creation Screens
14. **`create_screen_web.dart`** - Content creation hub
15. **`video_editor_screen_web.dart`** - Professional video editor
16. **`video_recording_screen_web.dart`** - Record video
17. **`video_preview_screen_web.dart`** - Preview before publishing

#### Live/Meeting Screens
18. **`live_screen_web.dart`** - Live streaming hub
19. **`stream_screen_web.dart`** - Stream viewer
20. **`live_stream_options_screen_web.dart`** - Stream setup
21. **`meetings_screen_web.dart`** - Meeting list
22. **`meeting_options_screen_web.dart`** - Meeting options
23. **`meeting_room_screen_web.dart`** - LiveKit meeting room

#### User Screens
24. **`profile_screen_web.dart`** - User profile
25. **`library_screen_web.dart`** - User library
26. **`favorites_screen_web.dart`** - User favorites
27. **`downloads_screen_web.dart`** - Offline downloads
28. **`notifications_screen_web.dart`** - Notifications

#### Voice Screens
29. **`voice_agent_screen_web.dart`** - AI voice assistant
30. **`voice_chat_screen_web.dart`** - Voice chat

#### Admin Screens
31. **`admin_dashboard_web.dart`** - Admin dashboard
32. **`admin_login_screen_web.dart`** - Admin login

#### Other Screens
33. **`support_screen_web.dart`** - Support tickets
34. **`bible_stories_screen_web.dart`** - Bible stories
35. **`not_found_screen_web.dart`** - 404 page
36. **`offline_screen_web.dart`** - Offline mode
37. **`user_login_screen_web.dart`** - User login
38. **`register_screen_web.dart`** - User registration
39. **`audio_player_full_screen_web.dart`** - Full-screen audio player

### Shared Screens (Used by Web)

#### Creation Screens (`screens/creation/`)
- `audio_podcast_create_screen.dart` - Audio creation workflow
- `audio_recording_screen.dart` - Record audio
- `audio_preview_screen.dart` - Preview audio
- `video_podcast_create_screen.dart` - Video creation workflow
- `video_recording_screen.dart` - Record video
- `video_preview_screen.dart` - Preview video
- `quote_create_screen_web.dart` - Quote creation

#### Editing Screens (`screens/editing/`)
- `audio_editor_screen.dart` - Audio editor (trim, merge, fade)
- `video_editor_screen.dart` - Video editor (trim, overlays, audio)

#### Community Screens (`screens/community/`)
- `create_post_screen.dart` - Create image/text post
- `comment_screen.dart` - View/add comments

#### Live/Meeting Screens (`screens/live/`, `screens/meeting/`)
- `live_stream_broadcaster.dart` - Host broadcast
- `live_stream_viewer.dart` - Viewer interface
- `stream_creation_screen.dart` - Setup stream
- `meeting_room_screen.dart` - LiveKit meeting room
- `join_meeting_screen.dart` - Join meeting
- `schedule_meeting_screen.dart` - Schedule meeting
- `prejoin_screen.dart` - Prejoin meeting

#### Admin Screens (`screens/admin/`)
- `admin_dashboard_page.dart` - Admin overview
- `admin_users_page.dart` - User management
- `admin_posts_page.dart` - Content moderation
- `admin_audio_page.dart` - Audio content management
- `admin_video_page.dart` - Video content management
- `admin_documents_page.dart` - Document management
- `admin_support_page.dart` - Support ticket management
- `bulk_upload_screen.dart` - Bulk upload from Google Drive
- `google_drive_picker_screen.dart` - Google Drive picker
- `google_picker_webview_screen.dart` - Google Picker WebView

#### Other Screens
- `artist_profile_screen.dart` - Artist profile view
- `artist_profile_manage_screen.dart` - Artist profile management
- `bible_document_selector_screen.dart` - Bible document selector
- `pdf_viewer_screen.dart` - PDF viewer
- `bank_details_screen.dart` - Bank details for creators
- `edit_profile_screen.dart` - Edit user profile
- `donation_modal.dart` - Donation modal

---

## Key Features Analysis

### 1. Home Screen (`home_screen_web.dart`)

**Features:**
- **Hero Carousel:** Auto-scrolling carousel with latest community posts
- **Welcome Section:** Personalized greeting with quick actions
- **Content Sections:**
  - Audio Podcasts (disc design)
  - Video Podcasts (card grid)
  - Bible Reader Section
  - Recently Played
  - Movies
  - Featured Music
  - User Playlists
  - Bible Stories
  - Animated Bible Stories
- **Parallax Effects:** Carousel fades and parallax on scroll
- **Infinite Scroll:** Loads more content as user scrolls

**Data Sources:**
- Podcasts API (`/api/v1/podcasts`)
- Movies API (`/api/v1/movies`)
- Music API (`/api/v1/music`)
- Community Posts API (`/api/v1/community/posts`)
- Bible Stories API (`/api/v1/bible-stories`)
- Documents API (`/api/v1/documents`)

### 2. Community Screen (`community_screen_web.dart`)

**Features:**
- **Instagram-like Feed:** Grid layout with posts
- **Post Types:**
  - Image posts (user-uploaded photos)
  - Text posts (auto-generated quote images)
- **Interactions:**
  - Like/unlike posts
  - Comment on posts
  - Share posts
- **Categories:**
  - Testimony
  - Prayer Request
  - Question
  - Announcement
  - General
- **Infinite Scroll:** Loads more posts as user scrolls
- **Post Navigation:** Can scroll to specific post via URL parameter

**API Endpoints:**
- `GET /api/v1/community/posts` - Fetch posts
- `POST /api/v1/community/posts` - Create post
- `POST /api/v1/community/posts/{id}/like` - Like/unlike
- `POST /api/v1/community/posts/{id}/comments` - Add comment

### 3. Video Editor (`video_editor_screen_web.dart`)

**Features:**
- **Professional Editing UI:**
  - Large video preview
  - Timeline with playhead
  - Tab-based editing tools
- **Editing Capabilities:**
  - **Trim:** Cut start/end of video
  - **Audio Management:**
    - Remove audio track
    - Add audio track
    - Replace audio track
  - **Text Overlays:**
    - Add text at specific timestamps
    - Customize: text, position (x, y), font, color, size, alignment
    - Multiple overlays supported
    - Timeline visualization
- **State Persistence:**
  - Saves editor state to localStorage
  - Restores on page reload
  - Handles blob URLs (uploads to backend for persistence)
  - Warns before leaving with unsaved changes
- **Video Player:**
  - Full-screen preview
  - Play/pause controls
  - Seek bar with playhead
  - Duration display
  - Resolution display
  - Auto-hide controls on mouse move

**API Endpoints:**
- `POST /api/v1/video-editing/trim` - Trim video
- `POST /api/v1/video-editing/remove-audio` - Remove audio
- `POST /api/v1/video-editing/add-audio` - Add audio
- `POST /api/v1/video-editing/replace-audio` - Replace audio
- `POST /api/v1/video-editing/add-text-overlays` - Add text overlays

**Blob URL Handling:**
- Detects blob URLs from MediaRecorder
- Uploads to backend for persistence
- Converts to backend URL for editing

### 4. Audio Editor (`audio_editor_screen.dart`)

**Features:**
- **Editing Capabilities:**
  - **Trim:** Cut start/end of audio
  - **Merge:** Combine multiple audio files
  - **Fade Effects:**
    - Fade In
    - Fade Out
    - Fade In/Out
- **Audio Player:**
  - Play/pause controls
  - Seek bar
  - Duration display
  - Volume control
- **State Persistence:**
  - Saves editor state to localStorage
  - Restores on page reload
  - Warns before leaving with unsaved changes

**API Endpoints:**
- `POST /api/v1/audio-editing/trim` - Trim audio
- `POST /api/v1/audio-editing/merge` - Merge audio
- `POST /api/v1/audio-editing/fade-in` - Fade in
- `POST /api/v1/audio-editing/fade-out` - Fade out
- `POST /api/v1/audio-editing/fade-in-out` - Fade in/out

### 5. Content Creation Hub (`create_screen_web.dart`)

**Features:**
- **Grid of Creation Options:**
  - Video Podcast
  - Audio Podcast
  - Meeting
  - Document (admin only)
  - Live Stream
  - Quote
- **Each option navigates to appropriate creation workflow**

### 6. Admin Dashboard (`admin_dashboard_web.dart`)

**Features:**
- **7 Admin Pages:**
  1. Dashboard (overview)
  2. Users (user management)
  3. Posts (content moderation)
  4. Audio (audio content management)
  5. Video (video content management)
  6. Documents (document management)
  7. Support (support ticket management)
- **Content Moderation:**
  - Approve/reject content
  - View pending content
  - Bulk operations
- **User Management:**
  - View all users
  - Edit user roles
  - User statistics

---

## Services Layer

### 1. ApiService (`services/api_service.dart`)

**Purpose:** Main API communication service (2800+ lines)

**Key Methods:**
- **Authentication:**
  - `login()`, `register()`, `googleLogin()`
  - `sendOTP()`, `verifyOTP()`, `registerWithOTP()`
  - `checkUsername()`
- **Content:**
  - `getPodcasts()`, `createPodcast()`, `getPodcast()`
  - `getMovies()`, `createMovie()`, `getMovie()`
  - `getMusicTracks()`, `createMusicTrack()`
- **Community:**
  - `getCommunityPosts()`, `createCommunityPost()`
  - `likePost()`, `unlikePost()`
  - `addComment()`, `getComments()`
- **Upload:**
  - `uploadAudio()`, `uploadVideo()`, `uploadImage()`
  - `uploadProfileImage()`, `uploadThumbnail()`
  - `uploadTemporaryAudio()`, `uploadDocument()`
  - `getMediaDuration()`, `getDefaultThumbnails()`
- **Artists:**
  - `getArtist()`, `getArtistPodcasts()`
  - `followArtist()`, `unfollowArtist()`
  - `updateArtistProfile()`, `uploadArtistCoverImage()`
- **Playlists:**
  - `getPlaylists()`, `createPlaylist()`
  - `addToPlaylist()`, `removeFromPlaylist()`
- **Live/Meetings:**
  - `createStream()`, `getStreams()`, `joinStream()`
  - `getLiveKitToken()`, `getVoiceAgentToken()`
- **Admin:**
  - `getAdminDashboard()`, `getPendingContent()`
  - `approveContent()`, `rejectContent()`
- **Support:**
  - `createSupportMessage()`, `getSupportMessages()`
  - `updateSupportMessage()`
- **Documents:**
  - `getDocuments()`, `getBibleStories()`
- **Notifications:**
  - `getNotifications()`, `markNotificationRead()`

**Media URL Handling:**
```dart
String getMediaUrl(String? path) {
  // Handles both full URLs and relative paths
  // Maps to CloudFront in production, localhost in development
}
```

**Error Handling:**
- Automatic 401 handling (token expiration)
- Generic error messages for security
- Timeout handling

### 2. AuthService (`services/auth_service.dart`)

**Purpose:** Authentication handling

**Features:**
- Token storage in localStorage
- Token expiration checking
- Auto-logout on expiration
- Google OAuth integration
- OTP verification

### 3. WebSocketService (`services/websocket_service.dart`)

**Purpose:** Real-time communication

**Features:**
- Socket.IO connection
- Real-time notifications
- Connection management
- Reconnection logic

### 4. VideoEditingService (`services/video_editing_service.dart`)

**Purpose:** Video editing API calls

**Methods:**
- `trimVideo()`
- `removeAudio()`
- `addAudio()`
- `replaceAudio()`
- `addTextOverlays()`
- `applyFilters()`

### 5. AudioEditingService (`services/audio_editing_service.dart`)

**Purpose:** Audio editing API calls

**Methods:**
- `trimAudio()`
- `mergeAudio()`
- `fadeIn()`
- `fadeOut()`
- `fadeInOut()`

### 6. LiveKitMeetingService (`services/livekit_meeting_service.dart`)

**Purpose:** Video meeting integration

**Features:**
- LiveKit room creation
- Token generation
- Participant management

### 7. LiveKitVoiceService (`services/livekit_voice_service.dart`)

**Purpose:** Voice agent integration

**Features:**
- Voice room creation
- AI voice agent connection
- Speech-to-text / text-to-speech

### 8. GoogleAuthService (`services/google_auth_service.dart`)

**Purpose:** Google OAuth integration

**Features:**
- Google Sign-In
- Token handling
- Profile data retrieval

### 9. DownloadService (`services/download_service.dart`)

**Purpose:** Content downloading

**Features:**
- Offline content management
- Download queue
- Progress tracking

### 10. DonationService (`services/donation_service.dart`)

**Purpose:** Payment processing

**Features:**
- Stripe integration
- PayPal integration
- Donation tracking

---

## Widget Architecture

### Web-Specific Widgets (`widgets/web/`)

1. **Navigation:**
   - `sidebar_nav.dart` - Main sidebar navigation
   - `sidebar_action_box.dart` - Quick action boxes

2. **Content Display:**
   - `content_card_web.dart` - Standard content cards
   - `disc_card_web.dart` - Circular disc-style cards
   - `featured_categories_web.dart` - Category showcase
   - `welcome_section_web.dart` - Personalized welcome

3. **UI Components:**
   - `styled_page_header.dart` - Page headers
   - `styled_filter_chip.dart` - Filter chips
   - `styled_pill_button.dart` - Pill buttons
   - `styled_search_field.dart` - Search input
   - `section_container.dart` - Section containers

### Shared Widgets (`widgets/shared/`)

1. **`content_section.dart`** - Flexible content section
   - Horizontal/vertical layouts
   - Disc design option
   - Scroll controls
   - Empty state handling

2. **`loading_shimmer.dart`** - Loading animations
   - Skeleton screens
   - Shimmer effects

3. **`empty_state.dart`** - Empty state illustrations
   - Customizable messages
   - Action buttons

4. **`hero_carousel_widget.dart`** - Hero carousel
   - Auto-scrolling
   - Community post images
   - Navigation support
   - Image caching

### Specialized Widgets

1. **Community:** `widgets/community/`
   - `instagram_post_card.dart` - Post cards
   - Comment widgets
   - Like buttons

2. **Media:** `widgets/media/`
   - `global_audio_player.dart` - Persistent player
   - `sliding_audio_player.dart` - Collapsible player

3. **Bible:** `widgets/bible/`
   - `bible_reader_section.dart` - Bible reader
   - Document selectors

4. **Meeting:** `widgets/meeting/`
   - `meeting_section.dart` - Meeting widgets
   - Video participant views

5. **Live Stream:** `widgets/live_stream/`
   - `live_stream_section.dart` - Stream widgets
   - Broadcaster/viewer interfaces

---

## Design System

### Color Palette (`theme/app_colors.dart`)

**Primary Colors:**
- `primaryMain`: `#8B7355` (Warm Brown)
- `warmBrown`: `#92775B` (Hero/Banner Brown)
- `accentMain`: `#D4A574` (Golden Yellow)

**Background Colors:**
- `backgroundPrimary`: `#F7F5F2` (Cream)
- `backgroundSecondary`: `#FCFAF8` (Card Background)
- `cardBackground`: `#FCFAF8` (Card Background)

**Text Colors:**
- `textPrimary`: `#2D2520` (Dark Brown)
- `textSecondary`: `#5A4F47` (Medium Text)
- `textInverse`: `#F7F5F2` (Light text on dark)

### Typography (`theme/app_typography.dart`)

**Font Sizes:**
- `heading1`: 32px
- `heading2`: 24px
- `heading3`: 20px
- `body`: 16px
- `caption`: 14px
- `small`: 12px

**Font Weights:**
- Regular: 400
- Medium: 500
- Semi-bold: 600
- Bold: 700

### Spacing (`theme/app_spacing.dart`)

**Standard Spacing:**
- `xs`: 4px
- `sm`: 8px
- `md`: 16px
- `lg`: 24px
- `xl`: 32px
- `xxl`: 48px

### Theme (`theme/app_theme.dart`)

**Features:**
- Light theme (default)
- Dark theme support
- System theme detection
- Consistent Material Design components

---

## API Integration

### Base Configuration

**API Base URL:** Configured via `--dart-define=API_BASE_URL`
- **Development:** `http://localhost:8002/api/v1`
- **Production:** `https://api.christnewtabernacle.com/api/v1`

**Media Base URL:** Configured via `--dart-define=MEDIA_BASE_URL`
- **Development:** `http://localhost:8002`
- **Production:** `https://d126sja5o8ue54.cloudfront.net`

### Authentication

**JWT Token Storage:**
- Stored in `localStorage` (web)
- Automatic token expiration checking
- Auto-logout on expiration

**Token Format:**
```
Authorization: Bearer <token>
```

### Request/Response Format

**Request Headers:**
```dart
{
  'Content-Type': 'application/json',
  'Authorization': 'Bearer <token>'
}
```

**Response Format:**
- JSON responses
- Error responses with status codes
- Generic error messages for security

### Error Handling

**401 Unauthorized:**
- Automatic token expiration detection
- Auto-logout and redirect to login

**Network Errors:**
- Timeout handling (10 seconds default)
- Retry logic (not implemented)
- User-friendly error messages

---

## Media Handling

### Media URL Resolution

**Function:** `ApiService.getMediaUrl()`

**Logic:**
1. Returns full URLs directly (if starts with `http://` or `https://`)
2. Strips legacy `media/` prefix if present
3. Maps to CloudFront URL in production
4. Maps to localhost in development

**Example:**
```dart
// Input: "audio/abc123.mp3"
// Production: "https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3"
// Development: "http://localhost:8002/media/audio/abc123.mp3"
```

### File Upload

**Audio Upload:**
- Endpoint: `POST /api/v1/upload/audio`
- Multipart form data
- Returns: `{filename, url, file_path, duration, thumbnail_url}`

**Video Upload:**
- Endpoint: `POST /api/v1/upload/video`
- Multipart form data
- Auto-generates thumbnail
- Returns: `{filename, url, file_path, duration, thumbnail_url}`

**Image Upload:**
- Endpoint: `POST /api/v1/upload/image`
- Multipart form data
- Returns: `{filename, url, content_type}`

### Media Recording (Web)

**Video Recording:**
- Uses `MediaRecorder` API
- Creates blob URLs
- Uploads to backend for persistence
- File: `utils/web_video_recorder.dart`

**Audio Recording:**
- Uses `Web Audio API`
- Creates blob URLs
- Uploads to backend for persistence
- File: `utils/web_audio_recorder.dart`

### Media Playback

**Video Player:**
- Package: `video_player`
- Supports network URLs and blob URLs
- Full-screen playback
- Controls: play, pause, seek, volume

**Audio Player:**
- Custom implementation
- Global persistent player
- Playlist support
- Continuous playback across navigation

---

## Authentication Flow

### Login Flow

1. **User enters credentials** on landing page
2. **AuthProvider.login()** called
3. **AuthService.login()** sends request to `/api/v1/auth/login`
4. **Backend returns JWT token** and user data
5. **Token stored in localStorage**
6. **User data cached in AuthProvider**
7. **Redirect to `/home`**

### Registration Flow

1. **User fills registration form**
2. **Optional OTP verification:**
   - `sendOTP()` → `verifyOTP()` → `registerWithOTP()`
3. **AuthProvider.register()** called
4. **AuthService.register()** sends request to `/api/v1/auth/register`
5. **Backend creates user** and returns JWT token
6. **Token stored and user logged in**
7. **Redirect to `/home`**

### Google OAuth Flow

1. **User clicks "Sign in with Google"**
2. **GoogleAuthService.signInWithGoogle()** called
3. **Google OAuth popup opens**
4. **User authenticates with Google**
5. **Google returns id_token or access_token**
6. **AuthService.googleLogin()** sends token to backend
7. **Backend creates/links user account**
8. **Backend returns JWT token**
9. **Token stored and user logged in**
10. **Redirect to `/home`**

### Token Expiration

**Automatic Checking:**
- Checks every 5 minutes
- Validates token expiration
- Auto-logout if expired
- Shows error message

**Manual Checking:**
- On each API request
- 401 response triggers logout
- User redirected to login

---

## Content Creation Workflows

### Video Podcast Creation

1. **User navigates to `/create`**
2. **Selects "Video Podcast"**
3. **Options:**
   - Record video (uses MediaRecorder)
   - Upload from file (file picker)
4. **Recording/Upload:**
   - Creates blob URL (if recording)
   - Shows preview screen
5. **Preview Screen (`video_preview_screen_web.dart`):**
   - Shows video preview
   - Displays metadata (duration, file size)
   - Option to edit
6. **Editing (optional):**
   - Navigate to `/edit/video?path=...`
   - Apply edits (trim, overlays, audio)
   - Save edited video
7. **Publishing:**
   - Upload to backend: `POST /api/v1/upload/video`
   - Backend saves to S3
   - Create podcast record: `POST /api/v1/podcasts`
   - Status: "pending" (requires admin approval)

### Audio Podcast Creation

1. **User navigates to `/create`**
2. **Selects "Audio Podcast"**
3. **Options:**
   - Record audio (uses Web Audio API)
   - Upload from file (file picker)
4. **Recording/Upload:**
   - Creates blob URL (if recording)
   - Shows preview screen
5. **Preview Screen (`audio_preview_screen.dart`):**
   - Shows audio preview
   - Displays metadata (duration, file size)
   - Option to edit
6. **Editing (optional):**
   - Navigate to `/edit/audio?path=...`
   - Apply edits (trim, merge, fade)
   - Save edited audio
7. **Publishing:**
   - Upload to backend: `POST /api/v1/upload/audio`
   - Backend saves to S3
   - Create podcast record: `POST /api/v1/podcasts`
   - Status: "pending" (requires admin approval)

### Quote Creation

1. **User navigates to `/create`**
2. **Selects "Quote"**
3. **Quote Creation Screen (`quote_create_screen_web.dart`):**
   - Enter text content
   - Select category
   - Preview quote image
4. **Publishing:**
   - Create post: `POST /api/v1/community/posts`
   - Backend detects `post_type='text'`
   - Backend generates quote image
   - Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
   - Updates post with image URL
   - Status: "pending" (requires admin approval)

---

## Community Features

### Post Types

1. **Image Posts:**
   - User uploads photo
   - Adds caption (title + content)
   - Selects category
   - Uploads image: `POST /api/v1/upload/image`
   - Creates post: `POST /api/v1/community/posts`

2. **Text Posts:**
   - User enters text
   - Selects category
   - Creates post: `POST /api/v1/community/posts`
   - Backend auto-generates quote image
   - Displays as image post in feed

### Interactions

**Like/Unlike:**
- Endpoint: `POST /api/v1/community/posts/{id}/like`
- Toggles like status
- Updates like count

**Comments:**
- Endpoint: `POST /api/v1/community/posts/{id}/comments`
- Add comment with content
- Updates comment count

**Sharing:**
- Copy post URL
- Share to social media (not implemented)

### Feed Features

**Infinite Scroll:**
- Loads more posts as user scrolls
- Pagination support
- Loading states

**Filtering:**
- Filter by category
- Filter by user
- Search posts

**Post Navigation:**
- Click post to view details
- Scroll to specific post via URL: `/community?postId=123`

---

## Admin Features

### Admin Dashboard

**7 Admin Pages:**

1. **Dashboard:**
   - Overview statistics
   - Recent activity
   - Quick actions

2. **Users:**
   - List all users
   - Edit user roles
   - User statistics
   - Search users

3. **Posts:**
   - Content moderation
   - Approve/reject posts
   - View pending posts
   - Bulk operations

4. **Audio:**
   - Audio content management
   - Approve/reject audio
   - View pending audio
   - Edit audio metadata

5. **Video:**
   - Video content management
   - Approve/reject video
   - View pending video
   - Edit video metadata

6. **Documents:**
   - Document management
   - Upload documents (PDF)
   - Delete documents
   - Document statistics

7. **Support:**
   - Support ticket management
   - View tickets
   - Respond to tickets
   - Close tickets

### Content Moderation

**Workflow:**
1. User creates content
2. Content status: "pending"
3. Admin views pending content
4. Admin approves/rejects
5. Approved content visible to all users
6. Rejected content hidden

**Bulk Operations:**
- Bulk approve
- Bulk reject
- Bulk delete (not implemented)

### Bulk Upload

**Google Drive Integration:**
- Connect Google Drive
- Select files from Drive
- Bulk upload to S3
- Create content records
- Admin-only feature

---

## Real-time Features

### WebSocket Connection

**Service:** `WebSocketService`

**Connection:**
- Connects on app startup
- Uses Socket.IO protocol
- Reconnects on disconnect
- Non-blocking (doesn't crash app on failure)

**Events:**
- Real-time notifications
- Live stream updates
- Meeting updates

### Live Streaming

**LiveKit Integration:**
- Create stream: `POST /api/v1/live/streams`
- Get LiveKit token: `POST /api/v1/live/streams/{id}/livekit-token`
- Connect to LiveKit room
- Broadcast or view stream

**Features:**
- Real-time video/audio
- Live comments
- Viewer count
- Stream recording (backend)

### Video Meetings

**LiveKit Integration:**
- Create meeting: `POST /api/v1/live/streams`
- Get LiveKit token
- Connect to meeting room
- Multi-participant support
- Screen sharing (LiveKit feature)

**Meeting Types:**
- Instant meetings
- Scheduled meetings
- Recurring meetings (not implemented)

### Voice Agent

**AI Voice Assistant:**
- Create voice room: `POST /api/v1/livekit/voice/room`
- Get voice token: `POST /api/v1/livekit/voice/token`
- Connect to voice agent
- Speech-to-text (Deepgram)
- Text-to-speech (Deepgram)
- AI responses (OpenAI GPT-4o-mini)

---

## Deployment Configuration

### AWS Amplify

**Build Configuration:** `amplify.yml`

**Build Command:**
```bash
flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL \
  --dart-define=WEBSOCKET_URL=$WEBSOCKET_URL \
  --dart-define=ENVIRONMENT=production
```

**Environment Variables (Set in Amplify Console):**
- `API_BASE_URL`
- `MEDIA_BASE_URL`
- `LIVEKIT_WS_URL`
- `LIVEKIT_HTTP_URL`
- `WEBSOCKET_URL`
- `ENVIRONMENT`

### Local Development

**Run Command:**
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development
```

**Build Command:**
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development
```

### Production URLs

**API Base URL:** `https://api.christnewtabernacle.com/api/v1`
**Media Base URL:** `https://d126sja5o8ue54.cloudfront.net`
**LiveKit WS URL:** `wss://livekit.christnewtabernacle.com`
**LiveKit HTTP URL:** `https://livekit.christnewtabernacle.com`
**WebSocket URL:** `wss://api.christnewtabernacle.com`

---

## Known Issues & Areas for Improvement

### Current Issues

1. **Upload Progress:**
   - No progress indicators for large file uploads
   - May timeout on very large files
   - **Recommendation:** Implement chunked uploads with progress tracking

2. **File Size Limits:**
   - No explicit file size validation in frontend
   - Backend may have limits, but not communicated to user
   - **Recommendation:** Add file size validation before upload

3. **Error Handling:**
   - Some errors show technical messages
   - No retry logic for failed uploads
   - **Recommendation:** Improve error messages and add retry logic

4. **State Persistence:**
   - Editor state persists, but may become stale
   - No cleanup of old persisted state
   - **Recommendation:** Add state expiration and cleanup

5. **Performance:**
   - Large lists may cause performance issues
   - No virtual scrolling for very long lists
   - **Recommendation:** Implement virtual scrolling for large lists

6. **Accessibility:**
   - Limited keyboard navigation support
   - Screen reader support could be improved
   - **Recommendation:** Improve accessibility features

### Areas for Improvement

1. **Upload Features:**
   - Chunked uploads for large files
   - Upload queue for multiple files
   - Resume failed uploads
   - Upload progress indicators

2. **User Experience:**
   - Better loading states
   - Skeleton screens for all loading states
   - Optimistic UI updates
   - Better error recovery

3. **Performance:**
   - Image lazy loading
   - Code splitting
   - Service worker for offline support
   - Caching strategy improvements

4. **Features:**
   - Search filters
   - Advanced content discovery
   - User recommendations
   - Social sharing features

5. **Testing:**
   - Unit tests for services
   - Widget tests for components
   - Integration tests for workflows
   - E2E tests for critical paths

---

## Summary

The CNT Media Platform Web Application is a **comprehensive, production-ready Flutter Web application** with:

✅ **Complete Feature Set:**
- Content consumption (podcasts, movies, music, Bible)
- Content creation (audio/video with professional editing)
- Social features (community posts, likes, comments)
- Real-time features (live streaming, meetings, voice agent)
- Admin dashboard (content moderation, user management)

✅ **Well-Structured Architecture:**
- Clean separation of concerns
- Provider-based state management
- Service layer for API calls
- Reusable widget components
- Consistent design system

✅ **Production Deployment:**
- AWS Amplify hosting
- Environment-based configuration
- CloudFront CDN for media
- Secure authentication
- Real-time WebSocket support

✅ **Professional UI/UX:**
- Responsive design
- Modern Material Design
- Consistent color scheme
- Smooth animations
- Loading states and error handling

**The application is ready for feature enhancements and bug fixes as needed.**

---

**Document Created:** Complete web application analysis  
**Last Updated:** Current  
**Status:** ✅ Comprehensive understanding achieved
