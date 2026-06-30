import 'package:url_launcher/url_launcher.dart';

/// Returns true only for https URLs (blocks javascript:, data:, file:, etc.).
bool isAllowedExternalUrl(Uri uri) {
  return uri.scheme == 'https' && uri.host.isNotEmpty;
}

/// Launch an external URL only when it uses an allowed https scheme.
Future<bool> launchAllowedUrl(
  String url, {
  LaunchMode mode = LaunchMode.externalApplication,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !isAllowedExternalUrl(uri)) {
    return false;
  }
  if (!await canLaunchUrl(uri)) {
    return false;
  }
  return launchUrl(uri, mode: mode);
}
