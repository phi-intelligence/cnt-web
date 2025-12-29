import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional import for web-specific code
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;
import 'logger_service.dart';

/// Web storage service that supports both session storage and local storage
/// For Netflix-style behavior: session storage logs out on browser close,
/// local storage persists across browser sessions ("Remember Me" mode)
class WebStorageService {
  static const String _rememberMeKey = 'remember_me';
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userKey = 'user_data';
  
  /// Check if we're on web platform
  static bool get isWeb => kIsWeb;
  
  /// Check if "Remember Me" is enabled
  static bool get rememberMeEnabled {
    if (!isWeb) return true; // On non-web, always persist
    try {
      // Check localStorage for remember me preference (always stored in localStorage)
      final value = html.window.localStorage[_rememberMeKey];
      return value == 'true';
    } catch (e) {
      LoggerService.e('Error reading remember me preference: $e');
      return false;
    }
  }
  
  /// Set "Remember Me" preference
  static void setRememberMe(bool value) {
    if (!isWeb) return;
    try {
      // Always store this in localStorage so we know the preference on page load
      html.window.localStorage[_rememberMeKey] = value.toString();
    } catch (e) {
      LoggerService.e('Error setting remember me preference: $e');
    }
  }
  
  /// Get the appropriate storage based on "Remember Me" setting
  static html.Storage get _storage {
    if (rememberMeEnabled) {
      return html.window.localStorage; // Persists across browser sessions
    } else {
      return html.window.sessionStorage; // Cleared on browser/tab close
    }
  }
  
  /// Write a value to storage
  static Future<void> write({required String key, required String? value}) async {
    if (!isWeb) return;
    try {
      if (value == null) {
        _storage.remove(key);
      } else {
        _storage[key] = value;
      }
    } catch (e) {
      LoggerService.e('WebStorageService: Error writing $key: $e');
    }
  }
  
  /// Read a value from storage
  static Future<String?> read({required String key}) async {
    if (!isWeb) return null;
    try {
      // First check the current storage based on rememberMe
      String? value = _storage[key];
      
      // If not found and in session storage, also check localStorage
      // (for migration from old sessions)
      if (value == null && !rememberMeEnabled) {
        value = html.window.localStorage[key];
        if (value != null) {
          // Migrate to session storage and clear from localStorage
          html.window.sessionStorage[key] = value;
          html.window.localStorage.remove(key);
        }
      }
      
      return value;
    } catch (e) {
      LoggerService.e('WebStorageService: Error reading $key: $e');
      return null;
    }
  }
  
  /// Delete a value from both storages (to ensure complete cleanup)
  static Future<void> delete({required String key}) async {
    if (!isWeb) return;
    try {
      html.window.localStorage.remove(key);
      html.window.sessionStorage.remove(key);
    } catch (e) {
      LoggerService.e('WebStorageService: Error deleting $key: $e');
    }
  }
  
  /// Clear all auth data from both storages
  static Future<void> clearAuthData() async {
    if (!isWeb) return;
    try {
      // Clear from both storages
      for (final key in [_tokenKey, _refreshTokenKey, _userKey]) {
        html.window.localStorage.remove(key);
        html.window.sessionStorage.remove(key);
      }
      // Keep remember_me preference - only in localStorage
    } catch (e) {
      LoggerService.e('WebStorageService: Error clearing auth data: $e');
    }
  }
  
  /// Migrate existing tokens to appropriate storage based on remember me setting
  /// Call this on app startup
  static Future<void> migrateStorage() async {
    if (!isWeb) return;
    
    try {
      final shouldRemember = rememberMeEnabled;
      
      // If remember me is disabled, move tokens from localStorage to sessionStorage
      if (!shouldRemember) {
        for (final key in [_tokenKey, _refreshTokenKey, _userKey]) {
          final value = html.window.localStorage[key];
          if (value != null) {
            html.window.sessionStorage[key] = value;
            html.window.localStorage.remove(key);
            LoggerService.i('Migrated $key from localStorage to sessionStorage');
          }
        }
      }
      // If remember me is enabled, move tokens from sessionStorage to localStorage
      else {
        for (final key in [_tokenKey, _refreshTokenKey, _userKey]) {
          final value = html.window.sessionStorage[key];
          if (value != null) {
            html.window.localStorage[key] = value;
            html.window.sessionStorage.remove(key);
            LoggerService.i('Migrated $key from sessionStorage to localStorage');
          }
        }
      }
    } catch (e) {
      LoggerService.e('WebStorageService: Error migrating storage: $e');
    }
  }
}

