# LiveKit Implementation - Complete Analysis

**Analysis Date:** December 12, 2025  
**Focus:** LiveKit setup and implementation for meetings and voice agent  
**Status:** Production-ready on EC2

---

## Executive Summary

LiveKit is implemented as a **self-hosted real-time communication service** running on AWS EC2, providing:
1. **Video Meetings** - Multi-participant video conferencing
2. **Live Streaming** - Broadcaster and viewer capabilities
3. **Voice Agent** - AI-powered voice assistant using OpenAI + Deepgram

**Architecture:**
- **LiveKit Server:** Docker container on EC2 (ports 7880-7881, UDP 50100-50200)
- **Voice Agent:** Python agent process (separate container or subprocess)
- **Backend API:** FastAPI endpoints for token generation and room management
- **Frontend:** Flutter Web using `livekit_client` SDK

---

## 1. LiveKit Server Setup (EC2)

### 1.1 Docker Container Configuration

**Running on EC2:**
```bash
# Container: c92dbc70709a_cnt-livekit-server
# Image: livekit/livekit-server:latest
# Status: Up 4 days (healthy)

# Ports Exposed:
- 7880:7880 (WebSocket)
- 7881:7881 (HTTP/TCP RTC)
- 50100-50200:50100-50200/udp (RTC UDP)
```

**Container Details:**
- **Image:** `livekit/livekit-server:latest`
- **Command:** `/livekit-server --config /etc/livekit.yaml`
- **Health Status:** Healthy
- **Ports:**
  - TCP 7880: WebSocket connections
  - TCP 7881: HTTP API and TCP RTC
  - UDP 50100-50200: WebRTC media traffic

### 1.2 LiveKit Configuration (`livekit.yaml`)

**Location:** `livekit-server/livekit.yaml`

```yaml
port: 7880
bind_addresses:
  - "0.0.0.0"  # Listen on all interfaces

rtc:
  tcp_port: 7881
  port_range_start: 50100
  port_range_end: 50200
  use_external_ip: false  # Set to true in production if needed

# API Keys for authentication
keys:
  RvSL2BvFryECUIy2BELujY5E5mGUlSClNUZXPKWOJds: NCXkii10fq8DZ7z7m5b_cOx52-bJNGW9jv-WfvbQCqI

# Redis configuration (optional, for scaling)
# redis:
#   address: redis:6379

# TURN configuration (disabled for now)
turn:
  enabled: false  # Set to true in production if NAT traversal needed

# Development mode
development: false  # Production mode

# Log level
log_level: info

# Region (optional)
# region: eu-west-2
```

**Key Configuration Points:**
- **API Keys:** Stored in config file (should be in environment variables in production)
- **TURN:** Disabled (may need enabling for NAT traversal in some networks)
- **Port Range:** UDP 50100-50200 for WebRTC media
- **Bind Address:** 0.0.0.0 to accept connections from any interface

### 1.3 Environment Variables (Backend `.env`)

```env
# LiveKit Configuration
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com  # WebSocket URL
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com  # HTTP API URL
LIVEKIT_API_KEY=RvSL2BvFryECUIy2BELujY5E5mGUlSClNUZXPKWOJds
LIVEKIT_API_SECRET=NCXkii10fq8DZ7z7m5b_cOx52-bJNGW9jv-WfvbQCqI

# AI Services (for voice agent)
OPENAI_API_KEY=...
DEEPGRAM_API_KEY=...
```

**Production URLs:**
- **WebSocket:** `wss://livekit.christnewtabernacle.com` (port 7880)
- **HTTP API:** `https://livekit.christnewtabernacle.com` (port 7881)

**Internal Docker URLs (on EC2):**
- **WebSocket:** `ws://livekit-server:7880` (Docker internal)
- **HTTP API:** `http://livekit-server:7881` (Docker internal)

---

## 2. Backend Implementation

### 2.1 LiveKit Service (`services/livekit_service.py`)

