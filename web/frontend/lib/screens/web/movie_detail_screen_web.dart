import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/content_item.dart';
import '../../models/api_models.dart';
import '../../services/api_service.dart';
import '../../providers/artist_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/playlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/shared/content_section.dart';
import '../../screens/video/video_player_full_screen.dart';
import '../../screens/donation_modal.dart';
import '../../utils/bank_details_helper.dart';
import 'dart:async';
import '../../services/logger_service.dart';

/// Web-specific Movie Detail Screen - Redesigned
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
    _checkFavoriteStatus();
  }
  
  Future<void> _checkFavoriteStatus() async {
    // Check favorite status when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _item != null) {
        final favoritesProvider = context.read<FavoritesProvider>();
        favoritesProvider.checkFavoriteStatus(_item!);
      }
    });
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
      LoggerService.e('Error loading movie: $e');
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
      LoggerService.e('Error loading creator info: $e');
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
      await _previewController!.setVolume(0.0);
      await _previewController!.setLooping(true);
      await _previewController!.seekTo(Duration.zero);
      await _previewController!.play();

      _previewLoopTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
        if (_previewController != null && _previewController!.value.isInitialized) {
          _previewController!.seekTo(Duration.zero);
        }
      });

      setState(() {
        _isPreviewLoading = false;
      });
    } catch (e) {
      LoggerService.e('Error initializing preview: $e');
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
      LoggerService.e('Error loading similar movies: $e');
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

    final recipientId = _creatorInfo!['id'] as int;
    final recipientName = _creatorInfo!['name'] ?? 'Creator';

    // Check if recipient has bank details before showing donation modal
    final hasRecipientBankDetails = await checkRecipientBankDetails(recipientId);
    if (!hasRecipientBankDetails) {
      // Show error dialog if recipient doesn't have bank details
      await showRecipientBankDetailsMissingDialog(context, recipientName);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => DonationModal(
        recipientName: recipientName,
        recipientUserId: recipientId,
      ),
    );
  }

  Future<void> _handleFavorite() async {
    if (_item == null) return;
    
    final favoritesProvider = context.read<FavoritesProvider>();
    final isFavorite = favoritesProvider.isFavorite(_item!.id);
    
    final success = await favoritesProvider.toggleFavorite(_item!);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? (isFavorite 
                    ? 'Removed from favorites' 
                    : 'Added to favorites')
                : 'Failed to update favorites',
          ),
          backgroundColor: success ? AppColors.successMain : AppColors.errorMain,
        ),
      );
      
      // Update local state to reflect change
      if (success) {
        setState(() {
          // Toggle the isFavorite state in the item if applicable
        });
      }
    }
  }
  
  Future<void> _handleAddToList() async {
    if (_item == null) return;
    
    // Show playlist selection dialog
    await showDialog(
      context: context,
      builder: (context) => _PlaylistSelectionDialog(
        item: _item!,
        onPlaylistSelected: (playlistId) async {
          final playlistProvider = context.read<PlaylistProvider>();
          final success = await playlistProvider.addItemToPlaylist(
            playlistId,
            _item!,
          );
          
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success 
                      ? 'Added to playlist' 
                      : 'Failed to add to playlist',
                ),
                backgroundColor: success ? AppColors.successMain : AppColors.errorMain,
              ),
            );
          }
        },
      ),
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
      resizeToAvoidBottomInset: false,
        body: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
          ),
        ),
      );
    }

    if (_item == null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.movie_outlined, size: 64, color: AppColors.textTertiary),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Movie not found',
                style: AppTypography.heading3.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.large),
              StyledPillButton(
                label: 'Go Back',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      );
    }

    final item = _item!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    final heroHeight = MediaQuery.of(context).size.height * (isDesktop ? 0.75 : 0.6);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: SizedBox(
              height: heroHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background video/image
                  _buildHeroBackground(item),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                          Colors.black.withOpacity(0.9),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  // Content overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildHeroContent(item, isDesktop, isTablet),
                  ),

                  // Back button
                  Positioned(
                    top: MediaQuery.of(context).padding.top + AppSpacing.medium,
                    left: AppSpacing.large,
                    child: _buildBackButton(),
                  ),
                ],
              ),
            ),
          ),

          // Content Section
          SliverToBoxAdapter(
            child: _buildContentSection(item, isDesktop, isTablet),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBackground(ContentItem item) {
    if (_previewController != null && 
        _previewController!.value.isInitialized && 
        !_hasPreviewError) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.cover,
          clipBehavior: Clip.hardEdge,
          child: SizedBox(
            width: _previewController!.value.size.width,
            height: _previewController!.value.size.height,
            child: VideoPlayer(_previewController!),
          ),
        ),
      );
    } else if (item.coverImage != null && item.coverImage!.isNotEmpty) {
      return Image.network(
        _apiService.getMediaUrl(item.coverImage!),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholderBackground();
        },
      );
    }
    return _buildPlaceholderBackground();
  }

  Widget _buildPlaceholderBackground() {
    return Container(
      color: AppColors.warmBrown.withOpacity(0.3),
      child: const Center(
        child: Icon(Icons.movie, color: Colors.white24, size: 100),
      ),
    );
  }

  Widget _buildBackButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildHeroContent(ContentItem item, bool isDesktop, bool isTablet) {
    final horizontalPadding = isDesktop ? 80.0 : (isTablet ? 40.0 : 24.0);
    
    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Category badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warmBrown,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              item.category.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Title
          Text(
            item.title,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 48 : (isTablet ? 36 : 28),
              height: 1.1,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.medium),

          // Metadata row
          _buildMetadataRow(item),
          const SizedBox(height: AppSpacing.large),

          // Description preview
          if (item.description != null && item.description!.isNotEmpty)
            Text(
              item.description!.length > 180
                  ? '${item.description!.substring(0, 180)}...'
                  : item.description!,
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
                fontSize: isDesktop ? 16 : 14,
                height: 1.5,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: AppSpacing.extraLarge),

          // Action buttons
          _buildActionButtons(isDesktop),
        ],
      ),
    );
  }

  Widget _buildMetadataRow(ContentItem item) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.small,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (item.rating != null)
          _buildMetadataChip(
            icon: Icons.star,
            iconColor: Colors.amber,
            text: item.rating!.toStringAsFixed(1),
          ),
        if (item.releaseDate != null)
          _buildMetadataChip(
            icon: Icons.calendar_today,
            text: '${item.releaseDate!.year}',
          ),
        if (item.duration != null)
          _buildMetadataChip(
            icon: Icons.schedule,
            text: _formatDuration(item.duration!),
          ),
      ],
    );
  }

  Widget _buildMetadataChip({required IconData icon, required String text, Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor ?? Colors.white.withOpacity(0.9)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDesktop) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorite = _item != null && favoritesProvider.isFavorite(_item!.id);
        
        return Wrap(
          spacing: AppSpacing.medium,
          runSpacing: AppSpacing.medium,
          children: [
            // Play button
            _buildPrimaryButton(
              icon: Icons.play_arrow,
              label: 'Play Now',
              onTap: _handlePlay,
            ),
            // Add to List button
            _buildSecondaryButton(
              icon: Icons.add,
              onTap: _handleAddToList,
              tooltip: 'Add to List',
            ),
            // Favorite button
            _buildSecondaryButton(
              icon: isFavorite ? Icons.favorite : Icons.favorite_border,
              onTap: _handleFavorite,
              tooltip: isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              isActive: isFavorite,
            ),
            // Share button
            _buildSecondaryButton(
              icon: Icons.share,
              onTap: _handleShare,
              tooltip: 'Share',
            ),
            // Donate button
            if (_creatorInfo != null)
              _buildSecondaryButton(
                icon: Icons.volunteer_activism,
                onTap: _handleDonate,
                tooltip: 'Support Creator',
              ),
          ],
        );
      },
    );
  }

  Widget _buildPrimaryButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.warmBrown,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.warmBrown.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon, 
    required VoidCallback onTap,
    String? tooltip,
    bool isActive = false,
  }) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: isActive 
              ? AppColors.warmBrown.withOpacity(0.3) 
              : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive 
                ? AppColors.warmBrown 
                : Colors.white.withOpacity(0.3), 
            width: 1,
          ),
        ),
        child: Icon(
          icon, 
          color: isActive ? AppColors.warmBrown : Colors.white, 
          size: 24,
        ),
      ),
    );
    
    if (tooltip != null) {
      return Tooltip(
        message: tooltip,
        child: button,
      );
    }
    return button;
  }

  Widget _buildContentSection(ContentItem item, bool isDesktop, bool isTablet) {
    final horizontalPadding = isDesktop ? 80.0 : (isTablet ? 40.0 : 24.0);
    
    return Padding(
      padding: EdgeInsets.all(horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator Card
          if (_creatorInfo != null) ...[
            _buildCreatorCard(isDesktop),
            const SizedBox(height: AppSpacing.extraLarge),
          ],

          // Description
          if (item.description != null && item.description!.isNotEmpty) ...[
            _buildInfoCard(
              title: 'About This Movie',
              child: Text(
                item.description!,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
          ],

          // Director and Cast
          if (item.director != null || item.cast != null) ...[
            _buildInfoCard(
              title: 'Cast & Crew',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.director != null)
                    _buildInfoRow('Director', item.director!),
                  if (item.director != null && item.cast != null)
                    const SizedBox(height: AppSpacing.medium),
                  if (item.cast != null)
                    _buildInfoRow('Cast', item.cast!),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
          ],

          // Similar Content
          if (_similarItems.isNotEmpty) ...[
            Text(
              'You Might Also Like',
              style: AppTypography.heading3.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
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
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                ),
              ),
            ),
          ],
          
          const SizedBox(height: AppSpacing.extraLarge),
        ],
      ),
    );
  }

  Widget _buildCreatorCard(bool isDesktop) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: isMobile 
      ? Column( // Mobile Layout
          children: [
             Row(
               children: [
                 // Avatar
                 GestureDetector(
                   onTap: () => _navigateToCreatorProfile(),
                   child: Container(
                     width: 56,
                     height: 56,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       gradient: LinearGradient(
                         colors: [AppColors.warmBrown, AppColors.warmBrown.withOpacity(0.7)],
                       ),
                     ),
                     child: ClipOval(
                       child: _creatorInfo!['avatar'] != null
                           ? Image.network(
                               _apiService.getMediaUrl(_creatorInfo!['avatar']),
                               fit: BoxFit.cover,
                               errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white, size: 32),
                             )
                           : const Icon(Icons.person, color: Colors.white, size: 32),
                     ),
                   ),
                 ),
                 const SizedBox(width: AppSpacing.large),
                 
                 // Creator info
                 Expanded(
                   child: GestureDetector(
                     onTap: () => _navigateToCreatorProfile(),
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           'Created by',
                           style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
                         ),
                         const SizedBox(height: 4),
                         Row(
                           children: [
                             Flexible(
                               child: Text(
                                 _creatorInfo!['name'] ?? 'Creator',
                                 style: AppTypography.heading4.copyWith(
                                   fontWeight: FontWeight.bold,
                                   color: AppColors.textPrimary,
                                 ),
                                 overflow: TextOverflow.ellipsis,
                               ),
                             ),
                             const SizedBox(width: AppSpacing.small),
                             Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.warmBrown),
                           ],
                         ),
                         if (_creatorInfo!['bio'] != null && _creatorInfo!['bio'].toString().isNotEmpty) ...[
                           const SizedBox(height: 4),
                           Text(
                             _creatorInfo!['bio'],
                             style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
                             maxLines: 1,
                             overflow: TextOverflow.ellipsis,
                           ),
                         ],
                       ],
                     ),
                   ),
                 ),
               ],
             ),
             const SizedBox(height: AppSpacing.large),
             
             // Donate button (Full Width)
             SizedBox(
               width: double.infinity,
               child: StyledPillButton(
                 label: 'Donate',
                 icon: Icons.favorite,
                 onPressed: _handleDonate,
               ),
             ),
          ],
        )
      : Row( // Desktop/Tablet Layout
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _navigateToCreatorProfile(),
            child: Container(
              width: isDesktop ? 70 : 56,
              height: isDesktop ? 70 : 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.warmBrown, AppColors.warmBrown.withOpacity(0.7)],
                ),
              ),
              child: ClipOval(
                child: _creatorInfo!['avatar'] != null
                    ? Image.network(
                        _apiService.getMediaUrl(_creatorInfo!['avatar']),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.large),
          
          // Creator info
          Expanded(
            child: GestureDetector(
              onTap: () => _navigateToCreatorProfile(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Created by',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _creatorInfo!['name'] ?? 'Creator',
                          style: AppTypography.heading4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.warmBrown,
                      ),
                    ],
                  ),
                  if (_creatorInfo!['bio'] != null && _creatorInfo!['bio'].toString().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _creatorInfo!['bio'],
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
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
    );
  }

  void _navigateToCreatorProfile() async {
    if (_creatorInfo!['id'] != null) {
      final artistProvider = context.read<ArtistProvider>();
      final artist = await artistProvider.fetchArtistByUserId(_creatorInfo!['id']);
      
      if (artist != null && mounted) {
        context.go('/artist/${artist.id}');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Creator profile not found')),
        );
      }
    }
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.body.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
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

