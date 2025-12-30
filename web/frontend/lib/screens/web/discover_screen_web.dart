import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/content_section.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../services/api_service.dart';
import '../../services/logger_service.dart';
import '../../providers/music_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../models/api_models.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Discover Screen - Content discovery with categories and trending
class DiscoverScreenWeb extends StatefulWidget {
  const DiscoverScreenWeb({super.key});

  @override
  State<DiscoverScreenWeb> createState() => _DiscoverScreenWebState();
}

class _DiscoverScreenWebState extends State<DiscoverScreenWeb> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ContentItem> _trendingPodcasts = [];
  List<ContentItem> _trendingMusic = [];
  List<ContentItem> _featuredContent = [];
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Podcasts', 'Music', 'Bible Stories', 'Live'];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchDiscoverContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscoverContent() async {
    setState(() => _isLoading = true);
    try {
      final podcasts = await _api.getPodcasts(limit: 20);
      final musicProvider = context.read<MusicProvider>();
      await musicProvider.fetchTracks();
      
      setState(() {
        _trendingPodcasts = podcasts.take(10).map((p) => ContentItem.fromJson(p.toJson())).toList();
        _trendingMusic = musicProvider.tracks.take(10).toList();
        _featuredContent = [
          ..._trendingPodcasts.take(5),
          ..._trendingMusic.take(5),
        ];
        _isLoading = false;
      });
    } catch (e) {
      LoggerService.e('❌ Error fetching discover content: $e');
      setState(() => _isLoading = false);
    }
  }

  void _handlePlay(ContentItem item) {
    context.read<AudioPlayerState>().playContent(item);
  }

  void _handleItemTap(ContentItem item) {
    _handlePlay(item);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            Text(
              'Discover',
              style: AppTypography.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            
            // Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search content...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Category Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: EdgeInsets.only(right: AppSpacing.small),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = category);
                      },
                      selectedColor: AppColors.primaryMain,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Content
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
                  : _selectedCategory == 'All' || _selectedCategory == 'Podcasts'
                      ? _buildFeaturedContent()
                      : _selectedCategory == 'Music'
                          ? _buildTrendingMusic()
                          : const EmptyState(
                              icon: Icons.explore,
                              title: 'Coming Soon',
                              message: 'More content categories coming soon',
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedContent() {
    if (_featuredContent.isEmpty) {
      return const EmptyState(
        icon: Icons.explore,
        title: 'No Content Found',
        message: 'Start exploring to discover new content',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ContentSection(
            title: 'Trending Now',
            items: _featuredContent,
            isHorizontal: true,
            onItemPlay: _handlePlay,
            onItemTap: _handleItemTap,
          ),
          const SizedBox(height: AppSpacing.extraLarge),
          ContentSection(
            title: 'Trending Podcasts',
            items: _trendingPodcasts,
            isHorizontal: true,
            onItemPlay: _handlePlay,
            onItemTap: _handleItemTap,
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingMusic() {
    if (_trendingMusic.isEmpty) {
      return const EmptyState(
        icon: Icons.music_note,
        title: 'No Music Found',
        message: 'Check back later for trending music',
      );
    }

    return GridView.builder(
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
      itemCount: _trendingMusic.length,
      itemBuilder: (context, index) {
        final track = _trendingMusic[index];
        return ContentCardWeb(
          item: track,
          onTap: () => _handleItemTap(track),
          onPlay: () => _handlePlay(track),
        );
      },
    );
  }
}
