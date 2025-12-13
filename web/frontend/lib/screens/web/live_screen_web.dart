import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/api_service.dart';
import '../../screens/live/live_stream_viewer.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Live Screen - Live streams with tabs
class LiveScreenWeb extends StatefulWidget {
  const LiveScreenWeb({super.key});

  @override
  State<LiveScreenWeb> createState() => _LiveScreenWebState();
}

class _LiveScreenWebState extends State<LiveScreenWeb> with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _liveStreams = [];
  List<Map<String, dynamic>> _upcomingStreams = [];
  List<Map<String, dynamic>> _pastStreams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchStreams();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStreams() async {
    setState(() => _isLoading = true);
    try {
      final allStreams = await _api.listStreams();
      setState(() {
        _liveStreams = allStreams.where((s) => s['status'] == 'live').toList();
        _upcomingStreams = allStreams.where((s) => s['status'] == 'scheduled').toList();
        _pastStreams = allStreams.where((s) => s['status'] == 'ended').toList();
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching streams: $e');
      setState(() => _isLoading = false);
    }
  }

  void _joinStream(Map<String, dynamic> stream) {
    // TODO: Get proper token and server URL from API
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewer(
          streamId: stream['id'].toString(),
          roomName: stream['room_name'] ?? stream['id'].toString(),
          streamTitle: stream['title'] ?? 'Live Stream',
          token: stream['token'] ?? '',
          serverUrl: stream['server_url'] ?? 'wss://livekit-server',
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
            // Header with gradient background
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.extraLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown,
                    AppColors.warmBrown.withOpacity(0.85),
                    AppColors.primaryMain.withOpacity(0.9),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Live Streams',
                    style: AppTypography.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  StyledPillButton(
                    label: 'Go Live',
                    icon: Icons.videocam,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Create stream coming soon')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Tabs with brown underline indicator
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.borderPrimary,
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: AppColors.warmBrown,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.warmBrown,
                indicatorWeight: 3,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'Live Now'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildLiveStreams(),
                  _buildUpcomingStreams(),
                  _buildPastStreams(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamCard({
    required Map<String, dynamic> stream,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.large),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background image with gradient overlay
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: const AssetImage('assets/images/jesus-walking.png'),
                  fit: BoxFit.cover,
                  opacity: 0.15,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown.withOpacity(0.1),
                    AppColors.accentMain.withOpacity(0.05),
                    Colors.white,
                  ],
                ),
              ),
            ),
          ),
          // Content overlay
          Container(
            padding: EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon section
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(width: AppSpacing.large),
                // Content section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.medium,
                              vertical: AppSpacing.tiny,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              status,
                              style: AppTypography.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        stream['title'] ?? 'Untitled Stream',
                        style: AppTypography.heading4.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.tiny),
                      Text(
                        stream['host_name'] ?? 'Host',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (stream['scheduled_start'] != null) ...[
                        const SizedBox(height: AppSpacing.tiny),
                        Text(
                          'Scheduled: ${stream['scheduled_start']}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                // Action button
                StyledPillButton(
                  label: actionLabel,
                  icon: Icons.play_arrow,
                  onPressed: onAction,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStreams() {
    if (_isLoading) {
      return ListView.builder(
        itemCount: 3,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.medium),
            child: const LoadingShimmer(width: double.infinity, height: 200),
          );
        },
      );
    }

    if (_liveStreams.isEmpty) {
      return const EmptyState(
        icon: Icons.radio,
        title: 'No Live Streams',
        message: 'Check back later for live content',
      );
    }

    return ListView.builder(
      itemCount: _liveStreams.length,
      itemBuilder: (context, index) {
        final stream = _liveStreams[index];
        return _buildStreamCard(
          stream: stream,
          status: 'LIVE',
          statusColor: AppColors.errorMain,
          statusIcon: Icons.videocam,
          onAction: () => _joinStream(stream),
          actionLabel: 'Join',
        );
      },
    );
  }

  Widget _buildUpcomingStreams() {
    if (_upcomingStreams.isEmpty) {
      return const EmptyState(
        icon: Icons.schedule,
        title: 'No Upcoming Streams',
        message: 'Check back later for scheduled streams',
      );
    }

    return ListView.builder(
      itemCount: _upcomingStreams.length,
      itemBuilder: (context, index) {
        final stream = _upcomingStreams[index];
        return _buildStreamCard(
          stream: stream,
          status: 'UPCOMING',
          statusColor: AppColors.warmBrown,
          statusIcon: Icons.schedule,
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stream not started yet')),
            );
          },
          actionLabel: 'View Details',
        );
      },
    );
  }

  Widget _buildPastStreams() {
    if (_pastStreams.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No Past Streams',
        message: 'Past streams will appear here',
      );
    }

    return ListView.builder(
      itemCount: _pastStreams.length,
      itemBuilder: (context, index) {
        final stream = _pastStreams[index];
        return _buildStreamCard(
          stream: stream,
          status: 'ENDED',
          statusColor: AppColors.textSecondary,
          statusIcon: Icons.history,
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Stream replay coming soon')),
            );
          },
          actionLabel: 'Watch Replay',
        );
      },
    );
  }
}

