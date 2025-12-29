# CNT Media Platform - Media Upload Guide

**Date:** December 20, 2025  
**Purpose:** Replace dummy S3 content with curated biblical audio and movies

---

## 📋 Overview

### Current Status
- **S3 Audio:** 116 dummy files (BBC Beyond Belief podcasts, test files)
- **S3 Movies:** 3 dummy movies (need verification)
- **Status:** All current content is placeholder/dummy data

### New Content to Upload
- **Audio:** 77 biblical story MP3 files (~1.3 GB)
- **Movies:** 3 Christian films (~4.0 GB)
- **Total Size:** ~5.3 GB

---

## 🎯 Content Breakdown

### New Audio Files (77 files, ~1.3 GB)
Biblical audio stories covering:

#### Old Testament Series
- **Adam & Eve** - Creation story
- **Noah** - The flood narrative
- **Abraham Series** (2 episodes)
  - Abraham Pioneer
  - Abraham Gods Friend
- **Isaac & Rebekah** stories
- **Jacob Series** (2 episodes)
  - Jacob Grabbing Twin
  - Jacob Gods Prince
- **Joseph Series** (3 episodes)
  - Joseph Brothers Schemes
  - Joseph Pharaohs Dreams
  - Joseph Grand Vizier
- **Moses Series** (9 episodes)
  - Moses Baby
  - Moses Burning Bush
  - Moses Great Escape
  - Moses Golden Calf
  - Moses House For God
  - Moses Journeys End
  - Moses Desert Encounter
- **Joshua Series** (5 episodes)
  - Joshua Spies Secret Mission
  - Joshua Strange Plan Battle
  - Joshua Waiting Border
  - Joshua Neighbours Ruse
  - Joshua Haven Hunted
- **Judges Period**
  - Gideon
  - Jephthah
  - Samson Lion Killer
  - Samson Wrecker
- **Ruth** - Full story
- **Samuel** stories
- **Hannah** story
- **Daniel Series** (2 episodes)
- **Queen Esther**
- **Job Series** (2 episodes)
- **Dead Sea Scrolls Isaiah** (2 episodes)

#### New Testament - Jesus Series (33 episodes)
- **Birth & Childhood** (3 episodes)
  - Jesus Baby 1
  - Jesus Baby 2
  - Jesus Boy
- **Ministry Period** (30+ episodes)
  - Jesus Carpenter
  - Jesus Temple Thieves
  - Jesus Secret Guest
  - Jesus Kingdom Kids (2 parts)
  - Jesus Frustrated Fisherman
  - Jesus Trip Abroad
  - Jesus Customs Crew
  - Jesus Crucial Choice
  - Jesus Children
  - Jesus Feast Of Booths
  - Jesus Dreadful Foe
  - Jesus Light World
  - Jesus Cavilling Clique
  - Jesus Burning Question
  - Jesus Wayside Scenes
  - Jesus Jericho Road
  - Jesus Lost Sheep
  - Jesus Resented Race
  - Jesus World Last Days
  - Jesus Lonely Battle
  - Jesus Hosannas
  - Jesus Cross
  - Jesus Splendid Dawn

#### Early Church - Peter & Paul Series (12 episodes)
- **Peter & John**
  - Peter John Beautiful Gate
  - Peter John Prison Mystery
- **Paul's Conversion & Ministry**
  - Saul Midnight Getaway
  - Paul Silas News Afar
  - Paul Magic Man Spell
  - Paul Daring Expedition
  - Paul Corinthian Friends
  - Paul Governor Gallio
  - Paul Plots Jerusalem
  - Paul Trouble Temple
  - Paul Riot Ephesus
  - Paul Shipwreck

### New Movies (3 files, ~4.0 GB)
1. **Pilgrim's Progress [1979]** (~927 MB)
   - Classic Christian allegory
   - Based on John Bunyan's masterpiece

2. **The Passion of The Christ** (~1.3 GB)
   - Mel Gibson's 2004 film
   - Depicts final hours of Jesus

3. **The Bible Collection - Jeremiah** (~1.7 GB)
   - Full Bible Collection episode
   - Prophet Jeremiah's story

---

## 🛠️ Upload Methods

### Method 1: Automated Script (Recommended) ⭐

**Advantages:**
- Fast bulk upload
- Automatic content-type setting
- Progress tracking
- Backup of old content

**Steps:**

