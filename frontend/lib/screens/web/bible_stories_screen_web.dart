import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../services/api_service.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Bible Stories Screen
class BibleStoriesScreenWeb extends StatefulWidget {
  const BibleStoriesScreenWeb({super.key});

  @override
  State<BibleStoriesScreenWeb> createState() => _BibleStoriesScreenWebState();
}

class _BibleStoriesScreenWebState extends State<BibleStoriesScreenWeb> {
  final ApiService _api = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<ContentItem> _bibleStories = [];
  List<ContentItem> _filteredStories = [];
  bool _isLoading = false;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Old Testament', 'New Testament', 'Parables', 'Miracles'];

  @override
  void initState() {
    super.initState();
    _fetchBibleStories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchBibleStories() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implement getBibleStories API method
      // For now, use podcasts as placeholder
      final podcasts = await _api.getPodcasts(limit: 20);
      setState(() {
        _bibleStories = podcasts.map((p) {
          final audioUrl = p.audioUrl != null && p.audioUrl!.isNotEmpty
              ? _api.getMediaUrl(p.audioUrl!)
              : null;
          return ContentItem(
            id: p.id.toString(),
            title: p.title,
            creator: 'Bible Story',
            description: p.description,
            coverImage: p.coverImage != null ? _api.getMediaUrl(p.coverImage!) : null,
            audioUrl: audioUrl,
            duration: p.duration != null ? Duration(seconds: p.duration!) : null,
            category: 'Bible Story',
            createdAt: p.createdAt,
          );
        }).toList();
        _filteredStories = _bibleStories;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching Bible stories: $e');
      setState(() {
        _isLoading = false;
        _bibleStories = [];
        _filteredStories = [];
      });
    }
  }

  void _filterStories() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStories = _bibleStories.where((story) {
        final matchesSearch = query.isEmpty || story.title.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'All' || story.category == _selectedCategory;
        return matchesSearch && matchesCategory;
      }).toList();
    });
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
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Header
            Text(
              'Bible Stories',
              style: AppTypography.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            
            // Search Bar
            TextField(
              controller: _searchController,
              onChanged: (_) => _filterStories(),
              decoration: InputDecoration(
                hintText: 'Search Bible stories...',
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
            const SizedBox(height: AppSpacing.medium),
            
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
                        _filterStories();
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
            const SizedBox(height: AppSpacing.large),
            
            // Stories Grid
            Expanded(
              child: _isLoading
                  ? GridView.builder(
                      padding: EdgeInsets.zero,
                      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                        context,
                        desktop: 4,
                        tablet: 3,
                        mobile: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: AppSpacing.medium,
                        mainAxisSpacing: AppSpacing.medium,
                      ),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        return const LoadingShimmer(width: double.infinity, height: 250);
                      },
                    )
                  : _filteredStories.isEmpty
                      ? const EmptyState(
                          icon: Icons.book,
                          title: 'No Bible Stories Found',
                          message: 'Try adjusting your search or filters',
                        )
                      : GridView.builder(
                          padding: EdgeInsets.zero,
                          gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                            context,
                            desktop: 4,
                            tablet: 3,
                            mobile: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppSpacing.medium,
                            mainAxisSpacing: AppSpacing.medium,
                          ),
                          itemCount: _filteredStories.length,
                          itemBuilder: (context, index) {
                            final story = _filteredStories[index];
                            return ContentCardWeb(
                              item: story,
                              onTap: () => _handleItemTap(story),
                              onPlay: () => _handlePlay(story),
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
