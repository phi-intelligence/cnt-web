// Stub file for web platform - path_provider not needed on web
// This file is only used when compiling for web to avoid import errors

/// Stub Directory class
class Directory {
  final String path;
  Directory(this.path);
}

/// Stub getApplicationDocumentsDirectory function
Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('/tmp'); // Stub path
}

