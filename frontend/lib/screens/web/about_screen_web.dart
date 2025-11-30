import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/section_container.dart';

/// Web About Screen
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
            // Hero Section
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
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Features Grid
                  _buildFeaturesSection(isMobile, isTablet),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Values Section
                  _buildValuesSection(isMobile, isTablet),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Version & Copyright
                  _buildFooterSection(),
                  const SizedBox(height: AppSpacing.extraLarge),
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
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
        vertical: AppSpacing.extraLarge * 2,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.1),
            AppColors.accentMain.withOpacity(0.05),
            AppColors.backgroundPrimary,
          ],
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            width: isMobile ? 100 : 140,
            height: isMobile ? 100 : 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              child: Image.asset(
                'assets/images/ChatGPT Image Nov 18, 2025, 07_33_01 PM.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.church,
                    size: isMobile ? 50 : 70,
                    color: Colors.white,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          
          // App Name
          Text(
            'Christ New Tabernacle',
            style: AppTypography.heading1.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.warmBrown,
              fontSize: isMobile ? 28 : 36,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.medium),
          
          // Tagline
          Text(
            'A Christian Media Platform for Faith, Community, and Worship',
            style: AppTypography.heading4.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
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
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.2),
                      AppColors.accentMain.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.warmBrown,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                'Our Mission',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          Text(
            'At Christ New Tabernacle, we are dedicated to creating a digital sanctuary where believers can come together to worship, learn, and grow in their faith. Our platform brings together the best of Christian media - from inspiring podcasts and uplifting music to Bible stories and live streaming services.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            'We believe in the power of community and the importance of sharing God\'s word through modern technology. Join thousands of believers who are already part of our growing community.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile, bool isTablet) {
    final features = [
      {
        'icon': Icons.podcasts,
        'title': 'Audio & Video Podcasts',
        'description': 'Access inspiring Christian podcasts and video content',
      },
      {
        'icon': Icons.music_note,
        'title': 'Christian Music Library',
        'description': 'Discover and enjoy uplifting Christian music',
      },
      {
        'icon': Icons.book,
        'title': 'Bible Stories & Documents',
        'description': 'Read Bible stories and study guides',
      },
      {
        'icon': Icons.live_tv,
        'title': 'Live Streaming',
        'description': 'Join live worship services and events',
      },
      {
        'icon': Icons.people,
        'title': 'Community Posts',
        'description': 'Connect and share with fellow believers',
      },
      {
        'icon': Icons.video_call,
        'title': 'Meetings & Gatherings',
        'description': 'Schedule and join virtual meetings',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentMain.withOpacity(0.2),
                    AppColors.warmBrown.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.accentMain.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.star,
                color: AppColors.accentMain,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Text(
              'Platform Features',
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 1 : (isTablet ? 2 : 3),
            childAspectRatio: 1.6,
            crossAxisSpacing: AppSpacing.large,
            mainAxisSpacing: AppSpacing.large,
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
    );
  }

  Widget _buildValuesSection(bool isMobile, bool isTablet) {
    final values = [
      {
        'icon': Icons.favorite,
        'title': 'Faith',
        'description': 'Rooted in Christian values and biblical principles',
      },
      {
        'icon': Icons.handshake,
        'title': 'Community',
        'description': 'Building connections among believers worldwide',
      },
      {
        'icon': Icons.volunteer_activism,
        'title': 'Service',
        'description': 'Serving God and our community with excellence',
      },
    ];

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.2),
                      AppColors.accentMain.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  border: Border.all(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: AppColors.warmBrown,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Text(
                'Our Core Values',
                style: AppTypography.heading2.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          isMobile
              ? Column(
                  children: values.map((value) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.large),
                      child: _ValueCard(
                        icon: value['icon'] as IconData,
                        title: value['title'] as String,
                        description: value['description'] as String,
                      ),
                    );
                  }).toList(),
                )
              : Row(
                  children: values.map((value) {
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: value == values.last ? 0 : AppSpacing.large,
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
      padding: const EdgeInsets.all(AppSpacing.extraLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Version 1.0.0',
            style: AppTypography.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            '© 2024 Christ New Tabernacle. All rights reserved.',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isHovered
                ? [
                    AppColors.warmBrown.withOpacity(0.1),
                    AppColors.accentMain.withOpacity(0.05),
                  ]
                : [
                    Colors.white,
                    Colors.white,
                  ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: _isHovered
                ? AppColors.warmBrown
                : AppColors.borderPrimary,
            width: _isHovered ? 2 : 1,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isHovered
                      ? [AppColors.warmBrown, AppColors.accentMain]
                      : [
                          AppColors.warmBrown.withOpacity(0.1),
                          AppColors.accentMain.withOpacity(0.05),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.warmBrown
                      : AppColors.borderPrimary,
                  width: 1,
                ),
              ),
              child: Icon(
                widget.icon,
                color: _isHovered ? Colors.white : AppColors.warmBrown,
                size: 24,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              widget.title,
              style: AppTypography.heading4.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: AppSpacing.tiny),
            Expanded(
              child: Text(
                widget.description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.4,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.05),
            AppColors.accentMain.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.warmBrown.withOpacity(0.2),
                  AppColors.accentMain.withOpacity(0.1),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.warmBrown,
              size: 40,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Text(
            title,
            style: AppTypography.heading4.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
