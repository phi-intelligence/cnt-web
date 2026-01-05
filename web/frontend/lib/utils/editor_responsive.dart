import 'package:flutter/material.dart';

/// Responsive utilities for editor screens (video/audio)
class EditorResponsive {
  // Screen breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;
  
  // Check device type
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  // Video preview sizing
  static double getVideoPreviewHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 200; // Mobile: Compact preview
    } else if (screenWidth < 1024) {
      return 300; // Tablet: Medium preview
    } else if (screenWidth < 1440) {
      return 400; // Desktop: Large preview
    }
    return 500; // Large desktop: Extra large preview
  }
  
  // Timeline sizing
  static double getTimelineHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 120; // Mobile: Compact timeline
    } else if (screenWidth < 1024) {
      return 160; // Tablet: Medium timeline
    }
    return 200; // Desktop: Full timeline
  }
  
  // Control panel sizing
  static double getControlPanelHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 80; // Mobile: Compact controls
    } else if (screenWidth < 1024) {
      return 100; // Tablet: Medium controls
    }
    return 120; // Desktop: Full controls
  }
  
  // Track height in timeline
  static double getTrackHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 30; // Mobile: Compact tracks
    } else if (screenWidth < 1024) {
      return 40; // Tablet: Medium tracks
    }
    return 50; // Desktop: Full tracks
  }
  
  // Button sizing
  static double getPlayButtonSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 40; // Mobile: Small play button
    } else if (screenWidth < 1024) {
      return 48; // Tablet: Medium play button
    }
    return 56; // Desktop: Large play button
  }
  
  static double getIconButtonSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 32; // Mobile: Small icon buttons
    } else if (screenWidth < 1024) {
      return 40; // Tablet: Medium icon buttons
    }
    return 48; // Desktop: Large icon buttons
  }
  
  // Text sizing
  static double getControlTextSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 12; // Mobile: Small text
    } else if (screenWidth < 1024) {
      return 14; // Tablet: Medium text
    }
    return 16; // Desktop: Large text
  }
  
  // Padding and spacing
  static EdgeInsets getScreenPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.all(8); // Mobile: Minimal padding
    } else if (screenWidth < 1024) {
      return const EdgeInsets.all(16); // Tablet: Medium padding
    }
    return const EdgeInsets.all(24); // Desktop: Large padding
  }
  
  static EdgeInsets getSectionPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const EdgeInsets.symmetric(horizontal: 8, vertical: 4); // Mobile
    } else if (screenWidth < 1024) {
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 8); // Tablet
    }
    return const EdgeInsets.symmetric(horizontal: 24, vertical: 12); // Desktop
  }
  
  // Layout configuration
  static int getCrossAxisCountForTools(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 2; // Mobile: 2 columns
    } else if (screenWidth < 1024) {
      return 3; // Tablet: 3 columns
    }
    return 4; // Desktop: 4 columns
  }
  
  // Modal sizing
  static double getModalHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return screenHeight * 0.9; // Mobile: Almost full screen
    } else if (screenHeight < 1024) {
      return screenHeight * 0.8; // Tablet: 80% screen
    }
    return screenHeight * 0.7; // Desktop: 70% screen
  }
  
  // Waveform/spectrum sizing
  static double getWaveformHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 60; // Mobile: Compact waveform
    } else if (screenWidth < 1024) {
      return 80; // Tablet: Medium waveform
    }
    return 100; // Desktop: Full waveform
  }
  
  // Slider dimensions
  static double getSliderTrackHeight(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 4; // Mobile: Thin track
    } else if (screenWidth < 1024) {
      return 6; // Tablet: Medium track
    }
    return 8; // Desktop: Thick track
  }
  
  static double getSliderThumbRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return 8; // Mobile: Small thumb
    } else if (screenWidth < 1024) {
      return 10; // Tablet: Medium thumb
    }
    return 12; // Desktop: Large thumb
  }
}
