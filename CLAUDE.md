# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

CNT (Christ New Tabernacle) Media Platform - A Christian media platform built with Flutter (web/mobile) frontend and FastAPI (Python) backend. Features podcasts, movies, meetings, community features, live streaming, and an AI voice agent.

## Architecture

```
cnt-web-deployment/
├── backend/           # FastAPI Python backend
├── web/frontend/      # Flutter Web application
├── mobile/frontend/   # Flutter Mobile application (iOS/Android)
├── livekit-server/    # LiveKit configuration for real-time features
├── nginx/             # Nginx reverse proxy configuration
└── deployment/        # Deployment scripts and configs
```

### Tech Stack
- **Backend**: FastAPI 0.104+, SQLAlchemy 2.0 (async), PostgreSQL (prod) / SQLite (dev)
- **Frontend**: Flutter 3.16+, Provider state management, go_router
- **Real-time**: LiveKit (meetings, voice agent), Socket.IO
- **AI**: OpenAI GPT-4o-mini, Deepgram (STT)
- **Storage**: AWS S3 + CloudFront CDN
- **Hosting**: AWS Amplify (web), EC2 (backend), RDS (database)

## Common Commands

### Backend Development

```bash
# Navigate to backend
cd backend

# Setup virtual environment (first time)
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Copy environment file
cp env.example .env
# Edit .env with your configuration

# Run backend server (port 8002)
./run.sh
# OR with voice agent
./start_backend.sh

# Run migrations
alembic revision --autogenerate -m "Description"
alembic upgrade head

# Import movies from media/movies/
python -m scripts.import_movies
python -m scripts.import_movies --prune-missing  # Remove deleted files
```

### Web Frontend Development

```bash
cd web/frontend

# Get dependencies
flutter pub get

# Run locally (requires dart-define for API URLs)
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8002/api/v1 \
  --dart-define=MEDIA_BASE_URL=http://localhost:8002 \
  --dart-define=LIVEKIT_WS_URL=ws://localhost:7880 \
  --dart-define=LIVEKIT_HTTP_URL=http://localhost:7881 \
  --dart-define=WEBSOCKET_URL=ws://localhost:8002 \
  --dart-define=ENVIRONMENT=development

# Build for production
flutter build web --release --no-source-maps \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  # ... other dart-defines
```

### Mobile Frontend Development

```bash
cd mobile/frontend

flutter pub get
flutter run  # Uses .env file for configuration
```

## Key Backend Structure

```
backend/app/
├── main.py              # FastAPI app entry point
├── config.py            # Environment configuration
├── database/            # SQLAlchemy models, session management
├── models/              # Pydantic response models
├── routes/              # API endpoints (100+ endpoints)
│   ├── auth.py          # Authentication (login, register, OAuth)
│   ├── podcasts.py      # Audio/video podcasts
│   ├── movies.py        # Movie content
│   ├── community.py     # Social posts, comments, likes
│   ├── upload.py        # File uploads (audio, video, images)
│   ├── audio_editing.py # Audio processing (trim, merge, fade)
│   ├── video_editing.py # Video processing (trim, overlays, filters)
│   └── livekit_voice.py # AI voice agent rooms
├── services/            # Business logic
├── schemas/             # Pydantic request/response schemas
└── agents/              # LiveKit AI voice agent
```

## Key Frontend Structure

```
web/frontend/lib/
├── main.dart           # App entry point
├── config/             # AppConfig (reads --dart-define values)
├── providers/          # Provider state management
├── services/           # API service, auth, media editing
├── screens/
│   ├── web/            # Main screens (home, podcasts, movies, etc.)
│   ├── admin/          # Admin dashboard pages
│   ├── audio/          # Audio player screens
│   ├── video/          # Video player screens
│   └── creation/       # Content creation workflows
├── widgets/
│   ├── web/            # Web-specific widgets
│   └── shared/         # Cross-platform widgets
└── theme/              # Color palette, typography, spacing
```

## Design System

The frontend uses a warm brown/cream color scheme defined in `theme/app_colors.dart`:
- Primary: `#8B7355` (warm brown)
- Accent: `#D4A574` (golden yellow)
- Background: `#F7F5F2` (cream)
- Text: `#2D2520` (dark brown)

## Database

21 tables including: `users`, `artists`, `podcasts`, `movies`, `music_tracks`, `community_posts`, `comments`, `likes`, `playlists`, `live_streams`, `document_assets`, `support_messages`, `notifications`, `categories`, etc.

## API Endpoints Pattern

All API routes are prefixed with `/api/v1/`:
- `POST /api/v1/auth/login` - Email/password login
- `POST /api/v1/auth/google-login` - Google OAuth
- `GET/POST /api/v1/podcasts` - Podcast CRUD
- `GET/POST /api/v1/movies` - Movie CRUD
- `POST /api/v1/upload/audio` - Audio file upload
- `POST /api/v1/upload/video` - Video file upload
- `POST /api/v1/audio-editing/trim` - Audio editing
- `POST /api/v1/video-editing/trim` - Video editing
- `GET /api/v1/livekit/voice/rooms` - Voice agent rooms

## Deployment

### Web Frontend (AWS Amplify)
Automatic deployment on push to main branch. See `amplify.yml` for build configuration.

### Backend (AWS EC2)
```bash
ssh -i christnew.pem ubuntu@52.56.78.203
cd /path/to/backend
git pull
sudo systemctl restart cnt-backend
```

## Environment Variables

### Backend (.env)
Required variables:
- `DATABASE_URL` - Database connection string
- `SECRET_KEY` - JWT signing key
- `LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET` - LiveKit credentials
- `OPENAI_API_KEY` - For AI voice agent
- `DEEPGRAM_API_KEY` - For speech-to-text
- `GOOGLE_CLIENT_ID` - For OAuth
- `AWS_*` - AWS credentials for S3 (production)

### Frontend (--dart-define)
Required build-time variables:
- `API_BASE_URL` - Backend API URL
- `MEDIA_BASE_URL` - Media server URL
- `LIVEKIT_WS_URL` - LiveKit WebSocket URL
- `LIVEKIT_HTTP_URL` - LiveKit HTTP URL
- `WEBSOCKET_URL` - Socket.IO URL
- `ENVIRONMENT` - development/production
- `GOOGLE_CLIENT_ID` - For OAuth
