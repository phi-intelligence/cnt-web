import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'admin_dashboard.dart';
import 'user_login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _selectedDateOfBirth;
  String? _generatedUsername;
  bool _isCheckingUsername = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _generateUsernamePreview() async {
    if (_emailController.text.isNotEmpty) {
      // Generate username from email (part before @)
      final email = _emailController.text.trim();
      if (email.contains('@')) {
        final username = email.split('@')[0].toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
        setState(() {
          _generatedUsername = username;
        });
      }
    } else if (_nameController.text.isNotEmpty) {
      // Generate from name
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

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
    );

    if (mounted) {
      if (success) {
        // Route based on user role
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

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.googleLogin();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          'Create Account',
          style: AppTypography.heading3.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            padding: const EdgeInsets.all(AppSpacing.extraLarge),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Welcome!',
                      style: AppTypography.heading1.copyWith(
                        color: AppColors.warmBrown,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      'Create your account to get started',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                    
                    // Name field
                    _buildTextField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person_outline,
                      onChanged: (_) => _generateUsernamePreview(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Email field
                    _buildTextField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => _generateUsernamePreview(),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    
                    // Generated username preview
                    if (_generatedUsername != null)
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.accentMain.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          border: Border.all(color: AppColors.accentMain.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.accentMain, size: 20),
                            const SizedBox(width: AppSpacing.small),
                            Expanded(
                              child: Text(
                                'Your username will be: $_generatedUsername',
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.accentMain,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_generatedUsername != null) const SizedBox(height: AppSpacing.large),
                    
                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryMain),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: AppColors.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide(color: AppColors.borderPrimary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide(color: AppColors.borderPrimary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.large,
                          vertical: AppSpacing.medium,
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
                    
                    // Phone field (optional)
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone (Optional)',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Date of birth field (optional)
                    InkWell(
                      onTap: _selectDateOfBirth,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth (Optional)',
                          labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
                          prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primaryMain),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            borderSide: BorderSide(color: AppColors.borderPrimary),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.large,
                            vertical: AppSpacing.medium,
                          ),
                        ),
                        child: Text(
                          _selectedDateOfBirth == null
                              ? 'Select date'
                              : DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
                          style: AppTypography.body.copyWith(
                            color: _selectedDateOfBirth == null ? AppColors.textPlaceholder : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Bio field (optional)
                    TextFormField(
                      controller: _bioController,
                      maxLines: 3,
                      style: AppTypography.body,
                      decoration: InputDecoration(
                        labelText: 'Bio (Optional)',
                        labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.description_outlined, color: AppColors.primaryMain),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium), // Less rounded for multiline
                          borderSide: BorderSide(color: AppColors.borderPrimary),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: BorderSide(color: AppColors.borderPrimary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                          borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
                        ),
                        alignLabelWithHint: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.large,
                          vertical: AppSpacing.medium,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    
                    // Register button
                    Consumer<AuthProvider>(
                      builder: (context, authProvider, _) {
                        return ElevatedButton(
                          onPressed: authProvider.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warmBrown,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            elevation: 4,
                          ),
                          child: authProvider.isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  'Create Account',
                                  style: AppTypography.button.copyWith(color: Colors.white),
                                ),
                        );
                      },
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Divider
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.borderPrimary)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                          child: Text(
                            'OR',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.borderPrimary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Google Sign-In button
                    OutlinedButton.icon(
                      onPressed: _handleGoogleSignIn,
                      icon: const Icon(Icons.g_mobiledata, size: 24),
                      label: Text(
                        'Continue with Google',
                        style: AppTypography.button.copyWith(color: AppColors.textPrimary),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
                        side: BorderSide(color: AppColors.borderPrimary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),
                    
                    // Login link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: AppTypography.body.copyWith(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const UserLoginScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: AppTypography.body.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: AppTypography.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.label.copyWith(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primaryMain),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium,
        ),
      ),
      onChanged: onChanged,
      validator: validator,
    );
  }
}
