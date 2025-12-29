# CNT Media Platform - S3 Bucket Analysis

**Date:** December 20, 2025  
**Bucket Name:** `cnt-web-media`  
**Region:** `eu-west-2` (London)  
**S3 URL:** `https://cnt-web-media.s3.eu-west-2.amazonaws.com`

---

## 📊 Bucket Overview

### Total Content Summary
- **Animated Bible Stories:** 17 files (~2.25 GB)
- **Audio Podcasts:** 117 files
- **Documents:** 2 files
- **Movies:** 4 files
- **Video Podcasts:** 192 files
- **Images:** 53 files (17 root + 29 thumbnails + 7 profiles)
- **Drafts:** 8 files (2 audio + 3 video + 3 images)

**Total Media Files:** ~390+ files

---

## 📁 Directory Structure

```
cnt-web-media/
├── animated-bible-stories/          # Biblical animated videos
│   ├── Old Testament 5.mp4
│   ├── Old Testament 6.mp4
│   ├── Solomon's Kingdom.mp4
│   ├── Stories From The Bible - David.mp4
│   ├── Stories From The Bible - Jonah.mp4
│   ├── The Prophet.mp4
│   └── ... (17 total files, ~2.25 GB)
│
├── audio/                            # User-uploaded audio podcasts
│   ├── [UUID].mp3                   # User audio files (UUID-named)
│   ├── [UUID].m4a                   # M4A format audio
│   ├── BeyondBelief-*.mp3           # BBC Beyond Belief podcasts
│   └── ... (117 files)
│
├── documents/                        # PDF documents
│   ├── bible.pdf                    # Bible document (3.5 MB)
│   └── doc_[UUID].pdf               # User documents
│
├── drafts/                          # User draft content
│   ├── audio/
│   │   └── draft_[UUID].m4a        # Audio drafts (2 files)
│   ├── video/
│   │   └── draft_[UUID].mp4        # Video drafts (3 files)
│   └── images/
│       └── draft_[UUID].jpg        # Image drafts (3 files)
│
├── images/                          # Images & thumbnails
│   ├── [UUID].png/jpg              # Community post images
│   ├── artist_covers/              # Artist cover images
│   ├── movies/                     # Movie posters/thumbnails
│   ├── profiles/                   # User profile pictures (7 files)
│   │   └── avatar_[short-id].jpg/png
│   ├── quotes/                     # Quote post backgrounds
│   └── thumbnails/                 # Video/audio thumbnails (29 files)
│       ├── default/
│       └── podcasts/
│
├── movies/                          # Full-length Christian movies
│   ├── Pilgrim's Progress [1979].mp4 (~971 MB)
│   ├── THE PASSION OF THE CHRIST(2004).mp4 (~285 MB)
│   └── The-Bible-Collection-Jeremiah.mp4 (~1.84 GB)
│
├── video/                           # User-uploaded video podcasts
│   └── [UUID].mp4                  # Video files (192 files)
│
└── test/                            # Test files
    ├── test-cloudfront-*.txt
    └── test-new-*.txt
```

---

## 🔧 Bucket Configuration

### CORS Configuration ✅
- **Allowed Methods:** GET, HEAD
- **Allowed Origins:**
  - `https://christnewtabernacle.com`
  - `https://www.christnewtabernacle.com`
  - `https://*.amplifyapp.com` (Amplify deployments)
  - `http://localhost:*` (Local development)
  - `http://127.0.0.1:*` (Local development)
- **Allowed Headers:**
  - `Content-Type`
  - `Range` (for video streaming)
  - `Accept-Encoding`
  - `Authorization`
- **Exposed Headers:**
  - `Content-Length`
  - `Content-Range`
  - `Accept-Ranges`
- **Max Age:** 3600 seconds (1 hour)

