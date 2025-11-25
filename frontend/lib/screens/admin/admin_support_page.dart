import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/support_message.dart';
import '../../providers/support_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/platform_helper.dart';
import '../../utils/format_utils.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/admin/admin_dashboard_card.dart';
import '../../utils/responsive_grid_delegate.dart';

class AdminSupportPage extends StatefulWidget {
  const AdminSupportPage({super.key});

  @override
  State<AdminSupportPage> createState() => _AdminSupportPageState();
}

class _AdminSupportPageState extends State<AdminSupportPage> {
  String? _statusFilter;
  final Map<int, TextEditingController> _replyControllers = {};
  final Map<int, bool> _isReplying = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SupportProvider>();
      provider.fetchStats();
      provider.fetchAdminMessages();
    });
  }

  @override
  void dispose() {
    for (final controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<SupportProvider>();
    await provider.fetchStats();
    await provider.fetchAdminMessages(status: _statusFilter);
  }

  Future<void> _submitReply(SupportMessage message) async {
    final controller =
        _replyControllers.putIfAbsent(message.id, () => TextEditingController());
    final response = controller.text.trim();
    if (response.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a reply before sending')),
      );
      return;
    }

    setState(() {
      _isReplying[message.id] = true;
    });

    try {
      await context.read<SupportProvider>().replyToMessage(
            messageId: message.id,
            response: response,
            status: 'responded',
          );
      controller.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response sent to user')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reply: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isReplying.remove(message.id);
        });
      }
    }
  }

  Future<void> _markRead(SupportMessage message) async {
    await context
        .read<SupportProvider>()
        .markMessageAsRead(messageId: message.id, forAdmin: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryMain,
        child: Consumer<SupportProvider>(
          builder: (context, provider, _) {
            final messages = provider.adminMessages;
            final isWide = PlatformHelper.isWebPlatform() ||
                MediaQuery.of(context).size.width > 900;

            return Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      StyledPageHeader(
                        title: 'Support Inbox',
                        size: StyledPageHeaderSize.h2,
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Stats Section
                      _buildStatsSection(provider),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Filters Section
                      _buildFiltersSection(),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Messages Section
                      if (provider.isAdminLoading && messages.isEmpty)
                        SectionContainer(
                          showShadow: true,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryMain,
                              ),
                            ),
                          ),
                        )
                      else if (messages.isEmpty)
                        SectionContainer(
                          showShadow: true,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.support_agent,
                                    size: 64,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    'No support requests found for this filter.',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...messages.map((message) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.large),
                              child: isWide
                                  ? _buildWideCard(message)
                                  : _buildCompactCard(message),
                            )),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsSection(SupportProvider provider) {
    final stats = provider.stats;
    return SectionContainer(
      showShadow: true,
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
          context,
          desktop: 3,
          tablet: 3,
          mobile: 1,
          childAspectRatio: 2.5,
          crossAxisSpacing: AppSpacing.large,
          mainAxisSpacing: AppSpacing.large,
        ),
        itemCount: 3,
        itemBuilder: (context, index) {
          switch (index) {
            case 0:
              return AdminDashboardCard(
                title: 'Total',
                value: stats?.total.toString() ?? '-',
                icon: Icons.support_agent,
                backgroundColor: AppColors.infoMain,
              );
            case 1:
              return AdminDashboardCard(
                title: 'Open',
                value: stats?.openCount.toString() ?? '-',
                icon: Icons.pending_actions,
                backgroundColor: AppColors.warningMain,
              );
            case 2:
              return AdminDashboardCard(
                title: 'New',
                value: stats?.unreadAdminCount.toString() ?? '-',
                icon: Icons.mark_unread_chat_alt_outlined,
                backgroundColor: AppColors.primaryMain,
              );
            default:
              return const SizedBox();
          }
        },
      ),
    );
  }

  Widget _buildFiltersSection() {
    final filters = <String?, String>{
      null: 'All',
      'open': 'Open',
      'responded': 'Responded',
      'closed': 'Closed',
    };

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by Status',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          Wrap(
            spacing: AppSpacing.medium,
            runSpacing: AppSpacing.medium,
            children: filters.entries.map((entry) {
              final isSelected = _statusFilter == entry.key;
              return StyledPillButton(
                label: entry.value,
                variant: isSelected
                    ? StyledPillButtonVariant.filled
                    : StyledPillButtonVariant.outlined,
                onPressed: () {
                  setState(() {
                    _statusFilter = entry.key;
                  });
                  context
                      .read<SupportProvider>()
                      .fetchAdminMessages(status: _statusFilter);
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWideCard(SupportMessage message) {
    final controller =
        _replyControllers.putIfAbsent(message.id, () => TextEditingController());
    final isReplying = _isReplying[message.id] ?? false;

    return SectionContainer(
      showShadow: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: _SupportMessageMeta(message: message, onMarkRead: _markRead),
            ),
          ),
          const SizedBox(width: AppSpacing.extraLarge),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Reply',
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Reply to ${message.user?.name ?? 'user'}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                      borderSide: BorderSide(color: AppColors.borderPrimary),
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Align(
                  alignment: Alignment.centerRight,
                  child: StyledPillButton(
                    label: isReplying ? 'Sending...' : 'Send Reply',
                    icon: Icons.send_outlined,
                    onPressed: isReplying ? null : () => _submitReply(message),
                    isLoading: isReplying,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard(SupportMessage message) {
    final controller =
        _replyControllers.putIfAbsent(message.id, () => TextEditingController());
    final isReplying = _isReplying[message.id] ?? false;

    return SectionContainer(
      showShadow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _SupportMessageMeta(message: message, onMarkRead: _markRead),
          const SizedBox(height: AppSpacing.large),
          Text(
            'Reply',
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          TextField(
            controller: controller,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Reply',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              filled: true,
              fillColor: AppColors.backgroundPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.medium),
          Align(
            alignment: Alignment.centerRight,
            child: StyledPillButton(
              label: isReplying ? 'Sending...' : 'Send Reply',
              icon: Icons.send_outlined,
              onPressed: isReplying ? null : () => _submitReply(message),
              isLoading: isReplying,
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportMessageMeta extends StatelessWidget {
  final SupportMessage message;
  final Future<void> Function(SupportMessage) onMarkRead;

  const _SupportMessageMeta({
    required this.message,
    required this.onMarkRead,
  });

  @override
  Widget build(BuildContext context) {
    final user = message.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (user?.avatar != null)
              CircleAvatar(
                backgroundImage: NetworkImage(user!.avatar!),
              )
            else
              CircleAvatar(
                backgroundColor: AppColors.primaryMain.withOpacity(0.15),
                child: Text(
                  (user?.name ?? 'U').substring(0, 1).toUpperCase(),
                  style: AppTypography.body.copyWith(
                    color: AppColors.primaryMain,
                  ),
                ),
              ),
            const SizedBox(width: AppSpacing.small),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    user?.name ?? 'Unknown User',
                    style: AppTypography.heading4,
                  ),
                  if (user?.email != null)
                    Text(
                      user!.email!,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (!message.adminSeen)
              StyledPillButton(
                label: 'Mark read',
                icon: Icons.mark_email_read_outlined,
                variant: StyledPillButtonVariant.outlined,
                onPressed: () => onMarkRead(message),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.small),
        Text(
          message.subject,
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.tiny),
        Flexible(
          child: Text(
            message.message,
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            _StatusPill(status: message.status),
            const SizedBox(width: AppSpacing.small),
            Flexible(
              child: Text(
                'Created ${FormatUtils.formatRelativeTime(message.createdAt.toLocal())}',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if ((message.adminResponse ?? '').isNotEmpty) ...[
          const SizedBox(height: AppSpacing.medium),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              border: Border.all(
                color: AppColors.borderPrimary,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Last response',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.tiny),
                Flexible(
                  child: Text(
                    message.adminResponse ?? '',
                    style: AppTypography.body,
                    maxLines: null,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          )
        ],
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (status) {
      case 'closed':
        color = AppColors.successMain;
        label = 'Resolved';
        break;
      case 'responded':
        color = AppColors.accentMain;
        label = 'Responded';
        break;
      default:
        color = AppColors.warningMain;
        label = 'Open';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.15),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.tiny),
          Text(
            value,
            style: AppTypography.heading3.copyWith(
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


