import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/responsive_utils.dart';

/// Model for a file to be uploaded
class BulkUploadFile {
  final String name;
  final String path;
  final int size;
  final bool isVideo;
  String title;
  String? description;
  double uploadProgress;
  String? uploadedUrl;
  String? thumbnailUrl;
  String? error;
  bool isUploading;
  bool isCompleted;

  BulkUploadFile({
    required this.name,
    required this.path,
    required this.size,
    required this.isVideo,
    String? title,
    this.description,
    this.uploadProgress = 0.0,
    this.uploadedUrl,
    this.thumbnailUrl,
    this.error,
    this.isUploading = false,
    this.isCompleted = false,
  }) : title = title ?? _extractTitle(name);

  static String _extractTitle(String filename) {
    // Remove extension and clean up filename
    final lastDot = filename.lastIndexOf('.');
    if (lastDot > 0) {
      return filename.substring(0, lastDot).replaceAll(RegExp(r'[_-]'), ' ');
    }
    return filename;
  }

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Bulk Upload Screen - Multi-step upload for admin
class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  int _currentStep = 0;
  final List<BulkUploadFile> _files = [];
  bool _autoGenerateThumbnails = true;
  bool _isUploading = false;
  int _completedUploads = 0;
  int _failedUploads = 0;

  final List<String> _allowedExtensions = [
    'mp3', 'wav', 'ogg', 'webm', 'm4a', 'aac', 'flac', // Audio
    'mp4', 'mov', 'avi', 'mkv', // Video
  ];