1. **Review and verify local files:**
```bash
# Check audio files
ls -lh /home/phi/Phi-Intelligence/cnt-web-deployment/media/audio/

# Check movies
ls -lh /home/phi/Phi-Intelligence/cnt-web-deployment/media/movies/
```

2. **Make script executable:**
```bash
chmod +x /home/phi/Phi-Intelligence/cnt-web-deployment/scripts/refresh_s3_media.sh
```

3. **Run the script:**
```bash
cd /home/phi/Phi-Intelligence/cnt-web-deployment
./scripts/refresh_s3_media.sh
```

4. **Script will:**
   - ✅ Backup current S3 file list to `/tmp/s3_backup/`
   - ✅ Delete all existing audio files from S3
   - ✅ Delete all existing movies from S3
   - ✅ Upload 77 new audio files with correct content-type
   - ✅ Upload 3 new movies with correct content-type
   - ✅ Verify uploads

**Estimated Time:** 10-15 minutes (depending on internet speed)

---

### Method 2: Manual AWS CLI Upload

If you prefer manual control:

```bash
# Step 1: Delete old content
aws s3 rm s3://cnt-web-media/audio/ --recursive --exclude ".gitkeep"
aws s3 rm s3://cnt-web-media/movies/ --recursive --exclude ".gitkeep"

# Step 2: Upload audio files
aws s3 cp /home/phi/Phi-Intelligence/cnt-web-deployment/media/audio/ \
    s3://cnt-web-media/audio/ \
    --recursive \
    --exclude "*" \
    --include "*.mp3" \
    --content-type "audio/mpeg"

# Step 3: Upload movies
aws s3 cp /home/phi/Phi-Intelligence/cnt-web-deployment/media/movies/ \
    s3://cnt-web-media/movies/ \
    --recursive \
    --exclude "*" \
    --include "*.mp4" \
    --content-type "video/mp4"
```

---

### Method 3: Via Admin Dashboard Interface

**Admin Credentials:**
- **Email:** `kofi.webb@agilentmaritime.com`
- **Password:** `christ@agilent`
- **Role:** Admin (also registered as Artist)

**Steps:**

1. **Access Admin Dashboard:**
   - Web: `https://christnewtabernacle.com/admin` or local dev
   - Mobile: Admin section in profile

2. **For Audio Uploads:**
   - Navigate to: **Admin Dashboard → Audio Management → Upload Audio**
   - Select podcast category (e.g., "Bible Stories", "Sermons")
   - Upload files one by one or in batches
   - Add metadata:
     - Title (extracted from filename)
     - Description
     - Category
     - Duration (auto-detected)
   - Files will upload to S3 and register in database

3. **For Movie Uploads:**
   - Navigate to: **Admin Dashboard → Content → Movies → Add Movie**
   - Upload video file
   - Add metadata:
     - Title
     - Description
     - Genre
     - Release year
     - Thumbnail
   - Files will upload to S3 and register in database

**Note:** Admin upload interface handles database registration automatically, unlike direct S3 upload.

---

## 🔄 Post-Upload Steps

### 1. Database Registration

After S3 upload, you must register content in the database:

#### Option A: Via Admin Interface (Recommended)
- Use the admin dashboard to "Add from S3"
- Admin can browse S3 and add metadata
- Automatically creates database entries

#### Option B: Via Backend Script
Create a script to scan S3 and register files:

```python
# Example: Register audio files from S3
import os
from app.database import get_db
from app.models import Podcast
from app.services.api_service import ApiService

api = ApiService()
s3_audio_files = api.list_s3_files('audio/')

for file in s3_audio_files:
    podcast = Podcast(
        title=extract_title_from_filename(file),
        audio_url=file,
        category_id=1,  # Bible Stories
        status='published',
        user_id=admin_user_id
    )
    db.add(podcast)
db.commit()
```

### 2. Verification Checklist

After upload, verify:

- [ ] Files accessible via S3 URLs
- [ ] Files appear in admin dashboard
- [ ] Audio playback works on mobile app
- [ ] Video playback works on mobile app
- [ ] Thumbnails generated/uploaded
- [ ] Metadata correctly populated
- [ ] Content appears in user-facing app
- [ ] Search functionality finds new content

### 3. Test Playback

