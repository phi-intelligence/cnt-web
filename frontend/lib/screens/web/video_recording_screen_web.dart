import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import 'video_preview_screen_web.dart';

/// Web Video Recording Screen - Record video podcasts
/// Matches web app theme and avoids dart:io dependencies
class VideoRecordingScreenWeb extends StatefulWidget {
  const VideoRecordingScreenWeb({super.key});

  @override
  State<VideoRecordingScreenWeb> createState() => _VideoRecordingScreenWebState();
}

class _VideoRecordingScreenWebState extends State<VideoRecordingScreenWeb> {
  CameraController? _controller;
  bool _isRecording = false;
  int _recordingDuration = 0;
  bool _isFlashOn = false;
  CameraDescription? _camera;
  bool _isInitializing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No cameras available';
          _isInitializing = false;
        });
        return;
      }

      _camera = cameras.first;
      _controller = CameraController(
        _camera!,
        ResolutionPreset.high,
      );
      await _controller!.initialize();
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing camera: $e');
      setState(() {
        _errorMessage = 'Failed to initialize camera: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera not initialized'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
      return;
    }

    try {
      await _controller!.startVideoRecording();
      setState(() {
        _isRecording = true;
      });
      _updateDuration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting recording: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Camera not initialized'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
      return;
    }

    try {
      setState(() {
        _isRecording = false;
      });

      final video = await _controller!.stopVideoRecording();
      
      // On web, use XFile.readAsBytes() to get file size
      int fileSize = 0;
      try {
        final bytes = await video.readAsBytes();
        fileSize = bytes.length;
      } catch (e) {
        print('Error reading video bytes: $e');
        // Continue with fileSize = 0 if we can't read bytes
      }

      // Navigate to web preview screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => VideoPreviewScreenWeb(
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
          SnackBar(
            content: Text('Error stopping recording: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
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
    // TODO: Implement flash toggle if supported
  }

  Future<void> _switchCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Only one camera available')),
        );
        return;
      }

      final currentIndex = cameras.indexWhere(
        (camera) => camera.lensDirection == _camera!.lensDirection,
      );
      final newCamera = cameras[(currentIndex + 1) % cameras.length];

      await _controller?.dispose();
      
      _controller = CameraController(
        newCamera,
        ResolutionPreset.high,
      );
      await _controller!.initialize();
      _camera = newCamera;
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error switching camera: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: StyledPageHeader(
                    title: 'Record Video Podcast',
                    size: StyledPageHeaderSize.h2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Camera Preview Section
            Expanded(
              child: SectionContainer(
                showShadow: true,
                child: _isInitializing
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.primaryMain,
                            ),
                            const SizedBox(height: AppSpacing.medium),
                            Text(
                              'Initializing camera...',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: AppColors.errorMain,
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                Text(
                                  'Camera Error',
                                  style: AppTypography.heading3.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.small),
                                Text(
                                  _errorMessage!,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: AppSpacing.large),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primaryMain,
                                    foregroundColor: AppColors.textInverse,
                                  ),
                                  child: const Text('Go Back'),
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            children: [
                              // Camera Preview
                              ClipRRect(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                child: AspectRatio(
                                  aspectRatio: _controller!.value.aspectRatio,
                                  child: CameraPreview(_controller!),
                                ),
                              ),

                              // Top Controls Overlay
                              Positioned(
                                top: AppSpacing.medium,
                                left: AppSpacing.medium,
                                right: AppSpacing.medium,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Recording Duration Badge
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: AppSpacing.medium,
                                        vertical: AppSpacing.small,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isRecording
                                            ? AppColors.errorMain
                                            : AppColors.backgroundSecondary,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                        border: _isRecording
                                            ? null
                                            : Border.all(
                                                color: AppColors.borderPrimary,
                                                width: 1,
                                              ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (_isRecording) ...[
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.small),
                                          ],
                                          Text(
                                            _formatDuration(_recordingDuration),
                                            style: AppTypography.bodyMedium.copyWith(
                                              color: _isRecording
                                                  ? Colors.white
                                                  : AppColors.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Camera Controls
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                            color: AppColors.textInverse,
                                          ),
                                          onPressed: _toggleFlash,
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black.withOpacity(0.5),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.small),
                                        IconButton(
                                          icon: Icon(
                                            Icons.flip_camera_ios,
                                            color: AppColors.textInverse,
                                          ),
                                          onPressed: _switchCamera,
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black.withOpacity(0.5),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Bottom Controls
                              Positioned(
                                bottom: AppSpacing.large,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: GestureDetector(
                                    onTap: _isRecording ? _stopRecording : _startRecording,
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isRecording
                                            ? AppColors.errorMain
                                            : AppColors.primaryMain,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (_isRecording
                                                    ? AppColors.errorMain
                                                    : AppColors.primaryMain)
                                                .withOpacity(0.4),
                                            blurRadius: 20,
                                            spreadRadius: 4,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isRecording
                                            ? Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              )
                                            : Icon(
                                                Icons.videocam,
                                                color: Colors.white,
                                                size: 32,
                                              ),
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
      ),
    );
  }
}
