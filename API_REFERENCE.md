# CNT Media Platform - Complete API Reference

**Version:** 3.0  
**Base URL**: `https://api.christnewtabernacle.com/api/v1`  
**Date:** December 5, 2025

---

## Table of Contents

1. [Authentication](#1-authentication)
2. [Users](#2-users)
3. [Artists](#3-artists)
4. [Podcasts](#4-podcasts)
5. [Movies](#5-movies)
6. [Music](#6-music)
7. [Community](#7-community)
8. [Playlists](#8-playlists)
9. [Upload](#9-upload)
10. [Audio Editing](#10-audio-editing)
11. [Video Editing](#11-video-editing)
12. [Live Streaming](#12-live-streaming)
13. [LiveKit Voice](#13-livekit-voice)
14. [Documents](#14-documents)
15. [Donations](#15-donations)
16. [Bank Details](#16-bank-details)
17. [Support](#17-support)
18. [Categories](#18-categories)
19. [Bible Stories](#19-bible-stories)
20. [Notifications](#20-notifications)
21. [Admin](#21-admin)

---

## Authentication

All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer <jwt_token>
```

---

## 1. Authentication

### POST /auth/login
**Description**: Email/password login  
**Auth Required**: No

**Request Body**:
```json
{
  "username_or_email": "user@example.com",
  "password": "password123"
}
```

**Response (200)**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "john_doe",
    "name": "John Doe",
    "email": "user@example.com",
    "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg",
    "is_admin": false
  }
}
```

---

### POST /auth/register
**Description**: User registration  
**Auth Required**: No

**Request Body**:
```json
{
  "name": "John Doe",
  "email": "user@example.com",
  "password": "password123",
  "phone": "+1234567890",
  "date_of_birth": "1990-01-01",
  "bio": "Christian content creator"
}
```

**Response (201)**:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "id": 1,
    "username": "john_doe",
    "name": "John Doe",
    "email": "user@example.com"
  }
}
```

---

### POST /auth/google-login
**Description**: Google OAuth login  
**Auth Required**: No

**Request Body**:
```json
{
  "id_token": "google_id_token_here"
}
```
OR
```json
{
  "access_token": "google_access_token_here"
}
```

**Response (200)**: Same as `/auth/login`

---

### POST /auth/send-otp
**Description**: Send OTP verification code  
**Auth Required**: No

**Request Body**:
```json
{
  "email": "user@example.com"
}
```

**Response (200)**:
```json
{
  "message": "OTP sent successfully",
  "expires_in": 600
}
```

---

### POST /auth/verify-otp
**Description**: Verify OTP code  
**Auth Required**: No

**Request Body**:
```json
{
  "email": "user@example.com",
  "otp_code": "123456"
}
```

**Response (200)**:
```json
{
  "message": "OTP verified successfully",
  "verified": true
}
```

---

### POST /auth/check-username
**Description**: Check username availability  
**Auth Required**: No

**Request Body**:
```json
{
  "username": "john_doe"
}
```

**Response (200)**:
```json
{
  "available": true
}
```

---

### GET /auth/google-client-id
**Description**: Get Google OAuth client ID  
**Auth Required**: No

**Response (200)**:
```json
{
  "client_id": "your_google_client_id.apps.googleusercontent.com"
}
```

---

## 2. Users

### GET /users/me
**Description**: Get current user profile  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_doe",
  "name": "John Doe",
  "email": "user@example.com",
  "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg",
  "phone": "+1234567890",
  "date_of_birth": "1990-01-01",
  "bio": "Christian content creator",
  "is_admin": false,
  "auth_provider": "email",
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### PUT /users/me
**Description**: Update current user profile  
**Auth Required**: Yes

**Request Body**:
```json
{
  "name": "John Doe Updated",
  "phone": "+1234567890",
  "bio": "Updated bio"
}
```

**Response (200)**: Updated user object

---

### GET /users/{id}/public
**Description**: Get public user profile  
**Auth Required**: No

**Response (200)**:
```json
{
  "id": 1,
  "username": "john_doe",
  "name": "John Doe",
  "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg",
  "bio": "Christian content creator",
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

## 3. Artists

### GET /artists/me
**Description**: Get my artist profile  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "id": 1,
  "user_id": 1,
  "artist_name": "John Doe",
  "cover_image": "https://cloudfront.net/images/artists/cover_123.jpg",
  "bio": "Christian music artist",
  "social_links": {
    "instagram": "https://instagram.com/johndoe",
    "twitter": "https://twitter.com/johndoe"
  },
  "followers_count": 150,
  "total_plays": 5000,
  "is_verified": false,
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### PUT /artists/me
**Description**: Update artist profile  
**Auth Required**: Yes

**Request Body**:
```json
{
  "artist_name": "John Doe Music",
  "bio": "Updated bio",
  "social_links": {
    "instagram": "https://instagram.com/johndoe",
    "youtube": "https://youtube.com/@johndoe"
  }
}
```

**Response (200)**: Updated artist object

---

### POST /artists/me/cover-image
**Description**: Upload artist cover image  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
cover_image: <file>
```

**Response (200)**:
```json
{
  "message": "Cover image uploaded successfully",
  "cover_image": "https://cloudfront.net/images/artists/cover_123.jpg"
}
```

---

### GET /artists/{id}
**Description**: Get artist profile  
**Auth Required**: No

**Response (200)**: Artist object (same as `/artists/me`)

---

### GET /artists/{id}/podcasts
**Description**: Get artist's podcasts  
**Auth Required**: No

**Query Parameters**:
- `skip` (int): Offset for pagination (default: 0)
- `limit` (int): Number of items (default: 20)

**Response (200)**:
```json
{
  "podcasts": [
    {
      "id": 1,
      "title": "Podcast Title",
      "description": "Description",
      "audio_url": "https://cloudfront.net/audio/podcast_123.mp3",
      "cover_image": "https://cloudfront.net/images/thumbnails/thumb_123.jpg",
      "duration": 1800,
      "plays_count": 500,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 10
}
```

---

### POST /artists/{id}/follow
**Description**: Follow artist  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Artist followed successfully",
  "followers_count": 151
}
```

---

### DELETE /artists/{id}/follow
**Description**: Unfollow artist  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Artist unfollowed successfully",
  "followers_count": 150
}
```

---

## 4. Podcasts

### GET /podcasts
**Description**: List podcasts  
**Auth Required**: No

**Query Parameters**:
- `skip` (int): Offset (default: 0)
- `limit` (int): Limit (default: 20)
- `category_id` (int): Filter by category
- `creator_id` (int): Filter by creator
- `status` (string): Filter by status (admin only)

**Response (200)**:
```json
{
  "podcasts": [
    {
      "id": 1,
      "title": "Sunday Sermon",
      "description": "Weekly sermon",
      "audio_url": "https://cloudfront.net/audio/podcast_123.mp3",
      "video_url": null,
      "cover_image": "https://cloudfront.net/images/thumbnails/thumb_123.jpg",
      "creator": {
        "id": 1,
        "name": "John Doe",
        "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg"
      },
      "category": {
        "id": 1,
        "name": "Sermons"
      },
      "duration": 1800,
      "status": "approved",
      "plays_count": 500,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 100
}
```

---

### GET /podcasts/{id}
**Description**: Get single podcast  
**Auth Required**: No

**Response (200)**: Podcast object (same structure as list)

---

### POST /podcasts
**Description**: Create podcast  
**Auth Required**: Yes

**Request Body**:
```json
{
  "title": "Sunday Sermon",
  "description": "Weekly sermon",
  "audio_url": "audio/podcast_123.mp3",
  "video_url": null,
  "cover_image": "images/thumbnails/thumb_123.jpg",
  "category_id": 1,
  "duration": 1800
}
```

**Response (201)**:
```json
{
  "id": 1,
  "title": "Sunday Sermon",
  "status": "pending",
  "message": "Podcast created successfully. Awaiting admin approval."
}
```

---

### DELETE /podcasts/{id}
**Description**: Delete podcast  
**Auth Required**: Yes (creator or admin)

**Response (200)**:
```json
{
  "message": "Podcast deleted successfully"
}
```

---

## 5. Movies

### GET /movies
**Description**: List movies  
**Auth Required**: No

**Query Parameters**:
- `skip` (int): Offset
- `limit` (int): Limit
- `category_id` (int): Filter by category

**Response (200)**:
```json
{
  "movies": [
    {
      "id": 1,
      "title": "The Passion",
      "description": "Movie description",
      "video_url": "https://cloudfront.net/video/movie_123.mp4",
      "cover_image": "https://cloudfront.net/images/movies/poster_123.jpg",
      "preview_url": "https://cloudfront.net/video/previews/preview_123.mp4",
      "preview_start_time": 60,
      "preview_end_time": 120,
      "director": "Director Name",
      "cast": "Actor 1, Actor 2",
      "release_date": "2024-01-01",
      "rating": 8.5,
      "duration": 7200,
      "is_featured": true,
      "plays_count": 1000,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 50
}
```

---

### GET /movies/featured
**Description**: Get featured movies  
**Auth Required**: No

**Response (200)**: Array of movie objects

---

### GET /movies/{id}
**Description**: Get movie details  
**Auth Required**: No

**Response (200)**: Movie object

---

### GET /movies/{id}/similar
**Description**: Get similar movies  
**Auth Required**: No

**Response (200)**: Array of movie objects

---

### POST /movies
**Description**: Create movie (admin only)  
**Auth Required**: Yes (admin)

**Request Body**:
```json
{
  "title": "The Passion",
  "description": "Movie description",
  "video_url": "video/movie_123.mp4",
  "cover_image": "images/movies/poster_123.jpg",
  "director": "Director Name",
  "cast": "Actor 1, Actor 2",
  "release_date": "2024-01-01",
  "category_id": 1,
  "duration": 7200,
  "is_featured": true
}
```

**Response (201)**: Movie object

---

## 6. Music

### GET /music
**Description**: List music tracks  
**Auth Required**: No

**Query Parameters**:
- `skip` (int): Offset
- `limit` (int): Limit
- `genre` (string): Filter by genre
- `artist` (string): Filter by artist

**Response (200)**:
```json
{
  "tracks": [
    {
      "id": 1,
      "title": "Amazing Grace",
      "artist": "John Doe",
      "album": "Worship Songs",
      "genre": "Gospel",
      "audio_url": "https://cloudfront.net/audio/music_123.mp3",
      "cover_image": "https://cloudfront.net/images/music/cover_123.jpg",
      "duration": 240,
      "lyrics": "Amazing grace, how sweet the sound...",
      "is_featured": true,
      "is_published": true,
      "plays_count": 2000,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 200
}
```

---

### GET /music/{id}
**Description**: Get music track  
**Auth Required**: No

**Response (200)**: Music track object

---

### POST /music
**Description**: Create music track (admin only)  
**Auth Required**: Yes (admin)

**Request Body**:
```json
{
  "title": "Amazing Grace",
  "artist": "John Doe",
  "album": "Worship Songs",
  "genre": "Gospel",
  "audio_url": "audio/music_123.mp3",
  "cover_image": "images/music/cover_123.jpg",
  "duration": 240,
  "lyrics": "Amazing grace, how sweet the sound...",
  "is_featured": true
}
```

**Response (201)**: Music track object

---

## 7. Community

### GET /community/posts
**Description**: List community posts  
**Auth Required**: No

**Query Parameters**:
- `skip` (int): Offset
- `limit` (int): Limit
- `category` (string): Filter by category
- `user_id` (int): Filter by user

**Response (200)**:
```json
{
  "posts": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "username": "john_doe",
        "name": "John Doe",
        "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg"
      },
      "title": "Testimony",
      "content": "God is good!",
      "image_url": "https://cloudfront.net/images/posts/post_123.jpg",
      "category": "testimony",
      "post_type": "image",
      "likes_count": 50,
      "comments_count": 10,
      "is_liked": false,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 500
}
```

---

### POST /community/posts
**Description**: Create community post  
**Auth Required**: Yes

**Request Body**:
```json
{
  "title": "Testimony",
  "content": "God is good!",
  "image_url": "images/posts/post_123.jpg",
  "category": "testimony",
  "post_type": "image"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "message": "Post created successfully. Awaiting admin approval.",
  "status": "pending"
}
```

---

### POST /community/posts/{id}/like
**Description**: Like/unlike post  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Post liked successfully",
  "likes_count": 51,
  "is_liked": true
}
```

---

### GET /community/posts/{id}/comments
**Description**: Get post comments  
**Auth Required**: No

**Response (200)**:
```json
{
  "comments": [
    {
      "id": 1,
      "user": {
        "id": 2,
        "username": "jane_doe",
        "name": "Jane Doe",
        "avatar": "https://cloudfront.net/images/profiles/profile_456.jpg"
      },
      "content": "Amen!",
      "created_at": "2024-01-01T01:00:00Z"
    }
  ],
  "total": 10
}
```

---

### POST /community/posts/{id}/comments
**Description**: Add comment to post  
**Auth Required**: Yes

**Request Body**:
```json
{
  "content": "Amen!"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "message": "Comment added successfully",
  "comments_count": 11
}
```

---

## 8. Playlists

### GET /playlists
**Description**: List user's playlists  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "playlists": [
    {
      "id": 1,
      "name": "Favorites",
      "description": "My favorite sermons",
      "cover_image": "https://cloudfront.net/images/playlists/playlist_123.jpg",
      "items_count": 15,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 5
}
```

---

### POST /playlists
**Description**: Create playlist  
**Auth Required**: Yes

**Request Body**:
```json
{
  "name": "Favorites",
  "description": "My favorite sermons",
  "cover_image": "images/playlists/playlist_123.jpg"
}
```

**Response (201)**: Playlist object

---

### GET /playlists/{id}
**Description**: Get playlist details  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "id": 1,
  "name": "Favorites",
  "description": "My favorite sermons",
  "cover_image": "https://cloudfront.net/images/playlists/playlist_123.jpg",
  "items": [
    {
      "id": 1,
      "content_type": "podcast",
      "content_id": 1,
      "position": 1,
      "content": {
        "id": 1,
        "title": "Sunday Sermon",
        "cover_image": "https://cloudfront.net/images/thumbnails/thumb_123.jpg"
      }
    }
  ],
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### POST /playlists/{id}/items
**Description**: Add item to playlist  
**Auth Required**: Yes

**Request Body**:
```json
{
  "content_type": "podcast",
  "content_id": 1
}
```

**Response (201)**:
```json
{
  "message": "Item added to playlist successfully"
}
```

---

### DELETE /playlists/{id}/items/{item_id}
**Description**: Remove item from playlist  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Item removed from playlist successfully"
}
```

---

## 9. Upload

### POST /upload/audio
**Description**: Upload audio file  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio: <file>
thumbnail: <file> (optional)
```

**Response (200)**:
```json
{
  "filename": "podcast_123.mp3",
  "url": "https://cloudfront.net/audio/podcast_123.mp3",
  "file_path": "audio/podcast_123.mp3",
  "duration": 1800,
  "thumbnail_url": "https://cloudfront.net/images/thumbnails/thumb_123.jpg"
}
```

---

### POST /upload/video
**Description**: Upload video file  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
generate_thumbnail: true (optional, query param)
```

**Response (200)**:
```json
{
  "filename": "podcast_123.mp4",
  "url": "https://cloudfront.net/video/podcast_123.mp4",
  "file_path": "video/podcast_123.mp4",
  "duration": 1800,
  "thumbnail_url": "https://cloudfront.net/images/thumbnails/generated/thumb_123.jpg"
}
```

---

### POST /upload/image
**Description**: Upload image file  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
image: <file>
```

**Response (200)**:
```json
{
  "filename": "image_123.jpg",
  "url": "https://cloudfront.net/images/image_123.jpg",
  "content_type": "image/jpeg"
}
```

---

### POST /upload/profile-image
**Description**: Upload profile image  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
image: <file>
```

**Response (200)**:
```json
{
  "message": "Profile image uploaded successfully",
  "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg"
}
```

---

### POST /upload/thumbnail
**Description**: Upload custom thumbnail  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
thumbnail: <file>
```

**Response (200)**:
```json
{
  "filename": "thumb_123.jpg",
  "url": "https://cloudfront.net/images/thumbnails/podcasts/custom/thumb_123.jpg"
}
```

---

### GET /upload/thumbnail/defaults
**Description**: Get default thumbnail options  
**Auth Required**: No

**Response (200)**:
```json
{
  "thumbnails": [
    "https://cloudfront.net/images/thumbnails/default/1.jpg",
    "https://cloudfront.net/images/thumbnails/default/2.jpg",
    "https://cloudfront.net/images/thumbnails/default/3.jpg"
  ]
}
```

---

### GET /upload/media/duration
**Description**: Get media file duration  
**Auth Required**: Yes

**Query Parameters**:
- `url` (string): Media file URL

**Response (200)**:
```json
{
  "duration": 1800
}
```

---

## 10. Audio Editing

### POST /audio-editing/trim
**Description**: Trim audio file  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio: <file>
start_time: 10 (seconds)
end_time: 60 (seconds)
```

**Response (200)**:
```json
{
  "filename": "trimmed_123.mp3",
  "url": "https://cloudfront.net/audio/trimmed_123.mp3",
  "file_path": "audio/trimmed_123.mp3",
  "duration": 50
}
```

---

### POST /audio-editing/merge
**Description**: Merge multiple audio files  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio_files: <file[]> (multiple files)
```

**Response (200)**:
```json
{
  "filename": "merged_123.mp3",
  "url": "https://cloudfront.net/audio/merged_123.mp3",
  "file_path": "audio/merged_123.mp3",
  "duration": 3600
}
```

---

### POST /audio-editing/fade-in
**Description**: Apply fade-in effect  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio: <file>
fade_duration: 3 (seconds)
```

**Response (200)**: Same as trim

---

### POST /audio-editing/fade-out
**Description**: Apply fade-out effect  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio: <file>
fade_duration: 3 (seconds)
audio_duration: 180 (seconds)
```

**Response (200)**: Same as trim

---

### POST /audio-editing/fade-in-out
**Description**: Apply fade-in and fade-out effects  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
audio: <file>
fade_in_duration: 3 (seconds)
fade_out_duration: 3 (seconds)
audio_duration: 180 (seconds)
```

**Response (200)**: Same as trim

---

## 11. Video Editing

### POST /video-editing/trim
**Description**: Trim video file  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
start_time: 10 (seconds)
end_time: 60 (seconds)
```

**Response (200)**:
```json
{
  "filename": "trimmed_123.mp4",
  "url": "https://cloudfront.net/video/trimmed_123.mp4",
  "file_path": "video/trimmed_123.mp4",
  "duration": 50
}
```

---

### POST /video-editing/remove-audio
**Description**: Remove audio track from video  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
```

**Response (200)**: Same as trim

---

### POST /video-editing/add-audio
**Description**: Add audio track to video  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
audio: <file>
```

**Response (200)**: Same as trim

---

### POST /video-editing/replace-audio
**Description**: Replace audio track in video  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
audio: <file>
```

**Response (200)**: Same as trim

---

### POST /video-editing/add-text-overlays
**Description**: Add text overlays to video  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
overlays_json: '[{"text": "Welcome", "start_time": 5, "end_time": 10, "x": 0.5, "y": 0.1, "font_size": 48, "color": "#FFFFFF"}]'
```

**Response (200)**: Same as trim

---

### POST /video-editing/apply-filters
**Description**: Apply filters to video  
**Auth Required**: Yes  
**Content-Type**: multipart/form-data

**Request Body**:
```
video: <file>
brightness: 1.2 (optional)
contrast: 1.1 (optional)
saturation: 1.0 (optional)
```

**Response (200)**: Same as trim

---

## 12. Live Streaming

### GET /live/streams
**Description**: List live streams/meetings  
**Auth Required**: No

**Response (200)**:
```json
{
  "streams": [
    {
      "id": 1,
      "user": {
        "id": 1,
        "name": "John Doe",
        "avatar": "https://cloudfront.net/images/profiles/profile_123.jpg"
      },
      "title": "Sunday Service",
      "description": "Live worship service",
      "status": "live",
      "room_name": "room_123",
      "started_at": "2024-01-01T10:00:00Z",
      "ended_at": null
    }
  ],
  "total": 10
}
```

---

### POST /live/streams
**Description**: Create live stream/meeting  
**Auth Required**: Yes

**Request Body**:
```json
{
  "title": "Sunday Service",
  "description": "Live worship service",
  "scheduled_start": "2024-01-01T10:00:00Z"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "room_name": "room_123",
  "message": "Stream created successfully"
}
```

---

### POST /live/streams/{id}/join
**Description**: Join live stream/meeting  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Joined stream successfully"
}
```

---

### POST /live/streams/{id}/livekit-token
**Description**: Get LiveKit token for stream  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "ws_url": "wss://livekit.christnewtabernacle.com",
  "room_name": "room_123"
}
```

---

## 13. LiveKit Voice

### POST /livekit/voice/token
**Description**: Get voice agent token  
**Auth Required**: Yes

**Request Body**:
```json
{
  "room_name": "voice-agent-user123"
}
```

**Response (200)**:
```json
{
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "ws_url": "wss://livekit.christnewtabernacle.com",
  "room_name": "voice-agent-user123"
}
```

---

### POST /livekit/voice/room
**Description**: Create voice agent room  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "room_name": "voice-agent-user123-session456",
  "message": "Voice room created successfully"
}
```

---

### DELETE /livekit/voice/room/{name}
**Description**: Delete voice agent room  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Voice room deleted successfully"
}
```

---

### GET /livekit/voice/rooms
**Description**: List active voice rooms  
**Auth Required**: Yes (admin)

**Response (200)**:
```json
{
  "rooms": [
    {
      "name": "voice-agent-user123",
      "num_participants": 2,
      "creation_time": 1704067200
    }
  ]
}
```

---

### GET /livekit/voice/health
**Description**: Voice agent health check  
**Auth Required**: No

**Response (200)**:
```json
{
  "status": "healthy",
  "agent_running": true
}
```

---

## 14. Documents

### GET /documents
**Description**: List documents  
**Auth Required**: No

**Response (200)**:
```json
{
  "documents": [
    {
      "id": 1,
      "title": "Holy Bible (KJV)",
      "file_url": "https://cloudfront.net/documents/holy_bible_kjv.pdf",
      "file_type": "pdf",
      "file_size": 5242880,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 5
}
```

---

### GET /documents/{id}
**Description**: Get document details  
**Auth Required**: No

**Response (200)**: Document object

---

### POST /documents
**Description**: Upload document (admin only)  
**Auth Required**: Yes (admin)  
**Content-Type**: multipart/form-data

**Request Body**:
```
document: <file>
title: "Document Title"
```

**Response (201)**:
```json
{
  "id": 1,
  "message": "Document uploaded successfully"
}
```

---

## 15. Donations

### POST /donations
**Description**: Process donation  
**Auth Required**: Yes

**Request Body**:
```json
{
  "recipient_id": 1,
  "amount": 50.00,
  "currency": "USD",
  "payment_method": "stripe",
  "payment_token": "tok_123"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "status": "completed",
  "message": "Donation processed successfully"
}
```

---

### GET /donations/history
**Description**: Get donation history  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "donations": [
    {
      "id": 1,
      "recipient": {
        "id": 1,
        "name": "John Doe"
      },
      "amount": 50.00,
      "currency": "USD",
      "status": "completed",
      "payment_method": "stripe",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 10
}
```

---

## 16. Bank Details

### GET /bank-details/me
**Description**: Get my bank details  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "id": 1,
  "account_number": "****1234",
  "bank_name": "Bank Name",
  "account_holder_name": "John Doe",
  "is_verified": false,
  "created_at": "2024-01-01T00:00:00Z"
}
```

---

### POST /bank-details
**Description**: Add bank details  
**Auth Required**: Yes

**Request Body**:
```json
{
  "account_number": "1234567890",
  "ifsc_code": "ABCD0123456",
  "bank_name": "Bank Name",
  "account_holder_name": "John Doe",
  "branch_name": "Main Branch"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "message": "Bank details added successfully"
}
```

---

### PUT /bank-details/{id}
**Description**: Update bank details  
**Auth Required**: Yes

**Request Body**: Same as POST

**Response (200)**:
```json
{
  "message": "Bank details updated successfully"
}
```

---

## 17. Support

### GET /support/messages
**Description**: List support messages  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "messages": [
    {
      "id": 1,
      "subject": "Technical Issue",
      "message": "I'm having trouble uploading videos",
      "status": "pending",
      "admin_response": null,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 5
}
```

---

### POST /support/messages
**Description**: Create support message  
**Auth Required**: Yes

**Request Body**:
```json
{
  "subject": "Technical Issue",
  "message": "I'm having trouble uploading videos"
}
```

**Response (201)**:
```json
{
  "id": 1,
  "message": "Support message sent successfully"
}
```

---

### GET /support/messages/{id}
**Description**: Get support message  
**Auth Required**: Yes

**Response (200)**: Support message object

---

## 18. Categories

### GET /categories
**Description**: List categories  
**Auth Required**: No

**Query Parameters**:
- `type` (string): Filter by type (podcast, music, community)

**Response (200)**:
```json
{
  "categories": [
    {
      "id": 1,
      "name": "Sermons",
      "type": "podcast"
    },
    {
      "id": 2,
      "name": "Gospel",
      "type": "music"
    }
  ],
  "total": 10
}
```

---

## 19. Bible Stories

### GET /bible-stories
**Description**: List Bible stories  
**Auth Required**: No

**Response (200)**:
```json
{
  "stories": [
    {
      "id": 1,
      "title": "David and Goliath",
      "scripture_reference": "1 Samuel 17",
      "content": "Story content...",
      "audio_url": "https://cloudfront.net/audio/story_123.mp3",
      "cover_image": "https://cloudfront.net/images/stories/story_123.jpg",
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 50
}
```

---

### GET /bible-stories/{id}
**Description**: Get Bible story  
**Auth Required**: No

**Response (200)**: Bible story object

---

## 20. Notifications

### GET /notifications
**Description**: List notifications  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "notifications": [
    {
      "id": 1,
      "type": "like",
      "title": "New Like",
      "message": "John Doe liked your post",
      "data": {
        "post_id": 1
      },
      "is_read": false,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 20
}
```

---

### PUT /notifications/{id}/read
**Description**: Mark notification as read  
**Auth Required**: Yes

**Response (200)**:
```json
{
  "message": "Notification marked as read"
}
```

---

## 21. Admin

### GET /admin/dashboard
**Description**: Get admin dashboard statistics  
**Auth Required**: Yes (admin)

**Response (200)**:
```json
{
  "total_users": 1000,
  "total_podcasts": 500,
  "total_posts": 2000,
  "pending_podcasts": 10,
  "pending_posts": 5,
  "total_donations": 50000.00
}
```

---

### GET /admin/pending
**Description**: Get pending content  
**Auth Required**: Yes (admin)

**Query Parameters**:
- `type` (string): Content type (podcast, post)

**Response (200)**:
```json
{
  "content": [
    {
      "id": 1,
      "type": "podcast",
      "title": "Sunday Sermon",
      "creator": {
        "id": 1,
        "name": "John Doe"
      },
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 15
}
```

---

### POST /admin/approve/{type}/{id}
**Description**: Approve content  
**Auth Required**: Yes (admin)

**Path Parameters**:
- `type`: Content type (podcast, post, movie)
- `id`: Content ID

**Response (200)**:
```json
{
  "message": "Content approved successfully"
}
```

---

### POST /admin/reject/{type}/{id}
**Description**: Reject content  
**Auth Required**: Yes (admin)

**Path Parameters**:
- `type`: Content type (podcast, post, movie)
- `id`: Content ID

**Request Body**:
```json
{
  "reason": "Does not meet content guidelines"
}
```

**Response (200)**:
```json
{
  "message": "Content rejected successfully"
}
```

---

### GET /admin/users
**Description**: List all users  
**Auth Required**: Yes (admin)

**Response (200)**:
```json
{
  "users": [
    {
      "id": 1,
      "username": "john_doe",
      "name": "John Doe",
      "email": "user@example.com",
      "is_admin": false,
      "created_at": "2024-01-01T00:00:00Z"
    }
  ],
  "total": 1000
}
```

---

**Document Status**: Complete API reference for CNT Media Platform (100+ endpoints)