**Purpose:** Token generation and room management

**Key Methods:**

#### **`create_access_token()`**
```python
def create_access_token(
    self,
    room_name: str,
    user_identity: str,
    participant_type: str = "user",
    can_publish: bool = True,
    can_subscribe: bool = True,
) -> str:
    """Generate LiveKit JWT access token"""
    grant = VideoGrants(
        room_join=True,
        room=room_name,
        can_publish=can_publish,
        can_subscribe=can_subscribe,
    )
    
    token = AccessToken(self.api_key, self.api_secret) \
        .with_identity(user_identity) \
        .with_name(user_identity) \
        .with_grants(grant) \
        .to_jwt()
    
    return token
```

**Token Components:**
- **API Key/Secret:** Used to sign the JWT
- **Identity:** Unique user identifier (e.g., `user_123_email@example.com`)
- **Grants:** Permissions (room_join, can_publish, can_subscribe)
- **Room Name:** Target room for the token

#### **`create_room()`**
```python
async def create_room(
    self,
    room_name: str,
    max_participants: int = 10
) -> dict:
    """Create a LiveKit room"""
    livekit_api = self._get_api_client()
    room = await livekit_api.room.create_room(
        CreateRoomRequest(
            name=room_name,
            max_participants=max_participants,
        )
    )
    return room info
```

#### **`delete_room()`** & **`list_rooms()`**
- Delete room: Removes room and disconnects all participants
- List rooms: Returns all active rooms with participant counts

### 2.2 Live Stream Routes (`routes/live_stream.py`)

**Endpoints for Meetings/Live Streaming:**

#### **`POST /api/v1/live/streams`** - Create Meeting/Stream
```python
# Creates LiveStream record in database
# Generates room name: "{title}-{uuid}"
# Sends Socket.io notification
# Returns LiveStreamResponse with room_name
```

**Flow:**
1. User creates stream/meeting
2. Backend generates unique room name (sanitized)
3. Creates database record in `live_streams` table
4. Emits Socket.io notification to all users
5. Sends push notifications
6. Returns room name and stream ID

#### **`POST /api/v1/live/streams/{stream_id}/join`** - Join Meeting
```python
# Gets LiveStream from database
# Generates LiveKit access token
# Returns: {token, url, room_name}
```

**Response:**
```json
{
  "token": "eyJ...",
  "url": "wss://livekit.christnewtabernacle.com",
  "room_name": "instant-meeting-abc123"
}
```

#### **`POST /api/v1/live/streams/{stream_id}/livekit-token`** - Get Token
```python
# Alternative endpoint to get just the token
# Returns: {token, ws_url, room_name}
```

**Token Generation:**
- Uses `LiveKitService.create_access_token()`
- User identity: From request or current user
- Permissions: `can_publish=True`, `can_subscribe=True`
- Room: From database `LiveStream.room_name`

### 2.3 Voice Agent Routes (`routes/livekit_voice.py`)

**Endpoints for Voice Agent:**

#### **`POST /api/v1/livekit/voice/token`** - Get Voice Token
```python
# Generates token for voice agent room
# Room name format: "voice-agent-{room_name}"
# Authentication: Optional (guest allowed)
# Returns: {token, room_name, ws_url}
```

**Key Differences from Meeting Token:**
- **Optional Auth:** Guests can connect (no login required)
- **Room Naming:** Uses `voice-agent-` prefix (agent filters by this)
- **Same Permissions:** `can_publish=True`, `can_subscribe=True`

#### **`POST /api/v1/livekit/voice/room`** - Create Voice Room
```python
# Creates LiveKit room for voice agent
# Required before agent can join
# Returns: {success: true, room: {...}}
```

**Purpose:** Creates the room that the agent will automatically join when a user connects.

#### **`DELETE /api/v1/livekit/voice/room/{room_name}`** - Delete Room
```python
# Deletes voice agent room
# Disconnects all participants
```

