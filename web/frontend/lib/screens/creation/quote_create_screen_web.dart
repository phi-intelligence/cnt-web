import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/community_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../utils/unsaved_changes_guard.dart';
import '../../services/api_service.dart';

/// Web Quote Creation Screen - Simple text input for creating quotes
/// Backend automatically generates image with predefined templates
class QuoteCreateScreenWeb extends StatefulWidget {
  const QuoteCreateScreenWeb({super.key});

  @override
  State<QuoteCreateScreenWeb> createState() => _QuoteCreateScreenWebState();
}

class _QuoteCreateScreenWebState extends State<QuoteCreateScreenWeb> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  bool _isSubmitting = false;
  bool _hasUnsavedChanges = false;
  bool _isSavingDraft = false;

  @override
  void initState() {
    super.initState();
    _quoteController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _quoteController.removeListener(_onContentChanged);
    _quoteController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final hasContent = _quoteController.text.trim().isNotEmpty;
    if (hasContent != _hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = hasContent);
    }
  }

  Future<void> _saveDraft() async {
    if (_quoteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quote to save as draft'),
          backgroundColor: AppColors.warningMain,
        ),
      );
      return;
    }

    setState(() => _isSavingDraft = true);

    try {
      final quoteText = _quoteController.text.trim();
      await ApiService().createContentDraft(
        draftType: 'quote_post',
        title: quoteText.length > 50 ? '${quoteText.substring(0, 50)}...' : quoteText,
        content: quoteText,
        category: 'General',
        editingState: {
          'quote_text': quoteText,
        },
      );

      if (!mounted) return;

      setState(() => _hasUnsavedChanges = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote draft saved successfully'),
          backgroundColor: AppColors.successMain,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save draft: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingDraft = false);
      }
    }
  }

  Future<bool> _handleWillPop() async {
    if (!_hasUnsavedChanges) return true;

    final result = await UnsavedChangesGuard.showUnsavedChangesDialog(context);
    if (result == null) return false; // Cancel
    if (result == true) {
      await _saveDraft();
    }
    return true; // Discard or after saving
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final quoteText = _quoteController.text.trim();
    if (quoteText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a quote'),
          backgroundColor: AppColors.errorMain,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final communityProvider = Provider.of<CommunityProvider>(context, listen: false);
      
      await communityProvider.createPost(
        title: quoteText.split('\n').first,  // Use first line as title
        content: quoteText,
        category: 'General',
        postType: 'text',  // Backend will auto-generate image
      );

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAdmin = authProvider.isAdmin;

      // Show success dialog
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.successMain.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 50,
                  color: AppColors.successMain,
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              // Title
              Text(
                'Quote Posted!',
                style: AppTypography.heading3.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.medium),
              // Message
              Text(
                isAdmin 
                    ? 'Your quote has been published to the community page.'
                    : 'Your quote has been submitted for review. Once approved by an admin, it will appear on the community page.',
                style: AppTypography.body.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Go to community page
                        context.go('/community');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warmBrown,
                        side: BorderSide(color: AppColors.warmBrown),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('View Community'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(dialogContext).pop();
                        // Go back to create page using proper routing
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.warmBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create quote: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildQuotePreview() {
    final quoteText = _quoteController.text.trim();
    if (quoteText.isEmpty) {
      return Container(
        padding: EdgeInsets.all(AppSpacing.extraLarge * 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.warmBrown.withOpacity(0.05),
              AppColors.accentMain.withOpacity(0.02),
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
          border: Border.all(
            color: AppColors.warmBrown.withOpacity(0.2),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.format_quote,
              size: 64,
              color: AppColors.warmBrown.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.medium),
            Text(
              'Preview will appear here',
              style: AppTypography.body.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.extraLarge * 2),
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
        borderRadius: BorderRadius.circular(AppSpacing.radiusLarge),
        border: Border.all(
          color: AppColors.warmBrown,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Decorative quote icon
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(
                Icons.format_quote,
                size: 48,
                color: AppColors.warmBrown,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.large),
          // Quote text preview
          Text(
            quoteText,
            style: AppTypography.heading3.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.large),
          // Decorative quote icon (closing)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Transform.rotate(
                angle: 3.14159, // 180 degrees
                child: Icon(
                  Icons.format_quote,
                  size: 48,
                  color: AppColors.warmBrown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final maxContentWidth = ResponsiveGridDelegate.getMaxContentWidth(context);

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _handleWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundPrimary,
        body: Stack(
          children: [
            // Background pattern/gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warmBrown.withOpacity(0.03),
                      AppColors.accentMain.withOpacity(0.02),
                      Colors.white,
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              child: Center(
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: maxContentWidth,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header with decorative quote icon
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                              onPressed: () async {
                                if (_hasUnsavedChanges) {
                                  final shouldPop = await _handleWillPop();
                                  if (shouldPop && context.mounted) {
                                    Navigator.of(context).pop();
                                  }
                                } else {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            Expanded(
                              child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(AppSpacing.small),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.warmBrown,
                                        AppColors.accentMain,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.format_quote,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.medium),
                                Expanded(
                                  child: StyledPageHeader(
                                    title: 'Create Quote',
                                    size: StyledPageHeaderSize.h2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                            // Save Draft button
                            if (_hasUnsavedChanges)
                              TextButton.icon(
                                onPressed: _isSavingDraft ? null : _saveDraft,
                                icon: _isSavingDraft
                                    ? SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.warmBrown,
                                        ),
                                      )
                                    : Icon(Icons.save_outlined, color: AppColors.warmBrown),
                                label: Text(
                                  _isSavingDraft ? 'Saving...' : 'Save Draft',
                                  style: TextStyle(color: AppColors.warmBrown),
                                ),
                              ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Two-column layout: Input and Preview (responsive)
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 900;
                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left: Quote Form
                                Expanded(
                                  flex: 1,
                                  child: SectionContainer(
                              showShadow: true,
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    // Subtitle
                                    Text(
                                      'Share an inspiring quote',
                                      style: AppTypography.heading4.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.small),
                                    Text(
                                      'The system will automatically create a beautiful image',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: AppSpacing.extraLarge),

                                    // Quote input
                                    TextFormField(
                                      controller: _quoteController,
                                      maxLines: null,
                                      minLines: 8,
                                      expands: false,
                                      textAlignVertical: TextAlignVertical.top,
                                      onChanged: (_) => setState(() {}), // Update preview
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.textPrimary,
                                        fontSize: 16,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Share an inspiring quote...',
                                        hintStyle: AppTypography.body.copyWith(
                                          color: AppColors.textTertiary,
                                          fontSize: 16,
                                        ),
                                        prefixIcon: Icon(
                                          Icons.format_quote,
                                          color: AppColors.warmBrown.withOpacity(0.5),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                          borderSide: BorderSide(color: AppColors.borderPrimary),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                          borderSide: BorderSide(color: AppColors.borderPrimary),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                          borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: AppColors.backgroundSecondary,
                                        contentPadding: EdgeInsets.all(AppSpacing.large),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Please enter a quote';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: AppSpacing.extraLarge),

                                    // Info message with brown accent card
                                    Container(
                                      padding: EdgeInsets.all(AppSpacing.medium),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.warmBrown.withOpacity(0.15),
                                            AppColors.accentMain.withOpacity(0.08),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                        border: Border.all(
                                          color: AppColors.warmBrown.withOpacity(0.4),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(AppSpacing.tiny),
                                            decoration: BoxDecoration(
                                              color: AppColors.warmBrown,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.info_outline,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.small),
                                          Expanded(
                                            child: Text(
                                              'Your quote will be automatically styled and converted to an image. It will be reviewed by an admin before appearing in the community.',
                                              style: AppTypography.bodySmall.copyWith(
                                                color: AppColors.warmBrown,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.extraLarge),

                                    // Submit button
                                    StyledPillButton(
                                      label: 'Create Quote',
                                      icon: Icons.format_quote,
                                      onPressed: _isSubmitting ? null : _submit,
                                      isLoading: _isSubmitting,
                                      width: double.infinity,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            ),
                            const SizedBox(width: AppSpacing.extraLarge),
                            // Right: Interactive Preview Card
                            Expanded(
                              flex: 1,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Preview',
                                    style: AppTypography.heading4.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  _buildQuotePreview(),
                                ],
                              ),
                            ),
                          ],
                        );
                          } else {
                            // Stacked layout for smaller screens
                            return Column(
                              children: [
                                SectionContainer(
                                  showShadow: true,
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Text(
                                          'Share an inspiring quote',
                                          style: AppTypography.heading4.copyWith(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: AppSpacing.small),
                                        Text(
                                          'The system will automatically create a beautiful image',
                                          style: AppTypography.body.copyWith(
                                            color: AppColors.textSecondary,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: AppSpacing.extraLarge),
                                        TextFormField(
                                          controller: _quoteController,
                                          maxLines: null,
                                          minLines: 8,
                                          expands: false,
                                          textAlignVertical: TextAlignVertical.top,
                                          onChanged: (_) => setState(() {}),
                                          style: AppTypography.body.copyWith(
                                            color: AppColors.textPrimary,
                                            fontSize: 16,
                                          ),
                                          decoration: InputDecoration(
                                            hintText: 'Share an inspiring quote...',
                                            hintStyle: AppTypography.body.copyWith(
                                              color: AppColors.textTertiary,
                                              fontSize: 16,
                                            ),
                                            prefixIcon: Icon(
                                              Icons.format_quote,
                                              color: AppColors.warmBrown.withOpacity(0.5),
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                              borderSide: BorderSide(color: AppColors.borderPrimary),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                              borderSide: BorderSide(color: AppColors.borderPrimary),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                              borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                                            ),
                                            filled: true,
                                            fillColor: AppColors.backgroundSecondary,
                                            contentPadding: EdgeInsets.all(AppSpacing.large),
                                          ),
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'Please enter a quote';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: AppSpacing.extraLarge),
                                        Container(
                                          padding: EdgeInsets.all(AppSpacing.medium),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                AppColors.warmBrown.withOpacity(0.15),
                                                AppColors.accentMain.withOpacity(0.08),
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                                            border: Border.all(
                                              color: AppColors.warmBrown.withOpacity(0.4),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Container(
                                                padding: EdgeInsets.all(AppSpacing.tiny),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warmBrown,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.info_outline,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: AppSpacing.small),
                                              Expanded(
                                                child: Text(
                                                  'Your quote will be automatically styled and converted to an image. It will be reviewed by an admin before appearing in the community.',
                                                  style: AppTypography.bodySmall.copyWith(
                                                    color: AppColors.warmBrown,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.extraLarge),
                                        StyledPillButton(
                                          label: 'Create Quote',
                                          icon: Icons.format_quote,
                                          onPressed: _isSubmitting ? null : _submit,
                                          isLoading: _isSubmitting,
                                          width: double.infinity,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.extraLarge),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Preview',
                                      style: AppTypography.heading4.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.medium),
                                    _buildQuotePreview(),
                                  ],
                                ),
                      ],
                    );
                          }
                        },
                      ),
                    ],
                  ),
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

