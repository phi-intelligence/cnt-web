import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
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
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
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
                    image: const AssetImage('assets/images/Jesus-crowd.png'),
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
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Community Events',
                                  style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isMobile ? 28 : (isTablet ? 36 : 42),
                                    height: 1.1,
                                  ),
                                ),
                                SizedBox(height: AppSpacing.small),
                                Text(
                                  'Join or host events to connect with the community',
                                  style: AppTypography.getResponsiveBody(context).copyWith(
                                    color: AppColors.primaryDark.withOpacity(0.7),
                                    fontSize: isMobile ? 14 : 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppSpacing.medium),
                          Flexible(
                            child: StyledPillButton(
                              label: 'Host Event',
                              icon: Icons.add,
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const EventCreateScreenWeb()),
                                );
                                if (result != null) {
                                  _loadData();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: AppSpacing.large),
                    
                    // Tabs
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
                            Tab(text: 'All Events'),
                            Tab(text: 'My Events'),
                            Tab(text: 'Attending'),
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

    // Use list layout for compact horizontal cards
    return RefreshIndicator(
      color: AppColors.warmBrown,
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(isLargeScreen ? 32 : 16),
        itemCount: events.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: _buildCompactEventCard(events[index], isLargeScreen),
          );
        },
      ),
    );
  }

  Widget _buildCompactEventCard(EventModel event, bool isLargeScreen) {
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
          height: isLargeScreen ? 100 : 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(50), // Pill shape
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Date pill on the left
              Container(
                width: isLargeScreen ? 80 : 70,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: event.isPast 
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : [AppColors.warmBrown, AppColors.warmBrown.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                    bottomLeft: Radius.circular(50),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('MMM').format(event.eventDate).toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      event.eventDate.day.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title
                      Text(
                        event.title,
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      // Time and location
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 12, color: AppColors.textSecondary),
                          SizedBox(width: 4),
                          Text(
                            timeFormat.format(event.eventDate),
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          if (event.location != null) ...[
                            SizedBox(width: 12),
                            Icon(Icons.location_on, size: 12, color: AppColors.textSecondary),
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
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Status and attendees on the right
              Padding(
                padding: EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Status badge
                    if (event.isPast)
                      _buildStatusPill('Past', Colors.grey)
                    else if (event.isAttending)
                      _buildStatusPill(
                        event.myAttendanceStatus == 'approved' ? 'Going' : 'Pending',
                        event.myAttendanceStatus == 'approved' ? Colors.green : Colors.orange,
                      ),
                    SizedBox(height: 6),
                    // Attendees
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline, size: 14, color: AppColors.warmBrown),
                        SizedBox(width: 4),
                        Text(
                          '${event.attendeesCount}',
                          style: TextStyle(
                            color: AppColors.warmBrown,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Arrow indicator
              Container(
                width: 50,
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.08),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(50),
                    bottomRight: Radius.circular(50),
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.chevron_right,
                    color: AppColors.warmBrown,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
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
            // Decorative circles background
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown.withOpacity(0.05),
                        AppColors.accentMain.withOpacity(0.05),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.warmBrown.withOpacity(0.08),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.warmBrown.withOpacity(0.15),
                        AppColors.accentMain.withOpacity(0.1),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.event_busy,
                    size: 36,
                    color: AppColors.warmBrown.withOpacity(0.7),
                  ),
                ),
              ],
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
            // Gradient pill button
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warmBrown, AppColors.accentMain],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
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
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

