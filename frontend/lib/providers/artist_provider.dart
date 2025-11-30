import 'package:flutter/foundation.dart';
import '../models/artist.dart';
import '../models/content_item.dart';
import '../services/api_service.dart';

class ArtistProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Current user's artist profile
  Artist? _myArtist;
  bool _myArtistLoading = false;
  String? _myArtistError;

  // Cached artist profiles (viewed by user)
  final Map<int, Artist> _artistCache = {};
  final Map<int, bool> _artistLoading = {};
  final Map<int, String?> _artistErrors = {};

  // Cached artist podcasts
  final Map<int, List<ContentItem>> _artistPodcastsCache = {};
  final Map<int, bool> _artistPodcastsLoading = {};

  // Getters
  Artist? get myArtist => _myArtist;
  bool get myArtistLoading => _myArtistLoading;
  String? get myArtistError => _myArtistError;

  Artist? getArtist(int artistId) => _artistCache[artistId];
  bool isArtistLoading(int artistId) => _artistLoading[artistId] ?? false;
  String? getArtistError(int artistId) => _artistErrors[artistId];

  List<ContentItem>? getArtistPodcasts(int artistId) => _artistPodcastsCache[artistId];
  bool isArtistPodcastsLoading(int artistId) => _artistPodcastsLoading[artistId] ?? false;

  /// Fetch current user's artist profile
  Future<void> fetchMyArtist() async {
    if (_myArtistLoading) return;

    _myArtistLoading = true;
    _myArtistError = null;
    notifyListeners();

    try {
      final data = await _apiService.getMyArtist();
      _myArtist = Artist.fromJson(data);
      _myArtistError = null;
    } catch (e) {
      _myArtistError = e.toString();
      print('Error fetching my artist: $e');
    } finally {
      _myArtistLoading = false;
      notifyListeners();
    }
  }

  /// Fetch artist by ID
  Future<void> fetchArtist(int artistId, {bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (_artistCache.containsKey(artistId) && !forceRefresh) {
      return;
    }

    if (_artistLoading[artistId] == true) return;

    _artistLoading[artistId] = true;
    _artistErrors[artistId] = null;
    notifyListeners();

    try {
      final data = await _apiService.getArtist(artistId);
      _artistCache[artistId] = Artist.fromJson(data);
      _artistErrors[artistId] = null;
    } catch (e) {
      _artistErrors[artistId] = e.toString();
      print('Error fetching artist $artistId: $e');
    } finally {
      _artistLoading[artistId] = false;
      notifyListeners();
    }
  }

  /// Fetch artist by user ID
  Future<Artist?> fetchArtistByUserId(int userId) async {
    try {
      final data = await _apiService.getArtistByUserId(userId);
      final artist = Artist.fromJson(data);
      // Cache it
      _artistCache[artist.id] = artist;
      notifyListeners();
      return artist;
    } catch (e) {
      print('Error fetching artist by user ID $userId: $e');
      return null;
    }
  }

  /// Update artist profile
  Future<bool> updateArtist({
    String? artistName,
    String? bio,
    Map<String, String>? socialLinks,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (artistName != null) data['artist_name'] = artistName;
      if (bio != null) data['bio'] = bio;
      if (socialLinks != null) data['social_links'] = socialLinks;

      final response = await _apiService.updateArtist(data);
      _myArtist = Artist.fromJson(response);
      notifyListeners();
      return true;
    } catch (e) {
      print('Error updating artist: $e');
      return false;
    }
  }

  /// Upload artist cover image
  Future<bool> uploadCoverImage(Uint8List imageData, String filename) async {
    try {
      final coverUrl = await _apiService.uploadArtistCover(imageData, filename);
      // Update local artist object
      if (_myArtist != null) {
        // Fetch updated artist profile to get the new cover image
        await fetchMyArtist();
      }
      return true;
    } catch (e) {
      print('Error uploading cover image: $e');
      return false;
    }
  }

  /// Fetch artist podcasts
  Future<void> fetchArtistPodcasts(int artistId, {bool forceRefresh = false}) async {
    // Return cached if available and not forcing refresh
    if (_artistPodcastsCache.containsKey(artistId) && !forceRefresh) {
      return;
    }

    if (_artistPodcastsLoading[artistId] == true) return;

    _artistPodcastsLoading[artistId] = true;
    notifyListeners();

    try {
      final podcasts = await _apiService.getArtistPodcasts(artistId);
      _artistPodcastsCache[artistId] = podcasts;
    } catch (e) {
      print('Error fetching artist podcasts: $e');
    } finally {
      _artistPodcastsLoading[artistId] = false;
      notifyListeners();
    }
  }

  /// Follow an artist
  Future<bool> followArtist(int artistId) async {
    try {
      await _apiService.followArtist(artistId);
      
      // Update local cache
      final artist = _artistCache[artistId];
      if (artist != null) {
        // Refresh artist to get updated follower count
        await fetchArtist(artistId, forceRefresh: true);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error following artist: $e');
      return false;
    }
  }

  /// Unfollow an artist
  Future<bool> unfollowArtist(int artistId) async {
    try {
      await _apiService.unfollowArtist(artistId);
      
      // Update local cache
      final artist = _artistCache[artistId];
      if (artist != null) {
        // Refresh artist to get updated follower count
        await fetchArtist(artistId, forceRefresh: true);
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('Error unfollowing artist: $e');
      return false;
    }
  }

  /// Clear cache
  void clearCache() {
    _artistCache.clear();
    _artistLoading.clear();
    _artistErrors.clear();
    _artistPodcastsCache.clear();
    _artistPodcastsLoading.clear();
    notifyListeners();
  }

  /// Clear user's artist profile
  void clearMyArtist() {
    _myArtist = null;
    _myArtistError = null;
    notifyListeners();
  }
}