/// Dialog for selecting a playlist to add content to
class _PlaylistSelectionDialog extends StatefulWidget {
  final ContentItem item;
  final Function(int playlistId) onPlaylistSelected;
  
  const _PlaylistSelectionDialog({
    required this.item,
    required this.onPlaylistSelected,
  });
  
  @override
  State<_PlaylistSelectionDialog> createState() => _PlaylistSelectionDialogState();
}

class _PlaylistSelectionDialogState extends State<_PlaylistSelectionDialog> {
  bool _isCreatingNew = false;
  bool _isCreating = false;
  final _newPlaylistController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Fetch playlists when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlaylistProvider>().fetchPlaylists();
    });
  }
  
  @override
  void dispose() {
    _newPlaylistController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F0E8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.warmBrown.withOpacity(0.1),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.playlist_add, color: AppColors.warmBrown),
                  SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      'Add to List',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Playlist list
            Flexible(
              child: Consumer<PlaylistProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final playlists = provider.playlists;
                  
                  return ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                    children: [
                      // Create new playlist option
                      if (_isCreatingNew)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: AppSpacing.small,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _newPlaylistController,
                                  autofocus: true,
                                  decoration: InputDecoration(
                                    hintText: 'New playlist name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.medium,
                                      vertical: AppSpacing.small,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSpacing.small),
                              _isCreating
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      icon: Icon(Icons.check, color: AppColors.successMain),
                                      onPressed: () async {
                                        final name = _newPlaylistController.text.trim();
                                        if (name.isNotEmpty && !_isCreating) {
                                          setState(() {
                                            _isCreating = true;
                                          });
                                          
                                          try {
                                            final playlist = await provider.createPlaylist(name);
                                            
                                            if (mounted) {
                                              if (playlist != null) {
                                                // Refresh playlists list
                                                await provider.fetchPlaylists();
                                                // Add item to the newly created playlist
                                                widget.onPlaylistSelected(playlist.id);
                                              } else {
                                                setState(() {
                                                  _isCreating = false;
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: const Text('Failed to create playlist'),
                                                    backgroundColor: AppColors.errorMain,
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              setState(() {
                                                _isCreating = false;
                                              });
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: ${e.toString()}'),
                                                  backgroundColor: AppColors.errorMain,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                              IconButton(
                                icon: Icon(Icons.close, color: AppColors.textSecondary),
                                onPressed: () {
                                  setState(() {
                                    _isCreatingNew = false;
                                    _newPlaylistController.clear();
                                  });
                                },
                              ),
                            ],
                          ),
                        )
                      else
                        ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.add, color: AppColors.warmBrown),
                          ),
                          title: Text(
                            'Create New Playlist',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onTap: () {
                            setState(() => _isCreatingNew = true);
                          },
                        ),
                      
                      Divider(color: AppColors.warmBrown.withOpacity(0.1)),
                      
                      // Existing playlists
                      if (playlists.isEmpty)
                        Padding(
                          padding: EdgeInsets.all(AppSpacing.extraLarge),
                          child: Center(
                            child: Text(
                              'No playlists yet',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                      else
                        ...playlists.map((playlist) => ListTile(
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: playlist.thumbnailUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      playlist.thumbnailUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Icon(
                                        Icons.playlist_play,
                                        color: AppColors.warmBrown,
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.playlist_play,
                                    color: AppColors.warmBrown,
                                  ),
                          ),
                          title: Text(
                            playlist.name,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          subtitle: Text(
                            '${playlist.itemCount} items',
                            style: AppTypography.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          onTap: () => widget.onPlaylistSelected(playlist.id),
                        )),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
