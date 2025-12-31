import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/bank_details_helper.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/thumbnail_selector.dart';
import '../../services/api_service.dart';
import '../../utils/state_persistence.dart';
import 'video_editor_screen_web.dart';
import 'package:go_router/go_router.dart';

/// Web Video Preview Screen
/// Shows recorded/uploaded video with playback and controls
/// Matches web app theme and handles blob URLs
class VideoPreviewScreenWeb extends StatefulWidget {
  final String videoUri;
  final String source; // 'camera' or 'gallery'
  final int duration;
  final int fileSize;

  const VideoPreviewScreenWeb({
    super.key,
    required this.videoUri,
    required this.source,
    this.duration = 0,
    this.fileSize = 0,
  });

  @override
  State<VideoPreviewScreenWeb> createState() => _VideoPreviewScreenWebState();
}

class _VideoPreviewScreenWebState extends State<VideoPreviewScreenWeb> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;

  // Controls visibility
  bool _showControls = true;
  Timer? _hideControlsTimer;
  bool _isMouseOverVideo = false;

  // Seek/Scrubbing
  bool _isScrubbing = false;
  double _scrubValue = 0.0;
  bool _wasPlayingBeforeScrub = false;

  // Form fields
  final TextEditingController _titleController =
      TextEditingController(text: 'My Video Podcast');
  final TextEditingController _descriptionController = TextEditingController(
      text: 'A wonderful video podcast about faith and spirituality');
  String? _selectedThumbnail;
  String? _videoUrl; // Will be set after upload

  @override
  void initState() {
    super.initState();
    _loadSavedState();
    _initializePlayer();
  }

  Future<void> _loadSavedState() async {
    try {
      final savedState = await StatePersistence.loadVideoPreviewState();
      if (savedState != null && mounted) {
        // Restore form controllers
        final savedTitle = savedState['title'] as String?;
        final savedDescription = savedState['description'] as String?;
        final savedThumbnail = savedState['thumbnailUrl'] as String?;

        if (savedTitle != null && savedTitle.isNotEmpty) {
          _titleController.text = savedTitle;
        }
        if (savedDescription != null && savedDescription.isNotEmpty) {
          _descriptionController.text = savedDescription;
        }
        if (savedThumbnail != null && savedThumbnail.isNotEmpty) {
          _selectedThumbnail = savedThumbnail;
        }

        print('✅ Restored video preview state from saved state');
      }
    } catch (e) {
      print('❌ Error loading video preview state: $e');
    }
  }

  Future<void> _saveState() async {
    try {
      // Convert blob URL to backend URL before saving if needed
      String videoUriToSave = widget.videoUri;
      if (kIsWeb && widget.videoUri.startsWith('blob:')) {
        // If blob URL, try to get backend URL from saved state or upload
        final savedState = await StatePersistence.loadVideoPreviewState();
        if (savedState != null) {
          final savedUri = savedState['videoUri'] as String?;
          if (savedUri != null && !savedUri.startsWith('blob:')) {
            videoUriToSave = savedUri;
          }
        }
      }

      await StatePersistence.saveVideoPreviewState(
        videoUri: videoUriToSave,
        source: widget.source,
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        thumbnailUrl: _selectedThumbnail,
        duration: widget.duration > 0 ? widget.duration : null,
        fileSize: widget.fileSize > 0 ? widget.fileSize : null,
      );
    } catch (e) {
      print('⚠️ Error saving video preview state: $e');
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if URI is a network URL or blob URL
      final isNetworkUrl = widget.videoUri.startsWith('http://') ||
          widget.videoUri.startsWith('https://');
      final isBlobUrl = widget.videoUri.startsWith('blob:');

      // On web, use networkUrl for both blob URLs and network URLs
      if (kIsWeb || isNetworkUrl || isBlobUrl) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUri),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // Fallback for non-web (shouldn't happen, but handle gracefully)
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUri),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }

      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      setState(() {
        _isInitializing = false;
      });
      _startControlsTimer();
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;

    // Don't update position during scrubbing
    if (_isScrubbing) return;

    setState(() {});
  }

  void _onMouseEnter() {
    setState(() {
      _isMouseOverVideo = true;
    });
    _showControlsWithAutoHide();
  }

  void _onMouseExit() {
    setState(() {
      _isMouseOverVideo = false;
    });
    // Keep controls visible if paused, hide if playing
    if (_controller?.value.isPlaying ?? false) {
      _hideControls();
    }
  }

  void _onMouseMove() {
    if (_isMouseOverVideo) {
      _showControlsWithAutoHide();
    }
  }

  void _showControlsWithAutoHide() {
    _hideControlsTimer?.cancel();
    setState(() {
      _showControls = true;
    });

    if (_controller?.value.isPlaying ?? false) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    _hideControlsTimer?.cancel();
    if (_controller?.value.isPlaying ?? false) {
      _hideControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted &&
            (_controller?.value.isPlaying ?? false) &&
            !_isScrubbing) {
          setState(() {
            _showControls = false;
          });
        }
      });
    }
  }

  void _hideControls() {
    _hideControlsTimer?.cancel();
    if (mounted && (_controller?.value.isPlaying ?? false)) {
      setState(() {
        _showControls = false;
      });
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _handleBack() {
    // Use GoRouter for consistent navigation
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      GoRouter.of(context).go('/home');
    }
  }

  Future<void> _handlePlayPause() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });

    // Show controls and manage timer
    _showControlsWithAutoHide();
  }

  void _handleEdit() async {
    // If blob URL, upload to backend first for persistence
    String videoPathToUse = widget.videoUri;
    int?
        backendDuration; // Duration detected by backend (more reliable for WebM)

    if (kIsWeb && widget.videoUri.startsWith('blob:')) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing video for editing...')),
        );
        final uploadResult =
            await ApiService().uploadTemporaryMedia(widget.videoUri, 'video');
        if (uploadResult != null) {
          final backendUrl = uploadResult['url'] as String?;
          backendDuration = uploadResult['duration'] as int?;
          print('📊 Backend detected duration: ${backendDuration}s');
          if (backendUrl != null) {
            videoPathToUse = backendUrl;
          }
        }
      } catch (e) {
        print('⚠️ Failed to upload blob before editor: $e');
        // Continue with blob URL - editor will handle it
      }
    }

    // IMPORTANT: Clear any previous video editor state before starting fresh
    // This ensures old video data doesn't persist when editing a new video
    await StatePersistence.clearVideoEditorState();

    // Save current preview state (not editor state)
    await _saveState();

    // Use backend duration if available (more accurate for WebM), fallback to widget.duration
    final durationToUse = backendDuration ?? widget.duration;
    print(
        '🎬 Using duration for editor: ${durationToUse}s (backend: $backendDuration, widget: ${widget.duration})');

    // Navigate to VideoEditorScreenWeb with fresh state
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoEditorScreenWeb(
          videoPath: videoPathToUse,
          duration: durationToUse > 0 ? Duration(seconds: durationToUse) : null,
        ),
      ),
    );

    if (editedPath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video edited successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  void _handleAddCaptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Add captions feature coming soon'),
        backgroundColor: AppColors.infoMain,
      ),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundSecondary,
        title: Text(
          'Delete Video',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this video? This action cannot be undone.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(
              'Delete',
              style: AppTypography.button.copyWith(
                color: AppColors.errorMain,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    // Check bank details before publishing
    final hasBankDetails = await checkBankDetailsAndNavigate(context);
    if (!hasBankDetails || !mounted) {
      return;
    }

    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a title for your podcast'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload video file first (supports file paths, blob URLs, and http URLs)
      String videoUrl;
      String? thumbnailUrl;

      // Show upload progress
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Uploading video...'),
            ],
          ),
          backgroundColor: AppColors.infoMain,
          duration: const Duration(seconds: 60),
        ),
      );

      // Upload video - ApiService.uploadVideo() handles blob URLs via _createMultipartFileFromSource()
      final videoUploadResponse = await ApiService().uploadVideo(
        widget.videoUri,
        generateThumbnail: true,
      );
      videoUrl = videoUploadResponse['url'] as String;
      thumbnailUrl = videoUploadResponse['thumbnail_url'] as String?;

      // Hide upload progress snackbar immediately
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        // Show success message immediately after upload completes
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Video uploaded successfully!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // If auto-generated thumbnail, use it as default
      if (thumbnailUrl != null && _selectedThumbnail == null) {
        _selectedThumbnail = thumbnailUrl;
      }

      // Create podcast with thumbnail
      await ApiService().createPodcast(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        videoUrl: videoUrl,
        coverImage: _selectedThumbnail,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      // Clear saved state after successful publish
      await StatePersistence.clearVideoPreviewState();

      // Wait a moment before showing dialog to ensure SnackBar is visible
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Video Published',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Your video podcast has been published and shared with the community!',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Go back to VideoPodcastCreateScreen
              },
              child: Text(
                'OK',
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to publish podcast: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins}:${secs.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes == 0) return '0 Bytes';
    if (bytes < 1024) return '$bytes Bytes';

    final k = 1024;
    final sizes = ['Bytes', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();

    while (size >= k && i < sizes.length - 1) {
      size /= k;
      i++;
    }

    i = i.clamp(0, sizes.length - 1);

    return '${size.toStringAsFixed(2)} ${sizes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (context.mounted) {
          _handleBack();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
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
                  onPressed: _handleBack,
                ),
                Expanded(
                  child: StyledPageHeader(
                    title: 'Video Preview',
                    size: StyledPageHeaderSize.h2,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: AppColors.errorMain),
                  onPressed: _handleDelete,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Main Content: Horizontal Layout
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // On smaller screens, stack vertically; on larger screens, use horizontal layout
                  final useHorizontalLayout = constraints.maxWidth > 1024;

                  if (useHorizontalLayout) {
                    // Horizontal Layout: Video on left, controls on right
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Video Player Section (Left - 60-70%)
                        Expanded(
                          flex: 3,
                          child: SectionContainer(
                            showShadow: true,
                            padding: EdgeInsets.zero,
                            child: _buildVideoPlayer(),
                          ),
                        ),
                        SizedBox(width: AppSpacing.large),
                        // Controls & Form Section (Right - 30-40%)
                        Expanded(
                          flex: 2,
                          child: SectionContainer(
                            showShadow: true,
                            child: _buildControlsAndForm(),
                          ),
                        ),
                      ],
                    );
                  } else {
                    // Vertical Layout for smaller screens
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionContainer(
                            showShadow: true,
                            padding: EdgeInsets.zero,
                            child: _buildVideoPlayer(),
                          ),
                          const SizedBox(height: AppSpacing.large),
                          SectionContainer(
                            showShadow: true,
                            child: _buildControlsAndForm(),
                          ),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildVideoPlayer() {
    return _isInitializing
        ? Container(
            height: 400,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: AppColors.primaryMain,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'Loading video...',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          )
        : _hasError
            ? Container(
                height: 400,
                child: Center(
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
                        'Error loading video',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.small),
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.medium),
                          child: Text(
                            _errorMessage!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            : _controller != null && _controller!.value.isInitialized
                ? MouseRegion(
                    onEnter: (_) => _onMouseEnter(),
                    onExit: (_) => _onMouseExit(),
                    onHover: (_) => _onMouseMove(),
                    child: GestureDetector(
                      onTap: _handlePlayPause,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLarge),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Video Player
                              VideoPlayer(_controller!),

                              // Controls Overlay
                              AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.3),
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      stops: const [0.0, 0.6, 1.0],
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Center Play/Pause Button
                                      if (!_controller!.value.isPlaying ||
                                          _isMouseOverVideo)
                                        Center(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: _handlePlayPause,
                                              child: Container(
                                                width: 80,
                                                height: 80,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primaryMain
                                                      .withOpacity(0.9),
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.3),
                                                      blurRadius: 12,
                                                      offset:
                                                          const Offset(0, 4),
                                                    ),
                                                  ],
                                                ),
                                                child: Icon(
                                                  _controller!.value.isPlaying
                                                      ? Icons.pause
                                                      : Icons.play_arrow,
                                                  color: Colors.white,
                                                  size: 48,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Bottom Controls
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding:
                                              EdgeInsets.all(AppSpacing.medium),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Progress Bar
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: Text(
                                                      _formatTime((_isScrubbing
                                                          ? _scrubValue.toInt()
                                                          : _controller!
                                                              .value
                                                              .position
                                                              .inSeconds)),
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Builder(
                                                      builder: (context) {
                                                        // Get duration and ensure it's valid
                                                        final durationSeconds =
                                                            _controller!
                                                                .value
                                                                .duration
                                                                .inSeconds;
                                                        final positionSeconds =
                                                            _isScrubbing
                                                                ? _scrubValue
                                                                : _controller!
                                                                    .value
                                                                    .position
                                                                    .inSeconds
                                                                    .toDouble();

                                                        // Ensure max is always greater than min
                                                        // If duration is 0 or invalid, use a default of 1 second
                                                        final maxValue =
                                                            durationSeconds > 0
                                                                ? durationSeconds
                                                                    .toDouble()
                                                                : 1.0;

                                                        // Clamp position to valid range
                                                        final clampedValue =
                                                            positionSeconds
                                                                .clamp(0.0,
                                                                    maxValue);

                                                        // Only show slider if duration is valid
                                                        if (maxValue <= 0 ||
                                                            maxValue.isNaN ||
                                                            maxValue
                                                                .isInfinite) {
                                                          return Container(
                                                            height: 4,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withOpacity(
                                                                      0.3),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          2),
                                                            ),
                                                          );
                                                        }

                                                        return SliderTheme(
                                                          data: SliderTheme.of(
                                                                  context)
                                                              .copyWith(
                                                            trackHeight: 4,
                                                            thumbShape:
                                                                const RoundSliderThumbShape(
                                                              enabledThumbRadius:
                                                                  8,
                                                            ),
                                                            overlayShape:
                                                                const RoundSliderOverlayShape(
                                                              overlayRadius: 16,
                                                            ),
                                                          ),
                                                          child: Slider(
                                                            value: clampedValue,
                                                            min: 0.0,
                                                            max: maxValue,
                                                            activeColor:
                                                                AppColors
                                                                    .primaryMain,
                                                            inactiveColor: Colors
                                                                .white
                                                                .withOpacity(
                                                                    0.3),
                                                            thumbColor: AppColors
                                                                .primaryMain,
                                                            onChangeStart:
                                                                (value) {
                                                              if (maxValue >
                                                                  0) {
                                                                setState(() {
                                                                  _isScrubbing =
                                                                      true;
                                                                  _scrubValue =
                                                                      value.clamp(
                                                                          0.0,
                                                                          maxValue);
                                                                  _wasPlayingBeforeScrub =
                                                                      _controller!
                                                                          .value
                                                                          .isPlaying;
                                                                });
                                                                _controller!
                                                                    .pause();
                                                              }
                                                            },
                                                            onChanged: (value) {
                                                              if (maxValue >
                                                                  0) {
                                                                setState(() {
                                                                  _scrubValue =
                                                                      value.clamp(
                                                                          0.0,
                                                                          maxValue);
                                                                });
                                                              }
                                                            },
                                                            onChangeEnd:
                                                                (value) async {
                                                              if (maxValue >
                                                                  0) {
                                                                final clampedEndValue =
                                                                    value.clamp(
                                                                        0.0,
                                                                        maxValue);
                                                                await _controller!
                                                                    .seekTo(Duration(
                                                                        seconds:
                                                                            clampedEndValue.toInt()));
                                                                setState(() {
                                                                  _isScrubbing =
                                                                      false;
                                                                });
                                                                if (_wasPlayingBeforeScrub) {
                                                                  _controller!
                                                                      .play();
                                                                  _startControlsTimer();
                                                                }
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 60,
                                                    child: Text(
                                                      _formatTime(_controller!
                                                          .value
                                                          .duration
                                                          .inSeconds),
                                                      style: AppTypography
                                                          .bodySmall
                                                          .copyWith(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                      textAlign:
                                                          TextAlign.right,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
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
                      ),
                    ),
                  )
                : Container(
                    height: 400,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMain,
                      ),
                    ),
                  );
  }

  Widget _buildControlsAndForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Buttons
          // Edit Video button (Captions removed - description field serves same purpose)
          StyledPillButton(
            label: 'Edit Video',
            icon: Icons.edit,
            onPressed: _handleEdit,
            variant: StyledPillButtonVariant.outlined,
          ),
          const SizedBox(height: AppSpacing.large),

          Text(
            'Podcast Details',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.large),

          // Title
          TextField(
            controller: _titleController,
            onChanged: (_) => _saveState(), // Auto-save on change
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter podcast title',
              hintStyle: TextStyle(color: AppColors.textPlaceholder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Description
          TextField(
            controller: _descriptionController,
            onChanged: (_) => _saveState(), // Auto-save on change
            maxLines: 3,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter podcast description',
              hintStyle: TextStyle(color: AppColors.textPlaceholder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
              ),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Thumbnail Selection
          ThumbnailSelector(
            isVideo: true,
            videoUrl: _videoUrl ?? widget.videoUri,
            onThumbnailSelected: (thumbnailUrl) {
              setState(() {
                _selectedThumbnail = thumbnailUrl;
              });
              _saveState(); // Save when thumbnail changes
            },
            initialThumbnail: _selectedThumbnail,
          ),
          const SizedBox(height: AppSpacing.large),

          // Publish Button
          SizedBox(
            width: double.infinity,
            child: StyledPillButton(
              label: _isLoading ? 'Publishing...' : 'Publish Podcast',
              onPressed: _isLoading ? null : _handlePublish,
              variant: StyledPillButtonVariant.filled,
            ),
          ),
        ],
      ),
    );
  }
}
