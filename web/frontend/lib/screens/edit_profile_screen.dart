import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../utils/responsive_utils.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  DateTime? _selectedDateOfBirth;
  bool _isCheckingUsername = false;
  String? _usernameAvailabilityMessage;
  bool _isUsernameAvailable = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    _nameController = TextEditingController(text: user?['name'] ?? '');
    _usernameController = TextEditingController(text: user?['username'] ?? '');
    _phoneController = TextEditingController();
    _bioController = TextEditingController();

    // Load user data
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.fetchUser();

    if (userProvider.user != null) {
      final user = userProvider.user!;
      setState(() {
        _nameController.text = user['name'] ?? '';
        _usernameController.text = user['username'] ?? '';
        _phoneController.text = user['phone'] ?? '';
        _bioController.text = user['bio'] ?? '';
        if (user['date_of_birth'] != null) {
          _selectedDateOfBirth = DateTime.parse(user['date_of_birth']);
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _checkUsernameAvailability(String username) async {
    if (username.length < 3) {
      setState(() {
        _usernameAvailabilityMessage = 'Username must be at least 3 characters';
        _isUsernameAvailable = false;
      });
      return;
    }

    setState(() {
      _isCheckingUsername = true;
      _usernameAvailabilityMessage = null;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final result = await userProvider.checkUsernameAvailability(username);

    setState(() {
      _isCheckingUsername = false;
      _isUsernameAvailable = result['available'] == true;
      _usernameAvailabilityMessage = result['available'] == true
          ? 'Username is available'
          : (result['message'] ?? 'Username is not available');
    });
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 18)),
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

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    final profileData = {
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'phone': _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
      'bio': _bioController.text.trim().isEmpty
          ? null
          : _bioController.text.trim(),
    };

    final success = await userProvider.updateProfile(profileData);

    if (mounted) {
      if (success) {
        // Update AuthProvider with new user data
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.checkAuthStatus(); // Refresh auth state

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.successMain,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to update profile'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    if (isMobile || isTablet) {
      return _buildMobileLayout(context, isMobile);
    } else {
      return _buildDesktopLayout(context);
    }
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Row(
        children: [
          // Left: Form (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.backgroundPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Back button
                    SafeArea(
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(Icons.arrow_back,
                              color: AppColors.textPrimary),
                          label: Text('Back',
                              style: AppTypography.body
                                  .copyWith(color: AppColors.textPrimary)),
                          style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        ),
                      ),
                    ),
                    const Spacer(),

                    // Title & Description
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit Profile',
                            style: AppTypography.heading1.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.medium),
                          Text(
                            'Update your personal information',
                            style: AppTypography.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),

                    // Form fields
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildPillTextField(
                            controller: _nameController,
                            label: 'Full Name *',
                            hint: 'Enter your full name',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildPillTextField(
                            controller: _usernameController,
                            label: 'Username *',
                            hint: 'Enter a username',
                            icon: Icons.alternate_email,
                            suffixIcon: _isCheckingUsername
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.warmBrown,
                                      ),
                                    ),
                                  )
                                : null,
                            helperText: _usernameAvailabilityMessage,
                            helperTextColor:
                                _usernameAvailabilityMessage != null
                                    ? (_isUsernameAvailable
                                        ? AppColors.successMain
                                        : AppColors.errorMain)
                                    : null,
                            onChanged: (value) {
                              if (value.length >= 3) {
                                _checkUsernameAvailability(value);
                              } else {
                                setState(() {
                                  _usernameAvailabilityMessage = null;
                                  _isUsernameAvailable = false;
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a username';
                              }
                              if (value.length < 3 || value.length > 30) {
                                return 'Username must be 3-30 characters';
                              }
                              if (!_isUsernameAvailable &&
                                  _usernameAvailabilityMessage != null &&
                                  _usernameAvailabilityMessage!
                                      .contains('not available')) {
                                return 'Username is not available';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildPillTextField(
                            controller: _phoneController,
                            label: 'Phone (Optional)',
                            hint: 'Enter your phone number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 20),

                          _buildPillDatePicker(),
                          const SizedBox(height: 20),

                          _buildPillTextField(
                            controller: _bioController,
                            label: 'Bio (Optional)',
                            hint: 'Tell us about yourself...',
                            icon: Icons.description_outlined,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 32),

                          // Save button
                          _buildGradientSaveButton(),
                        ],
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),

          // Right: Image (60%)
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/jesus.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context, bool isMobile) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E8),
      body: SizedBox(
        width: double.infinity,
        height: screenHeight,
        child: Stack(
          children: [
            // Background image
            Positioned(
              top: isMobile ? -30 : 0,
              bottom: isMobile ? null : 0,
              right: isMobile ? -screenWidth * 0.4 : -50,
              height: isMobile ? screenHeight * 0.6 : null,
              width: isMobile ? screenWidth * 1.3 : screenWidth * 0.65,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/jesus.png'),
                    fit: BoxFit.contain,
                    alignment: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFFF5F0E8),
                      const Color(0xFFF5F0E8).withOpacity(0.98),
                      const Color(0xFFF5F0E8).withOpacity(0.85),
                      const Color(0xFFF5F0E8).withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.2, 0.4, 0.6, 0.8],
                  ),
                ),
              ),
            ),

            // Form content
            Positioned.fill(
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
                    right: isSmallMobile ? AppSpacing.medium : AppSpacing.large,
                    top: 20,
                    bottom: AppSpacing.extraLarge,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button and title
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back,
                                  color: AppColors.primaryDark),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Edit Profile',
                                style: AppTypography.heading2.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: isSmallMobile ? 24 : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.small),
                        Text(
                          'Update your personal information',
                          style: AppTypography.body.copyWith(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontSize: isSmallMobile ? 14 : null,
                          ),
                        ),
                        SizedBox(height: 32),

                        // Form fields
                        _buildPillTextField(
                          controller: _nameController,
                          label: 'Full Name *',
                          hint: 'Enter your full name',
                          icon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: AppSpacing.medium),

                        _buildPillTextField(
                          controller: _usernameController,
                          label: 'Username *',
                          hint: 'Enter a username',
                          icon: Icons.alternate_email,
                          suffixIcon: _isCheckingUsername
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.warmBrown,
                                    ),
                                  ),
                                )
                              : null,
                          helperText: _usernameAvailabilityMessage,
                          helperTextColor: _usernameAvailabilityMessage != null
                              ? (_isUsernameAvailable
                                  ? AppColors.successMain
                                  : AppColors.errorMain)
                              : null,
                          onChanged: (value) {
                            if (value.length >= 3) {
                              _checkUsernameAvailability(value);
                            } else {
                              setState(() {
                                _usernameAvailabilityMessage = null;
                                _isUsernameAvailable = false;
                              });
                            }
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a username';
                            }
                            if (value.length < 3 || value.length > 30) {
                              return 'Username must be 3-30 characters';
                            }
                            if (!_isUsernameAvailable &&
                                _usernameAvailabilityMessage != null &&
                                _usernameAvailabilityMessage!
                                    .contains('not available')) {
                              return 'Username is not available';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: AppSpacing.medium),

                        _buildPillTextField(
                          controller: _phoneController,
                          label: 'Phone (Optional)',
                          hint: 'Enter your phone number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: AppSpacing.medium),

                        _buildPillDatePicker(),
                        SizedBox(height: AppSpacing.medium),

                        _buildPillTextField(
                          controller: _bioController,
                          label: 'Bio (Optional)',
                          hint: 'Tell us about yourself...',
                          icon: Icons.description_outlined,
                          maxLines: 3,
                        ),
                        SizedBox(height: AppSpacing.extraLarge),

                        // Save button
                        _buildGradientSaveButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    Widget? suffixIcon,
    String? helperText,
    Color? helperTextColor,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above field
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        // Pill container
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(maxLines > 1 ? 20 : 30),
            border: Border.all(
              color: AppColors.warmBrown.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            onChanged: onChanged,
            validator: validator,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.textTertiary),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(
                    left: AppSpacing.large, right: AppSpacing.small),
                child: Icon(icon,
                    color: AppColors.warmBrown.withOpacity(0.7), size: 20),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 48),
              suffixIcon: suffixIcon,
              border: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical:
                    maxLines > 1 ? AppSpacing.medium : (AppSpacing.medium + 4),
              ),
              errorStyle: TextStyle(
                color: AppColors.errorMain,
                fontSize: 12,
              ),
            ),
          ),
        ),
        // Helper text
        if (helperText != null && helperTextColor != null) ...[
          const SizedBox(height: 4),
          Text(
            helperText,
            style: TextStyle(
              color: helperTextColor,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPillDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date of Birth (Optional)',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateOfBirth,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: AppColors.warmBrown.withOpacity(0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.medium + 4,
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                      left: AppSpacing.large, right: AppSpacing.small),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.warmBrown.withOpacity(0.7),
                    size: 20,
                  ),
                ),
                Text(
                  _selectedDateOfBirth == null
                      ? 'Select date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
                  style: AppTypography.body.copyWith(
                    color: _selectedDateOfBirth == null
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGradientSaveButton() {
    return Consumer<UserProvider>(
      builder: (context, userProvider, _) {
        return Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.warmBrown, AppColors.accentMain],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: userProvider.isLoading ? null : _handleSave,
              borderRadius: BorderRadius.circular(30),
              child: Center(
                child: userProvider.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
