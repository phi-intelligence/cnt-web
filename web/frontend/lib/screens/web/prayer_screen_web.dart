import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/empty_state.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_pill_button.dart';

/// Web Prayer Screen - Prayer requests and community prayers
class PrayerScreenWeb extends StatefulWidget {
  const PrayerScreenWeb({super.key});

  @override
  State<PrayerScreenWeb> createState() => _PrayerScreenWebState();
}

class _PrayerScreenWebState extends State<PrayerScreenWeb> {
  List<Map<String, dynamic>> _prayers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPrayers();
  }

  Future<void> _loadPrayers() async {
    setState(() => _isLoading = true);
    // TODO: Implement prayer requests API
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _prayers = [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            StyledPageHeader(
              title: 'Prayer Requests',
              size: StyledPageHeaderSize.h1,
              actionLabel: 'Submit Prayer',
              actionIcon: Icons.add,
              onAction: () => _showCreatePrayerDialog(context),
            ),
            const SizedBox(height: AppSpacing.large),
            
            // Prayers List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _prayers.isEmpty
                      ? const EmptyState(
                      icon: Icons.favorite,
                      title: 'No Prayer Requests',
                      message: 'Submit a prayer request to share with the community',
                    )
                  : ListView.builder(
                      itemCount: _prayers.length,
                      itemBuilder: (context, index) {
                        final prayer = _prayers[index];
                        return Card(
                          color: AppColors.cardBackground,
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: AppSpacing.medium),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(AppSpacing.large),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AppColors.primaryMain.withOpacity(0.1),
                                      child: Icon(Icons.person, color: AppColors.primaryMain),
                                    ),
                                    const SizedBox(width: AppSpacing.medium),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            prayer['author'] ?? 'Anonymous',
                                            style: AppTypography.body.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _formatTime(prayer['created_at']),
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.favorite_border,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        // TODO: Like prayer
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.medium),
                                Text(
                                  prayer['request'] ?? '',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
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

  void _showCreatePrayerDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text(
          'Submit Prayer Request',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Enter your prayer request...',
            hintStyle: TextStyle(color: AppColors.textPlaceholder),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
            ),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          StyledPillButton(
            label: 'Submit',
            onPressed: () {
              // TODO: Submit prayer
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Prayer request submitted'),
                  backgroundColor: AppColors.successMain,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString);
      return FormatUtils.formatRelativeTime(date);
    } catch (e) {
      return '';
    }
  }
}

