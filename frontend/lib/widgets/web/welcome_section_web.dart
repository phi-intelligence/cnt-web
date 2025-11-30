import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../voice/voice_bubble.dart';
import '../../screens/web/voice_agent_screen_web.dart';

class WelcomeSectionWeb extends StatelessWidget {
  const WelcomeSectionWeb({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
        vertical: isMobile ? AppSpacing.large : AppSpacing.extraLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(999), // Pill shape
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildVoiceAssistant(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildHeader(context),
                ),
                const SizedBox(width: AppSpacing.extraLarge * 2),
                _buildVoiceAssistant(context),
              ],
            ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), // Semi-transparent white on brown
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.church,
                color: Colors.white, // White icon on brown background
                size: 32,
              ),
            ),
            const SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to',
                    style: AppTypography.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.9), // Slightly transparent white
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Christ New Tabernacle',
                    style: AppTypography.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // White text on brown background
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Semi-transparent white on brown
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: Text(
            "Experience God's word through engaging podcasts, Bible stories, and spiritual guidance. Join our community of believers in Christ and be part of a movement that is changing lives.",
            style: AppTypography.body.copyWith(
              color: Colors.white.withOpacity(0.9), // Slightly transparent white
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildVoiceAssistant(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
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
            size: 120.0,
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Voice Assistant',
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

