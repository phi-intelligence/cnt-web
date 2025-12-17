import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/section_container.dart';

/// Web About Screen - Redesigned with compact layout
class AboutScreenWeb extends StatelessWidget {
  const AboutScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with Back Button
            _buildHeroSection(context, isMobile),
            
            // Main Content
            Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mission Section
                  _buildMissionSection(isMobile, isTablet),
                  const SizedBox(height: AppSpacing.large),
                  
                  // Features Grid
                  _buildFeaturesSection(isMobile, isTablet),
                  const SizedBox(height: AppSpacing.large),
                  
                  // Values Section
                  _buildValuesSection(isMobile, isTablet),
                  const SizedBox(height: AppSpacing.large),
                  
                  // Version & Copyright
                  _buildFooterSection(),
                  const SizedBox(height: AppSpacing.large),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.medium : AppSpacing.extraLarge,
        vertical: AppSpacing.large,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.08),
            AppColors.accentMain.withOpacity(0.04),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Back button row
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => context.go('/home'),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.medium,
                      vertical: AppSpacing.small,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.warmBrown.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 18,
                          color: AppColors.warmBrown,
                        ),
                        const SizedBox(width: AppSpacing.tiny),
                        Text(
                          'Back',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.warmBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Logo and Title Row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo - smaller size
              Container(
                width: isMobile ? 60 : 80,
                height: isMobile ? 60 : 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown, AppColors.accentMain],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.warmBrown.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Image.asset(
                    'assets/images/CNT-LOGO.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/cnt-dove-logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.church,
                            size: isMobile ? 32 : 40,
                            color: Colors.white,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              
              // Title Column
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About Us',
                      style: AppTypography.heading2.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warmBrown,
                        fontSize: isMobile ? 24 : 28,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.tiny),
                    Text(
                      'Christ New Tabernacle - Christian Media Platform',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(bool isMobile, bool isTablet) {
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.2),
                      AppColors.accentMain.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Our Mission',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'At Christ New Tabernacle, we are dedicated to creating a digital sanctuary where believers can come together to worship, learn, and grow in their faith. Our platform brings together the best of Christian media - from inspiring podcasts and uplifting music to Bible stories and live streaming services.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'We believe in the power of community and the importance of sharing God\'s word through modern technology.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile, bool isTablet) {
    final features = [
      {'icon': Icons.podcasts, 'title': 'Podcasts', 'description': 'Audio & video content'},
      {'icon': Icons.music_note, 'title': 'Music', 'description': 'Christian music library'},
      {'icon': Icons.book, 'title': 'Bible', 'description': 'Stories & documents'},
      {'icon': Icons.live_tv, 'title': 'Live', 'description': 'Worship services'},
      {'icon': Icons.people, 'title': 'Community', 'description': 'Connect & share'},
      {'icon': Icons.video_call, 'title': 'Meetings', 'description': 'Virtual gatherings'},
    ];

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accentMain.withOpacity(0.2),
                      AppColors.warmBrown.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.accentMain.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.star,
                  color: AppColors.accentMain,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Platform Features',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 6),
              childAspectRatio: isMobile ? 1.3 : 1.2,
              crossAxisSpacing: AppSpacing.small,
              mainAxisSpacing: AppSpacing.small,
            ),
            itemCount: features.length,
            itemBuilder: (context, index) {
              final feature = features[index];
              return _FeatureCard(
                icon: feature['icon'] as IconData,
                title: feature['title'] as String,
                description: feature['description'] as String,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildValuesSection(bool isMobile, bool isTablet) {
    final values = [
      {'icon': Icons.favorite, 'title': 'Faith', 'description': 'Rooted in Christian values'},
      {'icon': Icons.handshake, 'title': 'Community', 'description': 'Connecting believers'},
      {'icon': Icons.volunteer_activism, 'title': 'Service', 'description': 'Serving with excellence'},
    ];

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.2),
                      AppColors.accentMain.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                  border: Border.all(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.warmBrown,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.small),
              Text(
                'Our Core Values',
                style: AppTypography.heading3.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Row(
            children: values.map((value) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: value == values.last ? 0 : AppSpacing.small,
                  ),
                  child: _ValueCard(
                    icon: value['icon'] as IconData,
                    title: value['title'] as String,
                    description: value['description'] as String,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBrown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Version 1.0.0',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.warmBrown,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
          ),
          Text(
            '© 2024 Christ New Tabernacle',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.tiny : AppSpacing.small),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle icon container
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _ValueCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.warmBrown.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.small),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warmBrown,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            description,
            style: AppTypography.caption.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
