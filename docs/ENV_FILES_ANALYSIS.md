# Environment Files Analysis & Configuration Issues

**Date:** December 13, 2025  
**Domain:** christnewtabernacle.com (frontend on AWS Amplify)  
**Status:** Configuration issues identified

---

## Environment Files Overview

You have **two .env files** with different purposes:

### 1. Root `.env` (`/cnt-web-deployment/.env`)
**Purpose:** Docker Compose configuration (but actually overridden)  
**Location:** `/home/ubuntu/cnt-web-deployment/.env`

### 2. Backend `.env` (`/cnt-web-deployment/backend/.env`)
**Purpose:** Backend container runtime configuration  
**Location:** `/home/ubuntu/cnt-web-deployment/backend/.env`

---

## Current Configuration Analysis

### Root `.env` (Used by voice-agent container)

```bash
# Internal Docker URLs (for docker-compose)
LIVEKIT_WS_URL=ws://livekit-server:7880          # ✅ Correct (WebSocket)
LIVEKIT_HTTP_URL=http://livekit-server:7880      # ❌ WRONG PORT (should be 7881)
```

**Used by:**
- `cnt-voice-agent` container (via docker-compose)

**Issue:** 
- HTTP URL uses port **7880** (WebSocket port)
- Should use port **7881** (HTTP API port)
- This causes the 404 errors we found!

### Backend `.env` (Used by backend container)

```bash
# External production URLs
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com      # ✅ Correct (external WebSocket)
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com  # ✅ Correct (external HTTP)
```

**Used by:**
- `cnt-backend` container

**Status:** ✅ Correct configuration for external access

---

## LiveKit Port Configuration

**LiveKit Server Ports:**
- **7880:** WebSocket connections (WSS/WS) - for clients
- **7881:** HTTP API - for backend/agent server settings, room management
- **50100-50200/UDP:** WebRTC media (video/audio streams)

**Important:** 
- WebSocket (7880) ≠ HTTP API (7881)
- Agents need HTTP API (7881) to fetch server settings
- Clients use WebSocket (7880) for real-time communication

---

## Current Container Configuration

### Backend Container (`cnt-backend`)

**Source:** `backend/.env`

```bash
LIVEKIT_WS_URL=wss://livekit.christnewtabernacle.com      # External (for token generation)
LIVEKIT_HTTP_URL=https://livekit.christnewtabernacle.com  # External (for API calls)
```

**Why external URLs?**
- Backend generates tokens for frontend clients
- Frontend connects from browser (needs external URL)
- Backend also calls LiveKit API (can use external URL)

**Status:** ✅ Correct

### Voice Agent Container (`cnt-voice-agent`)

**Source:** Root `.env` (via docker-compose overrides)

```bash
LIVEKIT_WS_URL=ws://livekit-server:7880          # Internal Docker network
LIVEKIT_HTTP_URL=http://livekit-server:7880      # ❌ WRONG - should be 7881
```

**Why internal URLs?**
- Agent runs in same Docker network as LiveKit server
- Internal URLs are faster (no external routing)
- Agent only needs to connect to LiveKit, not serve clients

**Status:** ❌ **INCORRECT - HTTP port is wrong!**

---

## The Problem

### Root Cause

The voice agent container uses:
```
LIVEKIT_HTTP_URL=http://livekit-server:7880
```

But LiveKit HTTP API runs on port **7881**, not 7880.

**Result:**
- Agent tries: `http://livekit-server:7880/settings` → **404 Not Found**
- Agent can't fetch server settings
- Agent may not register properly as worker
- LiveKit server doesn't dispatch jobs to agent
- **Agent never joins voice-agent rooms**

---

## Docker Compose Configuration Issue

**File:** `docker-compose.ec2.yml`

```yaml
voice-agent:
  environment:
    # Note: LiveKit HTTP API is on port 7880, not 7881 (7881 is RTC TCP port)
    - LIVEKIT_HTTP_URL=http://livekit-server:7880  # ❌ COMMENT IS WRONG!
```

**The comment is incorrect!**

**Correct understanding:**
- **7880:** WebSocket (WS/WSS) for client connections
- **7881:** HTTP API for server settings, room management
- **50100-50200/UDP:** RTC media (not TCP)

---

## Configuration for Different Environments

