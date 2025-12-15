import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import 'audio_recording_screen.dart';
import 'audio_preview_screen.dart';
import 'package:file_picker/file_picker.dart';
// Conditional imports for platform-specific features
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import 'dart:html' if (dart.library.io) '../../utils/html_stub.dart' as html;

/// Audio Podcast Create Screen
/// Shows options to record audio or upload file
class AudioPodcastCreateScreen extends StatelessWidget {
  const AudioPodcastCreateScreen({super.key});

  Future<void> _selectAudioFile(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
        withData: true, // Always load bytes for web compatibility
      );

      if (result != null && context.mounted) {
        final file = result.files.single;
        int fileSize = 0;
        int estimatedDuration = 180; // Default estimate
        String audioUri;

        if (kIsWeb) {
          // Web: Must use bytes since path is unavailable on web platform
          final bytes = file.bytes;
          if (bytes == null || bytes.isEmpty) {
            throw Exception('No audio data available. Please try selecting the file again.');
          }
          fileSize = bytes.length;

          // Create a blob URL for web playback
          // Determine MIME type from file extension
          final fileName = file.name.toLowerCase();
          String mimeType = 'audio/mpeg'; // default
          if (fileName.endsWith('.wav')) {
            mimeType = 'audio/wav';
          } else if (fileName.endsWith('.webm')) {
            mimeType = 'audio/webm';
          } else if (fileName.endsWith('.ogg')) {
            mimeType = 'audio/ogg';
          } else if (fileName.endsWith('.m4a')) {
            mimeType = 'audio/mp4';
          } else if (fileName.endsWith('.aac')) {
            mimeType = 'audio/aac';
          } else if (fileName.endsWith('.flac')) {
            mimeType = 'audio/flac';
          }

          final blob = html.Blob([bytes], mimeType);
          audioUri = html.Url.createObjectUrlFromBlob(blob);

          print('🎵 Web: Created blob URL for audio file: $audioUri (${fileSize} bytes, $mimeType)');
        } else {
          // Mobile: Use file path
          final audioPath = file.path;
          if (audioPath == null || audioPath.isEmpty) {
            throw Exception('No file path available');
          }
          audioUri = audioPath;
          final ioFile = io.File(audioPath);
          fileSize = await ioFile.length();
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AudioPreviewScreen(
              audioUri: audioUri,
              source: 'file',
              duration: estimatedDuration,
              fileSize: fileSize,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting audio file: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1024;

    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.mic,
        'title': 'Record Audio',
        'description': 'Start recording your podcast with the microphone',
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AudioRecordingScreen(),
            ),
          );
        },
      },
      {
        'icon': Icons.audiotrack,
        'title': 'Upload Audio',
        'description': 'Select an existing audio file from your device',
        'onTap': () => _selectAudioFile(context),
      },
    ];

    if (kIsWeb) {
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
                      image: const AssetImage('assets/images/jesus-carrying-cross.png'),
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
                                'Create Audio Podcast',
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
                          'Record audio or upload an existing file',
                          style: AppTypography.getResponsiveBody(context).copyWith(
                            color: AppColors.primaryDark.withOpacity(0.7),
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        SizedBox(height: AppSpacing.extraLarge * 1.5),
                        
                        // Options Grid - centered on page
                        Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? double.infinity : 700,
                            ),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isMobile ? 1 : 2,
                                crossAxisSpacing: AppSpacing.large,
                                mainAxisSpacing: AppSpacing.large,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                // Alternate hover colors: orange for odd (1), brown for even (2)
                                final hoverColors = index % 2 == 0
                                    ? [AppColors.accentMain, AppColors.accentDark] // Orange
                                    : [AppColors.warmBrown, AppColors.primaryMain]; // Brown
                                return _buildOptionCard(
                                  context,
                                  icon: option['icon'] as IconData,
                                  title: option['title'] as String,
                                  description: option['description'] as String,
                                  hoverColors: hoverColors,
                                  onTap: option['onTap'] as VoidCallback,
                                );
                              },
                            ),
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
      );
    } else {
      // Mobile version (original design)
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Container(
          padding: ResponsiveGridDelegate.getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with back button
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: StyledPageHeader(
                      title: 'Create Audio Podcast',
                      size: StyledPageHeaderSize.h2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              
              // Options Grid
              Expanded(
                child: SectionContainer(
                  showShadow: true,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: GridView.builder(
                      gridDelegate: ResponsiveGridDelegate.getResponsiveGridDelegate(
                        context,
                        desktop: 2,
                        tablet: 2,
                        mobile: 1,
                        childAspectRatio: 1.5,
                        crossAxisSpacing: AppSpacing.large,
                        mainAxisSpacing: AppSpacing.large,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        // Alternate hover colors: orange for odd (1), brown for even (2)
                        final hoverColors = index % 2 == 0
                            ? [AppColors.accentMain, AppColors.accentDark] // Orange
                            : [AppColors.warmBrown, AppColors.primaryMain]; // Brown
                        return _buildOptionCard(
                          context,
                          icon: option['icon'] as IconData,
                          title: option['title'] as String,
                          description: option['description'] as String,
                          hoverColors: hoverColors,
                          onTap: option['onTap'] as VoidCallback,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required List<Color> hoverColors,
    required VoidCallback onTap,
  }) {
    return _OptionCard(
      icon: icon,
      title: title,
      description: description,
      hoverColors: hoverColors,
      onTap: onTap,
    );
  }
}

class _OptionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> hoverColors;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.hoverColors,
    required this.onTap,
  });

  @override
  State<_OptionCard> createState() => _OptionCardState();
}

class _OptionCardState extends State<_OptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isHovered
                  ? widget.hoverColors
                  : [
                      AppColors.cardBackground,
                      AppColors.backgroundSecondary,
                    ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: _isHovered
                  ? widget.hoverColors.first
                  : AppColors.borderPrimary,
              width: _isHovered ? 2 : 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: widget.hoverColors.first.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                      spreadRadius: 2,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.2)
                      : AppColors.warmBrown.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isHovered
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.warmBrown.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: _isHovered
                      ? Colors.white
                      : AppColors.warmBrown,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.small),
              Flexible(
                child: Text(
                  widget.title,
                  style: AppTypography.heading4.copyWith(
                    color: _isHovered
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.tiny),
              Flexible(
                child: Text(
                  widget.description,
                  style: AppTypography.bodySmall.copyWith(
                    color: _isHovered
                        ? Colors.white.withOpacity(0.9)
                        : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) ...[
                const SizedBox(height: AppSpacing.small),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.tiny),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
