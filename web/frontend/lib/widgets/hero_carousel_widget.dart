import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_typography.dart';
import '../utils/platform_helper.dart';
import '../utils/responsive_utils.dart';

/// Hero Carousel Widget - Image carousel with latest community posts
/// Auto-scrolling carousel displaying images from community posts
class HeroCarouselWidget extends StatefulWidget {
  final Function(int postId)? onItemTap; // Callback when item is tapped (receives postId)
  final double? height; // Optional custom height

  const HeroCarouselWidget({
    super.key,
    this.onItemTap,
    this.height,
  });

  @override
  State<HeroCarouselWidget> createState() => HeroCarouselWidgetState();
}


/// Simple carousel item model for community posts
class _CarouselItem {
  final String id;
  final String imageUrl;
  final String? title;
  final int postId; // For navigation

  _CarouselItem({
    required this.id,
    required this.imageUrl,
    this.title,
    required this.postId,
  });
}

class HeroCarouselWidgetState extends State<HeroCarouselWidget> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<_CarouselItem> _items = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  final Set<String> _loadedImages = {}; // Track loaded images to prevent duplicate logging
  DateTime? _lastLoadTime; // Track when items were last loaded
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent unnecessary rebuilds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadItems();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh when app becomes visible again (useful after admin deletes content)
    if (state == AppLifecycleState.resumed && mounted) {
      // Only refresh if data is older than 30 seconds to avoid excessive API calls
      if (_lastLoadTime == null || 
          DateTime.now().difference(_lastLoadTime!).inSeconds > 30) {
        _loadItems();
      }
    }
  }

  @override
  void didUpdateWidget(HeroCarouselWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If widget is rebuilt, refresh data (e.g., after navigation back)
    if (mounted && _lastLoadTime != null) {
      // Refresh if data is older than 60 seconds
      if (DateTime.now().difference(_lastLoadTime!).inSeconds > 60) {
        _loadItems();
      }
    }
  }

  /// Public method to refresh carousel items (e.g., when posts are deleted)
  Future<void> refresh() async {
    await _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      print('🖼️ Hero Carousel: Fetching approved community posts with images...');
      final apiService = ApiService();
      
      // Clear previous loaded images cache to prevent stale references
      _loadedImages.clear();
      
      // Stop auto-scroll during reload
      _stopAutoScroll();
      
      // Fetch latest approved community posts (backend filters by approved_only=true and image_url)
      final posts = await apiService.getCommunityPosts(
        limit: 20,
        approvedOnly: true,  // Only show approved posts
      );
      print('🖼️ Hero Carousel: Fetched ${posts.length} approved community posts');
      
      // Convert posts to carousel items
      // Backend already filters to only return posts with image_url (both image posts and text posts converted to quote images)
      final items = <_CarouselItem>[];
      for (final post in posts) {
        final imageUrl = post['image_url'] as String?;
        final postId = post['id'] as int;
        final isApproved = post['is_approved'] ?? false;
        final postType = post['post_type'] as String? ?? 'image';
        
        // Backend already filters by image_url, but double-check for safety
        // This includes both: post_type='image' posts AND post_type='text' posts converted to quote images
        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Get full media URL (handles both regular images and generated quote images)
          final fullImageUrl = apiService.getMediaUrl(imageUrl);
          
          // Log detailed information for debugging
          print('🖼️ Hero Carousel: Post $postId');
          print('   - Type: $postType');
          print('   - Approved: $isApproved');
          print('   - Original URL: $imageUrl');
          print('   - Full URL: $fullImageUrl');
          
          // Validate URL before adding
          if (fullImageUrl.isEmpty) {
            print('   ⚠️ Warning: Empty URL after processing, skipping post $postId');
            continue;
          }
          
          // Additional validation: Check if URL is valid format
          try {
            final uri = Uri.parse(fullImageUrl);
            if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
              print('   ⚠️ Warning: Invalid URL scheme, skipping post $postId');
              continue;
            }
          } catch (e) {
            print('   ⚠️ Warning: Invalid URL format ($fullImageUrl), skipping post $postId: $e');
            continue;
          }
          
          items.add(_CarouselItem(
            id: postId.toString(),
            imageUrl: fullImageUrl,
            title: post['title'] as String?,
            postId: postId,
          ));
          
          // Limit to 10-12 items for carousel
          if (items.length >= 12) break;
        } else {
          print('⚠️ Hero Carousel: Post $postId has null or empty image_url, skipping');
        }
      }
      
      print('🖼️ Hero Carousel: Found ${items.length} approved posts with images');
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
          _currentIndex = 0;
          _lastLoadTime = DateTime.now(); // Update last load time
        });
        
        // Start auto-scroll if we have items, otherwise stop it
        if (_items.isNotEmpty) {
          _startAutoScroll();
        } else {
          _stopAutoScroll();
        }
      }
    } catch (e, stackTrace) {
      print('❌ Hero Carousel: Error loading items: $e');
      print('❌ Hero Carousel: Stack trace: $stackTrace');
      if (e.toString().contains('TimeoutException')) {
        print('⚠️  Connection timeout! Make sure:');
        print('   1. Backend is running on port 8002');
        print('   2. For physical devices, use: --dart-define=API_BASE=http://192.168.0.14:8002/api/v1');
        print('   3. Device and computer are on the same network');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _startAutoScroll() {
    _stopAutoScroll();
    
    // Auto-scroll timer - advance to next image every 5 seconds
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!_isUserInteracting && mounted && _items.isNotEmpty) {
        _goToNext();
      }
    });
  }

  void _stopAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  void _goToNext() {
    if (_items.isEmpty) return;
    
    final nextIndex = (_currentIndex + 1) % _items.length;
    _changePage(nextIndex);
  }

  void _goToPrevious() {
    if (_items.isEmpty) return;
    
    final prevIndex = (_currentIndex - 1 + _items.length) % _items.length;
    _changePage(prevIndex);
  }

  void _changePage(int index) {
    if (index < 0 || index >= _items.length) return;
    
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
    }

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    
    // Restart auto-scroll if not user interacting
    if (!_isUserInteracting) {
      _startAutoScroll();
    }
  }

  void _onPageChanged(int index) {
    if (index == _currentIndex) return;
    _changePage(index);
  }


  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = PlatformHelper.isWebPlatform();
    
    // Calculate responsive height based on device type
    final double carouselHeight = widget.height ?? ResponsiveUtils.getResponsiveValue<double>(
      context: context,
      mobile: 250.0, // Fixed height for mobile (better touch experience)
      tablet: screenHeight * 0.35, // 35% for tablet
      desktop: screenHeight * 0.5, // 50% for desktop (increased from 30%)
    );
    
    // Show arrows on all screen sizes when there's more than 1 item
    final showArrows = _items.length > 1;
    
    if (_isLoading) {
      return Container(
        height: carouselHeight,
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }
    
    if (_items.isEmpty) {
      return Container(
        height: carouselHeight,
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No featured posts available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Community posts with images will appear here',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SizedBox(
      height: carouselHeight,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Image Carousel
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollStartNotification) {
                  _isUserInteracting = true;
                  _stopAutoScroll();
                } else if (notification is ScrollEndNotification) {
                  Future.delayed(const Duration(milliseconds: 1000), () {
                    if (mounted) {
                      _isUserInteracting = false;
                      _startAutoScroll();
                    }
                  });
                }
                return false;
              },
              child: SizedBox(
                height: carouselHeight,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  physics: isWeb
                      ? const PageScrollPhysics()
                      : const BouncingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    return _buildCarouselItem(index, carouselHeight);
                  },
                ),
              ),
            ),
          ),
          
          // Carousel Indicators - IgnorePointer to allow clicks through
          Positioned(
            top: carouselHeight - 16,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: _buildIndicators(),
            ),
          ),
          
          // Navigation Arrows (only for desktop)
          if (showArrows)
            ..._buildNavigationArrows(carouselHeight),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(int index, double height) {
    if (index >= _items.length) return const SizedBox();
    
    final item = _items[index];
    
    // Build image widget with error handling using CachedNetworkImage
    // This prevents re-loading images and improves performance
    // Optimize cache size based on screen size for better memory usage
    final screenWidth = MediaQuery.of(context).size.width;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // Use smaller cache size on mobile to save memory
    final cacheWidth = isMobile
        ? (screenWidth * devicePixelRatio * 0.8).round() // 80% on mobile
        : (screenWidth * devicePixelRatio).round();
    final cacheHeight = (height * devicePixelRatio).round();
    
    Widget content = CachedNetworkImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      errorWidget: (context, url, error) {
        // Only log error once per image URL
        if (!_loadedImages.contains('error:$url')) {
          print('❌ Hero Carousel: Error loading image $url: $error');
          _loadedImages.add('error:$url');
        }
        return Container(
          height: height,
          color: Colors.black,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.image_not_supported, color: Colors.white70, size: 64),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  url,
                  style: TextStyle(color: Colors.white38, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
      placeholder: (context, url) {
        return Container(
          height: height,
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        );
      },
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
    
    // Track successful image loads (only log once per image)
    if (!_loadedImages.contains(item.imageUrl)) {
      // Use a post-frame callback to log after image is actually displayed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_loadedImages.contains(item.imageUrl)) {
          _loadedImages.add(item.imageUrl);
          // Only log once per image to reduce console spam
          // Commented out to reduce logging - uncomment if needed for debugging
          // print('✅ Hero Carousel: Image loaded: ${item.imageUrl}');
        }
      });
    }
    
    // Wrap content with tap handling - works for both web and mobile
    // Use Stack with Positioned.fill for reliable click detection on web
    if (widget.onItemTap != null) {
      return Stack(
        children: [
          // Image content
          content,
          // Invisible clickable overlay that doesn't interfere with scroll
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  print('🖼️ Hero Carousel: Tapped on post ${item.postId}');
                  widget.onItemTap!(item.postId);
                },
                splashColor: Colors.white.withOpacity(0.1),
                highlightColor: Colors.transparent,
                hoverColor: Colors.white.withOpacity(0.05),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    return content;
  }

  Widget _buildContentOverlay(_CarouselItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        if (item.title != null)
          Text(
            item.title!,
            style: AppTypography.body.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
              shadows: [
                const Shadow(
                  offset: Offset(0, 2),
                  blurRadius: 4,
                  color: Colors.black87,
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  Widget _buildIndicators() {
    if (_items.length <= 1) return const SizedBox();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_items.length, (index) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentIndex == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentIndex == index 
                ? Colors.white 
                : Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  List<Widget> _buildNavigationArrows(double height) {
    // Responsive arrow size - smaller on mobile
    final isMobile = ResponsiveUtils.isMobile(context);
    final arrowSize = isMobile ? 16.0 : 20.0;
    final arrowPadding = isMobile ? 6.0 : 8.0;
    final arrowMargin = isMobile ? 8.0 : 16.0;
    final buttonRadius = isMobile ? 14.0 : 20.0;

    return [
      // Left Arrow
      Positioned(
        left: arrowMargin,
        top: height / 2 - buttonRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToPrevious,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Container(
              padding: EdgeInsets.all(arrowPadding),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back_ios, color: Colors.white, size: arrowSize),
            ),
          ),
        ),
      ),
      // Right Arrow
      Positioned(
        right: arrowMargin,
        top: height / 2 - buttonRadius,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToNext,
            borderRadius: BorderRadius.circular(buttonRadius),
            child: Container(
              padding: EdgeInsets.all(arrowPadding),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: arrowSize),
            ),
          ),
        ),
      ),
    ];
  }
}
