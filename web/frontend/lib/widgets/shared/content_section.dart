import 'package:flutter/material.dart';
import '../../models/content_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../utils/responsive_utils.dart';
import '../web/content_card_web.dart';
import '../web/disc_card_web.dart';

class ContentSection extends StatefulWidget {
  final String title;
  final List<ContentItem> items;
  final VoidCallback? onViewAll;
  final bool isHorizontal;
  final bool useDiscDesign;
  final Function(ContentItem)? onItemTap;
  final Function(ContentItem)? onItemPlay;

  const ContentSection({
    super.key,
    required this.title,
    required this.items,
    this.onViewAll,
    this.isHorizontal = false,
    this.useDiscDesign = false,
    this.onItemTap,
    this.onItemPlay,
  });

  @override
  State<ContentSection> createState() => _ContentSectionState();
}

class _ContentSectionState extends State<ContentSection> {
  final ScrollController _scrollController = ScrollController();
  bool _canScrollLeft = false;
  bool _canScrollRight = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_updateScrollButtons);
    // Initial check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateScrollButtons();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollButtons);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollButtons() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    final newCanScrollLeft = position.pixels > 10;
    final newCanScrollRight = position.pixels < position.maxScrollExtent - 10;

    if (newCanScrollLeft != _canScrollLeft || newCanScrollRight != _canScrollRight) {
      setState(() {
        _canScrollLeft = newCanScrollLeft;
        _canScrollRight = newCanScrollRight;
      });
    }
  }

  void _scrollLeft() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final targetOffset = (currentOffset - 400).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    if (!_scrollController.hasClients) return;
    final currentOffset = _scrollController.offset;
    final targetOffset = (currentOffset + 400).clamp(0.0, _scrollController.position.maxScrollExtent);
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Web-only deployment - always use web widgets
    if (widget.useDiscDesign) {
      return _buildDiscDesignWeb(context);
    } else if (widget.isHorizontal) {
      return _buildHorizontalWeb(context);
    } else {
      return _buildGridWeb(context);
    }
  }

  Widget _buildScrollArrow({
    required IconData icon,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 640;
    final arrowSize = isMobile ? 16.0 : 20.0;
    final buttonSize = isMobile ? 32.0 : 40.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(buttonSize / 2),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: AppColors.warmBrown.withOpacity(0.9),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: arrowSize,
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalWeb(BuildContext context) {
    final contentHeight = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 220.0,
      tablet: 250.0,
      desktop: 280.0,
    );
    
    final cardWidth = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 150.0,
      tablet: 175.0,
      desktop: 200.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.onViewAll != null)
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              // Scrollable content
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Prevent horizontal scroll notifications from bubbling up to parent
                  // This prevents interference with hero carousel
                  return notification.metrics.axis == Axis.horizontal;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: cardWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16.0),
                        child: _buildCard(context, widget.items[index]),
                      ),
                    );
                  },
                ),
              ),
              // Left Arrow
              if (_canScrollLeft)
                Positioned(
                  left: 8,
                  top: contentHeight / 2 - 20,
                  child: _buildScrollArrow(
                    icon: Icons.arrow_back_ios,
                    onTap: _scrollLeft,
                    isLeft: true,
                  ),
                ),
              // Right Arrow
              if (_canScrollRight)
                Positioned(
                  right: 8,
                  top: contentHeight / 2 - 20,
                  child: _buildScrollArrow(
                    icon: Icons.arrow_forward_ios,
                    onTap: _scrollRight,
                    isLeft: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildDiscDesignWeb(BuildContext context) {
    final contentHeight = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 200.0,
      tablet: 230.0,
      desktop: 250.0,
    );
    
    final discSize = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 120.0,
      tablet: 150.0,
      desktop: 180.0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.onViewAll != null)
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: contentHeight,
          child: Stack(
            children: [
              // Scrollable content
              NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  // Prevent horizontal scroll notifications from bubbling up to parent
                  // This prevents interference with hero carousel
                  return notification.metrics.axis == Axis.horizontal;
                },
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  itemCount: widget.items.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 24.0),
                      child: DiscCardWeb(
                        item: widget.items[index],
                        onTap: widget.onItemTap != null ? () => widget.onItemTap!(widget.items[index]) : null,
                        onPlay: widget.onItemPlay != null ? () => widget.onItemPlay!(widget.items[index]) : null,
                        size: discSize,
                      ),
                    );
                  },
                ),
              ),
              // Left Arrow
              if (_canScrollLeft)
                Positioned(
                  left: 8,
                  top: contentHeight / 2 - 20,
                  child: _buildScrollArrow(
                    icon: Icons.arrow_back_ios,
                    onTap: _scrollLeft,
                    isLeft: true,
                  ),
                ),
              // Right Arrow
              if (_canScrollRight)
                Positioned(
                  right: 8,
                  top: contentHeight / 2 - 20,
                  child: _buildScrollArrow(
                    icon: Icons.arrow_forward_ios,
                    onTap: _scrollRight,
                    isLeft: false,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGridWeb(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (widget.onViewAll != null)
              TextButton(
                onPressed: widget.onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index) {
            return _buildCard(context, widget.items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ContentItem item) {
    // Web-only deployment - always use web widgets
    return ContentCardWeb(
      item: item,
      onTap: widget.onItemTap != null ? () => widget.onItemTap!(item) : null,
      onPlay: widget.onItemPlay != null ? () => widget.onItemPlay!(item) : null,
    );
  }
}
