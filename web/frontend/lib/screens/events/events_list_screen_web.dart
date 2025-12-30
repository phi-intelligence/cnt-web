import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_pill_button.dart';
import 'event_create_screen_web.dart';
import 'event_detail_screen_web.dart';

class EventsListScreenWeb extends StatefulWidget {
  const EventsListScreenWeb({super.key});

  @override
  State<EventsListScreenWeb> createState() => _EventsListScreenWebState();
}

class _EventsListScreenWebState extends State<EventsListScreenWeb>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<EventProvider>();
    await provider.fetchEvents(refresh: true, upcomingOnly: false);
    await provider.fetchMyHostedEvents();
    await provider.fetchMyAttendingEvents();
    await provider.fetchPastEvents(refresh: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth > 1200;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // Hero Section
          SliverToBoxAdapter(
            child: _buildHeroSection(isMobile, isTablet),
          ),

          // Tabs
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverTabBarDelegate(
              TabBar(
                controller: _tabController,
                labelColor: AppColors.warmBrown,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.warmBrown,
                indicatorWeight: 3,
                labelStyle: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const [
                  Tab(text: 'All Events'),
                  Tab(text: 'My Events'),
                  Tab(text: 'Attending'),
                  Tab(text: 'Past Events'),
                ],
              ),
              backgroundColor: AppColors.backgroundPrimary,
            ),
          ),

          // Content
          Consumer<EventProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.warmBrown),
                  ),
                );
              }

              final events = _getCurrentEvents(provider);

              if (events.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(
                    _getEmptyTitle(),
                    _getEmptySubtitle(),
                  ),
                );
              }

              return SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isMobile ? AppSpacing.medium : (isLargeScreen ? 64 : 32),
                  vertical: AppSpacing.large,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.medium),
                        child: _buildCompactEventCard(
                            events[index], isLargeScreen),
                      );
                    },
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: _navigateToCreate,
              backgroundColor: AppColors.warmBrown,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  List<EventModel> _getCurrentEvents(EventProvider provider) {
    switch (_tabController.index) {
      case 0:
        return provider.events;
      case 1:
        return provider.myHostedEvents;
      case 2:
        return provider.myAttendingEvents;
      case 3:
        return provider.pastEvents;
      default:
        return provider.events;
    }
  }

  String _getEmptyTitle() {
    switch (_tabController.index) {
      case 1:
        return 'No hosted events';
      case 2:
        return 'Not attending any events';
      case 3:
        return 'No past events';
      default:
        return 'No events found';
    }
  }

  String _getEmptySubtitle() {
    switch (_tabController.index) {
      case 1:
        return 'Create your first event and invite the community!';
      case 2:
        return 'Browse events and request to join!';
      case 3:
        return 'Past events will appear here once they\'ve concluded.';
      default:
        return 'Be the first to create a community event!';
    }
  }

  Future<void> _navigateToCreate() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventCreateScreenWeb()),
    );
    if (result != null) {
      _loadData();
    }
  }

  Widget _buildHeroSection(bool isMobile, bool isTablet) {
    return Container(
      height: isMobile ? 250 : (isTablet ? 350 : 400),
      width: double.infinity,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/Jesus-crowd.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center, // Better alignment
        ),
      ),
      child: Stack(
        children: [
          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  AppColors.backgroundPrimary
                      .withOpacity(0.95), // More opaque start
                  AppColors.backgroundPrimary.withOpacity(0.8),
                  AppColors.backgroundPrimary.withOpacity(0.4),
                  AppColors.backgroundPrimary.withOpacity(0.1),
                ],
                stops: const [0.0, 0.4, 0.7, 1.0],
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? AppSpacing.large : 64,
              vertical: isMobile ? AppSpacing.medium : 48,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMobile) ...[
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                    color: AppColors.primaryDark,
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: AppSpacing.large),
                ],
                Text(
                  'Community Events',
                  style: isMobile
                      ? AppTypography.heading2
                          .copyWith(fontWeight: FontWeight.bold, fontSize: 24)
                      : (isTablet
                          ? AppTypography.heading1.copyWith(
                              fontWeight: FontWeight.bold, fontSize: 32)
                          : AppTypography.heroTitle.copyWith(
                              fontWeight: FontWeight.bold, height: 1.1)),
                ),
                const SizedBox(height: AppSpacing.medium),
                SizedBox(
                  width: isMobile ? double.infinity : 600,
                  child: Text(
                    'Join or host events to connect with the Christ-Centered community. Find fellowship, worship, and service opportunities.',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary.withOpacity(0.8),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                if (!isMobile)
                  StyledPillButton(
                    label: 'Host an Event',
                    icon: Icons.add,
                    onPressed: _navigateToCreate,
                  ),
              ],
            ),
          ),

          // Mobile Back Button
          if (isMobile)
            Positioned(
              top: 16,
              left: 16,
              child: SafeArea(
                child: CircleAvatar(
                  backgroundColor: AppColors.backgroundPrimary.withOpacity(0.8),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactEventCard(EventModel event, bool isLargeScreen) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final timeFormat = DateFormat('h:mm a');

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventDetailScreenWeb(eventId: event.id),
            ),
          );
        },
        child: Container(
          height:
              isMobile ? 90 : (isLargeScreen ? 110 : 100), // Responsive height
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24), // Less drastic than 50
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.borderPrimary.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Date Indicator
              Container(
                width: isMobile ? 70 : (isLargeScreen ? 90 : 80),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: event.isPast
                        ? [Colors.grey.shade300, Colors.grey.shade400]
                        : [
                            AppColors.warmBrown.withOpacity(0.1),
                            AppColors.warmBrown.withOpacity(0.2)
                          ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    bottomLeft: Radius.circular(24),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(event.eventDate).toUpperCase(),
                      style: TextStyle(
                        color: event.isPast ? Colors.grey : AppColors.warmBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.eventDate.day.toString(),
                      style: TextStyle(
                        color: event.isPast
                            ? Colors.grey.shade600
                            : AppColors.primaryDark,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Status Badge (Inline for compact)
                      if (event.isPast || event.isAttending) ...[
                        Row(
                          children: [
                            if (event.isPast)
                              _buildStatusText('Past', Colors.grey),
                            if (event.isAttending) ...[
                              if (event.isPast) const SizedBox(width: 8),
                              _buildStatusText(
                                event.myAttendanceStatus == 'approved'
                                    ? 'Going'
                                    : 'Pending',
                                event.myAttendanceStatus == 'approved'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                            const SizedBox(height: 6),
                          ],
                        ),
                      ],

                      Text(
                        event.title,
                        style: AppTypography.heading4.copyWith(
                          // Slightly bigger
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      // Time and location
                      Row(
                        children: [
                          Icon(Icons.access_time_filled,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            timeFormat.format(event.eventDate),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (event.location != null) ...[
                            const SizedBox(width: 16),
                            Icon(Icons.location_on,
                                size: 14, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Attendees & Arrow
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.people,
                              size: 16, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            '${event.attendeesCount}',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.warmBrown.withOpacity(0.5),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.backgroundSecondary,
              ),
              child: Icon(
                Icons.event_outlined,
                size: 40,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            StyledPillButton(
              label: 'Host an Event',
              icon: Icons.add,
              onPressed: _navigateToCreate,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  final Color backgroundColor;

  _SliverTabBarDelegate(this._tabBar, {required this.backgroundColor});

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.borderPrimary,
              width: 1,
            ),
          ),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
