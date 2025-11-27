import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class BankDetailsScreen extends StatefulWidget {
  final bool isFromUpload;
  
  const BankDetailsScreen({super.key, this.isFromUpload = false});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _ifscCodeController = TextEditingController();
  final _swiftCodeController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _branchNameController = TextEditingController();
  bool _isLoading = false;
  bool _hasExistingDetails = false;

  @override
  void initState() {
    super.initState();
    _loadBankDetails();
  }

  Future<void> _loadBankDetails() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    setState(() => _isLoading = true);
    
    try {
      final details = await userProvider.getBankDetails();
      if (details != null) {
        setState(() {
          _hasExistingDetails = true;
          // Don't load account number for security
          _ifscCodeController.text = details['ifsc_code'] ?? '';
          _swiftCodeController.text = details['swift_code'] ?? '';
          _bankNameController.text = details['bank_name'] ?? '';
          _accountHolderNameController.text = details['account_holder_name'] ?? '';
          _branchNameController.text = details['branch_name'] ?? '';
        });
      }
    } catch (e) {
      print('Error loading bank details: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _ifscCodeController.dispose();
    _swiftCodeController.dispose();
    _bankNameController.dispose();
    _accountHolderNameController.dispose();
    _branchNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      final success = await userProvider.updateBankDetails({
        'account_number': _accountNumberController.text.trim(),
        'ifsc_code': _ifscCodeController.text.trim(),
        'swift_code': _swiftCodeController.text.trim().isEmpty ? null : _swiftCodeController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'account_holder_name': _accountHolderNameController.text.trim(),
        'branch_name': _branchNameController.text.trim(),
      });

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bank details saved successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          if (widget.isFromUpload) {
            Navigator.of(context).pop(true); // Return true to indicate success
          } else {
            Navigator.of(context).pop();
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(userProvider.error ?? 'Failed to save bank details'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bank Details'),
      ),
      body: _isLoading && !_hasExistingDetails
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.isFromUpload)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Bank details are required to upload content and receive donations.',
                                style: TextStyle(color: Colors.orange.shade900),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    Text(
                      _hasExistingDetails ? 'Update Bank Details' : 'Add Bank Details',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your bank details are encrypted and secure',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Account Number
                    TextFormField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Account Number *',
                        prefixIcon: Icon(Icons.account_balance),
                        border: OutlineInputBorder(),
                        hintText: 'Enter your bank account number',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter account number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // IFSC Code
                    TextFormField(
                      controller: _ifscCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'IFSC Code *',
                        prefixIcon: Icon(Icons.qr_code),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., HDFC0001234',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter IFSC code';
                        }
                        if (value.length != 11) {
                          return 'IFSC code must be 11 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // SWIFT Code (Optional)
                    TextFormField(
                      controller: _swiftCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'SWIFT Code (Optional)',
                        prefixIcon: Icon(Icons.code),
                        border: OutlineInputBorder(),
                        hintText: 'For international transfers',
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Bank Name
                    TextFormField(
                      controller: _bankNameController,
                      decoration: const InputDecoration(
                        labelText: 'Bank Name *',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                        border: OutlineInputBorder(),
                        hintText: 'e.g., HDFC Bank',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter bank name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Account Holder Name
                    TextFormField(
                      controller: _accountHolderNameController,
                      decoration: const InputDecoration(
                        labelText: 'Account Holder Name *',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                        hintText: 'Name as on bank account',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter account holder name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Branch Name
                    TextFormField(
                      controller: _branchNameController,
                      decoration: const InputDecoration(
                        labelText: 'Branch Name *',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(),
                        hintText: 'Bank branch name',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter branch name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _hasExistingDetails ? 'Update Bank Details' : 'Save Bank Details',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

