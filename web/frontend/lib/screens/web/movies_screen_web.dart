import 'package:flutter/material.dart';
import 'dart:async';
import 'package:video_player/video_player.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../services/api_service.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/web/styled_page_header.dart';
import 'movie_detail_screen_web.dart';

/// Web Movies Screen - Full implementation
class MoviesScreenWeb extends StatefulWidget {
  const MoviesScreenWeb({super.key});

  @override
  State<MoviesScreenWeb> createState() => _MoviesScreenWebState();
}

class _MoviesScreenWebState extends State<MoviesScreenWeb> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  List<ContentItem> _movies = [];
  List<ContentItem> _filteredMovies = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Movies', 'Animated Bible Stories'];
  
  // Carousel State
  int _currentHeroIndex = 0;
  late PageController _heroPageController;
  Timer? _heroTimer;
  
  // Video Preview Controllers for Carousel
  Map<int, VideoPlayerController?> _previewControllers = {};
  Map<int, Timer?> _previewTimers = {};

  @override
  void initState() {
    super.initState();
    _heroPageController = PageController();
    _searchController.addListener(_onSearchChanged);
    _fetchMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroTimer?.cancel();
    _heroPageController.dispose();
    // Dispose all video controllers
    for (var controller in _previewControllers.values) {
      controller?.dispose();
    }
    for (var timer in _previewTimers.values) {
      timer?.cancel();
    }
    _previewControllers.clear();
    _previewTimers.clear();
    super.dispose();
  }

  void _startHeroTimer() {
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_movies.isEmpty) return;
      
      final nextIndex = (_currentHeroIndex + 1) % (_movies.length > 5 ? 5 : _movies.length);
      
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
    _filterMovies();
  }

  void _filterMovies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredMovies = _movies.where((movie) {
        final matchesSearch = query.isEmpty || 
            movie.title.toLowerCase().contains(query) ||
            (movie.description?.toLowerCase().contains(query) ?? false) ||
            (movie.director?.toLowerCase().contains(query) ?? false);
        
        return matchesSearch;
      }).toList();
    });
  }

  Future<void> _fetchMovies() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      List<ContentItem> moviesData = [];
      
      if (_selectedCategory == 'All') {
        // Fetch both regular movies and animated bible stories
        final regularMovies = await _api.getMovies(limit: 100);
        final animatedStories = await _api.getAnimatedBibleStories(limit: 100);
        
        moviesData = [
          ...regularMovies.map((movie) => _api.movieToContentItem(movie)),
          ...animatedStories.map((movie) => _api.movieToContentItem(movie)),
        ];
      } else if (_selectedCategory == 'Movies') {
        // Only regular movies (backend excludes animated bible stories)
        final regularMovies = await _api.getMovies(limit: 100);
        moviesData = regularMovies.map((movie) => _api.movieToContentItem(movie)).toList();
      } else if (_selectedCategory == 'Animated Bible Stories') {
        // Only animated bible stories
        final animatedStories = await _api.getAnimatedBibleStories(limit: 100);
        moviesData = animatedStories.map((movie) => _api.movieToContentItem(movie)).toList();
      }
      
      _movies = moviesData;
      _filteredMovies = List.from(_movies);
      
      // Initialize video previews for carousel movies
      if (_movies.isNotEmpty) {
        _initializeCarouselPreviews(_movies.take(5).toList());
        _startHeroTimer();
      }
    } catch (e) {
      print('Error fetching movies: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _fetchMovies();
  }

  Future<void> _initializeCarouselPreviews(List<ContentItem> movies) async {
    // Dispose existing controllers
    for (var controller in _previewControllers.values) {
      controller?.dispose();
    }
    for (var timer in _previewTimers.values) {
      timer?.cancel();
    }
    _previewControllers.clear();
    _previewTimers.clear();

    // Initialize previews for each movie
    for (var movie in movies) {
      if (movie.videoUrl != null && movie.videoUrl!.isNotEmpty) {
        try {
          final controller = VideoPlayerController.networkUrl(
            Uri.parse(_api.getMediaUrl(movie.videoUrl!)),
          );
          
          await controller.initialize();
          await controller.setVolume(0.0);
          await controller.setLooping(true);
          
          // If preview times exist, seek to start time
          if (movie.previewStartTime != null) {
            await controller.seekTo(Duration(seconds: movie.previewStartTime!));
          } else {
            await controller.seekTo(Duration.zero);
          }
          
          await controller.play();
          
          // Set up loop timer if preview end time exists
          if (movie.previewStartTime != null && movie.previewEndTime != null) {
            final previewDuration = movie.previewEndTime! - movie.previewStartTime!;
            _previewTimers[movie.id.hashCode] = Timer.periodic(
              Duration(seconds: previewDuration),
              (timer) {
                if (_previewControllers[movie.id.hashCode] != null &&
                    _previewControllers[movie.id.hashCode]!.value.isInitialized) {
                  _previewControllers[movie.id.hashCode]!.seekTo(
                    Duration(seconds: movie.previewStartTime!),
                  );
                }
              },
            );
          } else {
            // Default 60 second loop
            _previewTimers[movie.id.hashCode] = Timer.periodic(
              const Duration(seconds: 60),
              (timer) {
                if (_previewControllers[movie.id.hashCode] != null &&
                    _previewControllers[movie.id.hashCode]!.value.isInitialized) {
                  _previewControllers[movie.id.hashCode]!.seekTo(Duration.zero);
                }
              },
            );
          }
          
          _previewControllers[movie.id.hashCode] = controller;
        } catch (e) {
          print('Error initializing preview for movie ${movie.id}: $e');
        }
      }
    }
    
    // Play first video, pause others
    if (movies.isNotEmpty && _previewControllers.isNotEmpty) {
      for (int i = 0; i < movies.length; i++) {
        final controller = _previewControllers[movies[i].id.hashCode];
        if (controller != null && controller.value.isInitialized) {
          if (i == 0) {
            controller.play();
          } else {
            controller.pause();
          }
        }
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  void _handleMovieTap(ContentItem item) {
    // Navigate to movie detail screen (web version)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MovieDetailScreenWeb(
          item: item,
          movieId: int.tryParse(item.id),
        ),
      ),
    );
  }

  // Responsive aspect ratio for movie cards
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 480) {
      return 0.8; // Mobile: More compact cards
    } else if (screenWidth < 768) {
      return 0.75; // Tablet: Slightly less compact
    } else if (screenWidth < 1024) {
      return 0.7; // Desktop: Balanced
    }
    return 0.65; // Large desktop: More spacious
  }

  @override
  Widget build(BuildContext context) {
    // Top 5 movies for carousel
    final carouselMovies = _movies.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero Carousel Section
          if (carouselMovies.isNotEmpty && !_isLoading)
            SliverToBoxAdapter(
              child: _buildHeroCarousel(carouselMovies),
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
                             Icon(Icons.movie, size: 64, color: Colors.white.withOpacity(0.5)),
                             SizedBox(height: AppSpacing.medium),
                             Text('Explore Movies', style: AppTypography.heading1.copyWith(color: Colors.white)),
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
                          hintText: 'Search movies...',
                          onChanged: (_) => _filterMovies(),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        // Category Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((category) {
                              final isSelected = category == _selectedCategory;
                              return Padding(
                                padding: EdgeInsets.only(right: AppSpacing.small),
                                child: StyledFilterChip(
                                  label: category,
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    _onCategoryChanged(category);
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

          // Movies Grid
          SliverPadding(
            padding: ResponsiveGridDelegate.getResponsivePadding(context),
            sliver: _isLoading
                ? SliverGrid(
                    gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                      context,
                      desktop: 5,
                      tablet: 3,
                      mobile: 2,
                      childAspectRatio: _getChildAspectRatio(context),
                      crossAxisSpacing: AppSpacing.medium,
                      mainAxisSpacing: AppSpacing.medium,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => const LoadingShimmer(width: double.infinity, height: 250),
                      childCount: 10,
                    ),
                  )
                : _filteredMovies.isEmpty
                    ? SliverToBoxAdapter(
                        child: const EmptyState(
                          icon: Icons.movie,
                          title: 'No Movies Found',
                          message: 'Try adjusting your search',
                        ),
                      )
                    : SliverGrid(
                        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                          context,
                          desktop: 5,
                          tablet: 3,
                          mobile: 2,
                          childAspectRatio: _getChildAspectRatio(context),
                          crossAxisSpacing: AppSpacing.medium,
                          mainAxisSpacing: AppSpacing.medium,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final movie = _filteredMovies[index];
                            return ContentCardWeb(
                              item: movie,
                              onTap: () => _handleMovieTap(movie),
                              onPlay: () => _handleMovieTap(movie),
                            );
                          },
                          childCount: _filteredMovies.length,
                        ),
                      ),
          ),
          
          SliverToBoxAdapter(child: SizedBox(height: AppSpacing.extraLarge * 2)),
        ],
      ),
    );
  }

  Widget _buildHeroCarousel(List<ContentItem> movies) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final height = isDesktop ? 600.0 : 450.0;

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Carousel Pages
          PageView.builder(
            controller: _heroPageController,
            itemCount: movies.length,
            onPageChanged: (index) {
              setState(() {
                _currentHeroIndex = index;
              });
              // Pause previous video and play current
              for (int i = 0; i < movies.length; i++) {
                final controller = _previewControllers[movies[i].id.hashCode];
                if (controller != null && controller.value.isInitialized) {
                  if (i == index) {
                    controller.play();
                  } else {
                    controller.pause();
                  }
                }
              }
            },
            itemBuilder: (context, index) {
              final item = movies[index];
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
              children: List.generate(movies.length, (index) {
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
    
    // Check if we have a video preview controller for this movie
    final previewController = _previewControllers[item.id.hashCode];
    final hasVideoPreview = previewController != null && 
                           previewController.value.isInitialized;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Video Preview or Image
        if (hasVideoPreview)
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: previewController!.value.size.width,
                height: previewController.value.size.height,
                child: VideoPlayer(previewController),
              ),
            ),
          )
        else if (item.coverImage != null)
           Image.network(
             _api.getMediaUrl(item.coverImage!),
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
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.4),
                AppColors.backgroundPrimary.withOpacity(0.6), // Smoother blend to body
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),

        // Content
        Positioned(
          bottom: AppSpacing.extraLarge * 2, // Moved up to make space for dots
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
                     'FEATURED',
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
                     fontSize: isDesktop ? 64 : 36, // Larger title
                     fontWeight: FontWeight.bold,
                     height: 1.1,
                     shadows: [
                       BoxShadow(
                         color: Colors.black.withOpacity(0.5),
                         blurRadius: 10,
                         offset: const Offset(0, 4),
                       ),
                     ],
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
                         color: Colors.white.withOpacity(0.95),
                         fontSize: isDesktop ? 20 : 16,
                         height: 1.5,
                         shadows: [
                           BoxShadow(
                             color: Colors.black.withOpacity(0.5),
                             blurRadius: 4,
                             offset: const Offset(0, 2),
                           ),
                         ],
                       ),
                       maxLines: isDesktop ? 3 : 2,
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                 ],
                 const SizedBox(height: AppSpacing.large),
                 StyledPillButton(
                   label: 'Watch Now',
                   icon: Icons.play_arrow,
                   onPressed: () => _handleMovieTap(item),
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

