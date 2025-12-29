import 'package:livekit_client/livekit_client.dart' as lk;
import 'api_service.dart';
import 'dart:async';
import '../services/logger_service.dart';

/// Response model for meeting join token
class MeetingJoinResponse {
  final String token;
  final String url;
  final String roomName;
  
  MeetingJoinResponse({
    required this.token,
    required this.url,
    required this.roomName,
  });
}

/// LiveKit Meeting Service for video conferencing functionality
/// Handles meeting room connection via LiveKit SDK
class LiveKitMeetingService {
  static final LiveKitMeetingService _instance = LiveKitMeetingService._internal();
  factory LiveKitMeetingService() => _instance;
  LiveKitMeetingService._internal();

  final ApiService _apiService = ApiService();
  lk.Room? _currentRoom;
  lk.EventsListener<lk.RoomEvent>? _listener;
  bool _isConnected = false;

  // Streams for UI updates
  final _connectionStateController = StreamController<lk.ConnectionState>.broadcast();
  final _participantsController = StreamController<List<lk.RemoteParticipant>>.broadcast();

  Stream<lk.ConnectionState> get connectionState => _connectionStateController.stream;
  Stream<List<lk.RemoteParticipant>> get participants => _participantsController.stream;
  
  lk.Room? get currentRoom => _currentRoom;
  bool get isConnected => _isConnected;

  /// Fetch LiveKit token for joining a meeting by stream/meeting ID
  Future<MeetingJoinResponse> fetchTokenForMeeting({
    required int streamOrMeetingId,
    required String userIdentity,
    required String userName,
    String? userEmail,
    bool isHost = false,
    String? apiBaseParam,
  }) async {
    try {
      final response = await _apiService.getLiveKitMeetingToken(
        streamOrMeetingId,
        userIdentity: userIdentity,
        userName: userName,
        userEmail: userEmail,
        isHost: isHost,
      );
      
      // Always use frontend's configured LiveKit URL (ignores backend's ws_url which is internal Docker URL)
      final frontendUrl = _apiService.getLiveKitUrl();
      LoggerService.i('🎥 LiveKit Meeting: Using frontend URL: $frontendUrl (ignoring backend URL: ${response['ws_url']})');
      
      return MeetingJoinResponse(
        token: response['token'] as String,
        url: frontendUrl, // Use frontend's configured URL, not backend's internal URL
        roomName: response['room_name'] as String,
      );
    } catch (e) {
      throw Exception('Failed to fetch LiveKit token: $e');
    }
  }

  /// Fetch LiveKit token by room name (for link-based joins)
  Future<MeetingJoinResponse> fetchTokenForMeetingByRoom({
    required String roomName,
    required String userIdentity,
    required String userName,
    String? userEmail,
    bool isHost = false,
    String? apiBaseParam,
  }) async {
    try {
      final response = await _apiService.getLiveKitMeetingTokenByRoom(
        roomName,
        userIdentity: userIdentity,
        userName: userName,
        userEmail: userEmail,
        isHost: isHost,
      );
      
      // Always use frontend's configured LiveKit URL (ignores backend's ws_url which is internal Docker URL)
      final frontendUrl = _apiService.getLiveKitUrl();
      LoggerService.i('🎥 LiveKit Meeting: Using frontend URL: $frontendUrl (ignoring backend URL: ${response['ws_url']})');
      
      return MeetingJoinResponse(
        token: response['token'] as String,
        url: frontendUrl, // Use frontend's configured URL, not backend's internal URL
        roomName: response['room_name'] as String,
      );
    } catch (e) {
      throw Exception('Failed to fetch LiveKit token by room: $e');
    }
  }

