import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/video_editing_service.dart';
import '../../models/text_overlay.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Web Video Editor Screen - Professional Video Editing UI for Web
/// Features: Multi-track timeline, text overlays, trimming, filters, audio tracks
/// Handles blob URLs and network URLs properly
class VideoEditorScreenWeb extends StatefulWidget {
  final String videoPath;
  final String? title;

  const VideoEditorScreenWeb({
    super.key,
    required this.videoPath,
    this.title,
  });

  @override
  State<VideoEditorScreenWeb> createState() => _VideoEditorScreenWebState();
}

class _VideoEditorScreenWebState extends State<VideoEditorScreenWeb> with SingleTickerProviderStateMixin {
  VideoPlayerController? _controller;
  final VideoEditingService _editingService = VideoEditingService();
  late TabController _tabController;
  
  bool _isInitializing = true;
  bool _isEditing = false;
  bool _hasError = false;
  String? _errorMessage;
  
  // Video metadata
  String? _projectTitle;
  String _resolution = '1440p';
  double _fps = 30.0;
  Duration _videoDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  
  // Editing state
  Duration _trimStart = Duration.zero;
  Duration _trimEnd = Duration.zero;
  bool _audioRemoved = false;
  String? _audioFilePath;
  
  // Filter values
  double _brightness = 0.0;
  double _contrast = 1.0;
  double _saturation = 1.0;
  
  // Text overlays
  List<TextOverlay> _textOverlays = [];
  TextOverlay? _selectedTextOverlay;
  
  // Timeline state
  double _playheadPosition = 0.0; // 0.0 to 1.0
  bool _isDraggingPlayhead = false;
  
  // Controls visibility for video preview
  bool _showVideoControls = true;
  Timer? _hideVideoControlsTimer;
  bool _isMouseOverVideo = false;
  
