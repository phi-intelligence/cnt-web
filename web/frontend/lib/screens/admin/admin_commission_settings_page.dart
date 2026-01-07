import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/api_service.dart';
import '../../models/commission_settings.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_utils.dart';

/// Admin Commission Settings Page
/// Allows admins to configure platform commission rates
class AdminCommissionSettingsPage extends StatefulWidget {
  const AdminCommissionSettingsPage({super.key});

  @override
  State<AdminCommissionSettingsPage> createState() => _AdminCommissionSettingsPageState();
}

class _AdminCommissionSettingsPageState extends State<AdminCommissionSettingsPage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  
  // Form state
  String _commissionType = 'percentage';
  double _commissionPercentage = 0.0;
  double _commissionFixedAmount = 0.0;
  bool _isActive = false;
  
  DateTime? _updatedAt;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _api.getCommissionSettings();
      final settings = CommissionSettings.fromJson(data);
      
      if (mounted) {
        setState(() {
          _commissionType = settings.commissionType;
          _commissionPercentage = settings.commissionPercentage;
          _commissionFixedAmount = settings.commissionFixedAmount;
          _isActive = settings.isActive;
          _updatedAt = settings.updatedAt;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final settings = CommissionSettings(
        id: 0,
        commissionType: _commissionType,
        commissionPercentage: _commissionPercentage,
        commissionFixedAmount: _commissionFixedAmount,
        isActive: _isActive,
      );

      await _api.updateCommissionSettings(settings.toJson());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Commission settings saved successfully',
              style: AppTypography.body.copyWith(color: AppColors.textInverse),
            ),
            backgroundColor: AppColors.successMain,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _loadSettings(); // Reload to get updated timestamp
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to save settings: ${e.toString()}',
              style: AppTypography.body.copyWith(color: AppColors.textInverse),
            ),
            backgroundColor: AppColors.errorMain,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryMain,
        ),
      );
    }

    if (_error != null && !_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.errorMain,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Error loading settings',
              style: AppTypography.heading3,
            ),
            const SizedBox(height: AppSpacing.small),
            Text(
              _error!,
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.large),
            StyledPillButton(
              label: 'Retry',
              icon: Icons.refresh,
              onPressed: _loadSettings,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Container(
        padding: isMobile 
            ? const EdgeInsets.all(AppSpacing.medium)
            : EdgeInsets.all(AppSpacing.extraLarge),
        child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Back Button
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: AppColors.warmBrown),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Go Back',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Commission Settings',
                          style: AppTypography.heading2.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Configure platform commission rates',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    children: [
                      // Active/Inactive Toggle Card
                      _buildStatusCard(),
                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Status Dependent Settings
                      IgnorePointer(
                        ignoring: !_isActive,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: _isActive ? 1.0 : 0.5,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Commission Type',
                                style: AppTypography.heading4.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.medium),
                              _buildTypeSelection(),
                              const SizedBox(height: AppSpacing.extraLarge),
                              _buildInputFields(),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.extraLarge),
                      
                      // Save Actions
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.large),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: isMobile
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_updatedAt != null) ...[
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Last Updated',
                                          style: AppTypography.caption.copyWith(
                                            color: AppColors.textTertiary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(_updatedAt!),
                                          style: AppTypography.bodySmall.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: ResponsiveUtils.getResponsivePadding(context, AppSpacing.medium)),
                                  ],
                                  StyledPillButton(
                                    label: _isSaving ? 'Saving...' : 'Save Changes',
                                    icon: Icons.check_circle_outline,
                                    onPressed: _isSaving ? null : _saveSettings,
                                    isLoading: _isSaving,
                                    width: double.infinity,
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  if (_updatedAt != null)
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Last Updated',
                                            style: AppTypography.caption.copyWith(
                                              color: AppColors.textTertiary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(_updatedAt!),
                                            style: AppTypography.bodySmall.copyWith(
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  StyledPillButton(
                                    label: _isSaving ? 'Saving...' : 'Save Changes',
                                    icon: Icons.check_circle_outline,
                                    onPressed: _isSaving ? null : _saveSettings,
                                    isLoading: _isSaving,
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ));
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isActive 
            ? [AppColors.warmBrown, AppColors.warmBrown.withOpacity(0.8)]
            : [Colors.white, Colors.white],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _isActive 
              ? AppColors.warmBrown.withOpacity(0.3)
              : Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: _isActive ? Colors.transparent : AppColors.borderPrimary.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _isActive ? Colors.white.withOpacity(0.2) : AppColors.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.monetization_on_rounded,
              color: _isActive ? Colors.white : AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform Commission',
                  style: AppTypography.heading3.copyWith(
                    color: _isActive ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _isActive ? 'Commission is currently active' : 'Commission is currently disabled',
                  style: AppTypography.bodySmall.copyWith(
                    color: _isActive ? Colors.white.withOpacity(0.9) : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isActive,
            onChanged: (value) {
              setState(() => _isActive = value);
            },
            activeThumbColor: Colors.white,
            activeTrackColor: Colors.white.withOpacity(0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.backgroundSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelection() {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTypeCard('percentage', 'Percentage', Icons.percent),
          const SizedBox(height: 12),
          _buildTypeCard('fixed', 'Fixed Amount', Icons.attach_money),
          const SizedBox(height: 12),
          _buildTypeCard('percentage_plus_fixed', 'Both', Icons.add_circle_outline),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildTypeCard('percentage', 'Percentage', Icons.percent)),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeCard('fixed', 'Fixed Amount', Icons.attach_money)),
        const SizedBox(width: 12),
        Expanded(child: _buildTypeCard('percentage_plus_fixed', 'Both', Icons.add_circle_outline)),
      ],
    );
  }

  Widget _buildTypeCard(String value, String label, IconData icon) {
    final isSelected = _commissionType == value;
    return InkWell(
      onTap: () => setState(() => _commissionType = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.warmBrown.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.warmBrown : AppColors.borderPrimary.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.warmBrown : AppColors.textSecondary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.warmBrown : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputFields() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderPrimary.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_commissionType == 'percentage' || _commissionType == 'percentage_plus_fixed')
            _buildInputField(
              label: 'Percentage',
              suffix: '%',
              initialValue: _commissionPercentage.toString(),
              onChanged: (val) {
                final num = double.tryParse(val);
                if (num != null) setState(() => _commissionPercentage = num);
              },
              validator: (val) {
                if (_commissionType.contains('percentage') && (val == null || val.isEmpty)) {
                  return 'Required';
                }
                return null;
              },
            ),
          
          if (_commissionType == 'percentage_plus_fixed')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),

          if (_commissionType == 'fixed' || _commissionType == 'percentage_plus_fixed')
            _buildInputField(
              label: 'Fixed Amount',
              prefix: '\$',
              initialValue: _commissionFixedAmount.toString(),
              onChanged: (val) {
                final num = double.tryParse(val);
                if (num != null) setState(() => _commissionFixedAmount = num);
              },
              validator: (val) {
                if (_commissionType.contains('fixed') && (val == null || val.isEmpty)) {
                  return 'Required';
                }
                return null;
              },
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? prefix,
    String? suffix,
    required String initialValue,
    required Function(String) onChanged,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.black),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            prefixText: prefix,
            suffixText: suffix,
            filled: true,
            fillColor: AppColors.backgroundSecondary.withOpacity(0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context, 16),
              vertical: ResponsiveUtils.getResponsivePadding(context, 16),
            ),
            isDense: true,
          ),
          onChanged: onChanged,
          validator: validator,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
