import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_grid_delegate.dart';
import '../widgets/web/styled_page_header.dart';
import '../widgets/web/section_container.dart';
import '../widgets/web/styled_pill_button.dart';

class LiveStreamingScreen extends StatefulWidget {
  const LiveStreamingScreen({super.key});

  @override
  State<LiveStreamingScreen> createState() => _LiveStreamingScreenState();
}

class _LiveStreamingScreenState extends State<LiveStreamingScreen> with SingleTickerProviderStateMixin {
  int _selectedTab = 0;
  late TabController _tabController;
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
                    icon: Icons.videocam_rounded,
                    onPressed: () => _showCreateStreamDialog(context),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              
              // Tabs
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(color: AppColors.borderPrimary),
                ),
                child: TabBar(
                  controller: _tabController,
                  onTap: (index) => setState(() => _selectedTab = index),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    color: AppColors.warmBrown,
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
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
      // Mobile version
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: Text(
            'Live Streams',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textPrimary),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: StyledPillButton(
                onPressed: () => _showCreateStreamDialog(context),
                icon: Icons.videocam_rounded,
                label: 'Go Live',
                size: StyledPillButtonSize.small,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Tabs
            Container(
              margin: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(color: AppColors.borderPrimary),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (index) => setState(() => _selectedTab = index),
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textSecondary,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  color: AppColors.warmBrown,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                padding: EdgeInsets.zero,
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
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: card,
        );
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
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: card,
        );
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
            padding: const EdgeInsets.only(bottom: AppSpacing.medium),
            child: card,
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.medium),
          child: card,
        );
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MockLiveStreamViewer(streamId: streamId),
      ),
    );
  }

  void _setReminder(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder set!'),
        backgroundColor: AppColors.warmBrown,
      ),
    );
  }

  void _watchReplay(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => _MockVideoPlayerWidget()),
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
    
    // Content structure
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
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Icon(Icons.videocam_rounded, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            ),
            if (isLive)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.errorMain,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.errorMain.withOpacity(0.4),
                        blurRadius: 8,
                      ),
                    ],
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
          padding: EdgeInsets.all(AppSpacing.medium),
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
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              if (scheduledTime != null) ...[
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Starts: ${scheduledTime!.toString().split('.')[0]}',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
              if (duration != null) ...[
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  'Duration: ${duration!.inHours}h ${duration!.inMinutes.remainder(60)}m',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    // Wrapper
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: cardContent,
        ),
      ),
    );
  }
}

class _CreateStreamDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Live Stream',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
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
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                alignLabelWithHint: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.large, vertical: AppSpacing.medium),
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
                  icon: Icons.videocam_rounded,
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

class _MockLiveStreamViewer extends StatelessWidget {
  final int streamId;

  const _MockLiveStreamViewer({required this.streamId});

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
                    child: Text(
                      'Chat',
                      style: AppTypography.heading4.copyWith(color: Colors.white),
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
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide(color: AppColors.warmBrown),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.send_rounded, color: Colors.white),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                    onPressed: () {},
                  ),
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
            style: TextStyle(
              color: AppColors.warmBrown,
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

class _MockVideoPlayerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(child: Text('Video Player', style: TextStyle(color: Colors.white))),
    );
  }
}
