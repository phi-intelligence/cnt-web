import 'package:flutter/material.dart';

/// Comprehensive responsive utilities for the CNT Media Platform
/// Provides device type detection, breakpoint management, and responsive value selection
class ResponsiveUtils {
  ResponsiveUtils._();

  // Breakpoint constants
  static const double smallMobileBreakpoint = 375.0; // iPhone SE, older Androids
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 1024.0;
  static const double laptopBreakpoint = 1440.0;
  static const double desktopBreakpoint = 1920.0;

  /// Get the current device type based on screen width
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < smallMobileBreakpoint) {
      return DeviceType.smallMobile;
    } else if (width < mobileBreakpoint) {
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
    
    if (width < smallMobileBreakpoint) {
      return Breakpoint.smallMobile;
    } else if (width < mobileBreakpoint) {
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

  /// Check if current device is small mobile
  static bool isSmallMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < smallMobileBreakpoint;
  }

  /// Check if current device is mobile (includes smallMobile)
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if current device is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  /// Check if current device is laptop
  static bool isLaptop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= tabletBreakpoint && width < laptopBreakpoint;
  }

  /// Check if current device is desktop
  static bool isDesktop(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= laptopBreakpoint && width < desktopBreakpoint;
  }

  /// Check if current device is large desktop
  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Check if current device is desktop or larger
  static bool isDesktopOrLarger(BuildContext context) {
    return MediaQuery.of(context).size.width >= laptopBreakpoint;
  }

  /// Check if current device is tablet or smaller
  static bool isTabletOrSmaller(BuildContext context) {
    return MediaQuery.of(context).size.width < tabletBreakpoint;
  }

  /// Get screen width
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  /// Get screen height
  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  /// Check if orientation is portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  /// Check if orientation is landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  /// Get responsive font size scaling factor
  static double getFontSizeScale(BuildContext context) {
    final deviceType = getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.smallMobile:
        return 0.75;
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
      case DeviceType.smallMobile:
        return 0.6; // 40% reduction for very small screens
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

  /// Get a value based on the current breakpoint
  static T getResponsiveValue<T>({
    required BuildContext context,
    required T mobile,
    T? tablet,
    T? laptop,
    T? desktop,
    T? largeDesktop,
  }) {
    final breakpoint = getBreakpoint(context);
    switch (breakpoint) {
      case Breakpoint.mobile:
      case Breakpoint.smallMobile:
        return mobile;
      case Breakpoint.tablet:
        return tablet ?? mobile;
      case Breakpoint.laptop:
        return laptop ?? desktop ?? tablet ?? mobile;
      case Breakpoint.desktop:
        return desktop ?? laptop ?? tablet ?? mobile;
      case Breakpoint.largeDesktop:
        return largeDesktop ?? desktop ?? tablet ?? mobile;
    }
  }

  /// Get a responsive padding/spacing value scaled by device type
  static double getResponsivePadding(BuildContext context, double baseValue) {
    return baseValue * getSpacingScale(context);
  }

  /// Get standard page horizontal padding value
  static double getPageHorizontalPadding(BuildContext context) {
    if (isSmallMobile(context)) return 16.0;
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 32.0;
    return 64.0;
  }

  /// Get standard page vertical padding value
  static double getPageVerticalPadding(BuildContext context) {
    if (isSmallMobile(context)) return 16.0;
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 32.0;
    return 40.0;
  }

  /// Get responsive icon size
  static double getResponsiveIconSize(BuildContext context, [double? baseSize]) {
    final scale = getFontSizeScale(context);
    return (baseSize ?? 24.0) * scale;
  }

  /// Get responsive button height
  static double getResponsiveButtonHeight(BuildContext context) {
    return getResponsiveValue(
      context: context,
      mobile: 44.0,
      tablet: 48.0,
      desktop: 56.0,
    );
  }

  /// Get responsive maximum content width
  static double getResponsiveMaxWidth(BuildContext context) {
    return 1400.0;
  }
  
  /// Get responsive card width
  static double getResponsiveCardWidth(BuildContext context) {
    return getResponsiveValue(
        context: context,
        mobile: 300.0,
        tablet: 280.0,
        desktop: 320.0
    );
  }

  /// Simple responsive value getter (for backward compatibility)
  static T getResponsiveValueSimple<T>({
    required BuildContext context,
    required T mobile,
    required T tablet,
    required T desktop,
    T? laptop,
  }) {
    return getResponsiveValue(
      context: context,
      mobile: mobile,
      tablet: tablet,
      laptop: laptop,
      desktop: desktop,
    );
  }
}

/// Device type enumeration
enum DeviceType {
  smallMobile,
  mobile,
  tablet,
  laptop,
  desktop,
  largeDesktop,
}

/// Breakpoint enumeration
enum Breakpoint {
  smallMobile,
  mobile,
  tablet,
  laptop,
  desktop,
  largeDesktop,
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
