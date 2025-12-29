import 'package:flutter/material.dart';
import 'dart:html' if (dart.library.io) '../utils/html_stub.dart' as html;
import '../services/stripe_connect_service.dart';

class BankDetailsScreen extends StatefulWidget {
  final bool isFromUpload;

  const BankDetailsScreen({super.key, this.isFromUpload = false});

  @override
  State<BankDetailsScreen> createState() => _BankDetailsScreenState();
}

class _BankDetailsScreenState extends State<BankDetailsScreen> {
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
            const SnackBar(
              content: Text('Stripe Connect setup completed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
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
      print('Error loading account status: $e');
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
            const SnackBar(
              content: Text(
                  'Failed to create Stripe Connect account. Please try again.'),
              backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text(
                  'Opening Stripe onboarding in a new window. Complete the setup there.'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Failed to create onboarding link. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error setting up payouts: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
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
            const SnackBar(
              content: Text('Failed to get dashboard link. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting dashboard link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payout Settings'),
      ),
      body: _isLoading && _accountStatus == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                          Icon(Icons.info_outline,
                              color: Colors.orange.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Set up payout information to receive donations from your audience.',
                              style: TextStyle(color: Colors.orange.shade900),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Text(
                    'Stripe Connect Payouts',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set up your Stripe Connect account to receive donations and payments securely',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Show status or setup button
                  if (_accountExists &&
                      _accountStatus?['payouts_enabled'] == true)
                    _buildActiveStatus()
                  else
                    _buildSetupButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveStatus() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payouts Enabled',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'You can now receive donations and payments',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleViewDashboard,
              icon: const Icon(Icons.dashboard),
              label: const Text('View Stripe Dashboard'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupButton() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.account_balance_wallet, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Set Up Payouts',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your Stripe account to start receiving donations and payments. This is a secure process handled by Stripe.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _handleSetupPayouts,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.arrow_forward),
              label: Text(_isLoading ? 'Setting up...' : 'Set Up Payouts'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
