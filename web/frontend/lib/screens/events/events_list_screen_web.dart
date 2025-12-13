import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';
import 'event_create_screen_web.dart';
import 'event_detail_screen_web.dart';

class EventsListScreenWeb extends StatefulWidget {
  const EventsListScreenWeb({super.key});

  @override
  State<EventsListScreenWeb> createState() => _EventsListScreenWebState();
}

class _EventsListScreenWebState extends State<EventsListScreenWeb> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<EventProvider>();
    await provider.fetchEvents(refresh: true, upcomingOnly: false);
    await provider.fetchMyHostedEvents();
    await provider.fetchMyAttendingEvents();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.backgroundPrimary,
            elevation: 0,
            pinned: true,
            expandedHeight: 160,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
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
                ),
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isLargeScreen ? 80 : (isMediumScreen ? 48 : 24),
                      60,
                      isLargeScreen ? 80 : (isMediumScreen ? 48 : 24),
                      20,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Community Events',
                                style: AppTypography.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Join or host events to connect with the community',
                                style: AppTypography.body.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Create Event Button
                        ElevatedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const EventCreateScreenWeb()),
                            );
                            if (result != null) {
                              _loadData();
                            }
                          },
                          icon: Icon(Icons.add, size: 20),
                          label: Text('Host Event'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.warmBrown,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(48),
              child: Container(
                color: AppColors.backgroundPrimary,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.warmBrown,
                  labelColor: AppColors.warmBrown,
                  unselectedLabelColor: AppColors.textSecondary,
                  indicatorWeight: 3,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: 'All Events'),
                    Tab(text: 'My Events'),
                    Tab(text: 'Attending'),
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          SliverFillRemaining(
            child: Consumer<EventProvider>(
              builder: (context, provider, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEventsList(
                      provider.events,
                      provider.isLoading,
                      'No events found',
                      'Be the first to create a community event!',
                      isLargeScreen,
                      isMediumScreen,
                    ),
                    _buildEventsList(
                      provider.myHostedEvents,
                      provider.isLoading,
                      'No hosted events',
                      'Create your first event and invite the community!',
                      isLargeScreen,
                      isMediumScreen,
                    ),
                    _buildEventsList(
                      provider.myAttendingEvents,
                      provider.isLoading,
                      'Not attending any events',
                      'Browse events and request to join!',
                      isLargeScreen,
                      isMediumScreen,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(
    List<EventModel> events,
    bool isLoading,
    String emptyTitle,
    String emptySubtitle,
    bool isLargeScreen,
    bool isMediumScreen,
  ) {
    if (isLoading && events.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.warmBrown,
        ),
      );
    }

    if (events.isEmpty) {
      return _buildEmptyState(emptyTitle, emptySubtitle);
    }

    final crossAxisCount = isLargeScreen ? 3 : (isMediumScreen ? 2 : 1);

    return RefreshIndicator(
      color: AppColors.warmBrown,
      onRefresh: _loadData,
      child: GridView.builder(
        padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 1.1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
        ),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(events[index]);
        },
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_busy,
                size: 56,
                color: AppColors.warmBrown,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const EventCreateScreenWeb()),
                );
                if (result != null) {
                  _loadData();
                }
              },
              icon: Icon(Icons.add),
              label: Text('Host an Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(EventModel event) {
    final dateFormat = DateFormat('EEE, MMM d');
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image or Date Header
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.warmBrown,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Stack(
                    children: [
                      // Cover image if available
                      if (event.coverImage != null && event.coverImage!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.network(
                            _apiService.getMediaUrl(event.coverImage!),
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.warmBrown,
                              child: Center(
                                child: Icon(Icons.event, color: Colors.white38, size: 40),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.warmBrown,
                                AppColors.warmBrown.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          child: Center(
                            child: Icon(Icons.event, color: Colors.white38, size: 40),
                          ),
                        ),
                      
                      // Date badge
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Text(
                                DateFormat('MMM').format(event.eventDate).toUpperCase(),
                                style: TextStyle(
                                  color: AppColors.warmBrown,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                event.eventDate.day.toString(),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Status badge
                      if (event.isPast)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              'Past',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                      else if (event.isAttending)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: event.myAttendanceStatus == 'approved'
                                  ? Colors.green.withOpacity(0.9)
                                  : Colors.orange.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              event.myAttendanceStatus == 'approved' ? 'Attending' : 'Pending',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              
              // Content
              Expanded(
                flex: 3,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: AppTypography.heading4.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      SizedBox(height: 8),
                      
                      // Time
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${dateFormat.format(event.eventDate)} at ${timeFormat.format(event.eventDate)}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      if (event.location != null) ...[
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 14,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      Spacer(),
                      
                      // Host and Attendees
                      Row(
                        children: [
                          // Host avatar
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AppColors.warmBrown.withOpacity(0.2),
                            backgroundImage: event.host?.avatar != null && event.host!.avatar!.isNotEmpty
                                ? NetworkImage(_apiService.getMediaUrl(event.host!.avatar!))
                                : null,
                            child: event.host?.avatar == null || event.host!.avatar!.isEmpty
                                ? Icon(
                                    Icons.person,
                                    size: 14,
                                    color: AppColors.warmBrown,
                                  )
                                : null,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              event.host?.name ?? 'Unknown Host',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Attendees count
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 14,
                                  color: AppColors.warmBrown,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  event.maxAttendees > 0
                                      ? '${event.attendeesCount}/${event.maxAttendees}'
                                      : '${event.attendeesCount}',
                                  style: TextStyle(
                                    color: AppColors.warmBrown,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

