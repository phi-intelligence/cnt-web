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
    // Check for web platform
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800; // Mobile/Tablet breakpoint for Web

    if (isMobile) {
       return _buildMobileLayout(context);
    } else {
       return _buildDesktopSplitLayout(context);
    }
  }

  Widget _buildDesktopSplitLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Row(
        children: [
          // Left Side: Content (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.backgroundPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Back Button
                   SafeArea(
                     child: Align(
                       alignment: Alignment.topLeft,
                       child: TextButton.icon(
                         onPressed: () => Navigator.pop(context),
                         icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                         label: Text('Back', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                         style: TextButton.styleFrom(padding: EdgeInsets.zero),
                       ),
                     ),
                   ),
                   const Spacer(),
                   
                   // Title & Description
                   Text(
                     'Meeting Options',
                     style: AppTypography.heading1.copyWith(
                       color: AppColors.textPrimary,
                       fontSize: 48,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: AppSpacing.medium),
                   Text(
                     'Choose how you want to connect with others',
                     style: AppTypography.body.copyWith(
                       color: AppColors.textSecondary,
                       fontSize: 18,
                     ),
                   ),
                   const SizedBox(height: 48),

                   // Option Cards (Horizontal Row for Meeting Options)
                   Center(
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          _buildDesktopOptionCard(
                            context,
                            title: 'Instant Meeting',
                            icon: Icons.video_call,
                            onTap: () async {
                              // Instant Meeting Logic
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
                          ),
                          _buildDesktopOptionCard(
                            context,
                            title: 'Schedule Meeting',
                            icon: Icons.schedule,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScheduleMeetingScreen(),
                                ),
                              );
                            },
                          ),
                          _buildDesktopOptionCard(
                            context,
                            title: 'Join Meeting',
                            icon: Icons.login,
                            onTap: () async {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const JoinMeetingScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                   ),

                   const Spacer(),
                ],
              ),
            ),
          ),
          
          // Right Side: Image (60%)
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/jesus.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.1),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 200, // Fixed width for consistent cards
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.backgroundSecondary,
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, size: 32, color: AppColors.primaryMain),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTypography.heading4.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Reuse existing options logic
    final List<Map<String, dynamic>> options = [
      {
        'title': 'Instant Meeting',
        'icon': Icons.video_call,
        'onTap': () async {
          // ... (same logic as before, abbreviated here for brevity - copy from original file if needed or duplicate logic)
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
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
             // Keep existing mobile background
            Positioned(
              top: -30,
              right: -MediaQuery.of(context).size.width * 0.4,
              height: MediaQuery.of(context).size.height * 0.6,
              width: MediaQuery.of(context).size.width * 1.3,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/jesus-teaching.png'), // Fallback for mobile
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),
             // ... Gradient ...
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.98),
                            const Color(0xFFF5F0E8).withOpacity(0.85),
                            const Color(0xFFF5F0E8).withOpacity(0.4),
                            Colors.transparent,
                          ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8],
                  ),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: AppSpacing.large,
                    right: AppSpacing.large,
                    top: 20,
                    bottom: AppSpacing.extraLarge,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       // Mobile Header
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Meeting Options',
                              style: AppTypography.heading2.copyWith(color: AppColors.primaryDark),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.small),
                      Text(
                        'Choose how you want to connect with others',
                        style: AppTypography.body.copyWith(color: AppColors.primaryDark.withOpacity(0.7)),
                      ),
                      SizedBox(height: AppSpacing.extraLarge * 2),
                       // Mobile Grid
                       GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 1,
                              crossAxisSpacing: AppSpacing.large,
                              mainAxisSpacing: AppSpacing.large,
                              childAspectRatio: 1.5,
                            ),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options[index];
                               final hoverColors = index % 2 == 0
                                  ? [AppColors.accentMain, AppColors.accentDark]
                                  : [AppColors.warmBrown, AppColors.primaryMain];
                              return _buildOptionCard(
                                title: option['title'] as String,
                                icon: option['icon'] as IconData,
                                hoverColors: hoverColors,
                                onTap: option['onTap'] as VoidCallback,
                              );
                            },
                          ),
                    ],
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
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
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
              Flexible(
                child: Text(
                  widget.title,
                  style: AppTypography.heading4.copyWith(
                    color: _isHovered
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) ...[
                const SizedBox(height: AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tiny),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
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
