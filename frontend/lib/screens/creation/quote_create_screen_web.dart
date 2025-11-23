import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/community_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../web/create_screen_web.dart';

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

  @override
  void dispose() {
    _quoteController.dispose();
    super.dispose();
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quote submitted! It will be reviewed by an admin.'),
          backgroundColor: AppColors.successMain,
          duration: Duration(seconds: 3),
        ),
      );

      // Navigate back to create page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const CreateScreenWeb(),
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Container(
        padding: ResponsiveGridDelegate.getResponsivePadding(context),
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isDesktop ? 800 : 600,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with back button
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: StyledPageHeader(
                          title: 'Create Quote',
                          size: StyledPageHeaderSize.h2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.extraLarge),

                  // Quote Form Container
                  SectionContainer(
                    showShadow: true,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Subtitle
                          Text(
                            'Share an inspiring quote. The system will automatically create a beautiful image for it.',
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
                            style: AppTypography.body.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Share an inspiring quote...',
                              hintStyle: AppTypography.body.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 18,
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

                          // Info message
                          Container(
                            padding: EdgeInsets.all(AppSpacing.medium),
                            decoration: BoxDecoration(
                              color: AppColors.warmBrown.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
                              border: Border.all(
                                color: AppColors.warmBrown.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: AppColors.warmBrown,
                                  size: 20,
                                ),
                                const SizedBox(width: AppSpacing.small),
                                Expanded(
                                  child: Text(
                                    'Your quote will be automatically styled and converted to an image. It will be reviewed by an admin before appearing in the community.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.warmBrown,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

