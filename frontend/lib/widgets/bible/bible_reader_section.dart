import 'dart:async';

import 'package:flutter/material.dart';
import '../../models/api_models.dart';
import '../../models/document_asset.dart';
import '../../screens/bible/bible_document_selector_screen.dart';
import '../../screens/bible/pdf_viewer_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';

/// Bible Reader section styled like the Voice Board section
/// Main container with gradient background, text on left, circular bubble on right
class BibleReaderSection extends StatefulWidget {
  final List<BibleStory> stories;
  final List<DocumentAsset> documents;
  final void Function(BibleStory)? onOpenStory;
  final void Function(DocumentAsset)? onOpenDocument;
  final bool isWeb;

  const BibleReaderSection({
    super.key,
    required this.stories,
    this.documents = const [],
    this.onOpenStory,
    this.onOpenDocument,
    this.isWeb = false,
  });

  @override
  State<BibleReaderSection> createState() => _BibleReaderSectionState();
}

class _BibleReaderSectionState extends State<BibleReaderSection> {
  Future<void> _handleBibleReaderTap() async {
    // If documents exist, show document selector or open first document
    if (widget.documents.isNotEmpty) {
      DocumentAsset? selectedDoc = widget.documents.first;

      // If multiple documents exist, allow the user to pick a version
      if (widget.documents.length > 1) {
        selectedDoc = await Navigator.push<DocumentAsset>(
          context,
          MaterialPageRoute(
            builder: (_) => BibleDocumentSelectorScreen(documents: widget.documents),
          ),
        );

        // User dismissed selector without choosing; fall back to first doc
        selectedDoc ??= widget.documents.first;
      }

      final docToOpen = selectedDoc;
      if (docToOpen == null) return;

      if (widget.onOpenDocument != null) {
        widget.onOpenDocument!(docToOpen);
        return;
      }

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewerScreen(document: docToOpen),
        ),
      );
    } else if (widget.stories.isNotEmpty) {
      // If stories exist, open the first story
      final firstStory = widget.stories.first;
      if (widget.onOpenStory != null) {
        widget.onOpenStory!(firstStory);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.documents.isNotEmpty || widget.stories.isNotEmpty;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (!hasContent) {
      return const SizedBox.shrink();
    }

    // Pill-shaped brown container
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.large : AppSpacing.extraLarge * 2,
        vertical: isMobile ? AppSpacing.large : AppSpacing.extraLarge,
      ),
      decoration: BoxDecoration(
        color: AppColors.warmBrown,
        borderRadius: BorderRadius.circular(999), // Pill shape
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: isMobile
          ? Column(
              children: [
                _buildTextContent(),
                const SizedBox(height: AppSpacing.extraLarge),
                _buildBubble(),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildTextContent(),
                ),
                const SizedBox(width: AppSpacing.extraLarge * 2),
                _buildBubble(),
              ],
            ),
    );
  }

  Widget _buildTextContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Read the Bible',
          style: AppTypography.heading2.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text on brown background
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          "Explore God's word through stories and documents.",
          style: AppTypography.body.copyWith(
            color: Colors.white.withOpacity(0.9), // Slightly transparent white
            height: 1.7,
          ),
        ),
      ],
    );
  }

  Widget _buildBubble() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _handleBibleReaderTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2), // Semi-transparent white on brown
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              Icons.menu_book,
              size: 60,
              color: Colors.white, // White icon on brown background
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        Text(
          'Bible Reader',
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white, // White text on brown background
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


