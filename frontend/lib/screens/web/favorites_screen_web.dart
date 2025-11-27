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
import '../../widgets/web/section_container.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Favorites Screen
class FavoritesScreenWeb extends StatefulWidget {
  const FavoritesScreenWeb({super.key});

  @override
  State<FavoritesScreenWeb> createState() => _FavoritesScreenWebState();
}

class _FavoritesScreenWebState extends State<FavoritesScreenWeb> {
  final TextEditingController _searchController = TextEditingController();
  List<ContentItem> _filteredFavorites = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<FavoritesProvider>().fetchFavorites();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterFavorites(List<ContentItem> favorites) {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredFavorites = favorites.where((item) {
        return query.isEmpty ||
            item.title.toLowerCase().contains(query) ||
            item.creator.toLowerCase().contains(query);
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
            StyledPageHeader(
              title: 'My Favorites',
              size: StyledPageHeaderSize.h1,
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Search Section
            SectionContainer(
              child: StyledSearchField(
              controller: _searchController,
                hintText: 'Search favorites...',
              onChanged: (_) {
                final provider = context.read<FavoritesProvider>();
                _filterFavorites(provider.favorites);
              },
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Favorites Grid
            Expanded(
              child: Consumer<FavoritesProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
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
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return const LoadingShimmer(width: double.infinity, height: 250);
                      },
                    );
                  }

                  if (provider.favorites.isEmpty) {
                    return const EmptyState(
                      icon: Icons.favorite_border,
                      title: 'No Favorites',
                      message: 'Like content to see it here',
                    );
                  }

                  final favoritesToShow = _searchController.text.isEmpty
                      ? provider.favorites
                      : _filteredFavorites.isEmpty
                          ? provider.favorites
                          : _filteredFavorites;

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
                    itemCount: favoritesToShow.length,
                    itemBuilder: (context, index) {
                      final item = favoritesToShow[index];
                      return ContentCardWeb(
                        item: item,
                        onTap: () => _handleItemTap(item),
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
    );
  }
}
