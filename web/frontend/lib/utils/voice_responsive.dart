import 'package:flutter/material.dart';

/// Responsive design utilities for voicebot UI
class VoiceBreakpoints {
  static const double mobile = 480;      // < 480px
  static const double tablet = 768;      // 481px - 768px  
  static const double desktop = 1024;    // 769px - 1024px
  static const double largeDesktop = 1440; // > 1024px

  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width < mobile;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width >= mobile && 
      MediaQuery.of(context).size.width < desktop;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= desktop && 
      MediaQuery.of(context).size.width < largeDesktop;
  
  static bool isLargeDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width >= largeDesktop;
}

/// Responsive sizing utilities for voice components
class VoiceResponsiveSize {
  /// Get voice bubble size based on screen width
  static double getBubbleSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 480) return screenWidth * 0.6;      // Mobile: 60% width
    if (screenWidth < 768) return 160;                    // Tablet: Fixed 160px
    if (screenWidth < 1024) return 180;                   // Desktop: Fixed 180px
    return 200;                                            // Large: Fixed 200px
  }
  
  /// Get icon size based on bubble size
  static double getIconSize(BuildContext context) {
    final bubbleSize = getBubbleSize(context);
    if (VoiceBreakpoints.isMobile(context)) {
      return bubbleSize * 0.4;  // Mobile: Larger icon proportion
    }
    return bubbleSize * 0.35;    // Desktop: Standard proportion
  }
  
  /// Get touch target size (minimum 48px for accessibility)
  static double getTouchTargetSize(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) return 56;      // Mobile: Larger for thumbs
    return 48;                                              // Desktop: Standard
  }
  
  /// Get transcript height based on screen height
  static double getTranscriptHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) return 150;    // Small screens
    if (screenHeight < 800) return 200;    // Medium screens  
    return 250;                            // Large screens
  }
  
  /// Get padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) {
      return const EdgeInsets.all(16);
    } else if (VoiceBreakpoints.isTablet(context)) {
      return const EdgeInsets.all(24);
    } else {
      return const EdgeInsets.all(32);
    }
  }
  
  /// Get spacing multiplier based on screen size
  static double getSpacingMultiplier(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) return 0.8;
    if (VoiceBreakpoints.isTablet(context)) return 1.0;
    return 1.2;
  }
}

/// Performance optimization utilities
class VoicePerformance {
  /// Get number of wave animations based on device performance
  static int getWaveCount(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) return 3;      // Mobile: Fewer waves
    return 4;                                              // Desktop: Full waves
  }
  
  /// Get animation duration based on device
  static Duration getAnimationDuration(BuildContext context) {
    if (VoiceBreakpoints.isMobile(context)) {
      return const Duration(milliseconds: 1500);           // Mobile: Faster
    }
    return const Duration(milliseconds: 2000);             // Desktop: Standard
  }
  
  /// Check if should enable complex animations
  static bool enableComplexAnimations(BuildContext context) {
    return !VoiceBreakpoints.isMobile(context);
  }
}
