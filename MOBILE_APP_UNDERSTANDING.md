# CNT Media Platform - Mobile Application Understanding

**Date:** December 8, 2024  
**Status:** Production Ready (Code Complete, Pending Store Submission)  
**Version:** 1.0.0

---

## Executive Summary

The CNT Media Platform mobile application is a **production-ready** Flutter-based Christian media platform for iOS and Android. It provides a comprehensive media consumption and creation experience with social features, real-time communication, and professional editing tools.

### Key Statistics
- **Framework:** Flutter 3.0+ (Dart SDK >=3.0.0 <4.0.0)
- **Platforms:** iOS & Android
- **State Management:** Provider (primary), Riverpod (secondary)
- **14 State Providers** managing application state
- **18+ Mobile-Specific Screens** + shared screens
- **5-Tab Bottom Navigation** structure
- **2400+ lines** of API service code
- **100+ API Endpoints** integrated

---

## Architecture Overview

### Technology Stack

**Core Framework:**
- Flutter 3.0+ with Dart
- Material Design with custom theme (cream/brown color scheme)

**State Management:**
- **Primary:** Provider (ChangeNotifier pattern) - 14 providers
- **Secondary:** Riverpod (declarative state)
- **Local State:** StatefulWidget for UI-only state

**Backend Communication:**
- **REST API:** `http` package for API calls
- **WebSocket:** `socket_io_client` for real-time updates
- **Authentication:** JWT tokens stored in `flutter_secure_storage`

**Local Storage:**
- **SQLite:** `sqflite` for offline downloads
- **SharedPreferences:** App preferences
- **Secure Storage:** `flutter_secure_storage` for tokens

**Media Playback:**
- `just_audio` - Primary audio player
- `video_player` - Video playback
- `audioplayers` - Secondary audio support

**Real-time Communication:**
- **LiveKit:** Meetings, live streams, voice agent
- **WebSocket:** Real-time notifications

**Maps & Location:**
- `flutter_map` (OpenStreetMap) - Map display
- `geolocator` - Location services
- `geocoding` - Address resolution

### Application Entry Point

**Main File:** `lib/main.dart`
1. Initializes Flutter bindings
2. Loads environment configuration from `.env`
3. Initializes `AppRouter`
4. Sets up 14 state providers
5. Routes to `SplashScreen` (unauthenticated) or `MobileNavigationLayout` (authenticated)

**Environment Configuration:**
- Loaded from `.env` file via `flutter_dotenv`
- Production URLs set via environment variables
- Development defaults: localhost (iOS) or 10.0.2.2 (Android emulator)

**Required Environment Variables:**
- `ENVIRONMENT` (development/production)
- `API_BASE_URL`
- `WEBSOCKET_URL`
- `MEDIA_BASE_URL`
- `LIVEKIT_WS_URL`
- `LIVEKIT_HTTP_URL`

---

## Application Structure

### Directory Organization

```
mobile/frontend/lib/
├── config/              # Environment & configuration
│   └── environment.dart
├── constants/           # App constants
│   └── app_constants.dart
├── models/              # Data models (8 models)
│   ├── api_models.dart
│   ├── content_item.dart
│   ├── event.dart
│   ├── location_result.dart
│   └── ...
├── navigation/          # Routing & navigation
│   ├── app_router.dart
│   └── mobile_navigation.dart
├── providers/           # State management (14 providers)
│   ├── auth_provider.dart
│   ├── audio_player_provider.dart
│   ├── event_provider.dart
│   └── ...
├── screens/             # All application screens
│   ├── mobile/          # Main mobile screens (5 tabs)
│   ├── admin/           # Admin dashboard screens (11 pages)
│   ├── events/          # Events feature screens (4 screens)
│   ├── creation/        # Content creation screens (6 screens)
│   ├── meeting/         # Meeting/streaming screens (5 screens)
│   ├── editing/         # Audio/video editors (2 screens)
│   └── ...
├── services/            # Backend integration services (10 services)
│   ├── api_service.dart (2400+ lines)
│   ├── auth_service.dart
│   ├── livekit_meeting_service.dart
│   └── ...
├── theme/               # UI theme & styling
│   ├── app_colors.dart
│   ├── app_typography.dart
│   └── app_theme.dart
├── utils/               # Utility functions
│   ├── media_utils.dart
│   └── format_utils.dart
└── widgets/             # Reusable UI components
    ├── mobile/          # Mobile-specific widgets
    ├── shared/          # Shared widgets
    └── ...
```