#### **`GET /api/v1/livekit/voice/rooms`** - List Rooms
```python
# Lists all active LiveKit rooms
# Useful for debugging
```

#### **`GET /api/v1/livekit/voice/health`** - Health Check
```python
# Checks voice agent process status
# Returns: agent_status, livekit_config, environment_vars
```

**Health Check Details:**
- Checks log file: `/tmp/cnt-voice-agent.log`
- Verifies log was updated recently (< 5 minutes)
- Checks environment variables (API keys, URLs)
- Returns LiveKit configuration status

---

## 3. Voice Agent Implementation

### 3.1 Voice Agent Process (`agents/voice_agent.py`)

**Location:** `backend/app/agents/voice_agent.py`

**Technology Stack:**
- **Framework:** LiveKit Agents Framework
- **STT:** Deepgram Nova-3 (Speech-to-Text)
- **TTS:** Deepgram Aura-2-Andromeda (Text-to-Speech)
- **LLM:** OpenAI GPT-4o-mini
- **VAD:** Silero VAD (Voice Activity Detection)

### 3.2 Agent Architecture

#### **Entry Point**
```python
async def entrypoint(ctx: JobContext):
    """Main entry point for voice agent"""
    room_name = ctx.room.name
    
    # Filter: Only join rooms with "voice-agent-" prefix
    if not room_name.startswith("voice-agent-"):
        return  # Reject non-voice-agent rooms
    
    # Connect to room (audio-only subscription)
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
```

**Room Filtering:**
- **Critical:** Agent only joins rooms starting with `voice-agent-`
- **Purpose:** Prevents agent from joining meeting/live stream rooms
- **Room Names:** `voice-agent-{room_name}` format

#### **Agent Session Setup**
```python
session = AgentSession(
    # VAD - Voice Activity Detection
    vad=silero.VAD.load(),
    
    # LLM - Language Model (OpenAI)
    llm=openai.LLM(model="gpt-4o-mini"),
    
    # STT - Speech-to-Text (Deepgram)
    stt=deepgram.STT(
        model="nova-3",
        language="en-US",
        interim_results=True,
        endpointing_ms=500,
    ),
    
    # TTS - Text-to-Speech (Deepgram)
    tts=deepgram.TTS(
        model="aura-2-andromeda-en",
        sample_rate=24000,
    ),
    
    # Performance Settings
    preemptive_generation=True,  # Start generating before user finishes
    allow_interruptions=True,  # User can interrupt agent
    min_interruption_duration=0.3,  # 300ms detection
    agent_false_interruption_timeout=4.0,  # Resume if false positive
    use_tts_aligned_transcript=True,  # Better sync
)
```

**Key Features:**
- **Preemptive Generation:** Starts generating response before user finishes speaking
- **Interruptions:** User can interrupt agent mid-sentence
- **False Interruption Detection:** Resumes if interruption was false positive
- **TTS Aligned Transcript:** Better synchronization between speech and text

#### **Agent Instructions**
```python
instructions = """You are an AI voice assistant for Christ New Tabernacle, 
a Christian media platform. Help users with:
- Bible verses and scripture
- Prayer requests
- Christian content recommendations
- Faith-based questions
- Daily devotionals
- Finding sermons, podcasts, and music

Be warm, compassionate, and understanding. Grounded in Christian faith and values.
Keep responses concise (2-3 sentences for voice) and conversational.
Use natural language without complex formatting, emojis, or special symbols.
When appropriate, reference Bible verses or suggest relevant content from the platform."""
```

### 3.3 Agent Lifecycle

#### **Startup Sequence:**
1. LiveKit server detects user joins room with `voice-agent-` prefix
2. LiveKit Agents framework assigns job to agent worker
3. `entrypoint()` function called
4. Room name filtered (must start with `voice-agent-`)
5. Agent connects to room (audio-only subscription)
6. Agent session initialized with STT/TTS/LLM
7. Agent starts listening for user speech
8. Agent sends initial greeting

