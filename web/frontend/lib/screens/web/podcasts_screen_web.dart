import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_search_field.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_filter_chip.dart';
import '../../widgets/web/section_container.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';
import '../../models/content_item.dart';
import '../../providers/audio_player_provider.dart';
import '../../widgets/video_player.dart';
import '../video/video_player_full_screen.dart';
import 'video_podcast_detail_screen_web.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _fetchPodcasts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header
                StyledPageHeader(
                  title: 'Podcasts',
                  size: StyledPageHeaderSize.h1,
            ),
                const SizedBox(height: AppSpacing.extraLarge),
                  
                // Search and Filter Section
                SectionContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Search Bar
                      StyledSearchField(
                    controller: _searchController,
                      hintText: 'Search podcasts...',
                        onChanged: (_) => _filterPodcasts(),
                  ),
                  
                  const SizedBox(height: AppSpacing.medium),
                  
                  // Podcast Type Chips (Audio/Video only)
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
                  
                  // Podcasts Grid
                  Expanded(
                    child: _isLoading
                        ? GridView.builder(
                            padding: EdgeInsets.zero,
                            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                              context,
                              desktop: 4,
                              tablet: 3,
                              mobile: 2,
                              childAspectRatio: _getChildAspectRatio(context), // Dynamic aspect ratio
                              crossAxisSpacing: AppSpacing.medium,
                              mainAxisSpacing: AppSpacing.medium,
                            ),
                            itemCount: 8,
                            itemBuilder: (context, index) {
                              return const LoadingShimmer(width: double.infinity, height: 250);
                            },
                          )
                        : _filteredPodcasts.isEmpty
                            ? const EmptyState(
                                icon: Icons.podcasts,
                                title: 'No Podcasts Found',
                                message: 'Try adjusting your search or filters',
                              )
                            : GridView.builder(
                                padding: EdgeInsets.zero,
                                gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                                  context,
                                  desktop: 4,
                                  tablet: 3,
                                  mobile: 2,
                                  childAspectRatio: _getChildAspectRatio(context), // Dynamic aspect ratio
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
                ),
              ],
        ),
      ),
    );
  }
}

