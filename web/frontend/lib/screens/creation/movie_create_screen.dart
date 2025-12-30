import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import 'package:file_picker/file_picker.dart';
// Conditional import for web platform
import 'dart:html' if (dart.library.io) '../../utils/html_stub.dart' as html;
import '../../services/logger_service.dart';
import '../../services/api_service.dart';
import '../../models/api_models.dart';

/// Movie Create Screen
/// Shows options to upload movies directly
class MovieCreateScreen extends StatelessWidget {
  const MovieCreateScreen({super.key});

  /// Get category ID for "Animated Bible Stories" category
  Future<int?> _getAnimatedBibleStoriesCategoryId() async {
    try {
      final categories = await ApiService().getCategories();
      final kidsCategory = categories.firstWhere(
        (c) => c.name == 'Animated Bible Stories' && c.type == 'movie',
        orElse: () => Category(id: -1, name: '', type: ''),
      );
      return kidsCategory.id != -1 ? kidsCategory.id : null;
    } catch (e) {
      LoggerService.e('Error fetching category: $e');
      return null;
    }
  }

  /// Extract title from filename (remove extension)
  String _extractTitleFromFilename(String filename) {
    try {
      final nameWithoutExt = filename.split('.').first;
      if (nameWithoutExt.isEmpty) {
        return 'Untitled Movie';
      }
      // Replace underscores and hyphens with spaces, capitalize first letter
      final cleaned = nameWithoutExt
          .replaceAll('_', ' ')
          .replaceAll('-', ' ')
          .trim();
      if (cleaned.isEmpty) {
        return 'Untitled Movie';
      }
      return cleaned[0].toUpperCase() + cleaned.substring(1);
    } catch (e) {
      LoggerService.w('Error extracting title from filename: $e');
      return 'Untitled Movie';
    }
  }

  /// Get MIME type for video file based on extension
  String _getVideoMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
        return 'video/mp4';
      case 'webm':
        return 'video/webm';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'video/mp4';
    }
  }

  /// Select and upload movie file directly
  Future<void> _selectAndUploadMovie(BuildContext context, String movieType) async {
    try {
      // Open file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
        withData: kIsWeb, // Load bytes for web
      );

      if (result == null || result.files.isEmpty || !context.mounted) {
        return;
      }

      final file = result.files.single;
      String filePath;
      String fileName = file.name;

      // Handle web vs mobile file paths
      if (kIsWeb && file.bytes != null) {
        // Create blob URL for web
        final mimeType = _getVideoMimeType(fileName);
        final blob = html.Blob([file.bytes!], mimeType);
        filePath = html.Url.createObjectUrlFromBlob(blob);
        LoggerService.d('Created blob URL for video: $filePath');
      } else {
        filePath = file.path ?? '';
        if (filePath.isEmpty) {
          throw Exception('No file path available');
        }
      }

      // Show upload progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppColors.backgroundSecondary,
          title: Text(
            'Uploading Movie',
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
              ),
              const SizedBox(height: AppSpacing.medium),
              Text(
                'Please wait while your movie is being uploaded...',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      try {
        // Upload file
        final uploadResponse = await ApiService().uploadMovie(
          filePath,
          movieType: movieType,
          generateThumbnail: true,
          onProgress: (sent, total) {
            // Progress tracking - dialog shows loading indicator
            // Real-time progress updates would require StatefulWidget conversion
            LoggerService.d('Upload progress: ${total > 0 ? (sent / total * 100).toStringAsFixed(1) : 0}%');
          },
        );

        // Close upload dialog
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }

        // Get category ID if kids movie
        int? categoryId;
        if (movieType == 'kids_movie') {
          categoryId = await _getAnimatedBibleStoriesCategoryId();
        }

        // Extract title from filename
        final title = _extractTitleFromFilename(fileName);

        // Create movie record
        await ApiService().createMovie(
          title: title,
          videoUrl: uploadResponse['url'] as String,
          coverImage: uploadResponse['thumbnail_url'] as String?,
          duration: uploadResponse['duration'] as int?,
          categoryId: categoryId,
          status: 'pending', // Will be reviewed by admin
        );

        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Movie uploaded successfully! It will be reviewed by an admin before being published.',
              ),
              backgroundColor: AppColors.successMain,
              duration: const Duration(seconds: 4),
            ),
          );
          // Navigate back
          Navigator.pop(context);
        }
      } catch (e) {
        // Close upload dialog if still open
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        // Show error message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error uploading movie: $e'),
              backgroundColor: AppColors.errorMain,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        LoggerService.e('Error uploading movie: $e');
      } finally {
        // Clean up blob URL on web
        if (kIsWeb && filePath.startsWith('blob:')) {
          try {
            html.Url.revokeObjectUrl(filePath);
          } catch (e) {
            LoggerService.w('Error revoking blob URL: $e');
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: AppColors.errorMain,
          ),
        );
      }
      LoggerService.e('Error in _selectAndUploadMovie: $e');
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
                              'Upload Movies',
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
                        'Upload and share movies with the community. Choose the type of movie you want to upload.',
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
                                  title: 'Movies',
                                  icon: Icons.movie,
                                  description: 'Upload regular movies and films',
                                  hoverColors: [AppColors.accentMain, AppColors.accentDark],
                                  onTap: () => _selectAndUploadMovie(context, 'movie'),
                                );
                              } else {
                                return _buildOptionCard(
                                  title: 'Kids Movies',
                                  icon: Icons.child_care,
                                  description: 'Upload animated Bible stories for kids',
                                  hoverColors: [AppColors.warmBrown, AppColors.primaryMain],
                                  onTap: () => _selectAndUploadMovie(context, 'kids_movie'),
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

