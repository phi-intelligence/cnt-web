import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/content_item.dart';
import '../models/api_models.dart';

class SearchProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  
  List<ContentItem> _results = [];
  List<String> _recentSearches = [];
  bool _isLoading = false;
  String? _error;
  String? _query;
  String? _selectedFilter;
  
  List<ContentItem> get results => _results;
  List<String> get recentSearches => _recentSearches;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get query => _query;
  String? get selectedFilter => _selectedFilter;
  
  SearchProvider() {
    _loadRecentSearches();
  }
  
  Future<void> _loadRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final searches = prefs.getStringList('recent_searches') ?? [];
      _recentSearches = searches.take(10).toList();
      notifyListeners();
    } catch (e) {
      print('Error loading recent searches: $e');
    }
  }
  
  Future<void> _saveRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('recent_searches', _recentSearches);
    } catch (e) {
      print('Error saving recent searches: $e');
    }
  }
  
  Future<void> search(String query, {String? type}) async {
    if (query.trim().isEmpty) {
      clearResults();
      return;
    }
    
    _query = query.trim();
    _selectedFilter = type;
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    // Add to recent searches
    if (!_recentSearches.contains(_query)) {
      _recentSearches.insert(0, _query!);
      _recentSearches = _recentSearches.take(10).toList();
      _saveRecentSearches();
    }
    
    try {
      final data = await _api.searchContent(query: _query!, type: type);
      _results = _parseSearchResults(data);
      _error = null;
    } catch (e) {
      _error = 'Search failed: $e';
      _results = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  List<ContentItem> _parseSearchResults(Map<String, dynamic> data) {
    final List<ContentItem> items = [];
    
    try {
      if (data['podcasts'] != null) {
        final podcasts = data['podcasts'] as List;
        for (var p in podcasts) {
          try {
            if (p is Map<String, dynamic>) {
              final podcast = Podcast.fromJson(p);
              items.add(ContentItem(
                id: podcast.id.toString(),
                title: podcast.title,
                creator: 'Christ Tabernacle',
                description: podcast.description,
                coverImage: _api.getMediaUrl(podcast.coverImage),
                audioUrl: _api.getMediaUrl(podcast.audioUrl),
                duration: podcast.duration != null 
                    ? Duration(seconds: podcast.duration!)
                    : null,
                category: 'Podcast',
                plays: podcast.playsCount,
                createdAt: podcast.createdAt,
              ));
            }
          } catch (e) {
            print('Error parsing podcast: $e');
          }
        }
      }
      
      if (data['music'] != null) {
        final music = data['music'] as List;
        for (var m in music) {
          try {
            if (m is Map<String, dynamic>) {
              final track = MusicTrack.fromJson(m);
              items.add(ContentItem(
                id: track.id.toString(),
                title: track.title,
                creator: track.artist,
                description: track.album,
                coverImage: _api.getMediaUrl(track.coverImage),
                audioUrl: _api.getMediaUrl(track.audioUrl),
                duration: track.duration != null 
                    ? Duration(seconds: track.duration!)
                    : null,
                category: track.genre ?? 'Music',
                plays: track.playsCount,
                createdAt: track.createdAt,
              ));
            }
          } catch (e) {
            print('Error parsing music track: $e');
          }
        }
      }
    } catch (e) {
      print('Error parsing search results: $e');
    }
    
    return items;
  }
  
  void clearResults() {
    _results = [];
    _query = null;
    notifyListeners();
  }
  
  void clearRecentSearches() async {
    _recentSearches = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('recent_searches');
    notifyListeners();
  }
}