  final List<String> _videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];

  bool _isVideoFile(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return _videoExtensions.contains(ext);
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _allowedExtensions,
        allowMultiple: true,
        withData: kIsWeb, // Load bytes for web
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            // Check if file already added
            if (_files.any((f) => f.name == file.name)) continue;

            String path;
            if (kIsWeb && file.bytes != null) {
              // For web, create a blob URL
              final blob = Uri.dataFromBytes(file.bytes!, mimeType: _getMimeType(file.name));
              path = blob.toString();
            } else {
              path = file.path ?? '';
            }

            _files.add(BulkUploadFile(
              name: file.name,
              path: path,
              size: file.size,
              isVideo: _isVideoFile(file.name),
            ));
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick files: $e');
    }
  }

  String _getMimeType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'ogg':
        return 'audio/ogg';
      case 'webm':
        return 'video/webm';
      case 'm4a':
        return 'audio/mp4';
      case 'aac':
        return 'audio/aac';
      case 'flac':
        return 'audio/flac';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      default:
        return 'application/octet-stream';
    }
  }

  void _removeFile(int index) {
    setState(() {
      _files.removeAt(index);
    });
  }

  void _updateTitle(int index, String title) {
    setState(() {
      _files[index].title = title;
    });
  }

  Future<void> _startUpload() async {
    if (_files.isEmpty) return;

    setState(() {
      _isUploading = true;
      _currentStep = 2;
      _completedUploads = 0;
      _failedUploads = 0;
    });

    final apiService = ApiService();

    for (int i = 0; i < _files.length; i++) {
      final file = _files[i];

      setState(() {
        file.isUploading = true;
        file.uploadProgress = 0.0;
      });

      try {
        String? mediaUrl;
        String? thumbnailUrl;

        // Upload the media file
        if (file.isVideo) {
          final response = await apiService.uploadVideo(
            file.path,
            generateThumbnail: _autoGenerateThumbnails,
          );
          mediaUrl = response['url'] as String?;
          thumbnailUrl = response['thumbnail_url'] as String?;
        } else {
          final response = await apiService.uploadAudio(file.path);
          mediaUrl = response['url'] as String?;
        }

        if (mediaUrl == null) {
          throw Exception('Upload failed - no URL returned');
        }

        setState(() {
          file.uploadProgress = 0.5;
        });

        // Create the podcast entry
        await apiService.createPodcast(
          title: file.title,
          description: file.description,
          audioUrl: file.isVideo ? null : mediaUrl,
          videoUrl: file.isVideo ? mediaUrl : null,
          coverImage: thumbnailUrl,
          useDefaultThumbnail: _autoGenerateThumbnails && !file.isVideo,
        );

        setState(() {
          file.uploadProgress = 1.0;
          file.uploadedUrl = mediaUrl;
          file.thumbnailUrl = thumbnailUrl;
          file.isUploading = false;
          file.isCompleted = true;
          _completedUploads++;
        });
      } catch (e) {
        setState(() {
          file.error = e.toString();
          file.isUploading = false;
          file.isCompleted = true;
          _failedUploads++;
        });
      }
    }

    setState(() {
      _isUploading = false;
      _currentStep = 3;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorMain,
      ),
    );
  }

  void _reset() {
    setState(() {
      _currentStep = 0;
      _files.clear();
      _autoGenerateThumbnails = true;
      _isUploading = false;
      _completedUploads = 0;
      _failedUploads = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAdmin) {
      return Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AppColors.backgroundSecondary,
        ),
        body: const Center(
          child: Text('This feature is only available for administrators.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Custom Gradient Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.extraLarge),
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
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            'Bulk Upload',
                            style: AppTypography.heading2.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for back button
                      ],
                    ),
                    const SizedBox(height: AppSpacing.large),
                    Text(
                      'Upload multiple audio and video files at once',
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppSpacing.extraLarge),

            // Main Content with Constraint
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  children: [
                    // Stepper indicator
                    _buildStepperIndicator(),
                    const SizedBox(height: AppSpacing.large),
                    // Content
                    _buildStepContent(),
                    const SizedBox(height: AppSpacing.extraLarge),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepperIndicator() {
    final steps = ['Select Files', 'Review', 'Upload', 'Complete'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final stepIndex = index ~/ 2;
            return Expanded(
              child: Container(
                height: 2,
                color: _currentStep > stepIndex
                    ? AppColors.warmBrown
                    : AppColors.borderPrimary,
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isActive = _currentStep >= stepIndex;
            final isCurrent = _currentStep == stepIndex;

            return Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? AppColors.warmBrown : Colors.white,
                    border: Border.all(
                      color: isActive ? AppColors.warmBrown : AppColors.borderPrimary,
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.warmBrown.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isActive && !isCurrent
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${stepIndex + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIndex],
                  style: AppTypography.caption.copyWith(
                    color: isActive ? AppColors.warmBrown : AppColors.textSecondary,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildFileSelectionStep();
      case 1:
        return _buildReviewStep();
      case 2:
        return _buildUploadProgressStep();
      case 3:
        return _buildCompletionStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildFileSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          // Re-trigger build
          // Drag and drop zone
          GestureDetector(
            onTap: _pickFiles,
            child: Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.warmBrown.withOpacity(0.3),
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.warmBrown.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.warmBrown.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_upload_outlined,
                          size: 40,
                          color: AppColors.warmBrown,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      Text(
                        'Click to select files',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        'Supports MP3, WAV, MP4, MOV, WebM and more',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),
                      if (_files.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.medium,
                            vertical: AppSpacing.small,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${_files.length} file(s) selected',
                            style: AppTypography.body.copyWith(
                              color: AppColors.warmBrown,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.large),
          // Selected files preview
          if (_files.isNotEmpty) ...[
            Container(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: AppSpacing.small),
                    padding: const EdgeInsets.all(AppSpacing.small),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.borderPrimary),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          file.isVideo ? Icons.videocam : Icons.audiotrack,
                          color: file.isVideo ? AppColors.accentMain : AppColors.warmBrown,
                          size: 24,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          file.name,
                          style: AppTypography.caption,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: AppSpacing.large),
          ],
          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _files.isNotEmpty
                  ? () => setState(() => _currentStep = 1)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmBrown,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                disabledBackgroundColor: AppColors.warmBrown.withOpacity(0.3),
              ),
              child: Text(
                'Continue to Review',
                style: AppTypography.button.copyWith(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final isDesktop = ResponsiveUtils.isDesktop(context);

    return Column(
      children: [
        // Auto-generate thumbnails checkbox
        Container(
          margin: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Checkbox(
                value: _autoGenerateThumbnails,
                onChanged: (value) {
                  setState(() {
                    _autoGenerateThumbnails = value ?? true;
                  });
                },
                activeColor: AppColors.warmBrown,
              ),
              const SizedBox(width: AppSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-generate Thumbnails',
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      'Videos: Extract frame at 45s. Audio: Use preset thumbnails.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        // File list
        SizedBox(
          height: 400, // Fixed height for list within column
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
            itemCount: _files.length,
            itemBuilder: (context, index) {
              final file = _files[index];
              return _buildFileReviewCard(file, index, isDesktop);
            },
          ),
        ),
        // Bottom buttons
        Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmBrown,
                    side: BorderSide(color: AppColors.warmBrown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _files.isNotEmpty ? _startUpload : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Upload ${_files.length} File(s)',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFileReviewCard(BulkUploadFile file, int index, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File type icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: file.isVideo
                  ? AppColors.accentMain.withOpacity(0.1)
                  : AppColors.warmBrown.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              file.isVideo ? Icons.videocam : Icons.audiotrack,
              color: file.isVideo ? AppColors.accentMain : AppColors.warmBrown,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title input
                TextFormField(
                  initialValue: file.title,
                  onChanged: (value) => _updateTitle(index, value),
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: TextStyle(color: AppColors.textSecondary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.borderPrimary),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: AppColors.warmBrown),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  style: AppTypography.body.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                // File info row
                Row(
                  children: [
                    Icon(
                      file.isVideo ? Icons.movie : Icons.music_note,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      file.isVideo ? 'Video' : 'Audio',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.storage,
                      size: 14,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      file.formattedSize,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Remove button
          IconButton(
            onPressed: () => _removeFile(index),
            icon: Icon(
              Icons.close,
              color: AppColors.errorMain,
            ),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildUploadProgressStep() {
    final totalProgress = _files.isEmpty
        ? 0.0
        : _files.map((f) => f.uploadProgress).reduce((a, b) => a + b) / _files.length;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          // Overall progress
          Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Uploading...',
                  style: AppTypography.heading3.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                LinearProgressIndicator(
                  value: totalProgress,
                  backgroundColor: AppColors.warmBrown.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  '${(totalProgress * 100).toInt()}% Complete',
                  style: AppTypography.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          // Individual file progress
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return _buildFileProgressCard(file);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileProgressCard(BulkUploadFile file) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (file.error != null) {
      statusColor = AppColors.errorMain;
      statusIcon = Icons.error_outline;
      statusText = 'Failed';
    } else if (file.isCompleted) {
      statusColor = AppColors.successMain;
      statusIcon = Icons.check_circle_outline;
      statusText = 'Completed';
    } else if (file.isUploading) {
      statusColor = AppColors.warmBrown;
      statusIcon = Icons.upload;
      statusText = 'Uploading...';
    } else {
      statusColor = AppColors.textSecondary;
      statusIcon = Icons.hourglass_empty;
      statusText = 'Pending';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: file.isUploading ? AppColors.warmBrown : AppColors.borderPrimary,
          width: file.isUploading ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            file.isVideo ? Icons.videocam : Icons.audiotrack,
            color: file.isVideo ? AppColors.accentMain : AppColors.warmBrown,
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                if (file.isUploading)
                  LinearProgressIndicator(
                    value: file.uploadProgress,
                    backgroundColor: AppColors.warmBrown.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.warmBrown),
                    minHeight: 4,
                    borderRadius: BorderRadius.circular(2),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: AppTypography.caption.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionStep() {
    final allSuccessful = _failedUploads == 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(AppSpacing.extraLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: allSuccessful
                        ? AppColors.successMain.withOpacity(0.1)
                        : AppColors.warningMain.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    allSuccessful ? Icons.check_circle : Icons.info_outline,
                    size: 40,
                    color: allSuccessful ? AppColors.successMain : AppColors.warningMain,
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Text(
                  allSuccessful ? 'Upload Complete!' : 'Upload Finished',
                  style: AppTypography.heading2.copyWith(
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatChip(
                      icon: Icons.check_circle,
                      label: '$_completedUploads Successful',
                      color: AppColors.successMain,
                    ),
                    if (_failedUploads > 0) ...[
                      const SizedBox(width: AppSpacing.medium),
                      _buildStatChip(
                        icon: Icons.error,
                        label: '$_failedUploads Failed',
                        color: AppColors.errorMain,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.large),
          // File results list
          SizedBox(
            height: 400,
            child: ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return _buildFileResultCard(file);
              },
            ),
          ),
          // Action buttons
          const SizedBox(height: AppSpacing.large),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.warmBrown,
                    side: BorderSide(color: AppColors.warmBrown),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Upload More'),
                ),
              ),
              const SizedBox(width: AppSpacing.medium),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmBrown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.medium,
        vertical: AppSpacing.small,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileResultCard(BulkUploadFile file) {
    final isSuccess = file.error == null && file.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isSuccess ? AppColors.successMain : AppColors.errorMain,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.successMain.withOpacity(0.1)
                  : AppColors.errorMain.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.close,
              color: isSuccess ? AppColors.successMain : AppColors.errorMain,
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.title,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                if (file.error != null)
                  Text(
                    file.error!,
                    style: AppTypography.caption.copyWith(
                      color: AppColors.errorMain,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else
                  Text(
                    file.isVideo ? 'Video Podcast' : 'Audio Podcast',
                    style: AppTypography.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

