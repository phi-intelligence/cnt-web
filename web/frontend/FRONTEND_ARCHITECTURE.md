# CNT Web Frontend Architecture Documentation

## Overview
This Flutter web application is a Christian media platform for Christ New Tabernacle, featuring podcasts, meetings, community features, and content creation tools. The app uses a clean architecture with Provider state management and follows Material Design principles with a custom warm brown/cream color scheme.

## Project Structure

### Core Architecture
```
lib/
├── config/           # App configuration
├── constants/        # App constants
├── layouts/          # Layout components
├── models/           # Data models
├── navigation/       # Routing and navigation
├── providers/        # State management (Provider pattern)
├── screens/          # All screen/page components
├── services/         # API and external services
├── theme/            # Design system (colors, typography, spacing)
├── utils/            # Utility functions
├── widgets/          # Reusable UI components
└── main.dart         # App entry point
```

## Design System

### Color Palette (`theme/app_colors.dart`)
The app uses a warm, Christian-themed color scheme:

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
- `textInverse`: `#F7F5F2` (Light text on dark backgrounds)

### Typography (`theme/app_typography.dart`)
- Consistent font sizing and weights
- Responsive text scaling
- Semantic naming (heading1, heading2, body, caption, etc.)

### Spacing (`theme/app_spacing.dart`)
- Standardized spacing values
- Consistent padding and margins
- Responsive spacing utilities

## Navigation Structure

### Main Navigation (`navigation/web_navigation.dart`)
The app uses a sidebar navigation layout with the following main sections:

1. **Home** - Dashboard with content overview
2. **Search** - Content search functionality
3. **Create** - Content creation hub
4. **Community** - Social features and posts
5. **Podcasts** - Audio/video podcast library
6. **Movies** - Movie content library
7. **About** - Information about the platform
8. **My Profile** - User profile and settings
9. **Admin Dashboard** - Admin-only features (conditional)

### Layout System (`layouts/web_layout.dart`)
- **Sidebar**: 280px fixed width navigation
- **Content Area**: Flexible main content area
- **Global Audio Player**: Bottom-mounted persistent player

## Screen Categories

### 1. Authentication Screens (`screens/web/`)
- **`landing_screen_web.dart`**: Beautiful landing page with integrated login
  - Responsive design (desktop/tablet/mobile)
  - Feature showcase cards
  - Login form with validation
  - Background image integration

- **`register_screen_web.dart`**: User registration
- **`user_login_screen_web.dart`**: Standalone login screen

### 2. Main Content Screens (`screens/web/`)

#### **Home Screen (`home_screen_web.dart`)**
- **Hero Carousel**: Featured content carousel
- **Welcome Section**: Personalized greeting and quick actions
- **Content Sections**:
  - Audio Podcasts (disc design)
  - Video Podcasts (card grid)
  - Bible Reader Section
  - Recently Played
  - Movies
  - Featured Music
  - User Playlists
  - Bible Stories

#### **Content Discovery**
- **`search_screen_web.dart`**: Advanced search with filters
- **`discover_screen_web.dart`**: Content discovery and recommendations
- **`podcasts_screen_web.dart`**: Podcast library with categories
- **`movies_screen_web.dart`**: Movie collection
- **`music_screen_web.dart`**: Music library

#### **Content Creation (`create_screen_web.dart`)**
Grid of creation options:
- **Video Podcast**: Video recording and editing
- **Audio Podcast**: Audio recording and editing
- **Meeting**: Schedule or start meetings
- **Document**: Upload documents (admin only)
- **Live Stream**: Start live broadcasting
- **Quote**: Create inspirational quotes

#### **Community Features**
- **`community_screen_web.dart`**: Social posts and interactions
- **`profile_screen_web.dart`**: User profiles and settings

#### **Specialized Screens**
- **`bible_stories_screen_web.dart`**: Bible content
- **`prayer_screen_web.dart`**: Prayer features
- **`live_screen_web.dart`**: Live streaming
- **`meetings_screen_web.dart`**: Meeting management

