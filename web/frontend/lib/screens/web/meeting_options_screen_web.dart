import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../meeting/meeting_created_screen.dart';
import '../meeting/schedule_meeting_screen.dart';
import '../meeting/join_meeting_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';

/// Meeting Options Screen - Web version
/// Shows options for instant meeting, schedule meeting, or join meeting
class MeetingOptionsScreenWeb extends StatefulWidget {
  const MeetingOptionsScreenWeb({super.key});

  @override
  State<MeetingOptionsScreenWeb> createState() => _MeetingOptionsScreenWebState();
}

class _MeetingOptionsScreenWebState extends State<MeetingOptionsScreenWeb> {
  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'title': 'Instant Meeting',
        'icon': Icons.video_call,
        'onTap': () async {
          try {
            final resp = await ApiService().createStream(title: 'Instant Meeting');
            final meetingId = (resp['id'] ?? '').toString();
            final roomName = resp['room_name'] as String;
            final liveKitUrl = ApiService().getLiveKitUrl().replaceAll('ws://', 'http://').replaceAll('wss://', 'https://');
            final meetingLink = '$liveKitUrl/meeting/$roomName';
            if (meetingId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to create meeting')),
                );
              }
              return;
            }
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MeetingCreatedScreen(
                    meetingId: meetingId,
                    meetingLink: meetingLink,
                    isInstant: true,
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to start instant meeting: $e')),
              );
            }
          }
        },
      },
      {
        'title': 'Schedule Meeting',
        'icon': Icons.schedule,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduleMeetingScreen(),
            ),
          );
        },
      },
      {
        'title': 'Join Meeting',
        'icon': Icons.login,
        'onTap': () async {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const JoinMeetingScreen(),
            ),
          );
        },
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
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
                    title: 'Meeting Options',
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
    required List<Color> hoverColors,
    required VoidCallback onTap,
  }) {
    return _OptionCard(
      title: title,
      icon: icon,
      hoverColors: hoverColors,
      onTap: onTap,
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final List<Color> hoverColors;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
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
                      AppColors.cardBackground,
                      AppColors.backgroundSecondary,
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
