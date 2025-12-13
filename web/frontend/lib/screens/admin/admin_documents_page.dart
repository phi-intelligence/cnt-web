import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/documents_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/media_utils.dart';
import '../../widgets/web/section_container.dart';
import '../../widgets/web/styled_pill_button.dart';
import '../../utils/responsive_grid_delegate.dart';
import '../../models/document_asset.dart';

class AdminDocumentsPage extends StatefulWidget {
  const AdminDocumentsPage({super.key});

  @override
  State<AdminDocumentsPage> createState() => _AdminDocumentsPageState();
}

class _AdminDocumentsPageState extends State<AdminDocumentsPage> {
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DocumentsProvider>().fetchDocuments();
    });
  }

  Future<void> _handleUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final selected = result.files.single;
      final fileName = selected.name;
      final Uint8List? bytes = selected.bytes;
      
      // On web, path is not available - only use bytes
      // On mobile, we can use path if bytes is null
      String? path;
      if (!kIsWeb) {
        path = selected.path;
      }

      if (bytes == null && path == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read the selected file')),
        );
        return;
      }

      setState(() => _isUploading = true);

      await context.read<DocumentsProvider>().addDocument(
            title: fileName.replaceAll('.pdf', ''),
            description: 'Uploaded ${DateTime.now().toLocal()}',
            fileName: fileName,
            bytes: bytes,
            filePath: path,
            category: 'Bible',
            isFeatured: true,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName uploaded successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload document: $e'),
          backgroundColor: AppColors.errorMain,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: RefreshIndicator(
        onRefresh: () => context.read<DocumentsProvider>().fetchDocuments(),
        color: AppColors.primaryMain,
        child: Consumer<DocumentsProvider>(
          builder: (context, provider, child) {
            return Container(
              padding: ResponsiveGridDelegate.getResponsivePadding(context),
              width: double.infinity,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      // Header with Back Button and Upload Button
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.warmBrown,
                              AppColors.warmBrown.withOpacity(0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.warmBrown.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Back button row
                            Row(
                              children: [
                                StyledPillButton(
                                  label: 'Back',
                                  icon: Icons.arrow_back,
                                  variant: StyledPillButtonVariant.outlinedLight,
                                  onPressed: () => Navigator.of(context).pop(),
                                ),
                                const Spacer(),
                                StyledPillButton(
                                  label: _isUploading ? 'Uploading...' : 'Upload PDF',
                                  icon: Icons.cloud_upload,
                                  variant: StyledPillButtonVariant.outlinedLight,
                                  onPressed: _isUploading ? null : _handleUpload,
                                  isLoading: _isUploading,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.medium),
                            // Title row
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.small),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.medium),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Bible Documents',
                                        style: AppTypography.heading3.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Manage and organize Bible PDFs and study guides',
                                        style: AppTypography.bodySmall.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.extraLarge),

                      // Upload Section (if needed for drag-drop in future)
                      // For now, upload button is in header

                      // Documents List
                      if (provider.isLoading && provider.documents.isEmpty)
                        SectionContainer(
                          showShadow: true,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: CircularProgressIndicator(
                                color: AppColors.primaryMain,
                              ),
                            ),
                          ),
                        )
                      else if (provider.documents.isEmpty)
                        SectionContainer(
                          showShadow: true,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 80),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.extraLarge * 1.5),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          AppColors.warmBrown.withOpacity(0.15),
                                          AppColors.accentMain.withOpacity(0.08),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.warmBrown.withOpacity(0.4),
                                        width: 3,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.warmBrown.withOpacity(0.2),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.menu_book_outlined,
                                      size: 96,
                                      color: AppColors.warmBrown,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.large),
                                  Text(
                                    'No documents yet',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.heading2.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.extraLarge,
                                      vertical: AppSpacing.medium,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warmBrown.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: AppColors.warmBrown.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Upload Bible PDFs or study guides to appear in the Bible Reader.',
                                      textAlign: TextAlign.center,
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.warmBrown,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.extraLarge),
                                  StyledPillButton(
                                    label: 'Upload PDF',
                                    icon: Icons.cloud_upload,
                                    onPressed: _isUploading ? null : _handleUpload,
                                    isLoading: _isUploading,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ...provider.documents.asMap().entries.map((entry) {
                          final index = entry.key;
                          final document = entry.value;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == provider.documents.length - 1
                                  ? 0
                                  : AppSpacing.large,
                            ),
                            child: _buildDocumentCard(context, document, provider),
                          );
                        }),
                    ],
                  ),
                ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    DocumentAsset document,
    DocumentsProvider provider,
  ) {
    final downloadUrl = resolveMediaUrl(document.filePath);
    return _DocumentCardWidget(
      document: document,
      downloadUrl: downloadUrl,
      onOpen: downloadUrl == null
          ? null
          : () => launchUrl(Uri.parse(downloadUrl)),
      onDelete: () async {
        await provider.deleteDocument(document.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${document.title} deleted')),
        );
      },
    );
  }
}

