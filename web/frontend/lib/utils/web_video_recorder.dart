import 'dart:html' if (dart.library.io) 'html_stub.dart' as html;
import 'dart:typed_data';
import 'dart:async';
import 'package:cross_file/cross_file.dart';

/// Web-compatible video recorder using browser MediaDevices API
/// Provides camera access and video recording functionality for web
class WebVideoRecorder {
  html.MediaStream? _mediaStream;
  html.MediaRecorder? _mediaRecorder;
  html.VideoElement? _videoElement;
  List<html.Blob> _recordedChunks = [];
  bool _isRecording = false;
  bool _isPaused = false;
  Completer<XFile>? _stopCompleter;
  String? _currentDeviceId;
  String _facingMode = 'user'; // 'user' for front, 'environment' for back
  DateTime? _recordingStartTime;
  static const int _minRecordingDurationMs = 500; // Minimum 500ms recording
  static const int _minBlobSizeBytes = 1024; // Minimum 1KB for valid video

  /// Get video element for preview
  html.VideoElement? get videoElement => _videoElement;

  /// Check if we're in a secure context (HTTPS or localhost)
  bool _isSecureContext() {
    try {
      // Check if window.location.protocol is https or if we're on localhost
      final protocol = html.window.location.protocol;
      final hostname = html.window.location.hostname;
      final isHttps = protocol == 'https:';
      final isLocalhost = hostname == 'localhost' || 
                         hostname == '127.0.0.1' || 
                         (hostname?.startsWith('192.168.') ?? false) ||
                         (hostname?.startsWith('10.') ?? false) ||
                         (hostname?.startsWith('172.') ?? false);
      
      if (!isHttps && !isLocalhost) {
        print('⚠️ Camera access requires HTTPS. Current protocol: $protocol, hostname: $hostname');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error checking secure context: $e');
      return false;
    }
  }

  /// Check if camera permission is available
  Future<bool> hasPermission() async {
    try {
      // First check if we're in a secure context
      if (!_isSecureContext()) {
        print('❌ Not in secure context - camera access requires HTTPS');
        return false;
      }
      
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        print('❌ MediaDevices API not available');
        return false;
      }
      
      // Request camera access to check permission
      final stream = await mediaDevices.getUserMedia({'video': true});
      // Stop the test stream immediately
      stream.getTracks().forEach((track) => track.stop());
      print('✅ Camera permission granted');
      return true;
    } catch (e) {
      print('❌ Camera permission check failed: $e');
      // Log specific error types for debugging
      if (e.toString().contains('NotAllowedError') || e.toString().contains('Permission denied')) {
        print('   → User denied camera permission');
      } else if (e.toString().contains('NotFoundError') || e.toString().contains('No camera')) {
        print('   → No camera device found');
      } else if (e.toString().contains('NotReadableError') || e.toString().contains('Device in use')) {
        print('   → Camera device is in use by another application');
      } else if (e.toString().contains('OverconstrainedError')) {
        print('   → Camera constraints cannot be satisfied');
      } else if (e.toString().contains('SecurityError') || e.toString().contains('secure context')) {
        print('   → Security error - requires HTTPS');
      }
      return false;
    }
  }

