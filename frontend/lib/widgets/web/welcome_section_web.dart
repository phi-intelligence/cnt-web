import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../voice/voice_bubble.dart';
import '../../screens/web/voice_agent_screen_web.dart';

/// Welcome Section Widget for Web Homepage
/// Displays welcome message, description, action buttons, and voice assistant
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.extraLarge,
        vertical: AppSpacing.extraLarge * 1.5,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Text content and buttons
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Heading
                Text(
                  'Welcome to Christ New Tabernacle',
                  style: AppTypography.heading1.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                
                // Description
                Text(
                  "Experience God's word through engaging podcasts, Bible stories, and spiritual guidance. Join our community of believers in Christ.",
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                
                // Action Buttons
                Row(
                  children: [
                    // Start Listening Button (filled)
                    ElevatedButton(
                      onPressed: onStartListening ?? () {
                        // Scroll to audio podcasts section or play featured content
                        // Default action: scroll to audio podcasts
                        final RenderObject? renderObject = context.findRenderObject();
                        if (renderObject != null) {
                          Scrollable.ensureVisible(
                            context,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmBrown,
                        foregroundColor: AppColors.textInverse,
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.extraLarge,
                          vertical: AppSpacing.medium,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Start Listening',
                        style: AppTypography.button.copyWith(
                          color: AppColors.textInverse,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.medium),
                    
                    // Join Prayer Button (outlined)
                    OutlinedButton(
                      onPressed: onJoinPrayer ?? () {
                        // Navigate to prayer screen
                        Navigator.pushNamed(context, '/prayer');
                      },
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
                      child: Text(
                        'Join Prayer',
                        style: AppTypography.button.copyWith(
                          color: AppColors.warmBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Right side: Voice Assistant
          const SizedBox(width: AppSpacing.extraLarge),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              VoiceBubble(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VoiceAgentScreenWeb(),
                    ),
                  );
                },
                isActive: false,
                label: 'Tap to connect and start talking',
                enableHero: true,
                size: 130.0, // Larger size for web welcome section
              ),
            ],
          ),
        ],
      ),
    );
  }
}

