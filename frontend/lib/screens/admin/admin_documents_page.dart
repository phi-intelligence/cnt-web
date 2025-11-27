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
import '../../widgets/web/styled_page_header.dart';
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
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: ResponsiveGridDelegate.getMaxContentWidth(context),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Upload Button
                      Row(
                        children: [
                          Expanded(
                            child: StyledPageHeader(
                              title: 'Bible Documents',
                              size: StyledPageHeaderSize.h2,
                            ),
                          ),
                          StyledPillButton(
                            label: _isUploading ? 'Uploading...' : 'Upload PDF',
                            icon: Icons.cloud_upload,
                            onPressed: _isUploading ? null : _handleUpload,
                            isLoading: _isUploading,
                          ),
                        ],
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
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.menu_book_outlined,
                                    size: 80,
                                    color: AppColors.textSecondary.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: AppSpacing.medium),
                                  Text(
                                    'No documents yet',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.heading3.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.small),
                                  Text(
                                    'Upload Bible PDFs or study guides to appear in the Bible Reader.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.large),
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
    return SectionContainer(
      showShadow: true,
      child: Row(
        children: [
          // PDF Icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.errorMain.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            ),
            child: Icon(
              Icons.picture_as_pdf,
              color: AppColors.errorMain,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.large),
          // Document Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  document.title,
                  style: AppTypography.heading4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.tiny),
                Text(
                  document.description ?? 'Uploaded ${document.createdAt.toLocal()}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.medium),
          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StyledPillButton(
                label: 'Open',
                icon: Icons.open_in_new,
                variant: StyledPillButtonVariant.outlined,
                onPressed: downloadUrl == null
                    ? null
                    : () => launchUrl(Uri.parse(downloadUrl)),
              ),
              const SizedBox(width: AppSpacing.small),
              StyledPillButton(
                label: 'Delete',
                icon: Icons.delete_outline,
                variant: StyledPillButtonVariant.outlined,
                onPressed: () async {
                  await provider.deleteDocument(document.id);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${document.title} deleted')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

