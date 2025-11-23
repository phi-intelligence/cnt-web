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
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Row 1: Instant Meeting & Schedule Meeting
                      Row(
                        children: [
                          Expanded(
                            child: _buildOptionCard(
                              title: 'Instant Meeting',
                              icon: Icons.video_call,
                              onTap: () async {
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
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: _buildOptionCard(
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
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: AppSpacing.medium),
                      
                      // Row 2: Join Meeting
                      _buildOptionCard(
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
                        isFullWidth: true,
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
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          color: AppColors.primaryMain.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: AppColors.primaryMain.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryMain.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.primaryMain,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              title,
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

