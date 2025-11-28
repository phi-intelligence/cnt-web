import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../web/admin_dashboard_web.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import 'landing_screen_web.dart';

/// Web Register Screen - Redesigned to match web application theme
/// Uses SectionContainer, StyledPageHeader, and web styling components
class RegisterScreenWeb extends StatefulWidget {
  const RegisterScreenWeb({super.key});

  @override
  State<RegisterScreenWeb> createState() => _RegisterScreenWebState();
}

class _RegisterScreenWebState extends State<RegisterScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _selectedDateOfBirth;
  String? _generatedUsername;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _generateUsernamePreview() {
    if (_emailController.text.isNotEmpty) {
      final email = _emailController.text.trim();
      if (email.contains('@')) {
        final username = email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
        setState(() {
          _generatedUsername = username;
        });
      }
    } else if (_nameController.text.isNotEmpty) {
      final name = _nameController.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
      setState(() {
        _generatedUsername = name;
      });
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.warmBrown,
              onPrimary: Colors.white,
              surface: AppColors.backgroundSecondary,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (authProvider.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Registration failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  // Google Sign-In temporarily disabled
  // Uncomment below to enable Google Sign-In
  /*
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLogin();

    setState(() => _isLoading = false);

    if (mounted) {
      if (success) {
        if (authProvider.isAdmin) {
          context.go('/admin');
        } else {
          context.go('/home');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.error ?? 'Google sign-in failed'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }
  */

  InputDecoration _buildInputDecoration(String label, IconData icon, {bool isOptional = false}) {
    return InputDecoration(
      labelText: isOptional ? label : '$label *',
      labelStyle: AppTypography.body.copyWith(
        color: AppColors.textSecondary,
      ),
      prefixIcon: Icon(icon, color: AppColors.warmBrown),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.borderPrimary),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.borderPrimary),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
      ),
      filled: true,
      fillColor: AppColors.backgroundSecondary,
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LandingScreenWeb(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StyledPageHeader(
                          title: 'Create Account',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Registration Form Container
                  SectionContainer(
                    showShadow: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Subtitle
                          Text(
                            'Join Christ New Tabernacle and start sharing your content',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.extraLarge),

                          // Required Fields Section
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _nameController,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                                        onChanged: (_) => _generateUsernamePreview(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your name';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.large),
                                      TextFormField(
                                        controller: _emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _buildInputDecoration('Email', Icons.email_outlined),
                                        onChanged: (_) => _generateUsernamePreview(),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your email';
                                          }
                                          if (!value.contains('@') || !value.contains('.')) {
                                            return 'Please enter a valid email';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.large),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons.visibility_off_outlined,
                                              color: AppColors.textSecondary,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter a password';
                                          }
                                          if (value.length < 8) {
                                            return 'Password must be at least 8 characters';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: AppSpacing.large),
                                      TextFormField(
                                        controller: _phoneController,
                                        keyboardType: TextInputType.phone,
                                        style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                        ),
                                        decoration: _buildInputDecoration('Phone', Icons.phone_outlined, isOptional: true),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                                  onChanged: (_) => _generateUsernamePreview(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your name';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.large),
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _buildInputDecoration('Email', Icons.email_outlined),
                                  onChanged: (_) => _generateUsernamePreview(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your email';
                                    }
                                    if (!value.contains('@') || !value.contains('.')) {
                                      return 'Please enter a valid email';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.large),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _buildInputDecoration('Password', Icons.lock_outline).copyWith(
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        color: AppColors.textSecondary,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscurePassword = !_obscurePassword;
                                        });
                                      },
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a password';
                                    }
                                    if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: AppSpacing.large),
                                TextFormField(
                                  controller: _phoneController,
                                  keyboardType: TextInputType.phone,
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                  decoration: _buildInputDecoration('Phone', Icons.phone_outlined, isOptional: true),
                                ),
                              ],
                            ),

                          // Username preview
                          if (_generatedUsername != null) ...[
                            const SizedBox(height: AppSpacing.medium),
                            Container(
                              padding: EdgeInsets.all(AppSpacing.medium),
                              decoration: BoxDecoration(
                                color: AppColors.warmBrown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                border: Border.all(
                                  color: AppColors.warmBrown.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: AppColors.warmBrown,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.small),
                                  Expanded(
                                    child: Text(
                                      'Your username will be: $_generatedUsername',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.warmBrown,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: AppSpacing.large),

                          // Optional Fields Section
                          Text(
                            'Additional Information (Optional)',
                            style: AppTypography.heading4.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'These fields help us personalize your experience',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.large),

                          // Date of Birth
                          InkWell(
                            onTap: _selectDateOfBirth,
                            child: InputDecorator(
                              decoration: _buildInputDecoration('Date of Birth', Icons.calendar_today_outlined, isOptional: true),
                              child: Text(
                                _selectedDateOfBirth == null
                                    ? 'Select date'
                                    : DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
                                style: AppTypography.body.copyWith(
                                  color: _selectedDateOfBirth == null
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.large),

                          // Bio
                          TextFormField(
                            controller: _bioController,
                            maxLines: 3,
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: _buildInputDecoration('Bio', Icons.description_outlined, isOptional: true).copyWith(
                              alignLabelWithHint: true,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.extraLarge),

                          // Register Button
                          StyledPillButton(
                            label: 'Create Account',
                            icon: Icons.person_add,
                            onPressed: _isLoading ? null : _handleRegister,
                            isLoading: _isLoading,
                            width: double.infinity,
                          ),
                          // Google Sign-In temporarily disabled
                          // Uncomment below to enable Google Sign-In
                          /*
                          const SizedBox(height: AppSpacing.large),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: AppColors.borderPrimary,
                                  thickness: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                                child: Text(
                                  'OR',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: AppColors.borderPrimary,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.large),

                          // Google Sign-In Button
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _handleGoogleSignIn,
                            icon: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.g_mobiledata,
                                size: 18,
                                color: Color(0xFF4285F4), // Google Blue
                              ),
                            ),
                            label: Text(
                              'Sign up with Google',
                              style: AppTypography.button.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.medium,
                              ),
                              side: BorderSide(color: AppColors.borderPrimary),
                              foregroundColor: AppColors.textPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => const LandingScreenWeb(),
                            ),
                          );
                        },
                        child: Text(
                          'Sign In',
                          style: AppTypography.body.copyWith(
                            color: AppColors.warmBrown,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
