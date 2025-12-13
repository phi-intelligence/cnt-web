import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/event.dart';
import '../../providers/event_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/section_container.dart';
import 'location_picker_screen_web.dart';

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
  
  // Location data
  LocationResult? _selectedLocation;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxAttendeesController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectLocation() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreenWeb(
          initialLocation: _selectedLocation,
        ),
      ),
    );
    
    if (result != null) {
      setState(() {
        _selectedLocation = result;
        _locationController.text = result.address;
      });
    }
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
        location: _selectedLocation?.address ?? _locationController.text.trim(),
        latitude: _selectedLocation?.latitude,
        longitude: _selectedLocation?.longitude,
        maxAttendees: _maxAttendeesController.text.isNotEmpty
            ? int.tryParse(_maxAttendeesController.text)
            : 0,
      );
      
      final provider = context.read<EventProvider>();
      final event = await provider.createEvent(eventData);
      
      if (!mounted) return;
      
      if (event != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Event created successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.pop(context, event);
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
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            backgroundColor: AppColors.backgroundPrimary,
            elevation: 0,
            pinned: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Create Event',
              style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
            ),
            centerTitle: false,
          ),
          
          // Content
          SliverPadding(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? 64 : (isMediumScreen ? 32 : 16),
              vertical: 24,
            ),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 700),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Hero Header
                        Container(
                          padding: EdgeInsets.all(isLargeScreen ? 32 : 24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppColors.warmBrown,
                                AppColors.warmBrown.withOpacity(0.85),
                                AppColors.primaryMain.withOpacity(0.9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.warmBrown.withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.event,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Host a Community Event',
                                      style: AppTypography.heading3.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Create an event and invite the community to join',
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
                        
                        SizedBox(height: 32),
                        
                        // Event Details Section
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Event Details',
                                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 20),
                              
                              // Event Title
                              _buildTextField(
                                controller: _titleController,
                                label: 'Event Title *',
                                hint: 'Enter event title',
                                icon: Icons.title,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Title must be at least 3 characters';
                                  }
                                  return null;
                                },
                              ),
                              
                              SizedBox(height: 16),
                              
                              // Description
                              _buildTextField(
                                controller: _descriptionController,
                                label: 'Description (Optional)',
                                hint: 'What is this event about?',
                                icon: Icons.description,
                                maxLines: 4,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Date & Time Section
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 20),
                              
                              Row(
                                children: [
                                  // Date Picker
                                  Expanded(
                                    child: _buildDateTimePicker(
                                      icon: Icons.calendar_today,
                                      label: 'Date',
                                      value: DateFormat('MMM d, yyyy').format(_selectedDate),
                                      onTap: _selectDate,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  // Time Picker
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
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Location Section
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Location',
                                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 20),
                              
                              // Location picker button
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: _selectLocation,
                                  child: Container(
                                    padding: EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundSecondary,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.warmBrown.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.warmBrown.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            Icons.location_on,
                                            color: AppColors.warmBrown,
                                            size: 22,
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Event Location (Optional)',
                                                style: TextStyle(
                                                  color: AppColors.textSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                _selectedLocation != null
                                                    ? _selectedLocation!.address.isNotEmpty
                                                        ? _selectedLocation!.address
                                                        : 'Location selected'
                                                    : 'Click to select on map',
                                                style: TextStyle(
                                                  color: _selectedLocation != null
                                                      ? AppColors.textPrimary
                                                      : AppColors.textSecondary,
                                                  fontSize: 14,
                                                  fontWeight: _selectedLocation != null
                                                      ? FontWeight.w500
                                                      : FontWeight.normal,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.map,
                                          color: AppColors.warmBrown.withOpacity(0.6),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              
                              if (_selectedLocation != null)
                                Padding(
                                  padding: EdgeInsets.only(top: 8),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _selectedLocation = null;
                                          _locationController.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.clear,
                                        size: 16,
                                        color: AppColors.textSecondary,
                                      ),
                                      label: Text(
                                        'Clear location',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              
                              SizedBox(height: 16),
                              
                              // Or enter manually
                              Text(
                                'Or enter address manually:',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              SizedBox(height: 8),
                              _buildTextField(
                                controller: _locationController,
                                label: 'Address',
                                hint: 'Enter event address',
                                icon: Icons.edit_location_alt,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Capacity Section
                        SectionContainer(
                          showShadow: true,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Capacity',
                                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 20),
                              
                              _buildTextField(
                                controller: _maxAttendeesController,
                                label: 'Max Attendees (Optional)',
                                hint: 'Leave empty for unlimited',
                                icon: Icons.group,
                                keyboardType: TextInputType.number,
                              ),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: 32),
                        
                        // Create Button
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.warmBrown,
                                AppColors.accentMain,
                              ],
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
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.event_available, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Create Event',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        
                        SizedBox(height: 48),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            prefixIcon: Padding(
              padding: EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: AppColors.warmBrown),
            ),
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
              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide(color: Colors.red),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 16 : 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimePicker({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.warmBrown.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.warmBrown, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppColors.warmBrown.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

