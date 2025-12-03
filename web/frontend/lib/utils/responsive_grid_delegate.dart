import 'package:flutter/material.dart';
import 'responsive_utils.dart';

/// Enhanced responsive grid delegate utility for web screens
/// Provides adaptive grid layouts based on screen width with support for all breakpoints
class ResponsiveGridDelegate {
  ResponsiveGridDelegate._();

  /// Get responsive grid delegate based on screen width with full breakpoint support
  /// 
  /// Parameters:
  /// - mobile: Number of columns for mobile (< 640px)
  /// - tablet: Number of columns for tablet (640px - 1024px)
  /// - laptop: Number of columns for laptop (1024px - 1440px) [optional, defaults to desktop]
  /// - desktop: Number of columns for desktop (1440px - 1920px)
  /// - largeDesktop: Number of columns for large desktop (> 1920px) [optional, defaults to desktop]
  /// - childAspectRatio: Aspect ratio of grid items (default 0.75)
  /// - crossAxisSpacing: Horizontal spacing between items
  /// - mainAxisSpacing: Vertical spacing between items
  static SliverGridDelegateWithFixedCrossAxisCount getResponsiveGridDelegate(
    BuildContext context, {
    required int mobile,
    required int tablet,
    int? laptop,
    required int desktop,
    int? largeDesktop,
    double? childAspectRatio,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
  }) {
    final crossAxisCount = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet,
      laptop: laptop,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );

    // Get responsive spacing
    final responsiveSpacing = ResponsiveUtils.getSpacingScale(context);
    final finalCrossSpacing = (crossAxisSpacing ?? 16.0) * responsiveSpacing;
    final finalMainSpacing = (mainAxisSpacing ?? 16.0) * responsiveSpacing;

    // Get responsive aspect ratio if not provided
    final finalAspectRatio = childAspectRatio ?? getResponsiveAspectRatio(context);

    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: finalAspectRatio,
      crossAxisSpacing: finalCrossSpacing,
      mainAxisSpacing: finalMainSpacing,
    );
  }

  /// Simplified version for common use cases (3 breakpoints)
  static SliverGridDelegateWithFixedCrossAxisCount getSimpleGridDelegate(
    BuildContext context, {
    required int mobile,
    required int tablet,
    required int desktop,
    double childAspectRatio = 0.75,
    double crossAxisSpacing = 16.0,
    double mainAxisSpacing = 16.0,
  }) {
    return getResponsiveGridDelegate(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  /// Get responsive grid columns count with full breakpoint support
  static int getGridColumns(
    BuildContext context, {
    required int mobile,
    required int tablet,
    int? laptop,
    required int desktop,
    int? largeDesktop,
  }) {
    return ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet,
      laptop: laptop,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
  }

  /// Get responsive aspect ratio for grid items
  static double getResponsiveAspectRatio(BuildContext context, {
    double baseRatio = 0.75,
  }) {
    return ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: baseRatio * 1.2, // Slightly taller cards on mobile
      tablet: baseRatio * 1.1,
      desktop: baseRatio,
    );
  }

  /// Get responsive gap spacing
  static double getResponsiveGap(BuildContext context, {
    double baseGap = 16.0,
  }) {
    return baseGap * ResponsiveUtils.getSpacingScale(context);
  }

  /// Get responsive padding based on screen size
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final padding = ResponsiveUtils.getPageHorizontalPadding(context);
    return EdgeInsets.all(padding);
  }

  /// Get responsive horizontal padding
  static double getResponsiveHorizontalPadding(BuildContext context) {
    return ResponsiveUtils.getPageHorizontalPadding(context);
  }

  /// Get responsive vertical padding
  static double getResponsiveVerticalPadding(BuildContext context) {
    return ResponsiveUtils.getPageVerticalPadding(context);
  }

  /// Get responsive max content width for centering content on large screens
  /// This prevents content from being too wide on large desktop screens
  static double getMaxContentWidth(BuildContext context) {
    return ResponsiveUtils.getResponsiveMaxWidth(context);
  }

  /// Get responsive max width for post cards / content cards
  /// Used for community posts, cards, etc.
  static double getMaxCardWidth(BuildContext context) {
    return ResponsiveUtils.getResponsiveCardWidth(context);
  }

  /// Get responsive card size for uniform cards
  static Size getResponsiveCardSize(BuildContext context, {
    double mobileWidth = 300,
    double tabletWidth = 350,
    double desktopWidth = 400,
    double aspectRatio = 0.75,
  }) {
    final width = ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobileWidth,
      tablet: tabletWidth,
      desktop: desktopWidth,
    );
    
    return Size(width, width / aspectRatio);
  }

  /// Get responsive item extent for lists
  static double getResponsiveItemExtent(BuildContext context, {
    double mobileExtent = 80,
    double tabletExtent = 100,
    double desktopExtent = 120,
  }) {
    return ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: mobileExtent,
      tablet: tabletExtent,
      desktop: desktopExtent,
    );
  }

  /// Get responsive max width with constraints
  /// Useful for forms, modals, etc.
  static BoxConstraints getResponsiveConstraints(BuildContext context, {
    double? maxWidth,
  }) {
    final responsiveMaxWidth = maxWidth ?? getMaxContentWidth(context);
    
    return BoxConstraints(
      maxWidth: responsiveMaxWidth,
      minWidth: 0,
    );
  }

  /// Get responsive edge insets for content
  static EdgeInsets getContentPadding(BuildContext context) {
    final horizontal = ResponsiveUtils.getPageHorizontalPadding(context);
    final vertical = ResponsiveUtils.getPageVerticalPadding(context);
    
    return EdgeInsets.symmetric(
      horizontal: horizontal,
      vertical: vertical,
    );
  }

  /// Get responsive edge insets for cards
  static EdgeInsets getCardPadding(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: const EdgeInsets.all(12),
      tablet: const EdgeInsets.all(16),
      desktop: const EdgeInsets.all(20),
    );
  }

  /// Get responsive margin between sections
  static double getSectionMargin(BuildContext context) {
    return ResponsiveUtils.getResponsiveValue(
      context: context,
      mobile: 24.0,
      tablet: 32.0,
      desktop: 48.0,
    );
  }
}


