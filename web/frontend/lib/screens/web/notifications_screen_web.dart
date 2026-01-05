import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/loading_shimmer.dart';
import '../../widgets/shared/empty_state.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/web/styled_pill_button.dart';

/// Web Notifications Screen
class NotificationsScreenWeb extends StatefulWidget {
  const NotificationsScreenWeb({super.key});

  @override
  State<NotificationsScreenWeb> createState() => _NotificationsScreenWebState();
}

class _NotificationsScreenWebState extends State<NotificationsScreenWeb> {
  String _filter = 'All';
  final List<String> _filters = ['All', 'Unread', 'Read'];
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    provider.fetchNotifications(refresh: true);

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    _isLoadingMore = true;

    final provider = context.read<NotificationProvider>();
    final unreadOnly = _filter == 'Unread';
    await provider.fetchNotifications(unreadOnly: unreadOnly);

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Back Button
            Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.medium),
              child: StyledPillButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onPressed: () => Navigator.of(context).pop(),
                variant: StyledPillButtonVariant.outlined,
              ),
            ),
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: _filters.map((filter) {
                    final isSelected = filter == _filter;
                    return Padding(
                      padding: EdgeInsets.only(left: AppSpacing.small),
                      child: FilterChip(
                        label: Text(
                          filter,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : AppColors.textSecondary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _filter = filter);
                          final provider = context.read<NotificationProvider>();
                          provider.fetchNotifications(
                            unreadOnly: filter == 'Unread',
                            refresh: true,
                          );
                        },
                        selectedColor: AppColors.primaryMain,
                        backgroundColor: AppColors.cardBackground,
                        checkmarkColor: Colors.white,
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primaryMain
                              : AppColors.borderPrimary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.large),

            // Notifications List
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading && provider.notifications.isEmpty) {
                    return ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: AppSpacing.medium),
                          child: const LoadingShimmer(
                              width: double.infinity, height: 80),
                        );
                      },
                    );
                  }

                  if (provider.error != null &&
                      provider.notifications.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Error loading notifications',
                            style: AppTypography.body.copyWith(
                              color: AppColors.errorMain,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          ElevatedButton(
                            onPressed: () {
                              provider.fetchNotifications(refresh: true);
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  List<AppNotification> filteredNotifications =
                      provider.notifications;
                  if (_filter == 'Unread') {
                    filteredNotifications =
                        provider.notifications.where((n) => !n.read).toList();
                  } else if (_filter == 'Read') {
                    filteredNotifications =
                        provider.notifications.where((n) => n.read).toList();
                  }

                  if (filteredNotifications.isEmpty) {
                    return const EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No Notifications',
                      message: 'You\'re all caught up!',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await provider.fetchNotifications(
                        unreadOnly: _filter == 'Unread',
                        refresh: true,
                      );
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredNotifications.length +
                          (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == filteredNotifications.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSpacing.medium),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final notification = filteredNotifications[index];
                        return Card(
                          color: notification.read
                              ? AppColors.cardBackground
                              : AppColors.cardBackground.withOpacity(0.8),
                          elevation: notification.read ? 1 : 3,
                          margin: EdgeInsets.only(bottom: AppSpacing.small),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: notification.read
                                ? BorderSide.none
                                : BorderSide(
                                    color:
                                        AppColors.primaryMain.withOpacity(0.3),
                                    width: 2,
                                  ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primaryMain.withOpacity(0.1),
                              child: Icon(
                                _getNotificationIcon(notification.type),
                                color: AppColors.primaryMain,
                              ),
                            ),
                            title: Text(
                              notification.title,
                              style: AppTypography.body.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: notification.read
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatUtils.formatRelativeTime(
                                      notification.createdAt),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                            trailing: notification.read
                                ? null
                                : Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryMain,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                            onTap: () {
                              _handleNotificationTap(notification, provider);
                            },
                            onLongPress: () {
                              _showNotificationOptions(
                                  context, notification, provider);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'content_approved':
        return Icons.check_circle;
      case 'content_rejected':
        return Icons.cancel;
      case 'live_stream':
        return Icons.live_tv;
      case 'donation_received':
      case 'donation_sent':
        return Icons.payments;
      case 'new_follower':
        return Icons.person_add;
      case 'new_comment':
        return Icons.comment;
      case 'new_like':
        return Icons.favorite;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  void _handleNotificationTap(
      AppNotification notification, NotificationProvider provider) {
    // Mark as read if unread
    if (!notification.read) {
      provider.markAsRead([notification.id]);
    }

    // Navigate based on notification type and data
    final data = notification.data;
    if (data != null) {
      final contentType = data['content_type'] as String?;
      final contentId = data['content_id'];

      if (contentType != null && contentId != null) {
        switch (contentType) {
          case 'podcast':
            context.push('/podcast/$contentId');
            break;
          case 'movie':
            context.push('/movie/$contentId');
            break;
          case 'community_post':
            // Navigate to community screen
            context.push('/community');
            break;
          case 'event':
            context.push('/events/$contentId');
            break;
        }
      } else if (notification.type == 'live_stream') {
        final streamId = data['stream_id'];
        if (streamId != null) {
          context.push('/live-streams?refresh=true');
        }
      }
    }
  }

  void _showNotificationOptions(
    BuildContext context,
    AppNotification notification,
    NotificationProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!notification.read)
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text('Mark as Read'),
                onTap: () {
                  provider.markAsRead([notification.id]);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.errorMain),
              title: const Text('Delete',
                  style: TextStyle(color: AppColors.errorMain)),
              onTap: () {
                provider.deleteNotification(notification.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
