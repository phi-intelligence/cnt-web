import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget for selecting thumbnails for audio/video podcasts
class ThumbnailSelector extends StatefulWidget {
  final bool isVideo;
  final String? videoUrl;
  final Function(String?) onThumbnailSelected;
  final String? initialThumbnail;

  const ThumbnailSelector({
    super.key,
    required this.isVideo,
    this.videoUrl,
    required this.onThumbnailSelected,
    this.initialThumbnail,
  });

  @override
  State<ThumbnailSelector> createState() => _ThumbnailSelectorState();
}

class _ThumbnailSelectorState extends State<ThumbnailSelector> {
  String? _selectedThumbnail;
  bool _isLoadingDefaults = false;
  bool _isGenerating = false;
  bool _isUploading = false;
  List<String> _defaultThumbnails = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _selectedThumbnail = widget.initialThumbnail;
    if (!widget.isVideo) {
      _loadDefaultThumbnails();
    }
  }

  Future<void> _loadDefaultThumbnails() async {
    setState(() {
      _isLoadingDefaults = true;
      _errorMessage = null;
    });

    try {
      final thumbnails = await ApiService().getDefaultThumbnails();
      setState(() {
        _defaultThumbnails = thumbnails;
        _isLoadingDefaults = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load default thumbnails: $e';
        _isLoadingDefaults = false;
      });
    }
  }

  Future<void> _uploadCustomThumbnail() async {
    // Clear previous errors
    setState(() {
      _errorMessage = null;
      _isUploading = true;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() {
          _isUploading = false;
        });
        return; // User cancelled file picker
      }

      String? filePath;
      List<int>? bytes;
      
      // Handle web vs mobile file paths
      if (kIsWeb) {
        // On web, path is unavailable - use bytes instead
        bytes = result.files.single.bytes;
      } else {
        // On mobile, use path if available, otherwise bytes
        if (result.files.single.path != null) {
          filePath = result.files.single.path!;
        } else if (result.files.single.bytes != null) {
          bytes = result.files.single.bytes;
        }
      }
      
      if (filePath == null && bytes == null) {
        setState(() {
          _errorMessage = 'No file data available. Please select a valid image file.';
          _isUploading = false;
        });
        return;
      }

      String thumbnailUrl;
      if (filePath != null) {
        thumbnailUrl = await ApiService().uploadThumbnail(filePath);
      } else if (bytes != null) {
        // For web, use bytes with filename
        final fileName = result.files.single.name;
        thumbnailUrl = await ApiService().uploadThumbnail('', bytes: bytes, fileName: fileName);
      } else {
        throw Exception('No file data available');
      }
      
      setState(() {
        _selectedThumbnail = thumbnailUrl;
        _isUploading = false;
        _errorMessage = null;
      });
      
      widget.onThumbnailSelected(thumbnailUrl);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Thumbnail uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        // Provide user-friendly error messages
        if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
          _errorMessage = 'Authentication required. Please log in and try again.';
        } else if (e.toString().contains('413') || e.toString().contains('too large')) {
          _errorMessage = 'File is too large. Please select an image smaller than 10MB.';
        } else if (e.toString().contains('400') || e.toString().contains('invalid')) {
          _errorMessage = 'Invalid image file. Please select a valid image (JPG, PNG, or GIF).';
        } else if (e.toString().contains('network') || e.toString().contains('connection')) {
          _errorMessage = 'Network error. Please check your connection and try again.';
        } else {
          _errorMessage = 'Failed to upload thumbnail: ${e.toString().replaceAll('Exception: ', '')}';
        }
      });
      
      // Show error SnackBar for visibility
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_errorMessage ?? 'Failed to upload thumbnail'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Check if URL is a blob URL (browser-only, can't be processed server-side)
  bool _isBlobUrl(String? url) {
    if (url == null) return false;
    return url.startsWith('blob:');
  }

  Future<void> _generateFromVideo() async {
    if (widget.videoUrl == null) return;

    // Check if it's a blob URL - can't generate thumbnail from blob URLs
    if (_isBlobUrl(widget.videoUrl)) {
      setState(() {
        _errorMessage = 'Thumbnail will be auto-generated when you publish. You can also upload a custom thumbnail.';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final thumbnailUrl = await ApiService().generateThumbnailFromVideo(widget.videoUrl!);
      setState(() {
        _selectedThumbnail = thumbnailUrl;
        _isGenerating = false;
      });
      widget.onThumbnailSelected(thumbnailUrl);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to generate thumbnail: $e';
        _isGenerating = false;
      });
    }
  }

  void _selectDefaultThumbnail(String thumbnailUrl) {
    setState(() {
      _selectedThumbnail = thumbnailUrl;
    });
    widget.onThumbnailSelected(thumbnailUrl);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected thumbnail preview
        if (_selectedThumbnail != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Thumbnail',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildThumbnailImage(_selectedThumbnail!),
                ),
              ],
            ),
          ),

        // Video-specific options
        if (widget.isVideo) ...[
          // Show info message for blob URLs
          if (_isBlobUrl(widget.videoUrl)) ...[
            Container(
              padding: EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.warmBrown.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.warmBrown.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warmBrown, size: 20),
                  const SizedBox(width: AppSpacing.small),
                  Expanded(
                    child: Text(
                      'Thumbnail will be auto-generated when you publish',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            ElevatedButton.icon(
              onPressed: _isGenerating ? null : _generateFromVideo,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.large,
                  vertical: AppSpacing.medium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 2,
              ),
              icon: _isGenerating
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.image),
              label: Text(
                _isGenerating ? 'Generating...' : 'Generate from Video',
                style: AppTypography.button.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],

        // Audio-specific: Default thumbnails grid
        if (!widget.isVideo) ...[
          const Text(
            'Select Default Thumbnail',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_isLoadingDefaults)
            const Center(child: CircularProgressIndicator())
          else if (_defaultThumbnails.isEmpty)
            const Text('No default thumbnails available')
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _defaultThumbnails.length,
              itemBuilder: (context, index) {
                final thumbnailUrl = _defaultThumbnails[index];
                final isSelected = _selectedThumbnail == thumbnailUrl;
                return GestureDetector(
                  onTap: () => _selectDefaultThumbnail(thumbnailUrl),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: _buildThumbnailImage(thumbnailUrl),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 16),
        ],

        // Upload custom thumbnail button
        ElevatedButton.icon(
          onPressed: _isUploading ? null : _uploadCustomThumbnail,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmBrown,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.large,
              vertical: AppSpacing.medium,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 2,
            disabledBackgroundColor: AppColors.warmBrown.withOpacity(0.6),
          ),
          icon: _isUploading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.upload),
          label: Text(
            _isUploading ? 'Uploading...' : 'Upload Custom Thumbnail',
            style: AppTypography.button.copyWith(
              color: Colors.white,
            ),
          ),
        ),

        // Error message
        if (_errorMessage != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildThumbnailImage(String url) {
    // Handle different URL formats
    String imageUrl = url;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // Relative path - construct full URL
      final cleanPath = url.startsWith('/') ? url.substring(1) : url;
      imageUrl = '${AppConfig.mediaBaseUrl}/$cleanPath';
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }
}

