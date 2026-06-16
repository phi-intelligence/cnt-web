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
  final int? draftId;
  final String? initialTitle;
  final String? initialContent;
  final String? initialCategory;

  const CreatePostScreen({
    super.key,
    this.draftId,
    this.initialTitle,
    this.initialContent,
    this.initialCategory,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _imageCaptionController;
  late TextEditingController _quoteController;
  final FocusNode _quoteFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  dynamic _selectedImage; // For mobile (path-based File) or web (not used)
  Uint8List? _selectedImageBytes; // For web (bytes-based)
  String? _selectedImageName; // For web filename
  String? _uploadedImageUrl;
  bool _isSubmitting = false;
  bool _isUploadingImage = false;
  late String _postType; // 'image' or 'text'

  // Draft state
  int? _draftId;
  bool _isSavingDraft = false;
  final ApiService _draftApiService = ApiService();

  @override
  void initState() {
    super.initState();
    // Initialize from draft parameters if provided
    _draftId = widget.draftId;
    final initialContent = widget.initialContent ?? '';
    // If there's initial content but no image, default to text post type
    _postType = (widget.initialCategory == 'text' ||
            (widget.initialContent != null &&
                widget.initialContent!.isNotEmpty))
        ? 'text'
        : 'image';
    // Separate controllers: sharing one controller caused Flutter Web to keep
    // the image caption's white text color when switching to quote mode.
    _imageCaptionController = TextEditingController(
      text: _postType == 'image' ? initialContent : '',
    );
    _quoteController = TextEditingController(
      text: _postType == 'text' ? initialContent : '',
    );
    if (kIsWeb) {
      _quoteFocusNode.addListener(() {
        if (mounted) setState(() {});
      });
    }
  }

  String get _activeText =>
      _postType == 'text' ? _quoteController.text : _imageCaptionController.text;

  /// Check if there are unsaved changes
  bool _hasUnsavedChanges() {
    return _activeText.trim().isNotEmpty ||
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
        'content': _activeText.trim(),
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
    _quoteFocusNode.dispose();
    _imageCaptionController.dispose();
    _quoteController.dispose();
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
          SnackBar(
            content: Text('Error picking image: $e'),
            duration: const Duration(seconds: 5),
          ),
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
          SnackBar(
            content: Text('Error uploading image: $e'),
            duration: const Duration(seconds: 5),
          ),
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
          _imageCaptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please add a photo or write a caption'),
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }
    } else {
      // For text posts, must have content
      if (_quoteController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please write something to post'),
            duration: Duration(seconds: 3),
          ),
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

      final postText = _activeText.trim();

      // Create post
      await context.read<CommunityProvider>().createPost(
            title: postText.isEmpty
                ? (_postType == 'image' ? 'Photo' : 'Quote')
                : postText.split('\n').first,
            content: postText,
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
        SnackBar(
          content: Text('Unable to publish post: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _quoteCardShell({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 260),
      padding: EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.warmBrown.withOpacity(0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: AppColors.warmBrown),
              const SizedBox(width: AppSpacing.small),
              Text(
                title,
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.medium),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildQuoteTypingCard() {
    // On web, hide canvas text while focused so only the HTML input layer renders.
    final hideCanvasTextWhileFocused = kIsWeb && _quoteFocusNode.hasFocus;

    return _quoteCardShell(
      title: 'Write your quote',
      icon: Icons.edit_outlined,
      child: TextField(
        key: const ValueKey('quote-text-input'),
        controller: _quoteController,
        focusNode: _quoteFocusNode,
        minLines: 8,
        maxLines: 14,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        keyboardAppearance: Brightness.light,
        cursorColor: Colors.black,
        style: TextStyle(
          color: hideCanvasTextWhileFocused
              ? Colors.transparent
              : const Color(0xFF000000),
          fontSize: 18,
          height: 1.5,
          decoration: TextDecoration.none,
        ),
        decoration: InputDecoration(
          hintText: "What's on your mind?",
          hintStyle: TextStyle(
            color: hideCanvasTextWhileFocused
                ? Colors.transparent
                : AppColors.textPlaceholder,
            fontSize: 18,
          ),
          filled: true,
          fillColor: AppColors.backgroundPrimary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderPrimary),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.borderPrimary),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.warmBrown, width: 2),
          ),
          contentPadding: EdgeInsets.all(AppSpacing.medium),
        ),
      ),
    );
  }

  Widget _buildQuotePreviewContent(String quoteText) {
    final trimmed = quoteText.trim();
    if (trimmed.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.format_quote,
              size: 48,
              color: AppColors.warmBrown.withOpacity(0.35),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Your quote preview will appear here',
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(AppSpacing.large),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warmBrown.withOpacity(0.1),
              AppColors.accentMain.withOpacity(0.05),
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.warmBrown.withOpacity(0.4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.format_quote,
              color: AppColors.warmBrown,
              size: 32,
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              trimmed,
              textAlign: TextAlign.center,
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontStyle: FontStyle.italic,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.medium),
            Align(
              alignment: Alignment.centerRight,
              child: Transform.rotate(
                angle: 3.14159,
                child: Icon(
                  Icons.format_quote,
                  color: AppColors.warmBrown,
                  size: 32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotePreviewCard() {
    return _quoteCardShell(
      title: 'Preview',
      icon: Icons.visibility_outlined,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: _quoteController,
        builder: (context, value, _) =>
            _buildQuotePreviewContent(value.text),
      ),
    );
  }

  Widget _buildQuotePostLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        const minCardHeight = 320.0;
        final isWide = constraints.maxWidth >= 768;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: minCardHeight,
                  child: _buildQuoteTypingCard(),
                ),
              ),
              const SizedBox(width: AppSpacing.large),
              Expanded(
                child: SizedBox(
                  height: minCardHeight,
                  child: _buildQuotePreviewCard(),
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            SizedBox(height: minCardHeight, child: _buildQuoteTypingCard()),
            const SizedBox(height: AppSpacing.large),
            SizedBox(height: minCardHeight, child: _buildQuotePreviewCard()),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _draftId != null ? 'Edit Draft' : 'New Post',
          style: const TextStyle(color: AppColors.textPrimary),
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
                      FocusManager.instance.primaryFocus?.unfocus();
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
                        key: const ValueKey('image-caption-input'),
                        controller: _imageCaptionController,
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
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: _buildQuotePostLayout(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
