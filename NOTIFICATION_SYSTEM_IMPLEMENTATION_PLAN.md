# Notification System Implementation Plan - Detailed Code Changes

## Overview
This plan provides detailed code changes to implement a complete notification system for the CNT Media Platform web application. The system will notify users when:
1. Admin approves their content (podcasts, videos, movies, posts, events)
2. Admin starts a live stream (all users notified)

---

## Phase 1: Backend - Admin Approval Notifications

### File: `backend/app/routes/admin.py`

**Location**: After line 19, add imports:
```python
from app.services.notification_service import NotificationService
from app.models.notification import NotificationType
```

**Location**: Replace `approve_content` function (lines 299-342) with:

```python
@router.post("/approve/{content_type}/{content_id}")
async def approve_content(
    content_type: str,
    content_id: int,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    """Approve a content item and notify the creator"""
    notification_service = NotificationService(db)
    creator_id = None
    content_title = None
    content_type_display = content_type.replace('_', ' ').title()
    
    if content_type == "podcast":
        result = await db.execute(select(Podcast).where(Podcast.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Podcast not found")
        item.status = "approved"
        creator_id = item.creator_id
        content_title = item.title
    elif content_type == "movie":
        result = await db.execute(select(Movie).where(Movie.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Movie not found")
        item.status = "approved"
        creator_id = item.creator_id
        content_title = item.title
    elif content_type == "music":
        result = await db.execute(select(MusicTrack).where(MusicTrack.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Music track not found")
        item.is_published = True
        # Music tracks don't have creator_id, skip notification for now
        # If you add creator_id to MusicTrack model later, uncomment:
        # creator_id = item.creator_id
        # content_title = item.title
    elif content_type == "community_post":
        result = await db.execute(select(CommunityPost).where(CommunityPost.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Community post not found")
        item.is_approved = 1  # SQLite uses 1 for True
        creator_id = item.user_id
        content_title = item.title
    elif content_type == "event":
        result = await db.execute(select(Event).where(Event.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Event not found")
        item.status = "approved"
        creator_id = item.host_id
        content_title = item.title
    else:
        raise HTTPException(status_code=400, detail=f"Invalid content type: {content_type}")
    
    await db.commit()
    
    # Create notification for creator if they exist
    if creator_id and content_title:
        try:
            await notification_service.create_notification(
                user_id=creator_id,
                title="✅ Content Approved",
                message=f"Your {content_type_display} '{content_title}' has been approved and is now visible to all users.",
                event_type=NotificationType.CONTENT_APPROVED,
                metadata={
                    "content_type": content_type,
                    "content_id": content_id,
                    "content_title": content_title
                },
                send_push=False  # Web app doesn't need push, only in-app
            )
        except Exception as e:
            # Log error but don't fail the approval
            print(f"⚠️ Failed to send approval notification: {e}")
    
    return {"message": f"{content_type} approved successfully", "id": content_id}
```

**Location**: Replace `reject_content` function (lines 345-393) with:

