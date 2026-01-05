# Christ New Tabernacle (CNT) Media Platform - Codebase Analysis

## 1. Project Overview
The CNT Media Platform is a sophisticated hybrid application combining media streaming (Spotify/Netflix-like), social networking, and real-time communication.

**Key Technologies:**
- **Frontend**: Flutter Web (hosted on AWS Amplify).
- **Backend**: FastAPI (Python 3.11, hosted on AWS EC2).
- **Database**: PostgreSQL (Production/RDS), SQLite (Development).
- **Real-time**: LiveKit (Video/Audio), Socket.IO (Signaling/Chat).
- **AI**: OpenAI & Deepgram (via LiveKit Voice Agent).
- **Storage**: AWS S3 + CloudFront CDN.

## 2. Architecture

```mermaid
graph TD
    User[User (Web/Mobile)]
    LB[AWS ALB / Nginx]
    Amplify[AWS Amplify (Frontend)]
    EC2[AWS EC2 (Backend)]
    RDS[(PostgreSQL RDS)]
    S3[(AWS S3 Media)]
    CF[CloudFront CDN]
    LiveKit[LiveKit Server]
    VoiceAgent[Voice Agent Service]

    User --> Amplify
    User --> |API Requests| LB
    User --> |Media Stream| CF
    User --> |Real-time A/V| LiveKit

    LB --> EC2
    EC2 --> RDS
    EC2 --> LiveKit
    EC2 --> VoiceAgent
    CF --> S3

    subgraph Backend Services
        EC2
        VoiceAgent
    end
```

## 3. Backend Implementation (`backend/app`)

### Framework & Configuration
- **FastAPI**: Main entry point in `main.py`. Configured with CORS, ProxyHeadersMiddleware (for AWS ALB), and global exception handling.
- **Socket.IO**: Integrated via `sio = AsyncServer(...)` wrapped around the FastAPI app for real-time messaging.

### Key Components
- **Routes** (`/routes`):
    - `auth.py`: JWT-based authentication.
    - `community.py`: Social features (posts, comments).
    - `media.py`: Handling content (sermons, music).
    - `live_stream.py`: Managing live events and signaling.
    - `admin.py`: Administrative controls.
- **Models** (`/models`): SQLAlchemy models defining the schema. Key entities include `User`, `Content`, `Playlist`, `BibleStory`, `LiveSession`.
- **Services** (`/services`): Business logic isolation.
    - `livekit_service.py`: Interaction with LiveKit API for token generation and room management.
    - `video_editing_service.py` & `media_service.py`: Content processing.

### Voice Agent
- **Infrastructure**: Runs as a separate process (managed by `main.py` or Docker).
- **Tech**: Uses `livekit-agents`, `openai`, `deepgram`.
- **Functionality**: Provides conversational AI capabilities within calls/meetings.

## 4. Frontend Implementation (`web/frontend`)

### Structure (Flutter Web)
- **Framework**: Flutter 3.x tailored for Web.
- **Entry Point**: `lib/main.dart` initializes `AppRouter` and preloads fonts.
- **Routing**: `go_router` used for deep linking and navigation (`lib/navigation`).

### State Management & Architecture
- **Provider**: Primary state management solution (replacing Riverpod references).
- **Services Pattern**: `lib/services/` contains singletons for API interaction.
    - `api_service.dart`: Base HTTP client (Dio/Http).
    - `auth_service.dart`: Auth state and storage.
    - `livekit_meeting_service.dart`: Manages active conference sessions.
- **UI Components**: `lib/widgets` contains reusable "Pill" shaped buttons/inputs, consistent with the "Premium" aesthetic.

## 5. Infrastructure & Deployment

### AWS Integration
- **Amplify**: `amplify.yml` defines the build pipeline.
    - Uses `dart-define` to inject environment variables (API URL, keys) at build time.
    - **Environment Vars**: `API_BASE_URL`, `LIVEKIT_WS_URL`, `ENVIRONMENT=production`.
- **EC2**: Python backend runs here.
    - **Docker**: `backend/Dockerfile` builds a lightweight Python 3.11 environment with `ffmpeg` installed.
    - **Process Management**: `docker-compose` (likely used for orchestration) or systemd.

### Database
- **Development**: SQLite (`backend/local.db`).
- **Production**: AWS RDS (PostgreSQL). Connection strings managed via `.env`.

### Real-time & Media
- **LiveKit**: Dedicated server for WebRTC.
- **Voice Agent**: Python process running alongside backend or in a container.
- **Media**: Uploads go to S3, served via CloudFront for low latency.

## 6. Development Workflow
- **Frontend**: `flutter run -d chrome` (Local).
- **Backend**: `uvicorn app.main:app --reload` (Local) or Docker.
- **Build**: `flutter build web --release` (Production).
