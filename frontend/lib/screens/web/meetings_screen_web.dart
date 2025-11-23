import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../services/api_service.dart';
import '../../screens/meeting/meeting_room_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Meetings Screen - Meeting list and management
class MeetingsScreenWeb extends StatefulWidget {
  const MeetingsScreenWeb({super.key});

  @override
  State<MeetingsScreenWeb> createState() => _MeetingsScreenWebState();
}

class _MeetingsScreenWebState extends State<MeetingsScreenWeb> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _meetings = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    try {
      final streams = await _api.listStreams();
      setState(() {
        _meetings = streams;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading meetings: $e');
      setState(() => _isLoading = false);
    }
  }

  void _joinMeeting(Map<String, dynamic> meeting) {
    // TODO: Get proper JWT token and user name from API
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MeetingRoomScreen(
          meetingId: meeting['id'].toString(),
          roomName: meeting['title'] ?? 'Meeting',
          jwtToken: meeting['jwt_token'] ?? '',
          userName: meeting['user_name'] ?? 'User',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meetings',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/create-meeting');
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Create Meeting'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Meetings List
            Expanded(
              child: _isLoading
                  ? ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.medium),
                          child: const LoadingShimmer(width: double.infinity, height: 100),
                        );
                      },
                    )
                  : _meetings.isEmpty
                      ? const EmptyState(
                          icon: Icons.calendar_today,
                          title: 'No Meetings',
                          message: 'Create a meeting to get started',
                        )
                      : ListView.builder(
                          itemCount: _meetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _meetings[index];
                            return Card(
                              margin: EdgeInsets.only(bottom: AppSpacing.medium),
                              child: ListTile(
                                leading: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryMain.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.video_call,
                                    color: AppColors.primaryMain,
                                    size: 30,
                                  ),
                                ),
                                title: Text(
                                  meeting['title'] ?? 'Untitled Meeting',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(meeting['description'] ?? ''),
                                    if (meeting['scheduled_start'] != null)
                                      Text(
                                        'Scheduled: ${meeting['scheduled_start']}',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  onPressed: () => _joinMeeting(meeting),
                                  child: const Text('Join'),
                                ),
                                onTap: () => _joinMeeting(meeting),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

