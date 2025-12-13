# Production Deployment Guide - Video Editor

**Date:** December 12, 2025  
**Status:** ✅ PRODUCTION READY

---

## Overview

The video editor and all fixes applied are **fully compatible** with both local development and production environments. The code automatically detects the environment and adjusts URL construction accordingly.

---

## Environment Detection

### How It Works

The system uses environment variables to determine if it's running in development or production:

**Frontend (`api_service.dart`):**
```dart
static String get baseUrl {
  const envUrl = String.fromEnvironment('API_BASE_URL');
  return envUrl.isNotEmpty ? envUrl : AppConfig.apiBaseUrl;
}

static String get mediaBaseUrl {
  const envUrl = String.fromEnvironment('MEDIA_BASE_URL');
  return envUrl.isNotEmpty ? envUrl : AppConfig.mediaBaseUrl;
}
```

**Backend (`config.py`):**
```python
ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
S3_BUCKET_NAME: str = os.getenv("S3_BUCKET_NAME", "cnt-media-bucket")
CLOUDFRONT_URL: str = os.getenv("CLOUDFRONT_URL", "https://media.yourdomain.com")
```

---

## Configuration

### Local Development

**Environment Variables:**
```bash
API_BASE_URL=http://localhost:8002/api/v1
MEDIA_BASE_URL=http://localhost:8002
ENVIRONMENT=development
```

**Media Serving:**
- Backend serves files from `./media` directory via `/media` endpoint
- Video URL: `http://localhost:8002/media/video/{filename}`
- Files stored locally in `./media/video/`

**Video Editor Flow:**
1. User records video → blob URL
2. Upload to backend → saves to `./media/video/`
3. Returns relative path: `video/{filename}`
4. Frontend converts to: `http://localhost:8002/media/video/{filename}`
5. Video editing downloads from local backend
6. Processed video saved to `./media/video/`
7. Returns relative path, converted to full URL

### Production (AWS)

**Environment Variables (Amplify):**
```bash
API_BASE_URL=https://api.christnewtabernacle.com/api/v1
MEDIA_BASE_URL=https://d126sja5o8ue54.cloudfront.net
ENVIRONMENT=production
GOOGLE_CLIENT_ID=<your-google-client-id>
```

**AWS Configuration:**
- **S3 Bucket:** `cnt-web-media` (eu-west-2)
- **CloudFront Distribution:** `d126sja5o8ue54.cloudfront.net`
- **EC2 Backend:** `52.56.78.203` (eu-west-2)

**Media Serving:**
- Files stored in S3 bucket
- Served via CloudFront CDN
- Video URL: `https://d126sja5o8ue54.cloudfront.net/video/{filename}`

**Video Editor Flow:**
1. User records video → blob URL
2. Upload to backend → saves to S3 `video/` folder
3. Returns relative path: `video/{filename}`
4. Frontend converts to: `https://d126sja5o8ue54.cloudfront.net/video/{filename}`
5. Video editing downloads from CloudFront
6. Processed video uploaded to S3 by backend
7. Returns CloudFront URL

---

## S3 Bucket Structure

```
cnt-web-media/
├── audio/              # Audio files (podcasts, music)
├── video/              # Video files (podcasts, recordings, edited)
├── images/
│   ├── quotes/         # Generated quote images
│   ├── thumbnails/     # Video/audio thumbnails
│   ├── movies/         # Movie cover images
│   └── profiles/       # User profile images
├── documents/          # Bible documents, PDFs
└── animated-bible-stories/  # Animated content
```

---

## URL Construction Logic

### `getMediaUrl()` Method

**Development Mode:**
```dart
// Input: "video/temp_abc123.webm"
// Output: "http://localhost:8002/media/video/temp_abc123.webm"
```

**Production Mode:**
```dart
// Input: "video/temp_abc123.webm"
// Output: "https://d126sja5o8ue54.cloudfront.net/video/temp_abc123.webm"
```

### Video Editor Path Resolution

**Priority Order:**
```dart
final inputPath = _editedVideoPath ?? _persistedVideoPath ?? widget.videoPath;
```

1. **`_editedVideoPath`** - Previously edited video (full URL)
2. **`_persistedVideoPath`** - Original uploaded video (full URL)
3. **`widget.videoPath`** - Fallback (may be relative, converted to full URL)

---

## Backend Video Editing Service

### Local Development

**File Handling:**
```python
# Input: Full URL from frontend
# Downloads file to /tmp/video_editing/
# Processes with FFmpeg
# Saves to ./media/video/
# Returns relative path: "video/output.mp4"
```

### Production

**File Handling:**
```python
# Input: Full CloudFront URL from frontend
# Downloads file to /tmp/video_editing/
# Processes with FFmpeg
# Uploads to S3 bucket
# Returns CloudFront URL: "https://d126sja5o8ue54.cloudfront.net/video/output.mp4"
```

**S3 Upload Logic (`video_editing.py`):**
```python
use_s3 = os.getenv("ENVIRONMENT") == "production"

if use_s3:
    # Upload processed video to S3
    s3_url = await media_service.save_video_file(upload_file, output_filename)
    return {"url": s3_url, "filename": output_filename}
else:
    # Return local path
    return {"url": output_path, "filename": output_filename}
```

---

## CloudFront Configuration

### Distribution Settings

**Origin:**
- **Type:** S3 bucket
- **Bucket:** `cnt-web-media.s3.eu-west-2.amazonaws.com`
- **Origin Access:** CloudFront OAC (Origin Access Control)

**Behaviors:**
- **Path Pattern:** `/*`
- **Viewer Protocol:** Redirect HTTP to HTTPS
- **Allowed Methods:** GET, HEAD, OPTIONS
- **Cache Policy:** CachingOptimized
- **CORS:** Enabled for video streaming

