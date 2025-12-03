import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/bank_details_screen.dart';
import '../theme/app_colors.dart';

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
    print('Error checking bank details: $e');
    return false;
  }
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
                Icon(Icons.info_outline, color: AppColors.warningDark, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'To receive donations from your audience, please add your bank account details in your profile settings.',
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

