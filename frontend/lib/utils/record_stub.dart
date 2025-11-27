// Stub file for web platform - record package not available on web
// This file is only used when compiling for web to avoid import errors

/// Stub AudioRecorder class for web platform
class AudioRecorder {
  Future<bool> hasPermission() async => false;
  Future<void> start({required RecordConfig config, required String path}) async {}
  Future<void> pause() async {}
  Future<void> resume() async {}
  Future<String?> stop() async => null;
  void dispose() {}
}

/// Stub RecordConfig class
class RecordConfig {
  final AudioEncoder encoder;
  final int bitRate;
  final int sampleRate;
  const RecordConfig({
    required this.encoder,
    required this.bitRate,
    required this.sampleRate,
  });
}

/// Stub AudioEncoder enum
enum AudioEncoder {
  aacLc,
}

