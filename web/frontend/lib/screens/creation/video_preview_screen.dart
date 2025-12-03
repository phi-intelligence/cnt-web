import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/bank_details_helper.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../theme/app_typography.dart';
import '../editing/video_editor_screen.dart';
import '../web/video_editor_screen_web.dart';
import '../web/video_preview_screen_web.dart';

/// Video Preview Screen
/// Shows recorded/uploaded video with playback and controls
class VideoPreviewScreen extends StatefulWidget {
  final String videoUri;
  final String source; // 'camera' or 'gallery'
  final int duration;
  final int fileSize;

  const VideoPreviewScreen({
    super.key,
    required this.videoUri,
    required this.source,
    this.duration = 0,
    this.fileSize = 0,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Check if URI is a network URL or local file path
      final isNetworkUrl = widget.videoUri.startsWith('http://') || 
                          widget.videoUri.startsWith('https://');
      
      if (isNetworkUrl) {
        // Use network URL controller
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUri),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // For web, videoUri might be a blob URL or local path
        // For mobile, verify local file exists before initializing player
        if (kIsWeb) {
          // On web, use network URL (blob URLs or local paths work as network URLs)
          _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUri));
        } else {
          // Verify local file exists before initializing player (mobile only)
          final file = io.File(widget.videoUri);
          if (!await file.exists()) {
            setState(() {
              _hasError = true;
              _errorMessage = 'Video file not found at path: ${widget.videoUri}';
              _isInitializing = false;
            });
            return;
          }
          // On mobile, use file controller - cast to dynamic to avoid type issues
          // This is safe because we're in !kIsWeb block
          _controller = VideoPlayerController.file(file as dynamic);
        }
      }
      
      await _controller!.initialize();
      _controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
      setState(() {
        _isInitializing = false;
      });
    } catch (e) {
      print('Error initializing video player: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to load video: ${e.toString()}';
        _isInitializing = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(() {});
    _controller?.dispose();
    super.dispose();
  }

  void _handleBack() {
    Navigator.pop(context);
  }

  void _handlePlayPause() {
    if (_controller == null || !_controller!.value.isInitialized) return;
    
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
      } else {
        _controller!.play();
      }
    });
  }

  void _handleEdit() async {
    // Navigate to VideoEditorScreen (web or mobile version)
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => kIsWeb
            ? VideoEditorScreenWeb(
                videoPath: widget.videoUri,
                duration: widget.duration > 0 
                    ? Duration(seconds: widget.duration) 
                    : null,
              )
            : VideoEditorScreen(
                videoPath: widget.videoUri,
              ),
      ),
    );

    if (editedPath != null && mounted) {
      // Update video path with edited version
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video edited successfully')),
      );
      // TODO: Update video URI to edited path
    }
  }

  void _handleAddCaptions() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add captions feature')),
    );
  }

  void _handleDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Video'),
        content: const Text('Are you sure you want to delete this video? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePublish() async {
    setState(() {
      _isLoading = true;
    });

    // TODO: Implement actual video publish with API
    // For now, simulate publish success
    Future.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });

      // Check if bank details are missing
      final hasBankDetailsValue = await hasBankDetails(context);
      
      if (!hasBankDetailsValue && mounted) {
        // Show bank details prompt (handles navigation)
        await showBankDetailsPromptAfterPublish(context);
      } else if (mounted) {
        // Just show success and navigate
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Video Published'),
            content: const Text('Your video podcast has been published and shared with the community!'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    });
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
    
    // Calculate the correct unit index
    while (size >= k && i < sizes.length - 1) {
      size /= k;
      i++;
    }
    
    // Clamp index to valid range
    i = i.clamp(0, sizes.length - 1);
    
    return '${size.toStringAsFixed(2)} ${sizes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    // On web, use the web version
    if (kIsWeb) {
      return VideoPreviewScreenWeb(
        videoUri: widget.videoUri,
        source: widget.source,
        duration: widget.duration,
        fileSize: widget.fileSize,
      );
    }
    
    // Mobile version (original design with gradient)
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleBack,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
          onPressed: _handleDelete,
        ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryMain,
              AppColors.accentMain,
            ],
          ),
        ),
        child: Column(
          children: [
            // Video Player
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Actual Video Player
                    if (_isInitializing)
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    else if (_hasError)
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.white,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading video',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  _errorMessage!,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                        ),
                      )
                    else if (_controller != null && _controller!.value.isInitialized)
                      GestureDetector(
                        onTap: _handlePlayPause,
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              VideoPlayer(_controller!),
                              // Play/Pause overlay
                              if (!_controller!.value.isPlaying)
                                Container(
                                  color: Colors.black.withOpacity(0.3),
                                  child: Center(
                                    child: Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.play_arrow,
                                        size: 48,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),

            // Progress Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Row(
                children: [
                  SizedBox(
                    width: 50,
                    child: Text(
                      _controller != null && _controller!.value.isInitialized
                          ? _formatTime(_controller!.value.position.inSeconds)
                          : _formatTime(0),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _controller != null && _controller!.value.isInitialized
                          ? _controller!.value.position.inSeconds.toDouble()
                          : 0.0,
                      min: 0,
                      max: _controller != null && _controller!.value.isInitialized
                          ? _controller!.value.duration.inSeconds.toDouble()
                          : widget.duration.toDouble(),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white.withOpacity(0.3),
                      onChanged: (value) {
                        if (_controller != null && _controller!.value.isInitialized) {
                          _controller!.seekTo(Duration(seconds: value.toInt()));
                        }
                      },
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Text(
                      _controller != null && _controller!.value.isInitialized
                          ? _formatTime(_controller!.value.duration.inSeconds)
                          : _formatTime(widget.duration),
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),

            // Video Info
            Container(
              margin: const EdgeInsets.all(AppSpacing.large),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.info, 'Source: ${widget.source == 'camera' ? 'Camera Recording' : 'Gallery'}'),
                  _buildInfoRow(Icons.schedule, 'Duration: ${_formatTime(widget.duration)}'),
                  _buildInfoRow(Icons.storage, 'Size: ${_formatFileSize(widget.fileSize)}'),
                ],
              ),
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    label: 'Edit',
                    onPressed: _handleEdit,
                  ),
                  _buildActionButton(
                    icon: Icons.closed_caption,
                    label: 'Captions',
                    onPressed: _handleAddCaptions,
                  ),
                  _buildActionButton(
                    icon: Icons.publish,
                    label: _isLoading ? 'Publishing...' : 'Publish',
                    onPressed: _isLoading ? null : _handlePublish,
                    isPrimary: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.tiny),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.white),
          const SizedBox(width: AppSpacing.small),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
          decoration: BoxDecoration(
            color: isPrimary ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 24),
              const SizedBox(width: AppSpacing.tiny),
              Flexible(
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

