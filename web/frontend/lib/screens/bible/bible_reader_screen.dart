import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_typography.dart';
import '../../services/api_service.dart';
import '../../services/bible_reading_settings.dart';
import '../../models/document_asset.dart';
import '../../utils/media_utils.dart';

class BibleReaderScreen extends StatefulWidget {
  final DocumentAsset? document;

  const BibleReaderScreen({
    super.key,
    this.document,
  });

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
  double _zoomLevel = 1.0;
  bool _showSettings = false;
  List<int> _bookmarks = [];
  
  // Flag to prevent sidebar highlight updates during programmatic navigation
  bool _isNavigatingProgrammatically = false;
  // Timer for debouncing page change callbacks
  Timer? _pageChangeDebounceTimer;
  
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.25;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadBookmarks();
    _loadPdf();
  }

  Future<void> _loadSettings() async {
    final zoom = await BibleReadingSettings.getZoomLevel();
    final documentId = widget.document?.id ?? 0;
    final lastPage = documentId > 0 
        ? await BibleReadingSettings.getLastPage(documentId)
        : 1;
    
    if (mounted) {
      setState(() {
        _zoomLevel = zoom;
        _currentPage = lastPage;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    final documentId = widget.document?.id ?? 0;
    if (documentId > 0) {
      final bookmarks = await BibleReadingSettings.getBookmarks(documentId);
      if (mounted) {
        setState(() {
          _bookmarks = bookmarks;
        });
      }
    }
  }

  Future<void> _saveLastPage() async {
    final documentId = widget.document?.id ?? 0;
    if (documentId > 0) {
      await BibleReadingSettings.setLastPage(documentId, _currentPage);
    }
  }

  Future<void> _saveZoomLevel() async {
    await BibleReadingSettings.setZoomLevel(_zoomLevel);
  }

  Future<void> _toggleBookmark() async {
    final documentId = widget.document?.id ?? 0;
    if (documentId == 0) return;

    setState(() {
      if (_bookmarks.contains(_currentPage)) {
        _bookmarks.remove(_currentPage);
      } else {
        _bookmarks.add(_currentPage);
        _bookmarks.sort();
      }
    });

    await BibleReadingSettings.setBookmarks(documentId, _bookmarks);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _bookmarks.contains(_currentPage)
                ? 'Page $_currentPage bookmarked'
                : 'Bookmark removed',
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.warmBrown,
        ),
      );
    }
  }

  Future<void> _loadPdf() async {
    if (widget.document == null) {
      setState(() {
        _isLoading = false;
        _error = 'No Bible document selected. Please select a document from the home screen.';
      });
      return;
    }

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
            initialPage: _currentPage - 1, // Convert 1-based to 0-based for PDF controller
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
    if (widget.document == null) {
      throw Exception('No document provided');
    }
    
    final url = resolveMediaUrl(widget.document!.filePath);
    if (url == null) {
      throw Exception('Document URL is not available');
    }
    
    final response = await ApiService().downloadFileBytes(url);
    return response;
  }

  void _onPageChanged(int page) {
    // PDF library uses 0-based indexing, convert to 1-based for display
    final newPage = page + 1;
    
    // Debounce rapid page changes during scroll
    _pageChangeDebounceTimer?.cancel();
    _pageChangeDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted && !_isNavigatingProgrammatically) {
        setState(() {
          _currentPage = newPage;
        });
        _saveLastPage();
      }
    });
  }

  void _setZoom(double zoom) {
    setState(() {
      _zoomLevel = zoom.clamp(_minZoom, _maxZoom);
    });
    _saveZoomLevel();
  }

  void _goToPage(int page) {
    // page is 1-based, convert to 0-based for PDF controller
    if (page >= 1 && page <= _totalPages && _pdfController != null) {
      // Set flag to prevent sidebar highlight updates during navigation
      _isNavigatingProgrammatically = true;
      
      // Update current page immediately for sidebar highlight
      setState(() {
        _currentPage = page;
      });
      
      // Navigate to the page
      _pdfController!.jumpToPage(page - 1);
      
      // Reset flag after navigation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isNavigatingProgrammatically = false;
          });
          _saveLastPage();
        }
      });
    }
  }

  @override
  void dispose() {
    _pageChangeDebounceTimer?.cancel();
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Column(
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
          
          // Settings Panel
          if (_showSettings)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildSettingsPanel(),
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.document?.title ?? 'The Holy Bible',
                  style: AppTypography.heading3.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 18 : 22, // Smaller font on mobile
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_totalPages > 0 && !isMobile)
                  Text(
                    'Page $_currentPage of $_totalPages',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
              ],
            ),
          ),
          // Bookmark toggle
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                _bookmarks.contains(_currentPage) 
                    ? Icons.bookmark 
                    : Icons.bookmark_border,
                color: Colors.white,
              ),
              onPressed: _toggleBookmark,
              tooltip: 'Bookmark this page',
            ),
          ),
          const SizedBox(width: 8),
          // View bookmarks
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: const Icon(Icons.bookmarks_outlined, color: Colors.white),
              onPressed: _showBookmarksDialog,
              tooltip: 'View bookmarks',
            ),
          ),
          const SizedBox(width: 8),
          // Settings
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
            ),
            child: IconButton(
              icon: Icon(
                _showSettings ? Icons.settings : Icons.settings_outlined,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showSettings = !_showSettings;
                });
              },
              tooltip: 'Reading settings',
            ),
          ),
          // Toggle sidebar on desktop
          if (!isMobile) ...[
            const SizedBox(width: 8),
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
          ],
          const SizedBox(width: 8),
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

  Widget _buildSettingsPanel() {
    return Container(
      margin: EdgeInsets.all(AppSpacing.medium),
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderPrimary),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Reading Settings',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => setState(() => _showSettings = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Zoom Level
          Text(
            'Zoom: ${(_zoomLevel * 100).toInt()}%',
            style: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: AppColors.textPrimary),
                onPressed: () => _setZoom(_zoomLevel - 0.25),
              ),
              Expanded(
                child: Slider(
                  value: _zoomLevel,
                  min: _minZoom,
                  max: _maxZoom,
                  divisions: 10,
                  activeColor: AppColors.warmBrown,
                  inactiveColor: AppColors.borderPrimary,
                  onChanged: _setZoom,
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: AppColors.textPrimary),
                onPressed: () => _setZoom(_zoomLevel + 0.25),
              ),
            ],
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
              color: AppColors.backgroundPrimary,
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
              // PDF View with zoom support
              Center(
                child: Transform.scale(
                  scale: _zoomLevel,
                  alignment: Alignment.center,
                  child: PdfViewPinch(
                    controller: _pdfController!,
                    onDocumentLoaded: (document) {
                      setState(() => _totalPages = document.pagesCount);
                    },
                    onPageChanged: _onPageChanged,
                    builders: PdfViewPinchBuilders<DefaultBuilderOptions>(
                      options: const DefaultBuilderOptions(),
                      documentLoaderBuilder: (_) => _buildLoadingState(),
                      errorBuilder: (_, error) => _buildErrorState(),
                    ),
                  ),
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
                  color: AppColors.textPrimary,
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
                  onTap: () => _goToPage(startPage),
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
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundPrimary,
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
          // Mobile: Only show page indicator
          if (isMobile) ...[
             // Page Info with Progress
            InkWell(
              onTap: _showPageJumpDialog,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown, AppColors.accentMain],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentPage / $_totalPages',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Desktop: Full controls
            // Zoom Out Button
            Container(
              decoration: BoxDecoration(
                color: _zoomLevel > _minZoom
                    ? AppColors.warmBrown.withOpacity(0.1)
                    : AppColors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.zoom_out,
                  color: _zoomLevel > _minZoom ? AppColors.warmBrown : AppColors.textTertiary,
                  size: 22,
                ),
                tooltip: 'Zoom Out',
                onPressed: _zoomLevel > _minZoom ? () => _setZoom(_zoomLevel - _zoomStep) : null,
              ),
            ),
            const SizedBox(width: 8),
            
            // Zoom Level Display
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${(_zoomLevel * 100).toInt()}%',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            
            // Zoom In Button
            Container(
              decoration: BoxDecoration(
                color: _zoomLevel < _maxZoom
                    ? AppColors.warmBrown.withOpacity(0.1)
                    : AppColors.backgroundSecondary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.zoom_in,
                  color: _zoomLevel < _maxZoom ? AppColors.warmBrown : AppColors.textTertiary,
                  size: 22,
                ),
                tooltip: 'Zoom In',
                onPressed: _zoomLevel < _maxZoom ? () => _setZoom(_zoomLevel + _zoomStep) : null,
              ),
            ),
            
            const SizedBox(width: 20),
            
            // Divider
            Container(
              width: 1,
              height: 30,
              color: AppColors.borderPrimary,
            ),
            
            const SizedBox(width: 20),
            
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
                tooltip: 'Previous Page',
                onPressed: _currentPage > 1 
                    ? () => _pdfController?.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            
            // Page Info with Progress
            InkWell(
              onTap: _showPageJumpDialog,
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.warmBrown, AppColors.accentMain],
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$_currentPage / $_totalPages',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_totalPages > 0) ...[
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 100,
                        child: LinearProgressIndicator(
                          value: _currentPage / _totalPages,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(2),
                          minHeight: 2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            
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
                tooltip: 'Next Page',
                onPressed: _currentPage < _totalPages 
                    ? () => _pdfController?.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      )
                    : null,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPageJumpDialog() {
    final controller = TextEditingController(text: _currentPage.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundPrimary,
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
            Text(
              'Go to Page',
              style: AppTypography.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
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
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Page number',
                hintStyle: TextStyle(color: AppColors.textPlaceholder),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppColors.borderPrimary),
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
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
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
      _goToPage(page);
    }
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Bookmarks',
          style: AppTypography.heading4.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: _bookmarks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 48,
                        color: AppColors.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No bookmarks yet',
                        style: AppTypography.body.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap the bookmark icon to save pages',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: _bookmarks.length,
                  itemBuilder: (context, index) {
                    final page = _bookmarks[index];
                    return ListTile(
                      leading: Icon(Icons.bookmark, color: AppColors.warmBrown),
                      title: Text(
                        'Page $page',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () async {
                          setState(() {
                            _bookmarks.remove(page);
                          });
                          final documentId = widget.document?.id ?? 0;
                          if (documentId > 0) {
                            await BibleReadingSettings.setBookmarks(documentId, _bookmarks);
                          }
                          if (mounted) {
                            Navigator.pop(context);
                            if (_bookmarks.isNotEmpty) {
                              _showBookmarksDialog();
                            }
                          }
                        },
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        // Add delay to ensure dialog dismissal completes before navigation
                        Future.delayed(const Duration(milliseconds: 100), () {
                          _goToPage(page);
                        });
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
