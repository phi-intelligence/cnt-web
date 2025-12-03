import 'package:flutter/material.dart';
import '../../models/content_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../web/content_card_web.dart';
import '../web/disc_card_web.dart';

class ContentSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Web-only deployment - always use web widgets
    if (useDiscDesign) {
      return _buildDiscDesignWeb(context);
    } else if (isHorizontal) {
      return _buildHorizontalWeb(context);
    } else {
      return _buildGridWeb(context);
    }
  }


  Widget _buildHorizontalWeb(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 280, // Increased height for better card visibility
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding for better scroll indication
            itemCount: items.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: 200, // Slightly wider for better web experience
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: _buildCard(context, items[index]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }


  Widget _buildDiscDesignWeb(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 250, // Height to accommodate disc + label (increased to prevent overflow)
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4.0), // Add padding for better scroll indication
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 24.0),
                child: DiscCardWeb(
                  item: items[index],
                  onTap: onItemTap != null ? () => onItemTap!(items[index]) : null,
                  onPlay: onItemPlay != null ? () => onItemPlay!(items[index]) : null,
                  size: 180.0,
                ),
              );
            },
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
              title,
              style: AppTypography.heading2.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (onViewAll != null)
              TextButton(
                onPressed: onViewAll,
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
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildCard(context, items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildCard(BuildContext context, ContentItem item) {
    // Web-only deployment - always use web widgets
    return ContentCardWeb(
      item: item,
      onTap: onItemTap != null ? () => onItemTap!(item) : null,
      onPlay: onItemPlay != null ? () => onItemPlay!(item) : null,
    );
  }
}

