import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:video_player/video_player.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/thumbnail_selector.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'video_editor_screen_web.dart';
import 'package:go_router/go_router.dart';

/// Web Movie Preview Screen
/// Shows recorded/uploaded video with playback and controls
/// Includes movie metadata form (title, description, director, cast, release date, category, rating, cover image, featured)
class MoviePreviewScreenWeb extends StatefulWidget {
  final String videoUri;
  final String source; // 'camera' or 'gallery'
  final int duration;
  final int fileSize;

  const MoviePreviewScreenWeb({
    super.key,
    required this.videoUri,
    required this.source,
    this.duration = 0,
    this.fileSize = 0,
  });

  @override
  State<MoviePreviewScreenWeb> createState() => _MoviePreviewScreenWebState();
}

class _MoviePreviewScreenWebState extends State<MoviePreviewScreenWeb> {
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _directorController = TextEditingController();
  final TextEditingController _castController = TextEditingController();
  String? _selectedThumbnail;
  String? _videoUrl; // Will be set after upload
  DateTime? _releaseDate;
  double _rating = 0.0;
  int? _selectedCategoryId;
  bool _isFeatured = false;
  
  // Categories
  List<Category> _categories = [];
  bool _loadingCategories = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
    _loadCategories();
  }
  
  Future<void> _loadCategories() async {
    setState(() {
      _loadingCategories = true;
    });
    
    try {
      final categories = await ApiService().getCategories();
      // Filter for movie categories only
      final movieCategories = categories.where((c) => c.type == 'movie').toList();
      if (mounted) {
        setState(() {
          _categories = movieCategories;
          _loadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading categories: $e');
      if (mounted) {
        setState(() {
          _loadingCategories = false;
        });
      }
    }
  }

  Future<void> _initializePlayer() async {
    try {
      final isNetworkUrl = widget.videoUri.startsWith('http://') || 
                          widget.videoUri.startsWith('https://');
      final isBlobUrl = widget.videoUri.startsWith('blob:');
      
      if (kIsWeb || isNetworkUrl || isBlobUrl) {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUri),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
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
        if (mounted && (_controller?.value.isPlaying ?? false) && !_isScrubbing) {
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
    _titleController.dispose();
    _descriptionController.dispose();
    _directorController.dispose();
    _castController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (GoRouter.of(context).canPop()) {
      GoRouter.of(context).pop();
    } else {
      Navigator.pop(context);
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
    
    _showControlsWithAutoHide();
  }

  void _handleEdit() async {
    String videoPathToUse = widget.videoUri;
    int? backendDuration;
    
    if (kIsWeb && widget.videoUri.startsWith('blob:')) {
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing video for editing...')),
        );
        final uploadResult = await ApiService().uploadTemporaryMedia(widget.videoUri, 'video');
        if (uploadResult != null) {
          final backendUrl = uploadResult['url'] as String?;
          backendDuration = uploadResult['duration'] as int?;
          if (backendUrl != null) {
            videoPathToUse = backendUrl;
          }
        }
      } catch (e) {
        print('⚠️ Failed to upload blob before editor: $e');
      }
    }
    
    final durationToUse = backendDuration ?? widget.duration;
    
    final editedPath = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => VideoEditorScreenWeb(
          videoPath: videoPathToUse,
          duration: durationToUse > 0 
              ? Duration(seconds: durationToUse) 
              : null,
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
    // Validate required fields
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a title for the movie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload video file first
      String videoUrl;
      String? thumbnailUrl;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading video...'),
          backgroundColor: AppColors.infoMain,
          duration: Duration(seconds: 60),
        ),
      );
      
      final videoUploadResponse = await ApiService().uploadVideo(
        widget.videoUri, 
        generateThumbnail: true,
      );
      videoUrl = videoUploadResponse['url'] as String;
      thumbnailUrl = videoUploadResponse['thumbnail_url'] as String?;
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      
      if (thumbnailUrl != null && _selectedThumbnail == null) {
        _selectedThumbnail = thumbnailUrl;
      }

      // Get actual duration from video or use widget duration
      int? actualDuration = widget.duration > 0 ? widget.duration : null;
      if (_controller != null && _controller!.value.isInitialized) {
        final controllerDuration = _controller!.value.duration.inSeconds;
        if (controllerDuration > 0) {
          actualDuration = controllerDuration;
        }
      }

      // Check if user is admin - admins can set status to "approved" directly
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = authProvider.isAdmin;
      
      // Create movie
      await ApiService().createMovie(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        videoUrl: videoUrl,
        coverImage: _selectedThumbnail,
        duration: actualDuration,
        director: _directorController.text.trim().isEmpty 
            ? null 
            : _directorController.text.trim(),
        cast: _castController.text.trim().isEmpty 
            ? null 
            : _castController.text.trim(),
        releaseDate: _releaseDate,
        rating: _rating > 0 ? _rating : null,
        categoryId: _selectedCategoryId,
        isFeatured: _isFeatured,
        status: isAdmin ? 'approved' : 'pending', // Admins can approve directly
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            'Movie Published',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            isAdmin
                ? 'Your movie has been published and is now live!'
                : 'Your movie has been published and is pending admin approval!',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(
                'OK',
                style: AppTypography.button.copyWith(
                  color: AppColors.primaryMain,
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
          content: Text('Failed to publish movie: $e'),
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

  Future<void> _selectReleaseDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _releaseDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _releaseDate) {
      setState(() {
        _releaseDate = picked;
      });
    }
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
                  onPressed: _handleBack,
                ),
                Expanded(
                  child: StyledPageHeader(
                    title: 'Movie Preview',
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
                  final useHorizontalLayout = constraints.maxWidth > 1024;
                  
                  if (useHorizontalLayout) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: SectionContainer(
                            showShadow: true,
                            padding: EdgeInsets.zero,
                            child: _buildVideoPlayer(),
                          ),
                        ),
                        SizedBox(width: AppSpacing.large),
                        Expanded(
                          flex: 2,
                          child: SectionContainer(
                            showShadow: true,
                            child: _buildMovieForm(),
                          ),
                        ),
                      ],
                    );
                  } else {
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
                            child: _buildMovieForm(),
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
                        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              VideoPlayer(_controller!),
                              
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
                                      if (!_controller!.value.isPlaying || _isMouseOverVideo)
                                        Center(
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: _handlePlayPause,
                                              child: Container(
                                                width: 80,
                                                height: 80,
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
                                                  size: 48,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      
                                      Positioned(
                                        bottom: 0,
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(AppSpacing.medium),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Row(
                                                children: [
                                                  SizedBox(
                                                    width: 60,
                                                    child: Text(
                                                      _formatTime((_isScrubbing
                                                              ? _scrubValue.toInt()
                                                              : _controller!.value.position.inSeconds)),
                                                      style: AppTypography.bodySmall.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Builder(
                                                      builder: (context) {
                                                        final durationSeconds = _controller!.value.duration.inSeconds;
                                                        final positionSeconds = _isScrubbing
                                                            ? _scrubValue
                                                            : _controller!.value.position.inSeconds.toDouble();
                                                        
                                                        final maxValue = durationSeconds > 0 
                                                            ? durationSeconds.toDouble() 
                                                            : 1.0;
                                                        
                                                        final clampedValue = positionSeconds.clamp(0.0, maxValue);
                                                        
                                                        if (maxValue <= 0 || maxValue.isNaN || maxValue.isInfinite) {
                                                          return Container(
                                                            height: 4,
                                                            decoration: BoxDecoration(
                                                              color: Colors.white.withOpacity(0.3),
                                                              borderRadius: BorderRadius.circular(2),
                                                            ),
                                                          );
                                                        }
                                                        
                                                        return SliderTheme(
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
                                                            value: clampedValue,
                                                            min: 0.0,
                                                            max: maxValue,
                                                            activeColor: Colors.white,
                                                            inactiveColor: Colors.white.withOpacity(0.3),
                                                            onChanged: (value) {
                                                              setState(() {
                                                                _isScrubbing = true;
                                                                _scrubValue = value;
                                                              });
                                                            },
                                                            onChangeStart: (value) {
                                                              setState(() {
                                                                _wasPlayingBeforeScrub = _controller!.value.isPlaying;
                                                                if (_wasPlayingBeforeScrub) {
                                                                  _controller!.pause();
                                                                }
                                                              });
                                                            },
                                                            onChangeEnd: (value) async {
                                                              await _controller!.seekTo(Duration(seconds: value.toInt()));
                                                              setState(() {
                                                                _isScrubbing = false;
                                                              });
                                                              if (_wasPlayingBeforeScrub) {
                                                                _controller!.play();
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
                                                      _formatTime(_controller!.value.duration.inSeconds),
                                                      style: AppTypography.bodySmall.copyWith(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                      textAlign: TextAlign.right,
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

  Widget _buildMovieForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StyledPillButton(
            label: 'Edit Video',
            icon: Icons.edit,
            onPressed: _handleEdit,
            variant: StyledPillButtonVariant.outlined,
          ),
          const SizedBox(height: AppSpacing.large),
          
          Text(
            'Movie Details',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          
          // Title (required)
          TextField(
            controller: _titleController,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Title *',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter movie title',
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
            maxLines: 3,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Description',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter movie description',
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
          
          // Director
          TextField(
            controller: _directorController,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Director',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter director name',
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
          
          // Cast
          TextField(
            controller: _castController,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Cast',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter cast (comma-separated)',
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
          
          // Release Date
          InkWell(
            onTap: _selectReleaseDate,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium + 4,
              ),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      _releaseDate != null
                          ? '${_releaseDate!.day}/${_releaseDate!.month}/${_releaseDate!.year}'
                          : 'Release Date (optional)',
                      style: AppTypography.body.copyWith(
                        color: _releaseDate != null
                            ? AppColors.textPrimary
                            : AppColors.textPlaceholder,
                      ),
                    ),
                  ),
                  if (_releaseDate != null)
                    IconButton(
                      icon: Icon(Icons.clear, size: 18, color: AppColors.textSecondary),
                      onPressed: () {
                        setState(() {
                          _releaseDate = null;
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Category Dropdown
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.small,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderPrimary),
            ),
            child: DropdownButtonFormField<int>(
              value: _selectedCategoryId,
              decoration: InputDecoration(
                labelText: 'Category (optional)',
                labelStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              items: [
                DropdownMenuItem<int>(
                  value: null,
                  child: Text(
                    'No Category',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPlaceholder,
                    ),
                  ),
                ),
                ..._categories.map((category) {
                  return DropdownMenuItem<int>(
                    value: category.id,
                    child: Text(
                      category.name,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedCategoryId = value;
                });
              },
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Rating Slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rating: ${_rating.toStringAsFixed(1)}/10',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Slider(
                value: _rating,
                min: 0.0,
                max: 10.0,
                divisions: 20,
                label: _rating.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _rating = value;
                  });
                },
                activeColor: AppColors.warmBrown,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Cover Image
          ThumbnailSelector(
            isVideo: true,
            videoUrl: _videoUrl ?? widget.videoUri,
            onThumbnailSelected: (thumbnailUrl) {
              setState(() {
                _selectedThumbnail = thumbnailUrl;
              });
            },
            initialThumbnail: _selectedThumbnail,
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Featured Toggle
          Row(
            children: [
              Checkbox(
                value: _isFeatured,
                onChanged: (value) {
                  setState(() {
                    _isFeatured = value ?? false;
                  });
                },
                activeColor: AppColors.warmBrown,
              ),
              Expanded(
                child: Text(
                  'Feature this movie',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          
          // Publish Button
          SizedBox(
            width: double.infinity,
            child: StyledPillButton(
              label: _isLoading ? 'Publishing...' : 'Publish Movie',
              onPressed: _isLoading ? null : _handlePublish,
              variant: StyledPillButtonVariant.filled,
            ),
          ),
        ],
      ),
    );
  }
}

