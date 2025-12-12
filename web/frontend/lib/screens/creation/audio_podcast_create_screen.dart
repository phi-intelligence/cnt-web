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
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
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
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                widget.title,
                style: AppTypography.heading3.copyWith(
                  color: _isHovered
                      ? Colors.white
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                widget.description,
                style: AppTypography.body.copyWith(
                  color: _isHovered
                      ? Colors.white.withOpacity(0.9)
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (_isHovered) ...[
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Get Started',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 18,
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
