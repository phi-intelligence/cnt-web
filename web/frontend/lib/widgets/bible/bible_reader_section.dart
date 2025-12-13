import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import '../../models/api_models.dart';
import '../../models/document_asset.dart';
import '../../screens/bible/bible_document_selector_screen.dart';
import '../../screens/bible/pdf_viewer_screen.dart';
import '../../screens/bible/bible_reader_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';

/// Popular Bible verses for the daily quote feature
const List<Map<String, String>> _bibleVerses = [
  {'reference': 'John 3:16', 'text': 'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.'},
  {'reference': 'Jeremiah 29:11', 'text': 'For I know the plans I have for you, declares the Lord, plans to prosper you and not to harm you, plans to give you hope and a future.'},
  {'reference': 'Philippians 4:13', 'text': 'I can do all this through him who gives me strength.'},
  {'reference': 'Romans 8:28', 'text': 'And we know that in all things God works for the good of those who love him, who have been called according to his purpose.'},
  {'reference': 'Proverbs 3:5-6', 'text': 'Trust in the Lord with all your heart and lean not on your own understanding; in all your ways submit to him, and he will make your paths straight.'},
  {'reference': 'Isaiah 41:10', 'text': 'So do not fear, for I am with you; do not be dismayed, for I am your God. I will strengthen you and help you; I will uphold you with my righteous right hand.'},
  {'reference': 'Psalm 23:1', 'text': 'The Lord is my shepherd, I lack nothing.'},
  {'reference': 'Matthew 11:28', 'text': 'Come to me, all you who are weary and burdened, and I will give you rest.'},
  {'reference': 'Romans 12:2', 'text': 'Do not conform to the pattern of this world, but be transformed by the renewing of your mind.'},
  {'reference': 'Joshua 1:9', 'text': 'Have I not commanded you? Be strong and courageous. Do not be afraid; do not be discouraged, for the Lord your God will be with you wherever you go.'},
  {'reference': 'Psalm 46:1', 'text': 'God is our refuge and strength, an ever-present help in trouble.'},
  {'reference': '2 Timothy 1:7', 'text': 'For God has not given us a spirit of fear, but of power and of love and of a sound mind.'},
  {'reference': 'Hebrews 11:1', 'text': 'Now faith is confidence in what we hope for and assurance about what we do not see.'},
  {'reference': 'Psalm 119:105', 'text': 'Your word is a lamp for my feet, a light on my path.'},
  {'reference': 'Matthew 6:33', 'text': 'But seek first his kingdom and his righteousness, and all these things will be given to you as well.'},
  {'reference': 'Galatians 5:22-23', 'text': 'But the fruit of the Spirit is love, joy, peace, forbearance, kindness, goodness, faithfulness, gentleness and self-control.'},
  {'reference': '1 Corinthians 13:4-5', 'text': 'Love is patient, love is kind. It does not envy, it does not boast, it is not proud. It does not dishonor others, it is not self-seeking.'},
  {'reference': 'Ephesians 2:8-9', 'text': 'For it is by grace you have been saved, through faith—and this is not from yourselves, it is the gift of God—not by works, so that no one can boast.'},
  {'reference': 'Psalm 37:4', 'text': 'Take delight in the Lord, and he will give you the desires of your heart.'},
  {'reference': 'Romans 5:8', 'text': 'But God demonstrates his own love for us in this: While we were still sinners, Christ died for us.'},
  {'reference': '1 Peter 5:7', 'text': 'Cast all your anxiety on him because he cares for you.'},
  {'reference': 'Isaiah 40:31', 'text': 'But those who hope in the Lord will renew their strength. They will soar on wings like eagles; they will run and not grow weary, they will walk and not be faint.'},
  {'reference': 'Psalm 27:1', 'text': 'The Lord is my light and my salvation—whom shall I fear? The Lord is the stronghold of my life—of whom shall I be afraid?'},
  {'reference': 'Matthew 28:20', 'text': 'And surely I am with you always, to the very end of the age.'},
  {'reference': 'Colossians 3:23', 'text': 'Whatever you do, work at it with all your heart, as working for the Lord, not for human masters.'},
  {'reference': 'James 1:5', 'text': 'If any of you lacks wisdom, you should ask God, who gives generously to all without finding fault, and it will be given to you.'},
  {'reference': 'Psalm 34:8', 'text': 'Taste and see that the Lord is good; blessed is the one who takes refuge in him.'},
  {'reference': '1 John 4:19', 'text': 'We love because he first loved us.'},
  {'reference': 'Proverbs 16:3', 'text': 'Commit to the Lord whatever you do, and he will establish your plans.'},
  {'reference': 'Matthew 5:14', 'text': 'You are the light of the world. A town built on a hill cannot be hidden.'},
];

