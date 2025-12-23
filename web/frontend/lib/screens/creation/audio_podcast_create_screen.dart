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
import '../../utils/responsive_utils.dart';
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
    // Check for web platform
    if (kIsWeb) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isMobile = screenWidth < 800; // Mobile/Tablet breakpoint for Web

      if (isMobile) {
         return _buildMobileLayout(context);
      } else {
         return _buildDesktopSplitLayout(context);
      }
    } else {
      // Mobile Platform App
      return _buildMobileLayout(context);
    }
  }

  Widget _buildDesktopSplitLayout(BuildContext context) {
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.mic,
        'title': 'Record Audio',
        'description': 'Start recording your podcast with the microphone',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioRecordingScreen()));
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
      body: Row(
        children: [
          // Left Side: Content (40%)
          Expanded(
            flex: 4,
            child: Container(
              color: AppColors.backgroundPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Back Button
                   SafeArea(
                     child: Align(
                       alignment: Alignment.topLeft,
                       child: TextButton.icon(
                         onPressed: () => Navigator.pop(context),
                         icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                         label: Text('Back', style: AppTypography.body.copyWith(color: AppColors.textPrimary)),
                         style: TextButton.styleFrom(padding: EdgeInsets.zero),
                       ),
                     ),
                   ),
                   const Spacer(),
                   
                   // Title & Description
                   Text(
                     'Create Audio Podcast',
                     style: AppTypography.heading1.copyWith(
                       color: AppColors.textPrimary,
                       fontSize: 48,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: AppSpacing.medium),
                   Text(
                     'Share your voice with the world. Record now or upload an existing file.',
                     style: AppTypography.body.copyWith(
                       color: AppColors.textSecondary,
                       fontSize: 18,
                     ),
                   ),
                   const SizedBox(height: 48),

                   // Option Cards (Vertical List)
                   ...options.map((option) {
                     return Padding(
                       padding: const EdgeInsets.only(bottom: 24),
                       child: _buildDesktopOptionCard(
                         context,
                         icon: option['icon'] as IconData,
                         title: option['title'] as String,
                         description: option['description'] as String,
                         onTap: option['onTap'] as VoidCallback,
                       ),
                     );
                   }).toList(),

                   const Spacer(),
                ],
              ),
            ),
          ),
          
          // Right Side: Image (60%)
          Expanded(
            flex: 6,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/jesus-carrying-cross.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.3),
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

  Widget _buildMobileLayout(BuildContext context) {
    // Reuse the existing mobile/responsive layout logic but cleaner
    final List<Map<String, dynamic>> options = [
      {
        'icon': Icons.mic,
        'title': 'Record Audio',
        'description': 'Start recording your podcast with the microphone',
        'onTap': () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AudioRecordingScreen()));
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
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: Row(
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
              ),
              
              // Options Grid
              Expanded(
                child: SectionContainer(
                  showShadow: true,
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.large),
                    child: ListView.separated(
                      itemCount: options.length,
                      separatorBuilder: (c, i) => SizedBox(height: AppSpacing.large),
                      itemBuilder: (context, index) {
                        final option = options[index];
                        return _buildOptionCard(
                          context,
                          icon: option['icon'] as IconData,
                          title: option['title'] as String,
                          description: option['description'] as String,
                          hoverColors: [AppColors.accentMain, AppColors.accentDark],
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

  Widget _buildDesktopOptionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.borderPrimary),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(16),
                 decoration: BoxDecoration(
                   color: AppColors.backgroundSecondary,
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, size: 32, color: AppColors.primaryMain),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.heading4.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textTertiary),
            ],
          ),
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
    final isSmallMobile = ResponsiveUtils.isSmallMobile(context);
    final iconContainerSize = isSmallMobile ? 50.0 : 70.0;
    final iconSize = isSmallMobile ? 24.0 : 36.0;

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
          padding: EdgeInsets.all(isSmallMobile ? AppSpacing.medium : AppSpacing.large),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconContainerSize,
                height: iconContainerSize,
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
                  size: iconSize,
                ),
              ),
              SizedBox(height: isSmallMobile ? AppSpacing.small : AppSpacing.medium),
              Flexible(
                child: Text(
                  widget.title,
                  style: AppTypography.heading4.copyWith(
                    color: _isHovered
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: isSmallMobile ? 16 : null,
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
                    fontSize: isSmallMobile ? 12 : null,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_isHovered) ...[
                SizedBox(height: isSmallMobile ? AppSpacing.tiny : AppSpacing.small),
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
