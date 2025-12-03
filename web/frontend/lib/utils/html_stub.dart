// Stub file for mobile platform - HTML operations are not available on mobile
// This file is only used when compiling for mobile to avoid import errors

/// Stub HttpRequest class for mobile platform
class HttpRequest {
  final int status;
  final dynamic response;
  
  HttpRequest._(this.status, this.response);
  
  static Future<HttpRequest> request(
    String url, {
    String? responseType,
  }) async {
    // Stub implementation - should never be called on mobile
    throw UnsupportedError('HttpRequest.request is not supported on mobile platform');
  }
}

