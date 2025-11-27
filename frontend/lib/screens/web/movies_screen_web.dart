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
      final moviesData = await _api.getMovies(limit: 100);
      
      // Convert Movie models to ContentItem models
      _movies = moviesData.map((movie) {
        return _api.movieToContentItem(movie);
      }).toList();
      
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
            
            // Search Section
            SectionContainer(
              child: StyledSearchField(
              controller: _searchController,
                hintText: 'Search movies...',
                onChanged: (_) => _filterMovies(),
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
                        childAspectRatio: 0.75,
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
                            childAspectRatio: 0.75,
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