  String? _editedVideoPath;
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs: Edit, Music, Text, Filters, Adjust
    _initializePlayer();
  }

  String _extractFileName(String path) {
    // Handle blob URLs, network URLs, and file paths
    if (path.startsWith('blob:')) {
      return 'Video Recording';
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      final uri = Uri.parse(path);
      final segments = uri.pathSegments;
      if (segments.isNotEmpty) {
        final fileName = segments.last;
        return fileName.split('.').first;
      }
      return 'Video';
    } else {
      // Fallback for file paths (shouldn't happen on web, but handle gracefully)
      final parts = path.split('/');
      if (parts.isNotEmpty) {
        return parts.last.split('.').first;
      }
      return 'Video';
    }
  }

  Future<void> _initializePlayer() async {
    try {
      // On web, all paths should be URLs (blob URLs or network URLs)
      final isNetworkUrl = widget.videoPath.startsWith('http://') || 
                          widget.videoPath.startsWith('https://');
      final isBlobUrl = widget.videoPath.startsWith('blob:');
      
      // Use networkUrl for both blob URLs and network URLs
      if (isNetworkUrl || isBlobUrl) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // Fallback: treat as network URL
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      }
      
      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      
      // Extract project title from filename
      final fileName = _extractFileName(widget.videoPath);
      _projectTitle = widget.title ?? fileName;
      
      // Extract video metadata
      final size = _controller!.value.size;
      _resolution = _getResolutionFromSize(size);
      _fps = _controller!.value.size.height > 720 ? 30.0 : 29.97; // Estimate, video_player doesn't expose FPS directly
      
      setState(() {
        _isInitializing = false;
        _videoDuration = _controller!.value.duration;
        _trimEnd = _videoDuration;
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
    }
  }

  String _getResolutionFromSize(Size size) {
    final height = size.height;
    if (height >= 2160) return '4K';
    if (height >= 1440) return '1440p';
    if (height >= 1080) return '1080p';
    if (height >= 720) return '720p';
    if (height >= 480) return '480p';
    return '360p';
  }

  void _videoListener() {
    if (mounted && _controller != null) {
      setState(() {
        _currentPosition = _controller!.value.position;
        _isPlaying = _controller!.value.isPlaying;
        if (!_isDraggingPlayhead) {
          _playheadPosition = _currentPosition.inMilliseconds / _videoDuration.inMilliseconds;
          _playheadPosition = _playheadPosition.clamp(0.0, 1.0);
        }
      });
    }
  }

  Future<void> _togglePlayPause() async {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
    
    // Show controls and manage timer
    _showVideoControlsWithAutoHide();
  }

  Future<void> _seekToPosition(double position) async {
    if (_controller == null || _videoDuration == Duration.zero) return;
    
    final targetPosition = Duration(
      milliseconds: (position * _videoDuration.inMilliseconds).toInt(),
    );
    await _controller!.seekTo(targetPosition);
    if (mounted) {
      setState(() {
        _playheadPosition = position;
      });
    }
  }

  void _onPlayheadDragStart() {
    setState(() {
      _isDraggingPlayhead = true;
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      }
    });
  }

  void _onPlayheadDragUpdate(double position) {
    final clampedPosition = position.clamp(0.0, 1.0);
    setState(() {
      _playheadPosition = clampedPosition;
    });
    // Don't seek during drag - only update visual position
    // Seek will happen on drag end
  }

  void _onPlayheadDragEnd() {
    // Seek to final position when drag ends
    _seekToPosition(_playheadPosition);
    setState(() {
      _isDraggingPlayhead = false;
    });
  }
  
  void _onVideoMouseEnter() {
    setState(() {
      _isMouseOverVideo = true;
    });
    _showVideoControlsWithAutoHide();
  }

  void _onVideoMouseExit() {
    setState(() {
      _isMouseOverVideo = false;
    });
    if (_controller?.value.isPlaying ?? false) {
      _hideVideoControls();
    }
  }

  void _onVideoMouseMove() {
    if (_isMouseOverVideo) {
      _showVideoControlsWithAutoHide();
    }
  }

  void _showVideoControlsWithAutoHide() {
    _hideVideoControlsTimer?.cancel();
    setState(() {
      _showVideoControls = true;
    });
    
    if (_controller?.value.isPlaying ?? false) {
      _startVideoControlsTimer();
    }
  }

  void _startVideoControlsTimer() {
    _hideVideoControlsTimer?.cancel();
    if (_controller?.value.isPlaying ?? false) {
      _hideVideoControlsTimer = Timer(const Duration(seconds: 3), () {
        if (mounted && (_controller?.value.isPlaying ?? false)) {
          setState(() {
            _showVideoControls = false;
          });
        }
      });
    }
  }

  void _hideVideoControls() {
    _hideVideoControlsTimer?.cancel();
    if (mounted && (_controller?.value.isPlaying ?? false)) {
      setState(() {
        _showVideoControls = false;
      });
    }
  }

  void _addTextOverlay() {
    final overlay = TextOverlay(
      id: _uuid.v4(),
      text: 'New Text',
      startTime: _currentPosition,
      endTime: _currentPosition + const Duration(seconds: 5),
    );
    setState(() {
      _textOverlays.add(overlay);
      _selectedTextOverlay = overlay;
    });
    _showTextOverlayEditor(overlay);
  }

  void _editTextOverlay(TextOverlay overlay) {
    setState(() {
      _selectedTextOverlay = overlay;
    });
    _showTextOverlayEditor(overlay);
  }

  void _showTextOverlayEditor(TextOverlay overlay) {
    final textController = TextEditingController(text: overlay.text);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Text',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Text input
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: textController,
                decoration: InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  labelStyle: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 3,
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Delete overlay
                        setState(() {
                          _textOverlays.removeWhere((o) => o.id == overlay.id);
                          if (_selectedTextOverlay?.id == overlay.id) {
                            _selectedTextOverlay = null;
                          }
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorMain,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Update overlay
                        setState(() {
                          final index = _textOverlays.indexWhere((o) => o.id == overlay.id);
                          if (index != -1) {
                            _textOverlays[index] = overlay.copyWith(
                              text: textController.text,
                            );
                          }
                        });
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Save'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyTrim() async {
    if (_trimStart >= _trimEnd) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Start time must be less than end time'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.trimVideo(
      widget.videoPath,
      _trimStart,
      _trimEnd,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _isEditing = false;
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Video trimmed successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _removeAudio() async {
    final inputPath = _editedVideoPath ?? widget.videoPath;
    
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.removeAudioTrack(
      inputPath,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioRemoved = true;
        _isEditing = false;
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio removed successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        // On web, FilePicker returns bytes instead of path
        // For now, we'll need to upload the audio file to get a URL
        // TODO: Implement audio file upload to backend to get URL
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Audio file upload from web is not yet implemented. Please use a network URL.'),
            backgroundColor: AppColors.infoMain,
          ),
        );
        // For now, we can't proceed without a URL
        return;
      } else if (result != null && result.files.single.path != null) {
        // Fallback for mobile (shouldn't happen on web, but handle gracefully)
        final audioPath = result.files.single.path!;
        await _addAudioTrack(audioPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting audio file: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    }
  }

  Future<void> _addAudioTrack(String audioPath) async {
    final inputPath = _editedVideoPath ?? widget.videoPath;
    
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.addAudioTrack(
      inputPath,
      audioPath,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _audioFilePath = audioPath;
        _audioRemoved = false;
        _isEditing = false;
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Audio track added successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _applyFilters() async {
    final inputPath = _editedVideoPath ?? widget.videoPath;
    
    if (_brightness == 0.0 && _contrast == 1.0 && _saturation == 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No filters to apply'),
          backgroundColor: AppColors.infoMain,
        ),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final filters = <String, double>{};
    if (_brightness != 0.0) filters['brightness'] = _brightness;
    if (_contrast != 1.0) filters['contrast'] = _contrast;
    if (_saturation != 1.0) filters['saturation'] = _saturation;

    final outputPath = await _editingService.applyFilters(
      inputPath,
      filters,
      onProgress: (progress) {},
      onError: (error) {
        setState(() {
          _isEditing = false;
          _hasError = true;
          _errorMessage = error;
        });
      },
    );

    if (outputPath != null) {
      setState(() {
        _editedVideoPath = outputPath;
        _isEditing = false;
      });
      await _reloadPlayer(outputPath);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Filters applied successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    }
  }

  Future<void> _reloadPlayer(String path) async {
    await _controller?.dispose();
    
    // On web, path should be a URL (blob URL or network URL)
    final isNetworkUrl = path.startsWith('http://') || path.startsWith('https://');
    final isBlobUrl = path.startsWith('blob:');
    
    if (isNetworkUrl || isBlobUrl) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(path),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    } else {
      // Fallback: treat as network URL
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(path),
        videoPlayerOptions: VideoPlayerOptions(
          mixWithOthers: false,
          allowBackgroundPlayback: false,
        ),
      );
    }
    
    await _controller!.initialize();
    _controller!.addListener(_videoListener);
    setState(() {});
  }

  void _handleExport() {
    if (_editedVideoPath == null && _textOverlays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No edits to export'),
          backgroundColor: AppColors.infoMain,
        ),
      );
      return;
    }

    // TODO: Apply text overlays to video
    // For now, just return edited video path
    Navigator.pop(context, _editedVideoPath ?? widget.videoPath);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _hideVideoControlsTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppColors.primaryMain),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Loading video editor...',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: StyledPageHeader(
                      title: 'Video Editor',
                      size: StyledPageHeaderSize.h2,
                    ),
                  ),
                ],
              ),
              Expanded(
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
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Video Preview
            Expanded(
              child: _buildVideoPreview(),
            ),
            
            // Playback Controls
            _buildPlaybackControls(),
            
            // Timeline
            _buildTimeline(),
            
            // Bottom Toolbar
            _buildBottomToolbar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: StyledPageHeader(
            title: _projectTitle ?? 'Video Editor',
            size: StyledPageHeaderSize.h2,
          ),
        ),
        // Undo button
        IconButton(
          icon: Icon(Icons.undo, color: AppColors.textSecondary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Undo feature coming soon'),
                backgroundColor: AppColors.infoMain,
              ),
            );
          },
        ),
        // Redo button
        IconButton(
          icon: Icon(Icons.redo, color: AppColors.textSecondary),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Redo feature coming soon'),
                backgroundColor: AppColors.infoMain,
              ),
            );
          },
        ),
        // Share/Export button
        IconButton(
          icon: Icon(Icons.share, color: AppColors.primaryMain),
          onPressed: _handleExport,
        ),
      ],
    );
  }

  Widget _buildVideoPreview() {
    return SectionContainer(
      showShadow: true,
      child: MouseRegion(
        onEnter: (_) => _onVideoMouseEnter(),
        onExit: (_) => _onVideoMouseExit(),
        onHover: (_) => _onVideoMouseMove(),
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Video player
              if (_controller != null && _controller!.value.isInitialized)
                Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              
              // Text overlays
              ..._textOverlays.where((overlay) {
                final currentTime = _currentPosition;
                return currentTime >= overlay.startTime && currentTime <= overlay.endTime;
              }).map((overlay) => Positioned(
                left: overlay.x * MediaQuery.of(context).size.width - 100,
                top: overlay.y * MediaQuery.of(context).size.height - 20,
                child: GestureDetector(
                  onTap: () => _editTextOverlay(overlay),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: overlay.backgroundColor != null
                          ? Color(int.parse(overlay.backgroundColor!.replaceFirst('#', '0xff')))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      overlay.text,
                      style: TextStyle(
                        color: Color(overlay.color),
                        fontSize: overlay.fontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: overlay.textAlign,
                    ),
                  ),
                ),
              )),
              
              // Controls Overlay
              if (_controller != null && _controller!.value.isInitialized)
                AnimatedOpacity(
                  opacity: _showVideoControls ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Center Play/Pause Button
                        if (!_controller!.value.isPlaying || _isMouseOverVideo)
                          Center(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: _togglePlayPause,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMain.withOpacity(0.9),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _controller!.value.isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
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
      ),
    );
  }

  Widget _buildPlaybackControls() {
    return SectionContainer(
      showShadow: false,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      child: Row(
        children: [
          // Current time
          Text(
            _formatTime(_currentPosition),
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
          
          const Spacer(),
          
          // Play button (centered)
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryMain,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMain.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 36,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Total duration
          Text(
            '/${_formatTime(_videoDuration)}',
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    return SectionContainer(
      showShadow: false,
      child: Container(
        height: 200,
        child: Column(
          children: [
            // Timeline header with time markers
            _buildTimelineHeader(),
            
            // Timeline tracks
            Expanded(
              child: ListView(
                children: [
                  // Text track
                  _buildTextTrack(),
                  
                  // Video track
                  _buildVideoTrack(),
                  
                  // Audio track
                  _buildAudioTrack(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 30,
          color: AppColors.backgroundTertiary,
          child: Stack(
            children: [
              // Time markers
              Row(
                children: List.generate(
                  (_videoDuration.inSeconds ~/ 5) + 1,
                  (index) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.borderSecondary, width: 1)),
                      ),
                      child: Center(
                        child: Text(
                          _formatTime(Duration(seconds: index * 5)),
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Playhead
              Positioned(
                left: _playheadPosition * constraints.maxWidth,
                top: 0,
                bottom: 0,
                child: GestureDetector(
                  onPanStart: (_) => _onPlayheadDragStart(),
                  onPanUpdate: (details) {
                    final localPosition = details.localPosition;
                    final width = constraints.maxWidth;
                    final position = (localPosition.dx / width).clamp(0.0, 1.0);
                    _onPlayheadDragUpdate(position);
                  },
                  onPanEnd: (_) => _onPlayheadDragEnd(),
                  child: Container(
                    width: 2,
                    color: AppColors.primaryMain,
                    child: Stack(
                      children: [
                        Positioned(
                          top: -8,
                          left: -6,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: AppColors.primaryMain,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextTrack() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: 50,
          color: AppColors.backgroundPrimary,
          child: Stack(
            children: [
              // Text overlay bars
              ..._textOverlays.map((overlay) {
                final startPosition = overlay.startTime.inMilliseconds / _videoDuration.inMilliseconds;
                final duration = overlay.endTime.inMilliseconds - overlay.startTime.inMilliseconds;
                final width = (duration / _videoDuration.inMilliseconds) * constraints.maxWidth;
                
                return Positioned(
                  left: startPosition * constraints.maxWidth,
                  top: 8,
                  child: GestureDetector(
                    onTap: () => _editTextOverlay(overlay),
                    child: Container(
                      width: width,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.accentMain,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            child: const Icon(Icons.text_fields, color: Colors.white, size: 16),
                          ),
                          Expanded(
                            child: Text(
                              overlay.text,
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoTrack() {
    return Container(
      height: 60,
      color: AppColors.backgroundPrimary,
      child: Center(
        child: Text(
          'Video Track',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildAudioTrack() {
    return Container(
      height: 50,
      color: AppColors.backgroundPrimary,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(Icons.music_note, color: AppColors.textSecondary, size: 20),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.borderSecondary),
              ),
              child: CustomPaint(
                painter: WaveformPainter(),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomToolbar() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tab content panel
        SectionContainer(
          showShadow: false,
          padding: EdgeInsets.zero,
          child: Container(
            height: 150,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditPanel(),
                _buildMusicPanel(),
                _buildTextPanel(),
                _buildFiltersPanel(),
                _buildAdjustPanel(),
              ],
            ),
          ),
        ),
        
        // Tab bar
        SectionContainer(
          showShadow: false,
          padding: EdgeInsets.zero,
          child: Container(
            height: 60,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primaryMain,
              labelColor: AppColors.primaryMain,
              unselectedLabelColor: AppColors.textSecondary,
              tabs: const [
                Tab(icon: Icon(Icons.content_cut), text: 'Edit'),
                Tab(icon: Icon(Icons.music_note), text: 'Music'),
                Tab(icon: Icon(Icons.text_fields), text: 'Text'),
                Tab(icon: Icon(Icons.filter), text: 'Filters'),
                Tab(icon: Icon(Icons.tune), text: 'Adjust'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Trim Video',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Start: ${_formatTime(_trimStart)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Slider(
                      value: _trimStart.inSeconds.toDouble(),
                      min: 0,
                      max: _videoDuration.inSeconds.toDouble(),
                      activeColor: AppColors.primaryMain,
                      onChanged: (value) {
                        setState(() {
                          _trimStart = Duration(seconds: value.toInt());
                          if (_trimStart >= _trimEnd) {
                            _trimEnd = Duration(seconds: (value + 1).toInt());
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'End: ${_formatTime(_trimEnd)}',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    Slider(
                      value: _trimEnd.inSeconds.toDouble(),
                      min: 0,
                      max: _videoDuration.inSeconds.toDouble(),
                      activeColor: AppColors.primaryMain,
                      onChanged: (value) {
                        setState(() {
                          _trimEnd = Duration(seconds: value.toInt());
                          if (_trimEnd <= _trimStart) {
                            _trimStart = Duration(seconds: (value - 1).toInt());
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isEditing ? null : _applyTrim,
            icon: const Icon(Icons.check),
            label: const Text('Apply Trim'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Audio Track',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEditing || _audioRemoved ? null : _removeAudio,
                  icon: const Icon(Icons.volume_off),
                  label: const Text('Remove Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorMain,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEditing ? null : _selectAudioFile,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Add Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Text Overlays',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _addTextOverlay,
            icon: const Icon(Icons.text_fields),
            label: const Text('Add Text'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          
          // Brightness
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Brightness: ${_brightness.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Slider(
                value: _brightness,
                min: -1.0,
                max: 1.0,
                divisions: 40,
                activeColor: AppColors.primaryMain,
                onChanged: (value) {
                  setState(() {
                    _brightness = value;
                  });
                },
              ),
            ],
          ),
          
          // Contrast
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contrast: ${_contrast.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Slider(
                value: _contrast,
                min: 0.0,
                max: 2.0,
                divisions: 40,
                activeColor: AppColors.primaryMain,
                onChanged: (value) {
                  setState(() {
                    _contrast = value;
                  });
                },
              ),
            ],
          ),
          
          // Saturation
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saturation: ${_saturation.toStringAsFixed(2)}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              Slider(
                value: _saturation,
                min: 0.0,
                max: 3.0,
                divisions: 40,
                activeColor: AppColors.primaryMain,
                onChanged: (value) {
                  setState(() {
                    _saturation = value;
                  });
                },
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isEditing ? null : _applyFilters,
            icon: const Icon(Icons.check),
            label: const Text('Apply Filters'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdjustPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Adjustments',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Adjustments feature coming soon'),
                  backgroundColor: AppColors.infoMain,
                ),
              );
            },
            icon: const Icon(Icons.tune),
            label: const Text('Adjust Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryMain,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder waveform painter
class WaveformPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 2;
    
    // Draw simple waveform pattern
    for (double x = 0; x < size.width; x += 4) {
      final height = (20 + math.sin(x * 0.1) * 15).abs();
      canvas.drawLine(
        Offset(x, size.height / 2 - height / 2),
        Offset(x, size.height / 2 + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

