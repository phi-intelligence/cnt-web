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
import '../../services/logger_service.dart';
import '../../models/content_item.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/search_provider.dart';
import 'video_podcast_detail_screen_web.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';

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
  final ScrollController _scrollController = ScrollController();
  
  List<ContentItem> _podcasts = [];
  List<ContentItem> _filteredPodcasts = [];
  bool _isLoading = false;
  String _selectedType = 'All';
  final List<String> _podcastTypes = ['All', 'Audio Podcast', 'Video Podcast'];
  double _scrollOffset = 0.0;
  
  // Carousel State
  int _currentHeroIndex = 0;
  late PageController _heroPageController;
  Timer? _heroTimer;
  Timer? _searchDebounceTimer;

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _fetchPodcasts();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    setState(() {
      _scrollOffset = _scrollController.offset;
    });
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
    _searchDebounceTimer?.cancel();
    setState(() {});
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch();
  }
    });
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    final searchProvider = context.read<SearchProvider>();
    
    if (query.isEmpty) {
      // If empty, fetch all podcasts again
      await _fetchPodcasts();
      return;
    }
    
    // Use backend search API - always search podcasts type
    await searchProvider.search(query, type: 'podcasts');
    
    // Apply client-side filtering for Audio/Video Podcast type
    final results = searchProvider.results;
    setState(() {
      if (_selectedType != 'All') {
        _filteredPodcasts = results.where((podcast) {
          if (_selectedType == 'Audio Podcast') {
            return podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty &&
                   (podcast.videoUrl == null || podcast.videoUrl!.isEmpty);
          } else if (_selectedType == 'Video Podcast') {
            return podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty;
          }
          return true;
      }).toList();
      } else {
        _filteredPodcasts = results;
      }
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
      LoggerService.e('Error fetching podcasts: $e');
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
  
  // Calculate carousel opacity based on scroll position - Parallax effect
  double _calculateCarouselOpacity() {
    const fadeStart = 100.0;
    const fadeEnd = 500.0;
    
    if (_scrollOffset < fadeStart) return 1.0;
    if (_scrollOffset > fadeEnd) return 0.0;
    
    final fadeProgress = (_scrollOffset - fadeStart) / (fadeEnd - fadeStart);
    return (1.0 - fadeProgress).clamp(0.0, 1.0);
  }
  
  // Calculate parallax offset for carousel
  double _calculateParallaxOffset() {
    return _scrollOffset * 0.5;
  }

  // Responsive aspect ratio for cards
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return 0.95; 
    } else if (screenWidth < 768) {
      return 0.9;
    } else if (screenWidth < 1024) {
      return 0.85;
    }
    return 0.82;
  }

  void _handlePlay(ContentItem item) {
    if (item.videoUrl != null && item.videoUrl!.isNotEmpty) {
      // Navigate to video podcast detail page
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPodcastDetailScreenWeb(
            item: item,
          ),
        ),
      );
    } else if (item.audioUrl != null && item.audioUrl!.isNotEmpty) {
      // For audio podcasts, play directly
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isDesktop = screenWidth >= 1024;
    
    // Top 5 podcasts for carousel
    final carouselPodcasts = _podcasts.take(5).toList();
    
    // Responsive carousel height
    final carouselHeight = isDesktop ? 500.0 : (ResponsiveUtils.isSmallMobile(context) ? 300.0 : 400.0);
    final whiteCardTopMargin = carouselHeight * 0.75; // Increased overlap for premium feel

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Stack(
        children: [
          // Background Layer: Carousel with fade and parallax
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: Transform.translate(
              offset: Offset(0, _calculateParallaxOffset()),
              child: AnimatedOpacity(
                opacity: _calculateCarouselOpacity(),
                duration: const Duration(milliseconds: 100),
                child: IgnorePointer(
                  ignoring: _calculateCarouselOpacity() < 0.1,
                  child: carouselPodcasts.isNotEmpty && !_isLoading
                      ? _buildHeroCarousel(carouselPodcasts, carouselHeight)
                      : _buildPlaceholderHero(carouselHeight),
                ),
              ),
            ),
          ),
          
          // Foreground Layer: Scrollable content in white card
          SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Spacer to push white card down
                IgnorePointer(
                  ignoring: true,
                  child: SizedBox(height: whiteCardTopMargin),
                ),
                
                // White Floating Card containing all content
                Container(
                  width: double.infinity,
                  constraints: BoxConstraints(
                    minHeight: screenHeight - whiteCardTopMargin,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundPrimary,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, -5),
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: ResponsiveGridDelegate.getResponsivePadding(context).copyWith(top: AppSpacing.large),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filters & Search Section - Responsive Layout
                        SectionContainer(
                          padding: EdgeInsets.zero,
                          child: screenWidth < 768
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Search field (full width on small screens) - FIRST
                                    StyledSearchField(
                                      controller: _searchController,
                                      hintText: 'Search podcasts...',
                                    ),
                                    const SizedBox(height: AppSpacing.medium),
                                    // Filter chips (full width on small screens) - SECOND
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
                                                // If there's a search query, re-run search with new filter
                                                // Otherwise, just filter the existing podcasts
                                                if (_searchController.text.trim().isNotEmpty) {
                                                  _performSearch();
                                                } else {
                                                  // Client-side filter only
                                                  setState(() {
                                                    _filteredPodcasts = _podcasts.where((podcast) {
                                                      if (_selectedType == 'Audio Podcast') {
                                                        return podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty &&
                                                               (podcast.videoUrl == null || podcast.videoUrl!.isEmpty);
                                                      } else if (_selectedType == 'Video Podcast') {
                                                        return podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty;
                                                      }
                                                      return true;
                                                    }).toList();
                                                  });
                                                }
                                              },
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Filter chips (left side)
                                    Expanded(
                                      child: SingleChildScrollView(
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
                                                  // If there's a search query, re-run search with new filter
                                                  // Otherwise, just filter the existing podcasts
                                                  if (_searchController.text.trim().isNotEmpty) {
                                                    _performSearch();
                                                  } else {
                                                    // Client-side filter only
                                                    setState(() {
                                                      _filteredPodcasts = _podcasts.where((podcast) {
                                                        if (_selectedType == 'Audio Podcast') {
                                                          return podcast.audioUrl != null && podcast.audioUrl!.isNotEmpty &&
                                                                 (podcast.videoUrl == null || podcast.videoUrl!.isEmpty);
                                                        } else if (_selectedType == 'Video Podcast') {
                                                          return podcast.videoUrl != null && podcast.videoUrl!.isNotEmpty;
                                                        }
                                                        return true;
                                                      }).toList();
                                                    });
                                                  }
                                                },
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    // Search field (right side)
                                    const SizedBox(width: AppSpacing.medium),
                                    SizedBox(
                                      width: isDesktop ? 300 : 200,
                                      child: StyledSearchField(
                                        controller: _searchController,
                                        hintText: 'Search podcasts...',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                        
                        const SizedBox(height: AppSpacing.extraLarge),

                        // Podcasts Grid
                        if (_isLoading)
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 4,
                              tablet: 3,
                              mobile: 2,
                              childAspectRatio: _getChildAspectRatio(context),
                              crossAxisSpacing: AppSpacing.medium,
                              mainAxisSpacing: AppSpacing.medium,
                            ),
                            itemCount: 8,
                            itemBuilder: (context, index) => const LoadingShimmer(width: double.infinity, height: 250),
                          )
                        else if (_filteredPodcasts.isEmpty)
                          const EmptyState(
                            icon: Icons.podcasts,
                            title: 'No Podcasts Found',
                            message: 'Try adjusting your search or filters',
                          )
                        else
                          GridView.builder(
                            padding: EdgeInsets.zero,
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 4,
                              tablet: 3,
                              mobile: 2,
                              childAspectRatio: _getChildAspectRatio(context),
                              crossAxisSpacing: AppSpacing.medium,
                              mainAxisSpacing: AppSpacing.medium,
                            ),
                            itemCount: _filteredPodcasts.length,
                            itemBuilder: (context, index) {
                              final podcast = _filteredPodcasts[index];
                              return ContentCardWeb(
                                item: podcast,
                                onTap: () => _handleItemTap(podcast),
                                onPlay: () => _handlePlay(podcast),
                              );
                            },
                          ),
                          
                        const SizedBox(height: AppSpacing.extraLarge * 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderHero(double height) {
    return Container(
      height: height,
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
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(List<ContentItem> podcasts, double height) {
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
          
          // Gradient Overlay (Bottom) for indicators - Stronger gradient for parallax transition
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 150,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.4),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),

          // Page Indicators
          Positioned(
            bottom: height * 0.3, // Move indicators up so they don't get covered by the white sheet immediately
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
                Colors.black.withOpacity(0.8), // Darker bottom for text readiness
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: height * 0.35, // Positioned higher up to clear the floating sheet
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
                     fontSize: isDesktop ? 56 : (ResponsiveUtils.isSmallMobile(context) ? 24 : 32),
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
              ],
            ),
          ),
        ),
      ],
    );
  }
}

