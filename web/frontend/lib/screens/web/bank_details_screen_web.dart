import 'package:flutter/material.dart';
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;
import '../../services/stripe_connect_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../services/logger_service.dart';

/// Web-styled Bank Details Screen with Stripe Connect onboarding
class BankDetailsScreenWeb extends StatefulWidget {
  final bool isFromUpload;
  
  const BankDetailsScreenWeb({super.key, this.isFromUpload = false});

  @override
  State<BankDetailsScreenWeb> createState() => _BankDetailsScreenWebState();
}

class _BankDetailsScreenWebState extends State<BankDetailsScreenWeb> {
  final StripeConnectService _stripeConnect = StripeConnectService();
  Map<String, dynamic>? _accountStatus;
  bool _isLoading = false;
  bool _accountExists = false;

  @override
  void initState() {
    super.initState();
    _checkUrlParams();
    _loadAccountStatus();
  }

  void _checkUrlParams() {
    // Check if returning from Stripe onboarding
    final uri = Uri.parse(html.window.location.href);
    if (uri.queryParameters.containsKey('success')) {
      // Show success message and refresh status
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Stripe Connect setup completed successfully!'),
              backgroundColor: AppColors.successMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          // Reload status to show updated state
          _loadAccountStatus();
        }
      });
    }
  }

  Future<void> _loadAccountStatus() async {
    setState(() => _isLoading = true);
    
    try {
      final status = await _stripeConnect.getAccountStatus();
      if (status != null) {
        setState(() {
          _accountStatus = status;
          _accountExists = status['account_exists'] == true;
        });
      }
    } catch (e) {
      LoggerService.e('Error loading account status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSetupPayouts() async {
    setState(() => _isLoading = true);
    
    try {
      // 1. Create account if doesn't exist
      final accountId = await _stripeConnect.createConnectAccount();
      if (accountId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create Stripe Connect account. Please try again.'),
              backgroundColor: AppColors.errorMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
        return;
      }
      
      // 2. Get onboarding link
      final onboardingUrl = await _stripeConnect.createOnboardingLink();
      if (onboardingUrl != null) {
        // Open in new window
        html.window.open(onboardingUrl, '_blank');
        
        // Show message to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Opening Stripe onboarding in a new window. Complete the setup there.'),
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to create onboarding link. Please try again.'),
              backgroundColor: AppColors.errorMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.e('Error setting up payouts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorMain,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleViewDashboard() async {
    setState(() => _isLoading = true);
    
    try {
      final dashboardUrl = await _stripeConnect.getDashboardLink();
      if (dashboardUrl != null) {
        html.window.open(dashboardUrl, '_blank');
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to get dashboard link. Please try again.'),
              backgroundColor: AppColors.errorMain,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      LoggerService.e('Error getting dashboard link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.errorMain,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 900 : double.infinity,
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
                          title: 'Payout Settings',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                  
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
                              'Set up payout information to receive donations from your audience.',
                              style: AppTypography.body.copyWith(
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Content
                  if (_isLoading && _accountStatus == null)
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
    if (_accountExists && _accountStatus?['payouts_enabled'] == true) {
      return _buildActiveStatus(isDesktop);
    } else {
      return _buildSetupButton(isDesktop);
    }
  }

  Widget _buildActiveStatus(bool isDesktop) {
    return SectionContainer(
      showShadow: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.extraLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppColors.successMain.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.successMain,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.large),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payouts Enabled',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.successMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'You can now receive donations and payments securely through Stripe.',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.extraLarge),
            SizedBox(
              width: isDesktop ? 300 : double.infinity,
              child: StyledPillButton(
                label: 'View Stripe Dashboard',
                icon: Icons.dashboard,
                onPressed: _isLoading ? null : _handleViewDashboard,
                isLoading: _isLoading,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupButton(bool isDesktop) {
    return Column(
      children: [
        // Hero section
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
                    Icons.account_balance_wallet,
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
                        'Set Up Payouts',
                        style: AppTypography.heading2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Connect your Stripe account to start receiving donations and payments. This is a secure process handled by Stripe.',
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
        
        // Setup card
        SectionContainer(
          showShadow: true,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.extraLarge),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How it works',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                _buildInfoRow(
                  Icons.security,
                  'Secure & Compliant',
                  'Your payment information is handled securely by Stripe, a PCI-compliant payment processor.',
                ),
                const SizedBox(height: AppSpacing.medium),
                _buildInfoRow(
                  Icons.credit_card,
                  'Easy Setup',
                  'Complete a simple onboarding process to connect your bank account for payouts.',
                ),
                const SizedBox(height: AppSpacing.medium),
                _buildInfoRow(
                  Icons.payments,
                  'Receive Payments',
                  'Start receiving donations and payments directly to your bank account.',
                ),
                const SizedBox(height: AppSpacing.extraLarge),
                Center(
                  child: SizedBox(
                    width: isDesktop ? 300 : double.infinity,
                    child: StyledPillButton(
                      label: _isLoading ? 'Setting up...' : 'Set Up Payouts',
                      icon: Icons.arrow_forward,
                      onPressed: _isLoading ? null : _handleSetupPayouts,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.warmBrown, size: 24),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.tiny),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
