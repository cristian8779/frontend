// banner_styles.dart
import 'package:flutter/material.dart';

class BannerTheme {
  static const Color primaryColor = Color(0xFFBE0C0C);
  static const Color textColor = Colors.white;
  static const Color subtextColor = Colors.white70;
  static const Color shadowColor = Colors.black;
  static const Color errorBackgroundColor = Colors.white;
  
  static const double shadowOpacity = 0.1;
  static const double shadowBlurRadius = 8.0;
  static const Offset shadowOffset = Offset(0, 2);
  
  static const double textHeight = 1.4;
  static const double tabletLetterSpacing = 0.5;
  
  static const IconData fallbackIcon = Icons.dashboard_outlined;
}

class BannerDimensions {
  // Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double smallMobileBreakpoint = 360.0;
  
  // Padding
  static double getHorizontalPadding(double maxWidth) {
    if (maxWidth > tabletBreakpoint) return 32.0;
    if (maxWidth > mobileBreakpoint) return 24.0;
    return 16.0;
  }
  
  static double getVerticalPadding(double maxWidth) {
    if (maxWidth > tabletBreakpoint) return 24.0;
    if (maxWidth > mobileBreakpoint) return 20.0;
    return 16.0;
  }
  
  // Border radius
  static double getBorderRadius(double maxWidth) {
    return maxWidth > mobileBreakpoint ? 20.0 : 16.0;
  }
  
  // Typography
  static double getTitleFontSize(double maxWidth) {
    if (maxWidth > tabletBreakpoint) return 28.0;
    if (maxWidth > mobileBreakpoint) return 24.0;
    return 20.0;
  }
  
  static double getSubtitleFontSize(double maxWidth) {
    if (maxWidth > tabletBreakpoint) return 18.0;
    if (maxWidth > mobileBreakpoint) return 16.0;
    return 14.0;
  }
  
  // Spacing
  static double getTitleSpacing(double maxWidth) {
    return maxWidth > mobileBreakpoint ? 12.0 : 8.0;
  }
  
  static double getContentSpacing(double maxWidth) {
    return maxWidth > mobileBreakpoint ? 20.0 : 12.0;
  }
  
  // Image sizing
  static double getImageHeight(double maxWidth, Size screenSize) {
    if (maxWidth > tabletBreakpoint) return screenSize.height * 0.16;
    if (maxWidth > mobileBreakpoint) return screenSize.height * 0.14;
    return screenSize.height * 0.12;
  }
  
  // Layout checks
  static bool isTablet(double maxWidth) => maxWidth > mobileBreakpoint;
  static bool isLargeTablet(double maxWidth) => maxWidth > tabletBreakpoint;
  static bool isMobile(double maxWidth) => maxWidth <= mobileBreakpoint;
  static bool useVerticalLayout(double maxWidth) => 
      isMobile(maxWidth) && maxWidth < smallMobileBreakpoint;
}

class BannerTextStyles {
  static TextStyle getTitleStyle(double maxWidth) {
    final fontSize = BannerDimensions.getTitleFontSize(maxWidth);
    final isTablet = BannerDimensions.isTablet(maxWidth);
    
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: BannerTheme.textColor,
      letterSpacing: isTablet ? BannerTheme.tabletLetterSpacing : 0,
    );
  }
  
  static TextStyle getSubtitleStyle(double maxWidth) {
    final fontSize = BannerDimensions.getSubtitleFontSize(maxWidth);
    
    return TextStyle(
      color: BannerTheme.subtextColor,
      fontSize: fontSize,
      height: BannerTheme.textHeight,
    );
  }
}

class BannerDecorations {
  static BoxDecoration getContainerDecoration(double maxWidth) {
    final borderRadius = BannerDimensions.getBorderRadius(maxWidth);
    final isTablet = BannerDimensions.isTablet(maxWidth);
    
    return BoxDecoration(
      color: BannerTheme.primaryColor,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: isTablet ? [
        BoxShadow(
          color: BannerTheme.shadowColor.withOpacity(BannerTheme.shadowOpacity),
          blurRadius: BannerTheme.shadowBlurRadius,
          offset: BannerTheme.shadowOffset,
        ),
      ] : null,
    );
  }
  
  static BoxDecoration getErrorContainerDecoration() {
    return BoxDecoration(
      color: BannerTheme.errorBackgroundColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
    );
  }
}