import 'dart:io' if (dart.library.html) '../utils/file_stub.dart' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

/// Audio Editing Service
/// Handles audio editing operations: trim, cut, merge, fade effects
/// Uses backend API for all operations
class AudioEditingService {
  final ApiService _apiService = ApiService();

  /// Construct media URL with proper handling for local vs production environments
  String _constructMediaUrl(String outputUrl) {
    // If outputUrl is already a full HTTP/HTTPS URL, use it directly
    if (outputUrl.startsWith('http://') || outputUrl.startsWith('https://')) {
      print('✅ Using full URL directly: $outputUrl');
      return outputUrl;
    }
    
    // If outputUrl starts with /media/, it's a backend-served file
    if (outputUrl.startsWith('/media/')) {
      // Get API base URL without /api/v1 suffix
      final apiBase = ApiService.baseUrl.replaceAll('/api/v1', '').trim();
      
      // Check if we're in development (localhost, 127.0.0.1, ngrok, or contains port)
      final isDevelopment = apiBase.contains('localhost') || 
                           apiBase.contains('127.0.0.1') ||
                           apiBase.contains('ngrok') ||
                           apiBase.contains(':8002') ||
                           apiBase.contains(':8000') ||
                           apiBase.contains('192.168.') ||
                           apiBase.contains('10.') ||
                           apiBase.contains('172.');
      
      if (isDevelopment) {
        // Development: Use backend API URL to serve the file
        // Backend serves files via /media endpoint
        final constructedUrl = apiBase + outputUrl;
        print('🔧 Development mode - Using backend URL: $constructedUrl');
        return constructedUrl;
      } else {
        // Production: Use CloudFront/S3 URL
        final constructedUrl = ApiService.mediaBaseUrl + outputUrl;
        print('🌐 Production mode - Using CloudFront/S3 URL: $constructedUrl');
        return constructedUrl;
      }
    }
    
    // Fallback: Use mediaBaseUrl
    final fallbackUrl = ApiService.mediaBaseUrl + (outputUrl.startsWith('/') ? outputUrl : '/$outputUrl');
    print('⚠️ Fallback URL construction: $fallbackUrl');
    return fallbackUrl;
  }

  /// Trim audio - Cut audio from start time to end time
  Future<String?> trimAudio(
    String inputPath,
    Duration startTime,
    Duration endTime, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      print('🎵 AudioEditingService.trimAudio called');
      print('   Input path: $inputPath');
      print('   Start time: ${startTime.inSeconds}s');
      print('   End time: ${endTime.inSeconds}s');
      
      final result = await _apiService.trimAudio(
        inputPath,
        startTime.inSeconds.toDouble(),
        endTime.inSeconds.toDouble(),
      );

      print('🎵 Audio trim API response: $result');

      final outputUrl = result['url'] ?? result['path'] ?? '';
      print('🎵 Extracted output URL: $outputUrl');
      
      if (outputUrl.isEmpty) {
        print('❌ No output URL in response');
        onError?.call('No output URL returned from server. Response: $result');
        return null;
      }

      // On web, return the URL directly
      if (kIsWeb) {
        final constructedUrl = _constructMediaUrl(outputUrl);
        print('🎵 Constructed media URL: $constructedUrl');
        return constructedUrl;
      }

      // On mobile, download the edited audio to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      // Add authentication headers for download
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final file = io.File(savePath);
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

      // On web, return the URL directly
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the merged audio to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      // Add authentication headers for download
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final file = io.File(savePath);
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

      // On web, return the URL directly
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited audio to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      // Add authentication headers for download
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final file = io.File(savePath);
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

      // On web, return the URL directly
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited audio to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      // Add authentication headers for download
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final file = io.File(savePath);
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

      // On web, return the URL directly
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited audio to a file
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      // Add authentication headers for download
      final authService = AuthService();
      final headers = await authService.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse(fullUrl),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final file = io.File(savePath);
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
