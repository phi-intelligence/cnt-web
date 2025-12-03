import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../services/api_service.dart';
import 'meeting_created_screen.dart';

/// Schedule Meeting Screen
/// Form to schedule a meeting with date/time picker
class ScheduleMeetingScreen extends StatefulWidget {
  const ScheduleMeetingScreen({super.key});

  @override
  State<ScheduleMeetingScreen> createState() => _ScheduleMeetingScreenState();
}

class _ScheduleMeetingScreenState extends State<ScheduleMeetingScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '60');

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    // Use DateFormat to get weekday abbreviation (Mon, Tue, etc.)
    final weekday = DateFormat('EEE').format(date);
    return '$weekday ${date.month}/${date.day}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  void _handleSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a meeting title')),
      );
      return;
    }

    setState(() { _isLoading = true; });

    try {
      // Build scheduled start datetime
      final scheduled = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      final resp = await ApiService().createStream(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        scheduledStart: scheduled,
      );
      final meetingId = (resp['id'] ?? '').toString();
      final roomName = resp['room_name'] as String;
      // Generate meeting link using LiveKit URL format (or app-specific format)
      final liveKitUrl = ApiService().getLiveKitUrl().replaceAll('ws://', 'http://').replaceAll('wss://', 'https://');
      final meetingLink = '$liveKitUrl/meeting/$roomName';

      if (!mounted) return;
      setState(() { _isLoading = false; });
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MeetingCreatedScreen(
              meetingId: meetingId,
              meetingLink: meetingLink,
              isInstant: false,
            ),
          ),
        );
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule meeting: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with web design system
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Gradient header section similar to landing page
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(AppSpacing.extraLarge),
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
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.warmBrown.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Meeting',
                                style: AppTypography.heading2.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: AppSpacing.tiny),
                              Text(
                                'Plan your meeting in advance',
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
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Meeting Details Section
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting Details',
                          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Meeting Title
                        _buildTextField(
                          label: 'Meeting Title *',
                          controller: _titleController,
                          hint: 'Enter meeting title',
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Description
                        _buildTextField(
                          label: 'Description (Optional)',
                          controller: _descriptionController,
                          hint: 'Enter meeting description',
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // Date & Time Section
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date & Time',
                          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Date Picker
                        _buildDateTimeButton(
                          icon: Icons.calendar_today,
                          label: 'Date',
                          value: _formatDate(_selectedDate),
                          onTap: _selectDate,
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Time Picker
                        _buildDateTimeButton(
                          icon: Icons.access_time,
                          label: 'Time',
                          value: _formatTime(_selectedTime),
                          onTap: _selectTime,
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        // Duration
                        _buildTextField(
                          label: 'Duration (minutes)',
                          controller: _durationController,
                          hint: '60',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // Meeting Options Section
                  SectionContainer(
                    showShadow: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting Options',
                          style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                        ),
                        const SizedBox(height: AppSpacing.medium),

                        _buildOptionRow(Icons.videocam, 'Video enabled by default'),
                        _buildOptionRow(Icons.mic, 'Microphone enabled by default'),
                        _buildOptionRow(Icons.screen_share, 'Screen sharing allowed'),
                        _buildOptionRow(Icons.lock, 'Waiting room enabled'),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Schedule Button - oval/rounded pill button
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
                      onPressed: _isLoading ? null : _handleSchedule,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
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
                                const Icon(Icons.schedule, color: Colors.white, size: 20),
                                const SizedBox(width: AppSpacing.small),
                                Text(
                                  'Schedule Meeting',
                                  style: AppTypography.button.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),
                ],
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Schedule Meeting',
            style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
          ),
          centerTitle: true,
          actions: [
            const SizedBox(width: 40),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meeting Details Section
                    Text(
                      'Meeting Details',
                      style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Meeting Title
                    _buildTextField(
                      label: 'Meeting Title *',
                      controller: _titleController,
                      hint: 'Enter meeting title',
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Description
                    _buildTextField(
                      label: 'Description (Optional)',
                      controller: _descriptionController,
                      hint: 'Enter meeting description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),

                    // Date & Time Section
                    Text(
                      'Date & Time',
                      style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Date Picker
                    _buildDateTimeButton(
                      icon: Icons.calendar_today,
                      label: 'Date',
                      value: _formatDate(_selectedDate),
                      onTap: _selectDate,
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Time Picker
                    _buildDateTimeButton(
                      icon: Icons.access_time,
                      label: 'Time',
                      value: _formatTime(_selectedTime),
                      onTap: _selectTime,
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // Duration
                    _buildTextField(
                      label: 'Duration (minutes)',
                      controller: _durationController,
                      hint: '60',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),

                    // Meeting Options
                    Text(
                      'Meeting Options',
                      style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    _buildOptionRow(Icons.videocam, 'Video enabled by default'),
                    _buildOptionRow(Icons.mic, 'Microphone enabled by default'),
                    _buildOptionRow(Icons.screen_share, 'Screen sharing allowed'),
                    _buildOptionRow(Icons.lock, 'Waiting room enabled'),
                  ],
                ),
              ),
            ),

            // Schedule Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: AppColors.backgroundPrimary,
                border: Border(
                  top: BorderSide(color: AppColors.borderPrimary, width: 1),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSchedule,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryMain,
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.large),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.schedule, color: Colors.white),
                            const SizedBox(width: AppSpacing.small),
                            Text(
                              'Schedule Meeting',
                              style: AppTypography.body.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.tiny),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderPrimary),
            ),
            contentPadding: const EdgeInsets.all(AppSpacing.medium),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: AppColors.warmBrown,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.warmBrown, size: 24),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.warmBrown),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.small),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryMain, size: 20),
          const SizedBox(width: AppSpacing.medium),
          Text(
            text,
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

