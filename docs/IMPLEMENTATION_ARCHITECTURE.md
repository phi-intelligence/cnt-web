# CNT Media Platform - Implementation Architecture

**Version:** 3.0  
**Date:** December 5, 2025  
**Status:** Complete Production System

---

## System Architecture Overview

### High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    CLIENT LAYER                               │
├──────────────────────────────────────────────────────────────┤
│  Web: Flutter Web (Dart)    │  Mobile: Flutter (iOS/Android) │
│  AWS Amplify Deployment     │  In Development                │
└──────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    API LAYER                                  │
├──────────────────────────────────────────────────────────────┤
│  FastAPI (Python 3.11+) on AWS EC2 (eu-west-2)              │
│  100+ RESTful Endpoints                                      │
└──────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    DATA LAYER                                 │
├──────────────────────────────────────────────────────────────┤
│  PostgreSQL (AWS RDS) - 21 Tables                            │
│  SQLAlchemy ORM (Async)                                      │
└──────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    STORAGE LAYER                              │
├──────────────────────────────────────────────────────────────┤
│  AWS S3 (cnt-web-media) + CloudFront CDN                     │
│  FFmpeg Processing                                           │
└──────────────────────────────────────────────────────────────┘
                             │
                             ▼
┌──────────────────────────────────────────────────────────────┐
│                    REAL-TIME LAYER                            │
├──────────────────────────────────────────────────────────────┤
│  LiveKit (Meetings, Streaming, Voice Agent)                  │
│  OpenAI GPT-4o-mini + Deepgram                               │
└──────────────────────────────────────────────────────────────┘
```

## Technology Stack

### Backend Stack
- **Framework**: FastAPI 0.104+
- **Database**: PostgreSQL 14+ (AWS RDS)
- **ORM**: SQLAlchemy 2.0+ (Async)
- **Media Processing**: FFmpeg, Pillow
- **AI Services**: OpenAI GPT-4o-mini, Deepgram
- **Real-Time**: LiveKit, Socket.IO
- **Cloud**: AWS (EC2, S3, RDS, CloudFront)

### Frontend Stack
- **Framework**: Flutter 3.16+ (Web & Mobile)
- **State Management**: Provider Pattern
- **HTTP Client**: http package
- **Media**: video_player, audioplayers
- **Real-Time**: livekit_client
- **Storage**: flutter_secure_storage

### Infrastructure
- **Web Hosting**: AWS Amplify
- **Backend Hosting**: AWS EC2 (eu-west-2)
- **Database**: AWS RDS PostgreSQL
- **Media Storage**: AWS S3 + CloudFront CDN
- **DNS**: Route 53 (christnewtabernacle.com)

## Database Schema (21 Tables)

### Core Tables
1. **users** - User accounts and authentication
2. **artists** - Creator profiles (auto-created)
3. **podcasts** - Audio/video podcast content
4. **movies** - Full-length movie content
5. **music_tracks** - Music content
6. **community_posts** - Social media posts
7. **comments** - Post comments
8. **likes** - Post likes
9. **playlists** - User playlists
10. **playlist_items** - Playlist content links

### Financial Tables
11. **bank_details** - Creator payment info
12. **payment_accounts** - Payment gateway accounts
13. **donations** - Donation transactions

### Feature Tables
14. **live_streams** - Meeting/stream records
15. **document_assets** - PDF documents (Bible)
16. **support_messages** - Support tickets
17. **bible_stories** - Bible story content
18. **notifications** - User notifications
19. **categories** - Content categories
20. **email_verification** - Email verification tokens
21. **artist_followers** - Follow relationships

## API Endpoints (100+)

### Authentication (`/api/v1/auth`)
- POST `/login` - Email/password login
- POST `/register` - User registration
- POST `/google-login` - Google OAuth
- POST `/send-otp` - Send OTP verification
- POST `/verify-otp` - Verify OTP
- POST `/check-username` - Username availability
- GET `/google-client-id` - OAuth client ID

### Content Management
- **Podcasts**: `/api/v1/podcasts` (GET, POST, DELETE)
- **Movies**: `/api/v1/movies` (GET, POST, DELETE)
- **Music**: `/api/v1/music` (GET, POST, DELETE)
- **Community**: `/api/v1/community` (GET, POST, LIKE, COMMENT)
- **Playlists**: `/api/v1/playlists` (CRUD operations)

### Media Upload
- POST `/upload/audio` - Upload audio file
- POST `/upload/video` - Upload video file
- POST `/upload/image` - Upload image
- POST `/upload/profile-image` - Upload avatar
- POST `/upload/thumbnail` - Upload thumbnail
- POST `/upload/document` - Upload PDF (admin)

### Media Editing
- **Audio**: `/api/v1/audio-editing` (trim, merge, fade)
- **Video**: `/api/v1/video-editing` (trim, audio, overlays, filters)

### Real-Time Features
- **Live Streaming**: `/api/v1/live` (streams, tokens)
- **Voice Agent**: `/api/v1/livekit/voice` (rooms, tokens)
- **Meetings**: LiveKit room management

### Admin
- GET `/admin/dashboard` - Statistics
- POST `/admin/approve/{type}/{id}` - Approve content
- POST `/admin/reject/{type}/{id}` - Reject content

## AWS Infrastructure

### S3 Bucket Structure
```
cnt-web-media/
├── audio/              # Audio podcasts
├── video/              # Video podcasts
├── images/
│   ├── quotes/         # Generated quote images
│   ├── thumbnails/     # Podcast thumbnails
│   ├── movies/         # Movie posters
│   └── profiles/       # User avatars
├── documents/          # PDF documents
└── animated-bible-stories/  # Bible story videos
```

### CloudFront Configuration
- **Distribution ID**: E3ER061DLFYFK8
- **Domain**: d126sja5o8ue54.cloudfront.net
- **Origin**: cnt-web-media.s3.eu-west-2.amazonaws.com
- **OAC ID**: E1LSA9PF0Z69X7

### EC2 Backend Server
- **Public IP**: 52.56.78.203
- **Domain**: christnewtabernacle.com
- **Region**: eu-west-2 (London)
- **Instance**: Private VPC (172.31.33.228)

### RDS Database
- **Engine**: PostgreSQL
- **Endpoint**: cntdb.c9gukkkmamkh.eu-west-2.rds.amazonaws.com
- **Database**: cntdb

## Security Architecture

### Authentication
- JWT tokens (30-minute expiration)
- Secure storage (flutter_secure_storage)
- Google OAuth integration
- Admin role-based access

### File Upload Security
- Authentication required
- File type validation
- UUID-based filenames
- S3 bucket policy restrictions

### API Security
- CORS configuration
- Rate limiting (potential)
- Input validation (Pydantic)
- SQL injection protection (ORM)

## Deployment Architecture

### Web Frontend (AWS Amplify)
1. Git push to main branch
2. Amplify auto-builds Flutter Web
3. Deploys to CDN
4. Domain: d1poes9tyirmht.amplifyapp.com

### Backend (AWS EC2)
1. SSH to EC2: `ssh -i christnew.pem ubuntu@52.56.78.203`
2. Pull latest code: `git pull`
3. Restart service: `sudo systemctl restart cnt-backend`

### Mobile App
- **iOS**: TestFlight (future)
- **Android**: Google Play (future)
- **Current**: Development builds only

## Performance Considerations

### Caching Strategy
- CloudFront CDN for media files
- Browser caching for static assets
- API response caching (Redis - optional)

### Optimization
- FFmpeg hardware acceleration
- Image compression (Pillow)
- Lazy loading in frontend
- Pagination for large datasets

### Scalability
- Async database operations
- Connection pooling
- Horizontal scaling potential (EC2 Auto Scaling)
- S3 unlimited storage

## Monitoring & Logging

### Backend Logging
- FastAPI access logs
- Error tracking
- Database query logging

### Frontend Logging
- Console logs (development)
- Error reporting (production)

### AWS Monitoring
- CloudWatch metrics
- S3 access logs
- RDS performance insights

---

**Document Status**: Complete architecture overview for CNT Media Platform
