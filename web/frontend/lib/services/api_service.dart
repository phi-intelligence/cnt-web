import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;
import '../models/api_models.dart';
import '../models/content_item.dart';
import '../models/support_message.dart';
import '../models/document_asset.dart';
import '../models/content_draft.dart';
import '../config/app_config.dart';
import 'auth_service.dart';

/// API Service for connecting Flutter to backend
class ApiService {
  final AuthService _authService = AuthService();
  // Web deployment - uses AppConfig for URLs
  // Configure via --dart-define=API_BASE_URL=https://api.yourdomain.com/api/v1
  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) {
      print('🌐 API Base URL (from env): $envUrl');
      return envUrl;
    }
    
    // Return config URL (will be placeholder if not set via --dart-define)
    // User should set API_BASE_URL via --dart-define when running locally
    final configUrl = AppConfig.apiBaseUrl;
    if (configUrl.isEmpty) {
      print('❌ ERROR: API_BASE_URL is not set! Set it via --dart-define=API_BASE_URL=<your-api-url>');
      throw Exception('API_BASE_URL is not configured. Please set it via --dart-define during build.');
    }
    if (configUrl.contains('yourdomain.com')) {
      print('⚠️ API Base URL: Placeholder URL detected. Set API_BASE_URL via --dart-define when running locally.');
    }
    
    return configUrl;
  }
  
  static String get mediaBaseUrl {
    const envUrl = String.fromEnvironment('MEDIA_BASE_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    final configUrl = AppConfig.mediaBaseUrl;
    if (configUrl.isEmpty) {
      print('❌ ERROR: MEDIA_BASE_URL is not set! Set it via --dart-define=MEDIA_BASE_URL=<your-media-url>');
      throw Exception('MEDIA_BASE_URL is not configured. Please set it via --dart-define during build.');
    }
    return configUrl;
  }
  
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  /// Check if running in development environment
  /// Development: localhost, 127.0.0.1, private IPs, or ports like :8002
  static bool _isDevelopment() {
    final url = baseUrl;
    return url.contains('localhost') || 
           url.contains('127.0.0.1') ||
           url.contains(':8002') ||
           url.contains(':8000') ||
           url.contains('192.168.') ||
           url.contains('10.') ||
           url.contains('172.');
  }
  
  /// Check if a URL is from S3 or CloudFront (needs proxy in production)
  static bool _isS3OrCloudFrontUrl(String url) {
    return url.contains('cloudfront.net') || 
           url.contains('.s3.') ||
           url.contains('s3.amazonaws.com') ||
           url.contains('s3-') ||
           // Also check if mediaBaseUrl is S3 and the URL matches
           (mediaBaseUrl.contains('s3.') && url.startsWith(mediaBaseUrl));
  }
  
  /// Validate that baseUrl is configured before making requests
  void _validateBaseUrl() {
    try {
      final url = baseUrl;
      if (url.isEmpty) {
        print('❌ API Configuration Error: API_BASE_URL is empty');
        throw Exception('API_BASE_URL is not configured. Please set it via --dart-define during build.');
      }
      // Try to parse the URL to ensure it's valid
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
        print('❌ API Configuration Error: Invalid URL format: $url (scheme: ${uri.scheme}, host: ${uri.host})');
        throw Exception('API_BASE_URL is invalid: $url. Must include scheme (http/https) and valid hostname.');
      }
      print('✅ API Base URL validated: $url (host: ${uri.host})');
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured') || e.toString().contains('invalid')) {
        print('❌ API Configuration Error: $e');
        rethrow;
      }
      // Re-throw as configuration error if it's a parsing error
      print('❌ API Configuration Error: Failed to parse URL - $e');
      throw Exception('API_BASE_URL is invalid: $e');
    }
  }
  
  /// Validate that mediaBaseUrl is configured before constructing media URLs
  void _validateMediaBaseUrl() {
    try {
      final url = mediaBaseUrl;
      if (url.isEmpty) {
        print('❌ Media Configuration Error: MEDIA_BASE_URL is empty');
        throw Exception('MEDIA_BASE_URL is not configured. Please set it via --dart-define during build.');
      }
      // Try to parse the URL to ensure it's valid
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !uri.hasAuthority || uri.host.isEmpty) {
        print('❌ Media Configuration Error: Invalid URL format: $url (scheme: ${uri.scheme}, host: ${uri.host})');
        throw Exception('MEDIA_BASE_URL is invalid: $url. Must include scheme (http/https) and valid hostname.');
      }
      print('✅ Media Base URL validated: $url (host: ${uri.host})');
    } catch (e) {
      if (e.toString().contains('MEDIA_BASE_URL') || e.toString().contains('not configured') || e.toString().contains('invalid')) {
        print('❌ Media Configuration Error: $e');
        rethrow;
      }
      // Re-throw as configuration error if it's a parsing error
      print('❌ Media Configuration Error: Failed to parse URL - $e');
      throw Exception('MEDIA_BASE_URL is invalid: $e');
    }
  }
  
  /// Helper method to check if a URL is valid
  static bool _isValidUrl(String url) {
    if (url.isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && uri.hasAuthority && uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get headers with authentication token (checks expiration)
  Future<Map<String, String>> _getHeaders({Map<String, String>? additional}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      ...?additional,
    };
    final authHeaders = await _authService.getAuthHeaders();
    headers.addAll(authHeaders);
    return headers;
  }
  
  /// Handle 401 Unauthorized errors - attempts token refresh before logging out
  Future<void> _handle401Error(http.Response response) async {
    // Try to refresh access token
    print('🔄 401 error - attempting token refresh...');
    final refreshed = await _authService.refreshAccessToken();
    
    if (refreshed) {
      print('✅ Token refreshed, request can be retried');
      // Don't throw error - let caller retry the request
      return;
    }
    
    // Refresh failed - user needs to log in
    await _authService.logout();
    throw Exception('Your session has expired. Please log in again.');
  }
  
  /// Check if response is 401 and handle accordingly
  void _checkResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Will be caught by caller and _handle401Error will be called
      throw http.ClientException('Unauthorized', response.request?.url);
    }
  }

  /// Create a live stream/meeting (returns backend stream object)
  Future<Map<String, dynamic>> createStream({
    String title = 'Instant Meeting',
    String? description,
    String? category,
    DateTime? scheduledStart,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'category': category,
        'scheduled_start': scheduledStart?.toIso8601String(),
      }..removeWhere((k, v) => v == null);

      final response = await http.post(
        Uri.parse('$baseUrl/live/streams'),
        headers: await _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // Handle 401 error (token expired or invalid)
        await _handle401Error(response);
        return {}; // Will never reach here, but satisfies return type
      }
      throw Exception('Failed to create stream: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      // Re-throw if it's already our custom exception
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Network error creating stream: $e');
    }
  }

  /// List streams (optional helper when joining by room without backend route)
  /// Note: This endpoint doesn't require authentication, but we include auth headers if available
  Future<List<Map<String, dynamic>>> listStreams({String? status}) async {
    try {
      _validateBaseUrl();
      Uri uri = Uri.parse('$baseUrl/live/streams');
      if (status != null) {
        uri = uri.replace(queryParameters: {'status': status});
      }
      // Include auth headers if available (optional for this endpoint)
      final headers = await _getHeaders();
      final response = await http.get(
        uri,
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 401) {
        // Token expired or invalid - try to refresh
        await _handle401Error(response);
        // If refresh succeeded, retry the request
        final headers = await _getHeaders();
        final retryResponse = await http.get(
          uri,
          headers: headers,
        ).timeout(const Duration(seconds: 10));
        if (retryResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(retryResponse.body);
          return data.cast<Map<String, dynamic>>();
        }
        throw Exception('Authentication failed. Please log in again.');
      }
      throw Exception('Failed to list streams: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Network error listing streams: $e');
    }
  }

  /// Helper to clean double slashes from URLs (except in protocol)
  String _cleanDoubleSlashes(String url) {
    // Replace multiple slashes with single slash, but preserve https://
    return url.replaceAllMapped(
      RegExp(r'(?<!:)\/\/+'),
      (match) => '/',
    );
  }

  /// Get full media URL for audio/image files
  String getMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    
    // Trim whitespace
    path = path.trim();
    if (path.isEmpty) return '';
    
    // If path is already a full URL (http:// or https://)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // Convert S3 URLs to CloudFront URLs
      // S3 URL pattern: https://cnt-web-media.s3.eu-west-2.amazonaws.com/...
      // or https://cnt-web-media.s3.amazonaws.com/...
      if (path.contains('cnt-web-media.s3')) {
        // Extract the path after the bucket name
        final s3Patterns = [
          'https://cnt-web-media.s3.eu-west-2.amazonaws.com/',
          'https://cnt-web-media.s3.amazonaws.com/',
          'http://cnt-web-media.s3.eu-west-2.amazonaws.com/',
          'http://cnt-web-media.s3.amazonaws.com/',
        ];
        // Clean mediaBaseUrl to ensure no trailing slashes
        final cleanBase = mediaBaseUrl.endsWith('/') 
            ? mediaBaseUrl.substring(0, mediaBaseUrl.length - 1) 
            : mediaBaseUrl;
        for (final pattern in s3Patterns) {
          if (path.startsWith(pattern)) {
            var relativePath = path.substring(pattern.length);
            // Ensure no leading slashes in relativePath
            while (relativePath.startsWith('/')) {
              relativePath = relativePath.substring(1);
            }
            final cloudFrontUrl = _cleanDoubleSlashes('$cleanBase/$relativePath');
            print('🔄 getMediaUrl: Converted S3 to CloudFront: $cloudFrontUrl');
            return cloudFrontUrl;
          }
        }
      }
      // Already a CloudFront URL or other external URL, return as-is
      return path;
    }
    
    // Check if path contains CloudFront domain or S3 domain (might be stored without protocol)
    // This handles cases where backend returns full URLs without http:// prefix
    if (path.contains('cloudfront.net') || path.contains('.amazonaws.com') || path.contains('.s3.')) {
      // Path contains CloudFront or S3 domain, add https:// prefix if missing
      return path.startsWith('http') ? path : 'https://$path';
    }
    
    // Check if path contains the configured media base URL domain
    // This handles cases where backend returns URLs matching our configured domain
    final mediaBase = mediaBaseUrl.replaceAll('https://', '').replaceAll('http://', '').trim();
    if (mediaBase.isNotEmpty && path.contains(mediaBase)) {
      // Path already contains CloudFront/media domain, return with https:// prefix
      return path.startsWith('http') ? path : 'https://$path';
    }
    
    // Clean mediaBaseUrl - remove trailing slashes to prevent double slashes
    final cleanMediaBase = mediaBaseUrl.endsWith('/') 
        ? mediaBaseUrl.substring(0, mediaBaseUrl.length - 1) 
        : mediaBaseUrl;
    
    // Clean path - remove all leading slashes to prevent double slashes
    String cleanPath = path;
    while (cleanPath.startsWith('/')) {
      cleanPath = cleanPath.substring(1);
    }
    
    // Handle paths with 'media/' prefix - strip it for production CloudFront
    // In development, keep it since backend serves from /media endpoint
    if (cleanPath.startsWith('media/')) {
      final isDev = cleanMediaBase.contains('localhost') || 
                    cleanMediaBase.contains('127.0.0.1') ||
                    cleanMediaBase.contains(':8002') ||
                    cleanMediaBase.contains(':8000');
      if (isDev) {
        // Development: Keep media/ prefix
        final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/$cleanPath');
        print('🔧 getMediaUrl: Dev mode - keeping media prefix: $constructedUrl');
        return constructedUrl;
      } else {
        // Production: Strip media/ prefix (CloudFront maps directly to S3)
        cleanPath = cleanPath.substring(6); // Remove 'media/'
        final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/$cleanPath');
        print('🌐 getMediaUrl: Prod mode - stripped media prefix: $constructedUrl');
        return constructedUrl;
      }
    }
    
    // Convert assets/images/ paths to images/ (remove assets/ prefix)
    if (cleanPath.startsWith('assets/images/')) {
      cleanPath = cleanPath.replaceFirst('assets/', '');
      final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/$cleanPath');
      print('🔧 getMediaUrl: Converted assets path: $constructedUrl');
      return constructedUrl;
    }
    
    // Paths starting with 'images/', 'audio/', 'video/', 'movies/', or 'documents/' without 'media/' prefix
    // These are direct S3/CloudFront paths in production (e.g., images/quotes/quote_13.jpg)
    // OR they need /media/ prefix in development (e.g., audio/temp_xxx.webm -> media/audio/temp_xxx.webm)
    // For development (localhost), add /media/ prefix. For production, use as-is.
    if (cleanPath.startsWith('images/') || cleanPath.startsWith('audio/') || cleanPath.startsWith('video/') || cleanPath.startsWith('movies/') || cleanPath.startsWith('documents/')) {
      // Check if we're in development mode (cleanMediaBase contains localhost)
      final isDevelopment = cleanMediaBase.contains('localhost') || 
                           cleanMediaBase.contains('127.0.0.1') ||
                           cleanMediaBase.contains(':8002') ||
                           cleanMediaBase.contains(':8000');
      
      if (isDevelopment) {
        // Development: Add /media/ prefix since backend serves from /media endpoint
        final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/media/$cleanPath');
        print('🔧 getMediaUrl: Development mode - Added /media/ prefix: $constructedUrl (from input: $path)');
        return constructedUrl;
      } else {
        // Production: Use as-is (direct S3/CloudFront path)
        final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/$cleanPath');
        print('🌐 getMediaUrl: Production mode - Using direct path: $constructedUrl');
        return constructedUrl;
      }
    }
    
    // Default: Check if development mode for other paths
    final isDev = cleanMediaBase.contains('localhost') || 
                  cleanMediaBase.contains('127.0.0.1') ||
                  cleanMediaBase.contains(':8002') ||
                  cleanMediaBase.contains(':8000');
    if (isDev) {
      // Development: Add /media/ prefix since backend serves from /media endpoint
      final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/media/$cleanPath');
      print('🔧 getMediaUrl: Default construction (dev): $constructedUrl (from input: $path)');
      return constructedUrl;
    }
    // Production: Use direct path (no /media/ prefix)
    final constructedUrl = _cleanDoubleSlashes('$cleanMediaBase/$cleanPath');
    print('🌐 getMediaUrl: Default construction (prod): $constructedUrl (from input: $path)');
    return constructedUrl;
  }

  /// Get all podcasts
  Future<List<Podcast>> getPodcasts({
    int skip = 0,
    int limit = 100,
    String? status,
    bool newestFirst = false,
  }) async {
    try {
      _validateBaseUrl();
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (newestFirst) {
        queryParams['sort'] = 'newest';
      }

      final uri = Uri.parse('$baseUrl/podcasts/').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Podcast.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load podcasts: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching podcasts: $e');
    }
  }

  /// Get single podcast
  Future<Podcast> getPodcast(int id) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/podcasts/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Podcast.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load podcast: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching podcast: $e');
    }
  }

  /// Get music tracks
  Future<List<MusicTrack>> getMusicTracks({
    int skip = 0,
    int limit = 100,
    String? genre,
    String? artist,
  }) async {
    try {
      _validateBaseUrl();
      Uri uri = Uri.parse('$baseUrl/music/tracks?skip=$skip&limit=$limit');
      if (genre != null) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'genre': genre,
        });
      }
      if (artist != null) {
        uri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'artist': artist,
        });
      }

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => MusicTrack.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load music tracks: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching music tracks: $e');
    }
  }

  /// Get bible stories for Bible reader section
  Future<List<BibleStory>> getBibleStories({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      _validateBaseUrl();
      final uri = Uri.parse('$baseUrl/bible-stories/').replace(
        queryParameters: {
          'skip': skip.toString(),
          'limit': limit.toString(),
        },
      );
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => BibleStory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load bible stories: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching bible stories: $e');
    }
  }

  /// Get single music track
  Future<MusicTrack> getMusicTrack(int id) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/music/tracks/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return MusicTrack.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load music track: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching music track: $e');
    }
  }

  /// Get featured podcasts (top plays or status = approved)
  Future<List<Podcast>> getFeaturedPodcasts() async {
    final podcasts = await getPodcasts(limit: 50);
    // Filter and sort by plays_count
    podcasts.sort((a, b) => b.playsCount.compareTo(a.playsCount));
    return podcasts.take(10).toList();
  }

  /// Get recent podcasts (newest first)
  Future<List<Podcast>> getRecentPodcasts() async {
    final podcasts = await getPodcasts(limit: 20);
    // Sort by created_at descending
    podcasts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return podcasts.take(10).toList();
  }

  /// Get community posts
  Future<List<dynamic>> getCommunityPosts({
    String? category,
    int skip = 0,
    int limit = 20,
    bool approvedOnly = true,  // Default to true - only show approved posts
    String? postType,  // Optional filter by post type ('image' or 'text')
  }) async {
    try {
      Uri uri = Uri.parse('$baseUrl/community/posts');
      final queryParams = {
        'skip': skip.toString(),
        'limit': limit.toString(),
        'approved_only': approvedOnly.toString(),
      };
      if (category != null && category != 'All' && category.isNotEmpty) {
        queryParams['category'] = category.toLowerCase();
      }
      if (postType != null && postType.isNotEmpty) {
        queryParams['post_type'] = postType;
      }
      
      final response = await http.get(
        uri.replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else {
        throw Exception('Failed to load posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching posts: $e');
    }
  }

  /// Create a new community post
  Future<Map<String, dynamic>> createPost({
    required String title,
    required String content,
    String? category,
    String? imageUrl,
    String? postType,  // 'image' or 'text' - auto-detected if not provided
  }) async {
    try {
      _validateBaseUrl();
      final body = <String, dynamic>{
        'title': title,
        'content': content,
        'category': category ?? 'General',
      };
      if (imageUrl != null) {
        body['image_url'] = imageUrl;
      }
      if (postType != null && postType.isNotEmpty) {
        body['post_type'] = postType;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts'),
        headers: await _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create post: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  /// Like a post (toggles like/unlike)
  Future<Map<String, dynamic>?> likePost(int postId) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts/$postId/like'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      print('Error liking post: $e');
      return null;
    }
  }

  /// Get comments for a post
  Future<List<dynamic>> getPostComments(int postId) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/community/posts/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      throw Exception('Failed to get comments: ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching comments: $e');
    }
  }

  /// Comment on a post
  Future<Map<String, dynamic>> commentPost(int postId, String comment) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/community/posts/$postId/comments'),
        headers: await _getHeaders(),
        body: json.encode({'content': comment}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to comment: ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error commenting: $e');
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get user: HTTP ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching user: $e');
    }
  }

  /// Upload image file (for posts, etc.)
  Future<Map<String, dynamic>> uploadImage({
    required String fileName,
    List<int>? bytes,
    String? filePath,
  }) async {
    if (bytes == null && (filePath == null || filePath.isEmpty)) {
      throw Exception('No file data provided');
    }

    try {
      _validateBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/image'),
      );
      
      // Add auth headers
      final headers = await _getHeaders();
      request.headers.addAll({
        'Authorization': headers['Authorization'] ?? '',
      });

      if (bytes != null) {
        // Determine content type from file extension
        http.MediaType contentType = http.MediaType('image', 'jpeg'); // Default fallback
        final lowerFileName = fileName.toLowerCase();
        if (lowerFileName.endsWith('.jpg') || lowerFileName.endsWith('.jpeg')) {
          contentType = http.MediaType('image', 'jpeg');
        } else if (lowerFileName.endsWith('.png')) {
          contentType = http.MediaType('image', 'png');
        } else if (lowerFileName.endsWith('.gif')) {
          contentType = http.MediaType('image', 'gif');
        } else if (lowerFileName.endsWith('.webp')) {
          contentType = http.MediaType('image', 'webp');
        } else if (lowerFileName.endsWith('.bmp')) {
          contentType = http.MediaType('image', 'bmp');
        }
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: contentType,
          ),
        );
      } else if (filePath != null && filePath.isNotEmpty) {
        request.files.add(
          await http.MultipartFile.fromPath('file', filePath),
        );
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Return with file_path key for consistency
        return {
          'file_path': data['url'] ?? data['filename'],
          'url': data['url'],
          'filename': data['filename'],
        };
      }
      throw Exception(
        'Failed to upload image: HTTP ${streamedResponse.statusCode}',
      );
    } catch (e) {
      throw Exception('Error uploading image: $e');
    }
  }

  /// Upload avatar image for the current user
  Future<String> uploadProfileImage({
    required String fileName,
    List<int>? bytes,
    String? filePath,
  }) async {
    if (bytes == null && (filePath == null || filePath.isEmpty)) {
      throw Exception('No file data provided');
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/profile-image'),
      );

      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );
      } else if (filePath != null) {
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
      }

      request.headers.addAll(await _getHeaders());

      final streamedResponse =
          await request.send().timeout(const Duration(minutes: 2));

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['url'] as String? ?? '';
      }

      throw Exception(
        'Failed to upload profile image: HTTP ${streamedResponse.statusCode}',
      );
    } catch (e) {
      throw Exception('Error uploading profile image: $e');
    }
  }

  /// Get support stats for the current user/admin
  Future<SupportStats> getSupportStats() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/support/messages/stats'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SupportStats.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to load support stats: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error fetching support stats: $e');
    }
  }

  Future<List<SupportMessage>> getMySupportMessages() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/support/messages/me'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return list
            .map((item) => SupportMessage.fromJson(item))
            .toList(growable: false);
      }
      throw Exception(
        'Failed to load support messages: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error loading support messages: $e');
    }
  }

  Future<List<SupportMessage>> getSupportMessagesForAdmin({String? status}) async {
    try {
      _validateBaseUrl();
      var uri = Uri.parse('$baseUrl/support/messages');
      if (status != null && status.isNotEmpty) {
        uri = uri.replace(queryParameters: {'status_filter': status});
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final list = json.decode(response.body) as List<dynamic>;
        return list
            .map((item) => SupportMessage.fromJson(item))
            .toList(growable: false);
      }
      throw Exception(
        'Failed to load admin support messages: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error loading admin support messages: $e');
    }
  }

  Future<SupportMessage> createSupportMessage({
    required String subject,
    required String message,
  }) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/support/messages'),
        headers: await _getHeaders(),
        body: json.encode({
          'subject': subject,
          'message': message,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return SupportMessage.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to send support message: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error sending support message: $e');
    }
  }

  Future<SupportMessage> replyToSupportMessage({
    required int messageId,
    required String responseText,
    String status = 'responded',
  }) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/support/messages/$messageId/reply'),
        headers: await _getHeaders(),
        body: json.encode({
          'response': responseText,
          'status': status,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SupportMessage.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to reply to message: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error replying to support message: $e');
    }
  }

  Future<SupportMessage> markSupportMessageRead({
    required int messageId,
    required String actor,
  }) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/support/messages/$messageId/mark-read'),
        headers: await _getHeaders(),
        body: json.encode({'actor': actor}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return SupportMessage.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception(
        'Failed to update message read state: HTTP ${response.statusCode}',
      );
    } catch (e) {
      throw Exception('Error updating support message: $e');
    }
  }

  Future<List<DocumentAsset>> getDocuments({String? category}) async {
    try {
      _validateBaseUrl();
      var uri = Uri.parse('$baseUrl/documents/');
      if (category != null && category.isNotEmpty) {
        uri = uri.replace(queryParameters: {'category': category});
      }
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => DocumentAsset.fromJson(e)).toList();
      }
      throw Exception('Failed to load documents: HTTP ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      throw Exception('Error fetching documents: $e');
    }
  }

  Future<DocumentAsset> createDocument({
    required String title,
    String? description,
    required String filePath,
    String? thumbnailPath,
    String category = 'Bible',
    bool isFeatured = false,
  }) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/documents'),
        headers: await _getHeaders(),
        body: json.encode({
          'title': title,
          'description': description,
          'file_path': filePath,
          'thumbnail_path': thumbnailPath,
          'category': category,
          'is_featured': isFeatured,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DocumentAsset.fromJson(
          json.decode(response.body) as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to create document: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating document: $e');
    }
  }

  Future<void> deleteDocument(int documentId) async {
    try {
      _validateBaseUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/documents/$documentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete document: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting document: $e');
    }
  }

  Future<String> uploadDocumentFile({
    required String fileName,
    List<int>? bytes,
    String? filePath,
  }) async {
    if (bytes == null && (filePath == null || filePath.isEmpty)) {
      throw Exception('No document data provided');
    }

    try {
      _validateBaseUrl();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/document'),
      );

      if (bytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
            contentType: http.MediaType('application', 'pdf'),
          ),
        );
      } else if (filePath != null) {
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
      }

      request.headers.addAll(await _getHeaders());

      final streamedResponse =
          await request.send().timeout(const Duration(minutes: 2));

      if (streamedResponse.statusCode == 200 ||
          streamedResponse.statusCode == 201) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['url'] as String? ?? '';
      }

      throw Exception(
        'Failed to upload document: HTTP ${streamedResponse.statusCode}',
      );
    } catch (e) {
      throw Exception('Error uploading document: $e');
    }
  }

  /// Get user stats (total listening time, tracks played, etc.)
  Future<Map<String, dynamic>?> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: await _getHeaders(),
        body: jsonEncode(profileData),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update profile: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }
  
  Future<Map<String, dynamic>?> getBankDetails() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/bank-details'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        return null; // No bank details found
      }
      throw Exception('Failed to get bank details: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting bank details: $e');
    }
  }
  
  Future<bool> updateBankDetails(Map<String, dynamic> bankData) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/bank-details'),
        headers: await _getHeaders(),
        body: jsonEncode(bankData),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating bank details: $e');
    }
  }
  
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/check-username'),
        headers: await _getHeaders(),
        body: jsonEncode({'username': username}),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to check username: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error checking username: $e');
    }
  }
  
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      // TODO: Implement actual stats endpoint
      return {
        'total_minutes': 1234,
        'songs_played': 567,
        'streak_days': 30,
      };
    } catch (e) {
      return {
        'total_minutes': 0,
        'songs_played': 0,
        'streak_days': 0,
      };
    }
  }

  /// Get public user profile by user ID
  Future<Map<String, dynamic>?> getPublicUserProfile(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/public'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching public user profile: $e');
      return null;
    }
  }

  /// Get all playlists
  Future<List<dynamic>> getPlaylists() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/playlists'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      } else if (response.statusCode == 401) {
        // Handle 401 error (token expired or invalid)
        await _handle401Error(response);
        // Retry the request after refresh
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/playlists'),
          headers: await _getHeaders(),
        ).timeout(const Duration(seconds: 10));
        if (retryResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(retryResponse.body);
          return data;
        }
        throw Exception('Authentication failed. Please log in again.');
      }
      return [];
    } catch (e) {
      if (e.toString().contains('API_BASE_URL') || e.toString().contains('not configured')) {
        rethrow;
      }
      print('Error fetching playlists: $e');
      return [];
    }
  }

  /// Create a new playlist
  Future<Map<String, dynamic>> createPlaylist({
    required String name,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      }
      throw Exception('Failed to create playlist: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating playlist: $e');
    }
  }

  /// Add item to playlist
  Future<bool> addToPlaylist(int playlistId, String contentType, int contentId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/playlists/$playlistId/items'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'content_type': contentType,
          'content_id': contentId,
        }),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Error adding to playlist: $e');
      return false;
    }
  }

  /// Get favorites
  Future<List<dynamic>> getFavorites() async {
    try {
      // TODO: Implement favorites endpoint
      // For now, return empty list
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Add to favorites
  Future<bool> addToFavorites(String contentType, int contentId) async {
    try {
      // TODO: Implement favorites endpoint
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Remove from favorites
  Future<bool> removeFromFavorites(String contentType, int contentId) async {
    try {
      // TODO: Implement favorites endpoint
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Search across all content types
  Future<Map<String, dynamic>> searchContent({
    required String query,
    String? type, // 'podcasts', 'music', 'videos', 'posts', 'users'
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      // For now, implement client-side search as backend search endpoint may not exist
      // Try API first, fallback to client-side search
      Uri uri = Uri.parse('$baseUrl/search');
      final queryParams = {
        'q': query,
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (type != null && type != 'All') {
        queryParams['type'] = type.toLowerCase();
      }
      
      final response = await http.get(
        uri.replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      // If search endpoint doesn't exist, return empty results
      // Client-side search will be handled in SearchProvider
      return {'podcasts': [], 'music': [], 'posts': []};
    } catch (e) {
      // Return empty results if search endpoint doesn't exist
      return {'podcasts': [], 'music': [], 'posts': []};
    }
  }

  /// Upload file and get URL (legacy method)
  Future<String> uploadFileToEndpoint(
    String filePath,
    String endpoint, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final file = await http.MultipartFile.fromPath('file', filePath);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.files.add(file);
      request.headers.addAll(await _getHeaders());
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body);
        return data['url'] ?? data['path'] ?? '';
      }
      throw Exception('Failed to upload file: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Upload file with type and get metadata
  Future<Map<String, dynamic>> uploadFile(
    String filePath,
    String fileType, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Determine default filename based on file type
      String defaultFilename = 'file';
      if (fileType == 'audio') {
        defaultFilename = 'audio.mp3';
      } else if (fileType == 'video') {
        defaultFilename = 'video.mp4';
      } else if (fileType == 'image') {
        defaultFilename = 'image.jpg';
      }
      
      final file = await _createMultipartFileFromSource(filePath, 'file', defaultFilename);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/$fileType'));
      request.files.add(file);
      request.headers.addAll(await _getHeaders());
      request.headers.remove('Content-Type'); // Let multipart set it
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Convert 'url' to 'file_path' for consistency
        if (data.containsKey('url') && !data.containsKey('file_path')) {
          data['file_path'] = data['url'];
        }
        return data;
      }
      throw Exception('Failed to upload file: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error uploading file: $e');
    }
  }

  /// Download file from URL to path
  Future<String> downloadFile(
    String url,
    String savePath, {
    Function(int, int)? onProgress,
  }) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : '$mediaBaseUrl$url');
      final request = http.Request('GET', uri);
      final streamedResponse = await request.send().timeout(const Duration(minutes: 5));
      
      if (streamedResponse.statusCode == 200) {
        final file = await http.Response.fromStream(streamedResponse);
        // Save file to savePath
        // This is a simplified version - in production you'd write to FileSystem
        return savePath;
      }
      throw Exception('Failed to download file: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  /// Download file bytes from URL (for in-memory use like PDF viewing)
  Future<List<int>> downloadFileBytes(String url) async {
    try {
      final uri = Uri.parse(url.startsWith('http') ? url : '$mediaBaseUrl$url');
      final response = await http.get(uri).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to download file: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error downloading file: $e');
    }
  }

  /// Helper function to detect content type from filename extension
  http.MediaType? _detectContentTypeFromFilename(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      // Audio formats
      case 'mp3':
        return http.MediaType('audio', 'mpeg');
      case 'wav':
        return http.MediaType('audio', 'wav');
      case 'ogg':
        return http.MediaType('audio', 'ogg');
      case 'webm':
        // Check if it's audio or video based on context - default to audio
        return http.MediaType('audio', 'webm');
      case 'm4a':
        return http.MediaType('audio', 'mp4');
      case 'aac':
        return http.MediaType('audio', 'aac');
      case 'flac':
        return http.MediaType('audio', 'flac');
      // Video formats
      case 'mp4':
        return http.MediaType('video', 'mp4');
      case 'mov':
        return http.MediaType('video', 'quicktime');
      case 'avi':
        return http.MediaType('video', 'x-msvideo');
      default:
        return null;
    }
  }

  /// Helper function to create MultipartFile from URL or file path
  /// Handles blob URLs, network URLs, and file paths
  Future<http.MultipartFile> _createMultipartFileFromSource(
    String source,
    String fieldName,
    String defaultFilename,
  ) async {
    print('🔍 _createMultipartFileFromSource: source=$source, fieldName=$fieldName');
    
    // Check if source is a URL
    if (source.startsWith('http://') || source.startsWith('https://')) {
      print('📥 Downloading file from URL: $source');
      // Network URL - download the file
      try {
        final isS3OrCloudFront = _isS3OrCloudFrontUrl(source);
        final isDev = _isDevelopment();
        
        String downloadUrl = source;
        Map<String, String>? headers;
        
        if (isS3OrCloudFront && !isDev) {
          // Production: Use backend proxy to access S3 files
          // The proxy handles S3 authentication via IAM credentials
          print('🔄 Using backend proxy for S3/CloudFront URL in production');
          downloadUrl = '$baseUrl/media/proxy?url=${Uri.encodeComponent(source)}';
          headers = await _getHeaders();
          // Remove Content-Type for download request
          headers.remove('Content-Type');
        } else if (!isS3OrCloudFront) {
          // Non-S3 URL: Use auth headers
          headers = await _getHeaders();
          headers.remove('Content-Type');
        }
        // else: Development with S3 URLs - these are actually local /media URLs
        
        print('📥 Fetching from: $downloadUrl');
        final response = await http.get(
          Uri.parse(downloadUrl),
          headers: headers,
        ).timeout(const Duration(minutes: 5));
        
        if (response.statusCode != 200) {
          throw Exception('Failed to download file from URL: HTTP ${response.statusCode}');
        }
        
        // Extract filename from URL or use default
        String filename = defaultFilename;
        try {
          final uri = Uri.parse(source);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final urlFilename = pathSegments.last;
            if (urlFilename.isNotEmpty && urlFilename.contains('.')) {
              filename = urlFilename;
            }
          }
        } catch (e) {
          // Use default filename if extraction fails
        }
        
        return http.MultipartFile.fromBytes(
          fieldName,
          response.bodyBytes,
          filename: filename,
        );
      } catch (e) {
        throw Exception('Error downloading file from URL: $e');
      }
    } else if (source.startsWith('blob:')) {
      // Blob URL - convert to bytes (web only)
      if (!kIsWeb) {
        throw Exception('Blob URLs are only supported on web platform');
      }
      
      try {
        // Detect content type from filename extension
        http.MediaType? contentType = _detectContentTypeFromFilename(defaultFilename);
        
        // If we couldn't detect from filename, use fallback based on filename content
        if (contentType == null) {
          final lowerFilename = defaultFilename.toLowerCase();
          if (lowerFilename.contains('audio') || 
              lowerFilename.contains('.mp3') ||
              lowerFilename.contains('.wav') ||
              lowerFilename.contains('.ogg')) {
            contentType = http.MediaType('audio', 'webm');
          } else if (lowerFilename.contains('video') ||
                     lowerFilename.contains('.mp4')) {
            contentType = http.MediaType('video', 'webm');
          } else {
            // Default to audio/webm for audio editor context
            contentType = http.MediaType('audio', 'webm');
          }
        }
        
        // Use HttpRequest to fetch blob URL as bytes
        final request = await html.HttpRequest.request(
          source,
          responseType: 'arraybuffer',
        );
        
        if (request.status != 200) {
          throw Exception('Failed to fetch blob URL: HTTP ${request.status}');
        }
        
        // Convert ArrayBuffer to Uint8List
        Uint8List bytes;
        if (request.response is ByteBuffer) {
          final buffer = request.response as ByteBuffer;
          bytes = Uint8List.view(buffer);
        } else {
          throw Exception('Unexpected response type from blob URL');
        }
        
        return http.MultipartFile.fromBytes(
          fieldName,
          bytes,
          filename: defaultFilename,
          contentType: contentType,
        );
      } catch (e) {
        throw Exception('Error converting blob URL to bytes: $e');
      }
    } else {
      // File path - use fromPath (for mobile only)
      if (kIsWeb) {
        throw Exception('File paths are not supported on web. Source must be a URL (http://, https://) or blob URL. Received: $source');
      }
      
      try {
        return await http.MultipartFile.fromPath(fieldName, source);
      } catch (e) {
        throw Exception('Error reading file from path: $e');
      }
    }
  }

  /// Video editing endpoints
  Future<Map<String, dynamic>> trimVideo(
    String videoPath,
    double startTime,
    double endTime, {
    Function(int, int)? onProgress,
  }) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        videoPath,
        'video_file',
        'video.mp4',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/video-editing/trim'));
      request.files.add(file);
      request.fields['start_time'] = startTime.toString();
      request.fields['end_time'] = endTime.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to trim video: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error trimming video: $e');
    }
  }

  Future<Map<String, dynamic>> removeAudio(String videoPath) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        videoPath,
        'video_file',
        'video.mp4',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/video-editing/remove-audio'));
      request.files.add(file);
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to remove audio: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error removing audio: $e');
    }
  }

  Future<Map<String, dynamic>> addAudio(String videoPath, String audioPath) async {
    try {
      // Create multipart files from URLs or file paths
      final videoFile = await _createMultipartFileFromSource(
        videoPath,
        'video_file',
        'video.mp4',
      );
      
      final audioFile = await _createMultipartFileFromSource(
        audioPath,
        'audio_file',
        'audio.mp3',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/video-editing/add-audio'));
      request.files.add(videoFile);
      request.files.add(audioFile);
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to add audio: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error adding audio: $e');
    }
  }

  Future<Map<String, dynamic>> applyVideoFilters(
    String videoPath, {
    double? brightness,
    double? contrast,
    double? saturation,
  }) async {
    try {
      final file = await http.MultipartFile.fromPath('video_file', videoPath);
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/video-editing/apply-filters'));
      request.files.add(file);
      if (brightness != null) request.fields['brightness'] = brightness.toString();
      if (contrast != null) request.fields['contrast'] = contrast.toString();
      if (saturation != null) request.fields['saturation'] = saturation.toString();
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to apply filters: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error applying filters: $e');
    }
  }

  Future<Map<String, dynamic>> addTextOverlays(
    String videoPath,
    List<Map<String, dynamic>> overlays,
  ) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        videoPath,
        'video_file',
        'video.mp4',
      );
      
      // Convert overlays to JSON string
      final overlaysJson = json.encode(overlays);
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/video-editing/add-text-overlays'),
      );
      request.files.add(file);
      request.fields['overlays_json'] = overlaysJson;
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to add text overlays: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error adding text overlays: $e');
    }
  }

  Future<Map<String, dynamic>> rotateVideo(
    String videoPath,
    int degrees,
  ) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        videoPath,
        'video_file',
        'video.mp4',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/video-editing/rotate'));
      request.files.add(file);
      request.fields['degrees'] = degrees.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to rotate video: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error rotating video: $e');
    }
  }

  /// Audio editing endpoints
  Future<Map<String, dynamic>> trimAudio(
    String audioPath,
    double startTime,
    double endTime,
  ) async {
    try {
      // Extract filename from audioPath if possible
      String defaultFilename = 'audio.mp3';
      try {
        if (audioPath.startsWith('http://') || audioPath.startsWith('https://')) {
          final uri = Uri.parse(audioPath);
          final pathSegments = uri.pathSegments;
          if (pathSegments.isNotEmpty) {
            final urlFilename = pathSegments.last;
            if (urlFilename.isNotEmpty && urlFilename.contains('.')) {
              defaultFilename = urlFilename;
            }
          }
        } else if (audioPath.contains('/')) {
          // Local file path - extract filename
          final pathParts = audioPath.split('/');
          if (pathParts.isNotEmpty) {
            final filename = pathParts.last;
            if (filename.isNotEmpty && filename.contains('.')) {
              defaultFilename = filename;
            }
          }
        }
      } catch (e) {
        // Use default if extraction fails
        print('⚠️ Could not extract filename from audioPath, using default: $e');
      }
      
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        audioPath,
        'audio_file',
        defaultFilename,
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/audio-editing/trim'));
      request.files.add(file);
      request.fields['start_time'] = startTime.toString();
      request.fields['end_time'] = endTime.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      print('🎵 Sending audio trim request: start=${startTime}s, end=${endTime}s, file=${audioPath}');
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      print('🎵 Audio trim response status: ${streamedResponse.statusCode}');
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        final responseBody = response.body;
        print('🎵 Audio trim response body: $responseBody');
        
        try {
          final decoded = json.decode(responseBody);
          print('🎵 Audio trim decoded response: $decoded');
          return decoded;
        } catch (e) {
          print('❌ Failed to decode audio trim response: $e');
          print('   Response body: $responseBody');
          throw Exception('Invalid response format from audio trim endpoint: $e');
        }
      } else {
        // Try to get error message from response
        try {
          final response = await http.Response.fromStream(streamedResponse);
          final errorBody = response.body;
          print('❌ Audio trim error response: $errorBody');
          throw Exception('Failed to trim audio: HTTP ${streamedResponse.statusCode} - $errorBody');
        } catch (e) {
          throw Exception('Failed to trim audio: HTTP ${streamedResponse.statusCode}');
        }
      }
    } catch (e) {
      print('❌ Error in trimAudio API call: $e');
      throw Exception('Error trimming audio: $e');
    }
  }

  Future<Map<String, dynamic>> mergeAudio(List<String> audioPaths) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/audio-editing/merge'));
      
      // Create multipart files from URLs or file paths
      for (final audioPath in audioPaths) {
        final file = await _createMultipartFileFromSource(
          audioPath,
          'audio_files',
          'audio.mp3',
        );
        request.files.add(file);
      }
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to merge audio: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error merging audio: $e');
    }
  }

  Future<Map<String, dynamic>> fadeInAudio(String audioPath, double fadeDuration) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        audioPath,
        'audio_file',
        'audio.mp3',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/audio-editing/fade-in'));
      request.files.add(file);
      request.fields['fade_duration'] = fadeDuration.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to apply fade in: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error applying fade in: $e');
    }
  }

  Future<Map<String, dynamic>> fadeOutAudio(String audioPath, double fadeDuration) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        audioPath,
        'audio_file',
        'audio.mp3',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/audio-editing/fade-out'));
      request.files.add(file);
      request.fields['fade_duration'] = fadeDuration.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to apply fade out: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error applying fade out: $e');
    }
  }

  Future<Map<String, dynamic>> fadeInOutAudio(
    String audioPath,
    double fadeInDuration,
    double fadeOutDuration,
  ) async {
    try {
      // Create multipart file from URL or file path
      final file = await _createMultipartFileFromSource(
        audioPath,
        'audio_file',
        'audio.mp3',
      );
      
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/audio-editing/fade-in-out'));
      request.files.add(file);
      request.fields['fade_in_duration'] = fadeInDuration.toString();
      request.fields['fade_out_duration'] = fadeOutDuration.toString();
      
      // Add authentication headers
      final headers = await _getHeaders();
      // Remove Content-Type as multipart request sets it automatically
      headers.remove('Content-Type');
      request.headers.addAll(headers);
      
      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      
      if (streamedResponse.statusCode == 200) {
        final response = await http.Response.fromStream(streamedResponse);
        return json.decode(response.body);
      }
      throw Exception('Failed to apply fade in/out: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error applying fade in/out: $e');
    }
  }

  /// Get all movies
  Future<List<Movie>> getMovies({
    int skip = 0,
    int limit = 100,
    bool? featured,
    int? categoryId,
    String? status,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (featured != null) queryParams['featured'] = featured.toString();
      if (categoryId != null) queryParams['category_id'] = categoryId.toString();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse('$baseUrl/movies/').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movies: $e');
    }
  }

  /// Get single movie
  Future<Movie> getMovie(int id) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$id'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return Movie.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load movie: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching movie: $e');
    }
  }

  /// Get featured movies for hero carousel
  Future<List<Movie>> getFeaturedMovies({int limit = 10}) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/movies/featured/?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load featured movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching featured movies: $e');
    }
  }

  /// Get animated Bible stories
  Future<List<Movie>> getAnimatedBibleStories({int limit = 20}) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/movies/animated-bible-stories/?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load animated Bible stories: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching animated Bible stories: $e');
    }
  }

  /// Get similar movies
  Future<List<Movie>> getSimilarMovies(int movieId, {int limit = 10}) async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/movies/$movieId/similar?limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Movie.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load similar movies: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching similar movies: $e');
    }
  }

  /// Get movie preview URL with timestamp support
  /// Returns video URL with optional start time parameter for direct playback
  String getMoviePreviewUrl(Movie movie) {
    final videoUrl = getMediaUrl(movie.videoUrl);
    // If preview times are set, we'll handle them in the video player
    // For now, just return the full video URL
    return videoUrl;
  }

  /// Convert Movie to ContentItem for display
  ContentItem movieToContentItem(Movie movie, {String? categoryName}) {
    // Prefer preview clip URL for lightweight hero carousel playback when available,
    // otherwise fall back to the full movie URL.
    final String effectiveVideoPath =
        (movie.previewUrl != null && movie.previewUrl!.isNotEmpty)
            ? movie.previewUrl!
            : movie.videoUrl;

    return ContentItem(
      id: movie.id.toString(),
      title: movie.title,
      creator: movie.director ?? 'Christ Tabernacle',
      description: movie.description,
      coverImage: movie.coverImage != null ? getMediaUrl(movie.coverImage!) : null,
      videoUrl: getMediaUrl(effectiveVideoPath),
      duration: movie.duration != null ? Duration(seconds: movie.duration!) : null,
      category: categoryName ?? 'Movies',
      plays: movie.playsCount,
      createdAt: movie.createdAt,
      isFavorite: false,
      director: movie.director,
      cast: movie.cast,
      releaseDate: movie.releaseDate,
      rating: movie.rating,
      previewStartTime: movie.previewStartTime,
      previewEndTime: movie.previewEndTime,
      isMovie: true,
    );
  }

  /// Admin API Methods
  Future<Map<String, dynamic>> getAdminDashboard() async {
    try {
      _validateBaseUrl();
      final headers = await _getHeaders();
      print('🔐 Admin Dashboard Request Headers: ${headers.keys.toList()}');
      print('🔐 Authorization header present: ${headers.containsKey('Authorization')}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      print('📡 Admin Dashboard Response Status: ${response.statusCode}');
      if (response.statusCode != 200) {
        print('❌ Admin Dashboard Error Response: ${response.body}');
      }
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _handle401Error(response);
        // Retry the request after refresh
        final retryHeaders = await _getHeaders();
        final retryResponse = await http.get(
          Uri.parse('$baseUrl/admin/dashboard'),
          headers: retryHeaders,
        ).timeout(const Duration(seconds: 10));
        if (retryResponse.statusCode == 200) {
          return json.decode(retryResponse.body) as Map<String, dynamic>;
        }
        throw Exception('Unauthorized: Please log in again. Token may have expired.');
      } else if (response.statusCode == 403) {
        throw Exception('Forbidden: Admin access required.');
      }
      throw Exception('Failed to get admin dashboard: ${response.statusCode} - ${response.body}');
    } catch (e) {
      print('💥 Admin Dashboard Exception: $e');
      throw Exception('Error fetching admin dashboard: $e');
    }
  }
  
  Future<List<dynamic>> getPendingContent() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      throw Exception('Failed to get pending content: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching pending content: $e');
    }
  }
  
  Future<bool> approveContent(String contentType, int contentId) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/approve/$contentType/$contentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error approving content: $e');
    }
  }
  
  Future<bool> rejectContent(String contentType, int contentId, {String? reason}) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/reject/$contentType/$contentId'),
        headers: await _getHeaders(),
        body: json.encode({'reason': reason}),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error rejecting content: $e');
    }
  }

  Future<bool> deleteContent(String contentType, int contentId) async {
    try {
      _validateBaseUrl();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/$contentType/$contentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting content: $e');
    }
  }

  Future<bool> archiveContent(String contentType, int contentId) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/archive/$contentType/$contentId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error archiving content: $e');
    }
  }
  
  Future<List<dynamic>> getAllContent({
    String? contentType,
    String? status,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      _validateBaseUrl();
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (contentType != null) queryParams['content_type'] = contentType;
      if (status != null) queryParams['status'] = status;
      
      final uri = Uri.parse('$baseUrl/admin/content').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      throw Exception('Failed to get content: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching content: $e');
    }
  }
  
  /// Google Drive API Methods
  Future<String> getGoogleDriveAuthUrl() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/google-drive/auth-url'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['auth_url'] as String;
      } else if (response.statusCode == 503) {
        // Service Unavailable - Google Drive not configured
        final errorData = json.decode(response.body);
        throw Exception('Google Drive not configured: ${errorData['detail']?['message'] ?? 'Setup required'}');
      }
      throw Exception('Failed to get auth URL: ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error getting Google Drive auth URL: $e');
    }
  }

  /// Get Google OAuth Client ID for frontend
  Future<String?> getGoogleClientId() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/auth/google-client-id'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['client_id'] as String?;
      }
      return null;
    } catch (e) {
      print('⚠️  Could not fetch Google Client ID from backend: $e');
      return null;
    }
  }

  /// Get OAuth token for Google Picker API
  Future<Map<String, dynamic>> getGoogleDrivePickerToken() async {
    try {
      _validateBaseUrl();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/google-drive/picker-token'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get picker token: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting Google Drive picker token: $e');
    }
  }
  
  Future<List<dynamic>> listGoogleDriveFiles({String? mimeType, int limit = 100}) async {
    try {
      _validateBaseUrl();
      final queryParams = <String, String>{'limit': limit.toString()};
      if (mimeType != null) queryParams['mime_type'] = mimeType;
      
      final uri = Uri.parse('$baseUrl/admin/google-drive/files').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['files'] as List<dynamic>;
      }
      throw Exception('Failed to list files: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error listing Google Drive files: $e');
    }
  }
  
  Future<Map<String, dynamic>> importGoogleDriveFile(String fileId, String fileType) async {
    try {
      _validateBaseUrl();
      final response = await http.post(
        Uri.parse('$baseUrl/admin/google-drive/import/$fileId?file_type=$fileType'),
        headers: await _getHeaders(),
      ).timeout(const Duration(minutes: 5));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to import file: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error importing file: $e');
    }
  }

  /// Get LiveKit WebSocket URL
  String getLiveKitUrl() {
    const envUrl = String.fromEnvironment('LIVEKIT_WS_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    return AppConfig.livekitWsUrl;
  }
  
  /// Get LiveKit access token for voice agent
  Future<Map<String, dynamic>> getLiveKitVoiceToken(String roomName, {String? userIdentity}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/livekit/voice/token'),
        headers: await _getHeaders(),
        body: jsonEncode({
          'room_name': roomName,
          if (userIdentity != null) 'user_identity': userIdentity,
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get token: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error getting LiveKit token: $e');
    }
  }
  
  /// Create a LiveKit room for voice agent
  Future<Map<String, dynamic>> createLiveKitRoom(String roomName, {int maxParticipants = 10}) async {
    try {
      _validateBaseUrl();
      final url = '$baseUrl/livekit/voice/room';
      print('🌐 Creating LiveKit room: POST $url');
      print('🌐 Room name: $roomName, max participants: $maxParticipants');
      
      final response = await http.post(
        Uri.parse(url),
        headers: await _getHeaders(),
        body: jsonEncode({
          'room_name': roomName,
          'max_participants': maxParticipants,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Room creation request timed out. Check if backend is running at $baseUrl');
        },
      );
      
      print('🌐 Response status: ${response.statusCode}');
      print('🌐 Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final result = json.decode(response.body) as Map<String, dynamic>;
        print('✅ Room created successfully: $result');
        return result;
      } else if (response.statusCode == 500) {
        // Try to parse error message from response
        try {
          final errorBody = json.decode(response.body) as Map<String, dynamic>;
          final detail = errorBody['detail'] ?? errorBody['message'] ?? response.body;
          throw Exception('Backend error: $detail');
        } catch (_) {
          throw Exception('Failed to create room: HTTP ${response.statusCode}. ${response.body}');
        }
      } else {
        throw Exception('Failed to create room: HTTP ${response.statusCode}. ${response.body}');
      }
    } on TimeoutException catch (e) {
      print('❌ Timeout creating room: $e');
      rethrow;
    } on http.ClientException catch (e) {
      print('❌ Network error creating room: $e');
      throw Exception('Network error: Cannot connect to backend at $baseUrl. Please ensure the backend server is running.');
    } catch (e) {
      print('❌ Error creating LiveKit room: $e');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error creating LiveKit room: $e');
    }
  }

  /// Get LiveKit access token for joining a meeting by stream ID
  Future<Map<String, dynamic>> getLiveKitMeetingToken(
    int streamId, {
    required String userIdentity,
    required String userName,
    String? userEmail,
    bool isHost = false,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/live/streams/$streamId/livekit-token');
      final body = <String, dynamic>{
        'identity': userIdentity,
        'name': userName,
      };
      if (userEmail != null && userEmail.isNotEmpty) {
        body['email'] = userEmail;
      }

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get LiveKit meeting token: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error getting LiveKit meeting token: $e');
    }
  }

  /// Get LiveKit access token for joining a meeting by room name
  Future<Map<String, dynamic>> getLiveKitMeetingTokenByRoom(
    String roomName, {
    required String userIdentity,
    required String userName,
    String? userEmail,
    bool isHost = false,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/live/streams/by-room/$roomName/livekit-token');
      final body = <String, dynamic>{
        'identity': userIdentity,
        'name': userName,
      };
      if (userEmail != null && userEmail.isNotEmpty) {
        body['email'] = userEmail;
      }

      final response = await http.post(
        url,
        headers: await _getHeaders(),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to get LiveKit meeting token by room: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error getting LiveKit meeting token by room: $e');
    }
  }

  /// Convert Podcast to ContentItem for display
  ContentItem podcastToContentItem(Podcast podcast, {String? categoryName}) {
    final audioUrl = podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty
        ? getMediaUrl(podcast.audioUrl!)
        : null;
    final videoUrl = podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty
        ? getMediaUrl(podcast.videoUrl!)
        : null;

    // Helper to get category name
    String getCategoryName(int? categoryId) {
      switch (categoryId) {
        case 1: return 'Sermons';
        case 2: return 'Bible Study';
        case 3: return 'Devotionals';
        case 4: return 'Prayer';
        case 5: return 'Worship';
        case 6: return 'Gospel';
        default: return categoryName ?? 'Podcast';
      }
    }

    return ContentItem(
      id: podcast.id.toString(),
      title: podcast.title,
      creator: 'Christ Tabernacle',
      description: podcast.description,
      coverImage: podcast.coverImage != null ? getMediaUrl(podcast.coverImage!) : null,
      audioUrl: audioUrl,
      videoUrl: videoUrl,
      duration: podcast.duration != null ? Duration(seconds: podcast.duration!) : null,
      category: getCategoryName(podcast.categoryId),
      plays: podcast.playsCount,
      createdAt: podcast.createdAt,
      isFavorite: false,
      isMovie: false,
    );
  }

  /// Generate thumbnail from video
  Future<String> generateThumbnailFromVideo(
    String videoUrl, {
    double? timestamp,
  }) async {
    try {
      final queryParams = <String, String>{
        'video_url': videoUrl,
      };
      if (timestamp != null) {
        queryParams['timestamp'] = timestamp.toString();
      }

      final uri = Uri.parse('$baseUrl/upload/thumbnail/generate-from-video')
          .replace(queryParameters: queryParams);

      final response = await http.post(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['thumbnail_url'] as String;
      }
      throw Exception('Failed to generate thumbnail: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error generating thumbnail: $e');
    }
  }

  /// Get list of default thumbnails
  Future<List<String>> getDefaultThumbnails() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/upload/thumbnail/defaults'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final thumbnails = data['thumbnails'] as List;
        return thumbnails.cast<String>();
      }
      throw Exception('Failed to get default thumbnails: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting default thumbnails: $e');
    }
  }

  /// Upload custom thumbnail
  Future<String> uploadThumbnail(String filePath, {List<int>? bytes, String? fileName}) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/thumbnail');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      request.headers.remove('Content-Type'); // Let multipart set it

      // Add file - handle both file path and bytes (for web)
      if (bytes != null && fileName != null) {
        request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: fileName),
        );
      } else {
        final file = await http.MultipartFile.fromPath('file', filePath);
        request.files.add(file);
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['url'] as String;
      }
      throw Exception('Failed to upload thumbnail: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error uploading thumbnail: $e');
    }
  }

  /// Upload audio file
  Future<Map<String, dynamic>> uploadAudio(String filePath) async {
    return await uploadFile(filePath, 'audio');
  }

  /// Upload audio file from bytes (for web)
  Future<Map<String, dynamic>> uploadAudioFromBytes(
    List<int> bytes,
    String fileName,
  ) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/audio');
      final request = http.MultipartRequest('POST', uri);
      
      // Add auth headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);
      request.headers.remove('Content-Type'); // Let multipart set it

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        // Convert 'url' to 'file_path' for consistency
        if (data.containsKey('url') && !data.containsKey('file_path')) {
          data['file_path'] = data['url'];
        }
        return data;
      }
      throw Exception('Failed to upload audio: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error uploading audio: $e');
    }
  }

  /// Upload video file
  /// Upload temporary media file (for persistence across page refresh)
  /// Used for blob URLs that need to be converted to backend URLs
  /// Upload temporary media file (for persistence across page refresh)
  /// Used for blob URLs that need to be converted to backend URLs
  /// Does NOT require bank details - only authentication
  Future<Map<String, dynamic>?> uploadTemporaryMedia(String sourcePath, String mediaType) async {
    try {
      // mediaType should be 'audio' or 'video'
      if (mediaType != 'audio' && mediaType != 'video') {
        throw Exception('Invalid media type. Must be "audio" or "video"');
      }

      Map<String, dynamic> result;
      
      if (mediaType == 'audio') {
        // Use temporary audio endpoint (no bank details required)
        final file = await _createMultipartFileFromSource(sourcePath, 'file', 'audio.webm');
        final request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload/temporary-audio'));
        request.files.add(file);
        request.headers.addAll(await _getHeaders());
        request.headers.remove('Content-Type'); // Let multipart set it
        
        final streamedResponse = await request.send().timeout(const Duration(minutes: 10));
        
        if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
          final response = await http.Response.fromStream(streamedResponse);
          result = json.decode(response.body) as Map<String, dynamic>;
          if (result.containsKey('url') && !result.containsKey('file_path')) {
            result['file_path'] = result['url'];
          }
        } else {
          final response = await http.Response.fromStream(streamedResponse);
          throw Exception('Failed to upload temporary audio: HTTP ${streamedResponse.statusCode} ${response.body}');
        }
      } else {
        // Video - use regular upload endpoint for now (may need temporary-video endpoint later)
        result = await uploadVideo(sourcePath, generateThumbnail: false);
      }

      // Return full response including duration, url, and file_path
      final url = result['url'] as String?;
      if (url == null || url.isEmpty) {
        throw Exception('No URL returned from temporary media upload');
      }

      final duration = result['duration'] as int?;
      print('✅ Temporary $mediaType uploaded successfully: $url${duration != null ? " (duration: ${duration}s)" : ""}');
      
      return {
        'url': url,
        'file_path': result['file_path'] ?? url,
        'duration': duration,
        'filename': result['filename'],
        'content_type': result['content_type'],
      };
    } catch (e) {
      print('❌ Error uploading temporary $mediaType: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> uploadVideo(
    String filePath, {
    bool generateThumbnail = true,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      final file = await _createMultipartFileFromSource(filePath, 'file', 'video.mp4');
      final uri = Uri.parse('$baseUrl/upload/video?generate_thumbnail=$generateThumbnail');
      final request = http.MultipartRequest('POST', uri);
      request.files.add(file);
      final headers = await _getHeaders();
      headers.remove('Content-Type'); // Let multipart set it
      request.headers.addAll(headers);
      
      // Get file size for progress tracking
      int? totalBytes = file.length;
      
      // Notify start of upload if callback provided
      if (onProgress != null && totalBytes != null) {
        onProgress(0, totalBytes);
      }
      
      // Increase timeout to 60 minutes for large movies
      final streamedResponse = await request.send().timeout(const Duration(minutes: 60));
      
      // Note: Tracking actual upload progress requires wrapping the request body stream,
      // which is complex. For now, we'll notify completion when response is received.
      // The backend will handle the actual upload, and we'll report completion here.
      
      if (streamedResponse.statusCode == 200 || streamedResponse.statusCode == 201) {
        final response = await http.Response.fromStream(streamedResponse);
        final data = json.decode(response.body) as Map<String, dynamic>;
        
        // Notify completion if callback provided
        if (onProgress != null && totalBytes != null) {
          onProgress(totalBytes, totalBytes);
        }
        
        return data;
      }
      throw Exception('Failed to upload video: HTTP ${streamedResponse.statusCode}');
    } catch (e) {
      throw Exception('Error uploading video: $e');
    }
  }

  /// Get media file duration from backend (uses FFprobe)
  /// [mediaPath] - Path to media file (e.g., /media/audio/file.webm or audio/file.webm)
  Future<int?> getMediaDuration(String mediaPath) async {
    try {
      // Normalize path - ensure it's a relative path
      String cleanPath = mediaPath;
      if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
        // Extract path from URL
        final uri = Uri.parse(cleanPath);
        cleanPath = uri.path;
      }
      
      // Remove leading slash
      cleanPath = cleanPath.startsWith('/') ? cleanPath.substring(1) : cleanPath;
      
      final response = await http.get(
        Uri.parse('$baseUrl/upload/media/duration?path=$cleanPath'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final duration = data['duration'] as int?;
        if (duration != null && duration > 0) {
          print('✅ Duration from backend (FFprobe): ${duration}s for $mediaPath');
          return duration;
        } else {
          // Duration is null - this is valid for WebM files without metadata
          print('⚠️ Backend returned null duration for $mediaPath (WebM file may be missing duration metadata)');
          return null;
        }
      } else if (response.statusCode == 404) {
        print('⚠️ Media file not found for duration: $mediaPath');
        return null;
      } else {
        print('⚠️ Failed to get duration from backend: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting media duration from backend: $e');
      return null;
    }
    return null;
  }

  /// Create podcast with thumbnail support
  Future<Map<String, dynamic>> createPodcast({
    required String title,
    String? description,
    String? audioUrl,
    String? videoUrl,
    String? coverImage,
    bool useDefaultThumbnail = false,
    int? categoryId,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        if (description != null) 'description': description,
        if (audioUrl != null) 'audio_url': audioUrl,
        if (videoUrl != null) 'video_url': videoUrl,
        if (coverImage != null) 'cover_image': coverImage,
        'use_default_thumbnail': useDefaultThumbnail,
        if (categoryId != null) 'category_id': categoryId,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/podcasts/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create podcast: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error creating podcast: $e');
    }
  }

  /// Bulk create podcasts - admin only
  /// Creates multiple podcasts at once with auto-approved status
  Future<List<Map<String, dynamic>>> bulkCreatePodcasts(
    List<Map<String, dynamic>> podcasts,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/podcasts/bulk/'),
        headers: await _getHeaders(),
        body: json.encode(podcasts),
      ).timeout(const Duration(seconds: 120)); // Longer timeout for bulk

      if (response.statusCode == 200 || response.statusCode == 201) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to bulk create podcasts: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error bulk creating podcasts: $e');
    }
  }

  /// Create movie with all metadata fields
  Future<Map<String, dynamic>> createMovie({
    required String title,
    String? description,
    required String videoUrl,
    String? coverImage,
    int? duration,
    String? director,
    String? cast,
    DateTime? releaseDate,
    double? rating,
    int? categoryId,
    bool isFeatured = false,
    String status = 'pending', // Default to pending, but admins can set to 'approved'
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'video_url': videoUrl,
        if (description != null) 'description': description,
        if (coverImage != null) 'cover_image': coverImage,
        if (duration != null) 'duration': duration,
        if (director != null) 'director': director,
        if (cast != null) 'cast': cast,
        if (releaseDate != null) 'release_date': releaseDate.toIso8601String(),
        if (rating != null) 'rating': rating,
        if (categoryId != null) 'category_id': categoryId,
        'is_featured': isFeatured,
        'status': status, // Admins can set to 'approved', others default to 'pending'
      };

      final response = await http.post(
        Uri.parse('$baseUrl/movies/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create movie: HTTP ${response.statusCode} ${response.body}');
    } catch (e) {
      throw Exception('Error creating movie: $e');
    }
  }

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/categories/'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Category.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to load categories: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // ============================================
  // ARTIST API METHODS
  // ============================================

  /// Get artist by ID
  Future<Map<String, dynamic>> getArtist(int artistId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artists/$artistId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Artist not found');
      }
      throw Exception('Failed to get artist: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting artist: $e');
    }
  }

  /// Get artist by user ID
  Future<Map<String, dynamic>> getArtistByUserId(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artists/by-user/$userId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        throw Exception('Artist not found for this user');
      }
      throw Exception('Failed to get artist: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting artist: $e');
    }
  }

  /// Get current user's artist profile (auto-creates if not exists)
  Future<Map<String, dynamic>> getMyArtist() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artists/me'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _handle401Error(response);
        return {};
      }
      throw Exception('Failed to get artist profile: HTTP ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error getting artist profile: $e');
    }
  }

  /// Update artist profile
  Future<Map<String, dynamic>> updateArtist(Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/artists/me'),
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        await _handle401Error(response);
        return {};
      }
      throw Exception('Failed to update artist: HTTP ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error updating artist: $e');
    }
  }

  /// Upload artist cover image
  Future<String> uploadArtistCover(Uint8List imageData, String filename) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/artists/me/cover-image'),
      );

      // Add auth headers
      final headers = await _getHeaders();
      request.headers.addAll(headers);

      // Add file
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageData,
        filename: filename,
      ));

      final streamedResponse = await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data['cover_image'] as String;
      } else if (response.statusCode == 401) {
        await _handle401Error(response);
        return '';
      }
      throw Exception('Failed to upload cover: HTTP ${response.statusCode}');
    } catch (e) {
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error uploading cover: $e');
    }
  }

  /// Get podcasts by artist
  Future<List<ContentItem>> getArtistPodcasts(int artistId, {int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artists/$artistId/podcasts?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => ContentItem.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to get artist podcasts: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting artist podcasts: $e');
    }
  }

  /// Follow an artist
  Future<void> followArtist(int artistId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/artists/$artistId/follow'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await _handle401Error(response);
        }
        throw Exception('Failed to follow artist: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error following artist: $e');
    }
  }

  /// Unfollow an artist
  Future<void> unfollowArtist(int artistId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/artists/$artistId/follow'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        if (response.statusCode == 401) {
          await _handle401Error(response);
        }
        throw Exception('Failed to unfollow artist: HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('session has expired') || e.toString().contains('Authentication failed')) {
        rethrow;
      }
      throw Exception('Error unfollowing artist: $e');
    }
  }

  /// Get artist followers
  Future<List<Map<String, dynamic>>> getArtistFollowers(int artistId, {int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/artists/$artistId/followers?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      throw Exception('Failed to get followers: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting followers: $e');
    }
  }

  // ============ Events API Methods ============

  /// Create a new event
  Future<Map<String, dynamic>> createEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    String? location,
    double? latitude,
    double? longitude,
    int? maxAttendees,
    String? coverImage,
  }) async {
    try {
      final body = <String, dynamic>{
        'title': title,
        'description': description,
        'event_date': eventDate.toIso8601String(),
        'location': location,
        'latitude': latitude,
        'longitude': longitude,
        'max_attendees': maxAttendees ?? 0,
        'cover_image': coverImage,
      }..removeWhere((k, v) => v == null);

      final response = await http.post(
        Uri.parse('$baseUrl/events/'),
        headers: await _getHeaders(),
        body: json.encode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create event: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating event: $e');
    }
  }

  /// Get list of events
  Future<Map<String, dynamic>> getEvents({
    int skip = 0,
    int limit = 20,
    String? statusFilter,
    bool upcomingOnly = false,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (statusFilter != null) queryParams['status_filter'] = statusFilter;
      if (upcomingOnly) queryParams['upcoming_only'] = 'true';

      final uri = Uri.parse('$baseUrl/events/').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch events: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching events: $e');
    }
  }

  /// Get event details by ID
  Future<Map<String, dynamic>> getEvent(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch event: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching event: $e');
    }
  }

  /// Update an event
  Future<Map<String, dynamic>> updateEvent(int eventId, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
        body: json.encode(data),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update event: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating event: $e');
    }
  }

  /// Request to join an event
  Future<Map<String, dynamic>> joinEvent(int eventId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/join'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to join event: HTTP ${response.statusCode} - ${response.body}');
    } catch (e) {
      throw Exception('Error joining event: $e');
    }
  }

  /// Leave an event
  Future<bool> leaveEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId/leave'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error leaving event: $e');
    }
  }

  /// Get event attendees
  Future<List<dynamic>> getEventAttendees(int eventId, {String? statusFilter}) async {
    try {
      var uri = Uri.parse('$baseUrl/events/$eventId/attendees');
      if (statusFilter != null) {
        uri = uri.replace(queryParameters: {'status_filter': statusFilter});
      }

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to fetch attendees: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching attendees: $e');
    }
  }

  /// Update attendee status (approve/reject)
  Future<bool> updateAttendeeStatus(int eventId, int userId, String status) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId/attendees/$userId'),
        headers: await _getHeaders(),
        body: json.encode({'status': status}),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating attendee status: $e');
    }
  }

  /// Get my hosted events
  Future<List<dynamic>> getMyHostedEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/my/hosted'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to fetch hosted events: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching hosted events: $e');
    }
  }

  /// Get events I'm attending
  Future<List<dynamic>> getMyAttendingEvents() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/my/attending'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as List<dynamic>;
      }
      throw Exception('Failed to fetch attending events: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching attending events: $e');
    }
  }

  /// Delete/cancel an event
  Future<bool> deleteEvent(int eventId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/events/$eventId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting event: $e');
    }
  }

  // ============ Content Drafts API Methods ============

  /// Create a new content draft (raw API)
  Future<Map<String, dynamic>> createDraft(Map<String, dynamic> draftData) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drafts/'),
        headers: await _getHeaders(),
        body: json.encode(draftData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to create draft: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error creating draft: $e');
    }
  }

  /// Create a new content draft with typed parameters (convenience method)
  Future<Map<String, dynamic>> createContentDraft({
    required String draftType,
    String? title,
    String? description,
    String? originalMediaUrl,
    String? editedMediaUrl,
    String? thumbnailUrl,
    String? content,
    String? category,
    Map<String, dynamic>? editingState,
    int? duration,
    String status = 'editing',
  }) async {
    final draftData = <String, dynamic>{
      'draft_type': draftType,
      'title': title,
      'description': description,
      'original_media_url': originalMediaUrl,
      'edited_media_url': editedMediaUrl,
      'thumbnail_url': thumbnailUrl,
      'content': content,
      'category': category,
      'editing_state': editingState,
      'duration': duration,
      'status': status,
    }..removeWhere((k, v) => v == null);

    return createDraft(draftData);
  }

  /// Get list of user's drafts (raw API)
  Future<Map<String, dynamic>> getDraftsRaw({
    String? draftType,
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (draftType != null) queryParams['draft_type'] = draftType;

      final uri = Uri.parse('$baseUrl/drafts/').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch drafts: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching drafts: $e');
    }
  }

  /// Get list of user's drafts as ContentDraft objects
  Future<List<ContentDraft>> getDrafts({
    String? draftType,
    int skip = 0,
    int limit = 100,
  }) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };
      if (draftType != null) queryParams['draft_type'] = draftType;

      final uri = Uri.parse('$baseUrl/drafts/').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        // Backend returns {drafts: [...], total: ..., skip: ..., limit: ...}
        final List<dynamic> draftsJson = responseData['drafts'] ?? [];
        return draftsJson.map((json) => ContentDraft.fromJson(json as Map<String, dynamic>)).toList();
      }
      throw Exception('Failed to fetch drafts: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching drafts: $e');
    }
  }

  /// Get a specific draft by ID
  Future<Map<String, dynamic>> getDraft(int draftId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/drafts/$draftId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch draft: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching draft: $e');
    }
  }

  /// Update an existing draft
  Future<Map<String, dynamic>> updateDraft(int draftId, Map<String, dynamic> draftData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/drafts/$draftId'),
        headers: await _getHeaders(),
        body: json.encode(draftData),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update draft: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error updating draft: $e');
    }
  }

  /// Delete a draft
  Future<bool> deleteDraft(int draftId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/drafts/$draftId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting draft: $e');
    }
  }

  /// Get drafts by type
  Future<Map<String, dynamic>> getDraftsByType(String draftType, {int skip = 0, int limit = 20}) async {
    try {
      final queryParams = <String, String>{
        'skip': skip.toString(),
        'limit': limit.toString(),
      };

      final uri = Uri.parse('$baseUrl/drafts/type/$draftType').replace(queryParameters: queryParams);
      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch drafts by type: HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching drafts by type: $e');
    }
  }

  // ============ Admin Users API Methods ============

  /// Get all users (admin only)
  Future<List<dynamic>> getUsers({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users?skip=$skip&limit=$limit'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data;
      }
      throw Exception('Failed to get users: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  /// Update user admin status
  Future<bool> updateUserAdmin(int userId, bool isAdmin) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/users/$userId/admin'),
        headers: await _getHeaders(),
        body: json.encode({'is_admin': isAdmin}),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error updating user admin status: $e');
    }
  }

  /// Delete a user (admin only)
  Future<bool> deleteUser(int userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: await _getHeaders(),
      ).timeout(const Duration(seconds: 10));
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}
