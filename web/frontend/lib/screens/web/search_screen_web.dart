import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../providers/search_provider.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../providers/audio_player_provider.dart';
import '../../providers/music_provider.dart';
import '../../models/content_item.dart';
import '../../services/api_service.dart';
import '../../widgets/shared/content_section.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../services/logger_service.dart';

/// Web Search Screen - Full implementation
class SearchScreenWeb extends StatefulWidget {
  const SearchScreenWeb({super.key});

  @override
  State<SearchScreenWeb> createState() => _SearchScreenWebState();
}

class _SearchScreenWebState extends State<SearchScreenWeb> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounceTimer;
  final ApiService _api = ApiService();
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Podcasts', 'Music', 'Videos', 'Posts', 'Users'];
  
  // Discover content state
  List<ContentItem> _trendingPodcasts = [];
  List<ContentItem> _trendingMusic = [];
  List<ContentItem> _featuredContent = [];
  bool _isLoadingDiscover = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchDiscoverContent();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounceTimer?.cancel();
    setState(() {});
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _performSearch(saveToRecent: false);
      }
    });
  }

  void _performSearch({bool saveToRecent = false}) {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      context.read<SearchProvider>().clearResults();
      return;
    }

    // Map filter names to backend type names
    String? type;
    if (_selectedFilter == 'All') {
      type = null;
    } else if (_selectedFilter == 'Videos') {
      type = 'movies'; // Backend uses 'movies' not 'videos'
    } else {
      type = _selectedFilter.toLowerCase();
    }
    context.read<SearchProvider>().search(query, type: type, saveToRecent: saveToRecent);
  }

  Future<void> _fetchDiscoverContent() async {
    if (_isLoadingDiscover) return;
    
    setState(() {
      _isLoadingDiscover = true;
    });

    try {
      final podcasts = await _api.getPodcasts(limit: 20);
      final musicProvider = context.read<MusicProvider>();
      await musicProvider.fetchTracks();
      
      // Convert Podcast models to ContentItem models (same approach as home screen)
      final allPodcastItems = podcasts.map((podcast) {
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
      }).toList();
      
      setState(() {
        _trendingPodcasts = allPodcastItems.take(10).toList();
        _trendingMusic = musicProvider.tracks.take(10).toList();
        _featuredContent = [
          ..._trendingPodcasts.take(5),
          ..._trendingMusic.take(5),
        ];
        _isLoadingDiscover = false;
        _isLoadingDiscover = false;
      });
    } catch (e) {
      LoggerService.e('❌ Error fetching discover content: $e');
      setState(() {
        _isLoadingDiscover = false;
      });
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

  void _handlePlay(ContentItem item) {
    if (item.audioUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No audio available for ${item.title}')),
      );
      return;
    }

    context.read<AudioPlayerState>().playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SafeArea(
        child: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search and Filter Section
                  SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Search Bar
                        StatefulBuilder(
                          builder: (context, setStateLocal) {
                            return StyledSearchField(
                      controller: _searchController,
                              hintText: 'Search podcasts, music, and more...',
                      autofocus: true,
                        suffixIcon: _searchController.text.isNotEmpty
                                  ? Icons.clear
                                  : null,
                              onSuffixTap: () {
                                  setState(() {
                                    _searchController.clear();
                                  });
                                setStateLocal(() {});
                              },
                      onChanged: (value) {
                        setState(() {});
                                setStateLocal(() {});
                              },
                      onSubmitted: (value) {
                        _searchDebounceTimer?.cancel();
                        _performSearch(saveToRecent: true);
                              },
                            );
                      },
                    ),

                    const SizedBox(height: AppSpacing.medium),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _filters.map((filter) {
                          final isSelected = filter == _selectedFilter;
                          return Padding(
                            padding: EdgeInsets.only(right: AppSpacing.small),
                                child: StyledFilterChip(
                                  label: filter,
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                                _searchDebounceTimer?.cancel();
                                _performSearch(saveToRecent: true);
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

                    // Search Results or Discover Content
                    Expanded(
                      child: _searchController.text.isEmpty
                          ? _buildDiscoverContent()
                          : Consumer<SearchProvider>(
                              builder: (context, provider, child) {
                                if (provider.isLoading) {
                                  return GridView.builder(
                                    padding: EdgeInsets.zero,
                                    gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                                      context,
                                      desktop: 5,
                                      tablet: 3,
                                      mobile: 2,
                                      childAspectRatio: 0.65, // Was 0.75
                                      crossAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
                                      mainAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
                                    ),
                                    itemCount: 10,
                                    itemBuilder: (context, index) {
                                      return const LoadingShimmer(width: double.infinity, height: 250);
                                    },
                                  );
                                }

                                if (provider.results.isEmpty) {
                                  return const EmptyState(
                                    icon: Icons.search_off,
                                    title: 'No Results Found',
                                    message: 'Try different keywords or filters',
                                  );
                                }

                                return GridView.builder(
                                  padding: EdgeInsets.zero,
                                  gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                                    context,
                                    desktop: 5,
                                    tablet: 3,
                                    mobile: 2,
                                    childAspectRatio: 0.65, // Was 0.75
                                    crossAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
                                    mainAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
                                  ),
                                  itemCount: provider.results.length,
                                  itemBuilder: (context, index) {
                                    final item = provider.results[index];
                                    return ContentCardWeb(
                                      item: item,
                                      onTap: () => _handlePlay(item),
                                      onPlay: () => _handlePlay(item),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ],
            ),
          ),
        ),
    );
  }

  Widget _buildDiscoverContent() {
    if (_isLoadingDiscover) {
      return GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
          context,
          desktop: 5,
          tablet: 3,
          mobile: 2,
          childAspectRatio: 0.65, // Was 0.75
          crossAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
          mainAxisSpacing: ResponsiveUtils.isSmallMobile(context) ? AppSpacing.small : AppSpacing.medium,
        ),
        itemCount: 10,
        itemBuilder: (context, index) {
          return const LoadingShimmer(width: double.infinity, height: 250);
        },
      );
    }

    if (_featuredContent.isEmpty && _trendingPodcasts.isEmpty && _trendingMusic.isEmpty) {
      return const EmptyState(
        icon: Icons.explore,
        title: 'No Content Found',
        message: 'Start exploring to discover new content',
      );
    }

    final List<Widget> sections = [];

    if (_featuredContent.isNotEmpty) {
      sections.addAll([
        ContentSection(
          title: 'Trending Now',
          items: _featuredContent,
          isHorizontal: true,
          onItemPlay: _handlePlay,
          onItemTap: _handleItemTap,
        ),
        const SizedBox(height: AppSpacing.extraLarge),
      ]);
    }

    if (_trendingPodcasts.isNotEmpty) {
      sections.addAll([
        ContentSection(
          title: 'Trending Podcasts',
          items: _trendingPodcasts,
          isHorizontal: true,
          onItemPlay: _handlePlay,
          onItemTap: _handleItemTap,
        ),
        const SizedBox(height: AppSpacing.extraLarge),
      ]);
    }

    if (_trendingMusic.isNotEmpty) {
      sections.add(
        ContentSection(
          title: 'Trending Music',
          items: _trendingMusic,
          isHorizontal: true,
          onItemPlay: _handlePlay,
          onItemTap: _handleItemTap,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: sections,
      ),
    );
  }

}