---

## Navigation & Routing

### Main Navigation Structure

**5-Tab Bottom Navigation Bar:**

1. **Home** (`HomeScreenMobile`)
   - Featured content carousel
   - Audio podcasts (disc design)
   - Video podcasts (180px cards)
   - Bible reader access
   - Daily Bible quote (80px height)
   - Movies (180px cards)
   - Animated Bible stories (180px cards)
   - Recently played content
   - Voice assistant bubble

2. **Search** (`SearchScreenMobile`)
   - Pill-shaped search field
   - Content type filters: All, Audio, Video, Movies, Music
   - Real-time search with debouncing
   - Filter-based content fetching

3. **Create** (`CreateScreenMobile`)
   - Video Podcast (record/upload)
   - Audio Podcast (record/upload)
   - Quote creation
   - Meeting scheduling
   - Live Stream setup
   - Events creation

4. **Community** (`CommunityScreenMobile`)
   - Post feed with images/text
   - Create new posts
   - Like/comment interactions
   - Deep linking support
   - Pull-to-refresh

5. **Profile** (`ProfileScreenMobile`)
   - Artist profile management
   - Bank details
   - Edit profile
   - Favorites
   - Downloads
   - Library
   - Notifications
   - Help & Support
   - Admin Dashboard (if admin)
   - Logout

### Navigation Flow

```
AppRouter (app_router.dart)
├── SplashScreen (if not authenticated)
│   └── UserLoginScreen / RegisterScreen
└── MobileNavigationLayout (if authenticated)
    ├── HomeScreenMobile
    ├── SearchScreenMobile
    ├── CreateScreenMobile
    ├── CommunityScreenMobile
    └── ProfileScreenMobile
```

### Key Navigation Features
- **Sliding Audio Player:** Overlay on Home screen when audio is playing
- **Community Post Navigation:** Deep linking to specific posts from carousel
- **Admin Dashboard:** Accessible from Profile screen for admin users
- **Events Navigation:** Events list and creation from Create screen
- **Back Button Handling:** Custom PopScope logic (minimize player or navigate home)

---

## State Management

### Provider Architecture

**14 State Providers Registered:**

1. **AuthProvider** - Authentication state, user data, admin status
2. **AppState** - Global application state
3. **MusicProvider** - Music tracks management
4. **CommunityProvider** - Community posts & interactions
5. **AudioPlayerState** - Audio playback state & queue
6. **SearchProvider** - Search functionality & filtering
7. **UserProvider** - User profile data
8. **PlaylistProvider** - User playlists
9. **FavoritesProvider** - Favorite content
10. **SupportProvider** - Support tickets & messages
11. **DocumentsProvider** - Bible documents
12. **NotificationProvider** - In-app notifications
13. **ArtistProvider** - Artist profiles
14. **EventProvider** - Events management

### State Management Pattern
- **Primary:** Provider (ChangeNotifier pattern)
- **Secondary:** Riverpod (declarative state)
- **Local State:** StatefulWidget for UI-only state
- **Persistence:** Secure storage for tokens, SQLite for downloads

---

## Core Features & Screens

### 1. Home Screen (`home_screen_mobile.dart`)

**Content Sections (in order):**
1. **Hero Carousel** - Featured community posts with images (clickable → Community)
2. **Voice Assistant Bubble** - Quick access to AI voice agent
3. **Audio Podcasts** - Horizontal scrolling audio content (disc design)
4. **Video Podcasts** - Horizontal scrolling video content (180px cards)
5. **Bible Reader** - Quick access to Bible documents
6. **Daily Bible Quote** - Random verse display (standardized 80px height)
7. **Movies** - Horizontal scrolling movie cards (180px cards)
8. **Animated Bible Stories** - Bible story animations (180px cards)
9. **Recently Played** - User's recent media

**Features:**
- Parallax scroll effects on carousel
- Continuous audio playback queue
- Section-aware content loading
- Scroll performance optimization (throttled updates)
- Optimized card heights (180px for video/movie content)

### 2. Search Screen (`search_screen_mobile.dart`)

**Features:**
- Pill-shaped search field
- Content type filters: All, Audio, Video, Movies, Music
- Real-time search with debouncing
- Filter-based content fetching (shows all content of selected type)
- Results display with content cards