### Production Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS EC2 Instance                      │
│                                                          │
│  ┌──────────────────┐    ┌──────────────────┐          │
│  │ LiveKit Server   │    │  Backend API     │          │
│  │ Port 7880 (WS)   │◄───┤  Port 8000       │          │
│  │ Port 7881 (HTTP) │    │                  │          │
│  └────────┬─────────┘    └──────────────────┘          │
│           │                                              │
│           │              ┌──────────────────┐          │
│           └──────────────┤  Voice Agent     │          │
│                          │  (Agent Worker)  │          │
│                          └──────────────────┘          │
│                                                          │
└─────────────────────────────────────────────────────────┘
           ▲                           ▲
           │                           │
           │ External Access           │ External Access
           │ (WSS/HTTPS)               │ (HTTPS)
           │                           │
┌──────────┴────────────┐  ┌──────────┴────────────┐
│   Browser Clients     │  │   AWS Amplify         │
│   (Frontend Web App)  │  │   Frontend            │
│   christnewtabernacle.│  │   christnewtabernacle.│
│   com                 │  │   com                 │
└───────────────────────┘  └───────────────────────┘
```

### URL Configuration Matrix

| Component | WebSocket URL | HTTP URL | Notes |
|-----------|--------------|----------|-------|
| **Frontend** | `wss://livekit.christnewtabernacle.com` | N/A | Browser connects via WSS |
| **Backend** | `wss://livekit.christnewtabernacle.com` | `https://livekit.christnewtabernacle.com` | Generates tokens, calls API |
| **Voice Agent** | `ws://livekit-server:7880` | `http://livekit-server:7881` | Internal Docker network |

---

## Fix Required

### Option 1: Fix Docker Compose (Recommended)

**Update `docker-compose.ec2.yml`:**

```yaml
voice-agent:
  environment:
    - LIVEKIT_URL=ws://livekit-server:7880
    - LIVEKIT_WS_URL=ws://livekit-server:7880
    - LIVEKIT_HTTP_URL=http://livekit-server:7881  # ✅ Fix: Change to 7881
```

### Option 2: Fix Root `.env` File

**Update `/cnt-web-deployment/.env`:**

```bash
# Internal Docker communication (used by docker-compose)
LIVEKIT_WS_URL=ws://livekit-server:7880
LIVEKIT_HTTP_URL=http://livekit-server:7881  # ✅ Fix: Change to 7881
```

### Option 3: Both (Best Practice)

Fix both files for consistency.

---

## Current File Status

### ✅ Correct Files

**`backend/.env`:**
- Uses external URLs (correct for backend)
- Ports are correct (implicit via domain)
- Used by backend container ✅

### ❌ Files Needing Fix

**`docker-compose.ec2.yml`:**
- Line 98: `LIVEKIT_HTTP_URL=http://livekit-server:7880` → Should be `7881`
- Comment on line 95 is incorrect

**Root `.env`:**
- Line 13: `LIVEKIT_HTTP_URL=http://livekit-server:7880` → Should be `7881`

---

## Domain & Frontend Configuration

### Frontend (AWS Amplify)

**Domain:** `christnewtabernacle.com`  
**Amplify URLs:**
- `main.d1poes9tyirmht.amplifyapp.com`
- `d1poes9tyirmht.amplifyapp.com`

**CORS Configuration:**
```bash
CORS_ORIGINS=https://christnewtabernacle.com,https://www.christnewtabernacle.com,https://main.d1poes9tyirmht.amplifyapp.com,https://d1poes9tyirmht.amplifyapp.com
```

**Status:** ✅ Correct (all frontend domains included)

### LiveKit Server

**External Domain:** `livekit.christnewtabernacle.com`  
**Ports:**
- 7880: WebSocket (WSS)
- 7881: HTTP API (HTTPS)

**Status:** ✅ Configuration is correct (external domain)

---

## Verification Checklist

After fixing the configuration:

- [ ] Update `docker-compose.ec2.yml` (LIVEKIT_HTTP_URL port)
- [ ] Update root `.env` (LIVEKIT_HTTP_URL port)
- [ ] Restart voice-agent container
- [ ] Check logs: `docker logs -f cnt-voice-agent`
- [ ] Verify: No more "404 failed to fetch server settings" errors
- [ ] Test: Create voice-agent room and verify agent joins
- [ ] Verify: Agent receives job requests for voice-agent-* rooms

---

## Summary

**Issue:** Voice agent uses wrong HTTP port (7880 instead of 7881)  
**Impact:** Agent can't fetch server settings → doesn't register properly → no job dispatches  
**Fix:** Change `LIVEKIT_HTTP_URL` from port 7880 to 7881 for voice agent  
**Files to update:**
1. `docker-compose.ec2.yml` (line 98)
2. Root `.env` (line 13, optional but recommended)

**Backend configuration is correct** - no changes needed there.

