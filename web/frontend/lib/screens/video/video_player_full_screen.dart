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
  double _scrubValue = 0.0;
  bool _wasPlayingBeforeScrub = false;
  
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
    final newPosition = _controller!.value.position + const Duration(seconds: 10);
    final maxPosition = _controller!.value.duration;
    _controller!.seekTo(newPosition > maxPosition ? maxPosition : newPosition);
    _showControlsWithAutoHide();
  }
  
  void _skipBackward() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    final newPosition = _controller!.value.position - const Duration(seconds: 10);
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

  Future<void> _initializePlayer() async {
    try {
      final videoUrl = _currentItem.videoUrl ?? widget.videoUrl;
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl));
      await _controller!.initialize();
      await _controller!.play();
      
      _controller!.addListener(_videoListener);
      
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _hasError = true;
        });
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;
    
    // Don't update position during scrubbing
    if (_isScrubbing) return;
    
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
        if (mounted && (_controller?.value.isPlaying ?? false) && !_isScrubbing) {
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
      await _controller!.play();
    }
    setState(() {
      _showControls = true;
    });
    _startControlsTimer();
  }

  Future<void> _seekTo(int seconds) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('VideoPlayer: Cannot seek - controller not initialized');
      return;
    }
    
    try {
      final duration = _controller!.value.duration.inSeconds;
      final clamped = seconds.clamp(0, duration);
      debugPrint('VideoPlayer: Seeking to ${clamped}s (requested: ${seconds}s, duration: ${duration}s)');
      await _controller!.seekTo(Duration(seconds: clamped));
      debugPrint('VideoPlayer: Seek completed successfully');
    } catch (e) {
      debugPrint('VideoPlayer: Error during seek: $e');
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

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _focusNode.dispose();
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
                        onPressed: widget.onBack,
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
                                  backgroundColor: AppColors.primaryMain.withOpacity(0.9),
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
                                widget.isFavorite ? Icons.favorite : Icons.favorite_border,
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
                            child: CircularProgressIndicator(color: AppColors.primaryMain),
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
                                  style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
                                ),
                              ],
                            ),
                          )
                        else if (_controller != null && _controller!.value.isInitialized)
                          Positioned.fill(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: _controller!.value.aspectRatio,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          ),

                        // Floating Back Button (always visible, especially in fullscreen)
                        if (_isFullscreen && _showControls && widget.onBack != null)
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
                                  onPressed: widget.onBack,
                                  tooltip: 'Back',
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
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 4,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 8,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 16,
                              ),
                            ),
                            child: Slider(
                              value: _isScrubbing
                                  ? _scrubValue
                                  : _currentTime.toDouble(),
                              min: 0.0,
                              max: (_controller != null && _controller!.value.isInitialized
                                      ? _controller!.value.duration.inSeconds.toDouble()
                                      : widget.duration.toDouble())
                                  .clamp(1.0, double.infinity), // Minimum 1 to avoid division by zero
                              activeColor: Colors.white,
                              inactiveColor: Colors.white.withOpacity(0.3),
                              thumbColor: Colors.white,
                              onChangeStart: (value) {
                                setState(() {
                                  _isScrubbing = true;
                                  _scrubValue = value;
                                  _wasPlayingBeforeScrub = _controller?.value.isPlaying ?? false;
                                });
                                _controller?.pause();
                              },
                              onChanged: (value) {
                                setState(() {
                                  _scrubValue = value;
                                  _currentTime = value.toInt();
                                });
                                widget.onSeek?.call(_currentTime);
                              },
                              onChangeEnd: (value) async {
                                await _seekTo(value.toInt());
                                setState(() {
                                  _isScrubbing = false;
                                });
                                if (_wasPlayingBeforeScrub) {
                                  _controller?.play();
                                  _startControlsTimer();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.small),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(
                              _isFullscreen ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                            ),
                            color: Colors.white,
                            onPressed: _toggleFullscreen,
                            tooltip: _isFullscreen ? 'Exit Fullscreen (F)' : 'Fullscreen (F)',
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatTime(_currentTime),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _formatTime(_controller?.value.duration.inSeconds ?? widget.duration),
                          style: AppTypography.caption.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Previous
                        MouseRegion(
                          cursor: _hasPrevious ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: IconButton(
                            icon: const Icon(Icons.skip_previous_rounded),
                            color: _hasPrevious ? Colors.white : Colors.white.withOpacity(0.3),
                            iconSize: 28,
                            onPressed: _hasPrevious ? _playPrevious : null,
                            tooltip: 'Previous',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Skip back 10s
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(Icons.replay_10_rounded),
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
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Icon(
                                _controller != null && _controller!.value.isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: AppColors.primaryDark,
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
                            icon: const Icon(Icons.forward_10_rounded),
                            color: Colors.white,
                            iconSize: 32,
                            onPressed: _skipForward,
                            tooltip: 'Skip forward 10s',
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Next
                        MouseRegion(
                          cursor: _hasNext ? SystemMouseCursors.click : SystemMouseCursors.basic,
                          child: IconButton(
                            icon: const Icon(Icons.skip_next_rounded),
                            color: _hasNext ? Colors.white : Colors.white.withOpacity(0.3),
                            iconSize: 28,
                            onPressed: _hasNext ? _playNext : null,
                            tooltip: 'Next',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    // Bottom row with volume and speed
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Volume control
                        MouseRegion(
                          onEnter: (_) => setState(() => _showVolumeSlider = true),
                          onExit: (_) => setState(() => _showVolumeSlider = false),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  _isMuted || _volume == 0
                                      ? Icons.volume_off_rounded
                                      : _volume < 0.5
                                          ? Icons.volume_down_rounded
                                          : Icons.volume_up_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: _toggleMute,
                                tooltip: _isMuted ? 'Unmute' : 'Mute',
                              ),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: _showVolumeSlider ? 100 : 0,
                                child: _showVolumeSlider
                                    ? SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3,
                                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                          activeTrackColor: Colors.white,
                                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                                          thumbColor: Colors.white,
                                        ),
                                        child: Slider(
                                          value: _isMuted ? 0 : _volume,
                                          onChanged: (value) {
                                            setState(() {
                                              _volume = value;
                                              _isMuted = value == 0;
                                            });
                                            _controller?.setVolume(value);
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
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_playbackSpeed}x',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                          ),
                          itemBuilder: (context) => _availableSpeeds.map((speed) {
                            return PopupMenuItem<double>(
                              value: speed,
                              child: Text(
                                '${speed}x',
                                style: TextStyle(
                                  fontWeight: _playbackSpeed == speed ? FontWeight.bold : FontWeight.normal,
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