```python
@router.post("/reject/{content_type}/{content_id}")
async def reject_content(
    content_type: str,
    content_id: int,
    request: ContentApprovalRequest,
    current_user: User = Depends(require_admin),
    db: AsyncSession = Depends(get_db)
):
    """Reject a content item with optional reason and notify the creator"""
    notification_service = NotificationService(db)
    creator_id = None
    content_title = None
    content_type_display = content_type.replace('_', ' ').title()
    
    if content_type == "podcast":
        result = await db.execute(select(Podcast).where(Podcast.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Podcast not found")
        item.status = "rejected"
        creator_id = item.creator_id
        content_title = item.title
    elif content_type == "movie":
        result = await db.execute(select(Movie).where(Movie.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Movie not found")
        item.status = "rejected"
        creator_id = item.creator_id
        content_title = item.title
    elif content_type == "music":
        result = await db.execute(select(MusicTrack).where(MusicTrack.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Music track not found")
        item.is_published = False
        # Music tracks don't have creator_id, skip notification
    elif content_type == "community_post":
        result = await db.execute(select(CommunityPost).where(CommunityPost.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Community post not found")
        creator_id = item.user_id
        content_title = item.title
        await db.delete(item)
        await db.commit()
        
        # Send notification before returning
        if creator_id and content_title:
            try:
                reason_text = f" Reason: {request.reason}" if request.reason else ""
                await notification_service.create_notification(
                    user_id=creator_id,
                    title="❌ Post Removed",
                    message=f"Your community post '{content_title}' has been removed.{reason_text}",
                    event_type=NotificationType.CONTENT_REJECTED,
                    metadata={
                        "content_type": content_type,
                        "content_id": content_id,
                        "content_title": content_title,
                        "reason": request.reason
                    },
                    send_push=False
                )
            except Exception as e:
                print(f"⚠️ Failed to send rejection notification: {e}")
        
        return {"message": "Community post deleted", "id": content_id, "reason": request.reason}
    elif content_type == "event":
        result = await db.execute(select(Event).where(Event.id == content_id))
        item = result.scalar_one_or_none()
        if not item:
            raise HTTPException(status_code=404, detail="Event not found")
        item.status = "rejected"
        creator_id = item.host_id
        content_title = item.title
    else:
        raise HTTPException(status_code=400, detail=f"Invalid content type: {content_type}")
    
    await db.commit()
    
    # Create notification for creator if they exist
    if creator_id and content_title:
        try:
            reason_text = f" Reason: {request.reason}" if request.reason else ""
            await notification_service.create_notification(
                user_id=creator_id,
                title="❌ Content Rejected",
                message=f"Your {content_type_display} '{content_title}' has been rejected.{reason_text}",
                event_type=NotificationType.CONTENT_REJECTED,
                metadata={
                    "content_type": content_type,
                    "content_id": content_id,
                    "content_title": content_title,
                    "reason": request.reason
                },
                send_push=False
            )
        except Exception as e:
            print(f"⚠️ Failed to send rejection notification: {e}")
    
    return {"message": f"{content_type} rejected", "id": content_id, "reason": request.reason}
```

---

## Phase 2: Backend - WebSocket Notification Events

### File: `backend/app/websocket/socket_io_handler.py`

**Location**: Add after line 158 (after `emit_live_stream_ended` function):

```python
async def emit_new_notification(user_id: int, notification_data: dict):
    """Emit notification to a specific user when a new notification is created"""
    sio = get_sio()
    if sio:
        # Emit to a user-specific room
        # Note: Frontend needs to join user room on connect
        user_room = f"user_{user_id}"
        await sio.emit(
            'new_notification',
            notification_data,
            room=user_room
        )
        # Also emit to all connections (frontend will filter by user_id)
        await sio.emit(
            'new_notification',
            notification_data,
            skip_sid=None
        )
```

**Location**: Update `connect` handler (around line 26-30) to join user room:

```python
@self.sio.on('connect')
async def connect(sid: str, environ: dict, auth: dict):
    """Client connected"""
    print(f"Client connected: {sid}")
    await self.sio.emit('welcome', {'message': 'Connected to CNT Media Platform'}, room=sid)
    
    # If user_id is provided in auth, join user-specific room
    user_id = auth.get('user_id') if auth else None
    if user_id:
        user_room = f"user_{user_id}"
        await self.sio.enter_room(sid, user_room)
        print(f"User {user_id} joined room {user_room}")
```

### File: `backend/app/services/notification_service.py`

**Location**: Update `create_notification` method (after line 44, before push notification):

