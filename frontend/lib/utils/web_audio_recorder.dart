import 'dart:html' as html;
import 'dart:typed_data';
import 'dart:async';

/// Web-compatible audio recorder using browser MediaRecorder API
/// Provides same interface as record package for mobile
class WebAudioRecorder {
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  List<html.Blob> _recordedChunks = [];
  bool _isRecording = false;
  bool _isPaused = false;
  Completer<String>? _stopCompleter;

  /// Check if microphone permission is available
  Future<bool> hasPermission() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) return false;
      
      // Request microphone access to check permission
      final stream = await mediaDevices.getUserMedia({'audio': true});
      // Stop the test stream immediately
      stream.getTracks().forEach((track) => track.stop());
      return true;
    } catch (e) {
      print('Microphone permission check failed: $e');
      return false;
    }
  }

  /// Start recording audio
  /// Returns the blob URL as a path-like string for compatibility
  Future<String?> start({
    String? path, // Not used on web, but kept for interface compatibility
  }) async {
    try {
      // Get media stream
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception('MediaDevices not available');
      }

      _mediaStream = await mediaDevices.getUserMedia({'audio': true});
      
      // Determine best mime type
      String? mimeType;
      if (html.MediaRecorder.isTypeSupported('audio/webm;codecs=opus')) {
        mimeType = 'audio/webm;codecs=opus';
      } else if (html.MediaRecorder.isTypeSupported('audio/webm')) {
        mimeType = 'audio/webm';
      } else if (html.MediaRecorder.isTypeSupported('audio/ogg')) {
        mimeType = 'audio/ogg';
      }

      // Create MediaRecorder
      _mediaRecorder = html.MediaRecorder(
        _mediaStream!,
        mimeType != null ? {'mimeType': mimeType} : null,
      );
      
      _recordedChunks.clear();
      _isPaused = false;

      // Set up event handlers using addEventListener
      _mediaRecorder!.addEventListener('dataavailable', (html.Event event) {
        final blobEvent = event as html.BlobEvent;
        if (blobEvent.data != null && blobEvent.data!.size > 0) {
          _recordedChunks.add(blobEvent.data!);
        }
      }, false);

      _mediaRecorder!.addEventListener('error', (html.Event event) {
        print('MediaRecorder error: $event');
      }, false);

      _mediaRecorder!.addEventListener('stop', (html.Event event) {
        // When recording stops, create blob and complete
        if (_recordedChunks.isNotEmpty) {
          final blob = html.Blob(_recordedChunks);
          final blobUrl = html.Url.createObjectUrlFromBlob(blob);
          _stopCompleter?.complete(blobUrl);
        } else {
          _stopCompleter?.complete(null);
        }
        _stopCompleter = null;
      }, false);

      // Start recording with timeslice to get data chunks
      _mediaRecorder!.start(100); // Request data every 100ms
      _isRecording = true;

      // Return a placeholder path - actual blob URL will come from stop()
      return 'web_recording_${DateTime.now().millisecondsSinceEpoch}.webm';
    } catch (e) {
      print('Error starting web audio recording: $e');
      await stop();
      rethrow;
    }
  }

  /// Pause recording
  Future<void> pause() async {
    if (_mediaRecorder != null && _isRecording && !_isPaused) {
      _mediaRecorder!.pause();
      _isPaused = true;
    }
  }

  /// Resume recording
  Future<void> resume() async {
    if (_mediaRecorder != null && _isRecording && _isPaused) {
      _mediaRecorder!.resume();
      _isPaused = false;
    }
  }

  /// Stop recording and return the recorded audio file
  /// Returns blob URL as path for compatibility with mobile interface
  Future<String?> stop() async {
    if (_mediaRecorder == null || !_isRecording) {
      return null;
    }

    try {
      // Create completer to wait for stop event
      _stopCompleter = Completer<String>();
      
      // Resume if paused before stopping
      if (_isPaused) {
        _mediaRecorder!.resume();
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Stop the recorder
      _mediaRecorder!.stop();
      _isRecording = false;
      _isPaused = false;

      // Stop all tracks
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _mediaStream = null;

      // Wait for stop event to complete (with timeout)
      String? blobUrl;
      try {
        blobUrl = await _stopCompleter!.future.timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        // If timeout, create blob from existing chunks
        if (_recordedChunks.isNotEmpty) {
          final blob = html.Blob(_recordedChunks);
          blobUrl = html.Url.createObjectUrlFromBlob(blob);
        } else {
          blobUrl = null;
        }
      }

      // Clear chunks
      _recordedChunks.clear();

      return blobUrl; // Return blob URL as path-like string
    } catch (e) {
      print('Error stopping web audio recording: $e');
      _mediaStream?.getTracks().forEach((track) => track.stop());
      _mediaStream = null;
      _recordedChunks.clear();
      _isRecording = false;
      _isPaused = false;
      _stopCompleter = null;
      return null;
    }
  }

  /// Get recorded audio as bytes from blob URL
  Future<Uint8List?> getBytes(String? blobUrl) async {
    if (blobUrl == null || !blobUrl.startsWith('blob:')) {
      return null;
    }

    try {
      final request = await html.HttpRequest.request(
        blobUrl,
        responseType: 'arraybuffer',
      );
      
      if (request.response is ByteBuffer) {
        final buffer = request.response as ByteBuffer;
        return Uint8List.view(buffer);
      }
    } catch (e) {
      print('Error getting audio bytes: $e');
    }
    return null;
  }

  /// Dispose of resources
  void dispose() {
    if (_isRecording && _mediaRecorder != null) {
      _mediaRecorder!.stop();
    }
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _mediaRecorder = null;
    _recordedChunks.clear();
    _isRecording = false;
    _isPaused = false;
    _stopCompleter = null;
  }

  /// Get recording state
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
}

