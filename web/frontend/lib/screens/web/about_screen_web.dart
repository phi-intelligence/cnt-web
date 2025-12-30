import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';

/// Web About Screen - Redesigned with Premium Landing Page Style
class AboutScreenWeb extends StatelessWidget {
  const AboutScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section (Full width)
            _buildHeroSection(context, isMobile, isSmallMobile),

            // Main Content Area with overlapping negative margin effect or simply continuous flow
            Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Mission Statement - High Impact Card
                  _buildMissionSection(isMobile, isSmallMobile),
                  const SizedBox(height: 60),

                  // Features Grid
                  _buildFeaturesSection(isMobile, isTablet, isSmallMobile),
                  const SizedBox(height: 60),

                  // Core Values
                  _buildValuesSection(isMobile, isTablet),
                  const SizedBox(height: 80),

                  // Footer
                  _buildFooterSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(
      BuildContext context, bool isMobile, bool isSmallMobile) {
    return Container(
      width: double.infinity,
      // Minimal height for impact
      constraints: const BoxConstraints(minHeight: 400),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile
            ? AppSpacing.medium
            : (isMobile ? AppSpacing.medium : AppSpacing.extraLarge),
        vertical: AppSpacing.extraLarge * 2, // More breathing room
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            AppColors.warmBrown.withOpacity(0.05),
            AppColors.warmBrown.withOpacity(0.12),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo
          Container(
            width: isMobile ? 100 : 140,
            height: isMobile ? 100 : 140,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.2),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/CNT-LOGO.png',
                fit: BoxFit.cover,
                errorBuilder: (context, _, __) =>
                    Icon(Icons.church, size: 60, color: AppColors.warmBrown),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Title & Subtitle
          Text(
            'About Us',
            style: AppTypography.heading1.copyWith(
              fontSize: isMobile ? 36 : 56,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              letterSpacing: -1.0,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Christ New Tabernacle',
            style: AppTypography.heading3.copyWith(
              color: AppColors.warmBrown,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.accentMain,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 32),

          Container(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Text(
              'A digital sanctuary where believers unite, worship, and grow. Experience the power of faith through modern technology.',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                fontSize: isMobile ? 18 : 24,
                color: AppColors.textSecondary,
                height: 1.6,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMissionSection(bool isMobile, bool isSmallMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(
          isSmallMobile ? AppSpacing.medium : (isMobile ? 24 : 48)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.08),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_rounded,
                color: AppColors.warmBrown, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'Our Mission',
            style: AppTypography.heading2.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Text(
            'At Christ New Tabernacle, we are dedicated to creating a digital sanctuary where believers can come together to worship, learn, and grow in their faith. Our platform brings together the best of Christian media - from inspiring podcasts and uplifting music to Bible stories and live streaming services.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.8,
              fontSize: isMobile ? 16 : 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(
      bool isMobile, bool isTablet, bool isSmallMobile) {
    final features = [
      {
        'icon': Icons.podcasts_rounded,
        'title': 'Podcasts',
        'desc': 'Inspiring audio & video series'
      },
      {
        'icon': Icons.music_note_rounded,
        'title': 'Music',
        'desc': 'Uplifting Christian melodies'
      },
      {
        'icon': Icons.menu_book_rounded,
        'title': 'Bible Stories',
        'desc': 'Digital scripture experience'
      },
      {
        'icon': Icons.live_tv_rounded,
        'title': 'Live Stream',
        'desc': 'Join services in real-time'
      },
      {
        'icon': Icons.people_rounded,
        'title': 'Community',
        'desc': 'Connect with other believers'
      },
      {
        'icon': Icons.video_call_rounded,
        'title': 'Meetings',
        'desc': 'Virtual prayer gatherings'
      },
    ];

    return Column(
      children: [
        Text('What We Offer',
            style:
                AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 3),
            crossAxisSpacing: isSmallMobile ? 12 : 24,
            mainAxisSpacing: isSmallMobile ? 12 : 24,
            childAspectRatio: isSmallMobile ? 0.9 : (isMobile ? 1.0 : 1.5),
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final f = features[index];
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
                border:
                    Border.all(color: AppColors.borderPrimary.withOpacity(0.5)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.warmBrown.withOpacity(0.2),
                          AppColors.accentMain.withOpacity(0.1)
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(f['icon'] as IconData,
                        color: AppColors.warmBrown, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    f['title'] as String,
                    style: AppTypography.heading4
                        .copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    f['desc'] as String,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildValuesSection(bool isMobile, bool isTablet) {
    final values = [
      {'title': 'Faith', 'desc': 'Rooted in unchanging Christian truth.'},
      {'title': 'Community', 'desc': 'Building strong bonds among believers.'},
      {
        'title': 'Service',
        'desc': 'Serving our neighbor with love and excellence.'
      },
    ];

    return Column(
      children: [
        Text('Core Values',
            style:
                AppTypography.heading2.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 40),
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: values.map((v) {
            return Container(
              width: isMobile ? double.infinity : 300,
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 0 : 16,
                vertical: isMobile ? 12 : 0,
              ),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown,
                    AppColors.primaryDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    v['title']!,
                    style: AppTypography.heading3.copyWith(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                      width: 40,
                      height: 2,
                      color: Colors.white.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    v['desc']!,
                    style: AppTypography.body
                        .copyWith(color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFooterSection() {
    return Column(
      children: [
        Icon(Icons.church_rounded, size: 32, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(
          '© 2025 Christ New Tabernacle',
          style: AppTypography.caption.copyWith(color: AppColors.textTertiary),
        ),
        const SizedBox(height: 8),
        Text(
          'Version 1.0.0',
          style: AppTypography.caption
              .copyWith(color: AppColors.textTertiary.withOpacity(0.6)),
        ),
      ],
    );
  }
}
