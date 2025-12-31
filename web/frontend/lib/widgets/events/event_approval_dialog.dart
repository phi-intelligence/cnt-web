import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

class EventApprovalDialog extends StatelessWidget {
  final bool isAdmin;

  const EventApprovalDialog({
    super.key,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with icon, title, and close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAdmin
                              ? AppColors.successMain.withOpacity(0.1)
                              : AppColors.warningMain.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdmin
                              ? Icons.check_circle
                              : Icons.schedule,
                          color: isAdmin
                              ? AppColors.successMain
                              : AppColors.warningMain,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        isAdmin ? 'Event Created' : 'Event Submitted',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),

              // Content message
              Text(
                isAdmin
                    ? 'Event created successfully! Your event is now live and visible to all users.'
                    : 'Your event has been submitted for review. It will be reviewed by an admin before being published. You will be notified once it\'s approved.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // OK button
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                  backgroundColor: AppColors.primaryMain,
                  foregroundColor: AppColors.textInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'OK',
                  style: AppTypography.button.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