#### **Conversation Flow:**
1. User speaks → Microphone captures audio
2. Audio sent to LiveKit server
3. Agent receives audio track
4. **STT (Deepgram)** transcribes speech to text
5. Text sent to **LLM (OpenAI)** for processing
6. LLM generates response text
7. **TTS (Deepgram)** converts response to speech
8. Audio sent back to user via LiveKit

#### **Prewarm Function**
```python
def prewarm(proc: JobProcess):
    """Preload models for low latency"""
    # Preload VAD model
    proc.userdata["vad"] = silero.VAD.load()
    
    # Preload LLM client
    proc.userdata["llm"] = openai.LLM(model="gpt-4o-mini")
    
    # Preload STT client
    proc.userdata["stt_client"] = deepgram.STT(model="nova-3", ...)
    
    # Preload TTS client
    proc.userdata["tts_client"] = deepgram.TTS(model="aura-2-andromeda-en", ...)
```

**Purpose:** Reduces cold start latency by preloading models before first use.

### 3.4 Agent Deployment

#### **Process Management (main.py)**
```python
def _start_voice_agent():
    """Start voice agent as background subprocess"""
    python_executable = "python3"  # or venv/bin/python
    _voice_agent_process = subprocess.Popen(
        [python_executable, "-m", "app.agents.voice_agent", "dev"],
        cwd=backend_dir,
        stdout=log_file,
        stderr=subprocess.STDOUT,
        env=env,  # Includes .env variables
    )
```

**Configuration:**
- **Auto-start:** Enabled by default (can disable with `DISABLE_VOICE_AGENT_AUTO_START=true`)
- **Log File:** `/tmp/cnt-voice-agent.log`
- **Environment:** Loads from `.env` file
- **Startup:** On FastAPI app startup

#### **Docker Deployment (Production)**
- Voice agent runs as **separate Docker container** (`cnt-voice-agent`)
- Auto-start disabled in main.py (via environment variable)
- Container managed separately from backend

#### **Worker Options**
```python
options = WorkerOptions(
    entrypoint_fnc=entrypoint,
    prewarm_fnc=prewarm,
    num_idle_processes=3,  # Keep 3 hot processes
    initialize_process_timeout=20.0,  # 20s timeout for initialization
)
```

**Performance Tuning:**
- **Num Idle Processes:** Keeps processes warm to avoid cold starts
- **Timeout:** Allows time for model loading

---

## 4. Frontend Implementation (Web)

### 4.1 LiveKit Meeting Service (`services/livekit_meeting_service.dart`)

**Purpose:** Video meeting/streaming functionality

#### **Key Methods:**

**`fetchTokenForMeeting()`**
```dart
// Fetches token from backend
// POST /api/v1/live/streams/{id}/livekit-token
// Returns: {token, ws_url, room_name}
// Uses frontend's LIVEKIT_WS_URL (ignores backend's internal URL)
```

**`joinMeeting()`**
```dart
Future<void> joinMeeting({
  required String roomName,
  required String jwtToken,
  required String displayName,
  bool audioMuted = false,
  bool videoMuted = false,
}) async {
  // Create Room instance
  _currentRoom = lk.Room(roomOptions: roomOptions);
  
  // Connect to LiveKit server
  await _currentRoom!.connect(url, jwtToken);
  
  // Enable camera/microphone
  await localParticipant.setMicrophoneEnabled(!audioMuted);
  await localParticipant.setCameraEnabled(!videoMuted);
}
```

**Room Options:**
```dart
lk.RoomOptions(
  adaptiveStream: true,  # Adaptive bitrate
  dynacast: true,  # Dynamic casting
  defaultAudioCaptureOptions: const lk.AudioCaptureOptions(
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
  ),
)
```

#### **Event Handlers:**
- `ParticipantConnectedEvent` - New participant joined
- `ParticipantDisconnectedEvent` - Participant left
- `TrackSubscribedEvent` - Audio/video track available
- `TrackUnsubscribedEvent` - Track removed
- `RoomDisconnectedEvent` - Connection lost

