import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../screens/live/stream_creation_screen.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/dimension_utils.dart';

/// Web Stream Screen - Stream creation and management
class StreamScreenWeb extends StatelessWidget {
  const StreamScreenWeb({super.key});

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
            Text(
              'Create Stream',
              style: AppTypography.heading1.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Start a live stream or schedule one for later',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            
            // Stream Options
          Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStreamOption(
                      context,
                      icon: Icons.videocam,
                      title: 'Go Live Now',
                      subtitle: 'Start an instant live stream',
                      color: AppColors.errorMain,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const StreamCreationScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),
                    _buildStreamOption(
                      context,
                      icon: Icons.schedule,
                      title: 'Schedule Stream',
                      subtitle: 'Plan a stream for later',
                      color: AppColors.primaryMain,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Schedule stream coming soon')),
                        );
                      },
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

  Widget _buildStreamOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: 400,
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
              padding: EdgeInsets.all(AppSpacing.large * 1.5),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: AppSpacing.large),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
            ),
          ),
                Icon(Icons.chevron_right, color: AppColors.textTertiary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
