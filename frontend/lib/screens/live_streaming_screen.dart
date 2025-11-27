import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_grid_delegate.dart';
import '../widgets/web/styled_page_header.dart';
import '../widgets/web/section_container.dart';
import '../widgets/web/styled_pill_button.dart';
import 'live/live_stream_viewer.dart';
// TODO: Consider Jitsi Meet integration for live streaming if needed

class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late TabController _tabController;
  // TODO: Add participant list when implementing live streaming
  final List<dynamic> _participants = [];
  bool _isHost = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with design system
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
                  StyledPageHeader(
                    title: 'Live Streams',
                    size: StyledPageHeaderSize.h1,
                  ),
                  StyledPillButton(
                    label: 'Go Live',
                    icon: Icons.videocam,
                    onPressed: () => _showCreateStreamDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundSecondary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() => _selectedTab = index),
                  labelColor: AppColors.primaryMain,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorColor: AppColors.primaryMain,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Live Now'),
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              
              // Content based on selected tab
              Expanded(
                child: IndexedStack(
                  index: _selectedTab,
                  children: [
                    _buildLiveNowTab(),
                    _buildUpcomingTab(),
                    _buildPastTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        appBar: AppBar(
          title: const Text('Live Streams'),
          actions: [
            ElevatedButton.icon(
              onPressed: () => _showCreateStreamDialog(context),
              icon: const Icon(Icons.videocam),
              label: const Text('Go Live'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Column(
          children: [
            // Tabs
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TabBar(
                controller: _tabController,
                onTap: (index) => setState(() => _selectedTab = index),
                labelColor: Colors.red,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.red,
                tabs: const [
                  Tab(text: 'Live Now'),
                  Tab(text: 'Upcoming'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
            
            // Content based on selected tab
            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: [
                  _buildLiveNowTab(),
                  _buildUpcomingTab(),
                  _buildPastTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLiveNowTab() {
    final isWeb = kIsWeb;
    return ListView.builder(
      padding: EdgeInsets.all(isWeb ? 0 : AppSpacing.medium),
      itemCount: 3, // Sample data
      itemBuilder: (context, index) {
        final card = _StreamCard(
          title: 'Sunday Service ${index + 1}',
          host: 'Pastor John',
          viewerCount: 120 + index * 15,
          isLive: true,
          onTap: () => _joinStream(context, index),
        );
        if (isWeb) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return card;
      },
    );
  }

  Widget _buildUpcomingTab() {
    final isWeb = kIsWeb;
    return ListView.builder(
      padding: EdgeInsets.all(isWeb ? 0 : AppSpacing.medium),
      itemCount: 5,
      itemBuilder: (context, index) {
        final card = _StreamCard(
          title: 'Upcoming Event ${index + 1}',
          host: 'Speaker Name',
          scheduledTime: DateTime.now().add(Duration(days: index + 1)),
          isLive: false,
          onTap: () => _setReminder(context),
        );
        if (isWeb) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return card;
      },
    );
  }

  Widget _buildPastTab() {
    final isWeb = kIsWeb;
    return ListView.builder(
      padding: EdgeInsets.all(isWeb ? 0 : AppSpacing.medium),
      itemCount: 10,
      itemBuilder: (context, index) {
        final card = _StreamCard(
          title: 'Past Stream ${index + 1}',
          host: 'Speaker Name',
          isLive: false,
          hasRecording: true,
          duration: const Duration(hours: 1, minutes: 30),
          onTap: () => _watchReplay(context),
        );
        if (isWeb) {
          return Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return card;
      },
    );
  }

  void _showCreateStreamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateStreamDialog(),
    );
  }

  Future<void> _joinStream(BuildContext context, int streamId) async {
    // TODO: Implement Jitsi Meet room join for live streaming
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LiveStreamViewer(streamId: streamId),
      ),
    );
  }

  void _setReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder set!')),
    );
  }

  void _watchReplay(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VideoPlayerWidget()),
    );
  }
}

class _StreamCard extends StatelessWidget {
  final String title;
  final String host;
  final int? viewerCount;
  final bool isLive;
  final DateTime? scheduledTime;
  final bool? hasRecording;
  final Duration? duration;
  final VoidCallback onTap;

  const _StreamCard({
    required this.title,
    required this.host,
    this.viewerCount,
    required this.isLive,
    this.scheduledTime,
    this.hasRecording,
    this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isWeb = kIsWeb;
    final cardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thumbnail
        Stack(
          children: [
            Container(
              height: isWeb ? 250 : 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.backgroundTertiary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isWeb ? AppSpacing.radiusLarge : 4),
                  topRight: Radius.circular(isWeb ? AppSpacing.radiusLarge : 4),
                ),
              ),
              child: Icon(Icons.videocam, size: 60, color: AppColors.textTertiary),
            ),
            if (isLive)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        
        // Info
        Padding(
          padding: EdgeInsets.all(isWeb ? AppSpacing.medium : 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                host,
                style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              ),
              if (viewerCount != null) ...[
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  '$viewerCount viewers',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
              if (scheduledTime != null) ...[
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Starts: ${scheduledTime!.toString().split('.')[0]}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
              if (duration != null) ...[
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Duration: ${duration!.inHours}h ${duration!.inMinutes.remainder(60)}m',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (isWeb) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SectionContainer(
          showShadow: true,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            child: cardContent,
          ),
        ),
      );
    } else {
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          child: cardContent,
        ),
      );
    }
  }
}

class _CreateStreamDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.extraLarge),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Live Stream',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            TextField(
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Stream Title',
                labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            
            TextField(
              maxLines: 3,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: AppTypography.body.copyWith(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.backgroundPrimary,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                  borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: AppTypography.button.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.medium),
                StyledPillButton(
                  label: 'Start Stream',
                  icon: Icons.videocam,
                  onPressed: () {
                    Navigator.pop(context);
                    // TODO: Create stream
                  },
                  variant: StyledPillButtonVariant.filled,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiveStreamViewer extends StatelessWidget {
  final int streamId;

  const LiveStreamViewer({super.key, required this.streamId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video Player
          Center(
            child: Container(
              color: Colors.grey[900],
              child: const Icon(Icons.play_circle_outline, size: 100, color: Colors.white),
            ),
          ),
          
          // Chat Panel (Right side)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 300,
              color: Colors.black.withOpacity(0.8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: const Text(
                      'Chat',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: 20,
                      itemBuilder: (context, index) {
                        return _ChatMessage(
                          username: 'User ${index + 1}',
                          message: 'This is a sample chat message ${index + 1}',
                        );
                      },
                    ),
                  ),
                  
                  // Message Input
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: const TextStyle(color: Colors.grey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Top Controls
          Positioned(
            top: 40,
            left: 16,
            right: 316,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.minimize, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String username;
  final String message;

  const _ChatMessage({
    required this.username,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            username,
            style: const TextStyle(
              color: Colors.blue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            message,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Video Player')),
    );
  }
}

