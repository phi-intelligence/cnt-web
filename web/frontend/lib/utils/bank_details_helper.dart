import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/bank_details_screen.dart';
import '../services/stripe_connect_service.dart';
import '../config/app_config.dart';
import '../screens/donation_modal.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../services/logger_service.dart';

/// Helper function to check if user has bank details
/// Now returns true always to allow publishing without bank details
/// (Bank details are now optional)
Future<bool> checkBankDetailsAndNavigate(BuildContext context) async {
  // Bank details are now optional - always allow publishing
  return true;
}

/// Helper function to check if user has bank details silently
Future<bool> hasBankDetails(BuildContext context) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);

  try {
    final bankDetails = await userProvider.getBankDetails();
    return bankDetails != null;
  } catch (e) {
    LoggerService.e('Error checking bank details: $e');
    return false;
  }
}

/// Check if recipient user has Stripe Connect account set up (for receiving donations)
/// Returns true if recipient has payouts_enabled, false otherwise
Future<bool> checkRecipientBankDetails(int recipientUserId) async {
  try {
    final stripeConnectService = StripeConnectService();
    final status = await stripeConnectService.getAccountStatus(userId: recipientUserId);
    
    if (status == null) {
      return false;
    }
    
    // Return true only if account exists and payouts are enabled
    return status['account_exists'] == true && status['payouts_enabled'] == true;
  } catch (e) {
    LoggerService.e('Error checking recipient Stripe Connect status: $e');
    return false;
  }
}

/// Show organization donation modal (for donating to Christ New Tabernacle)
/// Checks if organization account has bank details before showing modal
Future<void> showOrganizationDonationModal(BuildContext context) async {
  final organizationRecipientId = AppConfig.organizationRecipientUserId;
  const organizationName = 'Christ New Tabernacle';

  // Check if organization recipient has bank details
  final hasBankDetails =
      await checkRecipientBankDetails(organizationRecipientId);
  if (!hasBankDetails) {
    // Show error dialog if organization can't receive donations
    await showRecipientBankDetailsMissingDialog(context, organizationName);
    return;
  }

  // Show donation modal for organization
  if (!context.mounted) return;
  showDialog(
    context: context,
    builder: (ctx) => DonationModal(
      recipientName: organizationName,
      recipientUserId: organizationRecipientId,
    ),
  );
}

/// Show dialog when recipient doesn't have bank details set up
Future<void> showRecipientBankDetailsMissingDialog(
  BuildContext context,
  String recipientName,
) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Donations Not Available',
                      style: AppTypography.heading3.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              Container(
                padding: EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.warningLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.warningMain.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warningDark,
                      size: 24,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        'This artist is currently not accepting donations.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
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
                  style: AppTypography.body.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Shows a modal prompting user to add bank details after successful publish
/// Call this after a successful publish when bank_details_missing is true
Future<void> showBankDetailsPromptAfterPublish(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(Icons.celebration, color: AppColors.successMain, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Content Submitted!',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your content has been submitted for approval!',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningLight.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warningMain.withOpacity(0.3)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    color: AppColors.warningDark, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'To receive donations from your audience, please set up your Stripe Connect payout account in your profile settings.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(
            'Maybe Later',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmBrown,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('Add Bank Details'),
        ),
      ],
    ),
  ).then((shouldAdd) async {
    if (shouldAdd == true && context.mounted) {
      // Navigate to bank details screen
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const BankDetailsScreen(isFromUpload: true),
        ),
      );
    }

    // Navigate to home regardless
    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  });
}
