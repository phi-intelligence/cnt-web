import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';

class EventDetailScreenWeb extends StatefulWidget {
  final int eventId;

  const EventDetailScreenWeb({super.key, required this.eventId});

  @override
  State<EventDetailScreenWeb> createState() => _EventDetailScreenWebState();
}

class _EventDetailScreenWebState extends State<EventDetailScreenWeb> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventDetails();
    });
  }

  Future<void> _loadEventDetails() async {
    final provider = context.read<EventProvider>();
    await provider.fetchEventDetails(widget.eventId);
    await provider.fetchEventAttendees(widget.eventId);
  }

  Future<void> _handleJoin() async {
    final provider = context.read<EventProvider>();
    final success = await provider.joinEvent(widget.eventId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request sent! Waiting for host approval.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadEventDetails();
    } else if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _handleLeave() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Leave Event'),
        content: Text('Are you sure you want to leave this event?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final provider = context.read<EventProvider>();
    final success = await provider.leaveEvent(widget.eventId);
    
    if (!mounted) return;
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have left the event'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      _loadEventDetails();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Consumer<EventProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.selectedEvent == null) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.warmBrown),
            );
          }

          final event = provider.selectedEvent;
          if (event == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.event_busy, size: 64, color: AppColors.textSecondary),
                  SizedBox(height: 16),
                  Text(
                    'Event not found',
                    style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // App Bar with cover image
              SliverAppBar(
                backgroundColor: AppColors.warmBrown,
                elevation: 0,
                pinned: true,
                expandedHeight: 280,
                leading: Container(
                  margin: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Cover image
                      if (event.coverImage != null && event.coverImage!.isNotEmpty)
                        Image.network(
                          _apiService.getMediaUrl(event.coverImage!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.warmBrown,
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.warmBrown,
                                AppColors.warmBrown.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.6),
                            ],
                          ),
                        ),
                      ),
                      // Status badges
                      Positioned(
                        top: 80,
                        right: 16,
                        child: Row(
                          children: [
                            if (event.isPast)
                              _buildBadge('Past Event', Colors.grey),
                            if (event.isAttending) ...[
                              if (event.isPast) SizedBox(width: 8),
                              _buildBadge(
                                event.myAttendanceStatus == 'approved'
                                    ? 'Attending'
                                    : 'Pending Approval',
                                event.myAttendanceStatus == 'approved'
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Content
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? 64 : (isMediumScreen ? 32 : 16),
                  vertical: 24,
                ),
                sliver: SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Event header with title and date
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Date card
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 12,
                                      offset: Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      DateFormat('MMM').format(event.eventDate).toUpperCase(),
                                      style: TextStyle(
                                        color: AppColors.warmBrown,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      event.eventDate.day.toString(),
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      DateFormat('yyyy').format(event.eventDate),
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 20),
                              // Title and host info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      event.title,
                                      style: AppTypography.heading2.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 18,
                                          backgroundColor: AppColors.warmBrown.withOpacity(0.2),
                                          backgroundImage: event.host?.avatar != null && event.host!.avatar!.isNotEmpty
                                              ? NetworkImage(_apiService.getMediaUrl(event.host!.avatar!))
                                              : null,
                                          child: event.host?.avatar == null || event.host!.avatar!.isEmpty
                                              ? Icon(Icons.person, size: 18, color: AppColors.warmBrown)
                                              : null,
                                        ),
                                        SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Hosted by',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              event.host?.name ?? 'Unknown',
                                              style: TextStyle(
                                                color: AppColors.textPrimary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: 32),
                          
                          // Event details in a grid
                          isLargeScreen
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Left column
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        children: [
                                          _buildInfoSection(event),
                                          SizedBox(height: 24),
                                          _buildDescriptionSection(event),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 24),
                                    // Right column
                                    Expanded(
                                      child: Column(
                                        children: [
                                          _buildActionCard(event, provider),
                                          SizedBox(height: 24),
                                          _buildAttendeesSection(provider),
                                        ],
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildInfoSection(event),
                                    SizedBox(height: 24),
                                    _buildActionCard(event, provider),
                                    SizedBox(height: 24),
                                    _buildDescriptionSection(event),
                                    SizedBox(height: 24),
                                    _buildAttendeesSection(provider),
                                  ],
                                ),
                          
                          SizedBox(height: 48),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInfoSection(EventModel event) {
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Details',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 20),
          
          // Time
          _buildInfoRow(
            icon: Icons.access_time,
            title: 'Time',
            value: DateFormat('EEEE, MMMM d, yyyy • h:mm a').format(event.eventDate),
          ),
          
          SizedBox(height: 16),
          
          // Location
          if (event.location != null && event.location!.isNotEmpty) ...[
            _buildInfoRow(
              icon: Icons.location_on,
              title: 'Location',
              value: event.location!,
            ),
            SizedBox(height: 16),
          ],
          
          // Capacity
          _buildInfoRow(
            icon: Icons.people,
            title: 'Capacity',
            value: event.maxAttendees > 0
                ? '${event.attendeesCount} / ${event.maxAttendees} attendees'
                : '${event.attendeesCount} attendees',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.warmBrown.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.warmBrown, size: 20),
        ),
        SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(EventModel event) {
    if (event.description == null || event.description!.isEmpty) {
      return SizedBox.shrink();
    }

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About this Event',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16),
          Text(
            event.description!,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(EventModel event, EventProvider provider) {
    return SectionContainer(
      showShadow: true,
      child: Column(
        children: [
          // Attendees count
          Row(
            children: [
              Icon(Icons.people, color: AppColors.warmBrown, size: 24),
              SizedBox(width: 12),
              Text(
                event.maxAttendees > 0
                    ? '${event.attendeesCount} / ${event.maxAttendees}'
                    : '${event.attendeesCount}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'attendees',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          if (event.isFull)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Event is full',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          
          SizedBox(height: 20),
          
          // Action button
          if (!event.isPast)
            SizedBox(
              width: double.infinity,
              height: 48,
              child: event.isAttending
                  ? OutlinedButton(
                      onPressed: provider.isLoading ? null : _handleLeave,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: provider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('Leave Event'),
                    )
                  : ElevatedButton(
                      onPressed: (provider.isLoading || event.isFull) ? null : _handleJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmBrown,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.warmBrown.withOpacity(0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: provider.isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text('Request to Join'),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttendeesSection(EventProvider provider) {
    final attendees = provider.selectedEventAttendees;
    
    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendees',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          SizedBox(height: 16),
          
          if (attendees.isEmpty)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: AppColors.textSecondary.withOpacity(0.5),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No attendees yet',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: attendees.length.clamp(0, 10),
              separatorBuilder: (_, __) => Divider(height: 1),
              itemBuilder: (context, index) {
                final attendee = attendees[index];
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.warmBrown.withOpacity(0.2),
                    backgroundImage: attendee.user?.avatar != null && attendee.user!.avatar!.isNotEmpty
                        ? NetworkImage(_apiService.getMediaUrl(attendee.user!.avatar!))
                        : null,
                    child: attendee.user?.avatar == null || attendee.user!.avatar!.isEmpty
                        ? Icon(Icons.person, size: 20, color: AppColors.warmBrown)
                        : null,
                  ),
                  title: Text(
                    attendee.user?.name ?? 'Unknown',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  trailing: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: attendee.status == 'approved'
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      attendee.status == 'approved' ? 'Approved' : 'Pending',
                      style: TextStyle(
                        color: attendee.status == 'approved' ? Colors.green : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          
          if (attendees.length > 10)
            Padding(
              padding: EdgeInsets.only(top: 12),
              child: Center(
                child: Text(
                  '+ ${attendees.length - 10} more attendees',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

