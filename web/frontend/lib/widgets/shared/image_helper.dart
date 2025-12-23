import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Helper class to create ImageProvider that handles both network and asset images
class ImageHelper {
  /// Creates an appropriate ImageProvider based on the image URL/path
  /// - If it starts with 'http://' or 'https://', uses NetworkImage
  /// - If it starts with 'assets/', uses AssetImage
  /// - Otherwise, treats it as a relative path and constructs full URL with media base URL
  static ImageProvider getImageProvider(String? imageUrl, {String? fallbackAsset}) {
    if (imageUrl == null || imageUrl.isEmpty) {
      if (fallbackAsset != null) {
        return AssetImage(fallbackAsset);
      }
      // Return a placeholder (we'll handle this in the widget)
      return const AssetImage('assets/images/thumbnail1.jpg');
    }
    
    // Check if it's an asset path
    if (imageUrl.startsWith('assets/')) {
      return AssetImage(imageUrl);
    }
    
    // Check if it's a network URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl);
    }
    
    // For relative paths from backend, use centralized media URL resolver (matches mobile implementation)
    final fullUrl = ApiService().getMediaUrl(imageUrl);
    return NetworkImage(fullUrl);
  }
  
  /// Get fallback asset image based on index
  /// Cycles through available thumbnail assets
  static String getFallbackAsset(int index) {
    final thumbnails = [
      'assets/images/thumbnail1.jpg',
      'assets/images/thumb2.jpg',
      'assets/images/thumb3.jpg',
      'assets/images/thumb4.jpg',
      'assets/images/thumb5.jpg',
      'assets/images/thumb6.jpg',
      'assets/images/thumb7.jpg',
      'assets/images/thumb8.jpg',
    ];
    return thumbnails[index % thumbnails.length];
  }
}

