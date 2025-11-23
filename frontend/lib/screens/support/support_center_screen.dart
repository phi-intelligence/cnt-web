import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/support_message.dart';
import '../../providers/support_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class SupportCenterScreen extends StatefulWidget {
  const SupportCenterScreen({super.key});

  @override
  State<SupportCenterScreen> createState() => _SupportCenterScreenState();
}

class _SupportCenterScreenState extends State<SupportCenterScreen> {
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<SupportProvider>();
      provider.fetchMyMessages();
      provider.fetchStats();
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await context.read<SupportProvider>().submitMessage(
            subject: _subjectController.text.trim(),
            message: _messageController.text.trim(),
          );
      if (!mounted) return;
      _subjectController.clear();
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message sent to support')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: RefreshIndicator(
        color: AppColors.primaryMain,
        onRefresh: () async {
          final provider = context.read<SupportProvider>();
          await provider.fetchMyMessages();
          await provider.fetchStats();
        },
        child: Consumer<SupportProvider>(
          builder: (context, provider, _) {
            final messages = provider.myMessages;

            return ListView(
              padding: EdgeInsets.all(AppSpacing.medium),
              children: [
                _buildSupportForm(),
                const SizedBox(height: AppSpacing.large),
                Text(
                  'Previous Conversations',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                if (provider.isLoading && messages.isEmpty)
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
                    child: Text(
                      'No messages yet. Start a conversation above!',
                      style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...messages.map(_buildMessageCard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSupportForm() {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.large),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contact Admin',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                'Have a question or need help? Send us a message and our admin team will respond shortly.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(
                  labelText: 'Subject',
                  prefixIcon: Icon(Icons.subject),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 3) {
                    return 'Please enter at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.medium),
              TextFormField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Message',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return 'Please provide more details (min 10 characters)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.large),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_isSubmitting ? 'Sending...' : 'Send message'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageCard(SupportMessage message) {
    final hasResponse = (message.adminResponse ?? '').isNotEmpty;
    return Card(
      margin: EdgeInsets.only(bottom: AppSpacing.medium),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    message.subject,
                    style: AppTypography.heading4.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                _buildStatusChip(message.status),
              ],
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              message.message,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            if (hasResponse)
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.primaryMain.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin Response',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
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
            else
              Text(
                'Awaiting admin response...',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color bg = AppColors.infoMain.withOpacity(0.15);
    Color fg = AppColors.infoMain;
    String label = status;

    switch (status) {
      case 'closed':
        bg = AppColors.successMain.withOpacity(0.15);
        fg = AppColors.successMain;
        label = 'Resolved';
        break;
      case 'responded':
        bg = AppColors.accentMain.withOpacity(0.15);
        fg = AppColors.accentMain;
        label = 'Responded';
        break;
      default:
        label = 'Open';
        bg = AppColors.warningMain.withOpacity(0.15);
        fg = AppColors.warningMain;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: AppTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

