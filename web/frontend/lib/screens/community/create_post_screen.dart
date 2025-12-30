import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' if (dart.library.html) '../../utils/file_stub.dart' as io;
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../models/content_draft.dart';
import '../../utils/unsaved_changes_guard.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _captionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  dynamic _selectedImage; // For mobile (path-based File) or web (not used)
  Uint8List? _selectedImageBytes; // For web (bytes-based)
  String? _selectedImageName; // For web filename
  String? _uploadedImageUrl;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  String _postType = 'image'; // 'image' or 'text'

  // Draft state
  int? _draftId;
  bool _isSavingDraft = false;
  final ApiService _draftApiService = ApiService();

  /// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    return _captionController.text.trim().isNotEmpty ||
        _selectedImage != null ||
        _selectedImageBytes != null ||
        _uploadedImageUrl != null;
  }

  /// Save current state as a draft
  Future<bool> _saveDraft() async {
    if (_isSavingDraft) return false;

    setState(() {
      _isSavingDraft = true;
    });

    try {
      final draftData = {
        'draft_type': DraftType.communityPost.value,
        'content': _captionController.text.trim(),
        'original_media_url': _uploadedImageUrl,
        'category': _postType,
        'status': DraftStatus.editing.value,
      };

      Map<String, dynamic> result;

      if (_draftId != null) {
        result = await _draftApiService.updateDraft(_draftId!, draftData);
      } else {
        result = await _draftApiService.createDraft(draftData);
        _draftId = result['id'] as int?;
      }

      if (!mounted) return false;

      UnsavedChangesGuard.showDraftSavedToast(context);
      return true;
    } catch (e) {
      print('Error saving draft: $e');
      if (mounted) {
        UnsavedChangesGuard.showDraftErrorToast(context,
            message: 'Failed to save draft: $e');
      }
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isSavingDraft = false;
        });
      }
    }
  }

  /// Handle back button with unsaved changes confirmation
  Future<bool> _handleBackPressed() async {
    if (!_hasUnsavedChanges()) {
      return true;
    }

    final result = await UnsavedChangesGuard.showUnsavedChangesDialog(context);

    if (result == null) {
      return false;
    } else if (result) {
      final saved = await _saveDraft();
      return saved;
    } else {
      return true;
    }
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        if (kIsWeb) {
          // Web: Read bytes from XFile
          final bytes = await image.readAsBytes();
          setState(() {
            _selectedImage = null;
            _selectedImageBytes = bytes;
            _selectedImageName = image.name;
            _uploadedImageUrl = null;
          });
        } else {
          // Mobile: Use file path
          setState(() {
            _selectedImage = kIsWeb ? null : io.File(image.path);
            _selectedImageBytes = null;
            _selectedImageName = null;
            _uploadedImageUrl = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
      _selectedImageName = null;
      _uploadedImageUrl = null;
    });
  }

  Future<String?> _uploadImage() async {
    if (_selectedImage == null && _selectedImageBytes == null) return null;

    setState(() => _isUploadingImage = true);
    try {
      final apiService = ApiService();
      List<int> bytes;
      String fileName;

      if (_selectedImageBytes != null && _selectedImageName != null) {
        // Web: Use bytes directly
        bytes = _selectedImageBytes!;
        fileName = _selectedImageName!;
      } else if (_selectedImage != null && !kIsWeb) {
        // Mobile: Read bytes from file
        final file = _selectedImage as io.File;
        bytes = await file.readAsBytes();
        fileName = file.path.split('/').last;
      } else {
        return null;
      }

      // Upload image using the upload/image endpoint
      final response = await apiService.uploadImage(
        fileName: fileName,
        bytes: bytes,
      );

      setState(() => _isUploadingImage = false);
      return response['file_path'] as String?;
    } catch (e) {
      setState(() => _isUploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _submit() async {
    // Validate based on post type
    if (_postType == 'image') {
      // For image posts, must have either image or caption
      if (_selectedImage == null &&
          _selectedImageBytes == null &&
          _captionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please add a photo or write a caption')),
        );
        return;
      }
    } else {
      // For text posts, must have content
      if (_captionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please write something to post')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      // Upload image only for image posts
      if (_postType == 'image') {
        imageUrl = _uploadedImageUrl;
        if ((_selectedImage != null || _selectedImageBytes != null) &&
            imageUrl == null) {
          imageUrl = await _uploadImage();
          if (imageUrl == null) {
            setState(() => _isSubmitting = false);
            return; // Error already shown in _uploadImage
          }
        }
      }

      // Create post
      await context.read<CommunityProvider>().createPost(
            title: _captionController.text.trim().isEmpty
                ? (_postType == 'image' ? 'Photo' : 'Quote')
                : _captionController.text.trim().split('\n').first,
            content: _captionController.text.trim(),
            category: 'General', // Default category
            imageUrl: imageUrl,
            postType: _postType,
          );

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = authProvider.isAdmin;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAdmin
              ? 'Post published successfully!'
              : 'Post submitted! It will be reviewed by an admin.'),
          duration: const Duration(seconds: 3),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to publish post: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Post',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: (_isSubmitting || _isUploadingImage) ? null : _submit,
            child: (_isSubmitting || _isUploadingImage)
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Share',
                    style: AppTypography.body.copyWith(
                      color: AppColors.primaryMain,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Post type selector
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.medium, vertical: AppSpacing.small),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.borderSecondary,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _postType = 'image'),
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
                      decoration: BoxDecoration(
                        color: _postType == 'image'
                            ? AppColors.primaryMain
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: _postType == 'image'
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Text(
                            'Image Post',
                            style: AppTypography.body.copyWith(
                              color: _postType == 'image'
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: _postType == 'image'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.small),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _postType = 'text';
                        _selectedImage = null;
                        _selectedImageBytes = null;
                        _selectedImageName = null;
                        _uploadedImageUrl = null;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.small),
                      decoration: BoxDecoration(
                        color: _postType == 'text'
                            ? AppColors.primaryMain
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.text_fields,
                            color: _postType == 'text'
                                ? Colors.white
                                : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.small),
                          Text(
                            'Text Post (Quote)',
                            style: AppTypography.body.copyWith(
                              color: _postType == 'text'
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: _postType == 'text'
                                  ? FontWeight.w600
                                  : FontWeight.normal,
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

          // Content area - different for image vs text posts
          if (_postType == 'image') ...[
            // Image preview section
            Expanded(
              child: GestureDetector(
                onTap: (_selectedImage == null && _selectedImageBytes == null)
                    ? _pickImage
                    : null,
                child: Container(
                  width: double.infinity,
                  color: AppColors.backgroundTertiary,
                  child: (_selectedImage != null || _selectedImageBytes != null)
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            // Display image from File (mobile) or bytes (web)
                            _selectedImage != null
                                ? Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.contain,
                                  )
                                : Image.memory(
                                    Uint8List.fromList(_selectedImageBytes!),
                                    fit: BoxFit.contain,
                                  ),
                            // Remove button
                            Positioned(
                              top: AppSpacing.small,
                              right: AppSpacing.small,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.close,
                                      color: Colors.white),
                                  onPressed: _removeImage,
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: AppSpacing.medium),
                            Text(
                              'Tap to add a photo',
                              style: AppTypography.body.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            // Caption input section (Instagram-style)
            Container(
              padding: EdgeInsets.all(AppSpacing.medium),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: AppColors.borderSecondary,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile picture placeholder
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryMain,
                    child: Text(
                      'U',
                      style: AppTypography.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  // Caption input - pill-shaped white container
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.warmBrown.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _captionController,
                        maxLines: null,
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          hintText: 'Write a caption...',
                          hintStyle: AppTypography.body.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Add photo button (if no image selected)
                  if (_selectedImage == null)
                    IconButton(
                      icon: const Icon(Icons.add_photo_alternate),
                      color: AppColors.primaryMain,
                      onPressed: _pickImage,
                    ),
                ],
              ),
            ),
          ] else ...[
            // Text post input (Facebook-style)
            Expanded(
              child: Container(
                padding: EdgeInsets.all(AppSpacing.large),
                color: AppColors.primaryDark,
                child: TextField(
                  controller: _captionController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: "What's on your mind?",
                    hintStyle: AppTypography.body.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: AppTypography.body.copyWith(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