### 3. Create Screen (`create_screen_mobile.dart`)

**Creation Options:**
1. **Video Podcast** - Record or upload video
2. **Audio Podcast** - Record or upload audio
3. **Quote** - Create inspirational quote images
4. **Meeting** - Schedule or join meetings
5. **Live Stream** - Start live streaming
6. **Events** - Host community events with map location

**Design:** White/brown theme with pill-shaped buttons

### 4. Community Screen (`community_screen_mobile.dart`)

**Features:**
- Post feed with images, text, likes, comments
- Create new posts
- Like/comment interactions
- Deep linking support (navigate to specific post)
- Pull-to-refresh

### 5. Profile Screen (`profile_screen_mobile.dart`)

**Sections (in order):**
1. **Artist Profile** - Artist profile management (if applicable)
2. **Bank Details** - Payment information
3. **Edit Profile** - User information editing
4. **Favorites** - Saved content
5. **Downloads** - Offline content
6. **Library** - User's content library
7. **Notifications** - In-app notifications
8. **Help & Support** - Support center (pill-shaped design)
9. **Admin Dashboard** - Admin access (if admin)
10. **Logout** - Sign out

**Design:** Cream background, warmBrown accents, pill-shaped elements

---

## Services & API Integration

### API Service (`api_service.dart`)

**Key Methods:**
- `getPodcasts()` - Fetch audio/video podcasts
- `getMovies()` - Fetch movies
- `getBibleStories()` - Fetch animated Bible stories
- `createPodcast()` - Upload new podcast
- `createEvent()` - Create new event
- `getEvents()` - Fetch events list
- `joinEvent()` / `leaveEvent()` - Event attendance
- `uploadFile()` - File upload to S3
- `getCommunityPosts()` - Fetch community posts
- Admin endpoints (approve/reject content, manage users, bulk upload)

**Authentication:**
- JWT tokens from `AuthService`
- Automatic token injection in headers
- Token refresh handling

### WebSocket Service (`websocket_service.dart`)

**Features:**
- Real-time notifications
- Live event updates
- Connection management
- Reconnection logic

### LiveKit Services

**Meeting Service** (`livekit_meeting_service.dart`):
- Video conferencing
- Room creation & joining
- Participant management
- Camera/microphone controls

**Voice Service** (`livekit_voice_service.dart`):
- AI voice agent integration
- Speech-to-text / Text-to-speech
- Voice chat functionality

---

## UI/UX Design System

### Color Scheme (`app_colors.dart`)

