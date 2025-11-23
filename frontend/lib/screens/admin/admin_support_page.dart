import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/support_message.dart';
import '../../providers/support_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/platform_helper.dart';
import '../../utils/format_utils.dart';

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
      appBar: AppBar(
        title: const Text('Support Inbox'),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primaryMain,
        child: Consumer<SupportProvider>(
          builder: (context, provider, _) {
            final messages = provider.adminMessages;
            final isWide = PlatformHelper.isWebPlatform() ||
                MediaQuery.of(context).size.width > 900;

            return ListView(
              padding: EdgeInsets.all(AppSpacing.medium),
              children: [
                _buildStatsRow(provider),
                const SizedBox(height: AppSpacing.medium),
                _buildFilters(),
                const SizedBox(height: AppSpacing.medium),
                if (provider.isAdminLoading && messages.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(
                        color: AppColors.primaryMain,
                      ),
                    ),
                  )
                else if (messages.isEmpty)
                  Padding(
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
                  )
                else if (isWide)
                  ...messages.map(_buildWideCard)
                else
                  ...messages.map(_buildCompactCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsRow(SupportProvider provider) {
    final stats = provider.stats;
    return Row(
      children: [
        Expanded(
          child: _StatChip(
            label: 'Total',
            value: stats?.total.toString() ?? '-',
            color: AppColors.infoMain,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _StatChip(
            label: 'Open',
            value: stats?.openCount.toString() ?? '-',
            color: AppColors.warningMain,
          ),
        ),
        const SizedBox(width: AppSpacing.small),
        Expanded(
          child: _StatChip(
            label: 'New',
            value: stats?.unreadAdminCount.toString() ?? '-',
            color: AppColors.primaryMain,
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    final filters = <String?, String>{
      null: 'All',
      'open': 'Open',
      'responded': 'Responded',
      'closed': 'Closed',
    };

    return Wrap(
      spacing: AppSpacing.small,
      children: filters.entries.map((entry) {
        final isSelected = _statusFilter == entry.key;
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (_) {
            setState(() {
              _statusFilter = entry.key;
            });
            context
                .read<SupportProvider>()
                .fetchAdminMessages(status: _statusFilter);
          },
        );
      }).toList(),
    );
  }

  Widget _buildWideCard(SupportMessage message) {
    final controller =
        _replyControllers.putIfAbsent(message.id, () => TextEditingController());
    final isReplying = _isReplying[message.id] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.medium),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _SupportMessageMeta(message: message, onMarkRead: _markRead)),
            const SizedBox(width: AppSpacing.large),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Reply to ${message.user?.name ?? 'user'}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: isReplying ? null : () => _submitReply(message),
                      icon: isReplying
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(isReplying ? 'Sending...' : 'Send Reply'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactCard(SupportMessage message) {
    final controller =
        _replyControllers.putIfAbsent(message.id, () => TextEditingController());
    final isReplying = _isReplying[message.id] ?? false;

    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.medium),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SupportMessageMeta(message: message, onMarkRead: _markRead),
            const SizedBox(height: AppSpacing.medium),
            TextField(
              controller: controller,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: 'Reply',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: isReplying ? null : () => _submitReply(message),
                icon: isReplying
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send),
                label: Text(isReplying ? 'Sending...' : 'Send Reply'),
              ),
            ),
          ],
        ),
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
              TextButton.icon(
                onPressed: () => onMarkRead(message),
                label: const Text('Mark read'),
                icon: const Icon(Icons.mark_email_read_outlined),
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
        Text(
          message.message,
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            _StatusPill(status: message.status),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Created ${FormatUtils.formatRelativeTime(message.createdAt.toLocal())}',
              style: AppTypography.caption.copyWith(
                color: AppColors.textSecondary,
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
              children: [
                Text(
                  'Last response',
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  message.adminResponse ?? '',
                  style: AppTypography.body,
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


