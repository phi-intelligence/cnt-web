import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';
import '../../widgets/web/section_container.dart';

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
            
            // Main Content Area
            Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              constraints: const BoxConstraints(maxWidth: 1400),
              child: Column(
                children: [
                   const SizedBox(height: AppSpacing.extraLarge),
                   
                   // Mission Statement
                   _buildMissionSection(isMobile, isSmallMobile),
                   const SizedBox(height: 80),
                   
                   // Features Grid
                   _buildFeaturesSection(isMobile, isTablet, isSmallMobile),
                   const SizedBox(height: 80),
                   
                   // Core Values
                   _buildValuesSection(isMobile, isTablet),
                   const SizedBox(height: 100),
                   
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

  Widget _buildHeroSection(BuildContext context, bool isMobile, bool isSmallMobile) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 500),
      child: Stack(
        children: [
          // Background with Premium Gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/christimage.png'),
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.9),
                      Colors.white.withOpacity(0.7),
                      AppColors.warmBrown.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Decorative Elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.warmBrown.withOpacity(0.03),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.05),
                    blurRadius: 100,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallMobile ? AppSpacing.medium : (isMobile ? AppSpacing.medium : AppSpacing.extraLarge),
              vertical: AppSpacing.extraLarge * 2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 const SizedBox(height: 40), // Space for back button if needed, though it's absolute now
                 
                 // Logo
                 Hero(
                   tag: 'app_logo',
                   child: Container(
                     width: isMobile ? 120 : 160,
                     height: isMobile ? 120 : 160,
                     padding: const EdgeInsets.all(4),
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white,
                       boxShadow: [
                         BoxShadow(
                           color: AppColors.warmBrown.withOpacity(0.15),
                           blurRadius: 40,
                           offset: const Offset(0, 15),
                         ),
                       ],
                     ),
                     child: ClipOval(
                        child: Image.asset(
                          'assets/images/CNT-LOGO.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, _, __) => Icon(Icons.church, size: 60, color: AppColors.warmBrown),
                        ),
                     ),
                   ),
                 ),
                 const SizedBox(height: 40),

                 // Title & Subtitle
                 Text(
                   'About Us',
                   style: AppTypography.heading1.copyWith(
                     fontSize: isMobile ? 40 : 64,
                     fontWeight: FontWeight.bold,
                     color: AppColors.textPrimary,
                     letterSpacing: -1.0,
                     height: 1.1,
                   ),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 16),
                 Text(
                   'Christ New Tabernacle',
                   style: AppTypography.heading3.copyWith(
                     color: AppColors.warmBrown,
                     fontWeight: FontWeight.w600,
                     letterSpacing: 2.0,
                     fontSize: isMobile ? 16 : 20,
                   ),
                   textAlign: TextAlign.center,
                 ),
                 const SizedBox(height: 32),
                 
                 Container(
                   width: 80,
                   height: 4,
                   decoration: BoxDecoration(
                     color: AppColors.warmBrown,
                     borderRadius: BorderRadius.circular(2),
                   ),
                 ),
                 const SizedBox(height: 40),
                 
                 Container(
                   constraints: const BoxConstraints(maxWidth: 800),
                   child: Text(
                     'A digital sanctuary where believers unite, worship, and grow.\nExperience the power of faith through modern technology.',
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
          ),

          // Back Navigation - Properly Positioned
          Positioned(
            top: AppSpacing.extraLarge,
            left: isMobile ? AppSpacing.medium : AppSpacing.extraLarge,
            child: SafeArea( // Ensure it doesn't overlap with status bar on mobile web
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: AppColors.borderPrimary.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_back_rounded, color: AppColors.warmBrown, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Back to Home', 
                          style: TextStyle(
                            color: AppColors.warmBrown, 
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionSection(bool isMobile, bool isSmallMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallMobile ? AppSpacing.medium : (isMobile ? 32 : 64),
        vertical: 48,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        image: DecorationImage(
          image: AssetImage('assets/images/christ.png'),
          fit: BoxFit.cover,
          opacity: 0.05,
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.06),
            blurRadius: 60,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
             padding: const EdgeInsets.all(20),
             decoration: BoxDecoration(
               color: AppColors.warmBrown.withOpacity(0.08),
               shape: BoxShape.circle,
             ),
             child: Icon(Icons.favorite_rounded, color: AppColors.warmBrown, size: 36),
          ),
          const SizedBox(height: 32),
          Text(
            'Our Mission',
            style: AppTypography.heading2.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
              fontSize: isMobile ? 28 : 36,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Text(
               'At Christ New Tabernacle, we are dedicated to creating a digital sanctuary where believers can come together to worship, learn, and grow in their faith. Our platform brings together the best of Christian media - from inspiring podcasts and uplifting music to Bible stories and live streaming services.',
               textAlign: TextAlign.center,
               style: AppTypography.body.copyWith(
                 color: AppColors.textSecondary,
                 height: 1.8,
                 fontSize: isMobile ? 16 : 20,
                 letterSpacing: 0.2,
               ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isMobile, bool isTablet, bool isSmallMobile) {
    final features = [
      {'icon': Icons.podcasts_rounded, 'title': 'Podcasts', 'desc': 'Inspiring audio & video series'},
      {'icon': Icons.music_note_rounded, 'title': 'Music', 'desc': 'Uplifting Christian melodies'},
      {'icon': Icons.menu_book_rounded, 'title': 'Bible Stories', 'desc': 'Digital scripture experience'},
      {'icon': Icons.live_tv_rounded, 'title': 'Live Stream', 'desc': 'Join services in real-time'},
      {'icon': Icons.people_rounded, 'title': 'Community', 'desc': 'Connect with other believers'},
      {'icon': Icons.video_call_rounded, 'title': 'Meetings', 'desc': 'Virtual prayer gatherings'},
    ];

    return Column(
      children: [
        Text(
          'What We Offer', 
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 28 : 36,
          )
        ),
        const SizedBox(height: 48),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isMobile ? 2 : (isTablet ? 3 : 3),
            crossAxisSpacing: isSmallMobile ? 16 : 32,
            mainAxisSpacing: isSmallMobile ? 16 : 32,
            childAspectRatio: isSmallMobile ? 0.85 : (isMobile ? 0.9 : 1.2),
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
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: AppColors.borderPrimary.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warmBrown.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(f['icon'] as IconData, color: AppColors.warmBrown, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    f['title'] as String,
                    style: AppTypography.heading4.copyWith(
                      fontWeight: FontWeight.w600, 
                      fontSize: isMobile ? 16 : 20
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    f['desc'] as String,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary, 
                      fontSize: isMobile ? 13 : 15,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
      {'title': 'Service', 'desc': 'Serving our neighbor with love and excellence.'},
    ];

    return Column(
      children: [
        Text(
          'Core Values', 
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 28 : 36,
          )
        ),
        const SizedBox(height: 48),
        Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          mainAxisAlignment: MainAxisAlignment.center,
          children: values.map((v) {
            return Container(
              width: isMobile ? double.infinity : 350,
              margin: EdgeInsets.symmetric(
                 horizontal: isMobile ? 0 : 20,
                 vertical: isMobile ? 16 : 0,
              ),
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown,
                    Color(0xFF8D6E63), // A slightly darker shade for gradient
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 15),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    v['title']!,
                    style: AppTypography.heading3.copyWith(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(width: 40, height: 2, color: Colors.white.withOpacity(0.4)),
                  const SizedBox(height: 24),
                  Text(
                    v['desc']!,
                    style: AppTypography.body.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                      fontSize: 16,
                    ),
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
        Icon(Icons.church_rounded, size: 40, color: AppColors.warmBrown.withOpacity(0.5)),
        const SizedBox(height: 24),
        Text(
          '© 2025 Christ New Tabernacle',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Version 1.0.0',
          style: AppTypography.caption.copyWith(
            color: AppColors.textTertiary.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