### 3. Admin Screens (`screens/admin/`)
- **`admin_dashboard_page.dart`**: Admin overview
- **`admin_users_page.dart`**: User management
- **`admin_posts_page.dart`**: Content moderation
- **`admin_audio_page.dart`**: Audio content management
- **`admin_video_page.dart`**: Video content management
- **`admin_documents_page.dart`**: Document management
- **`admin_support_page.dart`**: Support ticket management

### 4. Media Players (`screens/audio/`, `screens/video/`)
- **`audio_player_full_screen_web.dart`**: Full-screen audio player
- **`video_player_full_screen.dart`**: Full-screen video player
- **`audio_player_full_screen_new.dart`**: Enhanced audio player

### 5. Creation Workflows (`screens/creation/`)
- **`audio_podcast_create_screen.dart`**: Audio creation workflow
- **`video_podcast_create_screen.dart`**: Video creation workflow
- **`quote_create_screen_web.dart`**: Quote creation
- **Recording screens**: Audio/video recording interfaces
- **Preview screens**: Content preview before publishing

## Widget Architecture

### 1. Web-Specific Widgets (`widgets/web/`)

#### **Navigation Components**
- **`sidebar_nav.dart`**: Main sidebar navigation
- **`sidebar_action_box.dart`**: Quick action boxes in sidebar

#### **Content Display**
- **`content_card_web.dart`**: Standard content cards with hover effects
- **`disc_card_web.dart`**: Circular disc-style cards for audio content
- **`featured_categories_web.dart`**: Category showcase
- **`welcome_section_web.dart`**: Personalized welcome area

#### **UI Components**
- **`styled_page_header.dart`**: Consistent page headers
- **`styled_filter_chip.dart`**: Filter chips for search/categories
- **`styled_pill_button.dart`**: Pill-style buttons
- **`styled_search_field.dart`**: Search input components
- **`section_container.dart`**: Consistent section containers

### 2. Shared Widgets (`widgets/shared/`)
- **`content_section.dart`**: Flexible content section component
- **`loading_shimmer.dart`**: Loading state animations
- **`empty_state.dart`**: Empty state illustrations
- **`image_helper.dart`**: Image loading and fallback utilities
- **`badge_widget.dart`**: Status badges

### 3. Media Widgets (`widgets/media/`)
- **`global_audio_player.dart`**: Persistent bottom audio player
- **`sliding_audio_player.dart`**: Collapsible audio player
- **`voice_bubble_player.dart`**: Voice message player

### 4. Specialized Widgets
- **`widgets/admin/`**: Admin-specific components
- **`widgets/audio/`**: Audio-related widgets (vinyl disc animations)
- **`widgets/bible/`**: Bible reading components
- **`widgets/community/`**: Social media components
- **`widgets/meeting/`**: Video conferencing components
- **`widgets/notifications/`**: Notification components
- **`widgets/voice/`**: Voice chat components

## State Management

### Provider Architecture (`providers/`)
- **`auth_provider.dart`**: Authentication state
- **`app_state.dart`**: Global app state
- **`audio_player_provider.dart`**: Audio playback state
- **`music_provider.dart`**: Music library state
- **`community_provider.dart`**: Social features state
- **`search_provider.dart`**: Search functionality state
- **`user_provider.dart`**: User profile state
- **`playlist_provider.dart`**: Playlist management
- **`favorites_provider.dart`**: Favorites management
- **`support_provider.dart`**: Support ticket state
- **`documents_provider.dart`**: Document management
- **`notification_provider.dart`**: Notification state

## Services Layer (`services/`)

### Core Services
- **`api_service.dart`**: Main API communication
- **`auth_service.dart`**: Authentication handling
- **`websocket_service.dart`**: Real-time communication

### Media Services
- **`audio_editing_service.dart`**: Audio processing
- **`video_editing_service.dart`**: Video processing
- **`download_service.dart`**: Content downloading

### External Services
- **`google_auth_service.dart`**: Google authentication
- **`livekit_meeting_service.dart`**: Video conferencing
- **`livekit_voice_service.dart`**: Voice chat
- **`donation_service.dart`**: Payment processing

