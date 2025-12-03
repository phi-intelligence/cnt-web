import 'dart:io' if (dart.library.html) '../utils/file_stub.dart' as io;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_service.dart';
import '../models/text_overlay.dart';
import 'package:http/http.dart' as http;

/// Video Editing Service
/// Handles video editing operations: trim, cut, audio track manipulation, filters
/// Uses backend API for all operations
class VideoEditingService {
  final ApiService _apiService = ApiService();

  /// Construct the correct URL for a media file path
  /// In development: Uses backend API URL (files served via /media endpoint)
  /// In production: Uses CloudFront/S3 URL (files stored on S3)
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

  /// Trim video - Cut video from start time to end time
  Future<String?> trimVideo(
    String inputPath,
    Duration startTime,
    Duration endTime, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.trimVideo(
        inputPath,
        startTime.inSeconds.toDouble(),
        endTime.inSeconds.toDouble(),
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // On web, return the URL directly (don't download/save files)
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited video and save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = io.File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited video');
      return null;
    } catch (e) {
      onError?.call('Error trimming video: $e');
      return null;
    }
  }

  /// Remove audio track from video
  Future<String?> removeAudioTrack(
    String inputPath, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.removeAudio(inputPath);

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // On web, return the URL directly (don't download/save files)
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited video and save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = io.File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited video');
      return null;
    } catch (e) {
      onError?.call('Error removing audio: $e');
      return null;
    }
  }

  /// Add audio track to video
  Future<String?> addAudioTrack(
    String videoPath,
    String audioPath, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.addAudio(videoPath, audioPath);

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // On web, return the URL directly (don't download/save files)
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited video and save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = io.File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited video');
      return null;
    } catch (e) {
      onError?.call('Error adding audio: $e');
      return null;
    }
  }

  /// Replace audio track in video
  Future<String?> replaceAudioTrack(
    String videoPath,
    String audioPath, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    // For now, use addAudio as replacement
    // TODO: Add replaceAudio endpoint to backend
    return addAudioTrack(videoPath, audioPath, onProgress: onProgress, onError: onError);
  }

  /// Apply filters to video
  /// filters: Map with keys: brightness, contrast, saturation
  /// Values range: brightness (-1.0 to 1.0), contrast (0.0 to 2.0), saturation (0.0 to 3.0)
  Future<String?> applyFilters(
    String inputPath,
    Map<String, double> filters, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      final result = await _apiService.applyVideoFilters(
        inputPath,
        brightness: filters['brightness'],
        contrast: filters['contrast'],
        saturation: filters['saturation'],
      );

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // On web, return the URL directly (don't download/save files)
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited video and save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = io.File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited video');
      return null;
    } catch (e) {
      onError?.call('Error applying filters: $e');
      return null;
    }
  }

  /// Add text overlays to video
  Future<String?> addTextOverlays(
    String videoPath,
    List<TextOverlay> overlays, {
    Function(int)? onProgress,
    Function(String)? onError,
  }) async {
    try {
      // Convert TextOverlay objects to JSON maps
      final overlaysJson = overlays.map((overlay) => overlay.toJson()).toList();
      
      final result = await _apiService.addTextOverlays(videoPath, overlaysJson);

      final outputUrl = result['url'] ?? result['path'] ?? '';
      if (outputUrl.isEmpty) {
        onError?.call('No output URL returned from server');
        return null;
      }

      // On web, return the URL directly (don't download/save files)
      if (kIsWeb) {
        return _constructMediaUrl(outputUrl);
      }

      // On mobile, download the edited video and save to temp directory
      final tempDir = await getTemporaryDirectory();
      final fileName = outputUrl.split('/').last;
      final savePath = '${tempDir.path}/$fileName';
      
      final fullUrl = outputUrl.startsWith('http') 
          ? outputUrl 
          : ApiService.mediaBaseUrl + outputUrl;
      
      final response = await http.get(Uri.parse(fullUrl));
      if (response.statusCode == 200) {
        final file = io.File(savePath);
        await file.writeAsBytes(response.bodyBytes);
        return savePath;
      }

      onError?.call('Failed to download edited video');
      return null;
    } catch (e) {
      onError?.call('Error adding text overlays: $e');
      return null;
    }
  }

  /// Get video duration in seconds
  Future<Duration?> getVideoDuration(String videoPath) async {
    try {
      // Use video_player package to get duration
      // This will be handled by the video player widget
      return null;
    } catch (e) {
      return null;
    }
  }
}
