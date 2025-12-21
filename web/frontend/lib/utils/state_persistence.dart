import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Utility class for persisting editor state across page refreshes
class StatePersistence {
  static const String _videoEditorStateKey = 'video_editor_state';
  static const String _audioEditorStateKey = 'audio_editor_state';
  static const String _videoPreviewStateKey = 'video_preview_state';
  static const String _audioPreviewStateKey = 'audio_preview_state';
  static const String _musicPlayerStateKey = 'music_player_state';
  static const String _meetingStateKey = 'meeting_state';
  
  /// Save video editor state
  static Future<void> saveVideoEditorState({
    required String videoPath,
    String? editedVideoPath,
    Duration? trimStart,
    Duration? trimEnd,
    bool? audioRemoved,
    String? audioFilePath,
    int? rotation,
    bool? isFrontCamera,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'videoPath': videoPath,
        'editedVideoPath': editedVideoPath,
        'trimStart': trimStart?.inMilliseconds,
        'trimEnd': trimEnd?.inMilliseconds,
        'audioRemoved': audioRemoved,
        'audioFilePath': audioFilePath,
        'rotation': rotation,
        'isFrontCamera': isFrontCamera,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_videoEditorStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving video editor state: $e');
    }
  }
  
  /// Load video editor state
  static Future<Map<String, dynamic>?> loadVideoEditorState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_videoEditorStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 1 hour (expire old state)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 1) {
          await clearVideoEditorState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading video editor state: $e');
      return null;
    }
  }
  
  /// Clear video editor state
  static Future<void> clearVideoEditorState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_videoEditorStateKey);
    } catch (e) {
      print('Error clearing video editor state: $e');
    }
  }
  
  /// Save audio editor state
  static Future<void> saveAudioEditorState({
    required String audioPath,
    String? editedAudioPath,
    Duration? trimStart,
    Duration? trimEnd,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'audioPath': audioPath,
        'editedAudioPath': editedAudioPath,
        'trimStart': trimStart?.inMilliseconds,
        'trimEnd': trimEnd?.inMilliseconds,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_audioEditorStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving audio editor state: $e');
    }
  }
  
  /// Load audio editor state
  static Future<Map<String, dynamic>?> loadAudioEditorState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_audioEditorStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 1 hour (expire old state)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 1) {
          await clearAudioEditorState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading audio editor state: $e');
      return null;
    }
  }
  
  /// Clear audio editor state
  static Future<void> clearAudioEditorState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_audioEditorStateKey);
    } catch (e) {
      print('Error clearing audio editor state: $e');
    }
  }
  
  /// Save video preview state
  static Future<void> saveVideoPreviewState({
    required String videoUri,
    required String source,
    String? title,
    String? description,
    String? thumbnailUrl,
    int? duration,
    int? fileSize,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'videoUri': videoUri,
        'source': source,
        'title': title,
        'description': description,
        'thumbnailUrl': thumbnailUrl,
        'duration': duration,
        'fileSize': fileSize,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_videoPreviewStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving video preview state: $e');
    }
  }
  
  /// Load video preview state
  static Future<Map<String, dynamic>?> loadVideoPreviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_videoPreviewStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 2 hours (expire old state)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 2) {
          await clearVideoPreviewState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading video preview state: $e');
      return null;
    }
  }
  
  /// Clear video preview state
  static Future<void> clearVideoPreviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_videoPreviewStateKey);
    } catch (e) {
      print('Error clearing video preview state: $e');
    }
  }
  
  /// Save audio preview state
  static Future<void> saveAudioPreviewState({
    required String audioUri,
    required String source,
    String? title,
    String? description,
    int? duration,
    int? fileSize,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'audioUri': audioUri,
        'source': source,
        'title': title,
        'description': description,
        'duration': duration,
        'fileSize': fileSize,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_audioPreviewStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving audio preview state: $e');
    }
  }
  
  /// Load audio preview state
  static Future<Map<String, dynamic>?> loadAudioPreviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_audioPreviewStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 2 hours (expire old state)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 2) {
          await clearAudioPreviewState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading audio preview state: $e');
      return null;
    }
  }
  
  /// Clear audio preview state
  static Future<void> clearAudioPreviewState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_audioPreviewStateKey);
    } catch (e) {
      print('Error clearing audio preview state: $e');
    }
  }
  
  /// Save music player state
  static Future<void> saveMusicPlayerState({
    String? currentTrackId,
    int? currentTrackPositionMs,
    List<String>? queueTrackIds,
    bool? isPlaying,
    double? volume,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'currentTrackId': currentTrackId,
        'currentTrackPositionMs': currentTrackPositionMs,
        'queueTrackIds': queueTrackIds,
        'isPlaying': isPlaying,
        'volume': volume,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_musicPlayerStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving music player state: $e');
    }
  }
  
  /// Load music player state
  static Future<Map<String, dynamic>?> loadMusicPlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_musicPlayerStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 24 hours (expire old state)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 24) {
          await clearMusicPlayerState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading music player state: $e');
      return null;
    }
  }
  
  /// Clear music player state
  static Future<void> clearMusicPlayerState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_musicPlayerStateKey);
    } catch (e) {
      print('Error clearing music player state: $e');
    }
  }
  
  /// Save meeting state
  static Future<void> saveMeetingState({
    required String roomName,
    required int meetingId,
    String? jwtToken,
    String? serverUrl,
    bool? isHost,
    bool? audioMuted,
    bool? videoMuted,
    String? displayName,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final state = {
        'roomName': roomName,
        'meetingId': meetingId,
        'jwtToken': jwtToken,
        'serverUrl': serverUrl,
        'isHost': isHost,
        'audioMuted': audioMuted,
        'videoMuted': videoMuted,
        'displayName': displayName,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_meetingStateKey, jsonEncode(state));
    } catch (e) {
      print('Error saving meeting state: $e');
    }
  }
  
  /// Load meeting state
  static Future<Map<String, dynamic>?> loadMeetingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stateJson = prefs.getString(_meetingStateKey);
      if (stateJson == null) return null;
      
      final state = jsonDecode(stateJson) as Map<String, dynamic>;
      
      // Check if state is older than 1 hour (expire old state - meetings are temporary)
      final timestampStr = state['timestamp'] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final now = DateTime.now();
        if (now.difference(timestamp).inHours > 1) {
          await clearMeetingState();
          return null;
        }
      }
      
      return state;
    } catch (e) {
      print('Error loading meeting state: $e');
      return null;
    }
  }
  
  /// Clear meeting state
  static Future<void> clearMeetingState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_meetingStateKey);
    } catch (e) {
      print('Error clearing meeting state: $e');
    }
  }
}