#### **URL Resolution:**
```dart
// Critical: Frontend uses its own LIVEKIT_WS_URL
// Backend returns internal Docker URL (ignored)
final frontendUrl = _apiService.getLiveKitUrl();
// Returns: wss://livekit.christnewtabernacle.com (from --dart-define)
```

**Why?** Frontend runs in browser and needs external URL, not Docker internal.

### 4.2 LiveKit Voice Service (`services/livekit_voice_service.dart`)

**Purpose:** Voice agent connection

#### **Connection Flow:**
```dart
Future<void> connectToRoom({
  required String roomName,
  String? userIdentity,
  int maxRetries = 3,
}) async {
  // Step 1: Get token from backend
  final tokenResponse = await _apiService.getLiveKitVoiceToken(roomName);
  
  // Step 2: Get LiveKit URL (frontend's configured URL)
  final wsUrl = _apiService.getLiveKitUrl();
  
  // Step 3: Create room and connect
  _room = lk.Room(roomOptions: roomOptions);
  await _room!.connect(wsUrl, token);
  
  // Step 4: Enable microphone
  await _room!.localParticipant!.setMicrophoneEnabled(true);
}
```

#### **Agent Detection:**
```dart
_listener!.on<lk.ParticipantConnectedEvent>((event) {
  if (event.participant.kind == lk.ParticipantKind.AGENT) {
    _onAgentConnected(event.participant);
  }
});

_listener!.on<lk.TrackSubscribedEvent>((event) {
  if (event.participant.kind == lk.ParticipantKind.AGENT) {
    if (event.track.kind == lk.TrackType.AUDIO) {
      // Agent audio track ready
      _onAgentAudioTrack(event.track);
    }
  }
});
```

**Agent State Management:**
- Listens for agent metadata changes
- Parses agent state from metadata (JSON, query string, or keywords)
- States: `initializing`, `listening`, `speaking`, `thinking`, `disconnected`
- Streams state updates to UI

#### **Retry Logic:**
```dart
int attempt = 0;
while (attempt < maxRetries) {
  try {
    // Connect...
    return;  // Success
  } catch (e) {
    attempt++;
    if (attempt < maxRetries) {
      // Exponential backoff: 1s, 2s, 4s
      await Future.delayed(Duration(seconds: 1 << (attempt - 1)));
    }
  }
}
```

### 4.3 Voice Agent Screen (`screens/web/voice_agent_screen_web.dart`)

**Connection Sequence:**
```dart
Future<void> _connectToRoom() async {
  final roomName = 'voice-agent-${DateTime.now().millisecondsSinceEpoch}';
  
  // Step 1: Create room (mandatory - agent needs room to exist)
  await _apiService.createLiveKitRoom(roomName);
  
  // Step 2: Wait for room initialization
  await Future.delayed(const Duration(milliseconds: 500));
  
  // Step 3: Connect to room
  await _service.connectToRoom(roomName: roomName);
  
  // Step 4: Wait for agent to join (up to 30 seconds)
  // Agent auto-joins when user connects (if room name starts with "voice-agent-")
}
```

**UI States:**
- `initializing` - Setting up connection
- `connecting` - Connecting to LiveKit
- `waiting_for_agent` - Waiting for agent to join
- `listening` - Agent listening for user input
- `speaking` - Agent is speaking
- `thinking` - Agent processing response
- `error` - Connection error

### 4.4 Meeting Room Screen (`screens/web/meeting_room_screen_web.dart`)

**Meeting Join Flow:**
```dart
// 1. Get token from backend
final tokenResponse = await ApiService().getLiveKitMeetingToken(
  meetingId,
  userIdentity: userId,
  userName: userName,
);

// 2. Join meeting
await LiveKitMeetingService().joinMeeting(
  roomName: tokenResponse.roomName,
  jwtToken: tokenResponse.token,
  displayName: userName,
  audioMuted: false,
  videoMuted: false,
);
```