  /// Initialize camera and create video preview element
  /// Returns the video element for display
  Future<html.VideoElement> initializeCamera({
    String? deviceId,
    String facingMode = 'user',
  }) async {
    try {
      // Check secure context first
      if (!_isSecureContext()) {
        final protocol = html.window.location.protocol;
        final hostname = html.window.location.hostname;
        throw Exception(
          'Camera access requires HTTPS. Current URL: $protocol//$hostname. '
          'Please access the site via HTTPS or contact support if the issue persists.'
        );
      }
      
      // Stop existing stream if any
      await dispose();

      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        throw Exception(
          'MediaDevices API is not available in this browser. '
          'Please use a modern browser that supports camera access.'
        );
      }

      // Build video constraints
      final videoConstraints = <String, dynamic>{};
      if (deviceId != null) {
        videoConstraints['deviceId'] = {'exact': deviceId};
      } else {
        videoConstraints['facingMode'] = facingMode;
      }

      print('📹 Requesting camera access...');
      // Get media stream
      _mediaStream = await mediaDevices.getUserMedia({
        'video': videoConstraints,
        'audio': true,
      }).catchError((error) {
        print('❌ getUserMedia error: $error');
        // Provide user-friendly error messages
        final errorStr = error.toString();
        if (errorStr.contains('NotAllowedError') || errorStr.contains('Permission denied')) {
          throw Exception(
            'Camera permission denied. Please allow camera access in your browser settings '
            'and try again.'
          );
        } else if (errorStr.contains('NotFoundError') || errorStr.contains('No camera')) {
          throw Exception(
            'No camera device found. Please connect a camera and try again.'
          );
        } else if (errorStr.contains('NotReadableError') || errorStr.contains('Device in use')) {
          throw Exception(
            'Camera is in use by another application. Please close other applications using '
            'the camera and try again.'
          );
        } else if (errorStr.contains('OverconstrainedError')) {
          throw Exception(
            'Camera constraints cannot be satisfied. Please try a different camera or '
            'contact support.'
          );
        } else if (errorStr.contains('SecurityError') || errorStr.contains('secure context')) {
          throw Exception(
            'Camera access requires a secure connection (HTTPS). Please access the site via HTTPS.'
          );
        } else {
          throw Exception('Failed to access camera: $error');
        }
      });

      print('✅ Camera access granted');

      // Create video element
      _videoElement = html.VideoElement()
        ..autoplay = true
        ..muted = true
        ..srcObject = _mediaStream
        ..style.width = '100%'
        ..style.height = '100%';
      
      // Mirror the preview for front-facing camera (like a mirror)
      // This fixes the camera inversion issue where right hand appears as left hand
      if (facingMode == 'user') {
        _videoElement!.style.transform = 'scaleX(-1)';
      }

      _facingMode = facingMode;
      _currentDeviceId = deviceId;

      print('✅ Camera initialized successfully');
      return _videoElement!;
    } catch (e) {
      print('❌ Error initializing camera: $e');
      await dispose();
      rethrow;
    }
  }

  /// Get available camera devices
  Future<List<html.MediaDeviceInfo>> getAvailableCameras() async {
    try {
      final mediaDevices = html.window.navigator.mediaDevices;
      if (mediaDevices == null) {
        return <html.MediaDeviceInfo>[];
      }

      final devices = await mediaDevices.enumerateDevices();
      return devices
          .where((device) => device.kind == 'videoinput')
          .cast<html.MediaDeviceInfo>()
          .toList();
    } catch (e) {
      print('Error enumerating cameras: $e');
      return <html.MediaDeviceInfo>[];
    }
  }

  /// Switch to a different camera
  Future<void> switchCamera() async {
    try {
      final cameras = await getAvailableCameras();
      if (cameras.length < 2) {
        throw Exception('Only one camera available');
      }

      // Find current camera index
      int currentIndex = 0;
      if (_currentDeviceId != null) {
        currentIndex = cameras.indexWhere(
          (device) => device.deviceId == _currentDeviceId,
        );
        if (currentIndex == -1) currentIndex = 0;
      }

      // Switch to next camera
      final nextIndex = (currentIndex + 1) % cameras.length;
      final nextCamera = cameras[nextIndex];

      // Reinitialize with new camera
      await initializeCamera(
        deviceId: nextCamera.deviceId,
        facingMode: _facingMode,
      );
    } catch (e) {
      print('Error switching camera: $e');
      rethrow;
    }
  }

  /// Start recording video
  Future<void> startRecording() async {
    if (_mediaStream == null || _videoElement == null) {
      throw Exception('Camera not initialized');
    }

    if (_isRecording) {
      return;
    }

    try {
      // Determine best mime type for video
      String? mimeType;
      if (html.MediaRecorder.isTypeSupported('video/webm;codecs=vp9,opus')) {
        mimeType = 'video/webm;codecs=vp9,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm;codecs=vp8,opus')) {
        mimeType = 'video/webm;codecs=vp8,opus';
      } else if (html.MediaRecorder.isTypeSupported('video/webm')) {
        mimeType = 'video/webm';
      } else if (html.MediaRecorder.isTypeSupported('video/mp4')) {
        mimeType = 'video/mp4';
      }

      // Create MediaRecorder
      _mediaRecorder = html.MediaRecorder(
        _mediaStream!,
        mimeType != null ? {'mimeType': mimeType} : null,
      );
      
      _recordedChunks.clear();
      _isPaused = false;

      // Set up event handlers
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
        // Enhanced validation
        if (_recordedChunks.isEmpty) {
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(Exception(
              'No video data recorded - recording may have been stopped too quickly'
            ));
          }
          return;
        }

        // Calculate total size of all chunks
        int totalSize = _recordedChunks.fold(0, (sum, chunk) => sum + chunk.size);
        if (totalSize == 0) {
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(Exception(
              'Recorded chunks are empty - no video frames were captured'
            ));
          }
          return;
        }

        // Check minimum blob size for valid video
        if (totalSize < _minBlobSizeBytes) {
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(Exception(
              'Recorded video is too small ($totalSize bytes) - recording may have been stopped too quickly. '
              'Please record for at least ${_minRecordingDurationMs}ms.'
            ));
          }
          return;
        }

        // Check minimum recording duration
        if (_recordingStartTime != null) {
          final duration = DateTime.now().difference(_recordingStartTime!);
          if (duration.inMilliseconds < _minRecordingDurationMs) {
            if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
              _stopCompleter!.completeError(Exception(
                'Recording duration too short (${duration.inMilliseconds}ms) - please record for at least ${_minRecordingDurationMs}ms'
              ));
            }
            return;
          }
        }

        // Create blob and convert
        final blob = html.Blob(_recordedChunks, mimeType ?? 'video/webm');
        print('📹 Created blob from ${_recordedChunks.length} chunks, total size: ${totalSize} bytes');
        
        // Call async function but don't await (event handler)
        _convertBlobToXFile(blob, mimeType ?? 'video/webm').catchError((error) {
          print('Error in _convertBlobToXFile: $error');
          if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
            _stopCompleter!.completeError(error);
          }
        });
      }, false);

      // Start recording with timeslice to get data chunks
      _mediaRecorder!.start(100); // Request data every 100ms
      _isRecording = true;
      _recordingStartTime = DateTime.now();
      print('📹 Recording started at ${_recordingStartTime}');
    } catch (e) {
      print('Error starting video recording: $e');
      _isRecording = false;
      rethrow;
    }
  }

  /// Convert blob to XFile
  Future<void> _convertBlobToXFile(html.Blob blob, String mimeType) async {
    if (_stopCompleter == null || _stopCompleter!.isCompleted) {
      print('Warning: _stopCompleter is null or already completed');
      return;
    }

    // Validate blob size before attempting conversion
    if (blob.size == 0) {
      final error = Exception('Blob is empty - no video data was recorded');
      print('❌ $error');
      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        _stopCompleter!.completeError(error);
      }
      return;
    }

    // Check minimum blob size for valid video
    if (blob.size < _minBlobSizeBytes) {
      final error = Exception(
        'Blob is too small (${blob.size} bytes) - recording may have been stopped before any valid video frames were captured. '
        'Minimum size required: $_minBlobSizeBytes bytes'
      );
      print('❌ $error');
      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        _stopCompleter!.completeError(error);
      }
      return;
    }

    try {
      // Read blob as bytes using FileReader
      final reader = html.FileReader();
      final completer = Completer<Uint8List>();
      bool isCompleted = false;
      
      // Set up load handler
      reader.onLoad.listen((event) {
        try {
          if (isCompleted) return;
          
          final result = reader.result;
          if (result == null) {
            if (!completer.isCompleted) {
              isCompleted = true;
              completer.completeError(Exception('FileReader result is null - blob may contain no valid video data'));
            }
            return;
          }
          
          // Enhanced type checking with proper ByteBuffer handling
          Uint8List bytes;
          if (result is ByteBuffer) {
            // Convert ByteBuffer to Uint8List
            bytes = result.asUint8List();
          } else if (result is Uint8List) {
            // Already a Uint8List
            bytes = result;
          } else if (result is String) {
            // Handle string result (shouldn't happen with readAsArrayBuffer, but handle gracefully)
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.completeError(Exception(
                'FileReader returned string instead of ArrayBuffer - blob may be invalid. '
                'This may indicate the blob contains no valid video data.'
              ));
            }
            return;
          } else {
            // Unknown type - provide more context
            print('⚠️ FileReader returned unexpected type: ${result.runtimeType}');
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.completeError(Exception(
                'Unexpected FileReader result type: ${result.runtimeType}. '
                'Expected ByteBuffer or Uint8List. This may indicate the blob contains no valid video data. '
                'Please try recording again and ensure you record for at least ${_minRecordingDurationMs}ms.'
              ));
            }
            return;
          }
          
          // Validate bytes are not empty
          if (bytes.isEmpty) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.completeError(Exception('Blob contains no valid video data - bytes array is empty'));
            }
            return;
          }
          
          // Validate minimum size
          if (bytes.length < _minBlobSizeBytes) {
            isCompleted = true;
            if (!completer.isCompleted) {
              completer.completeError(Exception(
                'Video data is too small (${bytes.length} bytes). '
                'Minimum size required: $_minBlobSizeBytes bytes. '
                'Please record for at least ${_minRecordingDurationMs}ms before stopping.'
              ));
            }
            return;
          }
          
          // Successfully converted
          if (!completer.isCompleted) {
            isCompleted = true;
            completer.complete(bytes);
          }
        } catch (e) {
          if (!isCompleted && !completer.isCompleted) {
            isCompleted = true;
            completer.completeError(Exception('Error processing FileReader result: $e'));
          }
        }
      });
      
      // Set up error handler
      reader.onError.listen((event) {
        if (!isCompleted && !completer.isCompleted) {
          isCompleted = true;
          completer.completeError(Exception('FileReader error: ${event.toString()}'));
        }
      });
      
      // Start reading
      reader.readAsArrayBuffer(blob);
      
      // Wait for completion with timeout
      Uint8List bytes;
      try {
        bytes = await completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw Exception('Timeout reading blob data after 15 seconds. The video file may be too large or corrupted.');
          },
        );
      } catch (e) {
        print('❌ Error reading blob bytes: $e');
        if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
          _stopCompleter!.completeError(e);
        }
        return;
      }

      // Validate bytes before creating XFile
      if (bytes.isEmpty) {
        final error = Exception('Blob contains no valid video data - bytes array is empty after conversion');
        print('❌ $error');
        if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
          _stopCompleter!.completeError(error);
        }
        return;
      }

      // Create XFile from bytes
      final extension = mimeType.contains('mp4') ? 'mp4' : 'webm';
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.$extension';
      
      try {
        final xFile = XFile.fromData(
          bytes,
          mimeType: mimeType,
          name: fileName,
        );

        // Complete the stop completer
        if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
          print('✅ Successfully converted blob to XFile: $fileName (${bytes.length} bytes)');
          _stopCompleter!.complete(xFile);
        }
      } catch (e) {
        print('❌ Error creating XFile from bytes: $e');
        if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
          _stopCompleter!.completeError(Exception(
            'Failed to create video file. Error: $e. '
            'The video data may be corrupted. Please try recording again.'
          ));
        }
      }
    } catch (e) {
      print('❌ Error converting blob to XFile: $e');
      if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
        _stopCompleter!.completeError(Exception(
          'Failed to process video recording. Error: $e. '
          'Please try recording again and ensure you record for at least ${_minRecordingDurationMs}ms before stopping.'
        ));
      }
    }
  }

  /// Pause recording
  Future<void> pauseRecording() async {
    if (_mediaRecorder != null && _isRecording && !_isPaused) {
      _mediaRecorder!.pause();
      _isPaused = true;
    }
  }

  /// Resume recording
  Future<void> resumeRecording() async {
    if (_mediaRecorder != null && _isRecording && _isPaused) {
      _mediaRecorder!.resume();
      _isPaused = false;
    }
  }

  /// Stop recording and return the recorded video file
  Future<XFile> stopRecording() async {
    if (_mediaRecorder == null || !_isRecording) {
      throw Exception('Not recording');
    }

    // Validate that recording actually started
    if (_mediaRecorder!.state == 'inactive') {
      throw Exception('Recording was never started or already stopped');
    }

    // Check minimum recording duration
    if (_recordingStartTime != null) {
      final duration = DateTime.now().difference(_recordingStartTime!);
      if (duration.inMilliseconds < _minRecordingDurationMs) {
        throw Exception(
          'Recording duration too short (${duration.inMilliseconds}ms). '
          'Please record for at least ${_minRecordingDurationMs}ms before stopping.'
        );
      }
    }

    try {
      // Create completer to wait for stop event
      _stopCompleter = Completer<XFile>();
      
      // Resume if paused before stopping
      if (_isPaused) {
        _mediaRecorder!.resume();
        await Future.delayed(const Duration(milliseconds: 50));
      }
      
      // Stop the recorder
      _mediaRecorder!.stop();
      _isRecording = false;
      _isPaused = false;

      // Wait for stop event to complete (with timeout)
      try {
        if (_stopCompleter == null) {
          throw Exception('Stop completer is null');
        }
        return await _stopCompleter!.future.timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        // If timeout or error, try to create file from existing chunks
        if (_recordedChunks.isNotEmpty && _stopCompleter != null && !_stopCompleter!.isCompleted) {
          try {
            final mimeType = _mediaRecorder!.mimeType ?? 'video/webm';
            final blob = html.Blob(_recordedChunks, mimeType);
            await _convertBlobToXFile(blob, mimeType);
            if (_stopCompleter != null && !_stopCompleter!.isCompleted) {
              // Wait a bit more for the conversion
              return await _stopCompleter!.future.timeout(
                const Duration(seconds: 5),
              );
            } else if (_stopCompleter != null) {
              // Already completed, get the result
              return await _stopCompleter!.future;
            } else {
              throw Exception('Stop completer became null');
            }
          } catch (e2) {
            print('Error in fallback blob conversion: $e2');
            throw Exception('Failed to create video file: $e');
          }
        } else {
          throw Exception('No video data recorded. Recording may have been stopped before any frames were captured: $e');
        }
      }
    } catch (e) {
      print('Error stopping video recording: $e');
      _recordedChunks.clear();
      _isRecording = false;
      _isPaused = false;
      _stopCompleter = null;
      rethrow;
    }
  }

  /// Dispose of resources
  Future<void> dispose() async {
    if (_isRecording && _mediaRecorder != null) {
      try {
        _mediaRecorder!.stop();
      } catch (e) {
        print('Error stopping recorder on dispose: $e');
      }
    }
    
    _mediaStream?.getTracks().forEach((track) => track.stop());
    _mediaStream = null;
    _mediaRecorder = null;
    _videoElement = null;
    _recordedChunks.clear();
    _isRecording = false;
    _isPaused = false;
    _stopCompleter = null;
    _currentDeviceId = null;
    _recordingStartTime = null;
  }

  /// Get recording state
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  bool get isInitialized => _videoElement != null && _mediaStream != null;
}

