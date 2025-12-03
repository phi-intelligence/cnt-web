import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../voice/voice_bubble.dart';
import '../../screens/web/voice_agent_screen_web.dart';
import '../../utils/responsive_utils.dart';

class WelcomeSectionWeb extends StatelessWidget {
  const WelcomeSectionWeb({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.medium : AppSpacing.extraLarge * 2,
        vertical: isMobile ? AppSpacing.medium : AppSpacing.extraLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(isMobile ? 32 : 999), // Rounded rect on mobile, pill on desktop
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
            flex: isMobile ? 3 : 2,
            child: _buildHeader(context),
          ),
          const Spacer(),
          _buildVoiceAssistant(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo and Title - matching sidebar style
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
                fontSize: isMobile ? 14 : 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Christ New Tabernacle',
              style: AppTypography.heading1.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isMobile ? 22 : 32,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
            ),
            const SizedBox(height: 4),
            Text(
              'Christian Podcast Platform',
              style: AppTypography.bodySmall.copyWith(
                color: Colors.white.withOpacity(0.8),
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
        if (!isMobile) ...[
          const SizedBox(height: AppSpacing.large),
          // Description text without glassmorphic border
          Text(
            "Experience God's word through engaging podcasts, Bible stories, and spiritual guidance. Join our community of believers in Christ and be part of a movement that is changing lives.",
            style: AppTypography.body.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.7,
            ),
          ),
        ],
      ],
    );
  }


  Widget _buildVoiceAssistant(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
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
          child: VoiceBubble(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VoiceAgentScreenWeb(),
                ),
              );
            },
            isActive: false,
            label: '',
            enableHero: true,
            size: isMobile ? 70.0 : 120.0,
          ),
        ),
        SizedBox(height: isMobile ? AppSpacing.small : AppSpacing.medium),
        Text(
          'Voice Assistant',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white, // White text on brown background
            fontWeight: FontWeight.w500,
            fontSize: isMobile ? 12 : 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

