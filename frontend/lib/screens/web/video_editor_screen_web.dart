import 'package:flutter/material.dart';
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
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import 'video_preview_screen_web.dart';

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
    _tabController = TabController(length: 3, vsync: this); // 3 tabs: Trim, Music, Text
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: screenHeight * 0.85,
        maxWidth: isMobile ? screenWidth : 600,
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: screenHeight * 0.85,
          maxWidth: isMobile ? screenWidth : 600,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLarge),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.1),
                      AppColors.accentMain.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppSpacing.radiusLarge),
                  ),
                  border: Border(
                    bottom: BorderSide(color: AppColors.borderPrimary),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.small),
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                      ),
                      child: Icon(
                        Icons.text_fields,
                        color: AppColors.warmBrown,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: Text(
                        'Edit Text Overlay',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),
              ),
              
              // Content - Scrollable
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.large),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text input
                      Text(
                        'Text Content',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      TextField(
                        controller: textController,
                        maxLines: 4,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter text to display on video',
                          hintStyle: AppTypography.body.copyWith(
                            color: AppColors.textPlaceholder,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            borderSide: BorderSide(
                              color: AppColors.warmBrown,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.backgroundSecondary,
                          contentPadding: const EdgeInsets.all(AppSpacing.medium),
                        ),
                      ),
                      
                      const SizedBox(height: AppSpacing.large),
                      
                      // Time Range Info
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundSecondary,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(color: AppColors.borderPrimary),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              color: AppColors.warmBrown,
                              size: 20,
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Display Time',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${_formatTime(overlay.startTime)} - ${_formatTime(overlay.endTime)}',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action Buttons - Fixed at bottom
              Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  border: Border(
                    top: BorderSide(color: AppColors.borderPrimary),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _textOverlays.removeWhere((o) => o.id == overlay.id);
                            if (_selectedTextOverlay?.id == overlay.id) {
                              _selectedTextOverlay = null;
                            }
                          });
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.errorMain,
                          side: BorderSide(color: AppColors.errorMain, width: 2),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.large,
                            vertical: AppSpacing.medium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
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
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Save Changes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warmBrown,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.large,
                            vertical: AppSpacing.medium,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

    final inputPath = _editedVideoPath ?? widget.videoPath;
    final outputPath = await _editingService.trimVideo(
      inputPath,
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

  Future<void> _handleSave() async {
    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    try {
      // Get the final video path (edited or original)
      String finalVideoPath = _editedVideoPath ?? widget.videoPath;

      // If there are pending edits that haven't been applied, apply them
      // Check if trim needs to be applied
      if (_trimStart > Duration.zero || _trimEnd < _videoDuration) {
        if (_editedVideoPath == null || _trimStart > Duration.zero || _trimEnd < _videoDuration) {
          // Apply trim
          final trimmedPath = await _editingService.trimVideo(
            finalVideoPath,
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
          if (trimmedPath != null) {
            finalVideoPath = trimmedPath;
          }
        }
      }

      // On web, the video is already at a URL, so we can navigate directly
      // On mobile, we would save to device storage here
      if (kIsWeb) {
        // For web, we use the URL directly
        // The video is already available at the URL, no need to download
        setState(() {
          _isEditing = false;
        });

        // Navigate to publish page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreenWeb(
                videoUri: finalVideoPath,
                source: 'editor',
                duration: _videoDuration.inSeconds,
                fileSize: 0,
              ),
            ),
          );
        }
      } else {
        // For mobile, save to device storage
        // TODO: Implement mobile save functionality if needed
        setState(() {
          _isEditing = false;
        });

        // Navigate to publish page
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreenWeb(
                videoUri: finalVideoPath,
                source: 'editor',
                duration: _videoDuration.inSeconds,
                fileSize: 0,
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isEditing = false;
        _hasError = true;
        _errorMessage = e.toString();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
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

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: AppSpacing.large),
            
            // Main Content Area
            Expanded(
              child: isMobile
                  ? _buildMobileLayout()
                  : _buildDesktopLayout(),
            ),
            
            // Timeline Section
            _buildTimelineSection(),
            
            // Editing Tools Panel
            _buildEditingToolsPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        border: Border.all(color: AppColors.borderPrimary),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.warmBrown),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _projectTitle ?? 'Video Editor',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_videoDuration != Duration.zero)
                  Text(
                    '${_resolution} • ${_fps.toStringAsFixed(0)}fps • ${_formatTime(_videoDuration)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          // Action buttons
          Row(
            children: [
              _buildHeaderButton(
                icon: Icons.undo,
                tooltip: 'Undo',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Undo feature coming soon'),
                      backgroundColor: AppColors.infoMain,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.small),
              _buildHeaderButton(
                icon: Icons.redo,
                tooltip: 'Redo',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Redo feature coming soon'),
                      backgroundColor: AppColors.infoMain,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.medium),
              StyledPillButton(
                label: _isEditing ? 'Processing...' : 'Save & Continue',
                icon: Icons.save,
                onPressed: _isEditing ? null : _handleSave,
                isLoading: _isEditing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
          border: Border.all(color: AppColors.borderPrimary),
        ),
        child: IconButton(
          icon: Icon(icon, color: AppColors.warmBrown, size: 20),
          onPressed: onPressed,
          padding: const EdgeInsets.all(AppSpacing.small),
          constraints: const BoxConstraints(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Video Preview Section (Left - 65%)
        Expanded(
          flex: 65,
          child: _buildVideoPreview(),
        ),
        const SizedBox(width: AppSpacing.large),
        // Controls Panel (Right - 35%)
        Expanded(
          flex: 35,
          child: _buildControlsPanel(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildVideoPreview(),
          const SizedBox(height: AppSpacing.large),
          _buildControlsPanel(),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return SectionContainer(
      showShadow: true,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Video Player
          Expanded(
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
                      )
                    else
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.warmBrown,
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
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              AppColors.warmBrown,
                                              AppColors.accentMain,
                                            ],
                                          ),
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.warmBrown.withOpacity(0.4),
                                              blurRadius: 16,
                                              offset: const Offset(0, 4),
                                              spreadRadius: 2,
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
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // Playback Controls Bar
          _buildPlaybackControlsBar(),
        ],
      ),
    );
  }

  Widget _buildPlaybackControlsBar() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          top: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Column(
        children: [
          // Progress Bar
          if (_controller != null && _controller!.value.isInitialized)
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                activeTrackColor: AppColors.warmBrown,
                inactiveTrackColor: AppColors.borderPrimary,
                thumbColor: AppColors.warmBrown,
              ),
              child: Slider(
                value: _playheadPosition.clamp(0.0, 1.0),
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  _onPlayheadDragStart();
                  _onPlayheadDragUpdate(value);
                  _onPlayheadDragEnd();
                },
                onChangeStart: (_) => _onPlayheadDragStart(),
                onChangeEnd: (_) => _onPlayheadDragEnd(),
              ),
            ),
          
          // Time and Controls
          Row(
            children: [
              Text(
                _formatTime(_currentPosition),
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                '/ ${_formatTime(_videoDuration)}',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              // Play/Pause button
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown,
                        AppColors.accentMain,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlsPanel() {
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmBrown.withOpacity(0.1),
                  AppColors.accentMain.withOpacity(0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLarge),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: AppColors.warmBrown,
                  size: 24,
                ),
                const SizedBox(width: AppSpacing.small),
                Text(
                  'Editing Tools',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.warmBrown,
              indicatorWeight: 3,
              labelColor: AppColors.warmBrown,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(icon: Icon(Icons.content_cut, size: 20), text: 'Trim'),
                Tab(icon: Icon(Icons.music_note, size: 20), text: 'Audio'),
                Tab(icon: Icon(Icons.text_fields, size: 20), text: 'Text'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEditPanel(),
                _buildMusicPanel(),
                _buildTextPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.large),
      height: 180,
      child: SectionContainer(
        showShadow: true,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Timeline Header
            _buildTimelineHeader(),
            
            // Timeline Tracks
            Expanded(
              child: ListView(
                children: [
                  _buildTextTrack(),
                  _buildVideoTrack(),
                  _buildAudioTrack(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditingToolsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.medium),
      height: 0,
      child: const SizedBox.shrink(),
    );
  }

  Widget _buildTimelineHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final markerCount = (_videoDuration.inSeconds ~/ 5).clamp(5, 20);
        return Container(
          height: 40,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.backgroundTertiary,
                AppColors.backgroundSecondary,
              ],
            ),
            border: Border(
              bottom: BorderSide(color: AppColors.borderPrimary, width: 2),
            ),
          ),
          child: Stack(
            children: [
              // Time markers
              Row(
                children: List.generate(
                  markerCount + 1,
                  (index) => Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: AppColors.borderPrimary,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 1,
                            height: 8,
                            color: AppColors.warmBrown,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(Duration(seconds: index * 5)),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              
              // Playhead
              Positioned(
                left: (_playheadPosition * constraints.maxWidth).clamp(0.0, constraints.maxWidth - 2),
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
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeLeftRight,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        color: AppColors.warmBrown,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warmBrown.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: -10,
                            left: -8,
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.warmBrown,
                                    AppColors.accentMain,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.warmBrown.withOpacity(0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
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
          decoration: BoxDecoration(
            color: AppColors.backgroundPrimary,
            border: Border(
              bottom: BorderSide(color: AppColors.borderPrimary),
            ),
          ),
          child: Row(
            children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.text_fields, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Text',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
              // Track content
              Expanded(
                child: Stack(
                  children: [
                    // Text overlay bars
                    ..._textOverlays.map((overlay) {
                      final startPosition = overlay.startTime.inMilliseconds / _videoDuration.inMilliseconds;
                      final duration = overlay.endTime.inMilliseconds - overlay.startTime.inMilliseconds;
                      final width = (duration / _videoDuration.inMilliseconds) * constraints.maxWidth;
                      
                      return Positioned(
                        left: (startPosition * constraints.maxWidth).clamp(0.0, constraints.maxWidth - width),
                        top: 8,
                        child: GestureDetector(
                          onTap: () => _editTextOverlay(overlay),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Container(
                              width: width.clamp(50.0, double.infinity),
                              height: 34,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.accentMain,
                                    AppColors.accentDark,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentMain.withOpacity(0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    child: const Icon(Icons.text_fields, color: Colors.white, size: 14),
                                  ),
                                  Expanded(
                                    child: Text(
                                      overlay.text,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoTrack() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Video',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Track content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBrown.withOpacity(0.2),
                    AppColors.primaryMain.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: AppColors.warmBrown.withOpacity(0.3),
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_circle_outline, color: AppColors.warmBrown, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Main Video Track',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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
  }

  Widget _buildAudioTrack() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
      ),
      child: Row(
        children: [
          // Track label
          Container(
            width: 80,
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, color: AppColors.warmBrown, size: 16),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'Audio',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // Track content
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _audioFilePath != null
                      ? [
                          AppColors.accentMain.withOpacity(0.2),
                          AppColors.accentDark.withOpacity(0.1),
                        ]
                      : _audioRemoved
                          ? [
                              AppColors.errorMain.withOpacity(0.1),
                              AppColors.errorMain.withOpacity(0.05),
                            ]
                          : [
                              AppColors.backgroundTertiary,
                              AppColors.backgroundSecondary,
                            ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                border: Border.all(
                  color: _audioFilePath != null
                      ? AppColors.accentMain.withOpacity(0.3)
                      : AppColors.borderPrimary,
                ),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _audioFilePath != null
                          ? Icons.volume_up
                          : _audioRemoved
                              ? Icons.volume_off
                              : Icons.music_off,
                      color: _audioFilePath != null
                          ? AppColors.accentMain
                          : AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _audioFilePath != null
                          ? 'Audio track loaded'
                          : _audioRemoved
                              ? 'Audio removed'
                              : 'No audio track',
                      style: AppTypography.bodySmall.copyWith(
                        color: _audioFilePath != null
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: _audioFilePath != null ? FontWeight.w600 : FontWeight.normal,
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
  }


  Widget _buildEditPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.content_cut,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Trim Video',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Trim Controls
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Column(
              children: [
                // Start Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Start Time',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
                          ),
                          child: Text(
                            _formatTime(_trimStart),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Builder(
                      builder: (context) {
                        // Get duration and ensure it's valid
                        final durationSeconds = _videoDuration.inSeconds;
                        final maxValue = durationSeconds > 0 
                            ? durationSeconds.toDouble() 
                            : 1.0;
                        final trimStartValue = _trimStart.inSeconds.toDouble().clamp(0.0, maxValue);
                        
                        // Only show slider if duration is valid
                        if (maxValue <= 0 || maxValue.isNaN || maxValue.isInfinite) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.borderPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }
                        
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            activeTrackColor: AppColors.warmBrown,
                            inactiveTrackColor: AppColors.borderPrimary,
                            thumbColor: AppColors.warmBrown,
                          ),
                          child: Slider(
                            value: trimStartValue,
                            min: 0.0,
                            max: maxValue,
                            onChanged: (value) {
                              if (maxValue > 0) {
                                final clampedValue = value.clamp(0.0, maxValue);
                                setState(() {
                                  _trimStart = Duration(seconds: clampedValue.toInt());
                                  if (_trimStart >= _trimEnd) {
                                    _trimEnd = Duration(seconds: (clampedValue + 1).toInt().clamp(0, durationSeconds));
                                  }
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: AppSpacing.large),
                
                // End Time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'End Time',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                            border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
                          ),
                          child: Text(
                            _formatTime(_trimEnd),
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Builder(
                      builder: (context) {
                        // Get duration and ensure it's valid
                        final durationSeconds = _videoDuration.inSeconds;
                        final maxValue = durationSeconds > 0 
                            ? durationSeconds.toDouble() 
                            : 1.0;
                        final trimEndValue = _trimEnd.inSeconds.toDouble().clamp(0.0, maxValue);
                        
                        // Only show slider if duration is valid
                        if (maxValue <= 0 || maxValue.isNaN || maxValue.isInfinite) {
                          return Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.borderPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }
                        
                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 6,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
                            activeTrackColor: AppColors.warmBrown,
                            inactiveTrackColor: AppColors.borderPrimary,
                            thumbColor: AppColors.warmBrown,
                          ),
                          child: Slider(
                            value: trimEndValue,
                            min: 0.0,
                            max: maxValue,
                            onChanged: (value) {
                              if (maxValue > 0) {
                                final clampedValue = value.clamp(0.0, maxValue);
                                setState(() {
                                  _trimEnd = Duration(seconds: clampedValue.toInt());
                                  if (_trimEnd <= _trimStart) {
                                    _trimStart = Duration(seconds: (clampedValue - 1).toInt().clamp(0, durationSeconds));
                                  }
                                });
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.large),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isEditing ? null : _applyTrim,
              icon: const Icon(Icons.check_circle),
              label: Text(
                _isEditing ? 'Processing...' : 'Apply Trim',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.extraLarge,
                  vertical: AppSpacing.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicPanel() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.music_note,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Audio Track',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Audio Status Card
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: _audioFilePath != null
                        ? AppColors.accentMain.withOpacity(0.1)
                        : _audioRemoved
                            ? AppColors.errorMain.withOpacity(0.1)
                            : AppColors.backgroundTertiary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _audioFilePath != null
                        ? Icons.volume_up
                        : _audioRemoved
                            ? Icons.volume_off
                            : Icons.music_off,
                    color: _audioFilePath != null
                        ? AppColors.accentMain
                        : _audioRemoved
                            ? AppColors.errorMain
                            : AppColors.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _audioFilePath != null
                            ? 'Audio Track Loaded'
                            : _audioRemoved
                                ? 'Audio Removed'
                                : 'No Audio Track',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _audioFilePath != null
                            ? 'Custom audio track is active'
                            : _audioRemoved
                                ? 'Original audio has been removed'
                                : 'Video has original audio track',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: AppSpacing.large),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isEditing || _audioRemoved ? null : _removeAudio,
                  icon: const Icon(Icons.volume_off),
                  label: const Text('Remove Audio'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorMain,
                    side: BorderSide(color: AppColors.errorMain, width: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isEditing ? null : _selectAudioFile,
                  icon: const Icon(Icons.volume_up),
                  label: const Text('Add Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                    ),
                    elevation: 2,
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
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Icon(
                  Icons.text_fields,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Text Overlays',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Add Text Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _addTextOverlay,
              icon: const Icon(Icons.add_circle),
              label: const Text('Add Text Overlay'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.extraLarge,
                  vertical: AppSpacing.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                elevation: 2,
              ),
            ),
          ),
          
          // Text Overlays List
          if (_textOverlays.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.large),
            Text(
              'Active Overlays (${_textOverlays.length})',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            ..._textOverlays.map((overlay) => Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.small),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: _selectedTextOverlay?.id == overlay.id
                      ? AppColors.warmBrown
                      : AppColors.borderPrimary,
                  width: _selectedTextOverlay?.id == overlay.id ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.small),
                    decoration: BoxDecoration(
                      color: AppColors.accentMain.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                    ),
                    child: Icon(
                      Icons.text_fields,
                      color: AppColors.accentMain,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          overlay.text,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTime(overlay.startTime)} - ${_formatTime(overlay.endTime)}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: AppColors.warmBrown,
                      size: 20,
                    ),
                    onPressed: () => _editTextOverlay(overlay),
                    tooltip: 'Edit',
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

}

