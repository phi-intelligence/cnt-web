import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  // Responsive grid configuration
  int _getCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 1;  // Mobile
    if (screenWidth < 900) return 2;  // Tablet
    if (screenWidth < 1200) return 3; // Desktop
    return 4; // Large Desktop
  }

  // Responsive aspect ratio
  double _getChildAspectRatio(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 0.9;
    return 0.75;
  }

  // Responsive height for recently played section
  double _getRecentlyPlayedHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) return 140;
    return 160;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Your Library',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.warmBrown),
            onPressed: () {
              // TODO: Refresh library
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // View Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: Icon(Icons.grid_view_rounded, color: AppColors.warmBrown),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.list_rounded, color: AppColors.textSecondary),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            
            // Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(label: 'All', count: 42, isSelected: true),
                    _FilterChip(label: 'Playlists', count: 8),
                    _FilterChip(label: 'Artists', count: 15),
                    _FilterChip(label: 'Podcasts', count: 12),
                    _FilterChip(label: 'Music', count: 7),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.large),
            
            // Recently Played
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recently Played',
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'View All',
                      style: AppTypography.button.copyWith(
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(
              height: _getRecentlyPlayedHeight(context),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _RecentlyPlayedCard(
                    title: 'Item ${index + 1}',
                    artist: 'Artist Name',
                  );
                },
              ),
            ),
            
            const SizedBox(height: AppSpacing.large),
            
            // Library GridHeader
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Saved Content',
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Library Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.large),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _getCrossAxisCount(context),
                childAspectRatio: _getChildAspectRatio(context),
                crossAxisSpacing: AppSpacing.medium,
                mainAxisSpacing: AppSpacing.medium,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return _LibraryCard(
                  title: 'Item ${index + 1}',
                  subtitle: 'Description',
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    required this.count,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.small),
      child: FilterChip(
        label: Text(
          '$label ($count)',
          style: AppTypography.bodySmall.copyWith(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: (value) {},
        backgroundColor: Colors.white,
        selectedColor: AppColors.warmBrown,
        checkmarkColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          side: BorderSide(
            color: isSelected ? AppColors.warmBrown : AppColors.borderPrimary,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small, vertical: AppSpacing.tiny),
      ),
    );
  }
}

class _RecentlyPlayedCard extends StatelessWidget {
  final String title;
  final String artist;

  const _RecentlyPlayedCard({
    required this.title,
    required this.artist,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: AppColors.backgroundSecondary,
              ),
              child: Icon(Icons.music_note_rounded, size: 40, color: AppColors.warmBrown.withOpacity(0.5)),
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.small),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artist,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _LibraryCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: AppColors.backgroundSecondary,
              ),
              child: Icon(Icons.library_music_rounded, size: 50, color: AppColors.warmBrown.withOpacity(0.5)),
            ),
          ),
          
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