**UI Features:**
- Video grid showing all participants
- Camera toggle button
- Microphone toggle button
- Leave meeting button
- Participant list

---

## 5. Configuration & URLs

### 5.1 Frontend Configuration (Build-time)

**Amplify Build (`amplify.yml`):**
```yaml
flutter build web --release \
  --dart-define=LIVEKIT_WS_URL=$LIVEKIT_WS_URL \
  --dart-define=LIVEKIT_HTTP_URL=$LIVEKIT_HTTP_URL
```

**Environment Variables (Amplify Console):**
- `LIVEKIT_WS_URL`: `wss://livekit.christnewtabernacle.com`
- `LIVEKIT_HTTP_URL`: `https://livekit.christnewtabernacle.com`

**Runtime Usage:**
```dart
// api_service.dart
String getLiveKitUrl() {
  const envUrl = String.fromEnvironment('LIVEKIT_WS_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;  // wss://livekit.christnewtabernacle.com
  }
  return AppConfig.livekitWsUrl;
}
```

### 5.2 Backend Configuration (Runtime)

**`.env` File:**
```env
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com
LIVEKIT_API_KEY=RvSL2BvFryECUIy2BELujY5E5mGUlSClNUZXPKWOJds
LIVEKIT_API_SECRET=NCXkii10fq8DZ7z7m5b_cOx52-bJNGW9jv-WfvbQCqI
```

**Internal Docker URLs (for agent):**
- Agent uses `LIVEKIT_URL` environment variable
- If not set, uses `LIVEKIT_WS_URL`
- Should point to Docker internal: `ws://livekit-server:7880` (or external URL)

### 5.3 URL Resolution Strategy

**Problem:** Backend returns internal Docker URL, but frontend needs external URL.

**Solution:** Frontend ignores backend's URL and uses its own configured URL.

```dart
// Frontend always uses its own URL
final frontendUrl = _apiService.getLiveKitUrl();
print('Using frontend URL: $frontendUrl (ignoring backend URL: ${response['ws_url']})');
```

**Why This Works:**
- Frontend runs in browser (external client)
- Backend runs in Docker (internal network)
- Both point to same LiveKit server, just different paths
- External URL goes through load balancer/nginx
- Internal URL goes through Docker network

---

## 6. Connection Flow Diagrams

### 6.1 Meeting/Stream Connection Flow

```
User (Browser)
    ↓
1. Create Meeting
    POST /api/v1/live/streams
    ↓
2. Backend Creates LiveStream Record
    - Generates room_name: "instant-meeting-abc123"
    - Stores in database
    ↓
3. User Joins Meeting
    POST /api/v1/live/streams/{id}/livekit-token
    ↓
4. Backend Generates JWT Token
    LiveKitService.create_access_token()
    - Room: "instant-meeting-abc123"
    - Identity: "user_123_email@example.com"
    - Permissions: can_publish, can_subscribe
    ↓
5. Frontend Receives Token
    {token: "eyJ...", url: "wss://...", room_name: "..."}
    ↓
6. Frontend Connects to LiveKit
    Room.connect(wss://livekit.christnewtabernacle.com, token)
    ↓
7. LiveKit Server Validates Token
    - Verifies JWT signature (API key/secret)
    - Checks permissions
    - Allows connection
    ↓
8. User in Room
    - Can publish audio/video
    - Can subscribe to other participants
    - Real-time communication active
```

### 6.2 Voice Agent Connection Flow

