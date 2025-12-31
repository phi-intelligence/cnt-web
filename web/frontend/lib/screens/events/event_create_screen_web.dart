import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/platform_helper.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../widgets/events/event_approval_dialog.dart';

/// Data class to hold location result
class LocationResult {
  final double latitude;
  final double longitude;
  final String address;

  LocationResult({
    required this.latitude,
    required this.longitude,
    required this.address,
  });
}

class EventCreateScreenWeb extends StatefulWidget {
  const EventCreateScreenWeb({super.key});

  @override
  State<EventCreateScreenWeb> createState() => _EventCreateScreenWebState();
}

class _EventCreateScreenWebState extends State<EventCreateScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxAttendeesController = TextEditingController();
  final _locationController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 18, minute: 0);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxAttendeesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  DateTime get _eventDateTime {
    return DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.warmBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.warmBrown,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate date is in the future
    if (_eventDateTime.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Event date must be in the future'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final eventData = EventCreate(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        eventDate: _eventDateTime,
        location: _locationController.text.trim(),
        latitude: null,
        longitude: null,
        maxAttendees: _maxAttendeesController.text.isNotEmpty
            ? int.tryParse(_maxAttendeesController.text)
            : 0,
      );
      
      final provider = context.read<EventProvider>();
      final event = await provider.createEvent(eventData);
      
      if (!mounted) return;
      
      if (event != null) {
        // Check if user is admin
        final authProvider = context.read<AuthProvider>();
        final isAdmin = authProvider.isAdmin;
        
        // Show approval dialog instead of snackbar
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => EventApprovalDialog(isAdmin: isAdmin),
        );
        
        // Navigate back after dialog is dismissed
        if (mounted) {
          Navigator.pop(context, event);
        }
      } else if (provider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = PlatformHelper.getScreenType(screenWidth) == ScreenType.mobile;

    return isMobile 
        ? _buildMobileLayout(context)
        : _buildDesktopLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          // Left Side - Form (40% width)
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.backgroundPrimary,
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    child: Row(
                      children: [
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.medium,
                                vertical: AppSpacing.small,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warmBrown.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: AppColors.warmBrown.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back,
                                    size: 18,
                                    color: AppColors.warmBrown,
                                  ),
                                  const SizedBox(width: AppSpacing.tiny),
                                  Text(
                                    'Back to Events',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: AppColors.warmBrown,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Form Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              StyledPageHeader(
                                title: 'Host an Event',
                                // Subtitle removed as it is not supported in StyledPageHeader
                                // subtitle: 'Create an event and invite the community to join.',
                              ),
                              const SizedBox(height: AppSpacing.large),

                              // Form Sections
                              _buildFormSection(
                                title: 'Event Details',
                                children: [
                                  _buildTextField(
                                    controller: _titleController,
                                    label: 'Event Title',
                                    hint: 'e.g., Weekly Bible Study',
                                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  _buildTextField(
                                    controller: _descriptionController,
                                    label: 'Description',
                                    hint: 'What is this event about?',
                                    maxLines: 4,
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: AppSpacing.large),
                              
                              _buildFormSection(
                                title: 'Date & Time',
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildDateTimePicker(
                                          icon: Icons.calendar_today,
                                          label: 'Date',
                                          value: DateFormat('MMM d, yyyy').format(_selectedDate),
                                          onTap: _selectDate,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.medium),
                                      Expanded(
                                        child: _buildDateTimePicker(
                                          icon: Icons.access_time,
                                          label: 'Time',
                                          value: _selectedTime.format(context),
                                          onTap: _selectTime,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.large),

                              _buildFormSection(
                                title: 'Location',
                                children: [
                                  _buildTextField(
                                    controller: _locationController,
                                    label: 'Address',
                                    hint: 'Enter full address',
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.large),

                              _buildFormSection(
                                title: 'Capacity',
                                children: [
                                  _buildTextField(
                                    controller: _maxAttendeesController,
                                    label: 'Max Attendees',
                                    hint: 'Leave empty for unlimited',
                                    keyboardType: TextInputType.number,
                                  ),
                                ],
                              ),

                              const SizedBox(height: AppSpacing.extraLarge),

                              // Actions
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  StyledPillButton(
                                    label: 'Cancel',
                                    icon: Icons.close,
                                    onPressed: () => Navigator.pop(context),
                                    variant: StyledPillButtonVariant.outlined,
                                  ),
                                  const SizedBox(width: AppSpacing.medium),
                                  StyledPillButton(
                                    label: _isSubmitting ? 'Creating...' : 'Create Event',
                                    icon: _isSubmitting ? null : Icons.check,
                                    onPressed: _isSubmitting ? null : _handleSubmit,
                                    variant: StyledPillButtonVariant.filled,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Right Side - Image (60% width)
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/Jesus-crowd.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: [
                      Colors.black.withOpacity(0.2),
                      Colors.black.withOpacity(0.4),
                    ],
                  ),
                ),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xxl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event, size: 80, color: Colors.white.withOpacity(0.9)),
                        const SizedBox(height: AppSpacing.large),
                        Text(
                          'Gather Together in His Name',
                          style: AppTypography.heroTitle.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.medium),
                        Text(
                          'For where two or three gather in my name, there am I with them.\nMatthew 18:20',
                          style: AppTypography.heading4.copyWith(
                            color: Colors.white.withOpacity(0.9),
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    // Keep a simplified version of the original layout for mobile
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Event'),
        backgroundColor: AppColors.backgroundPrimary,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildFormSection(
                title: 'Event Details',
                children: [
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'Event Title',
                    validator: (v) => v?.isEmpty == true ? 'Required' : null,
                  ),
                  const SizedBox(height: AppSpacing.medium),
                   _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Details...',
                    maxLines: 3,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildFormSection(
                  title: 'Date & Time',
                  children: [
                     _buildDateTimePicker(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: DateFormat('MMM d, yyyy').format(_selectedDate),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: AppSpacing.small),
                    _buildDateTimePicker(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: _selectedTime.format(context),
                      onTap: _selectTime,
                    ),
                  ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildFormSection(
                title: 'Location',
                children: [
                  _buildTextField(
                    controller: _locationController,
                    label: 'Address',
                    hint: 'Enter full address',
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.medium),
              _buildFormSection(
                title: 'Capacity',
                children: [
                  _buildTextField(
                    controller: _maxAttendeesController,
                    label: 'Max Attendees',
                    hint: 'Leave empty for unlimited',
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              StyledPillButton(
                label: 'Create Event',
                variant: StyledPillButtonVariant.filled,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: AppSpacing.medium),
        ...children,
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: AppTypography.body.copyWith(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppColors.textPrimary),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.borderPrimary),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorMain),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.errorMain, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDateTimePicker({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.borderPrimary),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