### Bucket Policy ✅
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::cnt-web-media/*"
    }
  ]
}
```
**Status:** Public read access enabled for all objects

### Versioning ✅
**Status:** ENABLED  
- All file versions are tracked
- Allows recovery from accidental deletions/overwrites

---

## 📂 File Naming Conventions

### UUID-Based Files (User Content)
- **Format:** `[UUID].ext` (e.g., `03e34c68-25e3-4885-981c-62e330231fa3.mp3`)
- **Used for:** User-uploaded audio, video, and images
- **Purpose:** Ensures uniqueness and prevents filename conflicts

### Draft Files
- **Format:** `draft_[UUID].ext` (e.g., `draft_18d6db18-e6a8-4248-beb5-f9003dbee5a9.m4a`)
- **Used for:** Temporary user drafts before publishing
- **Purpose:** Separate draft storage from published content

### Profile Pictures
- **Format:** `avatar_[short-id].ext` (e.g., `avatar_056f706daded.jpg`)
- **Used for:** User profile avatars
- **Purpose:** Shorter IDs for profile pictures

### Named Files (Admin Content)
- **Examples:** 
  - `Solomon's Kingdom.mp4`
  - `Pilgrim's Progress [1979].mp4`
  - `bible.pdf`
- **Used for:** Admin-uploaded curated content
- **Purpose:** Human-readable filenames for pre-selected content

---

## 🎯 Content Categories

### 1. Animated Bible Stories (17 files)
**Purpose:** Educational animated biblical narratives  
**Size:** ~2.25 GB total  
**Format:** MP4 video  
**Examples:**
- Old Testament series
- Stories of prophets (David, Jonah, etc.)
- Historical biblical events

### 2. Audio Podcasts (117 files)
**Purpose:** User-generated & curated audio content  
**Formats:** MP3, M4A, WAV  
**Types:**
- User-uploaded podcasts (UUID-named)
- BBC Beyond Belief series
- Faith discussions & sermons

### 3. Video Podcasts (192 files)
**Purpose:** User-generated video content  
**Format:** MP4  
**Storage:** UUID-based filenames for uniqueness

### 4. Movies (4 files)
**Purpose:** Full-length Christian films  
**Total Size:** ~3.1 GB  
**Notable Films:**
- Pilgrim's Progress (1979)
- The Passion of the Christ (2004)
- Bible Collection: Jeremiah

### 5. Documents (2 files)
**Purpose:** PDF resources  
**Content:** Bible PDF for reader feature

### 6. Images (53 files)
**Types:**
- Profile pictures (7)
- Thumbnails (29)
- Community post images (17+)
**Subfolders:** artist_covers, movies, profiles, quotes, thumbnails

### 7. Drafts (8 files)
**Purpose:** Temporary storage for in-progress content  
**Status:** Can be published or discarded by users  
**Categories:** Audio, Video, Images

---

## 🔐 Access Control

### Public Access
- ✅ **Read Access:** All objects are publicly readable
- ❌ **Write Access:** Restricted to authenticated backend API
- ❌ **Delete Access:** Restricted to authenticated backend API

### Upload Flow
1. Mobile/Web app requests signed URL from backend
2. Backend generates pre-signed S3 URL with upload permissions
3. Client uploads directly to S3 using signed URL
4. Backend stores media URL in PostgreSQL database

---

## 🚀 Performance Optimizations

### CORS for Streaming
- `Range` header support enables video/audio seeking
- Clients can request specific byte ranges for efficient streaming
- Reduces bandwidth usage for large files

### CloudFront Integration
- Can be integrated with CloudFront CDN for faster delivery
- Current setup: Direct S3 access
- **Recommendation:** Consider CloudFront for better global performance

---

## 📈 Storage Usage by Category

| Category | Files | Approx Size |
|----------|-------|-------------|
| Animated Bible Stories | 17 | 2.25 GB |
| Movies | 4 | 3.1 GB |
| Audio Podcasts | 117 | ~2-3 GB (estimated) |
| Video Podcasts | 192 | ~10-15 GB (estimated) |
| Images | 53 | ~50-100 MB |
| Drafts | 8 | ~5-10 MB |
| **TOTAL** | **~390** | **~18-24 GB** |

---

## 🔄 Media Workflow

### Content Creation Flow
```
User Records/Uploads → Draft Storage → Preview/Edit → Publish → Production Storage
                            ↓                                           ↓
                    drafts/[type]/              audio/video/images/
                    draft_[UUID].ext            [UUID].ext
```

### Draft to Published
1. User creates content in mobile app
2. Content saved to `drafts/[type]/draft_[UUID].ext`
3. User previews and edits
4. On publish: Content moved/copied to production folder
5. Draft can be deleted or kept for version history

---

## 🛠️ Management Recommendations

### 1. Lifecycle Policies
**Recommendation:** Implement lifecycle rules for:
- **Drafts older than 30 days:** Move to Glacier or delete
- **Old versions:** Transition to Glacier after 90 days
- **Test files:** Auto-delete after 7 days

### 2. CloudFront CDN
**Recommendation:** Add CloudFront distribution for:
- Faster global content delivery
- Reduced S3 costs (fewer GET requests)
- Edge caching for frequently accessed content

### 3. Monitoring
**Recommendation:** Enable:
- S3 Access Logging
- CloudWatch metrics for storage & requests
- Cost alerts for storage growth

### 4. Backup Strategy
**Current:** Versioning enabled ✅  
**Additional:** Consider cross-region replication for disaster recovery

---

## 🔍 Security Considerations

### Current Setup
✅ Public read access (appropriate for media platform)  
✅ Versioning enabled (protects against accidental deletion)  
✅ CORS properly configured  
❌ No encryption at rest configured  
❌ No access logging enabled

### Recommendations
1. **Enable S3 Server-Side Encryption (SSE-S3)**
2. **Enable access logging** to audit file access
3. **Implement S3 Object Lock** for critical content (movies, bible stories)
4. **Set up CloudTrail** for API-level auditing

---

## 📝 Notes

- All user-generated content uses UUID-based filenames to prevent conflicts
- The bucket supports both direct uploads (via signed URLs) and backend-mediated uploads
- CORS configuration allows local development and production domains
- Versioning provides a safety net for content management
- Draft system allows users to work on content before publishing

