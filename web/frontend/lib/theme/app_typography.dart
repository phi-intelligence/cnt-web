import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/responsive_utils.dart';

/// Typography system matching the React Native mobile app exactly
/// Based on Inter font family and website typography
class AppTypography {
  AppTypography._();

  // Font families
  static const String fontSans = 'Inter';
  static const String fontSerif = 'Georgia';
  static const String fontMono = 'Menlo';

  // Font sizes (matching React Native)
  static const double fontSizeXS = 12;
  static const double fontSizeSM = 14;
  static const double fontSizeBase = 16;
  static const double fontSizeLG = 18;
  static const double fontSizeXL = 20;
  static const double fontSize2XL = 24;
  static const double fontSize3XL = 30;
  static const double fontSize4XL = 36;
  static const double fontSize5XL = 48;
  static const double fontSize6XL = 60;
  static const double fontSize7XL = 72;

  // Font weights (matching React Native)
  static const FontWeight fontWeightNormal = FontWeight.w400;
  static const FontWeight fontWeightMedium = FontWeight.w500;
  static const FontWeight fontWeightSemibold = FontWeight.w600;
  static const FontWeight fontWeightBold = FontWeight.w700;

  // Line heights (matching React Native)
  static const double lineHeightTight = 1.25;
  static const double lineHeightSnug = 1.375;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.625;
  static const double lineHeightLoose = 2.0;

  // Font fallbacks for when Inter fails to load
  static const List<String> _fontFallbacks = ['Roboto', 'Arial', 'sans-serif'];

  /// Safe wrapper for GoogleFonts.inter() with fallback handling
  /// Prevents CanvasKit errors when Inter font fails to load
  static TextStyle _safeInter({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
  }) {
    try {
      // Get TextStyle from GoogleFonts and add fallback fonts
      return GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      ).copyWith(
        fontFamilyFallback: _fontFallbacks,
      );
    } catch (e) {
      // Fallback to system fonts if Google Fonts fails
      // This prevents CanvasKit "Aborted()" errors
      return TextStyle(
        fontFamily: 'Roboto',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
        fontFamilyFallback: ['Arial', 'sans-serif'],
      );
    }
  }

  // Text styles for common use cases
  static TextStyle get heroTitle => _safeInter(
        fontSize: fontSize4XL,
        fontWeight: fontWeightBold,
        height: lineHeightTight,
      );

  static TextStyle get heading1 => _safeInter(
        fontSize: fontSize3XL,
        fontWeight: fontWeightBold,
        height: lineHeightTight,
      );

  static TextStyle get heading2 => _safeInter(
        fontSize: fontSize2XL,
        fontWeight: fontWeightBold,
        height: lineHeightTight,
      );

  static TextStyle get heading3 => _safeInter(
        fontSize: fontSizeXL,
        fontWeight: fontWeightSemibold,
        height: lineHeightSnug,
      );

  static TextStyle get heading4 => _safeInter(
        fontSize: fontSizeLG,
        fontWeight: fontWeightSemibold,
        height: lineHeightNormal,
      );

  static TextStyle get body => _safeInter(
        fontSize: fontSizeBase,
        fontWeight: fontWeightNormal,
        height: lineHeightNormal,
      );

  static TextStyle get bodyMedium => _safeInter(
        fontSize: fontSizeBase,
        fontWeight: fontWeightMedium,
        height: lineHeightNormal,
      );

  static TextStyle get bodySmall => _safeInter(
        fontSize: fontSizeSM,
        fontWeight: fontWeightNormal,
        height: lineHeightNormal,
      );

  static TextStyle get caption => _safeInter(
        fontSize: fontSizeXS,
        fontWeight: fontWeightNormal,
        height: lineHeightNormal,
      );

  static TextStyle get button => _safeInter(
        fontSize: fontSizeBase,
        fontWeight: fontWeightSemibold,
        height: lineHeightNormal,
        letterSpacing: 0.5,
      );

  static TextStyle get label => _safeInter(
        fontSize: fontSizeSM,
        fontWeight: fontWeightMedium,
        height: lineHeightNormal,
      );

  // ============================================================================
  // RESPONSIVE TEXT STYLES
  // These methods return text styles scaled based on device type
  // Scale factors: Mobile 0.85x, Tablet 0.95x, Desktop 1.0x, Large Desktop 1.05x
  // ============================================================================

  static TextStyle getResponsiveHeroTitle(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSize4XL * scale,
      fontWeight: fontWeightBold,
      height: lineHeightTight,
    );
  }

  static TextStyle getResponsiveHeading1(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSize3XL * scale,
      fontWeight: fontWeightBold,
      height: lineHeightTight,
    );
  }

  static TextStyle getResponsiveHeading2(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSize2XL * scale,
      fontWeight: fontWeightBold,
      height: lineHeightTight,
    );
  }

  static TextStyle getResponsiveHeading3(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeXL * scale,
      fontWeight: fontWeightSemibold,
      height: lineHeightSnug,
    );
  }

  static TextStyle getResponsiveHeading4(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeLG * scale,
      fontWeight: fontWeightSemibold,
      height: lineHeightNormal,
    );
  }

  static TextStyle getResponsiveBody(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeBase * scale,
      fontWeight: fontWeightNormal,
      height: lineHeightNormal,
    );
  }

  static TextStyle getResponsiveBodyMedium(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeBase * scale,
      fontWeight: fontWeightMedium,
      height: lineHeightNormal,
    );
  }

  static TextStyle getResponsiveBodySmall(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeSM * scale,
      fontWeight: fontWeightNormal,
      height: lineHeightNormal,
    );
  }

  static TextStyle getResponsiveCaption(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeXS * scale,
      fontWeight: fontWeightNormal,
      height: lineHeightNormal,
    );
  }

  static TextStyle getResponsiveButton(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeBase * scale,
      fontWeight: fontWeightSemibold,
      height: lineHeightNormal,
      letterSpacing: 0.5,
    );
  }

  static TextStyle getResponsiveLabel(BuildContext context) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return _safeInter(
      fontSize: fontSizeSM * scale,
      fontWeight: fontWeightMedium,
      height: lineHeightNormal,
    );
  }

  /// Get scaled font size based on device type
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final scale = ResponsiveUtils.getFontSizeScale(context);
    return baseSize * scale;
  }
}

