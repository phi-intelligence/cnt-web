import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

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
      initialDate: _selectedDateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
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
      'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      'date_of_birth': _selectedDateOfBirth?.toIso8601String(),
      'bio': _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
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
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userProvider.error ?? 'Failed to update profile'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Username field with availability check
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username *',
                  prefixIcon: const Icon(Icons.alternate_email),
                  suffixIcon: _isCheckingUsername
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: Padding(
                            padding: EdgeInsets.all(12.0),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  helperText: _usernameAvailabilityMessage,
                  helperStyle: TextStyle(
                    color: _isUsernameAvailable ? Colors.green : Colors.red,
                  ),
                ),
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
                  if (!_isUsernameAvailable && _usernameAvailabilityMessage != null && _usernameAvailabilityMessage!.contains('not available')) {
                    return 'Username is not available';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Phone field
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (Optional)',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // Date of birth field
              InkWell(
                onTap: _selectDateOfBirth,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of Birth (Optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDateOfBirth == null
                        ? 'Select date'
                        : DateFormat('yyyy-MM-dd').format(_selectedDateOfBirth!),
                    style: TextStyle(
                      color: _selectedDateOfBirth == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Bio field
              TextFormField(
                controller: _bioController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Bio (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              
              // Save button
              Consumer<UserProvider>(
                builder: (context, userProvider, _) {
                  return ElevatedButton(
                    onPressed: userProvider.isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: userProvider.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(fontSize: 16),
                          ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

