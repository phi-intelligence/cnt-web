import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import '../meeting/meeting_created_screen.dart';
import '../meeting/schedule_meeting_screen.dart';
import '../meeting/join_meeting_screen.dart';
import '../meeting/scheduled_meetings_list_screen.dart';
import '../../widgets/web/section_container.dart';

/// Meeting Options Screen - Web version
/// Shows options for instant meeting, schedule meeting, or join meeting
class MeetingOptionsScreenWeb extends StatefulWidget {
  const MeetingOptionsScreenWeb({super.key});

  @override
  State<MeetingOptionsScreenWeb> createState() =>
      _MeetingOptionsScreenWebState();
}

class _MeetingOptionsScreenWebState extends State<MeetingOptionsScreenWeb> {
  List<Map<String, dynamic>> _scheduledMeetings = [];
  bool _loadingScheduledMeetings = false;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _fetchScheduledMeetings();
    // Start countdown timer to update UI every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh scheduled meetings when returning to this screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchScheduledMeetings();
    });
  }

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
      resizeToAvoidBottomInset: false,
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
                        icon: Icon(Icons.arrow_back,
                            color: AppColors.textPrimary),
                        label: Text('Back',
                            style: AppTypography.body
                                .copyWith(color: AppColors.textPrimary)),
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
                              final resp = await ApiService()
                                  .createStream(title: 'Instant Meeting');
                              final meetingId = (resp['id'] ?? '').toString();
                              final roomName = resp['room_name'] as String;
                              final liveKitUrl = ApiService()
                                  .getLiveKitUrl()
                                  .replaceAll('ws://', 'http://')
                                  .replaceAll('wss://', 'https://');
                              final meetingLink =
                                  '$liveKitUrl/meeting/$roomName';
                              if (meetingId.isEmpty) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text('Failed to create meeting')),
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
                                  SnackBar(
                                      content: Text(
                                          'Failed to start instant meeting: $e')),
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
                                builder: (context) =>
                                    const ScheduleMeetingScreen(),
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
                        _buildDesktopOptionCard(
                          context,
                          title: 'View Scheduled Meetings',
                          icon: Icons.calendar_month,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ScheduledMeetingsListScreen(),
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

  Future<void> _fetchScheduledMeetings() async {
    if (!mounted) return;

    setState(() {
      _loadingScheduledMeetings = true;
    });

    try {
      // Get current user ID
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = userProvider.user ?? authProvider.user;
      final userId = currentUser?['id'] as int?;

      if (userId == null) {
        setState(() {
          _scheduledMeetings = [];
          _loadingScheduledMeetings = false;
        });
        return;
      }

      // Fetch all streams
      final streams = await ApiService().listStreams();

      // Filter for scheduled meetings by current user
      final now = DateTime.now();
      final scheduled = streams.where((stream) {
        final hostId = stream['host_id'] as int?;
        final scheduledStart = stream['scheduled_start'] as String?;

        if (hostId != userId || scheduledStart == null) return false;

        try {
          final scheduledDate = DateTime.parse(scheduledStart);
          // Only show future scheduled meetings
          return scheduledDate.isAfter(now) &&
              (stream['status'] == 'scheduled' || stream['status'] == null);
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort by scheduled_start (earliest first)
      scheduled.sort((a, b) {
        final aDate = DateTime.parse(a['scheduled_start'] as String);
        final bDate = DateTime.parse(b['scheduled_start'] as String);
        return aDate.compareTo(bDate);
      });

      if (mounted) {
        setState(() {
          _scheduledMeetings = scheduled;
          _loadingScheduledMeetings = false;
        });
      }
    } catch (e) {
      print('Error fetching scheduled meetings: $e');
      if (mounted) {
        setState(() {
          _loadingScheduledMeetings = false;
        });
      }
    }
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
          width: 240, // Increased width for better layout
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
                padding: const EdgeInsets.all(20), // Increased padding
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon,
                    size: 40,
                    color: AppColors.primaryMain), // Increased icon size
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Slightly larger font
                  color:
                      AppColors.textPrimary, // Explicit color to fix visibility
                ),
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
            final resp =
                await ApiService().createStream(title: 'Instant Meeting');
            final meetingId = (resp['id'] ?? '').toString();
            final roomName = resp['room_name'] as String;
            final liveKitUrl = ApiService()
                .getLiveKitUrl()
                .replaceAll('ws://', 'http://')
                .replaceAll('wss://', 'https://');
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
      {
        'title': 'View Scheduled Meetings',
        'icon': Icons.calendar_month,
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ScheduledMeetingsListScreen(),
            ),
          );
        },
      },
    ];

    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              // Background Image
              Positioned(
                top: -30,
                right: -MediaQuery.of(context).size.width * 0.4,
                height: MediaQuery.of(context).size.height * 0.6,
                width: MediaQuery.of(context).size.width * 1.3,
                child: Opacity(
                  opacity:
                      0.6, // Reduce opacity to ensure text/content stands out
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: const AssetImage(
                            'assets/images/jesus-teaching.png'),
                        fit: BoxFit.contain,
                        alignment: Alignment.topRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Gradient Overlay for readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFF5F0E8),
                        const Color(0xFFF5F0E8).withOpacity(0.95),
                        const Color(0xFFF5F0E8).withOpacity(0.8),
                        const Color(0xFFF5F0E8).withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                    ),
                  ),
                ),
              ),
              // Content
              Positioned.fill(
                child: SafeArea(
                  child: Column(
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.large, vertical: 20),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: AppColors.textPrimary),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Meeting Options',
                                style: AppTypography.heading2
                                    .copyWith(color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Main Content in Scrollable Area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: EdgeInsets.only(
                            left: AppSpacing.large,
                            right: AppSpacing.large,
                            bottom: AppSpacing.extraLarge * 2,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Choose how you want to connect with others',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              SizedBox(height: AppSpacing.extraLarge),

                              // Cards Container - High Contrast
                              SectionContainer(
                                showShadow: true,
                                child: Padding(
                                  padding: EdgeInsets.all(isMobile
                                      ? AppSpacing.small
                                      : AppSpacing.medium),
                                  child: GridView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount:
                                          1, // Full width cards on mobile
                                      crossAxisSpacing: AppSpacing.medium,
                                      mainAxisSpacing: AppSpacing.medium,
                                      childAspectRatio: isMobile
                                          ? 2.2
                                          : 2.5, // Increased slightly for mobile to prevent overflow
                                    ),
                                    itemCount: options.length,
                                    itemBuilder: (context, index) {
                                      final option = options[index];
                                      // Ensure consistent colors
                                      final hoverColors = [
                                        AppColors.accentMain,
                                        AppColors.accentDark
                                      ];

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
                              SizedBox(height: AppSpacing.extraLarge),

                              // Scheduled Meetings Section
                              if (_scheduledMeetings.isNotEmpty) ...[
                                SizedBox(height: AppSpacing.extraLarge),
                                _buildScheduledMeetingsSection(),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildScheduledMeetingsSection() {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Scheduled Meetings',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : null,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        if (_loadingScheduledMeetings)
          const Center(child: CircularProgressIndicator())
        else
          ..._scheduledMeetings.map((meeting) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.medium),
                child: _buildScheduledMeetingCard(meeting),
              )),
      ],
    );
  }

  Widget _buildScheduledMeetingCard(Map<String, dynamic> meeting) {
    final isMobile = MediaQuery.of(context).size.width < 800;
    final scheduledStart = DateTime.parse(meeting['scheduled_start'] as String);
    final now = DateTime.now();
    final timeUntil = scheduledStart.difference(now);
    final canJoin = timeUntil.isNegative || timeUntil.inSeconds <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule,
                  color: AppColors.warmBrown, size: isMobile ? 20 : 24),
              SizedBox(width: isMobile ? AppSpacing.tiny : AppSpacing.small),
              Expanded(
                child: Text(
                  meeting['title'] as String? ?? 'Untitled Meeting',
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 16 : null,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? AppSpacing.tiny : AppSpacing.small),
          Text(
            'Scheduled for: ${_formatDateTime(scheduledStart)}',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: isMobile ? 13 : null,
            ),
          ),
          if (!canJoin) ...[
            SizedBox(height: isMobile ? AppSpacing.tiny : AppSpacing.small),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 10 : 12,
                vertical: isMobile ? 4 : 6,
              ),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Starts in: ${_formatCountdown(timeUntil)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w600,
                  fontSize: isMobile ? 11 : null,
                ),
              ),
            ),
          ],
          SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: canJoin ? () => _joinScheduledMeeting(meeting) : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canJoin ? AppColors.warmBrown : AppColors.borderPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                canJoin ? 'Join Meeting' : 'Waiting for meeting to start...',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.month}/${dateTime.day}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCountdown(Duration duration) {
    if (duration.isNegative) return 'Meeting started';

    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (days > 0) {
      return '$days day${days != 1 ? 's' : ''}, $hours hour${hours != 1 ? 's' : ''}';
    } else if (hours > 0) {
      return '$hours hour${hours != 1 ? 's' : ''}, $minutes minute${minutes != 1 ? 's' : ''}';
    } else if (minutes > 0) {
      return '$minutes minute${minutes != 1 ? 's' : ''}, $seconds second${seconds != 1 ? 's' : ''}';
    } else {
      return '$seconds second${seconds != 1 ? 's' : ''}';
    }
  }

  Future<void> _joinScheduledMeeting(Map<String, dynamic> meeting) async {
    try {
      final meetingId = (meeting['id'] ?? '').toString();
      final roomName = meeting['room_name'] as String;
      final liveKitUrl = ApiService()
          .getLiveKitUrl()
          .replaceAll('ws://', 'http://')
          .replaceAll('wss://', 'https://');
      final meetingLink = '$liveKitUrl/meeting/$roomName';

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingCreatedScreen(
              meetingId: meetingId,
              meetingLink: meetingLink,
              isInstant: false,
              scheduledStart:
                  DateTime.parse(meeting['scheduled_start'] as String),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join meeting: $e')),
        );
      }
    }
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
    final isMobile = MediaQuery.of(context).size.width < 800;
    final iconSize = isMobile ? 50.0 : 70.0;
    final iconInnerSize = isMobile ? 28.0 : 40.0;
    final cardPadding = isMobile ? AppSpacing.medium : AppSpacing.large;

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
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
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
                  color: _isHovered ? Colors.white : AppColors.warmBrown,
                  size: iconInnerSize,
                ),
              ),
              SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.medium),
              Flexible(
                child: Text(
                  widget.title,
                  style: AppTypography.heading4.copyWith(
                    color: _isHovered ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 16 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) ...[
                SizedBox(height: isMobile ? AppSpacing.tiny : AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isMobile ? 12 : null,
                      ),
                    ),
                    SizedBox(
                        width:
                            isMobile ? AppSpacing.tiny / 2 : AppSpacing.tiny),
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
