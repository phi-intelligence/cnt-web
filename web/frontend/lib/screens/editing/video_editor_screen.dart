import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import 'dart:math' as math;
import 'package:path/path.dart' as path;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/video_editing_service.dart';
import '../../models/text_overlay.dart';
import '../../utils/editor_responsive.dart';
import 'package:video_player/video_player.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../web/video_editor_screen_web.dart';

/// Video Editor Screen - Professional Video Editing UI
/// Features: Multi-track timeline, text overlays, trimming, filters, audio tracks
class VideoEditorScreen extends StatefulWidget {
  final String videoPath;
  final String? title;

  const VideoEditorScreen({
    super.key,
    required this.videoPath,
    this.title,
  });

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> with SingleTickerProviderStateMixin {
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
  
  String? _editedVideoPath;
  final _uuid = const Uuid();

  // Video thumbnails for timeline
  List<ImageProvider?> _videoThumbnails = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // 5 tabs: Edit, Music, Text, Filters, Adjust
    _initializePlayer();
  }
  
  Future<void> _generateThumbnails() async {
    // Generate thumbnails for video track
    // For now, use placeholder thumbnails - in production, extract frames from video
    if (_controller == null || !_controller!.value.isInitialized || _videoDuration == Duration.zero) return;
    
    // Placeholder: Generate thumbnails every 2 seconds
    final thumbnailCount = (_videoDuration.inSeconds / 2).ceil().clamp(0, 50); // Limit to 50 thumbnails max
    _videoThumbnails = List<ImageProvider?>.filled(thumbnailCount, null);
    setState(() {});
  }

