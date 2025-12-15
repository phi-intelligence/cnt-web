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

  Widget _buildHeroHeader(bool isLargeScreen, {required bool vertical}) {
    return Container(
      width: double.infinity,
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
      child: vertical
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Schedule Your Meeting',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Set up a meeting time and invite participants to join. You can customize options and share the link easily.',
                  style: AppTypography.body.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Schedule Your Meeting',
                        style: AppTypography.heading3.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Set up a meeting time and invite participants to join',
                        style: AppTypography.body.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.warmBrown, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent() {
    return Column(
      children: [
        // Meeting Details Section
        SectionContainer(
          showShadow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meeting Details',
                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 20),

              // Meeting Title
              _buildTextField(
                label: 'Meeting Title *',
                controller: _titleController,
                hint: 'Enter meeting title',
              ),
              const SizedBox(height: 16),

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
        const SizedBox(height: 24),

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
              const SizedBox(height: 20),

              // Date Picker
              _buildDateTimeButton(
                icon: Icons.calendar_today,
                label: 'Date',
                value: _formatDate(_selectedDate),
                onTap: _selectDate,
              ),
              const SizedBox(height: 12),

              // Time Picker
              _buildDateTimeButton(
                icon: Icons.access_time,
                label: 'Time',
                value: _formatTime(_selectedTime),
                onTap: _selectTime,
              ),
              const SizedBox(height: 16),

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
        const SizedBox(height: 24),

        // Meeting Options Section
        SectionContainer(
          showShadow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Meeting Options',
                style: AppTypography.heading4.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              _buildOptionRow(Icons.videocam, 'Video enabled by default'),
              _buildOptionRow(Icons.mic, 'Microphone enabled by default'),
              _buildOptionRow(Icons.screen_share, 'Screen sharing allowed'),
              _buildOptionRow(Icons.lock, 'Waiting room enabled'),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Schedule Button - oval/rounded pill button
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
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
        const SizedBox(height: 48),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web version with register page design pattern
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 600;
      final isTablet = screenWidth >= 600 && screenWidth < 1024;
      
      return Scaffold(
        backgroundColor: const Color(0xFFF5F0E8),
        body: SizedBox(
          width: double.infinity,
          height: screenHeight,
          child: Stack(
            children: [
              // Background image positioned to the right
              Positioned(
                top: isMobile ? -30 : 0,
                bottom: isMobile ? null : 0,
                right: isMobile ? -screenWidth * 0.4 : -50,
                height: isMobile ? screenHeight * 0.6 : null,
                width: isMobile ? screenWidth * 1.3 : screenWidth * 0.65,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/images/jesus-teaching.png'),
                      fit: isMobile ? BoxFit.contain : BoxFit.cover,
                      alignment: isMobile ? Alignment.topRight : Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              
              // Gradient overlay from left
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: isMobile
                          ? [
                              const Color(0xFFF5F0E8),
                              const Color(0xFFF5F0E8).withOpacity(0.98),
                              const Color(0xFFF5F0E8).withOpacity(0.85),
                              const Color(0xFFF5F0E8).withOpacity(0.4),
                              Colors.transparent,
                            ]
                          : [
                              const Color(0xFFF5F0E8),
                              const Color(0xFFF5F0E8).withOpacity(0.99),
                              const Color(0xFFF5F0E8).withOpacity(0.95),
                              const Color(0xFFF5F0E8).withOpacity(0.7),
                              const Color(0xFFF5F0E8).withOpacity(0.3),
                              Colors.transparent,
                            ],
                      stops: isMobile
                          ? const [0.0, 0.2, 0.4, 0.6, 0.8]
                          : const [0.0, 0.25, 0.4, 0.5, 0.6, 0.75],
                    ),
                  ),
                ),
              ),
              
              // Content positioned centered/right-aligned
              Positioned(
                left: isMobile ? 0 : (screenWidth * 0.15),
                top: 0,
                bottom: 0,
                right: 0,
                child: SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
                      right: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                      top: isMobile ? 20 : 40,
                      bottom: AppSpacing.extraLarge,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with back button
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.primaryDark),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Expanded(
                              child: Text(
                                'Schedule Meeting',
                                style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 28 : (isTablet ? 36 : 42),
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.small),
                        Text(
                          'Set up a meeting time and invite participants',
                          style: AppTypography.getResponsiveBody(context).copyWith(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: AppSpacing.extraLarge * 1.5),
                        
                        // Form content
                        _buildFormContentWeb(isMobile),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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

  Widget _buildFormContentWeb(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meeting Title
        _buildPillTextField(
          controller: _titleController,
          hintText: 'Meeting Title',
          icon: Icons.event,
          isMobile: isMobile,
        ),
        SizedBox(height: AppSpacing.medium),
        
        // Description
        _buildPillTextField(
          controller: _descriptionController,
          hintText: 'Description (Optional)',
          icon: Icons.description_outlined,
          maxLines: 3,
          isMobile: isMobile,
        ),
        SizedBox(height: AppSpacing.medium),
        
        // Date Picker
        _buildPillDateButton(
          icon: Icons.calendar_today,
          label: 'Date',
          value: _formatDate(_selectedDate),
          onTap: _selectDate,
          isMobile: isMobile,
        ),
        SizedBox(height: AppSpacing.medium),
        
        // Time Picker
        _buildPillDateButton(
          icon: Icons.access_time,
          label: 'Time',
          value: _formatTime(_selectedTime),
          onTap: _selectTime,
          isMobile: isMobile,
        ),
        SizedBox(height: AppSpacing.medium),
        
        // Duration
        _buildPillTextField(
          controller: _durationController,
          hintText: 'Duration (minutes)',
          icon: Icons.timer,
          keyboardType: TextInputType.number,
          isMobile: isMobile,
        ),
        SizedBox(height: AppSpacing.extraLarge * 1.5),
        
        // Schedule Button
        Container(
          constraints: BoxConstraints(maxWidth: isMobile ? double.infinity : 450.0),
          child: StyledPillButton(
            label: 'Schedule Meeting',
            icon: Icons.schedule,
            onPressed: _isLoading ? null : _handleSchedule,
            isLoading: _isLoading,
            width: double.infinity,
          ),
        ),
      ],
    );
  }

  Widget _buildPillTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    required bool isMobile,
  }) {
    final maxWidth = isMobile ? double.infinity : 450.0;
    
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
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
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: AppTypography.body.copyWith(
          color: AppColors.primaryDark,
          fontSize: isMobile ? 14 : 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTypography.body.copyWith(
            color: AppColors.primaryDark.withOpacity(0.4),
            fontSize: isMobile ? 14 : 15,
          ),
          prefixIcon: Padding(
            padding: EdgeInsets.only(left: AppSpacing.large, right: AppSpacing.small),
            child: Icon(
              icon,
              color: AppColors.warmBrown.withOpacity(0.7),
              size: 20,
            ),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 48),
          border: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: maxLines > 1 ? AppSpacing.medium : AppSpacing.medium + 4,
          ),
        ),
      ),
    );
  }

  Widget _buildPillDateButton({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    required bool isMobile,
  }) {
    final maxWidth = isMobile ? double.infinity : 450.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: AppSpacing.medium + 4,
        ),
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
        child: Row(
          children: [
            Icon(
              icon,
              color: AppColors.warmBrown.withOpacity(0.7),
              size: 20,
            ),
            SizedBox(width: AppSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.primaryDark.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    value,
                    style: AppTypography.body.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: isMobile ? 14 : 15,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.warmBrown.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
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
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textTertiary),
            filled: true,
            fillColor: AppColors.backgroundSecondary,
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
            contentPadding: EdgeInsets.symmetric(
              horizontal: 20,
              vertical: maxLines > 1 ? 16 : 14,
            ),
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
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: AppColors.warmBrown.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(icon, color: AppColors.warmBrown, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
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
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Icon(Icons.chevron_right, color: AppColors.warmBrown, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: AppColors.warmBrown, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              text,
              style: AppTypography.body.copyWith(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.warmBrown,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(Icons.check, color: Colors.white, size: 16),
          ),
        ],
      ),
    );
  }
}

