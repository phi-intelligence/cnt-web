import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/websocket_service.dart';

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
  StreamSubscription<Map<String, dynamic>>? _liveStreamSubscription;
  
  LiveStreamNotification? _currentNotification;
  bool _isDismissed = false;

  LiveStreamNotification? get currentNotification => _currentNotification;
  bool get hasNotification => _currentNotification != null && !_isDismissed;

  NotificationProvider() {
    _setupListeners();
  }

  void _setupListeners() {
    _liveStreamSubscription = _wsService.liveStreamStarted.listen((data) {
      _currentNotification = LiveStreamNotification(
        streamId: data['stream_id'] as int? ?? 0,
        hostName: data['host_name'] as String? ?? 'Unknown',
        streamTitle: data['stream_title'] as String? ?? 'Live Stream',
        roomName: data['room_name'] as String? ?? '',
        timestamp: DateTime.now(),
      );
      _isDismissed = false;
      notifyListeners();
    });
  }

  void dismissNotification() {
    _isDismissed = true;
    notifyListeners();
  }

  void clearNotification() {
    _currentNotification = null;
    _isDismissed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _liveStreamSubscription?.cancel();
    super.dispose();
  }
}

