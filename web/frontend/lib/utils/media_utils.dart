import '../services/api_service.dart';

String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  
  // Get media base URL and validate
  String mediaBase;
  try {
    mediaBase = ApiService.mediaBaseUrl;
  } catch (e) {
    print('❌ Error getting media base URL: $e');
    return null;
  }
  
  if (mediaBase.isEmpty) {
    print('❌ MEDIA_BASE_URL is empty, cannot resolve media URL for: $path');
    return null;
  }
  
  // Remove leading slash if present to avoid double slashes
  String cleanPath = path.startsWith('/') ? path.substring(1) : path;
  
  // Paths starting with 'images/' or 'documents/' are direct S3/CloudFront paths
  // These are direct S3 keys like: images/quotes/quote_13.jpg or documents/bible.pdf
  if (cleanPath.startsWith('images/') || cleanPath.startsWith('documents/')) {
    return '$mediaBase/$cleanPath';
  }
  
  // If path starts with '/', prepend mediaBaseUrl
  if (path.startsWith('/')) {
    return '$mediaBase$path';
  }
  
  return '$mediaBase/$path';
}

