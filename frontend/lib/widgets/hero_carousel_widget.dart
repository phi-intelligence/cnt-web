import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import '../theme/app_typography.dart';
import '../utils/platform_helper.dart';

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
  State<HeroCarouselWidget> createState() => _HeroCarouselWidgetState();
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

class _HeroCarouselWidgetState extends State<HeroCarouselWidget> with AutomaticKeepAliveClientMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  List<_CarouselItem> _items = [];
  bool _isLoading = true;
  Timer? _autoScrollTimer;
  bool _isUserInteracting = false;
  final Set<String> _loadedImages = {}; // Track loaded images to prevent duplicate logging
  
  @override
  bool get wantKeepAlive => true; // Keep widget alive to prevent unnecessary rebuilds

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      print('🖼️ Hero Carousel: Fetching approved community posts with images...');
      final apiService = ApiService();
      
      // Fetch latest approved community posts (backend filters by approved_only=true and image_url)
      final posts = await apiService.getCommunityPosts(
        limit: 20,
        approvedOnly: true,  // Only show approved posts
      );
      print('🖼️ Hero Carousel: Fetched ${posts.length} approved community posts');
      
      // Convert posts to carousel items (backend already filters by image_url)
      final items = <_CarouselItem>[];
      for (final post in posts) {
        final imageUrl = post['image_url'] as String?;
        final postId = post['id'] as int;
        final isApproved = post['is_approved'] ?? false;
        final postType = post['post_type'] as String? ?? 'image';
        
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
        });
        
        // Start auto-scroll if we have items
        if (_items.isNotEmpty) {
          _startAutoScroll();
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

  void _onTap() {
    if (_currentIndex < _items.length && widget.onItemTap != null) {
      widget.onItemTap!(_items[_currentIndex].postId);
    }
  }

  @override
  void dispose() {
    _stopAutoScroll();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final screenHeight = MediaQuery.of(context).size.height;
    final isWeb = PlatformHelper.isWebPlatform();
    
    // Calculate height (mobile: 20% of screen, web: 30%)
    final carouselHeight = widget.height ?? 
        (isWeb ? screenHeight * 0.3 : screenHeight * 0.2);
    
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
        color: Colors.black,
        child: const Center(
          child: Text(
            'No posts with images available',
            style: TextStyle(color: Colors.white),
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
              child: GestureDetector(
                onTap: _onTap,
                behavior: isWeb ? HitTestBehavior.opaque : HitTestBehavior.deferToChild,
                onPanDown: (_) {
                  _isUserInteracting = true;
                  _stopAutoScroll();
                },
                onPanEnd: (_) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      _isUserInteracting = false;
                      _startAutoScroll();
                    }
                  });
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
          ),
          
          // Gradient Overlay (bottom)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: carouselHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: carouselHeight * 0.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Title Overlay
          if (_currentIndex < _items.length && _items[_currentIndex].title != null)
            Positioned(
              top: carouselHeight - 100,
              left: 16,
              right: 16,
              child: _buildContentOverlay(_items[_currentIndex]),
            ),
          
          // Carousel Indicators
          Positioned(
            top: carouselHeight - 16,
            left: 0,
            right: 0,
            child: _buildIndicators(),
          ),
          
          // Navigation Arrows (optional, for web)
          if (isWeb && _items.length > 1)
            ..._buildNavigationArrows(carouselHeight),
        ],
      ),
    );
  }

  Widget _buildCarouselItem(int index, double height) {
    if (index >= _items.length) return const SizedBox();
    
    final item = _items[index];
    final isWeb = PlatformHelper.isWebPlatform();
    
    // Build image widget with error handling using CachedNetworkImage
    // This prevents re-loading images and improves performance
    Widget content = CachedNetworkImage(
      imageUrl: item.imageUrl,
      fit: BoxFit.cover,
      height: height,
      width: double.infinity,
      memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
      memCacheHeight: (height * MediaQuery.of(context).devicePixelRatio).round(),
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
    
    // For web, wrap content in InkWell for better tap detection
    if (isWeb && widget.onItemTap != null) {
      return InkWell(
        onTap: () {
          if (index == _currentIndex && widget.onItemTap != null) {
            widget.onItemTap!(_items[index].postId);
          }
        },
        child: content,
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
    return [
      // Left Arrow
      Positioned(
        left: 16,
        top: height / 2 - 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToPrevious,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
      // Right Arrow
      Positioned(
        right: 16,
        top: height / 2 - 20,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _goToNext,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    ];
  }
}
