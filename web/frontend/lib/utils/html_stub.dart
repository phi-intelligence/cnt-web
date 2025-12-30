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

/// Stub Window class for mobile platform
class Window {
  final Storage localStorage = _StorageStub();
  final Storage sessionStorage = _StorageStub();
}

/// Stub Storage class for mobile platform
class _StorageStub implements Storage {
  @override
  String? operator [](String key) => null;
  
  @override
  void operator []=(String key, String value) {
    throw UnsupportedError('localStorage is not supported on mobile platform');
  }
  
  @override
  void clear() {
    throw UnsupportedError('localStorage is not supported on mobile platform');
  }
  
  @override
  String? remove(String key) => null;
  
  @override
  int get length => 0;
  
  @override
  String? key(int index) => null;
}

/// Stub Storage interface for mobile platform
abstract class Storage {
  String? operator [](String key);
  void operator []=(String key, String value);
  void clear();
  String? remove(String key);
  int get length;
  String? key(int index);
}

/// Global window instance (stub for mobile)
final window = Window();

/// Stub Blob class for mobile platform
class Blob {
  final List<dynamic> data;
  final String? type;
  
  Blob(this.data, [this.type]);
}

/// Stub Url class for mobile platform
class Url {
  static String createObjectUrlFromBlob(Blob blob) {
    throw UnsupportedError('createObjectUrlFromBlob is not supported on mobile platform');
  }
  
  static void revokeObjectUrl(String url) {
    // No-op on mobile
  }
}

