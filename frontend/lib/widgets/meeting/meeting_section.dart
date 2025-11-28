import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/web/meeting_options_screen_web.dart';

/// Meetings section styled like the Bible Reader section
/// Main container with gradient background, text on left, circular bubble on right
class MeetingSection extends StatelessWidget {
  const MeetingSection({super.key});

  void _handleMeetingTap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MeetingOptionsScreenWeb(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    // Main container matching BibleReaderSection design
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown.withOpacity(0.15),
            AppColors.accentMain.withOpacity(0.1),
            AppColors.backgroundSecondary,
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildTextContent(),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildBubble(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextContent(),
                ),
                const SizedBox(width: AppSpacing.extraLarge * 2),
                _buildBubble(context),
              ],
            ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Start a Meeting',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Connect with your community through instant or scheduled meetings.',
          style: AppTypography.body.copyWith(
            color: AppColors.textSecondary,
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildBubble(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: () => _handleMeetingTap(context),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentMain.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.video_call,
              size: 60,
              color: AppColors.warmBrown,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Meetings',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

