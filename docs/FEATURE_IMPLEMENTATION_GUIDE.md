# CNT Media Platform - Feature Implementation Guide

**Version:** 3.0  
**Date:** December 5, 2025

---

## Table of Contents

1. [Content Consumption Features](#1-content-consumption-features)
2. [Content Creation Features](#2-content-creation-features)
3. [Social Features (Community)](#3-social-features-community)
4. [Real-Time Communication](#4-real-time-communication)
5. [Audio & Video Editing](#5-audio--video-editing)
6. [Admin Dashboard](#6-admin-dashboard)
7. [Artist Features](#7-artist-features)
8. [Payment & Donations](#8-payment--donations)

---

## 1. Content Consumption Features

### 1.1 Podcasts (Audio/Video)

#### Features
- List all approved podcasts
- Filter by category
- Search functionality
- Play count tracking
- Auto-thumbnail generation for video podcasts

#### API Endpoints
```
GET  /api/v1/podcasts              # List podcasts
GET  /api/v1/podcasts/{id}         # Get single podcast
POST /api/v1/podcasts              # Create podcast (auth required)
DELETE /api/v1/podcasts/{id}       # Delete podcast (creator/admin)
```

#### Implementation Details
**Backend (`backend/app/routes/podcasts.py`)**:
- Non-admin users see only approved podcasts
- Admin users see all podcasts
- Automatic artist profile creation on first upload
- Bank details check (soft warning)

**Frontend**:
- Web: `web/frontend/lib/screens/web/podcasts_screen_web.dart`
- Mobile: `mobile/frontend/lib/screens/mobile/podcasts_screen_mobile.dart`

#### Database Schema
```sql
podcasts (
    id, title, description,
    audio_url, video_url, cover_image,
    creator_id, category_id, duration,
    status (pending/approved/rejected),
    plays_count, created_at
)
```

### 1.2 Movies

#### Features
- Featured movies carousel
- Movie details with preview
- Similar movies recommendations
- Preview clips with configurable timestamps

#### API Endpoints
```
GET  /api/v1/movies                # List movies
GET  /api/v1/movies/featured       # Featured movies
GET  /api/v1/movies/{id}           # Movie details
GET  /api/v1/movies/{id}/similar   # Similar movies
POST /api/v1/movies                # Create movie (admin)
```

#### Implementation Details
- Preview generation: Extract clip from full video
- Preview timestamps: `preview_start_time`, `preview_end_time`
- Featured flag for hero carousel display

### 1.3 Music Tracks

#### Features
- Music library with genre filtering
- Artist filtering
- Track playback
- Lyrics display (optional)

#### API Endpoints
```
GET  /api/v1/music                 # List tracks
GET  /api/v1/music/{id}            # Track details
POST /api/v1/music                 # Create track (admin)
```

### 1.4 Bible Reader

#### Features
- PDF document viewer
- Holy Bible (KJV) auto-seeded
- Admin-only document uploads

#### API Endpoints
```
GET  /api/v1/documents             # List documents
GET  /api/v1/documents/{id}        # Document details
POST /api/v1/documents             # Upload document (admin)
```

#### Implementation
- Documents stored in S3: `documents/{filename}.pdf`
- Frontend PDF viewer integration

---

## 2. Content Creation Features

### 2.1 Audio Podcast Creation

#### Workflow
1. **Record or Upload**
   - Mobile: Device microphone recording
   - Web: Browser MediaRecorder API
   - File upload: MP3, WAV, WebM, M4A, AAC, FLAC

2. **Preview & Edit**
   - Audio player preview
   - Duration display
   - Optional editing (trim, fade)

3. **Add Details**
   - Title, description
   - Category selection
   - Thumbnail selection

4. **Upload**
   - Upload to S3: `audio/{uuid}.{ext}`
   - Create podcast record
   - Status: "pending" (requires approval)

#### API Flow
```
POST /api/v1/upload/audio
  → Returns: {filename, url, file_path, duration, thumbnail_url}

POST /api/v1/podcasts
  → Body: {title, description, audio_url, cover_image, category_id}
  → Returns: Podcast object
```

#### Implementation Files
- **Backend**: `backend/app/routes/upload.py`, `backend/app/routes/podcasts.py`
- **Web**: `web/frontend/lib/screens/creation/`
- **Mobile**: `mobile/frontend/lib/screens/creation/audio_*`

### 2.2 Video Podcast Creation

#### Workflow
1. **Record or Upload**
   - Mobile: Device camera recording
   - Web: Browser MediaRecorder API
   - Gallery: Select existing video

2. **Auto-Thumbnail Generation**
   - Extract frame at 45 seconds (or 10% of duration)
   - Save to S3: `images/thumbnails/podcasts/generated/{uuid}.jpg`

3. **Preview & Edit**
   - Video player preview
   - Optional editing (trim, audio, overlays)

4. **Upload**
   - Upload to S3: `video/{uuid}.{ext}`
   - Create podcast record

#### API Flow
```
POST /api/v1/upload/video?generate_thumbnail=true
  → Returns: {filename, url, file_path, duration, thumbnail_url}

POST /api/v1/podcasts
  → Body: {title, description, video_url, cover_image, category_id}
  → Returns: Podcast object
```

---

## 3. Social Features (Community)

### 3.1 Community Posts

#### Post Types
1. **Image Posts**: User-uploaded photos with captions
2. **Text Posts**: Auto-converted to styled quote images

#### Features
- Like/unlike system
- Comment threads
- Post categories (testimony, prayer_request, question, announcement, general)
- Admin approval workflow

#### API Endpoints
```
GET  /api/v1/community/posts       # List posts
POST /api/v1/community/posts       # Create post
POST /api/v1/community/posts/{id}/like      # Like/unlike
POST /api/v1/community/posts/{id}/comments  # Add comment
GET  /api/v1/community/posts/{id}/comments  # Get comments
```

### 3.2 Quote Image Generation

#### Process
1. User creates text post
2. Backend detects `post_type='text'`
3. `quote_image_service.py` generates styled image:
   - Selects random template
   - Renders text with PIL/Pillow
   - Wraps text to fit
   - Calculates optimal font size
4. Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
5. Updates post with `image_url`

#### Templates
- Predefined styles in `backend/app/services/quote_templates.py`
- Background images, fonts, colors
- Text positioning and alignment

#### Implementation
```python
# backend/app/services/quote_image_service.py
def generate_quote_image(post_id: int, text: str) -> str:
    template = random.choice(QUOTE_TEMPLATES)
    img = create_image_with_text(text, template)
    s3_url = upload_to_s3(img, f"images/quotes/quote_{post_id}.jpg")
    return s3_url
```

---

## 4. Real-Time Communication

### 4.1 Video Meetings

#### Features
- Instant meetings (create and join immediately)
- Scheduled meetings (set future start time)
- LiveKit room management
- JWT token generation for room access

#### API Endpoints
```
POST /api/v1/live/streams          # Create meeting/stream
GET  /api/v1/live/streams          # List meetings
POST /api/v1/live/streams/{id}/join            # Join meeting
POST /api/v1/live/streams/{id}/livekit-token   # Get LiveKit token
```

#### Implementation Flow
1. User creates meeting
2. Backend creates LiveKit room
3. Backend generates JWT token with room permissions
4. Frontend joins room with token
5. WebRTC connection established

#### Frontend Integration
```dart
// Get LiveKit token
final token = await apiService.post(
  '/live/streams/$streamId/livekit-token',
  {}
);

// Join room
await room.connect(
  AppConfig.livekitWsUrl,
  token['token'],
);
```

### 4.2 Live Streaming

#### Roles
- **Broadcaster**: Host streaming interface
- **Viewer**: Viewer interface (watch-only)

#### Screens
- `live_stream_broadcaster.dart` - Host interface
- `live_stream_viewer.dart` - Viewer interface
- `stream_creation_screen.dart` - Stream setup

#### Features
- Real-time video/audio streaming
- Chat integration (potential)
- Viewer count
- Stream recording (potential)

### 4.3 Voice Agent (AI Assistant)

#### Architecture
- **Framework**: LiveKit Agents SDK
- **LLM**: OpenAI GPT-4o-mini
- **STT**: Deepgram Nova-3
- **TTS**: Deepgram Aura-2-Andromeda

#### Room Naming Convention
- Voice agent only joins rooms with `voice-agent-` prefix
- Example: `voice-agent-user123-session456`

#### API Endpoints
```
POST /api/v1/livekit/voice/token   # Get voice agent token
POST /api/v1/livekit/voice/room    # Create voice room
DELETE /api/v1/livekit/voice/room/{name}  # Delete room
GET  /api/v1/livekit/voice/rooms   # List active rooms
GET  /api/v1/livekit/voice/health  # Agent health check
```

#### Implementation
**Backend (`backend/app/agents/voice_agent.py`)**:
```python
from livekit.agents import AutoSubscribe, JobContext, WorkerOptions, cli, llm
from livekit.agents.voice_assistant import VoiceAssistant
from livekit.plugins import openai, deepgram, silero

async def entrypoint(ctx: JobContext):
    initial_ctx = llm.ChatContext().append(
        role="system",
        text="You are a helpful Christian AI assistant..."
    )
    
    assistant = VoiceAssistant(
        vad=silero.VAD.load(),
        stt=deepgram.STT(),
        llm=openai.LLM(),
        tts=deepgram.TTS(),
        chat_ctx=initial_ctx,
    )
    
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    assistant.start(ctx.room)
```

---

## 5. Audio & Video Editing

### 5.1 Audio Editing Features

#### Available Operations

**1. Trim**
- API: `POST /api/v1/audio-editing/trim`
- Parameters: `start_time`, `end_time` (seconds)
- Backend: FFmpeg cut operation

**2. Merge**
- API: `POST /api/v1/audio-editing/merge`
- Parameters: Multiple audio files
- Backend: FFmpeg concatenation

**3. Fade In**
- API: `POST /api/v1/audio-editing/fade-in`
- Parameters: `fade_duration` (seconds)
- Backend: FFmpeg fade filter

**4. Fade Out**
- API: `POST /api/v1/audio-editing/fade-out`
- Parameters: `fade_duration`, `audio_duration`
- Backend: FFmpeg fade filter

**5. Fade In/Out**
- API: `POST /api/v1/audio-editing/fade-in-out`
- Parameters: `fade_in_duration`, `fade_out_duration`, `audio_duration`
- Backend: FFmpeg combined fade filter

#### Implementation Example
```python
# backend/app/services/audio_editing_service.py
import ffmpeg

def trim_audio(input_path: str, start_time: float, end_time: float) -> str:
    output_path = f"temp_{uuid.uuid4()}.mp3"
    
    (
        ffmpeg
        .input(input_path, ss=start_time, to=end_time)
        .output(output_path, acodec='copy')
        .run(overwrite_output=True)
    )
    
    return output_path
```

### 5.2 Video Editing Features

#### Available Operations

**1. Trim**
- API: `POST /api/v1/video-editing/trim`
- Parameters: `start_time`, `end_time`
- Backend: FFmpeg cut operation

**2. Remove Audio**
- API: `POST /api/v1/video-editing/remove-audio`
- Backend: FFmpeg removes audio track

**3. Add Audio**
- API: `POST /api/v1/video-editing/add-audio`
- Parameters: Video file + audio file
- Backend: FFmpeg adds audio track

**4. Replace Audio**
- API: `POST /api/v1/video-editing/replace-audio`
- Parameters: Video file + audio file
- Backend: FFmpeg replaces audio track

**5. Text Overlays**
- API: `POST /api/v1/video-editing/add-text-overlays`
- Parameters: `overlays_json` (array of overlay objects)
- Backend: FFmpeg drawtext filter

**6. Apply Filters** (Web only)
- API: `POST /api/v1/video-editing/apply-filters`
- Parameters: `brightness`, `contrast`, `saturation`
- Backend: FFmpeg filter effects

#### Text Overlay Structure
```json
{
  "overlays": [
    {
      "text": "Welcome to CNT",
      "start_time": 5.0,
      "end_time": 10.0,
      "x": 0.5,
      "y": 0.1,
      "font_family": "Arial",
      "font_size": 48,
      "color": "#FFFFFF",
      "background_color": "#000000",
      "alignment": "center"
    }
  ]
}
```

#### Implementation Example
```python
# backend/app/services/video_editing_service.py
def add_text_overlays(input_path: str, overlays: list) -> str:
    output_path = f"temp_{uuid.uuid4()}.mp4"
    
    # Build FFmpeg filter chain
    filters = []
    for overlay in overlays:
        filter_str = (
            f"drawtext=text='{overlay['text']}'"
            f":x={overlay['x']}:y={overlay['y']}"
            f":fontsize={overlay['font_size']}"
            f":fontcolor={overlay['color']}"
            f":enable='between(t,{overlay['start_time']},{overlay['end_time']})'"
        )
        filters.append(filter_str)
    
    (
        ffmpeg
        .input(input_path)
        .filter('drawtext', **overlay_params)
        .output(output_path)
        .run()
    )
    
    return output_path
```

---

## 6. Admin Dashboard

### 6.1 Admin Pages (7 Total)

1. **Dashboard** (`admin_dashboard_page.dart`)
   - Overview statistics
   - Total users, podcasts, posts
   - Pending approvals count

2. **Audio** (`admin_audio_page.dart`)
   - Audio podcast management
   - Approve/reject audio podcasts
   - View creator details

3. **Video** (`admin_video_page.dart`)
   - Video podcast management
   - Approve/reject video podcasts
   - Preview videos

4. **Posts** (`admin_posts_page.dart`)
   - Community post moderation
   - Approve/reject posts
   - View post details

5. **Users** (`admin_users_page.dart`)
   - User management
   - View user profiles
   - Ban/unban users (potential)

6. **Support** (`admin_support_page.dart`)
   - Support ticket handling
   - Respond to tickets
   - Mark as resolved

7. **Documents** (`admin_documents_page.dart`)
   - Bible/document management
   - Upload new documents
   - Delete documents

### 6.2 Admin API Endpoints

```
GET  /api/v1/admin/dashboard       # Statistics
GET  /api/v1/admin/pending         # Pending content
POST /api/v1/admin/approve/{type}/{id}  # Approve content
POST /api/v1/admin/reject/{type}/{id}   # Reject content
GET  /api/v1/admin/users           # List users
POST /api/v1/admin/users/{id}/ban  # Ban user
```

### 6.3 Approval Workflow

#### Content Types
- Podcasts (audio/video)
- Community posts
- Movies (admin-only creation)

#### Workflow
1. User creates content → Status: "pending"
2. Admin reviews in dashboard
3. Admin approves → Status: "approved" → Visible to all
4. Admin rejects → Status: "rejected" → Not visible

#### Auto-Approval
- Admin users: Content auto-approved
- Non-admin users: Requires approval

---

## 7. Artist Features

### 7.1 Artist Profile

#### Auto-Creation
- Artist profile automatically created when user uploads first podcast
- `artist_name` defaults to `user.name`
- Can be customized later

#### Features
- Cover image (banner)
- Bio
- Social links (JSON field)
- Followers count
- Total plays (aggregate from podcasts)
- Verification badge

### 7.2 Follow System

#### API Endpoints
```
POST   /api/v1/artists/{id}/follow    # Follow artist
DELETE /api/v1/artists/{id}/follow    # Unfollow artist
GET    /api/v1/artists/{id}/followers # Get followers
GET    /api/v1/artists/{id}/podcasts  # Get artist podcasts
```

#### Database
```sql
artist_followers (
    id, artist_id, user_id, created_at
    UNIQUE(artist_id, user_id)
)
```

### 7.3 Artist Management

#### API Endpoints
```
GET /api/v1/artists/me              # Get my artist profile
PUT /api/v1/artists/me              # Update profile
POST /api/v1/artists/me/cover-image # Upload cover image
GET /api/v1/artists/{id}            # Get artist profile
```

#### Screens
- Web: `web/frontend/lib/screens/artist/`
- Mobile: `mobile/frontend/lib/screens/artist/`

---

## 8. Payment & Donations

### 8.1 Bank Details

#### Purpose
- Creator payment information for revenue sharing
- Required for content monetization (future)

#### API Endpoints
```
GET  /api/v1/bank-details/me        # Get my bank details
POST /api/v1/bank-details           # Add bank details
PUT  /api/v1/bank-details/{id}      # Update bank details
```

#### Database Schema
```sql
bank_details (
    id, user_id, account_number,
    ifsc_code, swift_code, bank_name,
    account_holder_name, branch_name,
    is_verified, created_at, updated_at
)
```

### 8.2 Payment Gateways

#### Supported Gateways
- Stripe (primary)
- PayPal (alternative)

#### API Endpoints
```
POST /api/v1/donations              # Process donation
GET  /api/v1/donations/history      # Donation history
```

#### Implementation
- Stripe SDK integration
- PayPal SDK integration
- Webhook handling for payment confirmation

---

**Document Status**: Complete feature implementation guide for CNT Media Platform
