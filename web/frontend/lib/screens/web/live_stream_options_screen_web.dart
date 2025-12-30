import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/live/live_stream_start_screen.dart';
import '../../screens/web/live_screen_web.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';

/// Live Stream Options Screen - Web version
/// Shows options for starting live stream, scheduling stream, or viewing streams
class LiveStreamOptionsScreenWeb extends StatefulWidget {
  const LiveStreamOptionsScreenWeb({super.key});

  @override
  State<LiveStreamOptionsScreenWeb> createState() => _LiveStreamOptionsScreenWebState();
}

class _LiveStreamOptionsScreenWebState extends State<LiveStreamOptionsScreenWeb> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'Start Live Stream',
        'icon': Icons.videocam,
        'description': 'Start broadcasting immediately',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveStreamStartScreen(),
            ),
          );
        },
      },
      {
        'title': 'View Live Streams',
        'icon': Icons.live_tv,
        'description': 'Browse and join active streams',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const LiveScreenWeb(),
            ),
          );
        },
      },
      {
        'title': 'Schedule Stream',
        'icon': Icons.schedule,
        'description': 'Schedule a stream for later',
        'onTap': () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Stream scheduling coming soon'),
              duration: Duration(seconds: 2),
            ),
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
                Expanded(
                  child: StyledPageHeader(
                    title: 'Live Stream Options',
                    size: StyledPageHeaderSize.h2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),

            // Options Grid
            Expanded(
              child: SectionContainer(
                showShadow: true,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.large),
                  child: GridView.builder(
                    gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                      context,
                      desktop: 3,
                      tablet: 2,
                      mobile: 1,
                      childAspectRatio: 1.2,
                      crossAxisSpacing: AppSpacing.large,
                      mainAxisSpacing: AppSpacing.large,
                    ),
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options[index];
                      // Alternate hover colors: orange for odd (1, 3), brown for even (2)
                      final hoverColors = index % 2 == 0
                          ? [AppColors.accentMain, AppColors.accentDark] // Orange
                          : [AppColors.warmBrown, AppColors.primaryMain]; // Brown
                      return _buildOptionCard(
                        title: option['title'] as String,
                        icon: option['icon'] as IconData,
                        description: option['description'] as String,
                        hoverColors: hoverColors,
                        onTap: option['onTap'] as VoidCallback,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required String description,
    required List<Color> hoverColors,
    required VoidCallback onTap,
  }) {
    return _OptionCard(
      title: title,
      icon: icon,
      description: description,
      hoverColors: hoverColors,
      onTap: onTap,
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<Color> hoverColors;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.icon,
    required this.description,
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
            gradient: _isHovered
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
                    colors: widget.hoverColors,
                  )
                : null,
            color: _isHovered ? null : Colors.white,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 70,
                height: 70,
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
              const SizedBox(height: AppSpacing.medium),
              Text(
                widget.title,
                style: AppTypography.heading3.copyWith(
                  color: _isHovered
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                widget.description,
                style: AppTypography.bodySmall.copyWith(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_isHovered) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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

