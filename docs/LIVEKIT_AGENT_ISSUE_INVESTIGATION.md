# LiveKit Voice Agent - Issue Investigation

**Date:** December 13, 2025  
**Issue:** Voice agent not joining recent voice-agent rooms  
**Status:** Root cause identified

---

## Problem Summary

Recent voice-agent rooms show:
- ✅ Rooms being created successfully
- ✅ Users connecting and publishing audio tracks  
- ❌ **Agent NOT joining the rooms**

**Evidence from logs:**
- Agent container is running and healthy
- Agent correctly skips non-voice-agent rooms (filtering works)
- **NO job requests received for voice-agent-* rooms in recent logs**
- Only 1 successful agent connection seen in logs (Dec 13, 19:00:09)

---

## Root Cause Identified

### Critical Error: Failed to Fetch Server Settings

```
error: failed to fetch server settings: http status: 404
```

**This error appears repeatedly in agent logs.**

### Environment Variables Issue

**Current configuration in agent container:**
```bash
LIVEKIT_URL=ws://livekit-server:7880
LIVEKIT_HTTP_URL=http://livekit-server:7880
LIVEKIT_WS_URL=ws://livekit-server:7880
```

**Problem:**
- `LIVEKIT_HTTP_URL` is set to port **7880** (WebSocket port)
- LiveKit HTTP API runs on port **7881** (not 7880)
- Agent tries to fetch server settings from `http://livekit-server:7880/settings` → **404 error**

**LiveKit Port Configuration:**
- **Port 7880:** WebSocket connections (WSS/WS)
- **Port 7881:** HTTP API and TCP RTC

### Why This Prevents Agent Joining

1. Agent connects to LiveKit server via WebSocket (`ws://livekit-server:7880`) ✓
2. Agent tries to fetch server settings via HTTP (`http://livekit-server:7880`) ✗
3. HTTP request fails with 404 (wrong port)
4. Agent may not properly register as a worker without server settings
5. LiveKit server doesn't dispatch jobs to unregistered/improperly registered agents
6. Result: No job requests for voice-agent rooms

---

## Evidence from Logs

### 1. Agent Container Logs

**Missing job requests for voice-agent rooms:**
```
# Recent voice-agent rooms created:
- voice-agent-1765665541731 (22:39:02)
- voice-agent-1765665552610 (22:39:12)  
- voice-agent-1765665657924 (22:40:58)

# No agent logs for these rooms - no job requests received
```

**Only job requests seen are for non-voice-agent rooms:**
```
INFO:livekit.agents:received job request {"room": "live-stream---2025-12-08-2019-9bc66e5e"}
INFO:cnt.voice.agent:⏭️  CNT Voice Agent: Skipping room 'live-stream---2025-12-08-2019-9bc66e5e'
```

**Repeated 404 errors:**
```
error: failed to fetch server settings: http status: 404
```

### 2. LiveKit Server Logs

**User connections are successful:**
```
INFO:starting RTC session {"room": "voice-agent-1765665541731", "participant": "user_6_ajaymohan306@gmail.com"}
INFO:participant active {"room": "voice-agent-1765665541731"}
INFO:mediaTrack published {"room": "voice-agent-1765665541731", "kind": "audio"}
```

**No agent participant logs:**
- No logs showing agent joining as participant
- No agent participant ID in room logs

---

## Solution

### Fix Environment Variables

**Update agent container environment:**

```bash
# Current (WRONG):
LIVEKIT_HTTP_URL=http://livekit-server:7880  # ❌ Wrong port

# Should be (CORRECT):
LIVEKIT_HTTP_URL=http://livekit-server:7881  # ✅ Correct HTTP API port
```

**Or remove `LIVEKIT_HTTP_URL` entirely and let it default based on `LIVEKIT_URL`.**

---

## Verification Steps

1. **Check current environment:**
   ```bash
   docker exec cnt-voice-agent printenv | grep LIVEKIT
   ```

2. **Update environment variables:**
   - Update Docker container environment or `.env` file
   - Restart agent container

3. **Monitor logs after fix:**
   ```bash
   # Watch for successful server settings fetch
   docker logs -f cnt-voice-agent | grep -i "settings\|server\|connected"
   
   # Watch for job requests for voice-agent rooms
   docker logs -f cnt-voice-agent | grep "voice-agent-"
   ```

4. **Test voice agent:**
   - Create a new voice-agent room
   - Connect as user
   - Verify agent joins within 1-2 seconds

---

## Additional Findings

### Other Errors (Non-Critical)

1. **Audio filter warning:**
   ```
   ERROR: audio filter cannot be enabled: LiveKit Cloud is required
   ```
   - **Status:** Expected (self-hosted LiveKit)
   - **Impact:** None (noise cancellation disabled as intended)

2. **Deprecation warnings:**
   ```
   WARNING: `agent_false_interruption_timeout` is deprecated
   WARNING: RoomInputOptions and RoomOutputOptions are deprecated
   ```
   - **Status:** Code uses deprecated APIs
   - **Impact:** Minor (should update code for future compatibility)

---

## Next Steps

1. ✅ **Fix `LIVEKIT_HTTP_URL` environment variable** (set to port 7881)
2. ⏳ Restart voice agent container
3. ⏳ Test voice agent connection
4. ⏳ Monitor logs to confirm agent receives job requests
5. ⏳ Update code to use non-deprecated APIs (optional)

---

**Investigation completed.** Root cause identified and solution provided.