```python
        await self.db.commit()
        await self.db.refresh(notification)
        
        # Emit WebSocket notification for real-time updates
        try:
            from app.websocket.socket_io_handler import emit_new_notification
            notification_data = {
                "id": notification.id,
                "type": notification.type,
                "title": notification.title,
                "message": notification.message,
                "data": notification.data,
                "read": notification.read,
                "created_at": notification.created_at.isoformat() if notification.created_at else None
            }
            await emit_new_notification(user_id, notification_data)
        except Exception as e:
            logger.warning(f"Failed to emit WebSocket notification: {e}")
        
        # Send push notification
        if send_push:
```

**Location**: Update `notify_all_users` method (after line 95, before push notification):

```python
        await self.db.commit()
        
        # Emit WebSocket notifications for real-time updates
        try:
            from app.websocket.socket_io_handler import emit_new_notification
            for notification in notifications:
                notification_data = {
                    "id": notification.id,
                    "type": notification.type,
                    "title": notification.title,
                    "message": notification.message,
                    "data": notification.data,
                    "read": notification.read,
                    "created_at": notification.created_at.isoformat() if notification.created_at else None
                }
                await emit_new_notification(notification.user_id, notification_data)
        except Exception as e:
            logger.warning(f"Failed to emit WebSocket notifications: {e}")
        
        # Send push notification to all users
```

**Location**: Update `notify_users` method (after line 138, before push notification):

```python
        await self.db.commit()
        
        # Emit WebSocket notifications for real-time updates
        try:
            from app.websocket.socket_io_handler import emit_new_notification
            for notification in notifications:
                notification_data = {
                    "id": notification.id,
                    "type": notification.type,
                    "title": notification.title,
                    "message": notification.message,
                    "data": notification.data,
                    "read": notification.read,
                    "created_at": notification.created_at.isoformat() if notification.created_at else None
                }
                await emit_new_notification(notification.user_id, notification_data)
        except Exception as e:
            logger.warning(f"Failed to emit WebSocket notifications: {e}")
        
        # Send push notifications to specified users
```

---

## Phase 3: Frontend - API Service Integration

### File: `web/frontend/lib/services/api_service.dart`

**Location**: Add at the end of the class (before the closing brace, around line 4513):

```dart
  // ============================================
  // NOTIFICATIONS API
  // ============================================

  /// Get notifications for the current user
  Future<Map<String, dynamic>> getNotifications({
    int limit = 20,
    int offset = 0,
    bool unreadOnly = false,
  }) async {
    _validateBaseUrl();
    try {
      final queryParams = <String, String>{
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (unreadOnly) 'unread_only': 'true',
      };
      
      final uri = Uri.parse('$baseUrl/notifications').replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Token expired, try refresh
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http
              .get(uri, headers: await _getHeaders())
              .timeout(const Duration(seconds: 10));
          if (retryResponse.statusCode == 200) {
            return json.decode(retryResponse.body) as Map<String, dynamic>;
          }
        }
        throw Exception('Authentication failed. Please log in again.');
      }
      throw Exception('Failed to fetch notifications: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadNotificationCount() async {
    _validateBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/notifications/unread-count');
      final response = await http
          .get(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['unread_count'] as int? ?? 0;
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http
              .get(uri, headers: await _getHeaders())
              .timeout(const Duration(seconds: 10));
          if (retryResponse.statusCode == 200) {
            final data = json.decode(retryResponse.body) as Map<String, dynamic>;
            return data['unread_count'] as int? ?? 0;
          }
        }
        return 0;
      }
      return 0;
    } catch (e) {
      LoggerService.e('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Mark notifications as read
  Future<bool> markNotificationsAsRead(List<int> notificationIds) async {
    _validateBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/notifications/read');
      final response = await http
          .post(
            uri,
            headers: await _getHeaders(),
            body: json.encode({'notification_ids': notificationIds}),
          )
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http
              .post(
                uri,
                headers: await _getHeaders(),
                body: json.encode({'notification_ids': notificationIds}),
              )
              .timeout(const Duration(seconds: 10));
          return retryResponse.statusCode == 200;
        }
        return false;
      }
      return false;
    } catch (e) {
      LoggerService.e('Error marking notifications as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read
  Future<bool> markAllNotificationsAsRead() async {
    _validateBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/notifications/read-all');
      final response = await http
          .post(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        final refreshed = await _authService.refreshAccessToken();
        if (refreshed) {
          final retryResponse = await http
              .post(uri, headers: await _getHeaders())
              .timeout(const Duration(seconds: 10));
          return retryResponse.statusCode == 200;
        }
        return false;
      }
      return false;
    } catch (e) {
      LoggerService.e('Error marking all notifications as read: $e');
      return false;
    }
  }

  /// Delete a notification
  Future<bool> deleteNotification(int notificationId) async {
    _validateBaseUrl();
    try {
      final uri = Uri.parse('$baseUrl/notifications/$notificationId');
      final response = await http
          .delete(uri, headers: await _getHeaders())
          .timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      LoggerService.e('Error deleting notification: $e');
      return false;
    }
  }
}
```

