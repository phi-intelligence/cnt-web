import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../models/content_item.dart';
import '../../services/api_service.dart';
import '../../providers/artist_provider.dart';
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
import '../../services/logger_service.dart';

/// Web-specific Video Podcast Detail Screen with Netflix-style layout
class VideoPodcastDetailScreenWeb extends StatefulWidget {
  final ContentItem item;

  const VideoPodcastDetailScreenWeb({
    super.key,
    required this.item,
  });

  @override
  State<VideoPodcastDetailScreenWeb> createState() =>
      _VideoPodcastDetailScreenWebState();
}

class _VideoPodcastDetailScreenWebState
    extends State<VideoPodcastDetailScreenWeb> {
  final ApiService _apiService = ApiService();
  List<ContentItem> _similarPodcasts = [];
  bool _isLoadingSimilar = false;

  // Video preview
  VideoPlayerController? _previewController;
  bool _isPreviewLoading = false;
  bool _hasPreviewError = false;
  Timer? _previewLoopTimer;

  // User/Creator info
  Map<String, dynamic>? _creatorInfo;
  bool _isLoadingCreator = false;
  int? _creatorId;

  @override
  void initState() {
    super.initState();
    _extractCreatorId();
    _loadCreatorInfo();
    _loadSimilarPodcasts();
    _initializePreview();
  }

  @override
  void dispose() {
    _previewController?.dispose();
    _previewLoopTimer?.cancel();
    super.dispose();
  }

  void _extractCreatorId() {
    // Try to extract creator ID from the item
    // For podcasts, we may need to fetch the full podcast data
    // For now, we'll try to get it from the API if needed
    // The creator field might contain the creator name, not ID
    // We'll need to handle this differently - maybe fetch podcast by ID
  }

  Future<void> _loadCreatorInfo() async {
    if (_creatorId == null) {
      // Try to fetch podcast to get creator ID
      try {
        final podcasts = await _apiService.getPodcasts(limit: 1000);
        final podcast = podcasts.firstWhere(
          (p) => p.id.toString() == widget.item.id,
          orElse: () => podcasts.first,
        );

        if (podcast.creatorId != null) {
          setState(() {
            _creatorId = podcast.creatorId;
          });
          
          await _fetchCreatorProfile();
        }
      } catch (e) {
        LoggerService.e('Error fetching podcast for creator ID: $e');
      }
    } else {
      await _fetchCreatorProfile();
    }
  }

  Future<void> _fetchCreatorProfile() async {
    if (_creatorId == null) return;
    
    setState(() {
      _isLoadingCreator = true;
    });

    try {
      final creatorData = await _apiService.getPublicUserProfile(_creatorId!);
      if (mounted) {
        setState(() {
          _creatorInfo = creatorData;
          _isLoadingCreator = false;
        });
      }
    } catch (e) {
      LoggerService.e('Error loading creator info: $e');
      if (mounted) {
        setState(() {
          _isLoadingCreator = false;
        });
      }
    }
  }


  Future<void> _initializePreview() async {
    if (widget.item.videoUrl == null || widget.item.videoUrl!.isEmpty) {
      return;
    }

    try {
      setState(() {
        _isPreviewLoading = true;
        _hasPreviewError = false;
      });

      _previewController?.dispose();

      _previewController = VideoPlayerController.networkUrl(
        Uri.parse(widget.item.videoUrl!),
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
        if (_previewController != null &&
            _previewController!.value.isInitialized) {
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

  Future<void> _loadSimilarPodcasts() async {
    try {
      setState(() {
        _isLoadingSimilar = true;
      });

      // Fetch similar podcasts (same category)
      final podcasts = await _apiService.getPodcasts(
        limit: 20,
        status: 'approved',
      );

      // Filter by same category name and exclude current podcast
      // Get category name from current item
      final currentCategoryName = widget.item.category;
      final similar = podcasts
          .where((p) =>
              p.id.toString() != widget.item.id &&
              p.videoUrl != null &&
              p.videoUrl!.isNotEmpty)
          .take(10)
          .map((podcast) => _apiService.podcastToContentItem(podcast,
              categoryName: currentCategoryName))
          .toList();

      setState(() {
        _similarPodcasts = similar;
        _isLoadingSimilar = false;
      });
    } catch (e) {
      LoggerService.e('Error loading similar podcasts: $e');
      setState(() {
        _isLoadingSimilar = false;
      });
    }
  }

  void _handlePlay() {
    if (widget.item.videoUrl == null || widget.item.videoUrl!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Video not available')),
      );
      return;
    }

    // Get playlist of video podcasts
    final playlist = _similarPodcasts
        .where((p) => p.videoUrl != null && p.videoUrl!.isNotEmpty)
        .toList();

    // Add current item to playlist if not already there
    if (!playlist.any((p) => p.id == widget.item.id)) {
      playlist.insert(0, widget.item);
    }

    final initialIndex = playlist.indexWhere((p) => p.id == widget.item.id);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerFullScreen(
          videoId: widget.item.id,
          title: widget.item.title,
          author: widget.item.creator,
          duration: widget.item.duration?.inSeconds ?? 0,
          gradientColors: const [
            AppColors.backgroundPrimary,
            AppColors.backgroundSecondary
          ],
          videoUrl: widget.item.videoUrl!,
          playlist: playlist,
          initialIndex: initialIndex >= 0 ? initialIndex : 0,
          onBack: () => Navigator.of(context).pop(),
          onDonate: _handleDonate,
          onFavorite: _handleFavorite,
          onSeek: null,
        ),
      ),
    );
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
    final hasRecipientBankDetails =
        await checkRecipientBankDetails(recipientId);
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

  void _handleFavorite() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${widget.item.title} added to favorites')),
    );
  }

  void _handleShare() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
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
                  else if (item.coverImage != null &&
                      item.coverImage!.isNotEmpty)
                    Image.network(
                      _apiService.getMediaUrl(item.coverImage!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.black,
                          child: const Center(
                            child: Icon(Icons.video_library,
                                color: Colors.white70, size: 64),
                          ),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.black,
                      child: const Center(
                        child: Icon(Icons.video_library,
                            color: Colors.white70, size: 64),
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
                        isDesktop
                            ? AppSpacing.extraLarge * 2
                            : (isTablet
                                ? AppSpacing.extraLarge
                                : AppSpacing.large),
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
                          const SizedBox(height: AppSpacing.small),

                          // Creator name
                          Text(
                            'By ${item.creator}',
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isDesktop ? 18 : 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),

                          // Short description (truncated)
                          if (item.description != null &&
                              item.description!.isNotEmpty)
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
                                  borderRadius: BorderRadius.circular(30),
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
                              if (item.plays > 0)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.play_arrow,
                                      color: Colors.white70,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${item.plays} plays',
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                  ],
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
                                  item.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
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
                      icon: const Icon(Icons.arrow_back,
                          color: Colors.white, size: 32),
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
                isDesktop
                    ? AppSpacing.extraLarge * 2
                    : (isTablet ? AppSpacing.extraLarge : AppSpacing.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Creator/User Information Card
                  if (_creatorInfo != null) ...[
                    SectionContainer(
                      child: screenWidth < 768
                          ? Column(
                              // Mobile Layout
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Clickable Creator Info
                                InkWell(
                                  onTap: () async {
                                    if (_creatorInfo!['id'] != null) {
                                      // Fetch artist profile by user ID
                                      final artistProvider =
                                          context.read<ArtistProvider>();
                                      final artist = await artistProvider
                                          .fetchArtistByUserId(
                                              _creatorInfo!['id']);

                                      if (artist != null && mounted) {
                                        context.go('/artist/${artist.id}');
                                      } else if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Creator profile not found')),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMedium),
                                  child: Padding(
                                    padding: EdgeInsets.all(AppSpacing.medium),
                                    child: Row(
                                      children: [
                                        // Avatar
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundColor: AppColors.primaryMain
                                              .withOpacity(0.2),
                                          backgroundImage: _creatorInfo![
                                                      'avatar'] !=
                                                  null
                                              ? NetworkImage(
                                                  _apiService.getMediaUrl(
                                                      _creatorInfo!['avatar']))
                                              : null,
                                          child: _creatorInfo!['avatar'] == null
                                              ? Icon(Icons.person,
                                                  size: 30,
                                                  color: AppColors.primaryMain)
                                              : null,
                                        ),
                                        const SizedBox(width: AppSpacing.large),
                                        // Creator info
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Text(
                                                      _creatorInfo!['name'] ??
                                                          item.creator,
                                                      style: AppTypography
                                                          .heading3
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .primaryMain,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      width: AppSpacing.small),
                                                  Icon(
                                                    Icons.arrow_forward_ios,
                                                    size: 16,
                                                    color:
                                                        AppColors.primaryMain,
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'View Creator Profile',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                              if (_creatorInfo!['bio'] !=
                                                      null &&
                                                  _creatorInfo!['bio']
                                                      .toString()
                                                      .isNotEmpty) ...[
                                                const SizedBox(
                                                    height: AppSpacing.small),
                                                Text(
                                                  _creatorInfo!['bio'],
                                                  style: AppTypography.body
                                                      .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Donate button (Full width on mobile)
                                Padding(
                                  padding: EdgeInsets.all(AppSpacing.medium),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: StyledPillButton(
                                      label: 'Donate',
                                      icon: Icons.favorite,
                                      onPressed: _handleDonate,
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              // Desktop/Tablet Layout
                              children: [
                                // Clickable Creator Info
                                Expanded(
                                  child: InkWell(
                                    onTap: () async {
                                      if (_creatorInfo!['id'] != null) {
                                        // Fetch artist profile by user ID
                                        final artistProvider =
                                            context.read<ArtistProvider>();
                                        final artist = await artistProvider
                                            .fetchArtistByUserId(
                                                _creatorInfo!['id']);

                                        if (artist != null && mounted) {
                                          context.go('/artist/${artist.id}');
                                        } else if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text(
                                                    'Creator profile not found')),
                                          );
                                        }
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusMedium),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(AppSpacing.medium),
                                      child: Row(
                                        children: [
                                          // Avatar
                                          CircleAvatar(
                                            radius: isDesktop ? 40 : 30,
                                            backgroundColor: AppColors
                                                .primaryMain
                                                .withOpacity(0.2),
                                            backgroundImage:
                                                _creatorInfo!['avatar'] != null
                                                    ? NetworkImage(
                                                        _apiService.getMediaUrl(
                                                            _creatorInfo![
                                                                'avatar']))
                                                    : null,
                                            child: _creatorInfo!['avatar'] ==
                                                    null
                                                ? Icon(
                                                    Icons.person,
                                                    size: isDesktop ? 40 : 30,
                                                    color:
                                                        AppColors.primaryMain,
                                                  )
                                                : null,
                                          ),
                                          const SizedBox(
                                              width: AppSpacing.large),
                                          // Creator info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      _creatorInfo!['name'] ??
                                                          item.creator,
                                                      style: AppTypography
                                                          .heading3
                                                          .copyWith(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppColors
                                                            .primaryMain,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                        width:
                                                            AppSpacing.small),
                                                    Icon(
                                                      Icons.arrow_forward_ios,
                                                      size: 16,
                                                      color:
                                                          AppColors.primaryMain,
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'View Creator Profile',
                                                  style: AppTypography.caption
                                                      .copyWith(
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                ),
                                                if (_creatorInfo!['bio'] !=
                                                        null &&
                                                    _creatorInfo!['bio']
                                                        .toString()
                                                        .isNotEmpty) ...[
                                                  const SizedBox(
                                                      height: AppSpacing.small),
                                                  Text(
                                                    _creatorInfo!['bio'],
                                                    style: AppTypography.body
                                                        .copyWith(
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Donate button
                                Padding(
                                  padding: EdgeInsets.all(AppSpacing.medium),
                                  child: StyledPillButton(
                                    label: 'Donate',
                                    icon: Icons.favorite,
                                    onPressed: _handleDonate,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],

                  // Full Description
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
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

                  // Similar Content Section
                  if (_similarPodcasts.isNotEmpty) ...[
                    StyledPageHeader(
                      title: 'Similar Podcasts',
                      size: StyledPageHeaderSize.h2,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    ContentSection(
                      title: '',
                      items: _similarPodcasts,
                      isHorizontal: true,
                      onItemTap: (similarItem) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPodcastDetailScreenWeb(
                              item: similarItem,
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
