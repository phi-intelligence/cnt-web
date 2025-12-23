import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/platform_helper.dart';
import '../../utils/responsive_utils.dart';
import 'package:image_picker/image_picker.dart';
import '../web/movie_preview_screen_web.dart';
import '../web/video_recording_screen_web.dart';
// Conditional import for dart:io (only on non-web platforms)
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;

/// Movie Create Screen
/// Shows options to record video or choose from gallery
class MovieCreateScreen extends StatelessWidget {
  const MovieCreateScreen({super.key});

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
              builder: (_) => MoviePreviewScreenWeb(
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
              builder: (_) => MoviePreviewScreenWeb(
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
            // Content positioned
            Positioned(
              left: isMobile ? 0 : (screenWidth * 0.15),
              top: 0,
              bottom: 0,
              width: isMobile ? screenWidth : (isTablet ? screenWidth * 0.7 : screenWidth * 0.6),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 3,
                    right: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
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
                              'Create Movie',
                              style: AppTypography.getResponsiveHeroTitle(context).copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.bold,
                                fontSize: isMobile ? (ResponsiveUtils.isSmallMobile(context) ? 24 : 28) : (isTablet ? 36 : 42),
                                height: 1.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.small),
                      Text(
                        'Upload and share movies with the community. Choose how you want to start.',
                        style: AppTypography.getResponsiveBody(context).copyWith(
                          color: AppColors.primaryDark.withOpacity(0.7),
                          fontSize: isMobile ? 14 : 16,
                        ),
                      ),
                      SizedBox(height: AppSpacing.extraLarge * 1.5),
                      // Options Grid - centered
                      Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: 700),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: isMobile ? 1 : 2,
                              crossAxisSpacing: AppSpacing.large,
                              mainAxisSpacing: AppSpacing.large,
                              childAspectRatio: 1.1,
                            ),
                            itemCount: 2,
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _buildOptionCard(
                                  title: 'Choose from Gallery',
                                  icon: Icons.photo_library,
                                  description: 'Select an existing video from your gallery',
                                  hoverColors: [AppColors.accentMain, AppColors.accentDark],
                                  onTap: () => _selectVideoFromGallery(context),
                                );
                              } else {
                                return _buildOptionCard(
                                  title: 'Record Video',
                                  icon: Icons.videocam,
                                  description: 'Use your camera to record a new movie',
                                  hoverColors: [AppColors.warmBrown, AppColors.primaryMain],
                                  onTap: () {
                                    if (PlatformHelper.isWebPlatform()) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const VideoRecordingScreenWeb(
                                            previewType: 'movie',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                );
                              }
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
  }

  Widget _buildOptionCard({
    required String title,
    required IconData icon,
    required String description,
    required List<Color> hoverColors,
    required VoidCallback onTap,
  }) {
    return _OptionCard(
      title: title,
      icon: icon,
      description: description,
      hoverColors: hoverColors,
      onTap: onTap,
    );
  }
}

class _OptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String description;
  final List<Color> hoverColors;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.icon,
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
            gradient: _isHovered
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.hoverColors,
                  )
                : null,
            color: _isHovered ? null : Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isHovered
                  ? widget.hoverColors.first
                  : AppColors.warmBrown.withOpacity(0.2),
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
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
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