  Future<void> _initializePlayer() async {
    try {
      final isNetwork = widget.videoPath.startsWith('http');
      
      if (isNetwork) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
      } else {
        // On web, use network URL even for local paths (blob URLs)
        // On mobile, use file controller with dart:io File
        if (kIsWeb) {
          _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoPath));
        } else {
          // On mobile, use file controller - cast to dynamic to avoid type issues
          // This is safe because we're in !kIsWeb block
          final file = io.File(widget.videoPath);
          _controller = VideoPlayerController.file(file as dynamic);
        }
      }
      
      await _controller!.initialize();
      _controller!.addListener(_videoListener);
      
      // Extract project title from filename
      final fileName = path.basename(widget.videoPath);
      _projectTitle = widget.title ?? fileName.split('.').first;
      
      // Extract video metadata
      final size = _controller!.value.size;
      _resolution = _getResolutionFromSize(size);
      _fps = _controller!.value.size.height > 720 ? 30.0 : 29.97; // Estimate, video_player doesn't expose FPS directly
      
      setState(() {
        _isInitializing = false;
        _videoDuration = _controller!.value.duration;
        _trimEnd = _videoDuration;
      });
      
      // Generate thumbnails after video is initialized
      _generateThumbnails();
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _hasError = true;
        _errorMessage = _formatVideoError(e);
      });
    }
  }

  /// Format video errors into user-friendly messages
  String _formatVideoError(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('MEDIA_ERR_SRC_NOT_SUPPORTED') ||
        errorStr.contains('Format error') ||
        errorStr.contains('format not supported')) {
      return 'This video format is not supported by your browser.\n\n'
             'Tip: Try converting your video to MP4 format (H.264 codec) for best compatibility.';
    }

    if (errorStr.contains('MEDIA_ERR_NETWORK') ||
        errorStr.contains('network') ||
        errorStr.contains('Failed to load')) {
      return 'Failed to load video. Please check your internet connection and try again.';
    }

    if (errorStr.contains('MEDIA_ERR_DECODE') || errorStr.contains('decode')) {
      return 'This video file appears to be corrupted or uses an unsupported codec.\n\n'
             'Tip: Try re-encoding the video or use a different file.';
    }

    if (errorStr.contains('TimeoutException') || errorStr.contains('timeout')) {
      return 'Video took too long to load. Please try again or use a smaller file.';
    }

    if (errorStr.contains('blob:') || errorStr.contains('Blob')) {
      return 'Unable to process recorded video. Please try recording again.';
    }

    if (errorStr.contains('Permission') || errorStr.contains('denied')) {
      return 'Permission denied. Please check file access permissions.';
    }

    if (errorStr.contains('FileSystemException') || errorStr.contains('No such file')) {
      return 'Video file not found. The file may have been moved or deleted.';
    }

    return 'Error loading video: $errorStr';
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

  void _togglePlayPause() {
    if (_controller == null) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _seekToPosition(double position) {
    if (_controller == null || _videoDuration == Duration.zero) return;
    
    final targetPosition = Duration(
      milliseconds: (position * _videoDuration.inMilliseconds).toInt(),
    );
    _controller!.seekTo(targetPosition);
    setState(() {
      _playheadPosition = position;
    });
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
    setState(() {
      _playheadPosition = position.clamp(0.0, 1.0);
    });
    _seekToPosition(_playheadPosition);
  }

  void _onPlayheadDragEnd() {
    setState(() {
      _isDraggingPlayhead = false;
    });
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
        height: EditorResponsive.getModalHeight(context),
        decoration: const BoxDecoration(
          color: AppColors.backgroundPrimary,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: EditorResponsive.getSectionPadding(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Text',
                    style: TextStyle(
                      fontSize: EditorResponsive.getControlTextSize(context) + 4,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary, size: EditorResponsive.getIconButtonSize(context)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(),
            
            // Text input
            Padding(
              padding: EditorResponsive.getSectionPadding(context),
              child: TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: EditorResponsive.isMobile(context) ? 2 : 3,
                style: TextStyle(fontSize: EditorResponsive.getControlTextSize(context)),
              ),
            ),
            
            // Controls
            Padding(
              padding: EditorResponsive.getSectionPadding(context),
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
                      icon: Icon(Icons.delete, size: EditorResponsive.getIconButtonSize(context) * 0.8),
                      label: Text('Delete', style: TextStyle(fontSize: EditorResponsive.getControlTextSize(context))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorMain,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: EditorResponsive.isMobile(context) ? 8 : 12,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: EditorResponsive.isMobile(context) ? 8 : 16),
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
                      icon: Icon(Icons.check, size: EditorResponsive.getIconButtonSize(context) * 0.8),
                      label: Text('Save', style: TextStyle(fontSize: EditorResponsive.getControlTextSize(context))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryMain,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          vertical: EditorResponsive.isMobile(context) ? 8 : 12,
                        ),
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
        const SnackBar(content: Text('Start time must be less than end time')),
      );
      return;
    }

    setState(() {
      _isEditing = true;
      _hasError = false;
    });

    final outputPath = await _editingService.trimVideo(
      _editedVideoPath ?? widget.videoPath,
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
        const SnackBar(content: Text('Video trimmed successfully')),
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
        const SnackBar(content: Text('Audio removed successfully')),
      );
    }
  }

  Future<void> _selectAudioFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final audioPath = result.files.single.path!;
        await _addAudioTrack(audioPath);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting audio file: $e')),
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
        const SnackBar(content: Text('Audio track added successfully')),
      );
    }
  }

  Future<void> _applyFilters() async {
    final inputPath = _editedVideoPath ?? widget.videoPath;
    
    if (_brightness == 0.0 && _contrast == 1.0 && _saturation == 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No filters to apply')),
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
        const SnackBar(content: Text('Filters applied successfully')),
      );
    }
  }

  Future<void> _reloadPlayer(String path) async {
    await _controller?.dispose();
    // On web, use network URL even for local paths (blob URLs)
    // On mobile, use file controller with dart:io File
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(path));
    } else {
      // On mobile, use file controller - cast to dynamic to avoid type issues
      // This is safe because we're in !kIsWeb block
      final file = io.File(path);
      _controller = VideoPlayerController.file(file as dynamic);
    }
    await _controller!.initialize();
    _controller!.addListener(_videoListener);
    setState(() {});
  }

  void _handleExport() {
    if (_editedVideoPath == null && _textOverlays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No edits to export')),
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
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On web, use the web version
    if (kIsWeb) {
      return VideoEditorScreenWeb(
        videoPath: widget.videoPath,
        title: widget.title,
      );
    }

    // Mobile version
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: const Center(child: CircularProgressIndicator(color: AppColors.primaryMain)),
      );
    }

    if (_hasError) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.white),
              const SizedBox(height: 16),
              const Text(
                'Error loading video',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
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
    return Container(
      padding: EditorResponsive.getSectionPadding(context),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.textPrimary, size: EditorResponsive.getIconButtonSize(context)),
            onPressed: () => Navigator.pop(context),
          ),
          
          // Project title and resolution
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _projectTitle ?? 'Untitled Project',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: EditorResponsive.getControlTextSize(context) + 2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$_resolution • ${_fps.toStringAsFixed(2)} FPS',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: EditorResponsive.getControlTextSize(context) - 2,
                  ),
                ),
              ],
            ),
          ),
          
          // Action buttons - Responsive layout
          if (EditorResponsive.isMobile(context))
            // Mobile: Use menu button for more actions
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
              onSelected: (value) {
                switch (value) {
                  case 'undo':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Undo feature coming soon')),
                    );
                    break;
                  case 'redo':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redo feature coming soon')),
                    );
                    break;
                  case 'export':
                    _handleExport();
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'undo', child: Text('Undo')),
                const PopupMenuItem(value: 'redo', child: Text('Redo')),
                const PopupMenuItem(value: 'export', child: Text('Export')),
              ],
            )
          else
            // Tablet/Desktop: Show individual buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Undo button
                IconButton(
                  icon: Icon(Icons.undo, color: AppColors.textSecondary, size: EditorResponsive.getIconButtonSize(context)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Undo feature coming soon')),
                    );
                  },
                ),
                
                // Redo button
                IconButton(
                  icon: Icon(Icons.redo, color: AppColors.textSecondary, size: EditorResponsive.getIconButtonSize(context)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Redo feature coming soon')),
                    );
                  },
                ),
                
                // Share/Export button
                IconButton(
                  icon: Icon(Icons.share, color: AppColors.primaryMain, size: EditorResponsive.getIconButtonSize(context)),
                  onPressed: _handleExport,
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Container(
      color: Colors.black, // Keep black for video preview area
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
        ],
      ),
    );
  }

  Widget _buildPlaybackControls() {
    final buttonSize = EditorResponsive.getPlayButtonSize(context);
    final textSize = EditorResponsive.getControlTextSize(context);
    
    return Container(
      padding: EditorResponsive.getSectionPadding(context),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.borderSecondary, width: 1),
          bottom: BorderSide(color: AppColors.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Current time
          Text(
            _formatTime(_currentPosition),
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: textSize,
            ),
          ),
          
          const Spacer(),
          
          // Play button (centered) - Responsive size
          GestureDetector(
            onTap: _togglePlayPause,
            child: Container(
              width: buttonSize,
              height: buttonSize,
              decoration: BoxDecoration(
                color: AppColors.primaryMain,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryMain.withOpacity(0.3),
                    blurRadius: buttonSize * 0.15,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: buttonSize * 0.65,
              ),
            ),
          ),
          
          const Spacer(),
          
          // Total duration
          Text(
            '/${_formatTime(_videoDuration)}',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: textSize,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    final timelineHeight = EditorResponsive.getTimelineHeight(context);
    
    return Container(
      height: timelineHeight,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.borderSecondary, width: 1),
        ),
      ),
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
    final trackHeight = EditorResponsive.getTrackHeight(context);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: trackHeight,
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
                  top: 4,
                  child: GestureDetector(
                    onTap: () => _editTextOverlay(overlay),
                    child: Container(
                      width: width,
                      height: trackHeight - 8,
                      decoration: BoxDecoration(
                        color: AppColors.accentMain,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          if (!EditorResponsive.isMobile(context))
                            Container(
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.text_fields, color: Colors.white, size: 12),
                            ),
                          Expanded(
                            child: Text(
                              overlay.text,
                              style: TextStyle(
                                color: Colors.white, 
                                fontSize: EditorResponsive.getControlTextSize(context) - 2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
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
    final trackHeight = EditorResponsive.getTrackHeight(context);
    
    return Container(
      height: trackHeight,
      color: AppColors.backgroundPrimary,
      child: Row(
        children: [
          // Scroll left arrow
          Container(
            width: EditorResponsive.isMobile(context) ? 30 : 40,
            child: Icon(
              Icons.chevron_left, 
              color: AppColors.textSecondary,
              size: EditorResponsive.getIconButtonSize(context) * 0.6,
            ),
          ),
          
          // Video thumbnails
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _videoThumbnails.length,
              itemBuilder: (context, index) {
                // Generate thumbnail preview from video frames
                // For now, use video player to extract frames
                final thumbnailTime = Duration(seconds: index * 2);
                return Container(
                  width: 80,
                  margin: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundTertiary,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSecondary),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: _buildThumbnailWidget(index, thumbnailTime),
                  ),
                );
              },
            ),
          ),
          
          // Add video button
          Container(
            width: 40,
            child: Icon(Icons.add_circle, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThumbnailWidget(int index, Duration time) {
    // Try to get frame from video at specific time
    // For now, show placeholder with time indicator
    return Stack(
      fit: StackFit.expand,
      children: [
        // Placeholder background
        Container(
          color: AppColors.backgroundTertiary,
          child: const Center(
            child: Icon(Icons.videocam, color: AppColors.textTertiary, size: 24),
          ),
        ),
        // Time indicator
        Positioned(
          bottom: 2,
          right: 2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              _formatTime(time),
              style: const TextStyle(color: Colors.white, fontSize: 8),
            ),
          ),
        ),
      ],
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
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            border: Border(
              top: BorderSide(color: AppColors.borderSecondary, width: 1),
            ),
          ),
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
        
        // Tab bar
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            border: Border(
              top: BorderSide(color: AppColors.borderSecondary, width: 1),
            ),
          ),
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
                const SnackBar(content: Text('Adjustments feature coming soon')),
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
