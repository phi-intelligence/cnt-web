import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class MusicScreen extends StatelessWidget {
  const MusicScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      appBar: AppBar(
        title: Text(
          'Music',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          children: [
            // View Toggle
            Row(
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
            const SizedBox(height: AppSpacing.medium),
            
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Search music...',
                hintStyle: AppTypography.body.copyWith(color: AppColors.textPlaceholder),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.warmBrown),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Genre Filter
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: 'All', isSelected: true),
                  _FilterChip(label: 'Contemporary'),
                  _FilterChip(label: 'Gospel'),
                  _FilterChip(label: 'Worship'),
                  _FilterChip(label: 'Hymns'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Music Grid
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: AppSpacing.medium,
                  mainAxisSpacing: AppSpacing.medium,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  return _MusicCard(
                    title: 'Track ${index + 1}',
                    artist: 'Artist Name',
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _FilterChip({
    required this.label,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.small),
      child: FilterChip(
        label: Text(
          label,
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

class _MusicCard extends StatelessWidget {
  final String title;
  final String artist;

  const _MusicCard({
    required this.title,
    required this.artist,
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
          // Cover Image
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: AppColors.backgroundSecondary,
              ),
              child: Icon(Icons.music_note_rounded, size: 50, color: AppColors.warmBrown.withOpacity(0.5)),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    artist,
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
