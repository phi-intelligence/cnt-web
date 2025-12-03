import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pdfx/pdfx.dart';

import '../../models/document_asset.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../theme/app_spacing.dart';
import '../../utils/media_utils.dart';

class PDFViewerScreen extends StatefulWidget {
  final DocumentAsset document;

  const PDFViewerScreen({
    super.key,
    required this.document,
  });

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  PdfController? _pdfController;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isFullscreen = false;
  double _zoomLevel = 1.0;
  final double _minZoom = 0.5;
  final double _maxZoom = 3.0;
  final double _zoomStep = 0.25;
  
  // Auto-hide controls in fullscreen mode
  bool _showControls = true;
  DateTime _lastInteraction = DateTime.now();
  static const Duration _autoHideDelay = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _loadDocument();
    _startAutoHideTimer();
  }
  
  void _startAutoHideTimer() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAutoHide();
      }
    });
  }
  
  void _checkAutoHide() {
    if (!mounted) return;
    
    if (_isFullscreen && DateTime.now().difference(_lastInteraction) > _autoHideDelay) {
      if (_showControls) {
        setState(() {
          _showControls = false;
        });
      }
    }
    
    // Continue checking
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _checkAutoHide();
      }
    });
  }
  
  void _onUserInteraction() {
    _lastInteraction = DateTime.now();
    if (!_showControls && _isFullscreen) {
      setState(() {
        _showControls = true;
      });
    }
  }

  Future<void> _loadDocument() async {
    try {
      final url = resolveMediaUrl(widget.document.filePath);
      if (url == null) {
        throw Exception('Document URL is not available.');
      }

      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download document (HTTP ${response.statusCode}).');
      }

      // Load PDF document
      final pdfDocFuture = PdfDocument.openData(response.bodyBytes);
      final pdfDoc = await pdfDocFuture;
      
      // Initialize controller with the document
      _pdfController = PdfController(
        document: pdfDocFuture,
      );
      
      if (mounted) {
        setState(() {
          _totalPages = pdfDoc.pagesCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _pdfController?.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _pdfController?.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPage(int page) {
    if (page >= 1 && page <= _totalPages) {
      _pdfController?.jumpToPage(page);
    }
  }

  void _zoomIn() {
    if (_zoomLevel < _maxZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel + _zoomStep).clamp(_minZoom, _maxZoom);
      });
    }
  }

  void _zoomOut() {
    if (_zoomLevel > _minZoom) {
      setState(() {
        _zoomLevel = (_zoomLevel - _zoomStep).clamp(_minZoom, _maxZoom);
      });
    }
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      _showControls = true; // Always show controls when toggling
      _lastInteraction = DateTime.now();
    });
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundPrimary,
      appBar: _isFullscreen
          ? null
          : AppBar(
              backgroundColor: AppColors.backgroundPrimary,
              elevation: 0,
              iconTheme: IconThemeData(color: AppColors.primaryMain),
              title: Text(
                widget.document.title ?? 'Bible Document',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryMain),
        ),
      );
    }

    if (_errorMessage != null || _pdfController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, size: 48, color: AppColors.errorMain),
              const SizedBox(height: 12),
              Text(
                'Unable to open document',
                style: AppTypography.heading4.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Unknown error occurred.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isMobile = screenWidth < 768;
    final containerMaxWidth = _isFullscreen ? screenWidth : (isMobile ? screenWidth - 32 : 1200.0);

    // Wrap with MouseRegion and GestureDetector for auto-hide functionality
    return MouseRegion(
      onHover: (_) => _onUserInteraction(),
      onEnter: (_) => _onUserInteraction(),
      child: GestureDetector(
        onTap: _onUserInteraction,
        onPanDown: (_) => _onUserInteraction(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: containerMaxWidth),
                  margin: _isFullscreen 
                      ? EdgeInsets.zero 
                      : EdgeInsets.all(isMobile ? AppSpacing.medium : AppSpacing.large),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    border: _isFullscreen 
                        ? null 
                        : Border.all(
                            color: AppColors.borderPrimary,
                            width: 2,
                          ),
                    borderRadius: _isFullscreen 
                        ? BorderRadius.zero 
                        : BorderRadius.circular(AppSpacing.radiusLarge),
                    boxShadow: _isFullscreen 
                        ? null 
                        : [
                            BoxShadow(
                              color: AppColors.primaryMain.withOpacity(0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: ClipRRect(
                    borderRadius: _isFullscreen 
                        ? BorderRadius.zero 
                        : BorderRadius.circular(AppSpacing.radiusLarge - 2),
                    child: InteractiveViewer(
                      minScale: _minZoom,
                      maxScale: _maxZoom,
                      scaleEnabled: true,
                      panEnabled: true,
                      child: Transform.scale(
                        scale: _zoomLevel,
                        child: PdfView(
                          controller: _pdfController!,
                          onPageChanged: (page) {
                            if (mounted) {
                              setState(() {
                                _currentPage = page;
                              });
                            }
                          },
                          scrollDirection: Axis.vertical,
                          physics: const AlwaysScrollableScrollPhysics(),
                          pageSnapping: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_isFullscreen) _buildNavigationBar(isMobile),
          ],
        ),
        // Floating controls - auto-hide in fullscreen mode
        // Note: Positioned must be direct child of Stack, so AnimatedOpacity goes inside
        _buildFloatingControls(isMobile),
      ],
        ),
      ),
    );
  }

  Widget _buildFloatingControls(bool isMobile) {
    return Positioned(
      right: isMobile ? AppSpacing.medium : AppSpacing.large,
      top: _isFullscreen 
          ? AppSpacing.large + MediaQuery.of(context).padding.top
          : AppSpacing.large,
      child: AnimatedOpacity(
        opacity: (!_isFullscreen || _showControls) ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: _isFullscreen && !_showControls,
          child: Column(
        children: [
          // Fullscreen toggle
          _buildControlButton(
            icon: _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: _toggleFullscreen,
            tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Zoom in
          _buildControlButton(
            icon: Icons.zoom_in,
            onPressed: _zoomLevel < _maxZoom ? _zoomIn : null,
            tooltip: 'Zoom In',
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Zoom level indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.small,
              vertical: AppSpacing.tiny,
            ),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              border: Border.all(color: AppColors.borderPrimary),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryMain.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${(_zoomLevel * 100).toInt()}%',
              style: AppTypography.caption.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Zoom out
          _buildControlButton(
            icon: Icons.zoom_out,
            onPressed: _zoomLevel > _minZoom ? _zoomOut : null,
            tooltip: 'Zoom Out',
          ),
          const SizedBox(height: AppSpacing.small),
          
          // Reset zoom
          _buildControlButton(
            icon: Icons.fit_screen,
            onPressed: _zoomLevel != 1.0 ? _resetZoom : null,
            tooltip: 'Reset Zoom',
          ),
          
          // Back button in fullscreen mode
          if (_isFullscreen) ...[
            const SizedBox(height: AppSpacing.medium),
            _buildControlButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.of(context).pop(),
              tooltip: 'Back',
            ),
          ],
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border.all(
          color: AppColors.borderPrimary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        onPressed: onPressed,
        color: onPressed != null ? AppColors.primaryMain : AppColors.textTertiary,
        tooltip: tooltip,
        padding: const EdgeInsets.all(AppSpacing.small),
        constraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 40,
        ),
      ),
    );
  }

  Widget _buildNavigationBar(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.medium : AppSpacing.large,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(
          top: BorderSide(color: AppColors.borderPrimary, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Previous button
            IconButton(
              icon: const Icon(Icons.chevron_left, size: 28),
              onPressed: _currentPage > 1 ? _previousPage : null,
              color: _currentPage > 1 ? AppColors.primaryMain : AppColors.textTertiary,
              tooltip: 'Previous Page',
            ),
            
            const SizedBox(width: AppSpacing.small),
            
            // Page indicator with direct input
            InkWell(
              onTap: () => _showPageNumberDialog(),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? AppSpacing.medium : AppSpacing.large,
                  vertical: AppSpacing.small,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundPrimary,
                  border: Border.all(color: AppColors.borderPrimary),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Page $_currentPage of $_totalPages',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.small),
            
            // Next button
            IconButton(
              icon: const Icon(Icons.chevron_right, size: 28),
              onPressed: _currentPage < _totalPages ? _nextPage : null,
              color: _currentPage < _totalPages ? AppColors.primaryMain : AppColors.textTertiary,
              tooltip: 'Next Page',
            ),
          ],
        ),
      ),
    );
  }

  void _showPageNumberDialog() {
    final textController = TextEditingController(text: _currentPage.toString());
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.backgroundPrimary,
          title: Text(
            'Go to Page',
            style: AppTypography.heading4.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Page Number',
              labelStyle: TextStyle(color: AppColors.textSecondary),
              hintText: 'Enter page number (1-$_totalPages)',
              hintStyle: TextStyle(color: AppColors.textPlaceholder),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                borderSide: BorderSide(color: AppColors.borderPrimary),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSmall),
                borderSide: BorderSide(color: AppColors.primaryMain, width: 2),
              ),
            ),
            style: TextStyle(color: AppColors.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final pageNumber = int.tryParse(textController.text);
                if (pageNumber != null && pageNumber >= 1 && pageNumber <= _totalPages) {
                  _goToPage(pageNumber);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a valid page number between 1 and $_totalPages'),
                      backgroundColor: AppColors.errorMain,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryMain,
                foregroundColor: Colors.white,
              ),
              child: const Text('Go'),
            ),
          ],
        );
      },
    );
  }
}

