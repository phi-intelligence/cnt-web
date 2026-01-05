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
import '../../services/logger_service.dart';

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
      LoggerService.e('❌ Error fetching streams: $e');
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      resizeToAvoidBottomInset: false,
      body: SizedBox(
        width: double.infinity,
        height: screenHeight,
        child: Stack(
          children: [
            // Background image positioned to the right
            Positioned(
              top: isMobile ? -30 : 0,
              bottom: isMobile ? null : 0,
              right: isMobile ? -screenWidth * 0.4 : -50,
              height: isMobile ? screenHeight * 0.6 : null,
              width: isMobile ? screenWidth * 1.3 : screenWidth * 0.65,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/images/jesus-teaching.png'),
                    fit: isMobile ? BoxFit.contain : BoxFit.cover,
                    alignment: isMobile ? Alignment.topRight : Alignment.centerRight,
                  ),
                ),
              ),
            ),
            
            // Gradient overlay from left
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: isMobile
                        ? [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.98),
                            const Color(0xFFF5F0E8).withOpacity(0.85),
                            const Color(0xFFF5F0E8).withOpacity(0.4),
                            Colors.transparent,
                          ]
                        : [
                            const Color(0xFFF5F0E8),
                            const Color(0xFFF5F0E8).withOpacity(0.99),
                            const Color(0xFFF5F0E8).withOpacity(0.95),
                            const Color(0xFFF5F0E8).withOpacity(0.7),
                            const Color(0xFFF5F0E8).withOpacity(0.3),
                            Colors.transparent,
                          ],
                    stops: isMobile
                        ? const [0.0, 0.2, 0.4, 0.6, 0.8]
                        : const [0.0, 0.25, 0.4, 0.5, 0.6, 0.75],
                  ),
                ),
              ),
            ),
            
            // Content positioned centered/right-aligned
            Positioned(
              left: isMobile ? 0 : (screenWidth * 0.15),
              top: 0,
              bottom: 0,
              right: 0,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: EdgeInsets.only(
                        left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                        right: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                        top: isMobile ? 20 : 40,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Live Streams',
                                  style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 28 : (isTablet ? 36 : 42),
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.small),
                                Text(
                                  'Watch and join live streams',
                                  style: AppTypography.getResponsiveBody(context).copyWith(
                                    color: AppColors.primaryDark.withOpacity(0.7),
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppSpacing.medium),
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
                    
                    SizedBox(height: AppSpacing.large),
                    
                    // Tabs with brown underline indicator
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                      ),
                      child: Container(
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
                    ),
                    
                    // Tab Content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                          vertical: AppSpacing.medium,
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLiveStreams(),
                            _buildUpcomingStreams(),
                            _buildPastStreams(),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isMobile
                ? _buildMobileCardContent(
                    stream: stream,
                    status: status,
                    statusColor: statusColor,
                    statusIcon: statusIcon,
                    onAction: onAction,
                    actionLabel: actionLabel,
                  )
                : _buildDesktopCardContent(
                    stream: stream,
                    status: status,
                    statusColor: statusColor,
                    statusIcon: statusIcon,
                    onAction: onAction,
                    actionLabel: actionLabel,
                  ),
          ),
        ],
      ),
    );
  }

  // Mobile layout (Column)
  Widget _buildMobileCardContent({
    required Map<String, dynamic> stream,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status badge and icon row
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
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
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
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
        const SizedBox(height: AppSpacing.medium),
        // Title
        Text(
          stream['title'] ?? 'Untitled Stream',
          style: AppTypography.heading4.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: AppSpacing.tiny),
        // Host
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
        const SizedBox(height: AppSpacing.medium),
        // Full-width button
        SizedBox(
          width: double.infinity,
          child: StyledPillButton(
            label: actionLabel,
            icon: Icons.play_arrow,
            onPressed: onAction,
          ),
        ),
      ],
    );
  }

  // Desktop layout (Row) - existing layout
  Widget _buildDesktopCardContent({
    required Map<String, dynamic> stream,
    required String status,
    required Color statusColor,
    required IconData statusIcon,
    required VoidCallback onAction,
    required String actionLabel,
  }) {
    return Row(
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

