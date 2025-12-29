import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../models/content_item.dart';
import 'dart:html' as html show document;

/// Video Player Full Screen - Exact replica of React Native implementation
/// Features auto-hiding controls, fullscreen toggle, and gradient background
class VideoPlayerFullScreen extends StatefulWidget {
  final String videoId;
  final String title;
  final String author;
  final int duration;
  final List<Color> gradientColors;
  final bool isFavorite;
  final String videoUrl;
  final VoidCallback? onBack;
  final VoidCallback? onDonate;
  final VoidCallback? onFavorite;
  final void Function(int)? onSeek;
  // Optional playlist support
  final List<ContentItem>? playlist;
  final int? initialIndex;

  const VideoPlayerFullScreen({
    super.key,
    required this.videoId,
    required this.title,
    required this.author,
    required this.duration,
    required this.gradientColors,
    required this.videoUrl,
    this.isFavorite = false,
    this.onBack,
    this.onDonate,
    this.onFavorite,
    this.onSeek,
    this.playlist,
    this.initialIndex,
  });

  @override
  State<VideoPlayerFullScreen> createState() => _VideoPlayerFullScreenState();
}

class _VideoPlayerFullScreenState extends State<VideoPlayerFullScreen> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  bool _isFullscreen = false;
  bool _showControls = true;
  int _currentTime = 0;
  late List<ContentItem> _playlist;
  late int _currentIndex;

  // Seek/Scrubbing
  bool _isScrubbing = false;
  bool _isSeeking = false;
  double _scrubValue = 0.0;
  bool _wasPlayingBeforeScrub = false;

  // Duration management
  Duration? _validDuration;
  bool _durationError = false;
  String? _durationErrorMessage;

  // Autoplay management
  bool _autoplayBlocked = false;

  // Mouse movement detection
  Timer? _hideControlsTimer;
  bool _isMouseOverVideo = false;

  // Volume control
  double _volume = 1.0;
  bool _isMuted = false;
  bool _showVolumeSlider = false;

  // Playback speed
  double _playbackSpeed = 1.0;
  final List<double> _availableSpeeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  // Duration logging throttle - only log when source changes
  String? _lastLoggedDurationSource;

  // Buffering state tracking - uses controller's native buffering state only
  bool _isBuffering = false;

  // Focus node for keyboard shortcuts
  final FocusNode _focusNode = FocusNode();

  ContentItem get _currentItem => _playlist[_currentIndex];
  bool get _hasNext => _currentIndex < _playlist.length - 1;
  bool get _hasPrevious => _currentIndex > 0;

  @override
  void initState() {
    super.initState();
    // Build playlist: if none provided, create a single-item list from the widget props
    if (widget.playlist != null && widget.playlist!.isNotEmpty) {
      _playlist = List<ContentItem>.from(widget.playlist!);
      final providedIndex = widget.initialIndex ?? 0;
      _currentIndex = providedIndex.clamp(0, _playlist.length - 1);
    } else {
      _playlist = [
        ContentItem(
          id: widget.videoId,
          title: widget.title,
          creator: widget.author,
          description: null,
          coverImage: null,
          audioUrl: null,
          videoUrl: widget.videoUrl,
          duration: Duration(seconds: widget.duration),
          category: 'Video Podcast',
          createdAt: DateTime.now(),
        ),
      ];
      _currentIndex = 0;
    }

    _initializePlayer();
    _startControlsTimer();

    // Listen for fullscreen changes (when user presses ESC)
    if (kIsWeb) {
      html.document.onFullscreenChange.listen((_) {
        if (mounted) {
          final isCurrentlyFullscreen = html.document.fullscreenElement != null;
          if (isCurrentlyFullscreen != _isFullscreen) {
            setState(() {
              _isFullscreen = isCurrentlyFullscreen;
            });
          }
        }
      });
    }

    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  /// Handle keyboard shortcuts
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    switch (event.logicalKey.keyLabel) {
      case ' ': // Space - Play/Pause
        _togglePlayPause();
        break;
      case 'Arrow Left': // Left arrow - Skip back 10s
        _skipBackward();
        break;
      case 'Arrow Right': // Right arrow - Skip forward 10s
        _skipForward();
        break;
      case 'Arrow Up': // Up arrow - Volume up
        _adjustVolume(0.1);
        break;
      case 'Arrow Down': // Down arrow - Volume down
        _adjustVolume(-0.1);
        break;
      case 'F': // F - Toggle fullscreen
      case 'f':
        _toggleFullscreen();
        break;
      case 'M': // M - Toggle mute
      case 'm':
        _toggleMute();
        break;
    }
  }

  void _skipForward() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final validDuration = _getValidDuration();
    if (validDuration == null) {
      debugPrint(
          'VideoPlayer: Cannot skip forward - no valid duration available');
      return;
    }

    final newPosition =
        _controller!.value.position + const Duration(seconds: 10);
    final maxPosition = validDuration;
    _controller!.seekTo(newPosition > maxPosition ? maxPosition : newPosition);
    _showControlsWithAutoHide();
  }

  void _skipBackward() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final newPosition =
        _controller!.value.position - const Duration(seconds: 10);
    _controller!.seekTo(newPosition.isNegative ? Duration.zero : newPosition);
    _showControlsWithAutoHide();
  }

  void _adjustVolume(double delta) {
    final newVolume = (_volume + delta).clamp(0.0, 1.0);
    setState(() {
      _volume = newVolume;
      _isMuted = newVolume == 0;
    });
    _controller?.setVolume(newVolume);
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _controller?.setVolume(_isMuted ? 0 : _volume);
  }

  void _setPlaybackSpeed(double speed) {
    setState(() {
      _playbackSpeed = speed;
    });
    _controller?.setPlaybackSpeed(speed);
  }

  /// Get valid duration from any available source
  /// Checks in order: widget duration (database), _validDuration, controller duration
  /// Widget duration is most reliable as it comes from the database
  /// Returns null only if no valid duration is available from any source
  Duration? _getValidDuration() {
    // First, check widget-provided duration (most reliable, from database)
    if (widget.duration > 0) {
      final widgetDuration = Duration(seconds: widget.duration);

      // If controller duration is available, check if it's suspiciously different
      if (_controller != null && _controller!.value.isInitialized) {
        final controllerDuration = _controller!.value.duration;
        if (controllerDuration != Duration.zero &&
            controllerDuration.inMilliseconds > 0 &&
            controllerDuration.inSeconds.isFinite &&
            !controllerDuration.inSeconds.isNaN &&
            !controllerDuration.inSeconds.isInfinite) {
          // Sanity check: if controller duration is less than 10% of widget duration, it's likely wrong
          // Trust widget duration instead
          final controllerSeconds = controllerDuration.inSeconds;
          final widgetSeconds = widget.duration;
          if (controllerSeconds < widgetSeconds * 0.1) {
            _logDurationSource('widget_override',
                'Controller duration ($controllerSeconds s) is suspiciously small compared to widget duration ($widgetSeconds s), using widget duration');
            return widgetDuration;
          }
        }
      }

      _logDurationSource(
          'widget', 'Using widget duration: ${widget.duration}s');
      return widgetDuration;
    }

    // Second, check _validDuration (cached validated duration)
    if (_validDuration != null &&
        _validDuration != Duration.zero &&
        _validDuration!.inMilliseconds > 0 &&
        _validDuration!.inSeconds.isFinite &&
        !_validDuration!.inSeconds.isNaN &&
        !_validDuration!.inSeconds.isInfinite) {
      _logDurationSource(
          'cached', 'Using _validDuration: ${_validDuration!.inSeconds}s');
      return _validDuration;
    }

    // Third, fall back to controller duration (only if widget duration not available)
    if (_controller != null && _controller!.value.isInitialized) {
      final controllerDuration = _controller!.value.duration;
      if (controllerDuration != Duration.zero &&
          controllerDuration.inMilliseconds > 0 &&
          controllerDuration.inSeconds.isFinite &&
          !controllerDuration.inSeconds.isNaN &&
          !controllerDuration.inSeconds.isInfinite) {
        _logDurationSource('controller',
            'Using controller duration: ${controllerDuration.inSeconds}s');
        return controllerDuration;
      }
    }

    // No valid duration available
    _logDurationSource('none', 'No valid duration available from any source');
    return null;
  }

  /// Get duration specifically for seeking operations
  /// Prioritizes controller duration (actual video duration) over widget duration
  /// This ensures we never seek beyond the actual video length
  Duration? _getDurationForSeeking() {
    // First, check controller duration (actual video duration) - most reliable for seeking
    if (_controller != null && _controller!.value.isInitialized) {
      final controllerDuration = _controller!.value.duration;
      if (controllerDuration != Duration.zero &&
          controllerDuration.inMilliseconds > 0 &&
          controllerDuration.inSeconds.isFinite &&
          !controllerDuration.inSeconds.isNaN &&
          !controllerDuration.inSeconds.isInfinite) {
        return controllerDuration;
      }
    }

    // Second, check _validDuration (cached validated duration)
    if (_validDuration != null &&
        _validDuration != Duration.zero &&
        _validDuration!.inMilliseconds > 0 &&
        _validDuration!.inSeconds.isFinite &&
        !_validDuration!.inSeconds.isNaN &&
        !_validDuration!.inSeconds.isInfinite) {
      return _validDuration;
    }

    // Third, fall back to widget duration (from database) - least reliable for seeking
    if (widget.duration > 0) {
      return Duration(seconds: widget.duration);
    }

    return null;
  }

  /// Helper to log duration source only when it changes (throttled logging)
  void _logDurationSource(String source, String message) {
    if (_lastLoggedDurationSource != source) {
      _lastLoggedDurationSource = source;
      debugPrint('VideoPlayer: $message');
    }
  }

  /// Ensure video duration is available and valid
  /// Attempts to load metadata if duration is not immediately available
  Future<Duration> _ensureDurationAvailable() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint(
          'VideoPlayer: Controller not initialized, cannot get duration');
      throw Exception('Video controller not initialized');
    }

    Duration? duration = _controller!.value.duration;
    debugPrint('VideoPlayer: Initial duration check: ${duration.inSeconds}s');

    // Check if duration is valid
    bool isDurationValid = duration != Duration.zero &&
        duration.inMilliseconds > 0 &&
        duration.inSeconds.isFinite &&
        !duration.inSeconds.isNaN &&
        !duration.inSeconds.isInfinite;

    if (isDurationValid) {
      debugPrint('VideoPlayer: Duration is valid: ${duration.inSeconds}s');
      return duration;
    }

    debugPrint('VideoPlayer: Duration invalid, attempting to load metadata...');

    // Try to trigger metadata loading by seeking to a large position and back
    try {
      debugPrint('VideoPlayer: Attempting seek-based metadata load...');
      await _controller!.seekTo(const Duration(seconds: 999999));
      await Future.delayed(const Duration(milliseconds: 200));
      await _controller!.seekTo(Duration.zero);
      await Future.delayed(const Duration(milliseconds: 200));
      duration = _controller!.value.duration;

      isDurationValid = duration != Duration.zero &&
          duration.inMilliseconds > 0 &&
          duration.inSeconds.isFinite &&
          !duration.inSeconds.isNaN &&
          !duration.inSeconds.isInfinite;

      if (isDurationValid) {
        debugPrint(
            'VideoPlayer: Duration loaded via seek: ${duration.inSeconds}s');
        return duration;
      }
    } catch (e) {
      debugPrint('VideoPlayer: Seek-based metadata load failed: $e');
    }

    // Alternative: Try playing briefly and pausing
    try {
      debugPrint('VideoPlayer: Attempting play-based metadata load...');
      final wasPlaying = _controller!.value.isPlaying;
      await _controller!.play();
      await Future.delayed(const Duration(milliseconds: 500));
      await _controller!.pause();
      await Future.delayed(const Duration(milliseconds: 200));
      duration = _controller!.value.duration;

      isDurationValid = duration != Duration.zero &&
          duration.inMilliseconds > 0 &&
          duration.inSeconds.isFinite &&
          !duration.inSeconds.isNaN &&
          !duration.inSeconds.isInfinite;

      if (isDurationValid) {
        debugPrint(
            'VideoPlayer: Duration loaded via play: ${duration.inSeconds}s');
        if (wasPlaying) {
          await _controller!.play();
        }
        return duration;
      }
    } catch (e) {
      debugPrint('VideoPlayer: Play-based metadata load failed: $e');
    }

    // Wait with retries for duration to become available (increased attempts and delays)
    int attempts = 0;
    const int maxAttempts = 50; // Increased from 30
    while (!isDurationValid && attempts < maxAttempts) {
      // Use exponential backoff for longer waits
      final delayMs = attempts < 10
          ? 200
          : attempts < 20
              ? 500
              : 1000;
      await Future.delayed(Duration(milliseconds: delayMs));
      duration = _controller!.value.duration;

      isDurationValid = duration != Duration.zero &&
          duration.inMilliseconds > 0 &&
          duration.inSeconds.isFinite &&
          !duration.inSeconds.isNaN &&
          !duration.inSeconds.isInfinite;

      if (isDurationValid) {
        debugPrint(
            'VideoPlayer: Duration loaded after ${attempts + 1} retries: ${duration.inSeconds}s');
        return duration;
      }
      attempts++;
    }

    // Final check after longer wait (increased wait time)
    if (!isDurationValid) {
      await Future.delayed(
          const Duration(seconds: 2)); // Increased from 1 second
      duration = _controller!.value.duration;

      isDurationValid = duration != Duration.zero &&
          duration.inMilliseconds > 0 &&
          duration.inSeconds.isFinite &&
          !duration.inSeconds.isNaN &&
          !duration.inSeconds.isInfinite;
    }

    // Use widget's provided duration as fallback (don't throw if available)
    if (!isDurationValid && widget.duration > 0) {
      debugPrint(
          'VideoPlayer: Using widget-provided duration as fallback: ${widget.duration}s');
      return Duration(seconds: widget.duration);
    }

    // Only throw if we truly have no duration source available
    if (!isDurationValid && widget.duration <= 0) {
      debugPrint(
          'VideoPlayer: Could not determine video duration and no widget duration available');
      throw Exception(
          'Video duration is not available. The video may be corrupted or in an unsupported format.');
    }

    // If we get here, we should have widget duration (shouldn't happen, but return it)
    return Duration(seconds: widget.duration);
  }

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = _currentItem.videoUrl ?? widget.videoUrl;
      debugPrint('VideoPlayer: Initializing player for URL: $videoUrl');
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      debugPrint('VideoPlayer: Controller initialized');

      // Ensure duration is available before proceeding
      // First check if widget provides duration (database duration is most reliable)
      if (widget.duration > 0) {
        _validDuration = Duration(seconds: widget.duration);
        _durationError = false;
        _durationErrorMessage = null;
        debugPrint(
            'VideoPlayer: Using widget-provided duration (from database): ${_validDuration!.inSeconds}s');
      } else {
        // If no widget duration, try to extract from video metadata
        try {
          _validDuration = await _ensureDurationAvailable();
          debugPrint(
              'VideoPlayer: Valid duration obtained from video metadata: ${_validDuration!.inSeconds}s');
          _durationError = false;
          _durationErrorMessage = null;
        } catch (e) {
          debugPrint('VideoPlayer: Duration detection failed: $e');
          // Check if we have any fallback duration
          final fallbackDuration = _getValidDuration();
          if (fallbackDuration != null) {
            _validDuration = fallbackDuration;
            debugPrint(
                'VideoPlayer: Using fallback duration: ${fallbackDuration.inSeconds}s');
          } else {
            // No duration available - but DON'T treat this as an error
            // Video can still play, just seeking will be disabled until duration is detected
            _validDuration = null;
            debugPrint(
                'VideoPlayer: Duration unknown - playback will continue, seeking disabled until duration detected');
          }
          // Never set _durationError to true - we want playback to work regardless
          _durationError = false;
          _durationErrorMessage = null;
        }
      }

      // Attempt to play video with error handling for autoplay restrictions
      debugPrint('VideoPlayer: Attempting to play video');
      try {
        await _controller!.play();

        // Wait briefly and verify playback actually started
        await Future.delayed(const Duration(milliseconds: 500));

        final isActuallyPlaying = _controller!.value.isPlaying;
        final isBuffering = _controller!.value.isBuffering;
        final currentPosition = _controller!.value.position.inMilliseconds;

        if (isActuallyPlaying && !isBuffering) {
          debugPrint(
              'VideoPlayer: Video started playing successfully (position: ${currentPosition}ms)');
          _autoplayBlocked = false;
          _isBuffering = false;
        } else if (isBuffering) {
          debugPrint('VideoPlayer: Video is buffering - waiting for content');
          _autoplayBlocked = false;
          _isBuffering = true;
        } else {
          // play() succeeded but video isn't actually playing yet
          debugPrint(
              'VideoPlayer: play() returned but video not yet playing (isPlaying: $isActuallyPlaying, isBuffering: $isBuffering)');
          _isBuffering = true;
        }
      } catch (e) {
        debugPrint('VideoPlayer: Autoplay blocked by browser: $e');
        _autoplayBlocked = true;
        // Don't treat autoplay blocking as a fatal error - user can click play button
      }

      _controller!.addListener(_videoListener);

      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = false;
        });
      }
    } catch (e) {
      debugPrint('VideoPlayer: Error initializing player: $e');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
          // Note: Don't set _durationError here - this is a video loading error, not a duration issue
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    // Add initialization check - don't process updates if controller is not initialized
    // This prevents errors during temporary uninitialization states (e.g., during buffering on web)
    if (!_controller!.value.isInitialized) return;

    // Don't update position during scrubbing
    if (_isScrubbing) return;

    // Don't update position during seeking
    if (_isSeeking) return;

    // Track buffering state from controller's native isBuffering state only
    // Removed artificial stall detection - rely on video_player's native buffering detection
    final isControllerBuffering = _controller!.value.isBuffering;

    // Update buffering state based on controller's native state
    if (isControllerBuffering != _isBuffering) {
      if (isControllerBuffering) {
        debugPrint('VideoPlayer: Buffering started');
      } else {
        debugPrint('VideoPlayer: Buffering ended');
      }
      setState(() => _isBuffering = isControllerBuffering);
    }

    // Detect when video starts playing (to clear autoplay blocked flag)
    if (_autoplayBlocked && _controller!.value.isPlaying) {
      debugPrint(
          'VideoPlayer: Video started playing - clearing autoplay blocked flag');
      setState(() {
        _autoplayBlocked = false;
      });
    }

    // Check if duration becomes available after initialization
    // Only update if _validDuration is null or there's an error, AND widget duration is not available
    if ((_validDuration == null || _durationError) && widget.duration <= 0) {
      final controllerDuration = _controller!.value.duration;
      final isDurationValid = controllerDuration != Duration.zero &&
          controllerDuration.inMilliseconds > 0 &&
          controllerDuration.inSeconds.isFinite &&
          !controllerDuration.inSeconds.isNaN &&
          !controllerDuration.inSeconds.isInfinite;

      if (isDurationValid) {
        debugPrint(
            'VideoPlayer: Duration detected in listener: ${controllerDuration.inSeconds}s');
        setState(() {
          _validDuration = controllerDuration;
          _durationError = false;
          _durationErrorMessage = null;
        });
      }
    }

    setState(() {
      // Update current time for seek callback
      final position = _controller!.value.position;
      _currentTime = position.inSeconds;
      widget.onSeek?.call(_currentTime);
    });
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

  void _showControlsWithAutoHide() {
    _hideControlsTimer?.cancel();
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  void _hideControls() {
    _hideControlsTimer?.cancel();
    if (mounted && (_controller?.value.isPlaying ?? false)) {
      setState(() {
        _showControls = false;
      });
    }
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
    if (_controller?.value.isPlaying ?? false) {
      _hideControls();
    }
  }

  void _onMouseMove() {
    if (_isMouseOverVideo) {
      _showControlsWithAutoHide();
    }
  }

  void _toggleControls() {
    _showControlsWithAutoHide();
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;

    if (_controller!.value.isPlaying) {
      await _controller!.pause();
    } else {
      try {
        await _controller!.play();
        debugPrint('VideoPlayer: Video started playing via user interaction');
        // Clear autoplay blocked flag when user manually starts playback
        if (_autoplayBlocked) {
          setState(() {
            _autoplayBlocked = false;
          });
        }
      } catch (e) {
        debugPrint('VideoPlayer: Error playing video: $e');
      }
    }
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  Future<void> _seekTo(int seconds) async {
    // Wait for controller to be initialized (with retry for temporary uninitialization)
    if (_controller == null) {
      debugPrint('VideoPlayer: Cannot seek - controller is null');
      return;
    }

    // Retry logic for temporary uninitialization during buffering
    // On web, the video_player package can temporarily lose initialization state during network buffering
    int retryAttempts = 0;
    const maxRetryAttempts = 5;
    const retryDelay = Duration(milliseconds: 200);

    while (
        !_controller!.value.isInitialized && retryAttempts < maxRetryAttempts) {
      debugPrint(
          'VideoPlayer: Controller temporarily uninitialized, waiting... (attempt ${retryAttempts + 1}/$maxRetryAttempts)');
      await Future.delayed(retryDelay);
      retryAttempts++;
    }

    if (!_controller!.value.isInitialized) {
      debugPrint(
          'VideoPlayer: Cannot seek - controller not initialized after retries');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video is not ready for seeking'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
      return;
    }

    // Get duration specifically for seeking (prioritizes controller duration)
    Duration? durationToUse = _getDurationForSeeking();

    if (durationToUse == null) {
      debugPrint('VideoPlayer: Cannot seek - no valid duration available');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seeking is not available for this video'),
            duration: Duration(seconds: 2),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
      return;
    }

    // Set seeking flag synchronously to prevent listener from interfering
    setState(() {
      _isSeeking = true;
    });

    try {
      // Use the actual video duration for clamping
      final maxSeconds = durationToUse.inSeconds;
      final clamped = seconds.clamp(0, maxSeconds);
      debugPrint(
          'VideoPlayer: Seeking to ${clamped}s (requested: ${seconds}s, max: ${maxSeconds}s)');

      // Store current position before seek (to detect if seek fails and resets)
      final positionBeforeSeek = _controller!.value.position.inSeconds;

      // Perform the seek operation
      await _controller!.seekTo(Duration(seconds: clamped));

      // Wait for seek to complete (increased delay for better reliability)
      await Future.delayed(const Duration(milliseconds: 200));

      // Get the actual position after seek
      final actualPosition = _controller!.value.position.inSeconds;
      debugPrint(
          'VideoPlayer: Seek completed - actual position: ${actualPosition}s (requested: ${clamped}s)');

      // Validate seek result: if we requested a position > 0 but got 0, the seek failed
      // Also check if the actual position is significantly different from requested (more than 5 seconds)
      final seekFailed = (clamped > 0 && actualPosition == 0) ||
          (clamped > 5 && (actualPosition - clamped).abs() > 5);

      if (seekFailed) {
        debugPrint(
            'VideoPlayer: Seek failed - requested ${clamped}s but got ${actualPosition}s. Attempting recovery...');

        // Try to seek to a position slightly before the requested position (within actual duration)
        // This helps when seeking near the end of the video
        final recoveryPosition = (clamped - 1).clamp(0, maxSeconds);
        if (recoveryPosition > 0 && recoveryPosition < maxSeconds) {
          await _controller!.seekTo(Duration(seconds: recoveryPosition));
          await Future.delayed(const Duration(milliseconds: 200));
          final recoveredPosition = _controller!.value.position.inSeconds;
          debugPrint(
              'VideoPlayer: Recovery seek to ${recoveryPosition}s resulted in ${recoveredPosition}s');

          if (mounted) {
            setState(() {
              _currentTime = recoveredPosition;
              _isSeeking = false;
            });
          }
          return;
        }

        // If recovery failed, restore to position before seek
        debugPrint(
            'VideoPlayer: Recovery failed, restoring to position before seek: ${positionBeforeSeek}s');
        await _controller!.seekTo(Duration(seconds: positionBeforeSeek));
        await Future.delayed(const Duration(milliseconds: 200));

        if (mounted) {
          setState(() {
            _currentTime = positionBeforeSeek;
            _isSeeking = false;
          });
        }
        return;
      }

      // Update state once with final values
      if (mounted) {
        setState(() {
          _currentTime = actualPosition;
          _isSeeking = false;

          // Update _validDuration if controller now has a valid duration
          // Always prefer controller duration when available
          if (_controller!.value.duration != Duration.zero &&
              _controller!.value.duration.inMilliseconds > 0 &&
              _controller!.value.duration.inSeconds.isFinite) {
            final controllerDuration = _controller!.value.duration;
            _validDuration = controllerDuration;
            _durationError = false;
            _durationErrorMessage = null;
            debugPrint(
                'VideoPlayer: Updated _validDuration from controller: ${controllerDuration.inSeconds}s');
          }
        });
      }
    } catch (e) {
      debugPrint('VideoPlayer: Error during seek: $e');
      if (mounted) {
        setState(() {
          _isSeeking = false;
        });
      }
    }
  }

  void _toggleFullscreen() {
    if (!kIsWeb) {
      debugPrint('VideoPlayer: Fullscreen only available on web');
      return;
    }

    try {
      if (_isFullscreen) {
        debugPrint('VideoPlayer: Exiting fullscreen');
        html.document.exitFullscreen();
      } else {
        debugPrint('VideoPlayer: Entering fullscreen');
        html.document.documentElement?.requestFullscreen();
      }

      setState(() {
        _isFullscreen = !_isFullscreen;
      });
      _showControlsWithAutoHide();
    } catch (e) {
      debugPrint('VideoPlayer: Error toggling fullscreen: $e');
    }
  }

  Future<void> _loadEpisode(int newIndex) async {
    if (newIndex < 0 || newIndex >= _playlist.length) return;

    _controller?.removeListener(_videoListener);
    await _controller?.pause();
    await _controller?.dispose();
    _controller = null;

    setState(() {
      _isInitializing = true;
      _hasError = false;
      _currentIndex = newIndex;
      _currentTime = 0;
      _validDuration = null;
      _durationError = false;
      _durationErrorMessage = null;
      _lastLoggedDurationSource =
          null; // Reset logging throttle for new episode
      _isBuffering = false; // Reset buffering state for new episode
    });

    await _initializePlayer();
  }

  Future<void> _playNext() async {
    if (_hasNext) {
      await _loadEpisode(_currentIndex + 1);
    }
  }

  Future<void> _playPrevious() async {
    if (_hasPrevious) {
      await _loadEpisode(_currentIndex - 1);
    }
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(1, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  /// Handle back button - exit fullscreen first if needed
  void _handleBack() {
    // Exit fullscreen before navigating
    if (kIsWeb && _isFullscreen) {
      try {
        html.document.exitFullscreen();
        setState(() {
          _isFullscreen = false;
        });
      } catch (e) {
        debugPrint('VideoPlayer: Error exiting fullscreen on back: $e');
      }
    }
    // Call the provided callback
    widget.onBack?.call();
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _focusNode.dispose();
    // Exit fullscreen on dispose if still in fullscreen
    if (kIsWeb && _isFullscreen) {
      try {
        html.document.exitFullscreen();
      } catch (e) {
        debugPrint('VideoPlayer: Error exiting fullscreen on dispose: $e');
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      autofocus: true,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.backgroundPrimary,
                AppColors.primaryMain.withOpacity(0.1),
              ],
            ),
          ),
          child: Column(
            children: [
              // Top Bar (hidden in fullscreen)
              if (!_isFullscreen)
                SafeArea(
                  child: Container(
                    padding: EdgeInsets.all(AppSpacing.medium),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          color: AppColors.primaryMain,
                          onPressed: _handleBack,
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              'Video Podcast',
                              style: AppTypography.heading4.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 180,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ElevatedButton.icon(
                                  onPressed: widget.onDonate,
                                  icon: const Icon(Icons.favorite, size: 20),
                                  label: const Text('Donate'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        AppColors.primaryMain.withOpacity(0.9),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.small,
                                      vertical: AppSpacing.tiny,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  widget.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                color: Colors.white,
                                onPressed: widget.onFavorite,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Video area
              Expanded(
                child: Center(
                  child: MouseRegion(
                    onEnter: (_) => _onMouseEnter(),
                    onExit: (_) => _onMouseExit(),
                    onHover: (_) => _onMouseMove(),
                    child: GestureDetector(
                      onTap: _toggleControls,
                      child: Container(
                        width: double.infinity,
                        color: AppColors.backgroundPrimary,
                        child: Stack(
                          children: [
                            // Video Player
                            if (_isInitializing)
                              Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.primaryMain),
                              )
                            else if (_hasError)
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 80,
                                      color: AppColors.errorMain,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading video',
                                      style: TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 18),
                                    ),
                                  ],
                                ),
                              )
                            else if (_controller != null &&
                                _controller!.value.isInitialized)
                              Positioned.fill(
                                child: Center(
                                  child: AspectRatio(
                                    aspectRatio: _controller!.value.aspectRatio,
                                    child: VideoPlayer(_controller!),
                                  ),
                                ),
                              ),

                            // Play button overlay (shown when autoplay is blocked)
                            if (_autoplayBlocked &&
                                _controller != null &&
                                _controller!.value.isInitialized &&
                                !_controller!.value.isPlaying)
                              Positioned.fill(
                                child: GestureDetector(
                                  onTap: _togglePlayPause,
                                  child: Container(
                                    color: Colors.black.withOpacity(0.3),
                                    child: Center(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.6),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.5),
                                              blurRadius: 20,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: const Icon(
                                              Icons.play_arrow_rounded),
                                          iconSize: 80,
                                          color: Colors.white,
                                          onPressed: _togglePlayPause,
                                          tooltip: 'Play Video',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            // Buffering overlay (shown when video is buffering mid-playback)
                            if (_isBuffering &&
                                !_isInitializing &&
                                _controller != null &&
                                _controller!.value.isInitialized)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black.withOpacity(0.4),
                                  child: Center(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Buffering...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                            // Floating Back Button (always visible, especially in fullscreen)
                            if (_isFullscreen && _showControls)
                              Positioned(
                                top: AppSpacing.large,
                                left: AppSpacing.large,
                                child: MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.arrow_back),
                                      color: Colors.white,
                                      iconSize: 28,
                                      onPressed: _handleBack,
                                      tooltip: 'Exit Fullscreen & Back',
                                    ),
                                  ),
                                ),
                              ),

                            // Bottom controls bar (positioned over video)
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: IgnorePointer(
                                  ignoring: !_showControls,
                                  child: Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(AppSpacing.large),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withOpacity(0.4),
                                          Colors.black.withOpacity(0.8),
                                        ],
                                        stops: const [0.0, 0.4, 1.0],
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: SliderTheme(
                                                data: SliderTheme.of(context)
                                                    .copyWith(
                                                  trackHeight: 4,
                                                  thumbShape:
                                                      const RoundSliderThumbShape(
                                                    enabledThumbRadius: 8,
                                                  ),
                                                  overlayShape:
                                                      const RoundSliderOverlayShape(
                                                    overlayRadius: 16,
                                                  ),
                                                ),
                                                child: Builder(
                                                  builder: (context) {
                                                    // Calculate max value using _getDurationForSeeking() helper (prioritizes actual video duration)
                                                    final validDuration =
                                                        _getDurationForSeeking();
                                                    double maxValue = 1.0;

                                                    if (validDuration != null) {
                                                      maxValue = validDuration
                                                          .inSeconds
                                                          .toDouble();
                                                    }

                                                    // Ensure minimum value of 1.0 to avoid division by zero
                                                    maxValue = maxValue.clamp(
                                                        1.0, double.infinity);

                                                    // Check if we have any valid duration before allowing seeking
                                                    final canSeek =
                                                        validDuration != null;

                                                    return Slider(
                                                      value: _isScrubbing
                                                          ? _scrubValue.clamp(
                                                              0.0, maxValue)
                                                          : _currentTime
                                                              .toDouble()
                                                              .clamp(0.0,
                                                                  maxValue),
                                                      min: 0.0,
                                                      max: maxValue,
                                                      activeColor: canSeek
                                                          ? Colors.white
                                                          : Colors.white
                                                              .withOpacity(0.5),
                                                      inactiveColor: canSeek
                                                          ? Colors.white
                                                              .withOpacity(0.3)
                                                          : Colors.white
                                                              .withOpacity(0.2),
                                                      thumbColor: Colors.white,
                                                      onChangeStart: (value) {
                                                        if (!canSeek) {
                                                          debugPrint(
                                                              'VideoPlayer: Seeking disabled - no valid duration available');
                                                          return;
                                                        }
                                                        setState(() {
                                                          _isScrubbing = true;
                                                          _scrubValue = value;
                                                          _wasPlayingBeforeScrub =
                                                              _controller?.value
                                                                      .isPlaying ??
                                                                  false;
                                                        });
                                                        _controller?.pause();
                                                      },
                                                      onChanged: (value) {
                                                        if (!canSeek) {
                                                          return;
                                                        }
                                                        setState(() {
                                                          _scrubValue = value;
                                                          _currentTime =
                                                              value.toInt();
                                                        });
                                                        widget.onSeek?.call(
                                                            _currentTime);
                                                      },
                                                      onChangeEnd:
                                                          (value) async {
                                                        if (!canSeek) {
                                                          setState(() {
                                                            _isScrubbing =
                                                                false;
                                                          });
                                                          return;
                                                        }
                                                        await _seekTo(
                                                            value.toInt());
                                                        setState(() {
                                                          _isScrubbing = false;
                                                        });
                                                        if (_wasPlayingBeforeScrub) {
                                                          _controller?.play();
                                                          _startControlsTimer();
                                                        }
                                                      },
                                                    );
                                                  },
                                                ),
                                              ),
                                            ),
                                            const SizedBox(
                                                width: AppSpacing.small),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: Icon(
                                                  _isFullscreen
                                                      ? Icons
                                                          .fullscreen_exit_rounded
                                                      : Icons
                                                          .fullscreen_rounded,
                                                ),
                                                color: Colors.white,
                                                onPressed: _toggleFullscreen,
                                                tooltip: _isFullscreen
                                                    ? 'Exit Fullscreen (F)'
                                                    : 'Fullscreen (F)',
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              _formatTime(_currentTime),
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            Text(
                                              _getDurationForSeeking() != null
                                                  ? _formatTime(
                                                      _getDurationForSeeking()!
                                                          .inSeconds)
                                                  : '--:--',
                                              style: AppTypography.caption
                                                  .copyWith(
                                                color: Colors.white
                                                    .withOpacity(0.7),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.large),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Previous
                                            MouseRegion(
                                              cursor: _hasPrevious
                                                  ? SystemMouseCursors.click
                                                  : SystemMouseCursors.basic,
                                              child: IconButton(
                                                icon: const Icon(Icons
                                                    .skip_previous_rounded),
                                                color: _hasPrevious
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.3),
                                                iconSize: 28,
                                                onPressed: _hasPrevious
                                                    ? _playPrevious
                                                    : null,
                                                tooltip: 'Previous',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Skip back 10s
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.replay_10_rounded),
                                                color: Colors.white,
                                                iconSize: 32,
                                                onPressed: _skipBackward,
                                                tooltip: 'Skip back 10s',
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Play/Pause
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: _togglePlayPause,
                                                child: Container(
                                                  width: 64,
                                                  height: 64,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: Colors.white,
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
                                                    _controller != null &&
                                                            _controller!
                                                                .value.isPlaying
                                                        ? Icons.pause_rounded
                                                        : Icons
                                                            .play_arrow_rounded,
                                                    color:
                                                        AppColors.primaryDark,
                                                    size: 40,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            // Skip forward 10s
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.forward_10_rounded),
                                                color: Colors.white,
                                                iconSize: 32,
                                                onPressed: _skipForward,
                                                tooltip: 'Skip forward 10s',
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Next
                                            MouseRegion(
                                              cursor: _hasNext
                                                  ? SystemMouseCursors.click
                                                  : SystemMouseCursors.basic,
                                              child: IconButton(
                                                icon: const Icon(
                                                    Icons.skip_next_rounded),
                                                color: _hasNext
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withOpacity(0.3),
                                                iconSize: 28,
                                                onPressed:
                                                    _hasNext ? _playNext : null,
                                                tooltip: 'Next',
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.medium),
                                        // Bottom row with volume and speed
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Volume control
                                            MouseRegion(
                                              onEnter: (_) => setState(() =>
                                                  _showVolumeSlider = true),
                                              onExit: (_) => setState(() =>
                                                  _showVolumeSlider = false),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      _isMuted || _volume == 0
                                                          ? Icons
                                                              .volume_off_rounded
                                                          : _volume < 0.5
                                                              ? Icons
                                                                  .volume_down_rounded
                                                              : Icons
                                                                  .volume_up_rounded,
                                                      color: Colors.white,
                                                    ),
                                                    onPressed: _toggleMute,
                                                    tooltip: _isMuted
                                                        ? 'Unmute'
                                                        : 'Mute',
                                                  ),
                                                  AnimatedContainer(
                                                    duration: const Duration(
                                                        milliseconds: 200),
                                                    width: _showVolumeSlider
                                                        ? 100
                                                        : 0,
                                                    child: _showVolumeSlider
                                                        ? SliderTheme(
                                                            data:
                                                                SliderTheme.of(
                                                                        context)
                                                                    .copyWith(
                                                              trackHeight: 3,
                                                              thumbShape:
                                                                  const RoundSliderThumbShape(
                                                                      enabledThumbRadius:
                                                                          6),
                                                              overlayShape:
                                                                  const RoundSliderOverlayShape(
                                                                      overlayRadius:
                                                                          12),
                                                              activeTrackColor:
                                                                  Colors.white,
                                                              inactiveTrackColor:
                                                                  Colors.white
                                                                      .withOpacity(
                                                                          0.3),
                                                              thumbColor:
                                                                  Colors.white,
                                                            ),
                                                            child: Slider(
                                                              value: _isMuted
                                                                  ? 0
                                                                  : _volume,
                                                              onChanged:
                                                                  (value) {
                                                                setState(() {
                                                                  _volume =
                                                                      value;
                                                                  _isMuted =
                                                                      value ==
                                                                          0;
                                                                });
                                                                _controller
                                                                    ?.setVolume(
                                                                        value);
                                                              },
                                                            ),
                                                          )
                                                        : const SizedBox(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Playback speed
                                            PopupMenuButton<double>(
                                              initialValue: _playbackSpeed,
                                              onSelected: _setPlaybackSpeed,
                                              tooltip: 'Playback speed',
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.2),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  '${_playbackSpeed}x',
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w500),
                                                ),
                                              ),
                                              itemBuilder: (context) =>
                                                  _availableSpeeds.map((speed) {
                                                return PopupMenuItem<double>(
                                                  value: speed,
                                                  child: Text(
                                                    '${speed}x',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          _playbackSpeed ==
                                                                  speed
                                                              ? FontWeight.bold
                                                              : FontWeight
                                                                  .normal,
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