/// Bible Reader section with two side-by-side square boxes
/// Left: Bible Reader button, Right: Daily Bible Quote button
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
  final Random _random = Random();

  Future<void> _handleBibleReaderTap() async {
    // Open the new full-screen Bible Reader interface
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const BibleReaderScreen(),
      ),
    );
  }

  void _showBibleQuotePopup() {
    final verse = _bibleVerses[_random.nextInt(_bibleVerses.length)];
    _showQuoteDialog(verse);
  }

  void _showQuoteDialog(Map<String, String> verse) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500),
          padding: const EdgeInsets.all(AppSpacing.extraLarge),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.format_quote,
                        color: AppColors.warmBrown,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.small),
                      Text(
                        'Bible Verse',
                        style: AppTypography.heading3.copyWith(
                          color: AppColors.warmBrown,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.large),
              
              // Quote content
              Container(
                padding: const EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.warmBrown.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(
                      '"${verse['text']}"',
                      style: AppTypography.body.copyWith(
                        fontSize: 18,
                        height: 1.6,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Text(
                      '— ${verse['reference']}',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warmBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.large),
              
              // New Quote button
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  // Show a new random verse
                  final newVerse = _bibleVerses[_random.nextInt(_bibleVerses.length)];
                  Future.delayed(const Duration(milliseconds: 200), () {
                    if (mounted) _showQuoteDialog(newVerse);
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.warmBrown,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.extraLarge,
                    vertical: AppSpacing.medium,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('New Quote'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasContent = widget.documents.isNotEmpty || widget.stories.isNotEmpty;
    final isMobile = ResponsiveUtils.isMobile(context);
    final isTablet = ResponsiveUtils.isTablet(context);

    // On mobile, stack vertically; on tablet/desktop, side by side
    if (isMobile) {
      return Column(
        children: [
          _buildBibleReaderBox(isMobile: true),
          const SizedBox(height: AppSpacing.medium),
          _buildBibleQuoteBox(isMobile: true),
        ],
      );
    }

    // Desktop/Tablet: Side by side with 50% width each
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildBibleReaderBox(isMobile: false),
        ),
        SizedBox(width: isTablet ? AppSpacing.medium : AppSpacing.large),
        Expanded(
          child: _buildBibleQuoteBox(isMobile: false),
        ),
      ],
    );
  }

  Widget _buildBibleReaderBox({required bool isMobile}) {
    final hasContent = widget.documents.isNotEmpty || widget.stories.isNotEmpty;
    
    return GestureDetector(
      onTap: hasContent ? _handleBibleReaderTap : null,
      child: MouseRegion(
        cursor: hasContent ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
          decoration: BoxDecoration(
            color: AppColors.warmBrown,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Read the Bible',
                      style: (isMobile ? AppTypography.heading3 : AppTypography.heading2).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      hasContent 
                          ? "Explore God's word through stories and documents."
                          : "Bible documents coming soon.",
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? AppSpacing.medium : AppSpacing.large),
              // Icon
              Container(
                padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.menu_book,
                  size: isMobile ? 36 : 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBibleQuoteBox({required bool isMobile}) {
    return GestureDetector(
      onTap: _showBibleQuotePopup,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          padding: EdgeInsets.all(isMobile ? AppSpacing.large : AppSpacing.extraLarge),
          decoration: BoxDecoration(
            color: AppColors.warmBrown,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmBrown.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Daily Bible Quote',
                      style: (isMobile ? AppTypography.heading3 : AppTypography.heading2).copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.small),
                    Text(
                      "Tap to receive an inspiring verse from Scripture.",
                      style: AppTypography.body.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: isMobile ? AppSpacing.medium : AppSpacing.large),
              // Icon
              Container(
                padding: EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.format_quote,
                  size: isMobile ? 36 : 48,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