```
User (Browser)
    ↓
1. Open Voice Agent Screen
    ↓
2. Generate Room Name
    "voice-agent-{timestamp}"
    ↓
3. Create Room
    POST /api/v1/livekit/voice/room
    - Room name: "voice-agent-1234567890"
    ↓
4. Backend Creates LiveKit Room
    LiveKitService.create_room()
    ↓
5. Get Voice Token
    POST /api/v1/livekit/voice/token
    - Room name: "voice-agent-1234567890"
    ↓
6. Backend Generates Token
    LiveKitService.create_access_token()
    - Room: "voice-agent-1234567890"
    - Identity: "user_123" or "guest_..."
    ↓
7. Frontend Connects
    Room.connect(wss://livekit.christnewtabernacle.com, token)
    ↓
8. LiveKit Detects Room Name Pattern
    Room name starts with "voice-agent-"
    ↓
9. LiveKit Assigns Job to Agent Worker
    Agents framework triggers entrypoint()
    ↓
10. Agent Connects to Room
    await ctx.connect(auto_subscribe=AutoSubscribe.AUDIO_ONLY)
    ↓
11. Agent Session Starts
    - STT: Deepgram Nova-3
    - LLM: OpenAI GPT-4o-mini
    - TTS: Deepgram Aura-2
    ↓
12. Conversation Active
    User speaks → STT → LLM → TTS → User hears response
```

---

## 7. Database Schema

### 7.1 LiveStream Table

```sql
CREATE TABLE live_streams (
    id INTEGER PRIMARY KEY,
    host_id INTEGER REFERENCES users(id),
    title VARCHAR,
    description TEXT,
    thumbnail VARCHAR,
    category VARCHAR,
    room_name VARCHAR UNIQUE,  -- LiveKit room name
    status VARCHAR,  -- pending, live, ended
    viewer_count INTEGER DEFAULT 0,
    scheduled_start TIMESTAMP,
    started_at TIMESTAMP,
    ended_at TIMESTAMP,
    created_at TIMESTAMP
);
```

**Key Fields:**
- **room_name:** Unique identifier for LiveKit room
- **status:** Meeting/stream status
- **host_id:** User who created the meeting/stream

---

## 8. Security & Authentication

### 8.1 JWT Token Structure

**Token Claims:**
```json
{
  "sub": "user_123_email@example.com",  // Identity
  "iss": "RvSL2BvFryECUIy2BELujY5E5mGUlSClNUZXPKWOJds",  // API Key
  "exp": 1734057600,  // Expiration
  "video": {
    "room": "instant-meeting-abc123",  // Room name
    "room_join": true,  // Can join room
    "can_publish": true,  // Can publish tracks
    "can_subscribe": true  // Can subscribe to tracks
  }
}
```

**Token Validation:**
- LiveKit server verifies JWT signature using API secret
- Checks expiration timestamp
- Validates room permissions
- Allows/denies connection based on grants

### 8.2 Room Access Control

**Meeting Rooms:**
- Token required to join
- Permissions: `can_publish=True`, `can_subscribe=True`
- No room-level access control (anyone with token can join)

**Voice Agent Rooms:**
- Token required (optional auth for guests)
- Same permissions as meetings
- Agent auto-joins based on room name pattern

---

## 9. Performance & Optimization

### 9.1 Agent Prewarm

**Purpose:** Reduce cold start latency

**Implementation:**
- Preloads VAD, LLM, STT, TTS clients
- Keeps 3 idle processes warm
- Models loaded once per worker process

**Impact:**
- First response: ~2-3 seconds (model loading)
- Subsequent responses: ~1-2 seconds (models cached)

### 9.2 Preemptive Generation

**Feature:** Agent starts generating response before user finishes speaking

**Benefits:**
- Reduces perceived latency
- More natural conversation flow

### 9.3 Adaptive Streaming

**Frontend Room Options:**
- `adaptiveStream: true` - Adjusts bitrate based on network
- `dynacast: true` - Dynamic track casting

---

## 10. Troubleshooting & Debugging

### 10.1 Common Issues

**Agent Not Joining:**
- Check room name starts with `voice-agent-`
- Verify agent process is running
- Check log file: `/tmp/cnt-voice-agent.log`
- Verify API keys are set correctly

