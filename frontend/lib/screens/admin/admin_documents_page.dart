import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../providers/documents_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/media_utils.dart';

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
      final path = selected.path;

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
            if (provider.isLoading && provider.documents.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryMain),
              );
            }

            if (provider.documents.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(AppSpacing.large),
                children: [
                  const SizedBox(height: AppSpacing.extraLarge),
                  Icon(Icons.menu_book_outlined,
                      size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
                  const SizedBox(height: AppSpacing.medium),
                  Text(
                    'No documents yet',
                    textAlign: TextAlign.center,
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.tiny),
                  Text(
                    'Upload Bible PDFs or study guides to appear in the Bible Reader.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: EdgeInsets.all(AppSpacing.large),
              itemCount: provider.documents.length,
              itemBuilder: (context, index) {
                final document = provider.documents[index];
                final downloadUrl = resolveMediaUrl(document.filePath);
                return Card(
                  margin: EdgeInsets.only(bottom: AppSpacing.medium),
                  child: ListTile(
                    leading: const Icon(Icons.picture_as_pdf, color: AppColors.primaryMain),
                    title: Text(
                      document.title,
                      style: AppTypography.body.copyWith(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      document.description ?? 'Uploaded ${document.createdAt.toLocal()}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Open',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: downloadUrl == null
                              ? null
                              : () => launchUrl(Uri.parse(downloadUrl)),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline, color: AppColors.errorMain),
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
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _handleUpload,
        icon: _isUploading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.cloud_upload),
        label: Text(_isUploading ? 'Uploading...' : 'Upload PDF'),
      ),
    );
  }
}

