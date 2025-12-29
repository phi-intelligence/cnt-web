# CNT Media Platform - S3 Bucket Structure Analysis

**Date:** Current Analysis  
**Status:** Complete understanding of S3 bucket structure, access patterns, and configuration  
**Bucket:** `cnt-web-media` (eu-west-2)

---

## Table of Contents

1. [S3 Bucket Configuration](#s3-bucket-configuration)
2. [Complete Folder Structure](#complete-folder-structure)
3. [File Naming Conventions](#file-naming-conventions)
4. [Access Control & Security](#access-control--security)
5. [CloudFront Integration](#cloudfront-integration)
6. [Upload Patterns](#upload-patterns)
7. [URL Resolution Logic](#url-resolution-logic)
8. [Development vs Production](#development-vs-production)
9. [File Types & Extensions](#file-types--extensions)
10. [Storage Patterns by Feature](#storage-patterns-by-feature)

---

## S3 Bucket Configuration

### Basic Information

- **Bucket Name:** `cnt-web-media`
- **Region:** `eu-west-2` (London)
- **Account ID:** `649159624630`
- **CloudFront Distribution ID:** `E3ER061DLFYFK8`
- **CloudFront URL:** `https://d126sja5o8ue54.cloudfront.net`
- **OAC ID:** `E1LSA9PF0Z69X7` (Origin Access Control)

### Access Methods

1. **CloudFront OAC (Origin Access Control):**
   - Public reads via CloudFront distribution
   - Secure access through CloudFront only
   - No direct S3 public access

2. **EC2 Backend Direct Access:**
   - Server IP: `52.56.78.203/32`
   - Direct S3 access for uploads
   - Uses AWS credentials from EC2 instance

---

## Complete Folder Structure

```
cnt-web-media/
│
├── audio/                                    # Audio podcast files
│   ├── {uuid}.mp3                           # MP3 audio files
│   ├── {uuid}.wav                           # WAV audio files
│   ├── {uuid}.webm                          # WebM audio files
│   ├── {uuid}.m4a                           # M4A audio files
│   ├── {uuid}.aac                           # AAC audio files
│   ├── {uuid}.flac                          # FLAC audio files
│   └── temp_{uuid}.{ext}                    # Temporary audio files (for editing)
│
├── video/                                    # Video podcast files
│   ├── {uuid}.mp4                           # MP4 video files
│   ├── {uuid}.webm                          # WebM video files
│   ├── {uuid}.mov                           # QuickTime video files
│   ├── {uuid}.avi                           # AVI video files
│   ├── {uuid}.mkv                           # Matroska video files
│   └── previews/                            # Short preview clips (optional)
│       └── {uuid}.mp4                       # Preview video clips
│
├── images/                                   # All image files
│   │
│   ├── quotes/                               # Generated quote images
│   │   └── quote_{post_id}_{hash}.jpg       # Auto-generated quote images from text posts
│   │                                         # Example: quote_13_a1b2c3d4.jpg
│   │
│   ├── thumbnails/                          # Thumbnail images
│   │   │
│   │   ├── podcasts/                        # Podcast thumbnails
│   │   │   ├── custom/                      # User-uploaded custom thumbnails
│   │   │   │   └── {uuid}.jpg              # Custom thumbnail files
│   │   │   └── generated/                  # Auto-generated thumbnails from video
│   │   │       └── {uuid}.jpg              # Thumbnails extracted from video frames
│   │   │
│   │   └── default/                         # Default thumbnail templates
│   │       ├── 1.jpg                        # Default thumbnail template 1
│   │       ├── 2.jpg                        # Default thumbnail template 2
│   │       ├── 3.jpg                        # Default thumbnail template 3
│   │       ├── ...                          # Templates 4-12
│   │       └── 12.jpg                       # Default thumbnail template 12
│   │
│   ├── movies/                              # Movie posters/cover images
│   │   └── {uuid}.{ext}                     # Movie poster images (JPG, PNG)
│   │
│   ├── profiles/                             # User profile images
│   │   └── profile_{uuid}.{ext}              # User avatar images
│   │                                         # Example: profile_abc123.jpg
│   │
│   └── {uuid}.{ext}                         # General images (community posts, etc.)
│                                             # Direct uploads for community posts
│
├── documents/                                # PDF documents (Bible, etc.)
│   └── {filename}.pdf                       # PDF files
│                                             # Example: bible.pdf, kjv-bible.pdf
│
└── animated-bible-stories/                  # Video files for Bible stories
    └── *.mp4                                # Animated Bible story videos
```

---

## File Naming Conventions

### UUID-Based Naming

**Pattern:** `{uuid}.{extension}`

**UUID Generation:**
- Generated using UUID v4
- Ensures uniqueness
- Prevents naming conflicts

**Examples:**
- Audio: `a1b2c3d4-e5f6-7890-abcd-ef1234567890.mp3`
- Video: `b2c3d4e5-f6a7-8901-bcde-f12345678901.mp4`
- Image: `c3d4e5f6-a7b8-9012-cdef-123456789012.jpg`

### Special Naming Patterns

1. **Temporary Audio Files:**
   - Pattern: `temp_{uuid}.{ext}`
   - Example: `temp_a1b2c3d4-e5f6-7890-abcd-ef1234567890.webm`
   - Purpose: Files uploaded for editing workflows (no bank details required)

2. **Quote Images:**
   - Pattern: `quote_{post_id}_{hash}.jpg`
   - Example: `quote_13_a1b2c3d4.jpg`
   - Purpose: Auto-generated quote images from text posts
   - Hash: MD5 hash of post content (for cache busting)

3. **Profile Images:**
   - Pattern: `profile_{uuid}.{ext}`
   - Example: `profile_abc123def456.jpg`
   - Purpose: User profile avatars

4. **Default Thumbnails:**
   - Pattern: `{number}.jpg`
   - Example: `1.jpg`, `2.jpg`, ..., `12.jpg`
   - Purpose: Pre-uploaded default thumbnail templates

5. **Document Files:**
   - Pattern: `{filename}.pdf`
   - Example: `bible.pdf`, `kjv-bible.pdf`
   - Purpose: PDF documents (Bible, etc.)

---

## Access Control & Security

### Bucket Policy (`s3-bucket-policy.json`)

**Two Access Rules:**

1. **CloudFront OAC Access:**
```json
{
  "Sid": "AllowCloudFrontOACAccess",
  "Effect": "Allow",
  "Principal": {
    "Service": "cloudfront.amazonaws.com"
  },
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::cnt-web-media/*",
  "Condition": {
    "StringEquals": {
      "AWS:SourceArn": "arn:aws:cloudfront::649159624630:distribution/E3ER061DLFYFK8"
    }
  }
}
```

2. **EC2 Server IP Access:**
```json
{
  "Sid": "AllowServerIPAccess",
  "Effect": "Allow",
  "Principal": "*",
  "Action": "s3:GetObject",
  "Resource": "arn:aws:s3:::cnt-web-media/*",
  "Condition": {
    "IpAddress": {
      "aws:SourceIp": "52.56.78.203/32"
    }
  }
}
```

**Security Features:**
- ✅ No public direct S3 access
- ✅ CloudFront OAC for secure public reads
- ✅ EC2 IP whitelist for backend uploads
- ✅ IAM credentials required for writes

### CORS Configuration (`s3-cors-config.json`)

**Allowed Origins:**
- `https://main.d1poes9tyirmht.amplifyapp.com` (Amplify)
- `https://christnewtabernacle.com`
- `https://www.christnewtabernacle.com`
- `http://localhost:*` (Development)
- `http://127.0.0.1:*` (Development)

**Allowed Methods:**
- `GET` - Read files
- `HEAD` - Check file existence

**Allowed Headers:** `*` (All headers)

**Exposed Headers:**
- `ETag`
- `Content-Length`
- `Content-Type`
- `Date`
- `Last-Modified`

**Max Age:** 3600 seconds (1 hour)

---

## CloudFront Integration

### CloudFront Distribution

- **Distribution ID:** `E3ER061DLFYFK8`
- **Domain:** `d126sja5o8ue54.cloudfront.net`
- **Origin:** `cnt-web-media.s3.eu-west-2.amazonaws.com`
- **OAC:** `E1LSA9PF0Z69X7`

### URL Mapping

**S3 Path → CloudFront URL:**

```
S3: s3://cnt-web-media/audio/abc123.mp3
CloudFront: https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3

S3: s3://cnt-web-media/images/quotes/quote_13_a1b2c3d4.jpg
CloudFront: https://d126sja5o8ue54.cloudfront.net/images/quotes/quote_13_a1b2c3d4.jpg
```

**Direct Mapping:**
- CloudFront maps directly to S3 paths
- No `/media/` prefix in production
- Path structure preserved exactly

---

## Upload Patterns

### Audio Upload

**Endpoint:** `POST /api/v1/upload/audio`

**S3 Path:** `audio/{uuid}.{ext}`

**Process:**
1. Frontend uploads file to backend
2. Backend generates UUID
3. Backend uploads to S3: `audio/{uuid}.{ext}`
4. Backend returns CloudFront URL

**Example:**
```
Upload: audio_file.mp3
S3: audio/a1b2c3d4-e5f6-7890-abcd-ef1234567890.mp3
URL: https://d126sja5o8ue54.cloudfront.net/audio/a1b2c3d4-e5f6-7890-abcd-ef1234567890.mp3
```

### Video Upload

**Endpoint:** `POST /api/v1/upload/video`

**S3 Path:** `video/{uuid}.{ext}`

**Thumbnail Generation:**
- Auto-generates thumbnail if `generate_thumbnail=true`
- Extracts frame at 45 seconds (or 10% of duration)
- Saves to: `images/thumbnails/podcasts/generated/{uuid}.jpg`

**Process:**
1. Frontend uploads video to backend
2. Backend generates UUID
3. Backend uploads to S3: `video/{uuid}.{ext}`
4. Backend generates thumbnail: `images/thumbnails/podcasts/generated/{uuid}.jpg`
5. Backend returns CloudFront URLs for both

**Example:**
```
Upload: video_file.mp4
S3 Video: video/b2c3d4e5-f6a7-8901-bcde-f12345678901.mp4
S3 Thumbnail: images/thumbnails/podcasts/generated/b2c3d4e5-f6a7-8901-bcde-f12345678901.jpg
URL: https://d126sja5o8ue54.cloudfront.net/video/b2c3d4e5-f6a7-8901-bcde-f12345678901.mp4
Thumbnail URL: https://d126sja5o8ue54.cloudfront.net/images/thumbnails/podcasts/generated/b2c3d4e5-f6a7-8901-bcde-f12345678901.jpg
```

### Image Upload (Community Posts)

**Endpoint:** `POST /api/v1/upload/image`

**S3 Path:** `images/{uuid}.{ext}`

**Process:**
1. Frontend uploads image to backend
2. Backend generates UUID
3. Backend uploads to S3: `images/{uuid}.{ext}`
4. Backend returns CloudFront URL

**Example:**
```
Upload: photo.jpg
S3: images/c3d4e5f6-a7b8-9012-cdef-123456789012.jpg
URL: https://d126sja5o8ue54.cloudfront.net/images/c3d4e5f6-a7b8-9012-cdef-123456789012.jpg
```

### Profile Image Upload

**Endpoint:** `POST /api/v1/upload/profile-image`

**S3 Path:** `images/profiles/profile_{uuid}.{ext}`

**Process:**
1. Frontend uploads profile image
2. Backend generates UUID
3. Backend uploads to S3: `images/profiles/profile_{uuid}.{ext}`
4. Backend updates user record with new avatar URL

**Example:**
```
Upload: avatar.jpg
S3: images/profiles/profile_abc123def456.jpg
URL: https://d126sja5o8ue54.cloudfront.net/images/profiles/profile_abc123def456.jpg
```

### Quote Image Generation

**Process:**
1. User creates text post
2. Backend detects `post_type='text'`
3. Backend calls `generate_quote_image()` service
4. Service:
   - Selects random template from `quote_templates.py`
   - Renders text with PIL/Pillow
   - Generates hash from post content
   - Saves to S3: `images/quotes/quote_{post_id}_{hash}.jpg`
5. Backend updates post with `image_url`

**Example:**
```
Post ID: 13
Content Hash: a1b2c3d4
S3: images/quotes/quote_13_a1b2c3d4.jpg
URL: https://d126sja5o8ue54.cloudfront.net/images/quotes/quote_13_a1b2c3d4.jpg
```

### Document Upload (Admin Only)

**Endpoint:** `POST /api/v1/upload/document`

**S3 Path:** `documents/{filename}.pdf`

**Process:**
1. Admin uploads PDF document
2. Backend saves to S3: `documents/{filename}.pdf`
3. Backend creates document record in database

**Example:**
```
Upload: bible.pdf
S3: documents/bible.pdf
URL: https://d126sja5o8ue54.cloudfront.net/documents/bible.pdf
```

### Temporary Audio Upload (For Editing)

**Endpoint:** `POST /api/v1/upload/temporary-audio`

**S3 Path:** `audio/temp_{uuid}.{ext}`

**Purpose:**
- Files uploaded for editing workflows
- No bank details required
- Can be cleaned up later

**Example:**
```
Upload: recording.webm
S3: audio/temp_a1b2c3d4-e5f6-7890-abcd-ef1234567890.webm
URL: https://d126sja5o8ue54.cloudfront.net/audio/temp_a1b2c3d4-e5f6-7890-abcd-ef1234567890.webm
```

---

## URL Resolution Logic

### Frontend URL Resolution (`api_service.dart`)

**Function:** `getMediaUrl(String? path)`

**Logic Flow:**

1. **Full URLs (http:// or https://):**
   - Return as-is (no modification)

2. **CloudFront/S3 Domain Detection:**
   - If path contains `cloudfront.net` or `.amazonaws.com` or `.s3.`
   - Add `https://` prefix if missing

3. **Media Prefix Handling:**
   - **Development:** Keep `media/` prefix (backend serves from `/media` endpoint)
   - **Production:** Strip `media/` prefix (CloudFront maps directly to S3)

4. **Assets Path Conversion:**
   - Convert `assets/images/` to `images/` (remove `assets/` prefix)

5. **Direct S3 Paths:**
   - Paths starting with `images/`, `audio/`, `video/`, `movies/`, `documents/`
   - **Development:** Add `/media/` prefix
   - **Production:** Use as-is (direct CloudFront path)

**Examples:**

**Development Mode:**
```
Input: audio/abc123.mp3
Output: http://localhost:8002/media/audio/abc123.mp3

Input: images/quotes/quote_13.jpg
Output: http://localhost:8002/media/images/quotes/quote_13.jpg
```

**Production Mode:**
```
Input: audio/abc123.mp3
Output: https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3

Input: images/quotes/quote_13.jpg
Output: https://d126sja5o8ue54.cloudfront.net/images/quotes/quote_13.jpg
```

---

## Development vs Production

### Development Mode

**Backend Serves Files:**
- Local files stored in `backend/media/` directory
- Backend serves via `/media` endpoint
- Same folder structure as S3

**URL Pattern:**
```
http://localhost:8002/media/audio/abc123.mp3
http://localhost:8002/media/images/quotes/quote_13.jpg
```

**Frontend Behavior:**
- Adds `/media/` prefix to paths
- Uses localhost URLs

### Production Mode

**S3 + CloudFront:**
- Files stored in S3 bucket
- CloudFront serves files via CDN
- Direct S3 path mapping

**URL Pattern:**
```
https://d126sja5o8ue54.cloudfront.net/audio/abc123.mp3
https://d126sja5o8ue54.cloudfront.net/images/quotes/quote_13.jpg
```

**Frontend Behavior:**
- Strips `/media/` prefix from paths
- Uses CloudFront URLs directly

---

## File Types & Extensions

### Audio Files

**Supported Formats:**
- `.mp3` - MPEG Audio Layer 3
- `.wav` - Waveform Audio
- `.webm` - WebM Audio
- `.m4a` - MPEG-4 Audio
- `.aac` - Advanced Audio Coding
- `.flac` - Free Lossless Audio Codec
- `.ogg` - Ogg Vorbis

**Storage Location:** `audio/`

### Video Files

**Supported Formats:**
- `.mp4` - MPEG-4 Video
- `.webm` - WebM Video
- `.mov` - QuickTime Video
- `.avi` - Audio Video Interleave
- `.mkv` - Matroska Video

**Storage Location:** `video/`

**Preview Clips:** `video/previews/`

### Image Files

**Supported Formats:**
- `.jpg` / `.jpeg` - JPEG images
- `.png` - PNG images
- `.gif` - GIF images (if supported)
- `.webp` - WebP images (if supported)

**Storage Locations:**
- General images: `images/{uuid}.{ext}`
- Quote images: `images/quotes/quote_{post_id}_{hash}.jpg`
- Thumbnails: `images/thumbnails/podcasts/{custom|generated}/{uuid}.jpg`
- Movie posters: `images/movies/{uuid}.{ext}`
- Profile images: `images/profiles/profile_{uuid}.{ext}`

### Document Files

**Supported Formats:**
- `.pdf` - PDF documents

**Storage Location:** `documents/`

---

## Storage Patterns by Feature

### Podcasts (Audio/Video)

**Audio Podcasts:**
- Audio file: `audio/{uuid}.{ext}`
- Thumbnail: `images/thumbnails/podcasts/custom/{uuid}.jpg` (if uploaded)
- Or: `images/thumbnails/podcasts/generated/{uuid}.jpg` (if auto-generated)
- Or: `images/thumbnails/default/{1-12}.jpg` (if using default)

**Video Podcasts:**
- Video file: `video/{uuid}.{ext}`
- Thumbnail: `images/thumbnails/podcasts/generated/{uuid}.jpg` (auto-generated)
- Or: `images/thumbnails/podcasts/custom/{uuid}.jpg` (if user uploads custom)

### Community Posts

**Image Posts:**
- Image: `images/{uuid}.{ext}`

**Text Posts (Quote Images):**
- Quote image: `images/quotes/quote_{post_id}_{hash}.jpg`
- Auto-generated by backend

### User Profiles

**Profile Images:**
- Avatar: `images/profiles/profile_{uuid}.{ext}`

**Artist Cover Images:**
- Cover: `images/{uuid}.{ext}` (stored in general images, referenced in artist record)

### Movies

**Movie Content:**
- Video: `video/{uuid}.{ext}` (if video file)
- Poster: `images/movies/{uuid}.{ext}`
- Preview: `video/previews/{uuid}.mp4` (optional)

### Bible Content

**Documents:**
- PDF: `documents/{filename}.pdf`

**Animated Stories:**
- Video: `animated-bible-stories/*.mp4`

### Editing Workflows

**Temporary Files:**
- Temporary audio: `audio/temp_{uuid}.{ext}`
- Used for editing before final upload

**Edited Files:**
- After editing, new files created with new UUIDs
- Old files may be cleaned up (implementation dependent)

---

## Summary

### Key Points

✅ **Well-Organized Structure:**
- Clear separation by content type
- Logical folder hierarchy
- Consistent naming conventions

✅ **Secure Access:**
- CloudFront OAC for public reads
- EC2 IP whitelist for backend writes
- No direct public S3 access

✅ **Scalable Design:**
- UUID-based naming prevents conflicts
- Folder structure supports growth
- Easy to add new content types

✅ **Development Support:**
- Local development mirrors S3 structure
- URL resolution handles both modes
- Easy to test locally

✅ **CDN Integration:**
- CloudFront for fast global delivery
- Direct S3 path mapping
- No URL rewriting needed

### Storage Statistics (Estimated)

- **Audio Files:** `audio/` - Podcast audio content
- **Video Files:** `video/` - Podcast video content
- **Images:** `images/` - All image types (quotes, thumbnails, profiles, movies)
- **Documents:** `documents/` - PDF files (Bible, etc.)
- **Animated Stories:** `animated-bible-stories/` - Video content

### Best Practices

1. **Always use UUIDs** for file naming
2. **Store paths in database** (not full URLs)
3. **Use CloudFront URLs** in production
4. **Clean up temporary files** after editing
5. **Validate file types** before upload
6. **Generate thumbnails** for video content
7. **Use appropriate folders** for each content type

---

**Document Created:** Complete S3 bucket structure analysis  
**Last Updated:** Current  
**Status:** ✅ Comprehensive understanding achieved