## Key Features

### 1. Content Management
- **Multi-format Support**: Audio, video, documents, images
- **Real-time Upload**: Progress tracking and validation
- **Content Moderation**: Admin approval workflows
- **Categorization**: Organized content taxonomy

### 2. Media Playback
- **Global Audio Player**: Persistent playback across navigation
- **Playlist Support**: Custom playlists and queues
- **Offline Support**: Download for offline viewing
- **Quality Selection**: Multiple quality options

### 3. Live Features
- **Live Streaming**: Real-time broadcasting
- **Video Meetings**: Multi-participant video calls
- **Voice Chat**: Real-time voice communication
- **Live Comments**: Real-time interaction during streams

### 4. Community Features
- **Social Posts**: Text, image, and video posts
- **Comments System**: Threaded discussions
- **User Profiles**: Customizable user profiles
- **Following System**: User connections

### 5. Admin Features
- **Content Moderation**: Approve/reject content
- **User Management**: User roles and permissions
- **Analytics Dashboard**: Usage statistics
- **Support System**: Ticket management

## Responsive Design

### Breakpoints
- **Mobile**: < 768px
- **Tablet**: 768px - 1024px
- **Desktop**: > 1024px

### Responsive Components
- **Grid Layouts**: Adaptive column counts
- **Navigation**: Collapsible sidebar on mobile
- **Cards**: Responsive sizing and spacing
- **Typography**: Scalable text sizes

## UI Patterns

### 1. Card-Based Design
- **Content Cards**: Consistent card layouts for all content types
- **Hover Effects**: Interactive feedback on web
- **Shadow System**: Consistent elevation and shadows

### 2. Navigation Patterns
- **Sidebar Navigation**: Persistent navigation for desktop
- **Breadcrumbs**: Clear navigation hierarchy
- **Tab Navigation**: Secondary navigation within screens

### 3. Loading States
- **Shimmer Loading**: Skeleton screens during data loading
- **Progressive Loading**: Incremental content loading
- **Error States**: Graceful error handling with retry options

### 4. Interactive Elements
- **Hover States**: Visual feedback for interactive elements
- **Focus States**: Keyboard navigation support
- **Animation**: Smooth transitions and micro-interactions

## Development Guidelines

### 1. Component Structure
- Keep components focused and single-purpose
- Use composition over inheritance
- Implement proper error boundaries
- Follow consistent naming conventions

### 2. State Management
- Use Provider for global state
- Keep local state minimal
- Implement proper loading and error states
- Use immutable state updates

### 3. Performance
- Implement lazy loading for large lists
- Optimize image loading and caching
- Use proper widget keys for list items
- Minimize unnecessary rebuilds

### 4. Accessibility
- Implement proper semantic markup
- Support keyboard navigation
- Provide alternative text for images
- Ensure sufficient color contrast

## Assets and Resources

### Images (`assets/images/`)
- **Logo**: `ChatGPT Image Nov 18, 2025, 07_33_01 PM.png`
- **Thumbnails**: `thumb2.jpg` through `thumb8.jpg`
- **Fallback Images**: `thumbnail1.jpg`

### Configuration
- **Environment Variables**: API endpoints, service URLs
- **App Configuration**: `config/app_config.dart`
- **Constants**: `constants/app_constants.dart`

## Summary for UI Redesign

This Flutter web application follows a well-structured architecture with:

1. **Modular Design**: Clear separation of concerns with dedicated folders for screens, widgets, services, and state management
2. **Consistent Design System**: Unified color palette, typography, and spacing
3. **Responsive Layout**: Adaptive design for different screen sizes
4. **Rich Media Support**: Comprehensive audio/video playback and creation tools
5. **Admin Features**: Complete content management and user administration
6. **Real-time Features**: Live streaming, meetings, and chat functionality

The codebase is well-organized for UI redesign work, with clear separation between business logic and presentation layers. The existing design system provides a solid foundation that can be enhanced while maintaining consistency across the application.