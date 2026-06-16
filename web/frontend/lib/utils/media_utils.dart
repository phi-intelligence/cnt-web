import '../services/api_service.dart';

String? resolveMediaUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  final resolved = ApiService().getMediaUrl(path);
  return resolved.isEmpty ? null : resolved;
}

