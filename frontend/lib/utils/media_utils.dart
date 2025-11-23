import '../services/api_service.dart';

String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  if (path.startsWith('/')) {
    return '${ApiService.mediaBaseUrl}$path';
  }
  return '${ApiService.mediaBaseUrl}/$path';
}

