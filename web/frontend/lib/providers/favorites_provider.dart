import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/content_item.dart';

class FavoritesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<ContentItem> _favorites = [];
  Set<String> _favoriteIds = {}; // Track favorited content IDs
  bool _isLoading = false;
  String? _error;
  
  List<ContentItem> get favorites => _favorites;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool isFavorite(String contentId) => _favoriteIds.contains(contentId);
  
  /// Map ContentItem category to backend content_type
  String _mapCategoryToContentType(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('podcast')) {
      return 'podcast';
    } else if (lowerCategory.contains('movie')) {
      return 'movie';
    } else if (lowerCategory.contains('music') || lowerCategory.contains('track')) {
      return 'music';
    }
    // Default fallback - try to infer from category
    // If category is empty or unknown, default to 'podcast' for video content
    return 'podcast';
  }
  
  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final data = await _api.getFavorites();
      final List<ContentItem> favoritesList = [];
      final Set<String> favoriteIdsSet = {};
      
      for (final favoriteData in data) {
        final favorite = favoriteData as Map<String, dynamic>;
        final content = favorite['content'] as Map<String, dynamic>?;
        final contentType = favorite['content_type'] as String;
        final contentId = favorite['content_id'] as int;
        
        if (content != null) {
          // Convert API response to ContentItem
          ContentItem? item;
          
          if (contentType == 'podcast') {
            // Fetch full podcast to convert properly
            try {
              final podcast = await _api.getPodcast(contentId);
              item = _api.podcastToContentItem(podcast, categoryName: 'Podcast');
            } catch (e) {
              // If podcast fetch fails, create basic ContentItem from content data
              item = ContentItem(
                id: contentId.toString(),
                title: content['title'] as String? ?? 'Unknown',
                creator: 'Christ Tabernacle',
                description: content['description'] as String?,
                coverImage: content['cover_image'] as String?,
                audioUrl: content['audio_url'] as String?,
                videoUrl: content['video_url'] as String?,
                duration: content['duration'] != null
                    ? Duration(seconds: content['duration'] as int)
                    : null,
                category: 'Podcast',
                createdAt: DateTime.now(),
                isFavorite: true,
              );
            }
          } else if (contentType == 'movie') {
            // Fetch full movie to convert properly
            try {
              final movie = await _api.getMovie(contentId);
              item = _api.movieToContentItem(movie, categoryName: 'Movies');
            } catch (e) {
              // If movie fetch fails, create basic ContentItem from content data
              item = ContentItem(
                id: contentId.toString(),
                title: content['title'] as String? ?? 'Unknown',
                creator: 'Christ Tabernacle',
                description: content['description'] as String?,
                coverImage: content['cover_image'] as String?,
                videoUrl: content['video_url'] as String?,
                duration: content['duration'] != null
                    ? Duration(seconds: content['duration'] as int)
                    : null,
                category: 'Movies',
                createdAt: DateTime.now(),
                isFavorite: true,
                isMovie: true,
              );
            }
          } else if (contentType == 'music') {
            // For music, create ContentItem from content data
            item = ContentItem(
              id: contentId.toString(),
              title: content['title'] as String? ?? 'Unknown',
              creator: 'Artist',
              coverImage: content['cover_image'] as String?,
              audioUrl: content['audio_url'] as String?,
              duration: content['duration'] != null
                  ? Duration(seconds: content['duration'] as int)
                  : null,
              category: 'Music',
              createdAt: DateTime.now(),
              isFavorite: true,
            );
          }
          
          if (item != null) {
            favoritesList.add(item);
            favoriteIdsSet.add(item.id);
          }
        } else {
          // If content is null, still track the favorite ID
          favoriteIdsSet.add(contentId.toString());
        }
      }
      
      _favorites = favoritesList;
      _favoriteIds = favoriteIdsSet;
      _error = null;
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      print('Error fetching favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> checkFavoriteStatus(ContentItem item) async {
    try {
      final contentType = _mapCategoryToContentType(item.category);
      final isFavorited = await _api.checkFavorite(
        contentType,
        int.parse(item.id),
      );
      
      if (isFavorited && !_favoriteIds.contains(item.id)) {
        _favoriteIds.add(item.id);
        if (!_favorites.any((f) => f.id == item.id)) {
          _favorites.add(item);
        }
        notifyListeners();
      } else if (!isFavorited && _favoriteIds.contains(item.id)) {
        _favoriteIds.remove(item.id);
        _favorites.removeWhere((f) => f.id == item.id);
        notifyListeners();
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }
  
  Future<bool> toggleFavorite(ContentItem item) async {
    final isCurrentlyFavorite = _favoriteIds.contains(item.id);
    final contentType = _mapCategoryToContentType(item.category);
    
    if (isCurrentlyFavorite) {
      // Remove from favorites
      final success = await _api.removeFromFavorites(
        contentType,
        int.parse(item.id),
      );
      if (success) {
        _favorites.removeWhere((f) => f.id == item.id);
        _favoriteIds.remove(item.id);
        notifyListeners();
      }
      return success;
    } else {
      // Add to favorites
      final success = await _api.addToFavorites(
        contentType,
        int.parse(item.id),
      );
      if (success) {
        _favorites.add(item);
        _favoriteIds.add(item.id);
        notifyListeners();
      }
      return success;
    }
  }
}

