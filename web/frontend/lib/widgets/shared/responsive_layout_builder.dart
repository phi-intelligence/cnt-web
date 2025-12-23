import 'package:flutter/material.dart';
import '../../utils/responsive_utils.dart';

/// Responsive layout builder widget
/// Simplifies responsive UI building with builder callbacks for different device types
class ResponsiveLayoutBuilder extends StatelessWidget {
  /// Builder for mobile devices (< 640px)
  final WidgetBuilder? mobileBuilder;
  
  /// Builder for tablet devices (640px - 1024px)
  final WidgetBuilder? tabletBuilder;
  
  /// Builder for laptop devices (1024px - 1440px)
  final WidgetBuilder? laptopBuilder;
  
  /// Builder for desktop devices (1440px - 1920px)
  final WidgetBuilder? desktopBuilder;
  
  /// Builder for large desktop devices (> 1920px)
  final WidgetBuilder? largeDesktopBuilder;
  
  /// Default builder (used if specific builder is not provided)
  final WidgetBuilder? defaultBuilder;

  const ResponsiveLayoutBuilder({
    super.key,
    this.mobileBuilder,
    this.tabletBuilder,
    this.laptopBuilder,
    this.desktopBuilder,
    this.largeDesktopBuilder,
    this.defaultBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = ResponsiveUtils.getDeviceType(context);
    
    switch (deviceType) {
      case DeviceType.smallMobile:
      case DeviceType.mobile:
        return (mobileBuilder ?? defaultBuilder ?? _fallbackBuilder)(context);
      case DeviceType.tablet:
        return (tabletBuilder ?? mobileBuilder ?? defaultBuilder ?? _fallbackBuilder)(context);
      case DeviceType.laptop:
        return (laptopBuilder ?? desktopBuilder ?? defaultBuilder ?? _fallbackBuilder)(context);
      case DeviceType.desktop:
        return (desktopBuilder ?? laptopBuilder ?? defaultBuilder ?? _fallbackBuilder)(context);
      case DeviceType.largeDesktop:
        return (largeDesktopBuilder ?? desktopBuilder ?? defaultBuilder ?? _fallbackBuilder)(context);
    }
  }

  Widget _fallbackBuilder(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Simplified responsive layout builder with just three breakpoints
class SimpleResponsiveLayoutBuilder extends StatelessWidget {
  /// Builder for mobile devices (< 640px)
  final WidgetBuilder mobile;
  
  /// Builder for tablet devices (640px - 1024px)
  final WidgetBuilder tablet;
  
  /// Builder for desktop devices (>= 1024px)
  final WidgetBuilder desktop;

  const SimpleResponsiveLayoutBuilder({
    super.key,
    required this.mobile,
    required this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isMobile(context)) {
      return mobile(context);
    } else if (ResponsiveUtils.isTablet(context)) {
      return tablet(context);
    } else {
      return desktop(context);
    }
  }
}

/// Responsive value builder - returns different values based on device type
class ResponsiveValue<T> extends StatelessWidget {
  final T mobile;
  final T? tablet;
  final T? laptop;
  final T desktop;
  final T? largeDesktop;
  final Widget Function(BuildContext context, T value) builder;

  const ResponsiveValue({
    super.key,
    required this.mobile,
    this.tablet,
    this.laptop,
    required this.desktop,
    this.largeDesktop,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final value = ResponsiveUtils.getResponsiveValue<T>(
      context: context,
      mobile: mobile,
      tablet: tablet,
      laptop: laptop,
      desktop: desktop,
      largeDesktop: largeDesktop,
    );
    
    return builder(context, value);
  }
}

/// Orientation-aware responsive builder
class OrientationResponsiveBuilder extends StatelessWidget {
  final WidgetBuilder portraitBuilder;
  final WidgetBuilder landscapeBuilder;

  const OrientationResponsiveBuilder({
    super.key,
    required this.portraitBuilder,
    required this.landscapeBuilder,
  });

  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isPortrait(context)) {
      return portraitBuilder(context);
    } else {
      return landscapeBuilder(context);
    }
  }
}

/// Responsive show/hide widget based on device type
class ResponsiveVisibility extends StatelessWidget {
  final Widget child;
  final bool showOnMobile;
  final bool showOnTablet;
  final bool showOnDesktop;
  final Widget? replacement;

  const ResponsiveVisibility({
    super.key,
    required this.child,
    this.showOnMobile = true,
    this.showOnTablet = true,
    this.showOnDesktop = true,
    this.replacement,
  });

  /// Show only on mobile
  const ResponsiveVisibility.mobileOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : showOnMobile = true,
        showOnTablet = false,
        showOnDesktop = false;

  /// Show only on tablet
  const ResponsiveVisibility.tabletOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : showOnMobile = false,
        showOnTablet = true,
        showOnDesktop = false;

  /// Show only on desktop
  const ResponsiveVisibility.desktopOnly({
    super.key,
    required this.child,
    this.replacement,
  })  : showOnMobile = false,
        showOnTablet = false,
        showOnDesktop = true;

  /// Hide on mobile
  const ResponsiveVisibility.hideMobile({
    super.key,
    required this.child,
    this.replacement,
  })  : showOnMobile = false,
        showOnTablet = true,
        showOnDesktop = true;

  /// Hide on desktop
  const ResponsiveVisibility.hideDesktop({
    super.key,
    required this.child,
    this.replacement,
  })  : showOnMobile = true,
        showOnTablet = true,
        showOnDesktop = false;

  @override
  Widget build(BuildContext context) {
    bool shouldShow = false;
    
    if (ResponsiveUtils.isMobile(context) && showOnMobile) {
      shouldShow = true;
    } else if (ResponsiveUtils.isTablet(context) && showOnTablet) {
      shouldShow = true;
    } else if (ResponsiveUtils.isDesktopOrLarger(context) && showOnDesktop) {
      shouldShow = true;
    }
    
    if (shouldShow) {
      return child;
    } else {
      return replacement ?? const SizedBox.shrink();
    }
  }
}

/// Responsive padding widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  final EdgeInsets? mobile;
  final EdgeInsets? tablet;
  final EdgeInsets? desktop;

  const ResponsivePadding({
    super.key,
    required this.child,
    this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Create responsive padding with multiplier
  factory ResponsivePadding.scaled({
    Key? key,
    required Widget child,
    required EdgeInsets basePadding,
    double mobileScale = 0.75,
    double tabletScale = 0.85,
    double desktopScale = 1.0,
  }) {
    return ResponsivePadding(
      key: key,
      mobile: basePadding * mobileScale,
      tablet: basePadding * tabletScale,
      desktop: basePadding * desktopScale,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = ResponsiveUtils.getResponsiveValueSimple(
      context: context,
      mobile: mobile ?? const EdgeInsets.all(16),
      tablet: tablet ?? const EdgeInsets.all(24),
      desktop: desktop ?? const EdgeInsets.all(32),
    );
    
    return Padding(
      padding: padding,
      child: child,
    );
  }
}

/// Responsive constrained box
class ResponsiveConstrainedBox extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final double? maxHeight;
  final bool centerHorizontally;

  const ResponsiveConstrainedBox({
    super.key,
    required this.child,
    this.maxWidth,
    this.maxHeight,
    this.centerHorizontally = true,
  });

  @override
  Widget build(BuildContext context) {
    final constraints = BoxConstraints(
      maxWidth: maxWidth ?? ResponsiveUtils.getResponsiveMaxWidth(context),
      maxHeight: maxHeight ?? double.infinity,
    );
    
    Widget constrained = ConstrainedBox(
      constraints: constraints,
      child: child,
    );
    
    if (centerHorizontally) {
      return Center(
        child: constrained,
      );
    }
    
    return constrained;
  }
}

/// Responsive flex layout (row/column based on device)
class ResponsiveFlex extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final bool useColumnOnMobile;
  final bool useColumnOnTablet;

  const ResponsiveFlex({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.useColumnOnMobile = true,
    this.useColumnOnTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool useColumn = (ResponsiveUtils.isMobile(context) && useColumnOnMobile) ||
                           (ResponsiveUtils.isTablet(context) && useColumnOnTablet);
    
    if (useColumn) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        children: children,
      );
    }
  }
}

/// Responsive grid with automatic column count
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  const ResponsiveGrid({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
  });

  @override
  Widget build(BuildContext context) {
    final int columns = ResponsiveUtils.getResponsiveValueSimple<int>(
      context: context,
      mobile: mobileColumns ?? 1,
      tablet: tabletColumns ?? 2,
      desktop: desktopColumns ?? 3,
    );
    
    final double gap = spacing ?? ResponsiveUtils.getResponsiveValue<double>(
      context: context,
      mobile: 12.0,
      tablet: 16.0,
      desktop: 20.0,
    );
    
    return Wrap(
      spacing: gap,
      runSpacing: runSpacing ?? gap,
      children: children.map((child) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - (gap * (columns + 1))) / columns,
          child: child,
        );
      }).toList(),
    );
  }
}

