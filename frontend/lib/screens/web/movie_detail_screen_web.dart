import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../../models/content_item.dart';
import '../../models/api_models.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/shared/content_section.dart';
import '../../screens/video/video_player_full_screen.dart';
import '../../screens/donation_modal.dart';
import '../../utils/bank_details_helper.dart';
import 'dart:async';

/// Web-specific Movie Detail Screen with Netflix-style layout
class MovieDetailScreenWeb extends StatefulWidget {
  final ContentItem? item;
  final int? movieId;

  const MovieDetailScreenWeb({
    super.key,
    this.item,
    this.movieId,
  });

  @override
  State<MovieDetailScreenWeb> createState() => _MovieDetailScreenWebState();
}

class _MovieDetailScreenWebState extends State<MovieDetailScreenWeb> {
  final ApiService _apiService = ApiService();
  ContentItem? _item;
  Movie? _movie;
  List<ContentItem> _similarItems = [];
  bool _isLoading = true;
  bool _isLoadingSimilar = false;
  
  // Video preview
  VideoPlayerController? _previewController;
  bool _isPreviewLoading = false;
  bool _hasPreviewError = false;
  Timer? _previewLoopTimer;
  
  // User/Creator info
  Map<String, dynamic>? _creatorInfo;
  bool _isLoadingCreator = false;

  @override
  void initState() {
    super.initState();
    _loadMovie();
  }

