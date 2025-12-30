import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;
import '../../utils/platform_view_registry_helper.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../services/logger_service.dart';
import '../../utils/web_video_recorder.dart';
import 'video_preview_screen_web.dart';
import 'movie_preview_screen_web.dart';

/// Web Video Recording Screen - Record video podcasts or movies
/// Matches web app theme and avoids dart:io dependencies
class VideoRecordingScreenWeb extends StatefulWidget {
  final String previewType; // 'podcast' or 'movie'
  final String? movieType; // 'movie' or 'kids_movie' (only used when previewType is 'movie')
  
  const VideoRecordingScreenWeb({
    super.key,
    this.previewType = 'podcast', // Default to podcast for backward compatibility
    this.movieType,
  });

  @override
  State<VideoRecordingScreenWeb> createState() => _VideoRecordingScreenWebState();
}

class _VideoRecordingScreenWebState extends State<VideoRecordingScreenWeb> {
  WebVideoRecorder? _recorder;
  bool _isRecording = false;
  bool _isPaused = false;
  int _recordingDuration = 0;
  bool _isFlashOn = false;
  bool _isInitializing = true;
  String? _errorMessage;
  String? _videoElementViewId;
  html.VideoElement? _videoElement;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _initializeCamera();
    } else {
      setState(() {
        _errorMessage = 'Video recording is only available on web';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _recorder = WebVideoRecorder();
      
      // Check permissions first
      final hasPermission = await _recorder!.hasPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage = 'Camera permission denied. Please allow camera access in your browser settings.';
          _isInitializing = false;
        });
        return;
      }

      // Initialize camera
      _videoElement = await _recorder!.initializeCamera();
      
      // Register video element for HtmlElementView
      _videoElementViewId = 'video-preview-${DateTime.now().millisecondsSinceEpoch}';
      platformViewRegistry.registerViewFactory(
        _videoElementViewId!,
        (int viewId) => _videoElement!,
      );

      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      LoggerService.e('❌ Error initializing camera: $e');
      // Extract user-friendly error message
      String errorMsg = e.toString();
      if (errorMsg.contains('Exception: ')) {
        errorMsg = errorMsg.replaceFirst('Exception: ', '');
      }
      
      setState(() {
        _errorMessage = errorMsg.isNotEmpty ? errorMsg : 'Failed to initialize camera. Please check your browser settings and try again.';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (_recorder == null || !_recorder!.isInitialized) {
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
      await _recorder!.startRecording();
      setState(() {
        _isRecording = true;
        _isPaused = false;
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

  Future<void> _pauseRecording() async {
    if (_recorder == null || !_recorder!.isInitialized || !_isRecording) {
      return;
    }

    try {
      await _recorder!.pauseRecording();
      setState(() {
        _isPaused = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error pausing recording: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _resumeRecording() async {
    if (_recorder == null || !_recorder!.isInitialized || !_isRecording) {
      return;
    }

    try {
      await _recorder!.resumeRecording();
      setState(() {
        _isPaused = false;
      });
      _updateDuration();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resuming recording: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null || !_recorder!.isInitialized) {
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

    if (!_isRecording) {
      return;
    }

    try {
      setState(() {
        _isRecording = false;
        _isPaused = false;
      });

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  const Text('Processing video...'),
                ],
            ),
            duration: const Duration(seconds: 5),
            backgroundColor: AppColors.primaryMain,
          ),
        );
      }

      final videoFile = await _recorder!.stopRecording();
      
      // Get file size
      int fileSize = 0;
      try {
        final bytes = await videoFile.readAsBytes();
        fileSize = bytes.length;
        
        // Validate file size
        if (fileSize == 0) {
          throw Exception('Video file is empty. Please try recording again.');
        }
      } catch (e) {
        LoggerService.e('Error reading video bytes: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reading video file: $e'),
              backgroundColor: AppColors.errorMain,
              duration: const Duration(seconds: 5),
            ),
          );
        }
        setState(() {
          _isRecording = false;
        });
        return;
      }

      // Navigate to appropriate preview screen
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        if (widget.previewType == 'movie') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => MoviePreviewScreenWeb(
                videoUri: videoFile.path,
                source: 'camera',
                duration: _recordingDuration,
                fileSize: fileSize,
                movieType: widget.movieType ?? 'movie',
              ),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreenWeb(
                videoUri: videoFile.path,
                source: 'camera',
                duration: _recordingDuration,
                fileSize: fileSize,
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.e('❌ Error stopping video recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Extract user-friendly error message
        String errorMessage = e.toString();
        if (errorMessage.contains('Exception: ')) {
          errorMessage = errorMessage.replaceFirst('Exception: ', '');
        }
        if (errorMessage.contains('blob contains no valid video data')) {
          errorMessage = 'The recording contains no valid video data. Please try recording again and ensure you record for at least a few seconds.';
        } else if (errorMessage.contains('uint8 list expected byte buffer') || errorMessage.contains('ByteBuffer')) {
          errorMessage = 'Error processing video data. Please try recording again.';
        } else if (errorMessage.contains('Timeout')) {
          errorMessage = 'Processing took too long. The video file may be too large. Please try recording a shorter video.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppColors.errorMain,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Try Again',
              textColor: Colors.white,
              onPressed: () {
                setState(() {
                  _isRecording = false;
                  _isPaused = false;
                });
              },
            ),
          ),
        );
        setState(() {
          _isRecording = false;
          _isPaused = false;
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
    if (_recorder == null) return;
    
    try {
      await _recorder!.switchCamera();
      
      // Update video element view
      if (_videoElementViewId != null && _recorder!.videoElement != null) {
        _videoElement = _recorder!.videoElement;
        setState(() {});
      }
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
    if (_isRecording && !_isPaused) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted && _isRecording && !_isPaused) {
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
    _recorder?.dispose();
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
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final screenHeight = MediaQuery.of(context).size.height;
                              final screenWidth = MediaQuery.of(context).size.width;
                              final isMobile = screenWidth < 768;
                              
                              // On mobile, use 60-70% of screen height, on desktop use available space
                              final previewHeight = isMobile 
                                  ? (screenHeight * 0.65).clamp(300.0, screenHeight * 0.7)
                                  : constraints.maxHeight;
                              final previewWidth = previewHeight * (16 / 9);
                              
                              return Stack(
                                children: [
                                  // Camera Preview - HTML Video Element
                                  if (_videoElementViewId != null)
                                    Center(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                        child: SizedBox(
                                          width: isMobile 
                                              ? screenWidth * 0.9 
                                              : previewWidth.clamp(0.0, constraints.maxWidth),
                                          height: previewHeight,
                                          child: AspectRatio(
                                            aspectRatio: 16 / 9,
                                            child: HtmlElementView(
                                              viewType: _videoElementViewId!,
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    Container(
                                      color: Colors.black,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Pause/Resume Button (only shown when recording)
                                      if (_isRecording) ...[
                                        GestureDetector(
                                          onTap: _isPaused ? _resumeRecording : _pauseRecording,
                                          child: Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.accentMain,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: AppColors.accentMain.withOpacity(0.4),
                                                  blurRadius: 15,
                                                  spreadRadius: 3,
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Icon(
                                                _isPaused ? Icons.play_arrow : Icons.pause,
                                                color: Colors.white,
                                                size: 28,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: AppSpacing.large),
                                      ],
                                      
                                      // Record/Stop Button
                                      GestureDetector(
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
                                    ],
                                  ),
                                ),
                              ),
                                ],
                              );
                            },
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
