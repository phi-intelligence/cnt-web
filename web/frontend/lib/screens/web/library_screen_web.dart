import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/content_card_web.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/web/section_container.dart';
import '../../providers/playlist_provider.dart';
import '../../providers/favorites_provider.dart';
import '../../providers/audio_player_provider.dart';
import '../../services/download_service.dart';
import '../../models/content_item.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Library Screen - Full implementation
class LibraryScreenWeb extends StatefulWidget {
  const LibraryScreenWeb({super.key});

  @override
  State<LibraryScreenWeb> createState() => _LibraryScreenWebState();
}

class _LibraryScreenWebState extends State<LibraryScreenWeb> {
  int _selectedIndex = 0;
  final List<String> _sections = ['Downloaded', 'Playlists', 'Favorites'];
  final DownloadService _downloadService = DownloadService();
  List<Map<String, dynamic>> _downloads = [];
  bool _isLoadingDownloads = false;

  @override
  void initState() {
    super.initState();
    print('✅ LibraryScreenWeb initState');
    _loadDownloads();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context.read<PlaylistProvider>().fetchPlaylists();
        context.read<FavoritesProvider>().fetchFavorites();
      } catch (e) {
        print('❌ LibraryScreenWeb: Error fetching playlists/favorites: $e');
      }
    });
  }

  Future<void> _loadDownloads() async {
    try {
      if (mounted) {
        setState(() => _isLoadingDownloads = true);
      }
      final downloads = await _downloadService.getDownloads();
      if (mounted) {
        setState(() {
          _downloads = downloads;
          _isLoadingDownloads = false;
        });
      }
    } catch (e) {
      print('❌ LibraryScreenWeb: Error loading downloads: $e');
      if (mounted) {
        setState(() => _isLoadingDownloads = false);
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SizedBox.expand(
        child: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              StyledPageHeader(
                title: 'Library',
                size: StyledPageHeaderSize.h1,
                  ),
              const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Segmented Control
              SectionContainer(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.medium,
                  vertical: AppSpacing.small,
                ),
                child: Row(
                    children: List.generate(_sections.length, (index) {
                      final isSelected = index == _selectedIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                            decoration: BoxDecoration(
                            color: isSelected ? AppColors.warmBrown : Colors.transparent,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            ),
                            child: Text(
                              _sections[index],
                              textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium.copyWith(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
              ),
              const SizedBox(height: AppSpacing.extraLarge),
                  
              // Content
              Expanded(
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDownloadedSection();
      case 1:
        return _buildPlaylistsSection();
      case 2:
        return _buildFavoritesSection();
      default:
        return const SizedBox();
    }
  }

  Widget _buildDownloadedSection() {
    if (_isLoadingDownloads) {
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

    if (_downloads.isEmpty) {
      return const EmptyState(
        icon: Icons.download_outlined,
        title: 'No Downloads',
        message: 'Download content to listen offline',
      );
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        childAspectRatio: 0.75,
        crossAxisSpacing: AppSpacing.medium,
        mainAxisSpacing: AppSpacing.medium,
      ),
      itemCount: _downloads.length,
      itemBuilder: (context, index) {
        final download = _downloads[index];
        final item = ContentItem(
          id: download['id'],
          title: download['title'],
          creator: download['creator'] ?? 'Unknown',
          description: '',
          coverImage: download['cover_image'],
          audioUrl: download['local_path'],
          duration: download['duration'] != null
              ? Duration(seconds: download['duration'])
              : null,
          category: download['category'] ?? 'Downloaded',
          createdAt: download['created_at'] != null
              ? DateTime.parse(download['created_at'])
              : DateTime.now(),
        );

        return ContentCardWeb(
          item: item,
          onTap: () => _handlePlay(item),
          onPlay: () => _handlePlay(item),
        );
      },
    );
  }

  Widget _buildPlaylistsSection() {
    return Consumer<PlaylistProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              desktop: 5,
              tablet: 3,
              mobile: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: AppSpacing.medium,
              mainAxisSpacing: AppSpacing.medium,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return const LoadingShimmer(width: double.infinity, height: 200);
            },
          );
        }

        if (provider.playlists.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const EmptyState(
                icon: Icons.queue_music_outlined,
                title: 'No Playlists',
                message: 'Create your first playlist',
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.large),
                child: StyledPillButton(
                  label: 'Create Playlist',
                  icon: Icons.add,
                  onPressed: () => _showCreatePlaylistDialog(context),
                ),
              ),
            ],
          );
        }

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.9,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
          ),
          itemCount: provider.playlists.length,
          itemBuilder: (context, index) {
            final playlist = provider.playlists[index];
            return Card(
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryMain.withOpacity(0.2),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.queue_music,
                          size: 64,
                          color: AppColors.primaryMain,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      children: [
                        Text(
                          playlist.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${playlist.itemCount} items',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesSection() {
    return Consumer<FavoritesProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return GridView.builder(
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
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

        return GridView.builder(
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.75,
            crossAxisSpacing: AppSpacing.medium,
            mainAxisSpacing: AppSpacing.medium,
          ),
          itemCount: provider.favorites.length,
          itemBuilder: (context, index) {
            final item = provider.favorites[index];
            return ContentCardWeb(
              item: item,
              onTap: () => _handlePlay(item),
              onPlay: () => _handlePlay(item),
            );
          },
        );
      },
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        ),
        title: Text(
          'Create Playlist',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: nameController,
          style: AppTypography.body.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            labelText: 'Playlist Name',
            labelStyle: TextStyle(color: AppColors.textSecondary),
            hintText: 'Enter playlist name',
            hintStyle: TextStyle(color: AppColors.textPlaceholder),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: AppTypography.button.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isNotEmpty) {
                final success = await context.read<PlaylistProvider>().createPlaylist(
                  name: nameController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Playlist created!'
                            : 'Failed to create playlist',
                      ),
                      backgroundColor: success 
                          ? AppColors.successMain 
                          : AppColors.errorMain,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warmBrown,
              foregroundColor: AppColors.textInverse,
            ),
            child: Text(
              'Create',
              style: AppTypography.button.copyWith(
                color: AppColors.textInverse,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

