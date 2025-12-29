# Admin Dashboard & Admin Panel - Complete Analysis

**Date:** December 13, 2025  
**Credentials:** 
- Username: `kofi.webb@agilentmaritime.com`
- Password: `christ@agilent`

---

## Table of Contents

1. [Overview](#overview)
2. [Main Navigation Structure](#main-navigation-structure)
3. [Dashboard Page](#dashboard-page)
4. [Pending Page](#pending-page)
5. [Approved Page](#approved-page)
6. [Users Page](#users-page)
7. [Support Page](#support-page)
8. [Documents Page](#documents-page)
9. [Key Components & Widgets](#key-components--widgets)
10. [API Endpoints](#api-endpoints)
11. [Backend Routes](#backend-routes)

---

## Overview

The Admin Dashboard is a comprehensive content management system for the CNT Media Platform. It provides:

- **Content Approval Workflow**: Review and approve/reject user-submitted content
- **Content Management**: View, delete, and archive approved content
- **User Management**: View and manage users (view users, change admin status, delete users)
- **Support Ticket Management**: Handle user support messages
- **Document Management**: Upload and manage PDF documents (Bible documents)
- **Dashboard Statistics**: Real-time overview of pending content, approved content, support tickets

### Layout Structure

- **Web Layout**: Side navigation (280px) + Main content area
- **Mobile Layout**: Top app bar + Bottom navigation bar
- **Responsive**: Adapts based on screen size using `ResponsiveUtils`

---

## Main Navigation Structure

**Location:** `web/frontend/lib/screens/admin_dashboard.dart`

### Navigation Items

1. **Dashboard** (Index 0)
   - Icon: `Icons.dashboard_outlined` / `Icons.dashboard`
   - Shows statistics overview

2. **Pending** (Index 1)
   - Icon: `Icons.pending_actions_outlined` / `Icons.pending_actions`
   - Shows all pending content awaiting approval

3. **Approved** (Index 2)
   - Icon: `Icons.check_circle_outline` / `Icons.check_circle`
   - Shows all approved content for management

4. **Users** (Index 3)
   - Icon: `Icons.people_outlined` / `Icons.people`
   - Shows user management interface

### Features

- **Logout Button**: Located in sidebar footer (web) or app bar (mobile)
- **Active State Highlighting**: Active navigation item highlighted with primary color
- **Tab Persistence**: Maintains tab index when switching between pages

---

## Dashboard Page

**Location:** `web/frontend/lib/screens/admin/admin_dashboard_page.dart`  
**API Endpoint:** `GET /api/v1/admin/dashboard`

### Statistics Cards

#### 1. Pending Approvals Section

**Total Pending Card**
- **Value**: Sum of all pending content (podcasts + movies + music + posts)
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Pending page, "All" tab

**Pending Podcasts Card**
- **Value**: Count of podcasts with `status == "pending"`
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Pending page, "Podcasts" tab

**Pending Movies Card**
- **Value**: Count of movies with `status == "pending"`
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Pending page, "Movies" tab

**Pending Posts Card**
- **Value**: Count of community posts with `is_approved == 0`
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Pending page, "Posts" tab

#### 2. Approved Content Section

**All Approved Card**
- **Value**: Sum of all approved content (podcasts + movies + posts)
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Approved page, "All" tab

**Approved Podcasts Card**
- **Value**: Total count of all podcasts (`status == "approved"` or any)
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Approved page, "Podcasts" tab

**Approved Movies Card**
- **Value**: Total count of all movies
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Approved page, "Movies" tab

**Approved Posts Card**
- **Value**: Total count of all community posts
- **Color**: `AppColors.warmBrown`
- **Action**: Navigates to Approved page, "Posts" tab

#### 3. Support & Inbox Section

**Open Support Tickets Card**
- **Value**: Count of support messages with `status == "open"`
- **Color**: `AppColors.primaryMain`
- **Action**: Navigates to Support Page

**New Messages Card**
- **Value**: Count of support messages with `admin_seen == false`
- **Color**: `AppColors.primaryMain`
- **Action**: Navigates to Support Page

#### 4. Documents Section

**Total Documents Card**
- **Value**: Total count of document assets
- **Color**: `AppColors.primaryDark`
- **Action**: Navigates to Documents Page

**Manage Documents Card**
- **Value**: "Upload PDF" (text label)
- **Color**: `AppColors.primaryMain`
- **Action**: Navigates to Documents Page

### Layout

- **Desktop**: Single column layout with all sections stacked vertically
- **Mobile**: Tab-based layout with 3 tabs:
  - Tab 1: Pending stats
  - Tab 2: Approved stats
  - Tab 3: Management (Support + Documents)

### Refresh

- Pull-to-refresh available on all sections
- Refresh button in header (mobile)

---

## Pending Page

**Location:** `web/frontend/lib/screens/admin/admin_pending_page.dart`  
**API Endpoints:** 
- `GET /api/v1/admin/content?content_type=podcast&status=pending`
- `GET /api/v1/admin/content?content_type=movie&status=pending`
- `GET /api/v1/admin/content?content_type=community_post&status=pending`

### Tabs

1. **All** - Shows all pending content combined
2. **Podcasts** - Shows only pending podcasts (with Audio/Video filter)
3. **Movies** - Shows only pending movies
4. **Posts** - Shows only pending community posts

### Podcast Filter (Podcasts Tab Only)

- **All**: Show all podcasts
- **Audio**: Show podcasts without video_url or empty video_url
- **Video**: Show podcasts with non-empty video_url

### Features

#### Header Section
- **Title**: "Pending Approvals"
- **Subtitle**: "Review and approve content submissions"
- **Search Bar**: Search by title or creator name
- **Refresh Button**: Reload all content

#### Content Cards

Each content item displays:
- **Thumbnail**: Cover image, thumbnail_url, or image_url
- **Title**: Content title
- **Creator**: Creator name or username
- **Created Date**: Formatted as "MMM dd, yyyy"
- **Status Badge**: Shows "pending" status
- **Actions**:
  - **Approve Button** (Green pill button with check icon)
  - **Reject Button** (Red outlined pill button with close icon)

#### Actions

**Approve Content**
- Calls `POST /api/v1/admin/approve/{content_type}/{content_id}`
- Updates content status to "approved" (or `is_published = True` for music, `is_approved = 1` for posts)
- Shows success snackbar
- Refreshes content list

**Reject Content**
- Opens dialog to enter optional rejection reason
- Calls `POST /api/v1/admin/reject/{content_type}/{content_id}` with reason
- Updates content status to "rejected" (or deletes for posts)
- Shows warning snackbar
- Refreshes content list

#### Search

- Real-time search filtering
- Searches in title and creator_name fields
- Case-insensitive

#### Empty State

Shows when no pending content:
- Icon: `Icons.check_circle_outline`
- Title: "No pending {contentType}"
- Message: "All {contentType} have been reviewed"

---

## Approved Page

**Location:** `web/frontend/lib/screens/admin/admin_approved_page.dart`  
**API Endpoints:**
- `GET /api/v1/admin/content?content_type=podcast&status=approved`
- `GET /api/v1/admin/content?content_type=movie&status=approved`
- `GET /api/v1/admin/content?content_type=community_post&status=approved`

### Tabs

1. **All** - Shows all approved content combined
2. **Podcasts** - Shows only approved podcasts (with Audio/Video filter)
3. **Movies** - Shows only approved movies
4. **Posts** - Shows only approved community posts

### Podcast Filter (Podcasts Tab Only)

- Same as Pending page (All, Audio, Video)

### Features

#### Header Section
- **Title**: "Approved Content"
- **Subtitle**: "Manage published content - delete or archive"
- **Search Bar**: Search by title or creator name
- **Refresh Button**: Reload all content

#### Content Cards

Each content item displays:
- Same information as Pending page (thumbnail, title, creator, date, status)
- **Status Badge**: Shows "approved" status
- **Actions**:
  - **Archive Button** (Brown pill button with archive icon)
  - **Delete Button** (Red outlined pill button with delete icon)

#### Actions

**Archive Content**
- Shows confirmation dialog
- Calls `POST /api/v1/admin/archive/{content_type}/{content_id}`
- Hides content from users (sets archived flag)
- Shows success snackbar
- Refreshes content list

**Delete Content**
- Shows confirmation dialog with content title
- Warns: "This action cannot be undone"
- Calls `DELETE /api/v1/admin/{content_type}/{content_id}`
- Permanently deletes content
- Shows success snackbar
- Refreshes content list

#### Search

- Same as Pending page (real-time, case-insensitive)

#### Empty State

Shows when no approved content:
- Icon: `Icons.folder_open_outlined`
- Title: "No {contentType}"
- Message: "No approved {contentType} found"

---

## Users Page

**Location:** `web/frontend/lib/screens/admin/admin_users_page.dart`  
**API Endpoints:**
- `GET /api/v1/admin/users` (with search, skip, limit)
- `GET /api/v1/admin/users/{user_id}`
- `PATCH /api/v1/admin/users/{user_id}/admin`
- `DELETE /api/v1/admin/users/{user_id}`

### Current Status

⚠️ **Note**: User management UI is implemented but API integration is incomplete. The page shows:

- Search bar (functional UI)
- Empty state message: "User Management features coming soon. API endpoint needed."

### Planned Features

**User List**
- Display all users with:
  - Avatar
  - Name
  - Email
  - Username
  - Phone
  - Admin status badge
  - Artist profile indicator
  - Created date

**Actions**
- **Toggle Admin Status**: Make user admin or remove admin status
- **Delete User**: Permanently delete user account (with confirmation)
- **View User Details**: View full user profile

**Search**
- Search by name, email, or username
- Real-time filtering

**Pagination**
- Skip/limit support (default: 100 users per page)

### Backend API Available

The backend has full user management endpoints:
- ✅ `GET /admin/users` - List users with search
- ✅ `GET /admin/users/{user_id}` - Get user details
- ✅ `PATCH /admin/users/{user_id}/admin` - Update admin status
- ✅ `DELETE /admin/users/{user_id}` - Delete user

**TODO**: Frontend needs to implement API calls and UI for user list display.

---

## Support Page

**Location:** `web/frontend/lib/screens/admin/admin_support_page.dart`  
**Provider:** `SupportProvider`

### Features

#### Support Message List

- Displays all support messages
- Shows user information, message content, status
- Filter by status (All, Open, Responded, Closed)

#### Message Actions

**Reply to Message**
- Text field for admin reply
- Submit button
- Updates message status to "responded"
- Sends response to user

**Mark as Read**
- Marks message as seen by admin (`admin_seen = true`)
- Updates unread count

**Change Status**
- Open → Responded → Closed
- Status filter updates list

#### Statistics

- Total open tickets
- Unread messages count
- Messages by status

---

## Documents Page

**Location:** `web/frontend/lib/screens/admin/admin_documents_page.dart`  
**Provider:** `DocumentsProvider`

### Features

#### Document List

- Displays all document assets (PDFs)
- Shows title, description, category, file size, upload date
- Click to view/open PDF

#### Upload Document

**Upload Button**
- Opens file picker (PDF only)
- Uploads to backend
- Creates document asset record
- Category: "Bible" (default)
- Featured: true (default)

**Upload Process**
1. Select PDF file
2. Extract filename (without .pdf extension) as title
3. Create description: "Uploaded {timestamp}"
4. Upload via `DocumentsProvider.addDocument()`
5. Show success/error snackbar

#### Document Management

- View documents
- Delete documents (if implemented)
- Filter by category
- Search documents

---

## Key Components & Widgets

### AdminDashboardCard

**Location:** `web/frontend/lib/widgets/admin/admin_dashboard_card.dart`

**Purpose**: Displays statistics card with icon, value, and title

**Props:**
- `title`: String (card label)
- `value`: String (statistic value)
- `icon`: IconData (icon to display)
- `backgroundColor`: Color (card background color)
- `onTap`: VoidCallback? (navigation callback)

**Design:**
- Rounded corners (16px)
- Shadow effect
- Icon in circular white overlay
- Large value text (heading3, bold)
- Smaller title text below

### AdminContentCard

**Location:** `web/frontend/lib/widgets/admin/admin_content_card.dart`

**Purpose**: Displays content item with thumbnail, info, and actions

**Props:**
- `item`: Map<String, dynamic> (content data)
- `onApprove`: VoidCallback? (approve action)
- `onReject`: VoidCallback? (reject action)
- `onDelete`: VoidCallback? (delete action)
- `onArchive`: VoidCallback? (archive action)
- `showApproveReject`: bool (show approve/reject buttons)
- `showDeleteArchive`: bool (show delete/archive buttons)

**Features:**
- **Thumbnail**: 80x80px rounded image (with placeholder emoji if missing)
- **Content Info**:
  - Title (heading4, 2 lines max)
  - Creator name (with person icon)
  - Created date (formatted, with calendar icon)
  - Status badge
- **Actions**: Pill-shaped buttons (filled or outlined)

**Type Icons:**
- Podcast: 🎙️
- Movie: 🎬
- Music: 🎵
- Community Post: 📝

### AdminStatusBadge

**Location:** `web/frontend/lib/widgets/admin/admin_status_badge.dart`

**Purpose**: Displays content status with color coding

**Status Colors:**
- `pending`: Orange/Warning color
- `approved`: Green/Success color
- `rejected`: Red/Error color

---

## API Endpoints

### Frontend API Service

**Location:** `web/frontend/lib/services/api_service.dart`

#### Dashboard

```dart
Future<Map<String, dynamic>> getAdminDashboard()
```
- **Endpoint**: `GET /api/v1/admin/dashboard`
- **Returns**: Dashboard statistics (pending counts, totals, support tickets, documents)

#### Content Management

```dart
Future<List<dynamic>> getAllContent({
  String? contentType,
  String? status,
  int skip = 0,
  int limit = 100,
})
```
- **Endpoint**: `GET /api/v1/admin/content`
- **Query Params**: `content_type`, `status`, `skip`, `limit`
- **Returns**: List of content items

```dart
Future<bool> approveContent(String contentType, int contentId)
```
- **Endpoint**: `POST /api/v1/admin/approve/{content_type}/{content_id}`
- **Returns**: Success boolean

```dart
Future<bool> rejectContent(String contentType, int contentId, {String? reason})
```
- **Endpoint**: `POST /api/v1/admin/reject/{content_type}/{content_id}`
- **Body**: `{ "reason": "optional reason" }`
- **Returns**: Success boolean

```dart
Future<bool> deleteContent(String contentType, int contentId)
```
- **Endpoint**: `DELETE /api/v1/admin/{content_type}/{content_id}`
- **Returns**: Success boolean

```dart
Future<bool> archiveContent(String contentType, int contentId)
```
- **Endpoint**: `POST /api/v1/admin/archive/{content_type}/{content_id}`
- **Returns**: Success boolean

---

## Backend Routes

**Location:** `backend/app/routes/admin.py`

### Dashboard

- `GET /admin/dashboard` - Get dashboard statistics
  - Returns: `DashboardStats` (pending counts, totals, support tickets, documents, recent content)

### Content Management

- `GET /admin/pending` - Get all pending content items
  - Returns: `List[PendingContentItem]`

- `GET /admin/content` - Get all content with filters
  - Query Params: `content_type`, `status`, `skip`, `limit`
  - Returns: List of content items

- `POST /admin/approve/{content_type}/{content_id}` - Approve content
  - Updates status to "approved" (or equivalent)

- `POST /admin/reject/{content_type}/{content_id}` - Reject content
  - Body: `ContentApprovalRequest` (optional reason)
  - Updates status to "rejected" (or deletes for posts)

- `POST /admin/sync-images-to-posts` - Sync images from media/images to community posts
  - Creates community posts from image files

### User Management

- `GET /admin/users` - List all users
  - Query Params: `skip`, `limit`, `search`
  - Returns: `List[UserResponse]`

- `GET /admin/users/{user_id}` - Get user by ID
  - Returns: `UserResponse`

- `PATCH /admin/users/{user_id}/admin` - Update admin status
  - Body: `AdminStatusRequest` (`is_admin: bool`)
  - Prevents self-demotion

- `DELETE /admin/users/{user_id}` - Delete user
  - Prevents self-deletion

### Movie Management

- `POST /admin/movies/{movie_id}/regenerate-thumbnail` - Regenerate thumbnail from video
  - Generates new thumbnail using FFmpeg

- `POST /admin/movies/regenerate-all-thumbnails` - Regenerate all movie thumbnails
  - Query Params: `category_name` (optional filter)
  - Processes all movies or filtered by category

### Authentication

All admin routes require:
- Valid JWT token
- Admin user (`is_admin == true`)
- Middleware: `require_admin` dependency

---

## Content Types

### Podcast

- **Status Field**: `status` (string: "pending", "approved", "rejected")
- **Approve**: Sets `status = "approved"`
- **Reject**: Sets `status = "rejected"`
- **Fields**: title, creator_id, audio_url, video_url, cover_image, status

### Movie

- **Status Field**: `status` (string: "pending", "approved", "rejected")
- **Approve**: Sets `status = "approved"`
- **Reject**: Sets `status = "rejected"`
- **Fields**: title, creator_id, video_url, cover_image, status, category_id

### Music Track

- **Status Field**: `is_published` (boolean)
- **Approve**: Sets `is_published = True`
- **Reject**: Sets `is_published = False`
- **Fields**: title, artist, audio_url, cover_image, is_published

### Community Post

- **Status Field**: `is_approved` (integer: 0 = pending, 1 = approved)
- **Approve**: Sets `is_approved = 1`
- **Reject**: Deletes the post
- **Fields**: title, content, user_id, image_url, is_approved

---

## Database Models

### User

- `id`: int (primary key)
- `name`: str (optional)
- `email`: str (required, unique)
- `username`: str (optional)
- `phone`: str (optional)
- `avatar`: str (optional URL)
- `is_admin`: bool (default: False)
- `created_at`: datetime

### Podcast

- `id`: int
- `title`: str
- `creator_id`: int (FK to User)
- `audio_url`: str (optional)
- `video_url`: str (optional)
- `cover_image`: str (optional)
- `status`: str ("pending", "approved", "rejected")
- `created_at`: datetime

### Movie

- `id`: int
- `title`: str
- `creator_id`: int (FK to User)
- `video_url`: str
- `cover_image`: str (optional)
- `status`: str ("pending", "approved", "rejected")
- `category_id`: int (FK to Category)
- `created_at`: datetime

### MusicTrack

- `id`: int
- `title`: str
- `artist`: str
- `audio_url`: str
- `cover_image`: str (optional)
- `is_published`: bool
- `created_at`: datetime

### CommunityPost

- `id`: int
- `title`: str
- `content`: str
- `user_id`: int (FK to User)
- `image_url`: str (optional)
- `is_approved`: int (0 = False, 1 = True)
- `created_at`: datetime

### SupportMessage

- `id`: int
- `user_id`: int (FK to User)
- `subject`: str
- `message`: str
- `status`: str ("open", "responded", "closed")
- `admin_seen`: bool
- `created_at`: datetime

### DocumentAsset

- `id`: int
- `title`: str
- `description`: str (optional)
- `file_url`: str
- `category`: str
- `is_featured`: bool
- `created_at`: datetime

---

## Color Scheme

### Primary Colors

- `AppColors.primaryMain`: Primary blue/purple
- `AppColors.primaryDark`: Darker primary shade
- `AppColors.warmBrown`: Brown/tan accent color

### Status Colors

- `AppColors.successMain`: Green (approved/success)
- `AppColors.errorMain`: Red (rejected/error)
- `AppColors.warningMain`: Orange (pending/warning)

### Text Colors

- `AppColors.textPrimary`: Main text
- `AppColors.textSecondary`: Secondary text
- `AppColors.textTertiary`: Tertiary text
- `AppColors.textInverse`: White text on colored backgrounds

### Background Colors

- `AppColors.backgroundPrimary`: Main background
- `AppColors.backgroundSecondary`: Secondary background
- `AppColors.cardBackground`: Card background (white)

---

## Summary of Features

### ✅ Implemented

1. **Dashboard Statistics**
   - Pending content counts (podcasts, movies, music, posts)
   - Approved content totals
   - Support ticket statistics
   - Document counts
   - Quick navigation to sections

2. **Content Approval Workflow**
   - View pending content with tabs (All, Podcasts, Movies, Posts)
   - Approve content with one click
   - Reject content with optional reason
   - Search and filter functionality
   - Podcast type filtering (Audio/Video)

3. **Content Management**
   - View approved content
   - Delete content with confirmation
   - Archive content
   - Search and filter
   - Refresh functionality

4. **Support Management**
   - View support messages
   - Reply to messages
   - Mark as read
   - Filter by status

5. **Document Management**
   - Upload PDF documents
   - View document list
   - Category organization

6. **Backend API**
   - Full CRUD operations for content
   - User management endpoints
   - Support message endpoints
   - Document endpoints
   - Dashboard statistics endpoint

### ⚠️ Partially Implemented

1. **User Management**
   - UI structure exists
   - Backend API complete
   - Frontend API integration missing
   - User list display not implemented

### 🔄 Future Enhancements

1. **Content Archive View**: Separate page for archived content
2. **Bulk Actions**: Select multiple items for batch approve/reject/delete
3. **Content Preview**: Preview content before approval
4. **Analytics**: Content performance metrics
5. **User Activity**: View user activity logs
6. **Content Editing**: Edit content metadata from admin panel
7. **Category Management**: Create/edit/delete categories
8. **Bulk Upload**: Upload multiple documents at once

---

## Navigation Flow

```
Admin Dashboard (Index 0)
├── Dashboard Page
│   ├── Pending Stats → Navigate to Pending Page
│   ├── Approved Stats → Navigate to Approved Page
│   ├── Support Stats → Navigate to Support Page
│   └── Documents Stats → Navigate to Documents Page
│
├── Pending Page (Index 1)
│   ├── Tab: All
│   ├── Tab: Podcasts (with Audio/Video filter)
│   ├── Tab: Movies
│   └── Tab: Posts
│
├── Approved Page (Index 2)
│   ├── Tab: All
│   ├── Tab: Podcasts (with Audio/Video filter)
│   ├── Tab: Movies
│   └── Tab: Posts
│
└── Users Page (Index 3)
    └── User Management (UI ready, API integration pending)

Additional Pages (accessed from Dashboard):
├── Support Page
│   └── Support Message Management
│
└── Documents Page
    └── PDF Document Upload & Management
```

---

## Key Files Reference

### Frontend

- Main Dashboard: `web/frontend/lib/screens/admin_dashboard.dart`
- Dashboard Page: `web/frontend/lib/screens/admin/admin_dashboard_page.dart`
- Pending Page: `web/frontend/lib/screens/admin/admin_pending_page.dart`
- Approved Page: `web/frontend/lib/screens/admin/admin_approved_page.dart`
- Users Page: `web/frontend/lib/screens/admin/admin_users_page.dart`
- Support Page: `web/frontend/lib/screens/admin/admin_support_page.dart`
- Documents Page: `web/frontend/lib/screens/admin/admin_documents_page.dart`

### Widgets

- Dashboard Card: `web/frontend/lib/widgets/admin/admin_dashboard_card.dart`
- Content Card: `web/frontend/lib/widgets/admin/admin_content_card.dart`
- Status Badge: `web/frontend/lib/widgets/admin/admin_status_badge.dart`

### Backend

- Admin Routes: `backend/app/routes/admin.py`
- Auth Middleware: `backend/app/middleware/auth_middleware.py`

### Services

- API Service: `web/frontend/lib/services/api_service.dart`

---

**✅ ANALYSIS COMPLETE**

This document provides a comprehensive understanding of all admin dashboard components, features, and functionality. The admin panel is fully functional for content approval and management, with user management UI structure in place awaiting API integration.

