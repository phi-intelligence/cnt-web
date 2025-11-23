import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
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
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
                Text(
                  'Live Streams',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Navigate to create stream
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Create stream coming soon')),
                    );
                  },
                  icon: const Icon(Icons.videocam),
                  label: const Text('Go Live'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorMain,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primaryMain,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primaryMain,
              tabs: const [
                Tab(text: 'Live Now'),
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
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
        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.medium),
          child: ListTile(
            leading: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.videocam, color: AppColors.errorMain, size: 40),
            ),
            title: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorMain,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stream['title'] ?? 'Untitled Stream',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              stream['host_name'] ?? 'Host',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            trailing: ElevatedButton(
              onPressed: () => _joinStream(stream),
              child: const Text('Join'),
            ),
            onTap: () => _joinStream(stream),
          ),
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
        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.medium),
          child: ListTile(
            leading: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.schedule, color: AppColors.primaryMain, size: 40),
            ),
            title: Text(
              stream['title'] ?? 'Untitled Stream',
              style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stream['host_name'] ?? 'Host'),
                if (stream['scheduled_start'] != null)
                  Text(
                    'Scheduled: ${stream['scheduled_start']}',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
            trailing: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stream not started yet')),
                );
              },
              child: const Text('View Details'),
            ),
          ),
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
        return Card(
          margin: EdgeInsets.only(bottom: AppSpacing.medium),
          child: ListTile(
            leading: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.history, color: AppColors.textSecondary, size: 40),
            ),
            title: Text(
              stream['title'] ?? 'Untitled Stream',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(stream['host_name'] ?? 'Host'),
            trailing: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to replay
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Stream replay coming soon')),
                );
              },
              child: const Text('Watch Replay'),
            ),
          ),
        );
      },
    );
  }
}

