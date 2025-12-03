import 'package:flutter/material.dart';

/// Comprehensive responsive utilities for the CNT Media Platform
/// Provides device type detection, breakpoint management, and responsive value selection
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoint constants
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 1024.0;
  static const double laptopBreakpoint = 1440.0;
  static const double desktopBreakpoint = 1920.0;

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return DeviceType.mobile;
    } else if (width < tabletBreakpoint) {
      return DeviceType.tablet;
    } else if (width < laptopBreakpoint) {
      return DeviceType.laptop;
    } else if (width < desktopBreakpoint) {
      return DeviceType.desktop;
    } else {
      return DeviceType.largeDesktop;
    }
  }

  /// Get the current breakpoint
  static Breakpoint getBreakpoint(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < mobileBreakpoint) {
      return Breakpoint.mobile;
    } else if (width < tabletBreakpoint) {
      return Breakpoint.tablet;
    } else if (width < laptopBreakpoint) {
      return Breakpoint.laptop;
    } else if (width < desktopBreakpoint) {
      return Breakpoint.desktop;
    } else {
      return Breakpoint.largeDesktop;
    }
  }

  /// Check if current device is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current device is laptop or larger
  static bool isLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < laptopBreakpoint;
  }

  /// Check if current device is desktop (not laptop, not large desktop)
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= laptopBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current device is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Check if current device is desktop or larger (laptop+)
  static bool isDesktopOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Check if current device is tablet or smaller
  static bool isTabletOrSmaller(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Get screen orientation
  static Orientation getOrientation(BuildContext context) {
    return MediaQuery.of(context).orientation;
  }

  /// Check if device is in portrait mode
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if device is in landscape mode
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get a responsive value based on device type
  /// Provide values for mobile, tablet, and desktop
  /// If laptop or largeDesktop values are not provided, they default to desktop
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? laptop,
    required T desktop,
    T? largeDesktop,
  }) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.laptop:
        return laptop ?? desktop;
      case DeviceType.desktop:
        return desktop;
      case DeviceType.largeDesktop:
        return largeDesktop ?? desktop;
    }
  }

  /// Get a responsive value based on breakpoint
  /// Simplified version with just three breakpoints
  static T getResponsiveValueSimple<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet;
    } else {
      return desktop;
    }
  }

  /// Get responsive font size scaling factor
  static double getFontSizeScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 0.85;
      case DeviceType.tablet:
        return 0.95;
      case DeviceType.laptop:
        return 1.0;
      case DeviceType.desktop:
        return 1.0;
      case DeviceType.largeDesktop:
        return 1.05;
    }
  }

  /// Get responsive spacing scaling factor
  static double getSpacingScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.mobile:
        return 0.75; // 25% reduction
      case DeviceType.tablet:
        return 0.85; // 15% reduction
      case DeviceType.laptop:
        return 1.0;
      case DeviceType.desktop:
        return 1.0;
      case DeviceType.largeDesktop:
        return 1.1; // 10% increase
    }
  }

  /// Get responsive padding value
  static double getResponsivePadding(BuildContext context, double baseValue) {
    return baseValue * getSpacingScale(context);
  }

  /// Get responsive margin value
  static double getResponsiveMargin(BuildContext context, double baseValue) {
    return baseValue * getSpacingScale(context);
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, double baseSize) {
    return getResponsiveValue(
      context: context,
      mobile: baseSize * 1.2, // Slightly larger on mobile for touch
      tablet: baseSize * 1.1,
      desktop: baseSize,
    );
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 48.0, // Minimum touch target
      tablet: 44.0,
      desktop: 40.0,
    );
  }

  /// Get responsive card width (for constrained layouts)
  static double getResponsiveCardWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity, // Full width on mobile
      tablet: 400.0,
      desktop: 450.0,
    );
  }

  /// Get responsive max content width (for centered content)
  static double getResponsiveMaxWidth(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: double.infinity,
      tablet: 800.0,
      laptop: 1200.0,
      desktop: 1400.0,
      largeDesktop: 1600.0,
    );
  }

  /// Get responsive horizontal padding for page content
  static double getPageHorizontalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 40.0,
      largeDesktop: 60.0,
    );
  }

  /// Get responsive vertical padding for page content
  static double getPageVerticalPadding(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 16.0,
      tablet: 24.0,
      desktop: 32.0,
    );
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Get safe area padding
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  /// Calculate responsive value with custom breakpoints
  static T getValueForBreakpoint<T>({
    required BuildContext context,
    required Map<Breakpoint, T> values,
    required T defaultValue,
  }) {
    final breakpoint = getBreakpoint(context);
    return values[breakpoint] ?? defaultValue;
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  laptop,
  desktop,
  largeDesktop,
}

/// Breakpoint enumeration
enum Breakpoint {
  mobile,    // < 640px
  tablet,    // 640px - 1024px
  laptop,    // 1024px - 1440px
  desktop,   // 1440px - 1920px
  largeDesktop, // > 1920px
}

/// Extension on BuildContext for convenient access to responsive utilities
extension ResponsiveContext on BuildContext {
  /// Check if mobile
  bool get isMobile => ResponsiveUtils.isMobile(this);
  
  /// Check if tablet
  bool get isTablet => ResponsiveUtils.isTablet(this);
  
  /// Check if laptop
  bool get isLaptop => ResponsiveUtils.isLaptop(this);
  
  /// Check if desktop
  bool get isDesktop => ResponsiveUtils.isDesktop(this);
  
  /// Check if large desktop
  bool get isLargeDesktop => ResponsiveUtils.isLargeDesktop(this);
  
  /// Check if desktop or larger
  bool get isDesktopOrLarger => ResponsiveUtils.isDesktopOrLarger(this);
  
  /// Check if tablet or smaller
  bool get isTabletOrSmaller => ResponsiveUtils.isTabletOrSmaller(this);
  
  /// Get device type
  DeviceType get deviceType => ResponsiveUtils.getDeviceType(this);
  
  /// Get breakpoint
  Breakpoint get breakpoint => ResponsiveUtils.getBreakpoint(this);
  
  /// Get screen width
  double get screenWidth => ResponsiveUtils.getScreenWidth(this);
  
  /// Get screen height
  double get screenHeight => ResponsiveUtils.getScreenHeight(this);
  
  /// Check if portrait
  bool get isPortrait => ResponsiveUtils.isPortrait(this);
  
  /// Check if landscape
  bool get isLandscape => ResponsiveUtils.isLandscape(this);
}