class _DocumentCardWidget extends StatefulWidget {
  final DocumentAsset document;
  final String? downloadUrl;
  final VoidCallback? onOpen;
  final VoidCallback onDelete;

  const _DocumentCardWidget({
    required this.document,
    required this.downloadUrl,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  State<_DocumentCardWidget> createState() => _DocumentCardWidgetState();
}

class _DocumentCardWidgetState extends State<_DocumentCardWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _isHovered
                ? [
                    AppColors.warmBrown.withOpacity(0.08),
                    AppColors.accentMain.withOpacity(0.04),
                  ]
                : [
                    Colors.white,
                    AppColors.warmBrown.withOpacity(0.02),
                  ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _isHovered
                ? AppColors.warmBrown
                : AppColors.warmBrown.withOpacity(0.3),
            width: _isHovered ? 2.5 : 1.5,
          ),
          boxShadow: _isHovered
              ? [
                  BoxShadow(
                    color: AppColors.warmBrown.withOpacity(0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        padding: const EdgeInsets.all(AppSpacing.large),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildIcon(),
                      const SizedBox(width: AppSpacing.medium),
                      Expanded(child: _buildInfo()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.medium),
                  _buildActions(),
                ],
              )
            : Row(
                children: [
                  _buildIcon(),
                  const SizedBox(width: AppSpacing.large),
                  Expanded(child: _buildInfo()),
                  const SizedBox(width: AppSpacing.medium),
                  _buildActions(),
                ],
              ),
      ),
    );
  }

  Widget _buildIcon() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _isHovered
              ? [AppColors.warmBrown, AppColors.accentMain]
              : [
                  AppColors.warmBrown.withOpacity(0.15),
                  AppColors.accentMain.withOpacity(0.08),
                ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: _isHovered
              ? AppColors.warmBrown
              : AppColors.warmBrown.withOpacity(0.4),
          width: _isHovered ? 2 : 1.5,
        ),
        boxShadow: _isHovered
            ? [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.warmBrown.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Icon(
        Icons.picture_as_pdf,
        color: _isHovered ? Colors.white : AppColors.warmBrown,
        size: 36,
      ),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.document.title,
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.small),
        Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: AppSpacing.tiny),
            Expanded(
              child: Text(
                widget.document.description ?? 'Uploaded ${widget.document.createdAt.toLocal()}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StyledPillButton(
          label: 'Open',
          icon: Icons.open_in_new,
          variant: StyledPillButtonVariant.outlined,
          onPressed: widget.onOpen,
        ),
        const SizedBox(width: AppSpacing.small),
        StyledPillButton(
          label: 'Delete',
          icon: Icons.delete_outline,
          variant: StyledPillButtonVariant.outlined,
          onPressed: widget.onDelete,
        ),
      ],
    );
  }
}