**Primary Colors:**
- `warmBrown` - Primary accent (#8B4513)
- `backgroundPrimary` - Cream background (#F5F0E8)
- `primaryDark` - Dark text
- `textSecondary` - Secondary text
- `textInverse` - White text on dark backgrounds
- `errorMain` - Error states (red)

### Typography (`app_typography.dart`)

**Text Styles:**
- `heading1` through `heading4`
- `body`, `caption`, `overline`
- Consistent font sizing & weights

### Spacing (`app_spacing.dart`)

**Standard Spacing:**
- `small`, `medium`, `large`, `extraLarge`
- Consistent padding/margin values

### Design Patterns

**Pill-Shaped Elements:**
- Text fields with `borderRadius: 30`
- Buttons with rounded corners
- Consistent across login, register, profile, search, admin pages
- Reusable `PillTextField` and `PillTextFieldOutlined` widgets

**Card Design:**
- White background with rounded corners (12-16px)
- Subtle shadows
- Warm brown content areas
- Standardized heights: 180px for video/movie cards

---

## Media Handling

### Audio Playback

**Player Features:**
- Sliding player overlay (minimized/expanded states)
- Continuous playback queue with auto-fetch
- Section-aware next track selection
- Background playback support
- "View Artist" button integration

**Player Screens:**
- `audio_player_full_screen_new.dart` - Full-screen audio player
- `SlidingAudioPlayer` widget - Overlay player

### Video Playback

**Player Features:**
- Full-screen video player
- Netflix-style controls (bottom bar on rotation)
- Playback controls (play, pause, seek, volume)
- Orientation handling

**Player Screen:**
- `video_player_full_screen.dart`

### Media Upload

**Audio Podcast:**
- Record new audio OR upload existing file
- Preview before publishing
- Metadata entry (title, description)
- Full API integration with progress tracking

**Video Podcast:**
- Record new video OR upload existing file
- Preview before publishing
- Metadata entry
- Full API integration with progress tracking

---

## Real-time Features

### Live Streaming

**Features:**
- Start live stream
- Join live streams
- Viewer count
- Chat integration
- Stream management

**Screens:**
- `live_stream_start_screen.dart`
- `live_streaming_screen.dart`

### Video Meetings

**Features:**
- Schedule meetings
- Join meetings by code
- Pre-join screen (camera/mic check with mirroring)
- Meeting room with participants
- Screen sharing
- Recording

**Screens:**
- `schedule_meeting_screen.dart`
- `join_meeting_screen.dart`
- `prejoin_screen.dart` (with camera mirroring fix)
- `meeting_room_screen.dart`

### AI Voice Agent

**Features:**
- Voice-based AI assistant
- Speech recognition
- Text-to-speech responses
- Conversation history

**Screen:**
- `ai_voice_agent_screen.dart`

---

## Admin Features

### Admin Dashboard (`admin_dashboard.dart`)

**4-Tab Navigation:**
1. **Dashboard** - Statistics & overview (hero section with stats grid)
2. **Content** - Content management (Pending/Approved/All)
3. **Users** - User management with role filtering
4. **Tools** - Utilities (Bulk Upload, Documents, Support)

### Content Management

**Features:**
- View pending content
- Approve/reject content with reasons
- Delete content
- Filter by type (Audio, Video, Movies, Posts)
- Search functionality
- Content detail view

### User Management

**Features:**
- List all users with search
- View user profiles
- Toggle admin status
- Delete users
- Filter by role (All, Admins, Artists, Regular)

### Tools

**Bulk Upload:**
- Upload multiple files
- Batch podcast creation with API integration
- Progress tracking with real status

**Bible Documents:**
- Upload PDF documents (cream/brown theme)
- Categorize documents
- Feature documents

**Support Tickets:**
- View all support messages
- Reply to tickets (pill-shaped input)
- Filter by status

---

## Events Feature

### Overview
A feature allowing users to host and attend community events with map-based location selection.

### Models
- **EventModel** - Event data with coordinates
- **EventHost** - Host user information
- **EventAttendee** - Attendance tracking
- **EventCreate** - Event creation payload
- **LocationResult** - Map picker result

### Screens

**Events List** (`events_list_screen.dart`):
- Tabs: All Events, My Events, Attending
- Event cards with cover images
- Attendance status indicators

**Event Create** (`event_create_screen.dart`):
- Title, description, date/time pickers
- Map-based location selection
- Max attendees setting
- Full API integration

**Event Detail** (`event_detail_screen.dart`):
- Event information display
- Mini-map with location marker
- Host information
- Attendee management (for hosts)
- Join/leave functionality

**Location Picker** (`location_picker_screen.dart`):
- Full-screen OpenStreetMap
- Address search
- Current location detection
- Tap to select location
- Reverse geocoding

### Backend Integration
- `POST /events/` - Create event
- `GET /events/` - List events
- `GET /events/{id}` - Event details
- `POST /events/{id}/join` - Request to join
- `DELETE /events/{id}/leave` - Leave event
- `PUT /events/{id}/attendees/{id}` - Approve/reject attendee

---

## Audio & Video Editors

### Audio Editor (`audio_editor_screen.dart`)

**Features:**
1. **Trim Audio** - Set start/end times
2. **Merge Audio** - Combine multiple files
3. **Fade Effects** - Fade in/out
4. **Audio Player** - Play/pause, seek, volume

**API Endpoints:**
- `POST /api/v1/audio-editing/trim`
- `POST /api/v1/audio-editing/merge`
- `POST /api/v1/audio-editing/fade-in`
- `POST /api/v1/audio-editing/fade-out`
- `POST /api/v1/audio-editing/fade-in-out`

### Video Editor (`video_editor_screen.dart`)

**Features:**
1. **Trim Video** - Set start/end times
2. **Audio Management** - Remove/add/replace audio
3. **Text Overlays** - Add text at timestamps
4. **Video Player** - Full-screen preview with controls

**API Endpoints:**
- `POST /api/v1/video-editing/trim`
- `POST /api/v1/video-editing/remove-audio`
- `POST /api/v1/video-editing/add-audio`
- `POST /api/v1/video-editing/replace-audio`
- `POST /api/v1/video-editing/add-text-overlays`

---

## Platform-Specific Configuration

### Android (`android/app/src/main/AndroidManifest.xml`)

**Permissions:**
- Internet & Network State
- Camera & Microphone
- Location (Fine & Coarse) - for Events map picker
- Storage (Read/Write)
- Foreground Service
- Wake Lock
- Vibration

**Configuration:**
- Application ID: `com.christtabernacle.cntmedia`
- Min SDK: 24 (Android 7.0)
- Target SDK: 34 (Android 14)
- MultiDex enabled
- ABI splits enabled (armeabi-v7a, arm64-v8a, x86_64)
- ProGuard/R8 enabled for release

### iOS (`ios/Runner/Info.plist`)

**Permissions:**
- Camera Usage Description
- Microphone Usage Description
- Photo Library Usage
- Location When In Use - for Events map picker

**Configuration:**
- Bundle Identifier: `com.christtabernacle.cntmedia`
- Display Name: CNT Media
- Background Modes: Audio, Fetch
- All orientations supported

---

## Dependencies & Technologies

### Core Dependencies

**State Management:**
- `provider: ^6.1.1`
- `flutter_riverpod: ^2.4.9`

**HTTP & Networking:**
- `http: ^1.1.0`
- `socket_io_client: ^2.0.3+1`
- `dio: ^5.4.0`
- `web_socket_channel: ^2.4.0`

**Media:**
- `just_audio: ^0.9.36`
- `video_player: ^2.8.2`
- `audioplayers: ^5.2.1`
- `camera: ^0.10.5`
- `record: ^6.1.2`

**Storage:**
- `flutter_secure_storage: ^9.0.0`
- `shared_preferences: ^2.2.2`
- `sqflite: ^2.3.0+2`

**Real-time:**
- `livekit_client: ^2.1.0`

**Maps & Location:**
- `flutter_map: ^6.1.0`
- `latlong2: ^0.9.0`
- `geolocator: ^11.0.0`
- `geocoding: ^3.0.0`

**UI:**
- `cached_network_image: ^3.3.1`
- `shimmer: ^3.0.0`
- `google_fonts: ^6.1.0`

**Other:**
- `google_sign_in: ^6.2.1`
- `url_launcher: ^6.2.2`
- `pdfx: ^2.4.0`
- `permission_handler: ^11.1.0`
- `intl: ^0.18.1`

---

## Production Deployment Status

### ✅ Completed Items

| Component | Status | Notes |
|-----------|--------|-------|
| Core Features | ✅ Complete | All 5 main tabs functional |
| Authentication | ✅ Complete | JWT + Google OAuth |
| Content Playback | ✅ Complete | Audio/video with continuous queue |
| Content Creation | ✅ Complete | Upload with actual API integration |
| Community Features | ✅ Complete | Posts, likes, comments |
| Events Feature | ✅ Complete | With map location picker |
| Admin Dashboard | ✅ Complete | Redesigned with 4-tab navigation |
| Real-time Features | ✅ Complete | LiveKit meetings, streams, voice |
| UI/UX Polish | ✅ Complete | Pill design, consistent theme |
| Bug Fixes | ✅ Complete | Card heights, overflow issues fixed |

### 🔄 Pending for Store Submission

| Task | Status | Notes |
|------|--------|-------|
| Android Keystore | 📋 Required | Generate production signing key |
| iOS Provisioning | 📋 Required | Apple Developer account setup |
| App Store Assets | 📋 Required | Screenshots, descriptions, icons |
| Privacy Policy | 📋 Required | Public URL for stores |
| App Store Review | 📋 Pending | Submit for review |
| Play Store Review | 📋 Pending | Submit for review |

### Build Commands

**Debug Build:**
```bash
flutter build apk --debug
```

**Production Build (Android):**
```bash
flutter build appbundle --release \
  --dart-define=ENVIRONMENT=production \
  --dart-define=API_BASE_URL=https://api.christnewtabernacle.com/api/v1 \
  --dart-define=WEBSOCKET_URL=wss://api.christnewtabernacle.com \
  --dart-define=MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net \
  --dart-define=LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com \
  --dart-define=LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
```

**Production Build (iOS):**
```bash
flutter build ios --release \
  --dart-define=ENVIRONMENT=production \
  # ... same environment variables
```

---

## Recent Updates & Bug Fixes

### Latest Session (December 8, 2024)

**🔧 Bug Fixes:**
- ✅ **Card Height Mismatch Fix** - Fixed white space at bottom of Video Podcasts, Movies, and Animated Bible Stories cards
  - **Root Cause:** `ContentSection` SizedBox height (210px) was larger than `HorizontalContentCardMobile` card height (180px)
  - **Fix:** Aligned SizedBox height to 180px and ListView container to 185px
  - **Files:** `lib/widgets/shared/content_section.dart`

### Previous Sessions

**UI/UX Enhancements:**
- ✅ Pill-shaped input fields across all forms
- ✅ Cream/brown theme consistency
- ✅ Card height standardization (180px)
- ✅ Bible quote box size standardization (80px)
- ✅ Admin dashboard redesign (4-tab navigation)
- ✅ Help & Support page redesign
- ✅ Login/Register pages with pill design

**Features Added:**
- ✅ Events feature with map-based location picker
- ✅ Continuous audio playback queue
- ✅ "View Artist" button in audio player
- ✅ Camera mirroring fix in prejoin screen
- ✅ File upload with actual API integration
- ✅ Bulk upload with progress tracking

**Bug Fixes:**
- ✅ RenderFlex overflow fixes
- ✅ Positioned widget hierarchy fixes
- ✅ PostgreSQL boolean comparison fixes (is_approved)
- ✅ Nullable type handling improvements
- ✅ LiveKit service connection fixes
- ✅ Backend NotificationService creation

---

## Key Files Reference

### Core Files
- `lib/main.dart` - Application entry point
- `lib/navigation/app_router.dart` - Main routing logic
- `lib/navigation/mobile_navigation.dart` - Bottom tab navigation
- `lib/config/environment.dart` - Environment configuration

### Main Screens
- `lib/screens/mobile/home_screen_mobile.dart` - Home feed
- `lib/screens/mobile/search_screen_mobile.dart` - Search
- `lib/screens/mobile/create_screen_mobile.dart` - Creation hub
- `lib/screens/mobile/community_screen_mobile.dart` - Community
- `lib/screens/mobile/profile_screen_mobile.dart` - Profile

### Services
- `lib/services/api_service.dart` - Backend API integration (2400+ lines)
- `lib/services/auth_service.dart` - Authentication
- `lib/services/livekit_meeting_service.dart` - Meetings
- `lib/services/websocket_service.dart` - Real-time updates

### Providers
- `lib/providers/auth_provider.dart` - Auth state
- `lib/providers/audio_player_provider.dart` - Audio playback
- `lib/providers/event_provider.dart` - Events management

### Widgets
- `lib/widgets/shared/pill_text_field.dart` - Reusable pill input
- `lib/widgets/shared/content_section.dart` - Content list display
- `lib/widgets/mobile/horizontal_content_card_mobile.dart` - Video/movie cards

---

## Summary

The CNT Media Platform mobile application is a **production-ready** Flutter-based media platform with:

### Core Statistics
- **5 main navigation tabs** (Home, Search, Create, Community, Profile)
- **14 state providers** managing application state
- **50+ screens** covering all features
- **2400+ lines** of API service code
- **4 admin dashboard tabs** for content/user management

### Feature Completeness
- ✅ **Real-time capabilities** via WebSocket and LiveKit
- ✅ **Media playback** for audio and video with continuous queue
- ✅ **Content creation** tools (audio/video podcasts, quotes, events)
- ✅ **Social features** (community posts, likes, comments)
- ✅ **Events feature** with map-based location picker
- ✅ **Admin dashboard** for content and user management
- ✅ **Modern UI/UX** with pill-shaped elements and cream/brown theme
- ✅ **Platform-specific** optimizations for iOS and Android

### Production Readiness
- ✅ All core features implemented and tested
- ✅ Backend integration complete
- ✅ UI polish and consistency applied
- ✅ Bug fixes for all known issues
- 📋 Awaiting app store submission (keystore, provisioning, assets)

The application follows Flutter best practices with proper state management, service layer separation, and responsive design patterns. Ready for production deployment pending store submission requirements.

---

**Document Created:** December 8, 2024  
**Status:** Complete understanding of mobile application architecture, features, and implementation  
**Next Steps:** Store submission preparation (keystore, provisioning, assets)









