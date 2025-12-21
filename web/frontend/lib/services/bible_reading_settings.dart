import 'dart:convert';
import 'web_storage_service.dart';

/// Bible Reading Settings stored in WebStorageService (localStorage/sessionStorage)
/// Provides persistence for zoom level, reading position, and bookmarks
class BibleReadingSettings {
  static const String _keyZoomLevel = 'bible_zoom_level';
  static const String _keyLastPage = 'bible_last_page_';
  static const String _keyBookmarks = 'bible_bookmarks_';
  
  /// Get zoom level (default: 1.0)
  static Future<double> getZoomLevel() async {
    final value = await WebStorageService.read(key: _keyZoomLevel);
    return value != null ? double.tryParse(value) ?? 1.0 : 1.0;
  }
  
  /// Set zoom level
  static Future<void> setZoomLevel(double zoom) async {
    await WebStorageService.write(key: _keyZoomLevel, value: zoom.toString());
  }
  
  /// Get last page for document
  static Future<int> getLastPage(int documentId) async {
    final key = '$_keyLastPage$documentId';
    final value = await WebStorageService.read(key: key);
    return value != null ? int.tryParse(value) ?? 1 : 1;
  }
  
  /// Set last page for document
  static Future<void> setLastPage(int documentId, int page) async {
    final key = '$_keyLastPage$documentId';
    await WebStorageService.write(key: key, value: page.toString());
  }
  
  /// Get bookmarks for document
  static Future<List<int>> getBookmarks(int documentId) async {
    final key = '$_keyBookmarks$documentId';
    final value = await WebStorageService.read(key: key);
    if (value == null) return [];
    try {
      final List<dynamic> decoded = json.decode(value);
      return decoded.map((e) => int.tryParse(e.toString()) ?? 0)
          .where((p) => p > 0).toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Set bookmarks for document
  static Future<void> setBookmarks(int documentId, List<int> bookmarks) async {
    final key = '$_keyBookmarks$documentId';
    await WebStorageService.write(
      key: key,
      value: json.encode(bookmarks),
    );
  }
}

