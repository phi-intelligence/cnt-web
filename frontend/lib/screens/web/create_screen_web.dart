import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../creation/video_podcast_create_screen.dart';
import '../creation/audio_podcast_create_screen.dart';
import '../creation/quote_create_screen_web.dart';
import 'meeting_options_screen_web.dart';
import '../live/live_stream_start_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_documents_page.dart';

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              StyledPageHeader(
                title: 'Create Content',
                size: StyledPageHeaderSize.h2,
              ),
              const SizedBox(height: AppSpacing.extraLarge * 2),
              
              // Main Content Section
              SectionContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Title
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.small),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warmBrown.withOpacity(0.2),
                                AppColors.accentMain.withOpacity(0.15),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                            border: Border.all(
                              color: AppColors.warmBrown.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            Icons.add_circle_outline,
                            color: AppColors.warmBrown,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                        Text(
                          'Choose Content Type',
                          style: AppTypography.heading2.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.extraLarge * 2),
                    
                    // Options Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                        context,
                        desktop: 3,
                        tablet: 2,
                        mobile: 1,
                        childAspectRatio: isMobile ? 2.5 : 1.3,
                        crossAxisSpacing: AppSpacing.extraLarge,
                        mainAxisSpacing: AppSpacing.extraLarge,
                      ),
                      itemCount: _getOptionCards(context).length,
                      itemBuilder: (context, index) => _getOptionCards(context)[index],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _getOptionCards(BuildContext context) {
    // Orange hover colors (accent colors) - for odd cards (1, 3, 5)
    final orangeHover = [AppColors.accentMain, AppColors.accentDark];
    // Brown hover colors (warm brown/primary) - for even cards (2, 4, 6)
    final brownHover = [AppColors.warmBrown, AppColors.primaryMain];
    
    return [
      _buildOptionCard(
        context,
        title: 'Video Podcast',
        description: 'Create and upload video content',
        icon: Icons.videocam,
        hoverColors: orangeHover, // 1 - orange
        onTap: () => _navigateToScreen(
          context,
          const VideoPodcastCreateScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Audio Podcast',
        description: 'Record and share audio content',
        icon: Icons.mic,
        hoverColors: brownHover, // 2 - brown
        onTap: () => _navigateToScreen(
          context,
          const AudioPodcastCreateScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Live Stream',
        description: 'Start a live streaming session',
        icon: Icons.live_tv,
        hoverColors: orangeHover, // 3 - orange
        onTap: () => _navigateToScreen(
          context,
          const LiveStreamStartScreen(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Meeting',
        description: 'Schedule or start a meeting',
        icon: Icons.group,
        hoverColors: brownHover, // 4 - brown
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeetingOptionsScreenWeb(),
            ),
          );
        },
      ),
      _buildOptionCard(
        context,
        title: 'Quote',
        description: 'Share inspirational quotes',
        icon: Icons.format_quote,
        hoverColors: orangeHover, // 5 - orange
        onTap: () => _navigateToScreen(
          context,
          const QuoteCreateScreenWeb(),
        ),
      ),
      _buildOptionCard(
        context,
        title: 'Document',
        description: 'Upload and manage documents',
        icon: Icons.description,
        hoverColors: brownHover, // 6 - brown
        onTap: () {
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          if (authProvider.isAdmin) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AdminDocumentsPage(),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Document upload is only available for administrators.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      ),
    ];
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required List<Color> hoverColors,
    required VoidCallback onTap,
  }) {
    return _OptionCard(
      title: title,
      description: description,
      icon: icon,
      hoverColors: hoverColors,
      onTap: onTap,
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> hoverColors;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.hoverColors,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? widget.hoverColors
                  : [
                      Colors.white,
                      Colors.white,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: _isHovered
                  ? widget.hoverColors.first
                  : AppColors.borderPrimary,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.hoverColors.first.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.warmBrown.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isHovered
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered
                      ? Colors.white
                      : AppColors.warmBrown,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.heading3.copyWith(
                      color: _isHovered
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    widget.description,
                    style: AppTypography.body.copyWith(
                      color: _isHovered
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (_isHovered) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
