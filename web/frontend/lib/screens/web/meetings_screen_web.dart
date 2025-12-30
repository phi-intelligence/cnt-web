import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/api_service.dart';
import '../../screens/meeting/meeting_room_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';
import '../../services/logger_service.dart';

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
      LoggerService.e('❌ Error loading meetings: $e');
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
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                StyledPageHeader(
                  title: 'Meetings',
                  size: StyledPageHeaderSize.h1,
                ),
                StyledPillButton(
                  label: 'Create Meeting',
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.pushNamed(context, '/create-meeting');
                  },
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
                      ? SectionContainer(
                          showShadow: true,
                          child: const EmptyState(
                            icon: Icons.calendar_today,
                            title: 'No Meetings',
                            message: 'Create a meeting to get started',
                          ),
                        )
                      : ListView.builder(
                          itemCount: _meetings.length,
                          itemBuilder: (context, index) {
                            final meeting = _meetings[index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.medium),
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: SectionContainer(
                                  showShadow: true,
                                  child: InkWell(
                                    onTap: () => _joinMeeting(meeting),
                                    borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                                    child: Padding(
                                      padding: EdgeInsets.all(AppSpacing.medium),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryMain.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                            ),
                                            child: Icon(
                                              Icons.video_call,
                                              color: AppColors.primaryMain,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.medium),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  meeting['title'] ?? 'Untitled Meeting',
                                                  style: AppTypography.heading4.copyWith(
                                                    color: AppColors.textPrimary,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (meeting['description'] != null && meeting['description'].toString().isNotEmpty) ...[
                                                  const SizedBox(height: AppSpacing.tiny),
                                                  Text(
                                                    meeting['description'],
                                                    style: AppTypography.body.copyWith(
                                                      color: AppColors.textSecondary,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ],
                                                if (meeting['scheduled_start'] != null) ...[
                                                  const SizedBox(height: AppSpacing.tiny),
                                                  Text(
                                                    'Scheduled: ${meeting['scheduled_start']}',
                                                    style: AppTypography.bodySmall.copyWith(
                                                      color: AppColors.textTertiary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.medium),
                                          StyledPillButton(
                                            label: 'Join',
                                            icon: Icons.login,
                                            onPressed: () => _joinMeeting(meeting),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
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

