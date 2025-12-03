import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/web/podcasts_screen_web.dart';

/// Featured Categories Widget for Web Homepage
/// Displays 5 category cards in a horizontal row
class FeaturedCategoriesWeb extends StatelessWidget {
  final Function(int? categoryId)? onCategoryTap;

  const FeaturedCategoriesWeb({
    super.key,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    final categories = [
      _CategoryItem(
        name: 'Sermons',
        categoryId: 1,
        icon: Icons.church,
        color: AppColors.primaryMain,
      ),
      _CategoryItem(
        name: 'Devotionals',
        categoryId: 3,
        icon: Icons.book,
        color: AppColors.accentMain,
      ),
      _CategoryItem(
        name: 'Apologetics',
        categoryId: 2, // Map to Bible Study
        icon: Icons.library_books,
        color: AppColors.accentDark,
      ),
      _CategoryItem(
        name: 'Worship',
        categoryId: 5,
        icon: Icons.music_note,
        color: AppColors.primaryLight,
      ),
      _CategoryItem(
        name: 'Kids & Family',
        categoryId: null, // Placeholder - can be mapped later
        icon: Icons.family_restroom,
        color: AppColors.warmBrown,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Text(
          'Featured Categories',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.large),
        
        // Category Cards Row
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index < categories.length - 1 ? AppSpacing.medium : 0,
                ),
                child: _CategoryCard(
                  category: category,
                  onTap: () {
                    if (onCategoryTap != null) {
                      onCategoryTap!(category.categoryId);
                    } else {
                      // Default: Navigate to podcasts screen with category filter
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PodcastsScreenWeb(
                            initialCategoryId: category.categoryId,
                          ),
                        ),
                      );
                    }
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryItem {
  final String name;
  final int? categoryId;
  final IconData icon;
  final Color color;

  _CategoryItem({
    required this.name,
    required this.categoryId,
    required this.icon,
    required this.color,
  });
}

class _CategoryCard extends StatelessWidget {
  final _CategoryItem category;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        child: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon Container
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  category.icon,
                  size: 40,
                  color: category.color,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              
              // Category Name
              Text(
                category.name,
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

