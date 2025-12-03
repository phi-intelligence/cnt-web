import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../services/api_service.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../movie_detail_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchMovies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            StyledPageHeader(
              title: 'Movies',
              size: StyledPageHeaderSize.h1,
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Search and Filter Section
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
            
            // Movies Grid
            Expanded(
              child: _isLoading
                  ? GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                        context,
                        desktop: 5,
                        tablet: 3,
                        mobile: 2,
                        childAspectRatio: _getChildAspectRatio(context),
                        crossAxisSpacing: AppSpacing.medium,
                        mainAxisSpacing: AppSpacing.medium,
                      ),
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const LoadingShimmer(width: double.infinity, height: 250);
                      },
                    )
                  : _filteredMovies.isEmpty
                      ? const EmptyState(
                          icon: Icons.movie,
                          title: 'No Movies Found',
                          message: 'Try adjusting your search',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                            context,
                            desktop: 5,
                            tablet: 3,
                            mobile: 2,
                            childAspectRatio: _getChildAspectRatio(context),
                            crossAxisSpacing: AppSpacing.medium,
                            mainAxisSpacing: AppSpacing.medium,
                          ),
                          itemCount: _filteredMovies.length,
                          itemBuilder: (context, index) {
                            final movie = _filteredMovies[index];
                            return ContentCardWeb(
                              item: movie,
                              onTap: () => _handleMovieTap(movie),
                              onPlay: () => _handleMovieTap(movie),
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

