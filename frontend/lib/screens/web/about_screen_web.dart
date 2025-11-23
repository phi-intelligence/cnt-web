import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_page_header.dart';

/// Web About Screen
class AboutScreenWeb extends StatelessWidget {
  const AboutScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Logo/Icon (matching homepage style)
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                      child: Image.asset(
                        'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // Fallback to icon if image fails to load
                          return Icon(
                            Icons.church,
                            size: 60,
                            color: Colors.white,
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // App Name
                  Text(
                    'CNT Media Platform',
                    style: AppTypography.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  
                  // Tagline
                  Text(
                    'Christian Podcasts, Music, and Community',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Version (using SectionContainer for homepage theme)
                  SectionContainer(
                    child: Column(
                      children: [
                        Text(
                          'Version 1.0.0',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          '© 2024 Christ New Tabernacle',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Description (using SectionContainer for homepage theme)
                  SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          'CNT Media Platform is a comprehensive Christian media application offering podcasts, music, Bible stories, live streaming, and community features. Join our community of believers in Christ.',
                          style: AppTypography.body.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Features (using SectionContainer for homepage theme)
                  SectionContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Features',
                          style: AppTypography.heading3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        _buildFeatureItem(Icons.podcasts, 'Audio & Video Podcasts'),
                        _buildFeatureItem(Icons.music_note, 'Christian Music Library'),
                        _buildFeatureItem(Icons.book, 'Bible Stories'),
                        _buildFeatureItem(Icons.radio, 'Live Streaming'),
                        _buildFeatureItem(Icons.people, 'Community Posts'),
                        _buildFeatureItem(Icons.folder, 'Playlists & Favorites'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
            ),
            child: Icon(
              icon,
              color: AppColors.warmBrown,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

