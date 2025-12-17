import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../widgets/web/section_container.dart';
import '../../services/api_service.dart';
import '../../models/content_item.dart';
import '../../providers/audio_player_provider.dart';
import 'video_podcast_detail_screen_web.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_pill_button.dart';

/// Web Podcasts Screen - Full implementation
class PodcastsScreenWeb extends StatefulWidget {
  final int? initialCategoryId;
  
  const PodcastsScreenWeb({super.key, this.initialCategoryId});

  @override
  State<PodcastsScreenWeb> createState() => _PodcastsScreenWebState();
}

class _PodcastsScreenWebState extends State<PodcastsScreenWeb> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<ContentItem> _podcasts = [];
  List<ContentItem> _filteredPodcasts = [];
  bool _isLoading = false;
  String _selectedType = 'All';
  final List<String> _podcastTypes = ['All', 'Audio Podcast', 'Video Podcast'];
  
  // Carousel State
  int _currentHeroIndex = 0;
  late PageController _heroPageController;
  Timer? _heroTimer;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _searchController.addListener(_onSearchChanged);
    _fetchPodcasts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }
  
  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_podcasts.isEmpty) return;
      
      final carouselPodcasts = _podcasts.take(5).toList();
      if (carouselPodcasts.isEmpty) return;
      
      final nextIndex = (_currentHeroIndex + 1) % carouselPodcasts.length;
      
      if (_heroPageController.hasClients) {
        _heroPageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onSearchChanged() {
    _filterPodcasts();
  }

  void _filterPodcasts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPodcasts = _podcasts.where((podcast) {
        final matchesSearch = query.isEmpty || 
            podcast.title.toLowerCase().contains(query) ||
            (podcast.description?.toLowerCase().contains(query) ?? false);
        
        // Filter by media type (audioUrl vs videoUrl) instead of category
        final matchesType = _selectedType == 'All' ||
            (_selectedType == 'Audio Podcast' && 
             podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty &&
             (podcast.videoUrl == null || podcast.videoUrl!.isEmpty)) ||
            (_selectedType == 'Video Podcast' && 
             podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty);
        
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  Future<void> _fetchPodcasts() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final podcastsData = await _api.getPodcasts();
      
      _podcasts = podcastsData.map((podcast) {
        final audioUrl = podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty
            ? _api.getMediaUrl(podcast.audioUrl!)
            : null;
        final videoUrl = podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty
            ? _api.getMediaUrl(podcast.videoUrl!)
            : null;
        
        return ContentItem(
          id: podcast.id.toString(),
          title: podcast.title,
          creator: 'Christ Tabernacle',
          description: podcast.description,
          coverImage: podcast.coverImage != null 
            ? _api.getMediaUrl(podcast.coverImage!) 
            : null,
          audioUrl: audioUrl,
          videoUrl: videoUrl,
          duration: podcast.duration != null 
            ? Duration(seconds: podcast.duration!)
            : null,
          category: _getCategoryName(podcast.categoryId),
          plays: podcast.playsCount,
          createdAt: podcast.createdAt,
        );
      }).where((p) => (p.audioUrl != null && p.audioUrl!.isNotEmpty) || 
                      (p.videoUrl != null && p.videoUrl!.isNotEmpty)).toList();
      
      _filteredPodcasts = List.from(_podcasts);
      
      // Start hero carousel timer if we have podcasts
      if (_podcasts.isNotEmpty) {
        _startHeroTimer();
      }
    } catch (e) {
      print('Error fetching podcasts: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCategoryName(int? categoryId) {
    switch (categoryId) {
      case 1: return 'Sermons';
      case 2: return 'Bible Study';
      case 3: return 'Devotionals';
      case 4: return 'Prayer';
      case 5: return 'Worship';
      case 6: return 'Gospel';
      default: return 'Podcast';
    }
  }

  // Responsive aspect ratio for cards
  // Higher values = shorter/wider cards, Lower values = taller cards
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return 0.95; // Mobile: Compact cards
    } else if (screenWidth < 768) {
      return 0.9; // Tablet: Balanced
    } else if (screenWidth < 1024) {
      return 0.85; // Desktop: Slightly wider
    }
    return 0.82; // Large desktop: Wider cards
  }

  void _handlePlay(ContentItem item) {
    // If video exists, navigate to detail page; otherwise play audio
    if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPodcastDetailScreenWeb(
            item: item,
          ),
        ),
      );
    } else if (item.audioUrl != null && item.audioUrl!.isNotEmpty) {
      context.read<AudioPlayerState>().playContent(item);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No media available for ${item.title}')),
      );
    }
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
  }

  @override
  Widget build(BuildContext context) {
    // Top 5 podcasts for carousel
    final carouselPodcasts = _podcasts.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero Carousel Section
          if (carouselPodcasts.isNotEmpty && !_isLoading)
            SliverToBoxAdapter(
              child: _buildHeroCarousel(carouselPodcasts),
            )
          else if (!_isLoading)
             SliverToBoxAdapter(
               child: Container(
                 height: 400,
                 color: Colors.black,
                 child: Stack(
                    fit: StackFit.expand,
                    children: [
                       Container(
                         decoration: BoxDecoration(
                           gradient: LinearGradient(
                             colors: [AppColors.warmBrown.withOpacity(0.3), Colors.black],
                             begin: Alignment.topCenter,
                             end: Alignment.bottomCenter
                           )
                         ),
                       ),
                       Center(
                         child: Column(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             Icon(Icons.mic, size: 64, color: Colors.white.withOpacity(0.5)),
                             SizedBox(height: AppSpacing.medium),
                             Text('Explore Podcasts', style: AppTypography.heading1.copyWith(color: Colors.white)),
                           ],
                         ),
                       )
                    ]
                 ),
               )
             ),

          // Search and Filter Section
          SliverToBoxAdapter(
            child: Padding(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.large),
                  SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StyledSearchField(
                          controller: _searchController,
                          hintText: 'Search podcasts...',
                          onChanged: (_) => _filterPodcasts(),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        // Type Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _podcastTypes.map((type) {
                              final isSelected = type == _selectedType;
                              return Padding(
                                padding: EdgeInsets.only(right: AppSpacing.small),
                                child: StyledFilterChip(
                                  label: type,
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedType = type;
                                    });
                                    _filterPodcasts();
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                ],
              ),
            ),
          ),

          // Podcasts Grid
          SliverPadding(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            sliver: _isLoading
                ? SliverGrid(
                    gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                      context,
                      desktop: 4,
                      tablet: 3,
                      mobile: 2,
                      childAspectRatio: _getChildAspectRatio(context),
                      crossAxisSpacing: AppSpacing.medium,
                      mainAxisSpacing: AppSpacing.medium,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const LoadingShimmer(width: double.infinity, height: 250),
                      childCount: 8,
                    ),
                  )
                : _filteredPodcasts.isEmpty
                    ? SliverToBoxAdapter(
                        child: const EmptyState(
                          icon: Icons.podcasts,
                          title: 'No Podcasts Found',
                          message: 'Try adjusting your search or filters',
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 4,
                          tablet: 3,
                          mobile: 2,
                          childAspectRatio: _getChildAspectRatio(context),
                          crossAxisSpacing: AppSpacing.medium,
                          mainAxisSpacing: AppSpacing.medium,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final podcast = _filteredPodcasts[index];
                            return ContentCardWeb(
                              item: podcast,
                              onTap: () => _handleItemTap(podcast),
                              onPlay: () => _handlePlay(podcast),
                            );
                          },
                          childCount: _filteredPodcasts.length,
                        ),
                      ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.extraLarge * 2)),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(List<ContentItem> podcasts) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final height = isDesktop ? 500.0 : 400.0;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Carousel Pages
          PageView.builder(
            controller: _heroPageController,
            itemCount: podcasts.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final item = podcasts[index];
              return _buildHeroItem(item, height);
            },
          ),
          
          // Gradient Overlay (Bottom) for indicators
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Page Indicators
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(podcasts.length, (index) {
                final isActive = index == _currentHeroIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.accentMain : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroItem(ContentItem item, double height) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Image
        if (item.coverImage != null)
           Image.network(
             item.coverImage!,
             fit: BoxFit.cover,
             errorBuilder: (_, __, ___) => Container(color: Colors.black),
           )
        else
           Container(color: Colors.black),

        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
                AppColors.backgroundPrimary,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: AppSpacing.extraLarge * 2,
          left: 0,
          right: 0,
          child: Padding(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(
                     color: AppColors.warmBrown,
                     borderRadius: BorderRadius.circular(20),
                   ),
                   child: Text(
                     'LATEST EPISODE',
                     style: AppTypography.caption.copyWith(
                       color: Colors.white,
                       fontWeight: FontWeight.bold,
                       letterSpacing: 1.2,
                     ),
                   ),
                 ),
                 const SizedBox(height: AppSpacing.medium),
                 Text(
                   item.title,
                   style: AppTypography.heading1.copyWith(
                     color: Colors.white,
                     fontSize: isDesktop ? 56 : 32,
                     fontWeight: FontWeight.bold,
                     height: 1.1,
                   ),
                   maxLines: 2,
                   overflow: TextOverflow.ellipsis,
                 ),
                 if (item.description != null) ...[
                   const SizedBox(height: AppSpacing.medium),
                   SizedBox(
                     width: isDesktop ? screenWidth * 0.5 : screenWidth,
                     child: Text(
                       item.description!,
                       style: AppTypography.body.copyWith(
                         color: Colors.white.withOpacity(0.9),
                         fontSize: isDesktop ? 18 : 16,
                         height: 1.5,
                       ),
                       maxLines: isDesktop ? 3 : 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                 ],
                 const SizedBox(height: AppSpacing.large),
                 StyledPillButton(
                   label: 'Play Now',
                   icon: Icons.play_arrow,
                   onPressed: () => _handlePlay(item),
                   width: 180,
                 ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

