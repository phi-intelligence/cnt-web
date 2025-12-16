import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../creation/video_podcast_create_screen.dart';
import '../creation/audio_podcast_create_screen.dart';
import '../creation/quote_create_screen_web.dart';
import 'meeting_options_screen_web.dart';
import '../live/live_stream_start_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/responsive_utils.dart';
import '../../providers/auth_provider.dart';
import '../admin/bulk_upload_screen.dart';
import '../events/events_list_screen_web.dart';
import '../creation/movie_create_screen.dart';

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
    // Use responsive aspect ratio based on device type
    final aspectRatio = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 1.3, // Was 2.5 - caused overflow
      tablet: 1.8,
      desktop: 1.3,
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/christimage.png'),
            fit: BoxFit.cover,
            opacity: 0.15,
          ),
        ),
        child: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: GridView.builder(
            gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
              context,
              mobile: 1,
              tablet: 2,
              desktop: 3,
              childAspectRatio: aspectRatio,
              crossAxisSpacing: ResponsiveUtils.getResponsivePadding(context, AppSpacing.extraLarge),
              mainAxisSpacing: ResponsiveUtils.getResponsivePadding(context, AppSpacing.extraLarge),
            ),
            itemCount: _getOptionCards(context).length,
            itemBuilder: (context, index) => _getOptionCards(context)[index],
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
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final cards = <Widget>[
      // 1. Audio Podcast (brown)
      _buildOptionCard(
        context,
        title: 'Audio Podcast',
        description: 'Record and share audio content',
        icon: Icons.mic,
        hoverColors: brownHover,
        onTap: () => _navigateToScreen(
          context,
          const AudioPodcastCreateScreen(),
        ),
      ),
      // 2. Video Podcast (orange)
      _buildOptionCard(
        context,
        title: 'Video Podcast',
        description: 'Create and upload video content',
        icon: Icons.videocam,
        hoverColors: orangeHover,
        onTap: () => _navigateToScreen(
          context,
          const VideoPodcastCreateScreen(),
        ),
      ),
      // 3. Meetings (brown)
      _buildOptionCard(
        context,
        title: 'Meeting',
        description: 'Schedule or start a meeting',
        icon: Icons.group,
        hoverColors: brownHover,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const MeetingOptionsScreenWeb(),
            ),
          );
        },
      ),
      // 4. Quote (orange)
      _buildOptionCard(
        context,
        title: 'Quote',
        description: 'Share inspirational quotes',
        icon: Icons.format_quote,
        hoverColors: orangeHover,
        onTap: () => _navigateToScreen(
          context,
          const QuoteCreateScreenWeb(),
        ),
      ),
      // 5. Events (brown)
      _buildOptionCard(
        context,
        title: 'Events',
        description: 'Host or join community events',
        icon: Icons.event,
        hoverColors: brownHover,
        onTap: () => _navigateToScreen(
          context,
          const EventsListScreenWeb(),
        ),
      ),
      // 6. Live Stream (orange)
      _buildOptionCard(
        context,
        title: 'Live Stream',
        description: 'Start a live streaming session',
        icon: Icons.live_tv,
        hoverColors: orangeHover,
        onTap: () => _navigateToScreen(
          context,
          const LiveStreamStartScreen(),
        ),
      ),
      // 7. My Drafts (brown)
      _buildOptionCard(
        context,
        title: 'My Drafts',
        description: 'Continue editing saved work',
        icon: Icons.drafts_outlined,
        hoverColors: brownHover,
        onTap: () => context.push('/my-drafts'),
      ),
    ];
    
    // Add Movie and Bulk Upload cards for admins only
    if (authProvider.isAdmin) {
      cards.add(
        _buildOptionCard(
          context,
          title: 'Movie',
          description: 'Upload and manage movies',
          icon: Icons.movie,
          hoverColors: brownHover, // 8 - brown (admin only)
          onTap: () => _navigateToScreen(
            context,
            const MovieCreateScreen(),
          ),
        ),
      );
      cards.add(
        _buildOptionCard(
          context,
          title: 'Bulk Upload',
          description: 'Upload multiple podcasts at once',
          icon: Icons.cloud_upload,
          hoverColors: orangeHover, // 9 - orange (admin only)
          onTap: () => _navigateToScreen(
            context,
            const BulkUploadScreen(),
          ),
        ),
      );
    }
    
    return cards;
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
    // Responsive icon size and padding
    final iconSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 32.0,
      tablet: 36.0,
      desktop: 40.0,
    );
    
    final cardPadding = ResponsiveUtils.getResponsivePadding(context, AppSpacing.extraLarge);
    
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
            gradient: _isHovered
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.hoverColors,
                  )
                : null,
            color: _isHovered ? null : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(30),
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
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
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
                  size: iconSize,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.large)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: AppTypography.getResponsiveHeading3(context).copyWith(
                      color: _isHovered
                          ? Colors.white
                          : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                  Text(
                    widget.description,
                    style: AppTypography.getResponsiveBody(context).copyWith(
                      color: _isHovered
                          ? Colors.white.withOpacity(0.9)
                          : AppColors.textSecondary,
                      fontSize: ResponsiveUtils.getFontSizeScale(context) * 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              if (_isHovered) ...[
                SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
                Row(
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.getResponsiveBodyMedium(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: ResponsiveUtils.getResponsivePadding(context, AppSpacing.small)),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: ResponsiveUtils.getFontSizeScale(context) * 18,
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
