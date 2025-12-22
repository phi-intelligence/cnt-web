import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/shared/pill_text_field.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';

/// Web-styled Bank Details Screen with responsive design
class BankDetailsScreenWeb extends StatefulWidget {
  final bool isFromUpload;
  
  const BankDetailsScreenWeb({super.key, this.isFromUpload = false});

  @override
  State<BankDetailsScreenWeb> createState() => _BankDetailsScreenWebState();
}

class _BankDetailsScreenWebState extends State<BankDetailsScreenWeb> {
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
          // Don't load account number for security - user must re-enter
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
            SnackBar(
              content: const Text('Bank details saved successfully'),
              backgroundColor: AppColors.successMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
              backgroundColor: AppColors.errorMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : (isTablet ? 700 : double.infinity),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Back',
                      ),
                      Expanded(
                        child: StyledPageHeader(
                          title: 'Bank Details',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
                  // Content
                  if (_isLoading && !_hasExistingDetails)
                    SectionContainer(
                      showShadow: true,
                      child: const Center(
                        child: Padding(
                          padding: EdgeInsets.all(AppSpacing.extraLarge),
                          child: CircularProgressIndicator(color: AppColors.warmBrown),
                        ),
                      ),
                    )
                  else
                    _buildContent(isDesktop),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDesktop) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero section with icon
          SectionContainer(
            showShadow: true,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.extraLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.warmBrown,
                    AppColors.warmBrown.withOpacity(0.85),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
              ),
              child: Row(
                children: [
                  Container(
                    width: isDesktop ? 100 : 80,
                    height: isDesktop ? 100 : 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.account_balance,
                      color: Colors.white,
                      size: isDesktop ? 50 : 40,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasExistingDetails ? 'Update Bank Details' : 'Add Bank Details',
                          style: AppTypography.heading2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          'Your bank details are encrypted and stored securely. Required to receive donations and payments.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.large),
          
          // Warning banner if from upload
          if (widget.isFromUpload)
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              margin: const EdgeInsets.only(bottom: AppSpacing.large),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Text(
                      'Bank details are required to upload content and receive donations.',
                      style: AppTypography.body.copyWith(
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Form Fields
          SectionContainer(
            showShadow: true,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: isDesktop 
                  ? _buildDesktopForm() 
                  : _buildMobileForm(),
            ),
          ),
          
          const SizedBox(height: AppSpacing.extraLarge),
        ],
      ),
    );
  }

  Widget _buildDesktopForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.warmBrown, size: 24),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Bank Account Information',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.extraLarge),
        
        // Two column layout for desktop
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column
            Expanded(
              child: Column(
                children: [
                  PillTextFieldOutlined(
                    controller: _accountNumberController,
                    labelText: 'Account Number *',
                    hintText: 'Enter your bank account number',
                    prefixIcon: Icons.account_balance,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  PillTextFieldOutlined(
                    controller: _ifscCodeController,
                    labelText: 'IFSC Code *',
                    hintText: 'e.g., HDFC0001234',
                    prefixIcon: Icons.qr_code,
                    textCapitalization: TextCapitalization.characters,
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
                  const SizedBox(height: AppSpacing.large),
                  PillTextFieldOutlined(
                    controller: _swiftCodeController,
                    labelText: 'SWIFT Code (Optional)',
                    hintText: 'For international transfers',
                    prefixIcon: Icons.code,
                    textCapitalization: TextCapitalization.characters,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.extraLarge),
            // Right column
            Expanded(
              child: Column(
                children: [
                  PillTextFieldOutlined(
                    controller: _bankNameController,
                    labelText: 'Bank Name *',
                    hintText: 'e.g., HDFC Bank',
                    prefixIcon: Icons.account_balance_wallet,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter bank name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  PillTextFieldOutlined(
                    controller: _accountHolderNameController,
                    labelText: 'Account Holder Name *',
                    hintText: 'Name as on bank account',
                    prefixIcon: Icons.person,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter account holder name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.large),
                  PillTextFieldOutlined(
                    controller: _branchNameController,
                    labelText: 'Branch Name *',
                    hintText: 'Bank branch name',
                    prefixIcon: Icons.location_on,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter branch name';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        
        const SizedBox(height: AppSpacing.extraLarge),
        
        // Save button
        Center(
          child: SizedBox(
            width: 300,
            child: StyledPillButton(
              label: _hasExistingDetails ? 'Update Bank Details' : 'Save Bank Details',
              icon: Icons.save,
              onPressed: _isLoading ? null : _handleSave,
              isLoading: _isLoading,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.edit_note, color: AppColors.warmBrown, size: 24),
            const SizedBox(width: AppSpacing.small),
            Text(
              'Bank Account Information',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.large),
        
        // Single column layout for mobile
        PillTextFieldOutlined(
          controller: _accountNumberController,
          labelText: 'Account Number *',
          hintText: 'Enter your bank account number',
          prefixIcon: Icons.account_balance,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account number';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        
        PillTextFieldOutlined(
          controller: _ifscCodeController,
          labelText: 'IFSC Code *',
          hintText: 'e.g., HDFC0001234',
          prefixIcon: Icons.qr_code,
          textCapitalization: TextCapitalization.characters,
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
        const SizedBox(height: AppSpacing.medium),
        
        PillTextFieldOutlined(
          controller: _swiftCodeController,
          labelText: 'SWIFT Code (Optional)',
          hintText: 'For international transfers',
          prefixIcon: Icons.code,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: AppSpacing.medium),
        
        PillTextFieldOutlined(
          controller: _bankNameController,
          labelText: 'Bank Name *',
          hintText: 'e.g., HDFC Bank',
          prefixIcon: Icons.account_balance_wallet,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter bank name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        
        PillTextFieldOutlined(
          controller: _accountHolderNameController,
          labelText: 'Account Holder Name *',
          hintText: 'Name as on bank account',
          prefixIcon: Icons.person,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter account holder name';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSpacing.medium),
        
        PillTextFieldOutlined(
          controller: _branchNameController,
          labelText: 'Branch Name *',
          hintText: 'Bank branch name',
          prefixIcon: Icons.location_on,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter branch name';
            }
            return null;
          },
        ),
        
        const SizedBox(height: AppSpacing.extraLarge),
        
        // Save button
        SizedBox(
          width: double.infinity,
          child: StyledPillButton(
            label: _hasExistingDetails ? 'Update Bank Details' : 'Save Bank Details',
            icon: Icons.save,
            onPressed: _isLoading ? null : _handleSave,
            isLoading: _isLoading,
          ),
        ),
      ],
    );
  }
}

