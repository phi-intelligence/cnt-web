import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// Spacing system matching the React Native mobile app exactly
/// 8px grid system for consistent spacing
class AppSpacing {
  AppSpacing._();

  // Spacing values (all in logical pixels, matching 8px grid)
  static const double tiny = 4.0;
  static const double extraSmall = 8.0;
  static const double small = 12.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  static const double xxl = 48.0;
  static const double xxxl = 64.0;

  // Common spacing shortcuts
  static const EdgeInsets allTiny = EdgeInsets.all(tiny);
  static const EdgeInsets allExtraSmall = EdgeInsets.all(extraSmall);
  static const EdgeInsets allSmall = EdgeInsets.all(small);
  static const EdgeInsets allMedium = EdgeInsets.all(medium);
  static const EdgeInsets allLarge = EdgeInsets.all(large);
  static const EdgeInsets allExtraLarge = EdgeInsets.all(extraLarge);

  static const EdgeInsets horizontalSmall = EdgeInsets.symmetric(horizontal: small);
  static const EdgeInsets horizontalMedium = EdgeInsets.symmetric(horizontal: medium);
  static const EdgeInsets horizontalLarge = EdgeInsets.symmetric(horizontal: large);
  static const EdgeInsets horizontalExtraLarge = EdgeInsets.symmetric(horizontal: extraLarge);

  static const EdgeInsets verticalSmall = EdgeInsets.symmetric(vertical: small);
  static const EdgeInsets verticalMedium = EdgeInsets.symmetric(vertical: medium);
  static const EdgeInsets verticalLarge = EdgeInsets.symmetric(vertical: large);
  static const EdgeInsets verticalExtraLarge = EdgeInsets.symmetric(vertical: extraLarge);

  // Border radius (matching React Native)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusFull = 9999.0; // Circular

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;
  static const double iconSizeXXLarge = 64.0;

  // Touch target sizes (minimum for accessibility)
  static const double minTouchTarget = 44.0;

  // Voice bubble specific
  static const double voiceBubbleSize = 100.0;
  static const double voiceBubbleBorderRadius = 50.0; // Circular
  static const double voiceBubbleIconSize = 32.0;
  static const double soundbarWidth = 4.0;
  static const double soundbarGap = 3.0;
  static const double soundbarBorderRadius = 2.0;

  // Vinyl disc dimensions (relative calculations will be in widget)
  static const double vinylDiscMinSize = 200.0;
  static const double vinylCenterLabelRatio = 0.3; // 30% of disc size
  static const double vinylCenterHoleRatio = 0.08; // 8% of disc size
  static const double vinylGrooveSpacing = 15.0;
  static const double vinylGrooveBorderWidth = 1.0;
  static const double vinylOuterBorderWidth = 3.0;

  // Bottom tab bar (matching React Native)
  static const double bottomTabBarHeightIOS = 85.0;
  static const double bottomTabBarHeightAndroid = 60.0;
  static const double bottomTabBarPaddingTopIOS = 8.0;
  static const double bottomTabBarPaddingTopAndroid = 8.0;
  static const double bottomTabBarPaddingBottomIOS = 20.0;
  static const double bottomTabBarPaddingBottomAndroid = 8.0;

  // ============================================================================
  // RESPONSIVE SPACING METHODS
  // These methods return spacing values scaled based on device type
  // Scale factors: Mobile 0.75x, Tablet 0.85x, Desktop 1.0x, Large Desktop 1.1x
  // ============================================================================

  /// Get responsive padding value based on base size
  static double getResponsivePadding(BuildContext context, double baseSize) {
    final scale = ResponsiveUtils.getSpacingScale(context);
    return baseSize * scale;
  }

  /// Get responsive margin value based on base size
  static double getResponsiveMargin(BuildContext context, double baseSize) {
    final scale = ResponsiveUtils.getSpacingScale(context);
    return baseSize * scale;
  }

  /// Get responsive EdgeInsets with all sides equal
  static EdgeInsets getResponsiveAll(BuildContext context, double baseSize) {
    final scaled = getResponsivePadding(context, baseSize);
    return EdgeInsets.all(scaled);
  }

  /// Get responsive horizontal EdgeInsets
  static EdgeInsets getResponsiveHorizontal(BuildContext context, double baseSize) {
    final scaled = getResponsivePadding(context, baseSize);
    return EdgeInsets.symmetric(horizontal: scaled);
  }

  /// Get responsive vertical EdgeInsets
  static EdgeInsets getResponsiveVertical(BuildContext context, double baseSize) {
    final scaled = getResponsivePadding(context, baseSize);
    return EdgeInsets.symmetric(vertical: scaled);
  }

  /// Get responsive symmetric EdgeInsets
  static EdgeInsets getResponsiveSymmetric(
    BuildContext context, {
    double horizontal = 0,
    double vertical = 0,
  }) {
    final scale = ResponsiveUtils.getSpacingScale(context);
    return EdgeInsets.symmetric(
      horizontal: horizontal * scale,
      vertical: vertical * scale,
    );
  }

  /// Get responsive EdgeInsets with different values for each side
  static EdgeInsets getResponsiveOnly(
    BuildContext context, {
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
  }) {
    final scale = ResponsiveUtils.getSpacingScale(context);
    return EdgeInsets.only(
      left: left * scale,
      top: top * scale,
      right: right * scale,
      bottom: bottom * scale,
    );
  }

  /// Get responsive page padding (horizontal)
  static EdgeInsets getResponsivePagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getPageHorizontalPadding(context),
      vertical: ResponsiveUtils.getPageVerticalPadding(context),
    );
  }

  /// Get responsive content padding (horizontal only)
  static EdgeInsets getResponsiveContentPadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: ResponsiveUtils.getPageHorizontalPadding(context),
    );
  }

  /// Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context, double baseRadius) {
    final scale = ResponsiveUtils.getSpacingScale(context);
    return baseRadius * scale;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    return ResponsiveUtils.getResponsiveIconSize(context, baseSize);
  }

  /// Get responsive touch target size (minimum 44px on mobile)
  static double getResponsiveTouchTarget(BuildContext context) {
    return ResponsiveUtils.getResponsiveButtonHeight(context);
  }

  // Predefined responsive spacing values
  
  /// Get responsive tiny spacing
  static double getResponsiveTiny(BuildContext context) {
    return getResponsivePadding(context, tiny);
  }

  /// Get responsive extra small spacing
  static double getResponsiveExtraSmall(BuildContext context) {
    return getResponsivePadding(context, extraSmall);
  }

  /// Get responsive small spacing
  static double getResponsiveSmall(BuildContext context) {
    return getResponsivePadding(context, small);
  }

  /// Get responsive medium spacing
  static double getResponsiveMedium(BuildContext context) {
    return getResponsivePadding(context, medium);
  }

  /// Get responsive large spacing
  static double getResponsiveLarge(BuildContext context) {
    return getResponsivePadding(context, large);
  }

  /// Get responsive extra large spacing
  static double getResponsiveExtraLarge(BuildContext context) {
    return getResponsivePadding(context, extraLarge);
  }

  /// Get responsive XXL spacing
  static double getResponsiveXXL(BuildContext context) {
    return getResponsivePadding(context, xxl);
  }

  /// Get responsive XXXL spacing
  static double getResponsiveXXXL(BuildContext context) {
    return getResponsivePadding(context, xxxl);
  }
}