---

## Phase 4: Frontend - Notification Provider Enhancement

### File: `web/frontend/lib/providers/notification_provider.dart`

**Replace entire file with:**

```dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

class Notification {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      data: json['data'] as Map<String, dynamic>?,
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class LiveStreamNotification {
  final int streamId;
  final String hostName;
  final String streamTitle;
  final String roomName;
  final DateTime timestamp;

  LiveStreamNotification({
    required this.streamId,
    required this.hostName,
    required this.streamTitle,
    required this.roomName,
    required this.timestamp,
  });
}

class NotificationProvider extends ChangeNotifier {
  final WebSocketService _wsService = WebSocketService();
  final ApiService _apiService = ApiService();
  
  StreamSubscription<Map<String, dynamic>>? _liveStreamSubscription;
  StreamSubscription<Map<String, dynamic>>? _newNotificationSubscription;
  
  List<Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  LiveStreamNotification? _currentLiveStreamNotification;
  bool _isDismissed = false;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  LiveStreamNotification? get currentLiveStreamNotification => _currentLiveStreamNotification;
  bool get hasLiveStreamNotification => _currentLiveStreamNotification != null && !_isDismissed;

  NotificationProvider() {
    _setupListeners();
    fetchNotifications();
    fetchUnreadCount();
  }

  void _setupListeners() {
    // Listen for live stream notifications
    _liveStreamSubscription = _wsService.liveStreamStarted.listen((data) {
      _currentLiveStreamNotification = LiveStreamNotification(
        streamId: data['stream_id'] as int? ?? 0,
        hostName: data['host_name'] as String? ?? 'Unknown',
        streamTitle: data['stream_title'] as String? ?? 'Live Stream',
        roomName: data['room_name'] as String? ?? '',
        timestamp: DateTime.now(),
      );
      _isDismissed = false;
      notifyListeners();
    });

    // Listen for new notification events
    _newNotificationSubscription = _wsService.newNotification.listen((data) {
      try {
        final notification = Notification.fromJson(data);
        _notifications.insert(0, notification);
        if (!notification.read) {
          _unreadCount++;
        }
        notifyListeners();
        LoggerService.i('📬 New notification received: ${notification.title}');
      } catch (e) {
        LoggerService.e('Error parsing notification: $e');
      }
    });
  }

  Future<void> fetchNotifications({bool unreadOnly = false, bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.getNotifications(
        limit: 50,
        offset: refresh ? 0 : _notifications.length,
        unreadOnly: unreadOnly,
      );

      final notificationsList = (response['notifications'] as List<dynamic>?)
          ?.map((json) => Notification.fromJson(json as Map<String, dynamic>))
          .toList() ?? [];

      if (refresh) {
        _notifications = notificationsList;
      } else {
        _notifications.addAll(notificationsList);
      }

      _unreadCount = response['unread_count'] as int? ?? 0;
      _error = null;
    } catch (e) {
      _error = 'Failed to load notifications: $e';
      LoggerService.e('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchUnreadCount() async {
    try {
      _unreadCount = await _apiService.getUnreadNotificationCount();
      notifyListeners();
    } catch (e) {
      LoggerService.e('Error fetching unread count: $e');
    }
  }

  Future<void> markAsRead(List<int> notificationIds) async {
    try {
      final success = await _apiService.markNotificationsAsRead(notificationIds);
      if (success) {
        // Update local state
        for (final id in notificationIds) {
          final index = _notifications.indexWhere((n) => n.id == id);
          if (index != -1) {
            _notifications[index] = Notification(
              id: _notifications[index].id,
              type: _notifications[index].type,
              title: _notifications[index].title,
              message: _notifications[index].message,
              data: _notifications[index].data,
              read: true,
              createdAt: _notifications[index].createdAt,
            );
            if (_unreadCount > 0) {
              _unreadCount--;
            }
          }
        }
        notifyListeners();
      }
    } catch (e) {
      LoggerService.e('Error marking notifications as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final success = await _apiService.markAllNotificationsAsRead();
      if (success) {
        // Update local state
        _notifications = _notifications.map((n) => Notification(
          id: n.id,
          type: n.type,
          title: n.title,
          message: n.message,
          data: n.data,
          read: true,
          createdAt: n.createdAt,
        )).toList();
        _unreadCount = 0;
        notifyListeners();
      }
    } catch (e) {
      LoggerService.e('Error marking all as read: $e');
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final success = await _apiService.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n.id == notificationId);
        // Update unread count if it was unread
        final wasUnread = _notifications.any((n) => n.id == notificationId && !n.read);
        if (wasUnread && _unreadCount > 0) {
          _unreadCount--;
        }
        notifyListeners();
      }
    } catch (e) {
      LoggerService.e('Error deleting notification: $e');
    }
  }

  void dismissLiveStreamNotification() {
    _isDismissed = true;
    notifyListeners();
  }

  void clearLiveStreamNotification() {
    _currentLiveStreamNotification = null;
    _isDismissed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveStreamSubscription?.cancel();
    _newNotificationSubscription?.cancel();
    super.dispose();
  }
}
```

