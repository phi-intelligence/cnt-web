import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/donation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

class DonationModal extends StatefulWidget {
  final String recipientName;
  final int recipientUserId;

  const DonationModal({
    super.key,
    required this.recipientName,
    required this.recipientUserId,
  });

  @override
  State<DonationModal> createState() => _DonationModalState();
}

class _DonationModalState extends State<DonationModal> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final DonationService _donationService = DonationService();
  String _selectedPaymentMethod = 'stripe';
  bool _isProcessing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _handleDonate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid amount',
              style: AppTypography.body.copyWith(color: AppColors.textInverse)),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    // For Stripe, use PaymentIntent flow
    if (_selectedPaymentMethod == 'stripe') {
      await _handleStripePayment(amount);
    } else {
      // For PayPal or other methods, use legacy flow
      await _handleLegacyPayment(amount);
    }
  }

  Future<void> _handleStripePayment(double amount) async {
    setState(() => _isProcessing = true);

    try {
      // Step 1: Create payment intent on backend
      final paymentIntentData = await _donationService.createPaymentIntent(
        recipientUserId: widget.recipientUserId,
        amount: amount,
        currency: 'USD',
      );

      final clientSecret = paymentIntentData['client_secret'] as String;
      final publishableKey = paymentIntentData['publishable_key'] as String?;
      final paymentIntentId = paymentIntentData['payment_intent_id'] as String;

      // Step 2: Initialize Stripe with publishable key if provided
      if (publishableKey != null && publishableKey.isNotEmpty) {
        Stripe.publishableKey = publishableKey;
        Stripe.merchantIdentifier = 'merchant.com.cnt.media';
      }

      // Step 3: Present Stripe Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'CNT Media Platform',
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      // Step 4: Confirm payment on backend
      final confirmationResult = await _donationService.confirmPayment(
        paymentIntentId: paymentIntentId,
      );

      // Log confirmation for debugging
      print('✅ Donation confirmed: $confirmationResult');

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Donation of \$${amount.toStringAsFixed(2)} sent successfully!',
                style:
                    AppTypography.body.copyWith(color: AppColors.textInverse)),
            backgroundColor: AppColors.successMain,
          ),
        );
      }
    } on StripeException catch (e) {
      if (mounted) {
        String errorMessage = 'Payment failed';
        if (e.error.code == FailureCode.Canceled) {
          errorMessage = 'Payment was canceled';
        } else if (e.error.message != null) {
          errorMessage = e.error.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage,
                style:
                    AppTypography.body.copyWith(color: AppColors.textInverse)),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation failed: $e',
                style:
                    AppTypography.body.copyWith(color: AppColors.textInverse)),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleLegacyPayment(double amount) async {
    setState(() => _isProcessing = true);

    try {
      final donationResult = await _donationService.processDonation(
        recipientUserId: widget.recipientUserId,
        amount: amount,
        currency: 'USD',
        paymentMethod: _selectedPaymentMethod,
      );

      // Log result for debugging
      print('✅ Legacy donation processed: $donationResult');

      if (mounted) {
        Navigator.of(context).pop(true); // Return success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Donation of \$${amount.toStringAsFixed(2)} sent successfully!',
                style:
                    AppTypography.body.copyWith(color: AppColors.textInverse)),
            backgroundColor: AppColors.successMain,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Donation failed: $e',
                style:
                    AppTypography.body.copyWith(color: AppColors.textInverse)),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Donate to ${widget.recipientName}',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textPrimary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),

              // Amount field
              TextFormField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style:
                    AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Amount (USD)',
                  labelStyle: AppTypography.body
                      .copyWith(color: AppColors.textSecondary),
                  prefixIcon:
                      Icon(Icons.attach_money, color: AppColors.primaryMain),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide(color: AppColors.borderPrimary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide:
                        BorderSide(color: AppColors.primaryMain, width: 2),
                  ),
                  filled: true,
                  fillColor: AppColors.backgroundSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  final amount = double.tryParse(value);
                  if (amount == null || amount <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.large),

              // Payment method selection
              Text(
                'Payment Method',
                style: AppTypography.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              RadioListTile<String>(
                title: Text('Stripe',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)),
                value: 'stripe',
                groupValue: _selectedPaymentMethod,
                activeColor: AppColors.primaryMain,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              RadioListTile<String>(
                title: Text('PayPal',
                    style: AppTypography.body
                        .copyWith(color: AppColors.textPrimary)),
                value: 'paypal',
                groupValue: _selectedPaymentMethod,
                activeColor: AppColors.primaryMain,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.large),

              // Donate button
              ElevatedButton(
                onPressed: _isProcessing ? null : _handleDonate,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.medium),
                  backgroundColor: AppColors.primaryMain,
                  foregroundColor: AppColors.textInverse,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: _isProcessing
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.textInverse),
                        ),
                      )
                    : Text(
                        'Donate',
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
    );
  }
}
