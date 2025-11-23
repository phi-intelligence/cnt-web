import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'package:http/http.dart' as http;

/// Audio Editing Service
/// Handles audio editing operations: trim, cut, merge, fade effects
/// Uses backend API for all operations
class AudioEditingService {
  final ApiService _apiService = ApiService();

  /// Trim audio - Cut audio from start time to end time
  Future<String?> trimAudio(
    String inputPath,
    Duration startTime,
    Duration endTime, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.trimAudio(
        inputPath,
        startTime.inSeconds.toDouble(),
        endTime.inSeconds.toDouble(),
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // Download the edited audio
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited audio');
      return null;
    } catch (e) {
      onError?.call('Error trimming audio: $e');
      return null;
    }
  }

  /// Merge multiple audio files into one
  Future<String?> mergeAudioFiles(
    List<String> inputPaths, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      if (inputPaths.isEmpty) {
        onError?.call('No audio files to merge');
        return null;
      }

      if (inputPaths.length == 1) {
        // Only one file, return it
        return inputPaths.first;
      }

      final result = await _apiService.mergeAudio(inputPaths);

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // Download the merged audio
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download merged audio');
      return null;
    } catch (e) {
      onError?.call('Error merging audio: $e');
      return null;
    }
  }

  /// Apply fade in effect to audio
  Future<String?> applyFadeIn(
    String inputPath,
    Duration fadeDuration, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.fadeInAudio(
        inputPath,
        fadeDuration.inSeconds.toDouble(),
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // Download the edited audio
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited audio');
      return null;
    } catch (e) {
      onError?.call('Error applying fade in: $e');
      return null;
    }
  }

  /// Apply fade out effect to audio
  Future<String?> applyFadeOut(
    String inputPath,
    Duration fadeDuration, {
    Function(int)? onProgress,
    Function(String)? onError,
    Duration? audioDuration,
  }) async {
    try {
      final result = await _apiService.fadeOutAudio(
        inputPath,
        fadeDuration.inSeconds.toDouble(),
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // Download the edited audio
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited audio');
      return null;
    } catch (e) {
      onError?.call('Error applying fade out: $e');
      return null;
    }
  }

  /// Apply fade in and fade out effects to audio
  Future<String?> applyFadeInOut(
    String inputPath,
    Duration fadeInDuration,
    Duration fadeOutDuration, {
    Function(int)? onProgress,
    Function(String)? onError,
    Duration? audioDuration,
  }) async {
    try {
      final result = await _apiService.fadeInOutAudio(
        inputPath,
        fadeInDuration.inSeconds.toDouble(),
        fadeOutDuration.inSeconds.toDouble(),
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // Download the edited audio
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited audio');
      return null;
    } catch (e) {
      onError?.call('Error applying fade in/out: $e');
      return null;
    }
  }

  /// Get audio duration in seconds
  Future<Duration?> getAudioDuration(String audioPath) async {
    try {
      // This would require backend API or just_audio package
      // For now, return null and let just_audio handle it
      return null;
    } catch (e) {
      return null;
    }
  }
}