---

## Phase 5: Frontend - WebSocket Service Enhancement

### File: `web/frontend/lib/services/websocket_service.dart`

**Location**: Add after line 16 (after `_speakPermissionRequestedController`):

```dart
  final _newNotificationController = StreamController<Map<String, dynamic>>.broadcast();
```

**Location**: Add after line 24 (after `speakPermissionRequested` getter):

```dart
  Stream<Map<String, dynamic>> get newNotification => _newNotificationController.stream;
```

**Location**: Add after line 145 (after `speak_permission_requested` handler):

```dart
      _socket!.on('new_notification', (data) {
        try {
          if (data is Map<String, dynamic>) {
            _newNotificationController.add(data);
            LoggerService.i('📬 New notification received via WebSocket: $data');
          }
        } catch (e) {
          LoggerService.e('Error handling new_notification: $e');
        }
      });
```

**Location**: Update `disconnect` method (line 170-177) to close the new controller:

```dart
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
    _socket = null;
    _liveStreamStartedController.close();
    _speakPermissionRequestedController.close();
    _newNotificationController.close();
  }
```

---

## Phase 6: Frontend - Notifications Screen Implementation

### File: `web/frontend/lib/screens/web/notifications_screen_web.dart`

**Replace entire file with:**

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../providers/notification_provider.dart';
import '../../services/logger_service.dart';

/// Web Notifications Screen
class NotificationsScreenWeb extends StatefulWidget {
  const NotificationsScreenWeb({super.key});

  @override
  State<NotificationsScreenWeb> createState() => _NotificationsScreenWebState();
}

