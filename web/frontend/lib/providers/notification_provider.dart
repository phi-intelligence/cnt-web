import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';
import '../services/api_service.dart';
import '../services/logger_service.dart';

class AppNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final Map<String, dynamic>? data;
  final bool read;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    this.data,
    required this.read,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
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
  
  List<AppNotification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  
  LiveStreamNotification? _currentLiveStreamNotification;
  bool _isDismissed = false;

  List<AppNotification> get notifications => _notifications;
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
        final notification = AppNotification.fromJson(data);
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
          ?.map((json) => AppNotification.fromJson(json as Map<String, dynamic>))
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
            _notifications[index] = AppNotification(
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
        _notifications = _notifications.map((n) => AppNotification(
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
        final wasUnread = _notifications.any((n) => n.id == notificationId && !n.read);
        _notifications.removeWhere((n) => n.id == notificationId);
        // Update unread count if it was unread
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
