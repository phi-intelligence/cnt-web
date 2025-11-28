import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Utility class for persisting editor state across page refreshes
class StatePersistence {
  static const String _videoEditorStateKey = 'video_editor_state';
  static const String _audioEditorStateKey = 'audio_editor_state';
  
  /// Save video editor state
  static Future<void> saveVideoEditorState({
    required String videoPath,
    String? editedVideoPath,
    Duration? trimStart,
    Duration? trimEnd,
    bool? audioRemoved,
    String? audioFilePath,
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
}

