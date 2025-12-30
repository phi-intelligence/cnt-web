import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/auth_provider.dart';
import 'meeting_created_screen.dart';

/// Scheduled Meetings List Screen
/// Shows all scheduled meetings created by the current user
class ScheduledMeetingsListScreen extends StatefulWidget {
  const ScheduledMeetingsListScreen({super.key});

  @override
  State<ScheduledMeetingsListScreen> createState() => _ScheduledMeetingsListScreenState();
}

class _ScheduledMeetingsListScreenState extends State<ScheduledMeetingsListScreen> {
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
      final userId = currentUser?['id'];

      print('🔍 Fetching scheduled meetings for user ID: $userId');

      if (userId == null) {
        print('⚠️ No user ID found');
        setState(() {
          _scheduledMeetings = [];
          _loadingScheduledMeetings = false;
        });
        return;
      }

      // Fetch all streams
      final streams = await ApiService().listStreams();
      print('📊 Fetched ${streams.length} total streams');

      // Filter for scheduled meetings by current user
      final now = DateTime.now();
      final scheduled = <Map<String, dynamic>>[];

      for (final stream in streams) {
        final hostId = stream['host_id'];
        final scheduledStart = stream['scheduled_start'];

        // Convert host_id to int for comparison
        int? hostIdInt;
        if (hostId is int) {
          hostIdInt = hostId;
        } else if (hostId is String) {
          hostIdInt = int.tryParse(hostId);
        }

        // Check if this is the user's meeting
        if (hostIdInt != userId) {
          continue;
        }

        // Check if scheduled_start exists
        if (scheduledStart == null) {
          continue;
        }

        // Parse scheduled_start (handle both string and datetime)
        DateTime? scheduledDate;
        try {
          if (scheduledStart is String) {
            scheduledDate = DateTime.parse(scheduledStart);
          } else if (scheduledStart is DateTime) {
            scheduledDate = scheduledStart;
          } else {
            continue;
          }
        } catch (e) {
          print('⚠️ Error parsing scheduled_start: $e');
          continue;
        }

        // Only show future scheduled meetings
        if (!scheduledDate.isAfter(now)) {
          continue;
        }

        // Add to list
        scheduled.add(stream);
        print('✅ Found scheduled meeting: ${stream['title']} at $scheduledDate');
      }

      // Sort by scheduled_start (earliest first)
      scheduled.sort((a, b) {
        DateTime aDate;
        DateTime bDate;

        try {
          final aStart = a['scheduled_start'];
          final bStart = b['scheduled_start'];

          if (aStart is String) {
            aDate = DateTime.parse(aStart);
          } else if (aStart is DateTime) {
            aDate = aStart;
          } else {
            return 0;
          }

          if (bStart is String) {
            bDate = DateTime.parse(bStart);
          } else if (bStart is DateTime) {
            bDate = bStart;
          } else {
            return 0;
          }

          return aDate.compareTo(bDate);
        } catch (e) {
          return 0;
        }
      });

      print('✅ Found ${scheduled.length} scheduled meetings');

      if (mounted) {
        setState(() {
          _scheduledMeetings = scheduled;
          _loadingScheduledMeetings = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching scheduled meetings: $e');
      if (mounted) {
        setState(() {
          _loadingScheduledMeetings = false;
        });
      }
    }
  }

  Future<void> _joinScheduledMeeting(Map<String, dynamic> meeting) async {
    try {
      final meetingId = (meeting['id'] ?? '').toString();
      final roomName = meeting['room_name'] as String;
      final liveKitUrl = ApiService().getLiveKitUrl()
          .replaceAll('ws://', 'http://')
          .replaceAll('wss://', 'https://');
      final meetingLink = '$liveKitUrl/meeting/$roomName';
      
      // Parse scheduled_start
      DateTime? scheduledStart;
      final scheduledStartValue = meeting['scheduled_start'];
      if (scheduledStartValue is String) {
        scheduledStart = DateTime.parse(scheduledStartValue);
      } else if (scheduledStartValue is DateTime) {
        scheduledStart = scheduledStartValue;
      }
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingCreatedScreen(
              meetingId: meetingId,
              meetingLink: meetingLink,
              isInstant: false,
              scheduledStart: scheduledStart,
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

  Widget _buildScheduledMeetingCard(Map<String, dynamic> meeting) {
    // Parse scheduled_start (handle both string and datetime)
    DateTime scheduledStart;
    try {
      final scheduledStartValue = meeting['scheduled_start'];
      if (scheduledStartValue is String) {
        scheduledStart = DateTime.parse(scheduledStartValue);
      } else if (scheduledStartValue is DateTime) {
        scheduledStart = scheduledStartValue;
      } else {
        return const SizedBox.shrink();
      }
    } catch (e) {
      print('Error parsing scheduled_start in card: $e');
      return const SizedBox.shrink();
    }

    final now = DateTime.now();
    final timeUntil = scheduledStart.difference(now);
    final canJoin = timeUntil.isNegative || timeUntil.inSeconds <= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.large),
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
              Icon(Icons.schedule, color: AppColors.warmBrown, size: 24),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Text(
                  meeting['title'] as String? ?? 'Untitled Meeting',
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Scheduled for: ${_formatDateTime(scheduledStart)}',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          if (!canJoin) ...[
            const SizedBox(height: AppSpacing.small),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Starts in: ${_formatCountdown(timeUntil)}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.medium),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

    if (isMobile) {
      return _buildMobileLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                label: Text('Back', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
              ),
              const SizedBox(height: AppSpacing.large),
              
              // Title
              Text(
                'My Scheduled Meetings',
                style: AppTypography.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              
              // Content
              Expanded(
                child: _loadingScheduledMeetings
                    ? const Center(child: CircularProgressIndicator())
                    : _scheduledMeetings.isEmpty
                        ? _buildEmptyState()
                        : SingleChildScrollView(
                            child: Column(
                              children: _scheduledMeetings.map((meeting) => 
                                _buildScheduledMeetingCard(meeting)
                              ).toList(),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Scheduled Meetings',
          style: AppTypography.heading2.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: _loadingScheduledMeetings
              ? const Center(child: CircularProgressIndicator())
              : _scheduledMeetings.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _fetchScheduledMeetings,
                      child: ListView(
                        children: _scheduledMeetings.map((meeting) => 
                          _buildScheduledMeetingCard(meeting)
                        ).toList(),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.large),
          Text(
            'No Scheduled Meetings',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'Schedule a meeting to see it here',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

