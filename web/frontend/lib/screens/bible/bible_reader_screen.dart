import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../widgets/web/styled_page_header.dart';
import '../../services/api_service.dart';

class BibleReaderScreen extends StatefulWidget {
  const BibleReaderScreen({super.key});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  PdfControllerPinch? _pdfController;
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _showSidebar = true;
  
  // Bible PDF URL from S3
  static const String _biblePdfUrl = 'https://cnt-web-media.s3.eu-west-2.amazonaws.com/documents/doc_c4f436f7-9df5-449f-92cc-2aeb7a048180.pdf';

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final bytes = await _downloadPdf();
      final document = await PdfDocument.openData(
        Uint8List.fromList(bytes),
      );
      
      if (mounted) {
        setState(() {
          _pdfController = PdfControllerPinch(
            document: Future.value(document),
          );
          _totalPages = document.pagesCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load Bible PDF: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<List<int>> _downloadPdf() async {
    final response = await ApiService().downloadFileBytes(_biblePdfUrl);
    return response;
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      body: Column(
        children: [
          // Header
          _buildHeader(isMobile),
          
          // Main Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildPdfViewer(isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24, 
        vertical: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.warmBrown,
            AppColors.warmBrown.withOpacity(0.85),
            AppColors.primaryMain.withOpacity(0.9),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.menu_book, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'The Holy Bible',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_totalPages > 0)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          // Toggle sidebar on desktop
          if (!isMobile) ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: IconButton(
                icon: Icon(
                  _showSidebar ? Icons.menu_open : Icons.menu,
                  color: Colors.white,
                ),
                onPressed: () => setState(() => _showSidebar = !_showSidebar),
                tooltip: _showSidebar ? 'Hide Navigation' : 'Show Navigation',
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Page jump
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.find_in_page, color: Colors.white),
              onPressed: _showPageJumpDialog,
              tooltip: 'Go to Page',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warmBrown.withOpacity(0.1),
                      AppColors.accentMain.withOpacity(0.05),
                    ],
                  ),
                ),
              ),
              CircularProgressIndicator(
                color: AppColors.warmBrown,
                strokeWidth: 3,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Loading the Holy Bible...',
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while the scripture is prepared',
            style: AppTypography.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.errorMain.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 56,
                color: AppColors.errorMain,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load Bible',
              style: AppTypography.heading3.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'An error occurred',
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warmBrown, AppColors.accentMain],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: ElevatedButton.icon(
                onPressed: _loadPdf,
                icon: Icon(Icons.refresh, color: Colors.white),
                label: Text('Retry', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfViewer(bool isMobile) {
    if (_pdfController == null) return const SizedBox();

    return Row(
      children: [
        // Sidebar (Page Navigation) - Only on desktop
        if (!isMobile && _showSidebar)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                right: BorderSide(color: AppColors.borderPrimary),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: _buildPageNavigator(),
          ),
        
        // PDF Content
        Expanded(
          child: Stack(
            children: [
              // PDF View
              PdfViewPinch(
                controller: _pdfController!,
                onDocumentLoaded: (document) {
                  setState(() => _totalPages = document.pagesCount);
                },
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                  options: const DefaultBuilderOptions(),
                  documentLoaderBuilder: (_) => _buildLoadingState(),
                  errorBuilder: (_, error) => _buildErrorState(),
                ),
              ),
              
              // Bottom Navigation Bar
              Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: _buildBottomNavigationBar(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPageNavigator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown.withOpacity(0.15), AppColors.accentMain.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.bookmark_outline, color: AppColors.warmBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Quick Navigation',
                style: AppTypography.heading4.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: AppColors.borderPrimary),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _totalPages > 0 ? ((_totalPages / 50).ceil()) : 0,
            itemBuilder: (context, index) {
              final startPage = index * 50 + 1;
              final endPage = ((index + 1) * 50).clamp(1, _totalPages);
              final isCurrentRange = _currentPage >= startPage && _currentPage <= endPage;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _pdfController?.jumpToPage(startPage),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isCurrentRange ? AppColors.warmBrown : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: isCurrentRange 
                          ? null 
                          : Border.all(color: AppColors.borderPrimary),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          color: isCurrentRange ? Colors.white : AppColors.textSecondary,
                          size: 18,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Pages $startPage - $endPage',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isCurrentRange ? Colors.white : AppColors.textPrimary,
                            fontWeight: isCurrentRange ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmBrown.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Previous Page
          Container(
            decoration: BoxDecoration(
              color: _currentPage > 1 
                  ? AppColors.warmBrown.withOpacity(0.1) 
                  : AppColors.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_left,
                color: _currentPage > 1 ? AppColors.warmBrown : AppColors.textTertiary,
              ),
              onPressed: _currentPage > 1 
                  ? () => _pdfController?.previousPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          
          // Page Info
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              '$_currentPage / $_totalPages',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          
          // Next Page
          Container(
            decoration: BoxDecoration(
              color: _currentPage < _totalPages 
                  ? AppColors.warmBrown.withOpacity(0.1) 
                  : AppColors.backgroundSecondary,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(
                Icons.chevron_right,
                color: _currentPage < _totalPages ? AppColors.warmBrown : AppColors.textTertiary,
              ),
              onPressed: _currentPage < _totalPages 
                  ? () => _pdfController?.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.warmBrown.withOpacity(0.15), AppColors.accentMain.withOpacity(0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.find_in_page, color: AppColors.warmBrown),
            ),
            const SizedBox(width: 12),
            Text('Go to Page', style: AppTypography.heading4),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter a page number (1 - $_totalPages)',
              style: AppTypography.body.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Page number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.warmBrown, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              ),
              onSubmitted: (value) {
                _jumpToPage(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.warmBrown, AppColors.accentMain],
              ),
              borderRadius: BorderRadius.circular(30),
            ),
            child: ElevatedButton(
              onPressed: () {
                _jumpToPage(controller.text);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Text('Go', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _jumpToPage(String value) {
    final page = int.tryParse(value);
    if (page != null && page >= 1 && page <= _totalPages) {
      _pdfController?.jumpToPage(page);
    }
  }
}