**Test URLs:**
```
Audio: https://cnt-web-media.s3.eu-west-2.amazonaws.com/audio/Adam%20Eve.mp3
Movie: https://cnt-web-media.s3.eu-west-2.amazonaws.com/movies/Pilgrim's%20Progress%20%5B1979%5D%20.mp4
```

---

## 📊 Upload Progress Tracking

### Monitoring Upload
```bash
# Watch upload progress
watch -n 5 'aws s3 ls s3://cnt-web-media/audio/ | wc -l && aws s3 ls s3://cnt-web-media/movies/ | wc -l'

# Check total size uploaded
aws s3 ls s3://cnt-web-media/audio/ --recursive --human-readable --summarize
aws s3 ls s3://cnt-web-media/movies/ --recursive --human-readable --summarize
```

### Expected Results After Upload
```
Audio Files:
  - Count: 77 files
  - Size: ~1.3 GB
  - Format: MP3 (audio/mpeg)

Movies:
  - Count: 3 files
  - Size: ~4.0 GB
  - Format: MP4 (video/mp4)
```

---

## ⚠️ Important Notes

### Content Type Headers
Files **must** have correct content-type headers for proper streaming:
- Audio: `audio/mpeg`
- Movies: `video/mp4`

The automated script sets these automatically.

### File Naming
- Current local files have spaces and special characters
- S3 will URL-encode these (e.g., `Adam Eve.mp3` → `Adam%20Eve.mp3`)
- This is normal and handled by the app

### CORS & Permissions
- Current S3 CORS configuration supports streaming ✅
- Files are publicly readable ✅
- No changes needed to bucket policy

### Backup
- Old S3 file list is backed up to `/tmp/s3_backup/`
- Keep this for reference if needed
- Versioning is enabled on bucket, so files can be recovered

### Cost Implications
- S3 Storage: ~5.3 GB = ~$0.13/month
- Data Transfer: First 1 GB free, then $0.09/GB
- Requests: GET requests ~$0.0004 per 1,000 requests

---

## 🚨 Troubleshooting

### Upload Fails
```bash
# Check AWS credentials
aws sts get-caller-identity

# Check bucket permissions
aws s3api get-bucket-policy --bucket cnt-web-media

# Try single file upload
aws s3 cp "/home/phi/Phi-Intelligence/cnt-web-deployment/media/audio/Adam Eve.mp3" \
    s3://cnt-web-media/audio/ \
    --content-type "audio/mpeg"
```

### Files Not Playing
1. Check content-type header:
```bash
aws s3api head-object --bucket cnt-web-media --key "audio/Adam Eve.mp3" | grep ContentType
```

2. Verify public access:
```bash
curl -I "https://cnt-web-media.s3.eu-west-2.amazonaws.com/audio/Adam%20Eve.mp3"
```

### Database Issues
- Files in S3 but not showing in app = database registration needed
- Use admin interface to "sync from S3" or manually add entries

---

## 📝 Next Steps After Upload

1. **Test on Mobile App:**
   - Open app with admin account
   - Navigate to Podcasts section
   - Search for "Adam Eve" or "Jesus"
   - Test playback

2. **Create Playlists/Categories:**
   - Group audio by series (Moses, Jesus, Paul)
   - Add to curated playlists
   - Feature popular episodes

3. **Add Metadata:**
   - Descriptions for each episode
   - Cover artwork/thumbnails
   - Episode numbers and series info

4. **Promote Content:**
   - Featured content section
   - Push notifications for new uploads
   - Social media announcements

---

## 🎬 Quick Start (TL;DR)

```bash
# 1. Make script executable
chmod +x scripts/refresh_s3_media.sh

# 2. Run the automated upload
./scripts/refresh_s3_media.sh

# 3. When prompted, type 'yes' to confirm

# 4. Wait 10-15 minutes for upload to complete

# 5. Verify uploads
aws s3 ls s3://cnt-web-media/audio/ | head -10
aws s3 ls s3://cnt-web-media/movies/

# 6. Register in database via admin dashboard
# Login: kofi.webb@agilentmaritime.com / christ@agilent

# 7. Test playback on mobile app
```

---

## ✅ Success Criteria

Upload is successful when:
- ✅ 77 audio files uploaded to S3 audio folder
- ✅ 3 movies uploaded to S3 movies folder
- ✅ All files have correct content-type headers
- ✅ Files are publicly accessible
- ✅ Content registered in database
- ✅ Files playable in mobile/web app
- ✅ Search returns new content
- ✅ Old dummy data removed


