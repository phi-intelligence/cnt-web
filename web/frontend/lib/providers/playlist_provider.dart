import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/content_item.dart';

/// Simple playlist model for the provider
class Playlist {
  final int id;
  final String name;
  final String? description;
  final String? thumbnailUrl;
  final int itemCount;

  Playlist({
    required this.id,
    required this.name,
    this.description,
    this.thumbnailUrl,
    this.itemCount = 0,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnail_url'] as String?,
      itemCount: json['item_count'] as int? ?? json['items']?.length ?? 0,
    );
  }
}

class PlaylistProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Playlist> _playlists = [];
  bool _isLoading = false;
  String? _error;

  List<Playlist> get playlists => _playlists;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPlaylists() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getPlaylists();
      _playlists = (data).map((json) => Playlist.fromJson(json)).toList();
      _error = null;
    } catch (e) {
      _error = 'Failed to load playlists: $e';
      print('Error fetching playlists: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Playlist?> createPlaylist(String name, {String? description}) async {
    try {
      final data = await _api.createPlaylist(
        name: name,
        description: description,
      );
      final playlist = Playlist.fromJson(data);
      _playlists.insert(0, playlist);
      notifyListeners();
      return playlist;
    } catch (e) {
      _error = 'Failed to create playlist: $e';
      notifyListeners();
      return null;
    }
  }

  /// Map frontend category to backend content type
  String _mapCategoryToContentType(String category, ContentItem item) {
    // Check if it's a movie based on isMovie flag or category
    if (item.isMovie ||
        category == 'Movies' ||
        category == 'Kids Bible Stories') {
      return 'movie';
    }

    // Check if it's a video podcast (has videoUrl)
    if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
      // Could be video podcast or movie - check category
      if (category == 'Movies' || category == 'Kids Bible Stories') {
        return 'movie';
      }
      return 'video_podcast';
    }

    // Check if it's an audio podcast (has audioUrl but no videoUrl)
    if (item.audioUrl != null && item.audioUrl!.isNotEmpty) {
      return 'audio_podcast';
    }

    // Check category names for podcasts
    final podcastCategories = [
      'Sermons',
      'Bible Study',
      'Devotionals',
      'Prayer',
      'Worship',
      'Gospel',
      'Podcast',
      'Video Podcast',
      'Audio Podcast'
    ];
    if (podcastCategories.contains(category)) {
      // Determine if video or audio based on URLs
      if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
        return 'video_podcast';
      }
      return 'audio_podcast';
    }

    // Default to music if category suggests it, otherwise audio_podcast
    if (category.toLowerCase().contains('music') ||
        category.toLowerCase().contains('song')) {
      return 'music';
    }

    // Default fallback
    return 'audio_podcast';
  }

  Future<bool> addItemToPlaylist(int playlistId, ContentItem item) async {
    try {
      final contentType = _mapCategoryToContentType(item.category, item);
      final success = await _api.addToPlaylist(
        playlistId,
        contentType,
        int.parse(item.id),
      );
      if (success) {
        // Update local playlist item count
        final index = _playlists.indexWhere((p) => p.id == playlistId);
        if (index >= 0) {
          final old = _playlists[index];
          _playlists[index] = Playlist(
            id: old.id,
            name: old.name,
            description: old.description,
            thumbnailUrl: old.thumbnailUrl,
            itemCount: old.itemCount + 1,
          );
          notifyListeners();
        }
      }
      return success;
    } catch (e) {
      _error = 'Failed to add to playlist: $e';
      return false;
    }
  }

  Future<bool> addToPlaylist(
      int playlistId, String contentType, int contentId) async {
    final success =
        await _api.addToPlaylist(playlistId, contentType, contentId);
    if (success) {
      // Refresh playlists to get updated item count
      await fetchPlaylists();
    }
    return success;
  }
}
