import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import '../../theme/app_spacing.dart';
import 'video_preview_screen.dart';
import '../web/video_preview_screen_web.dart';

/// Video Recording Screen - Record video podcasts
class VideoRecordingScreen extends StatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  State<VideoRecordingScreen> createState() => _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends State<VideoRecordingScreen> {
  CameraController? _controller;
  bool _isRecording = false;
  int _recordingDuration = 0;
  bool _isFlashOn = false;
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _camera = cameras.first;
      _controller = CameraController(
        _camera!,
        ResolutionPreset.high,
      );
      await _controller!.initialize();
      setState(() {});
    }
  }

  Future<void> _startRecording() async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      _updateDuration();
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not initialized')),
        );
      }
      return;
    }

    try {
      setState(() {
        _isRecording = false;
      });

      final video = await _controller!.stopVideoRecording();
      
      // Get file size (on web, video.path is a blob URL, so we can't check file existence)
      int fileSize = 0;
      if (!kIsWeb) {
        // Verify the video file exists (mobile only)
        final file = io.File(video.path);
        if (!await file.exists()) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video file not found')),
            );
          }
          return;
        }
        fileSize = await file.length();
      }
      
      // Navigate to video preview screen (web or mobile version)
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => kIsWeb
                ? VideoPreviewScreenWeb(
                    videoUri: video.path,
                    source: 'camera',
                    duration: _recordingDuration,
                    fileSize: fileSize,
                  )
                : VideoPreviewScreen(
                    videoUri: video.path,
                    source: 'camera',
                    duration: _recordingDuration,
                    fileSize: fileSize,
                  ),
          ),
        );
      }
    } catch (e) {
      print('Error stopping video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
        // Reset recording state
        setState(() {
          _isRecording = false;
        });
      }
    }
  }

  void _toggleFlash() {
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
    // TODO: Toggle flash
  }

  Future<void> _switchCamera() async {
    final cameras = await availableCameras();
    final currentIndex = cameras.indexWhere(
      (camera) => camera.lensDirection == _camera!.lensDirection,
    );
    final newCamera = cameras[(currentIndex + 1) % cameras.length];

    _controller = CameraController(
      newCamera,
      ResolutionPreset.high,
    );
    await _controller!.initialize();
    _camera = newCamera;
    setState(() {});
  }

  void _updateDuration() {
    if (_isRecording) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isRecording) {
          setState(() {
            _recordingDuration++;
          });
          _updateDuration();
        }
      });
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: CameraPreview(_controller!),
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatDuration(_recordingDuration),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
                        color: Colors.white,
                        onPressed: _toggleFlash,
                      ),
                      IconButton(
                        icon: const Icon(Icons.flip_camera_ios),
                        color: Colors.white,
                        onPressed: _switchCamera,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!_isRecording)
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 6),
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _stopRecording,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red,
                          border: Border.all(color: Colors.white, width: 6),
                        ),
                        child: Center(
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
