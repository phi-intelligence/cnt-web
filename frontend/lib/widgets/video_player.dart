import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../theme/app_colors.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final String? title;
  final int? startTime; // Start time in seconds (for preview segments)
  final int? endTime; // End time in seconds (for preview segments)
  final VoidCallback? onSegmentEnd; // Callback when segment ends

  const VideoPlayerWidget({
    super.key,
    required this.videoUrl,
    this.title,
    this.startTime,
    this.endTime,
    this.onSegmentEnd,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  VideoPlayerController? _controller;
  bool _showControls = true;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isScrubbing = false;
  double _scrubValue = 0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final uri = Uri.parse(widget.videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);

      // Protect against hanging initialization by enforcing a timeout
      await _controller!
          .initialize()
          .timeout(const Duration(seconds: 15));
      _controller!.addListener(_videoListener);
      
      // If start time is specified, seek to it
      if (widget.startTime != null && widget.startTime! > 0) {
        await _controller!.seekTo(Duration(seconds: widget.startTime!));
      }
      
      // Start playing
      await _controller!.play();
      
      setState(() {
        _isInitializing = false;
      });
      _autoHideControls();
    } on TimeoutException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video took too long to load. Please try again.\n$e';
        _isInitializing = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isInitializing = false;
      });
    }
  }

  void _videoListener() {
    if (!mounted) return;

    // Check if we've reached the end time (for preview segments)
    if (widget.endTime != null && _controller != null && _controller!.value.isInitialized) {
      final currentPosition = _controller!.value.position.inSeconds;
      if (currentPosition >= widget.endTime!) {
        _controller!.pause();
        widget.onSegmentEnd?.call();
      }
    }

    if (_isScrubbing) return;

    setState(() {});
  }

  void _autoHideControls() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _autoHideControls();
      }
    });
  }

  void _togglePlayPause() {
    if (_controller != null && _controller!.value.isInitialized) {
      setState(() {
        if (_controller!.value.isPlaying) {
          _controller!.pause();
        } else {
          _controller!.play();
        }
      });
    }
  }

  void _seekBy(Duration offset) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return;
    }
    final duration = _controller!.value.duration;
    var target = _controller!.value.position + offset;
    if (target < Duration.zero) {
      target = Duration.zero;
    } else if (target > duration) {
      target = duration;
    }
    _controller!.seekTo(target);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: GestureDetector(
        onTap: _toggleControls,
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
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              )
            else if (_controller != null && _controller!.value.isInitialized)
              Center(
                child: AspectRatio(
                  aspectRatio: _controller!.value.aspectRatio,
                  child: VideoPlayer(_controller!),
                ),
              )
            else
              Center(
                child: CircularProgressIndicator(color: AppColors.primaryMain),
              ),

            // Controls Overlay
            if (_showControls && !_isInitializing && !_hasError)
              Positioned(
                top: 40,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.primaryMain),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (widget.title != null)
                      Expanded(
                        child: Text(
                          widget.title!,
                          style: TextStyle(color: AppColors.textPrimary),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(), // Spacer
                  ],
                ),
              ),

            // Play/Pause Button (Centered)
            if (_showControls && !_isInitializing && !_hasError && _controller != null)
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primaryMain.withOpacity(0.9),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryMain.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 64,
                    ),
                    onPressed: _togglePlayPause,
                  ),
                ),
              ),

            // Bottom Controls
            if (_showControls && !_isInitializing && !_hasError && _controller != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  children: [
                    // Progress Bar
                    Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            _formatDuration(_controller!.value.position),
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            ),
                            child: Builder(
                              builder: (context) {
                                double maxPosition = 1;
                                double currentPosition = 0;
                                if (_controller != null && _controller!.value.isInitialized) {
                                  maxPosition = _controller!.value.duration.inMilliseconds.toDouble();
                                  if (maxPosition <= 0) {
                                    maxPosition = 1;
                                  }
                                  currentPosition = _controller!.value.position.inMilliseconds.toDouble();
                                }
                                final sliderValue = (_isScrubbing
                                        ? _scrubValue.clamp(0, maxPosition)
                                        : currentPosition.clamp(0, maxPosition))
                                    .toDouble();
                                return Slider(
                                  value: sliderValue,
                                  min: 0,
                                  max: maxPosition,
                                  activeColor: AppColors.primaryMain,
                                  inactiveColor: AppColors.primaryMain.withOpacity(0.3),
                                  onChangeStart: (value) {
                                    if (!mounted) return;
                                    setState(() {
                                      _isScrubbing = true;
                                      _scrubValue = value;
                                    });
                                  },
                                  onChanged: (value) {
                                    if (!mounted) return;
                                    setState(() {
                                      _scrubValue = value;
                                    });
                                  },
                                  onChangeEnd: (value) {
                                    if (_controller != null && _controller!.value.isInitialized) {
                                      _controller!.seekTo(Duration(milliseconds: value.toInt()));
                                    }
                                    if (mounted) {
                                      setState(() {
                                        _isScrubbing = false;
                                      });
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 50,
                          child: Text(
                            _formatDuration(_controller!.value.duration),
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 12),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Control Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(Icons.skip_previous, color: AppColors.primaryMain),
                          onPressed: () {
                            _seekBy(const Duration(seconds: -10));
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            _controller!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                            color: AppColors.primaryMain,
                            size: 40,
                          ),
                          onPressed: _togglePlayPause,
                        ),
                        IconButton(
                          icon: Icon(Icons.skip_next, color: AppColors.primaryMain),
                          onPressed: () {
                            _seekBy(const Duration(seconds: 10));
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

