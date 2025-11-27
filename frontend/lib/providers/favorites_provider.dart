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
  
  Future<void> fetchFavorites() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      // TODO: Parse favorites into ContentItem list when API returns actual data
      // final data = await _api.getFavorites();
      _favorites = [];
      _favoriteIds = {};
      _error = null;
    } catch (e) {
      _error = 'Failed to load favorites: $e';
      print('Error fetching favorites: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<bool> toggleFavorite(ContentItem item) async {
    final isCurrentlyFavorite = _favoriteIds.contains(item.id);
    
    if (isCurrentlyFavorite) {
      // Remove from favorites
      final success = await _api.removeFromFavorites(
        item.category,
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
        item.category,
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

