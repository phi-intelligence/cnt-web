import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../screens/bank_details_screen.dart';

/// Helper function to check if user has bank details
/// Returns true if bank details exist, false otherwise
/// Shows dialog and navigates to bank details screen if missing
Future<bool> checkBankDetailsAndNavigate(BuildContext context) async {
  final userProvider = Provider.of<UserProvider>(context, listen: false);
  
  try {
    final bankDetails = await userProvider.getBankDetails();
    
    if (bankDetails == null) {
      // Show dialog asking user to add bank details
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Bank Details Required'),
          content: const Text(
            'Bank details are required to upload content and receive donations. Would you like to add them now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Add Bank Details'),
            ),
          ],
        ),
      );
      
      if (shouldAdd == true && context.mounted) {
        // Navigate to bank details screen
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BankDetailsScreen(isFromUpload: true),
          ),
        );
        
        // Return true if bank details were successfully added
        return result == true;
      }
      
      return false;
    }
    
    return true;
  } catch (e) {
    print('Error checking bank details: $e');
    return false;
  }
}

