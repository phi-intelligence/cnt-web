import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  String _selectedTestament = 'New Testament';
  String _selectedBook = 'John';
  int _selectedChapter = 1;

  final List<String> _oldTestament = [
    'Genesis', 'Exodus', 'Leviticus', 'Numbers', 'Deuteronomy',
    'Joshua', 'Judges', 'Ruth', '1 Samuel', '2 Samuel',
    '1 Kings', '2 Kings', '1 Chronicles', '2 Chronicles', 'Ezra',
    'Nehemiah', 'Esther', 'Job', 'Psalms', 'Proverbs',
    'Ecclesiastes', 'Song of Solomon', 'Isaiah', 'Jeremiah', 'Lamentations',
    'Ezekiel', 'Daniel', 'Hosea', 'Joel', 'Amos',
    'Obadiah', 'Jonah', 'Micah', 'Nahum', 'Habakkuk',
    'Zephaniah', 'Haggai', 'Zechariah', 'Malachi'
  ];

  final List<String> _newTestament = [
    'Matthew', 'Mark', 'Luke', 'John', 'Acts',
    'Romans', '1 Corinthians', '2 Corinthians', 'Galatians', 'Ephesians',
    'Philippians', 'Colossians', '1 Thessalonians', '2 Thessalonians', '1 Timothy',
    '2 Timothy', 'Titus', 'Philemon', 'Hebrews', 'James',
    '1 Peter', '2 Peter', '1 John', '2 John', '3 John',
    'Jude', 'Revelation'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
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
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.warmBrown),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                const StyledPageHeader(
                  title: 'Bible Reader',
                  size: StyledPageHeaderSize.h2,
                ),
                const Spacer(),
                // Settings icons could go here
                IconButton(
                  icon: const Icon(Icons.text_fields, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.bookmark_border, color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: Row(
              children: [
                // Sidebar (Book Navigation)
                Container(
                  width: 300,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: Border(
                      right: BorderSide(color: AppColors.borderPrimary),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Testament Toggle
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.backgroundTertiary,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: AppColors.borderPrimary),
                          ),
                          child: Row(
                            children: [
                              _buildTestamentTab('Old Testament'),
                              _buildTestamentTab('New Testament'),
                            ],
                          ),
                        ),
                      ),
                      
                      // Book List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _selectedTestament == 'Old Testament' 
                              ? _oldTestament.length 
                              : _newTestament.length,
                          itemBuilder: (context, index) {
                            final book = _selectedTestament == 'Old Testament' 
                                ? _oldTestament[index] 
                                : _newTestament[index];
                            final isSelected = book == _selectedBook;
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: InkWell(
                                onTap: () => setState(() => _selectedBook = book),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.warmBrown : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    book,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: isSelected ? Colors.white : AppColors.textPrimary,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Chapter Content
                Expanded(
                  child: Column(
                    children: [
                      // Chapter Navigation Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.borderPrimary.withOpacity(0.5))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _selectedChapter > 1 
                                  ? () => setState(() => _selectedChapter--) 
                                  : null,
                            ),
                            const SizedBox(width: 24),
                            Text(
                              '$_selectedBook Chapter $_selectedChapter',
                              style: AppTypography.heading3.copyWith(color: AppColors.textPrimary),
                            ),
                            const SizedBox(width: 24),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => setState(() => _selectedChapter++),
                            ),
                          ],
                        ),
                      ),
                      
                      // Text Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(64),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800), // Optimal reading width
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chapter $_selectedChapter',
                                  style: AppTypography.heading2.copyWith(
                                    color: AppColors.warmBrown,
                                    fontFamily: 'serif',
                                  ),
                                ),
                                const SizedBox(height: 32),
                                Text(
                                  // Placeholder text repeated
                                  'In the beginning was the Word, and the Word was with God, and the Word was God. He was with God in the beginning. Through him all things were made; without him nothing was made that has been made. In him was life, and that life was the light of all mankind. The light shines in the darkness, and the darkness has not overcome it.\n\nThere was a man sent from God whose name was John. He came as a witness to testify concerning that light, so that through him all might believe. He himself was not the light; he came only as a witness to the light.\n\nThe true light that gives light to everyone was coming into the world. He was in the world, and though the world was made through him, the world did not recognize him. He came to that which was his own, but his own did not receive him. Yet to all who did receive him, to those who believed in his name, he gave the right to become children of God— children born not of natural descent, nor of human decision or a husband’s will, but born of God.\n\nThe Word became flesh and made his dwelling among us. We have seen his glory, the glory of the one and only Son, who came from the Father, full of grace and truth.\n\n(John testified concerning him. He cried out, saying, "This is the one I spoke about when I said, \'He who comes after me has surpassed me because he was before me.\'") Out of his fullness we have all received grace in place of grace already given. For the law was given through Moses; grace and truth came through Jesus Christ. No one has ever seen God, but the one and only Son, who is himself God and is in closest relationship with the Father, has made him known.',
                                  style: AppTypography.body.copyWith(
                                    fontSize: 20,
                                    height: 1.8,
                                    fontFamily: 'serif',
                                    color: AppColors.textPrimary,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestamentTab(String title) {
    final isSelected = _selectedTestament == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTestament = title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.warmBrown : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

