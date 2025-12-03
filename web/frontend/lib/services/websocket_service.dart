import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  
  IO.Socket? _socket;
  bool _isConnected = false;
  
  // Stream controllers for different event types
  final _liveStreamStartedController = StreamController<Map<String, dynamic>>.broadcast();
  final _speakPermissionRequestedController = StreamController<Map<String, dynamic>>.broadcast();
  
  WebSocketService._internal();
  
  bool get isConnected => _isConnected;
  
  // Streams for listening to events
  Stream<Map<String, dynamic>> get liveStreamStarted => _liveStreamStartedController.stream;
  Stream<Map<String, dynamic>> get speakPermissionRequested => _speakPermissionRequestedController.stream;
  
  Future<void> connect() async {
    if (_isConnected) return;
    try {
      // Use AppConfig.websocketUrl directly for Socket.io connection
      // This URL should be the base URL (e.g., wss://api.christnewtabernacle.com)
      // Socket.io will append /socket.io/ automatically
      var url = AppConfig.websocketUrl;
      
      // Skip connection if using placeholder URL (development without proper env vars)
      if (url.contains('yourdomain.com')) {
        print('⚠️ WebSocket: Skipping connection - placeholder URL detected. Set WEBSOCKET_URL via --dart-define or update AppConfig.');
        return;
      }
      
      // Ensure proper protocol - Socket.io handles ws:// and wss:// automatically
      // Remove any trailing slashes
      url = url.trim();
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      
      // Use string manipulation to remove port specifications before parsing
      // This prevents socket_io_client from inferring port 0
      String cleanUrl = url;
      
      // Remove port specifications for default ports using regex
      // Remove :0, :443 (wss default), :80 (ws default) from URL string
      cleanUrl = cleanUrl.replaceAll(RegExp(r':(0|443|80)(?=/|$)'), '');
      
      // Parse URL after cleaning to reconstruct properly
      final uri = Uri.parse(cleanUrl);
      
      // Reconstruct URL to ensure no port 0 issues
      // For default ports, never include port in final URL
      String finalUrl;
      final defaultPort = (uri.scheme == 'https' || uri.scheme == 'wss') ? 443 : 80;
      
      // Always reconstruct without port for default ports to prevent socket_io_client from adding :0
      if (uri.port != 0 && uri.port != defaultPort) {
        // Valid non-default port specified, use as-is
        finalUrl = '${uri.scheme}://${uri.host}:${uri.port}';
      } else {
        // No port, port is 0, or default port - reconstruct without port (browser will use default)
        finalUrl = '${uri.scheme}://${uri.host}';
      }
      
      // Add path if present (but socket.io uses path option, so usually not needed)
      if (uri.path.isNotEmpty && uri.path != '/') {
        finalUrl += uri.path;
      }
      
      // Final check: ensure no :0 in the URL string before passing to socket_io_client
      // socket_io_client may parse the URL internally and add :0, so we need to be extra careful
      finalUrl = finalUrl.replaceAll(RegExp(r':0(?=/|$)'), '');
      
      print('🔌 WebSocket: Original: $url, Cleaned: $finalUrl');
      
      // Use socket_io_client with explicit options to prevent port inference
      // Add reconnection: false initially to prevent multiple connection attempts with wrong URL
      _socket = IO.io(finalUrl, <String, dynamic>{
        'path': '/socket.io/',
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
        'reconnection': false, // Disable auto-reconnection to prevent repeated :0 attempts
        'timeout': 20000, // 20 second timeout
      });

      _socket!.on('connect', (_) {
        _isConnected = true;
        print('✅ WebSocket connected');
      });
      _socket!.on('disconnect', (_) {
        _isConnected = false;
        print('❌ WebSocket disconnected');
      });
      _socket!.on('message', (data) {
        try {
          if (data is String) {
            _handleMessage(json.decode(data));
          } else if (data is Map<String, dynamic>) {
            _handleMessage(data);
          }
        } catch (_) {}
      });
      _socket!.on('live_stream_started', (data) {
        try {
          if (data is Map<String, dynamic>) {
            _liveStreamStartedController.add(data);
            print('📺 Live stream started notification: $data');
          }
        } catch (e) {
          print('Error handling live_stream_started: $e');
        }
      });
      _socket!.on('speak_permission_requested', (data) {
        try {
          if (data is Map<String, dynamic>) {
            _speakPermissionRequestedController.add(data);
            print('🎤 Speak permission requested: $data');
          }
        } catch (e) {
          print('Error handling speak_permission_requested: $e');
        }
      });
      _socket!.on('error', (error) {
        _isConnected = false;
        print('❌ WebSocket error: $error');
        // Log the actual connection URL being used by socket_io_client
        // This helps debug if port :0 is still being added
        if (error != null && error.toString().contains(':0')) {
          print('⚠️ WebSocket: Port :0 detected in error. URL used: $finalUrl');
        }
      });
      
      // Add connect_error handler to catch connection failures
      _socket!.on('connect_error', (error) {
        _isConnected = false;
        print('❌ WebSocket connection error: $error');
        // Check if error is related to port :0
        if (error != null && error.toString().contains(':0')) {
          print('⚠️ WebSocket: Port :0 detected in connection error. Attempted URL: $finalUrl');
        }
      });
    } catch (_) {
      _isConnected = false;
    }
  }
  
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _isConnected = false;
    _socket = null;
    _liveStreamStartedController.close();
    _speakPermissionRequestedController.close();
  }
  
  void send(Map<String, dynamic> data) {
    if (!_isConnected || _socket == null) {
      print('WebSocket not connected - message not sent');
      return;
    }
    
    try {
      _socket!.emit('message', data);
    } catch (e) {
      print('Error sending WebSocket message: $e');
      _isConnected = false;
      _socket = null;
    }
  }
  
  void _handleMessage(Map<String, dynamic> data) {
    // Handle incoming WebSocket messages
    print('WebSocket message: $data');
    // TODO: Notify listeners based on message type
  }
  
  // Stream listener for specific events
  Stream<String> listenToEvent(String eventType) {
    if (_socket == null) return const Stream.empty();
    return const Stream.empty();
  }
}

