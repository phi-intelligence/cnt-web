import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../voice/voice_bubble.dart';
import '../../screens/web/voice_agent_screen_web.dart';

class WelcomeSectionWeb extends StatelessWidget {
  final VoidCallback? onStartListening;
  final VoidCallback? onJoinPrayer;

  const WelcomeSectionWeb({
    super.key,
    this.onStartListening,
    this.onJoinPrayer,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

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
                _buildHeader(context),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildActionButtons(context),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.extraLarge),
                      _buildActionButtons(context),
                    ],
                  ),
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
                gradient: LinearGradient(
                  colors: [
                    AppColors.warmBrown.withOpacity(0.2),
                    AppColors.accentMain.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.church,
                color: AppColors.warmBrown,
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
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Christ New Tabernacle',
                    style: AppTypography.heading1.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.warmBrown,
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
            color: AppColors.cardBackground.withOpacity(0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: AppColors.borderPrimary.withOpacity(0.3),
            ),
          ),
          child: Text(
            "Experience God's word through engaging podcasts, Bible stories, and spiritual guidance. Join our community of believers in Christ and be part of a movement that is changing lives.",
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
              height: 1.7,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.medium,
      runSpacing: AppSpacing.medium,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.warmBrown,
                AppColors.primaryMain,
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: onStartListening ?? () {
              final RenderObject? renderObject = context.findRenderObject();
              if (renderObject != null) {
                Scrollable.ensureVisible(
                  context,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              }
            },
            icon: const Icon(Icons.play_circle_filled, size: 24),
            label: Text(
              'Start Listening',
              style: AppTypography.button.copyWith(
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.extraLarge,
                vertical: AppSpacing.medium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onJoinPrayer ?? () {
            Navigator.pushNamed(context, '/prayer');
          },
          icon: Icon(Icons.favorite, color: AppColors.accentMain),
          label: Text(
            'Join Prayer',
            style: AppTypography.button.copyWith(
              color: AppColors.warmBrown,
            ),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.warmBrown,
            side: BorderSide(
              color: AppColors.warmBrown,
              width: 2,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.extraLarge,
              vertical: AppSpacing.medium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
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
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