class _NotificationsScreenWebState extends State<NotificationsScreenWeb> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Read'];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    provider.fetchNotifications(refresh: true);
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;
    
    final provider = context.read<NotificationProvider>();
    final unreadOnly = _filter == 'Unread';
    await provider.fetchNotifications(unreadOnly: unreadOnly);
    
    _isLoadingMore = false;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: _filters.map((filter) {
                    final isSelected = filter == _filter;
                    return Padding(
                      padding: EdgeInsets.only(left: AppSpacing.small),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _filter = filter);
                          final provider = context.read<NotificationProvider>();
                          provider.fetchNotifications(
                            unreadOnly: filter == 'Unread',
                            refresh: true,
                          );
                        },
                        selectedColor: AppColors.primaryMain,
                        backgroundColor: AppColors.cardBackground,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected ? AppColors.primaryMain : AppColors.borderPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Notifications List
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.medium),
                          child: const LoadingShimmer(width: double.infinity, height: 80),
                        );
                      },
                    );
                  }

                  if (provider.error != null && provider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading notifications',
                            style: AppTypography.body.copyWith(
                              color: AppColors.errorMain,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          ElevatedButton(
                            onPressed: () {
                              provider.fetchNotifications(refresh: true);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  List<dynamic> filteredNotifications = provider.notifications;
                  if (_filter == 'Unread') {
                    filteredNotifications = provider.notifications.where((n) => !n.read).toList();
                  } else if (_filter == 'Read') {
                    filteredNotifications = provider.notifications.where((n) => n.read).toList();
                  }

                  if (filteredNotifications.isEmpty) {
                    return const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No Notifications',
                      message: 'You\'re all caught up!',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.fetchNotifications(
                        unreadOnly: _filter == 'Unread',
                        refresh: true,
                      );
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredNotifications.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredNotifications.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.medium),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final notification = filteredNotifications[index];
                        return Card(
                          color: notification.read
                              ? AppColors.cardBackground
                              : AppColors.cardBackground.withOpacity(0.8),
                          elevation: notification.read ? 1 : 3,
                          margin: EdgeInsets.only(bottom: AppSpacing.small),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: notification.read
                                ? BorderSide.none
                                : BorderSide(
                                    color: AppColors.primaryMain.withOpacity(0.3),
                                    width: 2,
                                  ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryMain.withOpacity(0.1),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: AppColors.primaryMain,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: notification.read
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatUtils.formatRelativeTime(notification.createdAt),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification.read
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMain,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              _handleNotificationTap(notification);
                            },
                            onLongPress: () {
                              _showNotificationOptions(context, notification, provider);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'content_approved':
        return Icons.check_circle;
      case 'content_rejected':
        return Icons.cancel;
      case 'live_stream':
        return Icons.live_tv;
      case 'donation_received':
      case 'donation_sent':
        return Icons.payments;
      case 'new_follower':
        return Icons.person_add;
      case 'new_comment':
        return Icons.comment;
      case 'new_like':
        return Icons.favorite;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(dynamic notification) {
    // Mark as read if unread
    if (!notification.read) {
      context.read<NotificationProvider>().markAsRead([notification.id]);
    }

    // Navigate based on notification type and data
    final data = notification.data;
    if (data != null) {
      final contentType = data['content_type'] as String?;
      final contentId = data['content_id'];

      if (contentType != null && contentId != null) {
        switch (contentType) {
          case 'podcast':
            context.push('/podcast/$contentId');
            break;
          case 'movie':
            context.push('/movie/$contentId');
            break;
          case 'community_post':
            // Navigate to community screen
            context.push('/community');
            break;
          case 'event':
            context.push('/events/$contentId');
            break;
        }
      } else if (notification.type == 'live_stream') {
        final streamId = data['stream_id'];
        if (streamId != null) {
          context.push('/live-streams');
        }
      }
    }
  }

  void _showNotificationOptions(
    BuildContext context,
    dynamic notification,
    NotificationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.read)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  provider.markAsRead([notification.id]);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.errorMain),
              title: const Text('Delete', style: TextStyle(color: AppColors.errorMain)),
              onTap: () {
                provider.deleteNotification(notification.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Phase 7: Frontend - Profile Screen Integration

### File: `web/frontend/lib/screens/web/profile_screen_web.dart`

**Location**: Add import at the top (after line 24):

```dart
import '../web/notifications_screen_web.dart';
import '../providers/notification_provider.dart';
```

**Location**: In `_buildSettingsSection` method, add after "My Drafts" item (around line 1176):

```dart
          _buildDivider(),
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              return _buildSettingItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'View your notifications',
                badge: notificationProvider.unreadCount > 0
                    ? '${notificationProvider.unreadCount > 99 ? '99+' : notificationProvider.unreadCount}'
                    : null,
                onTap: () {
                  context.push('/notifications');
                },
              );
            },
          ),
          _buildDivider(),
```

**Location**: In `initState` method (around line 40), add:

```dart
      context.read<NotificationProvider>().fetchUnreadCount();
```

---

## Phase 8: Frontend - Routing

### File: `web/frontend/lib/navigation/app_router.dart`

**Location**: Add import at the top (after line 30):

```dart
import '../screens/web/notifications_screen_web.dart';
```

**Location**: Add route after profile route (find profile route and add after it, around line 150-200):

```dart
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _buildPageWithoutTransition(
          context,
          state,
          const WebNavigationLayout(child: NotificationsScreenWeb()),
        ),
      ),
```

---

## Phase 9: Frontend - App Router Provider Registration

### File: `web/frontend/lib/navigation/app_router.dart`

**Location**: In `_AppRouterState` build method, ensure `NotificationProvider` is in the MultiProvider list (around line 79-95). It should already be there, but verify:

```dart
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
```

---

## Phase 10: Testing Checklist

1. **Admin Approval Notifications**:
   - [ ] Admin approves podcast → Creator receives notification
   - [ ] Admin approves movie → Creator receives notification
   - [ ] Admin approves community post → Creator receives notification
   - [ ] Admin approves event → Creator receives notification
   - [ ] Notification appears in real-time via WebSocket
   - [ ] Notification appears in notifications screen

2. **Live Stream Notifications**:
   - [ ] Admin starts live stream → All users receive notification
   - [ ] Notification appears in real-time via WebSocket
   - [ ] Notification appears in notifications screen

3. **Frontend Functionality**:
   - [ ] Notifications screen displays all notifications
   - [ ] Filter by All/Unread/Read works
   - [ ] Unread count badge shows in profile
   - [ ] Mark as read works
   - [ ] Mark all as read works
   - [ ] Delete notification works
   - [ ] Real-time updates via WebSocket
   - [ ] Navigation to content from notification works

---

## Deployment Steps

### Backend (EC2):
```bash
# 1. SSH to EC2
ssh -i christnew.pem ubuntu@52.56.78.203

# 2. Navigate to backend
cd ~/cnt-web-deployment/backend

# 3. Copy updated files (use SCP from local machine)
# Or if using git:
git pull origin main

# 4. Restart Docker container
docker restart cnt-backend

# 5. Check logs
docker logs -f cnt-backend
```

### Frontend (GitHub):
```bash
# 1. Commit changes
git add .
git commit -m "Implement notification system"
git push origin main

# 2. Amplify will auto-deploy from GitHub
```

---

## Notes

1. **Music Tracks**: Currently don't have `creator_id` field, so notifications won't be sent for music track approvals. If needed, add `creator_id` to `MusicTrack` model.

2. **WebSocket User Rooms**: The current implementation emits to all users. For better performance, implement user-specific rooms when user connects with authentication.

3. **Push Notifications**: Currently disabled for web (`send_push=False`). Mobile app can enable push notifications.

4. **Error Handling**: All notification creation is wrapped in try-catch to prevent approval/rejection failures if notification system has issues.