  @override
  void dispose() {
    _previewController?.dispose();
    _previewLoopTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMovie() async {
    try {
      setState(() {
        _isLoading = true;
      });

      ContentItem? item;
      Movie? movie;

      if (widget.item != null) {
        item = widget.item;
      } else if (widget.movieId != null) {
        movie = await _apiService.getMovie(widget.movieId!);
        item = _apiService.movieToContentItem(movie);
      }

      if (item != null) {
        setState(() {
          _item = item;
          _movie = movie;
          _isLoading = false;
        });

        // Load similar movies
        if (widget.movieId != null) {
          _loadSimilarMovies(widget.movieId!);
        }

        // Load creator info if creatorId exists
        if (movie?.creatorId != null) {
          _loadCreatorInfo(movie!.creatorId!);
        }

        // Initialize video preview
        if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
          _initializePreview(item.videoUrl!);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading movie: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCreatorInfo(int creatorId) async {
    setState(() {
      _isLoadingCreator = true;
    });

    try {
      final creatorData = await _apiService.getPublicUserProfile(creatorId);
      setState(() {
        _creatorInfo = creatorData;
        _isLoadingCreator = false;
      });
    } catch (e) {
      print('Error loading creator info: $e');
      setState(() {
        _isLoadingCreator = false;
      });
    }
  }

  Future<void> _initializePreview(String videoUrl) async {
    try {
      setState(() {
        _isPreviewLoading = true;
        _hasPreviewError = false;
      });

      _previewController?.dispose();
      
      _previewController = VideoPlayerController.networkUrl(
        Uri.parse(videoUrl),
      );

      await _previewController!.initialize();
      
      // Set volume to 0 (muted)
      await _previewController!.setVolume(0.0);
      
      // Set loop to true
      await _previewController!.setLooping(true);
      
      // Start playing from beginning (first 30-60 seconds will loop)
      await _previewController!.seekTo(Duration.zero);
      await _previewController!.play();

      // Set up loop timer to restart preview every 60 seconds
      _previewLoopTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        if (_previewController != null && _previewController!.value.isInitialized) {
          _previewController!.seekTo(Duration.zero);
        }
      });

      setState(() {
        _isPreviewLoading = false;
      });
    } catch (e) {
      print('Error initializing preview: $e');
      setState(() {
        _isPreviewLoading = false;
        _hasPreviewError = true;
      });
    }
  }

  Future<void> _loadSimilarMovies(int movieId) async {
    try {
      setState(() {
        _isLoadingSimilar = true;
      });

      final similarMovies = await _apiService.getSimilarMovies(movieId, limit: 10);
      final similarItems = similarMovies.map((movie) {
        return _apiService.movieToContentItem(movie);
      }).toList().cast<ContentItem>();

      setState(() {
        _similarItems = similarItems;
        _isLoadingSimilar = false;
      });
    } catch (e) {
      print('Error loading similar movies: $e');
      setState(() {
        _isLoadingSimilar = false;
      });
    }
  }

  void _handlePlay() {
    if (_item?.videoUrl != null && _item!.videoUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerFullScreen(
            videoId: _item!.id,
            title: _item!.title,
            author: _item!.creator,
            duration: _item!.duration?.inSeconds ?? 0,
            gradientColors: const [AppColors.backgroundPrimary, AppColors.backgroundSecondary],
            videoUrl: _item!.videoUrl!,
            onBack: () => Navigator.of(context).pop(),
            onDonate: _handleDonate,
            onFavorite: _handleFavorite,
            onSeek: null,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video not available')),
      );
    }
  }

  Future<void> _handleDonate() async {
    if (_creatorInfo == null || _creatorInfo!['id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creator information not available')),
      );
      return;
    }

    final hasBankDetails = await checkBankDetailsAndNavigate(context);
    if (!hasBankDetails) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DonationModal(
        recipientName: _creatorInfo!['name'] ?? 'Creator',
        recipientUserId: _creatorInfo!['id'] as int,
      ),
    );
  }

  void _handleFavorite() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_item?.title ?? "Movie"} added to favorites')),
    );
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Text('Movie not found'),
        ),
      );
    }

    final item = _item!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    // Responsive hero height
    final heroHeight = isDesktop ? 0.8 : (isTablet ? 0.6 : 0.5);
    final heroHeightValue = MediaQuery.of(context).size.height * heroHeight;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero Section with Video Preview
          SliverToBoxAdapter(
            child: Container(
              height: heroHeightValue,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background video preview or cover image
                  if (_previewController != null && 
                      _previewController!.value.isInitialized && 
                      !_hasPreviewError)
                    FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _previewController!.value.size.width,
                        height: _previewController!.value.size.height,
                        child: VideoPlayer(_previewController!),
                      ),
                    )
                  else if (item.coverImage != null && item.coverImage!.isNotEmpty)
                    Image.network(
                      _apiService.getMediaUrl(item.coverImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.movie, color: Colors.white70, size: 64),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.movie, color: Colors.white70, size: 64),
                      ),
                    ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.8),
                        ],
                        stops: const [0.0, 0.6, 1.0],
                      ),
                    ),
                  ),

                  // Content overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(
                        isDesktop ? AppSpacing.extraLarge * 2 : 
                        (isTablet ? AppSpacing.extraLarge : AppSpacing.large),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Title
                          Text(
                            item.title,
                            style: AppTypography.heading1.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isDesktop ? 48 : (isTablet ? 36 : 28),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppSpacing.medium),

                          // Short description (truncated)
                          if (item.description != null && item.description!.isNotEmpty)
                            Text(
                              item.description!.length > 150
                                  ? '${item.description!.substring(0, 150)}...'
                                  : item.description!,
                              style: AppTypography.body.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: isDesktop ? 16 : 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: AppSpacing.large),

                          // Metadata row
                          Wrap(
                            spacing: AppSpacing.medium,
                            runSpacing: AppSpacing.small,
                            children: [
                              if (item.rating != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.rating!.toStringAsFixed(1),
                                      style: AppTypography.body.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              if (item.releaseDate != null)
                                Text(
                                  '${item.releaseDate!.year}',
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              if (item.duration != null)
                                Text(
                                  _formatDuration(item.duration!),
                                  style: AppTypography.body.copyWith(
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryMain.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: AppColors.primaryMain,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  item.category,
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.large),

                          // Action buttons
                          Wrap(
                            spacing: AppSpacing.medium,
                            runSpacing: AppSpacing.medium,
                            children: [
                              // Play button
                              StyledPillButton(
                                label: 'Play',
                                icon: Icons.play_arrow,
                                onPressed: _handlePlay,
                                width: isDesktop ? 200 : 150,
                              ),
                              // Donate button
                              if (_creatorInfo != null)
                                StyledPillButton(
                                  label: 'Donate',
                                  icon: Icons.favorite,
                                  variant: StyledPillButtonVariant.outlined,
                                  onPressed: _handleDonate,
                                  width: isDesktop ? 200 : 150,
                                ),
                              // Favorite button
                              IconButton(
                                icon: Icon(
                                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _handleFavorite,
                                tooltip: 'Favorite',
                              ),
                              // Share button
                              IconButton(
                                icon: const Icon(
                                  Icons.share,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: _handleShare,
                                tooltip: 'Share',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + AppSpacing.medium,
                    left: AppSpacing.medium,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 32),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(
                isDesktop ? AppSpacing.extraLarge * 2 : 
                (isTablet ? AppSpacing.extraLarge : AppSpacing.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator/User Information Card
                  if (_creatorInfo != null) ...[
                    SectionContainer(
                      child: Row(
                        children: [
                          // Avatar
                          CircleAvatar(
                            radius: isDesktop ? 40 : 30,
                            backgroundColor: AppColors.primaryMain.withOpacity(0.2),
                            backgroundImage: _creatorInfo!['avatar'] != null
                                ? NetworkImage(_apiService.getMediaUrl(_creatorInfo!['avatar']))
                                : null,
                            child: _creatorInfo!['avatar'] == null
                                ? Icon(
                                    Icons.person,
                                    size: isDesktop ? 40 : 30,
                                    color: AppColors.primaryMain,
                                  )
                                : null,
                          ),
                          const SizedBox(width: AppSpacing.large),
                          // Creator info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _creatorInfo!['name'] ?? 'Creator',
                                  style: AppTypography.heading3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (_creatorInfo!['bio'] != null && _creatorInfo!['bio'].toString().isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    _creatorInfo!['bio'],
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Donate button
                          StyledPillButton(
                            label: 'Donate',
                            icon: Icons.favorite,
                            onPressed: _handleDonate,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],

                  // Full Description
                  if (item.description != null && item.description!.isNotEmpty) ...[
                    SectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          StyledPageHeader(
                            title: 'Description',
                            size: StyledPageHeaderSize.h2,
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            item.description!,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],

                  // Director and Cast
                  if (item.director != null || item.cast != null) ...[
                    SectionContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (item.director != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Director: ',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.director!,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.medium),
                          ],
                          if (item.cast != null) ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cast: ',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item.cast!,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],

                  // Similar Content Section
                  if (_similarItems.isNotEmpty) ...[
                    StyledPageHeader(
                      title: 'Similar Content',
                      size: StyledPageHeaderSize.h2,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    ContentSection(
                      title: '',
                      items: _similarItems,
                      isHorizontal: true,
                      onItemTap: (similarItem) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MovieDetailScreenWeb(
                              item: similarItem,
                              movieId: int.tryParse(similarItem.id),
                            ),
                          ),
                        );
                      },
                    ),
                  ] else if (_isLoadingSimilar) ...[
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.large),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

