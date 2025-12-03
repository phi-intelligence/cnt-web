import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../screens/web/meeting_options_screen_web.dart';
import '../../utils/responsive_utils.dart';

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
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Pill-shaped brown container
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.medium : AppSpacing.extraLarge * 2,
        vertical: isMobile ? AppSpacing.medium : AppSpacing.extraLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(isMobile ? 32 : 999), // Pill shape
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTextContent(),
          ),
          SizedBox(width: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2),
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
            color: Colors.white, // White text on brown background
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Connect with your community through instant or scheduled meetings.',
          style: AppTypography.body.copyWith(
            color: Colors.white.withOpacity(0.9), // Slightly transparent white
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
              color: Colors.white.withOpacity(0.2), // Semi-transparent white on brown
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.video_call,
              size: 60,
              color: Colors.white, // White icon on brown background
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Meetings',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white, // White text on brown background
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