**Connection Failed:**
- Check LiveKit server is running: `docker ps`
- Verify URL is correct (external vs internal)
- Check firewall rules (ports 7880-7881, UDP 50100-50200)
- Verify token is valid (check expiration)

**No Audio:**
- Check browser permissions (microphone)
- Verify microphone is enabled in room
- Check audio track subscription events
- Verify agent audio track is published

### 10.2 Health Check Endpoint

**`GET /api/v1/livekit/voice/health`**

**Returns:**
```json
{
  "success": true,
  "agent_status": {
    "log_file_exists": true,
    "log_last_updated_seconds_ago": 45,
    "likely_running": true,
    "livekit_configured": true,
    "livekit_url": "wss://livekit.christnewtabernacle.com",
    "environment": {
      "openai_key_set": true,
      "deepgram_key_set": true,
      "livekit_api_key_set": true,
      "livekit_api_secret_set": true
    }
  }
}
```

---

## 11. Production Deployment

### 11.1 EC2 Setup

**Docker Containers:**
```bash
# LiveKit Server
docker run -d \
  --name cnt-livekit-server \
  -p 7880:7880 \
  -p 7881:7881 \
  -p 50100-50200:50100-50200/udp \
  -v ./livekit.yaml:/etc/livekit.yaml \
  livekit/livekit-server:latest \
  --config /etc/livekit.yaml

# Voice Agent (optional - can run as subprocess)
docker run -d \
  --name cnt-voice-agent \
  --env-file .env \
  python:3.11 \
  python -m app.agents.voice_agent dev
```

### 11.2 Nginx/Reverse Proxy

**Configuration for HTTPS:**
```nginx
# LiveKit WebSocket (WSS)
location / {
    proxy_pass http://localhost:7880;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_set_header Host $host;
}

# LiveKit HTTP API
location /rtc/ {
    proxy_pass http://localhost:7881;
    proxy_set_header Host $host;
}
```

### 11.3 Firewall Rules

**Required Ports:**
- TCP 7880: WebSocket
- TCP 7881: HTTP API
- UDP 50100-50200: WebRTC media

**EC2 Security Group:**
```bash
# Allow WebSocket
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 7880 \
  --cidr 0.0.0.0/0

# Allow HTTP API
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol tcp \
  --port 7881 \
  --cidr 0.0.0.0/0

# Allow WebRTC UDP
aws ec2 authorize-security-group-ingress \
  --group-id sg-xxx \
  --protocol udp \
  --port 50100-50200 \
  --cidr 0.0.0.0/0
```

---

## 12. Summary

### 12.1 Architecture Summary

**Components:**
1. **LiveKit Server** - Real-time communication server (Docker)
2. **Backend API** - Token generation, room management (FastAPI)
3. **Voice Agent** - AI assistant (Python process/container)
4. **Frontend** - Web client (Flutter Web)

**Data Flow:**
- **Meetings:** User → Backend → Token → LiveKit → Video/Audio
- **Voice Agent:** User → Backend → Token → LiveKit → Agent → STT/LLM/TTS → User

### 12.2 Key Features

✅ **Video Meetings** - Multi-participant video conferencing  
✅ **Live Streaming** - Broadcaster and viewer modes  
✅ **Voice Agent** - AI-powered voice assistant  
✅ **Token-based Auth** - Secure room access  
✅ **Auto-scaling** - Agent worker pool  
✅ **Preemptive Generation** - Low latency responses  
✅ **Interruptions** - Natural conversation flow  

### 12.3 Production Status

**Deployed:**
- ✅ LiveKit server running on EC2
- ✅ Voice agent operational
- ✅ Backend API functional
- ✅ Frontend integration complete

**Configuration:**
- ✅ HTTPS/WSS enabled
- ✅ API keys configured
- ✅ Environment variables set
- ✅ Docker containers running

---

**Document Created:** Complete LiveKit implementation analysis  
**Status:** Production-ready  
**Last Updated:** December 12, 2025