  /// Join a LiveKit meeting room
  Future<void> joinMeeting({
    required String roomName,
    required String jwtToken,
    required String displayName,
    String? email,
    bool audioMuted = false,
    bool videoMuted = false,
    bool isModerator = false,
    String? wsUrl,
  }) async {
    try {
      // Always use frontend's configured LiveKit URL (ignores backend's ws_url which may be internal Docker URL)
      // Also replace any localhost/internal URLs with the configured external URL
      String url = _apiService.getLiveKitUrl();
      // Log which URL is being used
      if (wsUrl != null && wsUrl.isNotEmpty && wsUrl != url) {
        LoggerService.i('🎥 LiveKit Meeting: Ignoring internal URL from backend: $wsUrl, using: $url');
      } else if (url == _apiService.getLiveKitUrl()) { // Replaced ConfigUtils.getLiveKitWsUrl() with _apiService.getLiveKitUrl() to maintain existing functionality and avoid new dependencies.
        // Checking if it matches environment config
        LoggerService.i('🎥 LiveKit Meeting: Using frontend configured URL: $url');
      } else {
        LoggerService.i('🎥 LiveKit Meeting: Using provided URL: $url');
      }
      
      final roomOptions = lk.RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultAudioCaptureOptions: const lk.AudioCaptureOptions(
          echoCancellation: true,
          noiseSuppression: true,
          autoGainControl: true,
        ),
      );

      _currentRoom = lk.Room(roomOptions: roomOptions);
      await _currentRoom!.connect(url, jwtToken);

      // Set up event listener
      _listener = _currentRoom!.createListener();
      _setupEventHandlers();

      // Enable/disable camera and microphone based on options
      final localParticipant = _currentRoom!.localParticipant;
      if (localParticipant != null) {
        await localParticipant.setMicrophoneEnabled(!audioMuted);
        await localParticipant.setCameraEnabled(!videoMuted);
      }

      _isConnected = true;
      _connectionStateController.add(_currentRoom!.connectionState);
      
    } catch (e) {
      _isConnected = false;
      if (_currentRoom != null) {
        await _currentRoom!.disconnect();
        _currentRoom = null;
      }
      LoggerService.e('❌ LiveKit: Error connecting to room: $e');
      rethrow;
    }
  }

  void _setupEventHandlers() {
    if (_listener == null || _currentRoom == null) return;

    _currentRoom!.addListener(_onRoomChanged);

    _listener!
      ..on<lk.ParticipantConnectedEvent>((event) {
        LoggerService.i('👥 LiveKit: Participant connected: ${event.participant.identity}');
        _updateParticipants();
      })
      ..on<lk.ParticipantDisconnectedEvent>((event) {
        LoggerService.i('👥 LiveKit: Participant disconnected: ${event.participant.identity}');
        _updateParticipants();
      })
      ..on<lk.TrackSubscribedEvent>((event) {
        LoggerService.i('📹 LiveKit: Track subscribed: ${event.track.kind}');
        _updateParticipants();
      })
      ..on<lk.TrackUnsubscribedEvent>((event) {
        LoggerService.i('📹 LiveKit: Track unsubscribed: ${event.track.kind}');
        _updateParticipants();
      })
      ..on<lk.RoomDisconnectedEvent>((_) {
        LoggerService.i('🔌 LiveKit: Room disconnected');
        _isConnected = false;
        _connectionStateController.add(lk.ConnectionState.disconnected);
      });
  }

  void _onRoomChanged() {
    if (_currentRoom != null) {
      _connectionStateController.add(_currentRoom!.connectionState);
      _updateParticipants();
    }
  }

  void _updateParticipants() {
    if (_currentRoom != null) {
      final participants = _currentRoom!.remoteParticipants.values.toList();
      _participantsController.add(participants);
    }
  }

  /// Leave the current meeting
  Future<void> leaveMeeting() async {
    try {
      if (_currentRoom != null) {
        if (_currentRoom!.localParticipant != null) {
          await _currentRoom!.localParticipant!.setCameraEnabled(false);
          await _currentRoom!.localParticipant!.setMicrophoneEnabled(false);
        }
        await _currentRoom!.disconnect();
      }
      _listener?.dispose();
      _currentRoom = null;
      _listener = null;
      _isConnected = false;
      _connectionStateController.add(lk.ConnectionState.disconnected);
    } catch (e) {
      LoggerService.e('❌ LiveKit: Error leaving meeting: $e');
    }
  }

  /// Toggle camera on/off
  Future<void> toggleCamera() async {
    if (_currentRoom == null) return;
    final localParticipant = _currentRoom!.localParticipant;
    if (localParticipant != null) {
      final isEnabled = localParticipant.isCameraEnabled();
      await localParticipant.setCameraEnabled(!isEnabled);
    }
  }

  /// Toggle microphone on/off
  Future<void> toggleMicrophone() async {
    if (_currentRoom == null) return;
    final localParticipant = _currentRoom!.localParticipant;
    if (localParticipant != null) {
      final isEnabled = localParticipant.isMicrophoneEnabled();
      await localParticipant.setMicrophoneEnabled(!isEnabled);
    }
  }

  /// Get camera enabled state
  bool isCameraEnabled() {
    if (_currentRoom == null) return false;
    final localParticipant = _currentRoom!.localParticipant;
    return localParticipant?.isCameraEnabled() ?? false;
  }

  /// Get microphone enabled state
  bool isMicrophoneEnabled() {
    if (_currentRoom == null) return false;
    final localParticipant = _currentRoom!.localParticipant;
    return localParticipant?.isMicrophoneEnabled() ?? false;
  }

  /// Get list of remote participants
  List<lk.RemoteParticipant> getParticipants() {
    if (_currentRoom == null) return [];
    return _currentRoom!.remoteParticipants.values.toList();
  }

  /// Get local participant
  lk.LocalParticipant? getLocalParticipant() {
    return _currentRoom?.localParticipant;
  }

  /// Get participant count (including self)
  int getParticipantCount() {
    if (_currentRoom == null) return 0;
    return _currentRoom!.remoteParticipants.length + 1; // +1 for local participant
  }

  void dispose() {
    leaveMeeting();
    _connectionStateController.close();
    _participantsController.close();
  }
}