**Security:**
- S3 bucket is **private** (not publicly accessible)
- Only CloudFront can access S3 via OAC
- EC2 backend has IAM role for S3 write access

---

## Amplify Build Configuration

**File:** `amplify.yml`

```yaml
flutter build web --release \
  --dart-define=API_BASE_URL=$API_BASE_URL \
  --dart-define=MEDIA_BASE_URL=$MEDIA_BASE_URL \
  --dart-define=ENVIRONMENT=production
```

**Environment Variables (Set in Amplify Console):**
- `API_BASE_URL` = `https://api.christnewtabernacle.com/api/v1`
- `MEDIA_BASE_URL` = `https://d126sja5o8ue54.cloudfront.net`
- `LIVEKIT_WS_URL` = `wss://livekit.christnewtabernacle.com`
- `WEBSOCKET_URL` = `wss://api.christnewtabernacle.com`
- `GOOGLE_CLIENT_ID` = `<your-google-client-id>`

---

## Testing Checklist

### Local Development ✅
- [x] Video recording works
- [x] Video upload to backend works
- [x] Video editor loads video
- [x] Video trim works
- [x] Video remove audio works
- [x] Video add audio works
- [x] Edited video playback works

### Production ✅
- [x] S3 bucket configured (`cnt-web-media`)
- [x] CloudFront distribution active (`d126sja5o8ue54.cloudfront.net`)
- [x] EC2 backend has S3 write permissions
- [x] Environment variables set in Amplify
- [x] CORS configured for video streaming
- [x] Video URLs use CloudFront domain
- [x] Backend uploads to S3 in production mode

---

## Deployment Steps

### 1. Backend Deployment (EC2)

```bash
# SSH to EC2
ssh -i christnew.pem ubuntu@52.56.78.203

# Navigate to backend
cd ~/cnt-web-deployment/backend

# Set environment variables in .env
ENVIRONMENT=production
S3_BUCKET_NAME=cnt-web-media
CLOUDFRONT_URL=https://d126sja5o8ue54.cloudfront.net

# Restart backend
docker-compose restart cnt-backend
```

### 2. Frontend Deployment (Amplify)

**Automatic deployment on git push to main branch**

Amplify will:
1. Clone repository
2. Install Flutter SDK
3. Run `flutter build web` with production env vars
4. Deploy to CloudFront distribution

### 3. Verify Deployment

**Check Backend:**
```bash
curl https://api.christnewtabernacle.com/api/v1/health
```

**Check Frontend:**
```
https://d1poes9tyirmht.amplifyapp.com
```

**Check Media:**
```
https://d126sja5o8ue54.cloudfront.net/video/test.mp4
```

---

## Troubleshooting

### Issue: Video not loading in editor

**Check:**
1. Console logs for URL construction
2. Network tab for 403/404 errors
3. CloudFront distribution status
4. S3 bucket permissions

**Solution:**
- Ensure `MEDIA_BASE_URL` is set correctly
- Verify CloudFront OAC has S3 access
- Check CORS configuration

### Issue: Video trim fails

**Check:**
1. Backend logs for FFmpeg errors
2. EC2 disk space (`df -h`)
3. S3 upload permissions

**Solution:**
- Verify IAM role has `s3:PutObject` permission
- Check `/tmp` directory has space
- Ensure FFmpeg is installed on EC2

### Issue: CORS errors

**Check:**
1. CloudFront CORS configuration
2. S3 bucket CORS policy
3. Backend CORS middleware

**Solution:**
- Add allowed origins to backend CORS
- Configure CloudFront to forward CORS headers
- Ensure S3 bucket CORS allows CloudFront

---

## Performance Considerations

### Video Download Optimization

**Local:**
- Fast (local network)
- No bandwidth costs

**Production:**
- CloudFront CDN provides low latency
- Edge locations cache frequently accessed videos
- Reduces load on S3

### Video Upload Optimization

**Backend Processing:**
- Downloads video to `/tmp` (fast local disk)
- Processes with FFmpeg
- Uploads result to S3
- Cleans up temp files

**Recommended:**
- Use EC2 instance with sufficient disk space
- Monitor `/tmp` usage
- Set up CloudWatch alarms for disk space

---

## Cost Optimization

### S3 Storage
- Use S3 Intelligent-Tiering for automatic cost optimization
- Set lifecycle policies to delete temp files after 7 days
- Use S3 Transfer Acceleration for faster uploads

### CloudFront
- Enable compression for smaller file sizes
- Use appropriate cache TTL (e.g., 1 day for videos)
- Monitor bandwidth usage

### EC2
- Use appropriate instance size for video processing
- Consider spot instances for non-critical workloads
- Set up auto-scaling for high traffic periods

---

## Security Best Practices

### S3 Bucket
- ✅ Private bucket (no public access)
- ✅ CloudFront OAC for access control
- ✅ Encryption at rest enabled
- ✅ Versioning enabled for backup

### CloudFront
- ✅ HTTPS only (redirect HTTP)
- ✅ Signed URLs for sensitive content (optional)
- ✅ WAF integration for DDoS protection (optional)

### Backend
- ✅ IAM role for S3 access (no hardcoded credentials)
- ✅ JWT authentication for API endpoints
- ✅ CORS configured for specific origins
- ✅ Rate limiting enabled

---

## Monitoring

### CloudWatch Metrics
- S3 bucket size and request count
- CloudFront bandwidth and cache hit ratio
- EC2 CPU, memory, and disk usage
- Lambda function errors (if using)

### Application Logs
- Backend logs for video processing errors
- Frontend console logs for URL construction
- S3 access logs for debugging

---

**Status:** ✅ PRODUCTION READY - All configurations verified and tested
