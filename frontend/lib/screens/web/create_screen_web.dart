import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../creation/video_podcast_create_screen.dart';
import '../creation/audio_podcast_create_screen.dart';
import '../creation/quote_create_screen_web.dart';
import '../mobile/meeting_options_screen_mobile.dart';
import '../live/live_stream_start_screen.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Web Create Screen - Full implementation
class CreateScreenWeb extends StatelessWidget {
  const CreateScreenWeb({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> optionCards = [
      _buildOptionCard(
        context,
        title: 'Video',
        icon: Icons.videocam,
        backgroundColor: AppColors.primaryMain,
        onTap: () => _navigateToScreen(
          context,
          const VideoPodcastCreateScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Audio',
        icon: Icons.mic,
        backgroundColor: AppColors.accentDark,
        onTap: () => _navigateToScreen(
          context,
          const AudioPodcastCreateScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Meeting',
        icon: Icons.group,
        backgroundColor: AppColors.accentMain,
        onTap: () => _navigateToScreen(
          context,
          MeetingOptionsScreenMobile(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Live Stream',
        icon: Icons.live_tv,
        backgroundColor: AppColors.warmBrown,
        onTap: () => _navigateToScreen(
          context,
          const LiveStreamStartScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Quote',
        icon: Icons.format_quote,
        backgroundColor: AppColors.accentMain,
        onTap: () => _navigateToScreen(
          context,
          const QuoteCreateScreenWeb(),
        ),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            StyledPageHeader(
              title: 'Create Content',
              size: StyledPageHeaderSize.h2,
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Options Grid
            Expanded(
              child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                context,
                desktop: 5,
                tablet: 3,
                mobile: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: AppSpacing.large,
                mainAxisSpacing: AppSpacing.large,
              ),
              itemCount: optionCards.length,
              itemBuilder: (context, index) => optionCards[index],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    Color backgroundColor = AppColors.warmBrown,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.95),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: backgroundColor.withOpacity(0.25),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.textInverse, size: 36),
              ),
              const Spacer(),
              Text(
                title,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textInverse,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
