import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/platform_helper.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import 'video_recording_screen.dart';
import 'video_preview_screen.dart';
import '../web/video_recording_screen_web.dart';
import '../web/video_preview_screen_web.dart';
import 'package:image_picker/image_picker.dart';
// Conditional import for dart:io (only on non-web platforms)
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;

/// Video Podcast Create Screen
/// Shows options to record video or choose from gallery
class VideoPodcastCreateScreen extends StatelessWidget {
  const VideoPodcastCreateScreen({super.key});

  Future<void> _selectVideoFromGallery(BuildContext context) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (video != null && context.mounted) {
        int fileSize = 0;
        int estimatedDuration = 180; // Default estimate
        
        if (kIsWeb) {
          // Web: Read bytes to get file size
          try {
            final bytes = await video.readAsBytes();
            fileSize = bytes.length;
          } catch (e) {
            print('Error reading video bytes on web: $e');
            // Continue with fileSize = 0
          }
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreenWeb(
                videoUri: video.path,
                source: 'gallery',
                duration: estimatedDuration,
                fileSize: fileSize,
              ),
            ),
          );
        } else {
          // Mobile: Use File operations
          final file = io.File(video.path);
          fileSize = await file.length();
          
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoPreviewScreen(
                videoUri: video.path,
                source: 'gallery',
                duration: estimatedDuration,
                fileSize: fileSize,
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting video: $e'),
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
        'icon': Icons.videocam,
        'title': 'Record Video',
        'description': 'Use your camera to record a new video podcast',
        'onTap': () {
          // Use platform-specific recording screen
          if (PlatformHelper.isWebPlatform()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VideoRecordingScreenWeb(),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const VideoRecordingScreen(),
              ),
            );
          }
        },
      },
      {
        'icon': Icons.photo_library,
        'title': 'Choose from Gallery',
        'description': 'Select an existing video from your gallery',
        'onTap': () => _selectVideoFromGallery(context),
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
                    title: 'Create Video Podcast',
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
                      return _buildOptionCard(
                        context,
                        icon: option['icon'] as IconData,
                        title: option['title'] as String,
                        description: option['description'] as String,
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
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
            border: Border.all(
              color: AppColors.borderPrimary,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMain.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(AppSpacing.extraLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryMain.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: AppColors.primaryMain,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                title,
                style: AppTypography.heading3.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.small),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
