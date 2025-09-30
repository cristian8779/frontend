import 'package:flutter/material.dart';

class ProfileDimensions {
  static const double _mobileBreakpoint = 600;
  static const double _tabletBreakpoint = 900;
  
  // Screen size helpers
  static bool isMobile(BuildContext context) => MediaQuery.of(context).size.width < _mobileBreakpoint;
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width >= _mobileBreakpoint && MediaQuery.of(context).size.width < _tabletBreakpoint;
  static bool isDesktop(BuildContext context) => MediaQuery.of(context).size.width >= _tabletBreakpoint;
  
  // Max widths
  static double getMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 700;
    if (isTablet(context)) return 600;
    return double.infinity;
  }
  
  // Paddings
  static EdgeInsets getHorizontalPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 48);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 16);
  }
  
  static EdgeInsets getContentPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }
  
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(28);
    if (isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(20);
  }
  
  static EdgeInsets getInputContentPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 20, vertical: 20);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 18, vertical: 18);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
  
  static EdgeInsets getBadgePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 20, vertical: 6);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 18, vertical: 6);
    return const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
  }
  
  static EdgeInsets getNotificationPadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 20, vertical: 10);
    if (isTablet(context)) return const EdgeInsets.symmetric(horizontal: 18, vertical: 10);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 10);
  }
  
  // Avatar sizes
  static double getAvatarRadius(BuildContext context) {
    if (isDesktop(context)) return 70;
    if (isTablet(context)) return 60;
    return 50;
  }
  
  static double getAvatarIconSize(BuildContext context) {
    return getAvatarRadius(context) * 0.8;
  }
  
  static double getCameraIconSize(BuildContext context) {
    return isMobile(context) ? 18 : 22;
  }
  
  static double getCameraIconPadding(BuildContext context) {
    return isMobile(context) ? 10 : 12;
  }
  
  // Font sizes
  static double getFontSize(BuildContext context, double mobile, double tablet, double desktop) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  // Common font sizes
  static double getTitleFontSize(BuildContext context) => getFontSize(context, 26, 30, 34);
  static double getSubtitleFontSize(BuildContext context) => getFontSize(context, 16, 18, 20);
  static double getBodyFontSize(BuildContext context) => getFontSize(context, 16, 18, 18);
  static double getLabelFontSize(BuildContext context) => getFontSize(context, 14, 16, 16);
  static double getSmallFontSize(BuildContext context) => getFontSize(context, 12, 14, 14);
  static double getButtonFontSize(BuildContext context) => getFontSize(context, 16, 18, 20);
  static double getCreateTitleFontSize(BuildContext context) => getFontSize(context, 30, 34, 38);
  static double getToastFontSize(BuildContext context) => getFontSize(context, 14, 16, 16);
  static double getHintFontSize(BuildContext context) => getFontSize(context, 11, 12, 13);
  
  // Spacings
  static double getSpacing(BuildContext context, double mobile, double tablet, double desktop) {
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
  
  // Common spacings
  static double getSmallSpacing(BuildContext context) => getSpacing(context, 16, 20, 24);
  static double getMediumSpacing(BuildContext context) => getSpacing(context, 20, 24, 28);
  static double getLargeSpacing(BuildContext context) => getSpacing(context, 32, 40, 48);
  static double getCardSpacing(BuildContext context) => getSpacing(context, 16, 20, 24);
  static double getSectionSpacing(BuildContext context) => getSpacing(context, 16, 20, 24);
  static double getFieldSpacing(BuildContext context) => getSpacing(context, 20, 24, 28);
  
  // Button dimensions
  static double getButtonHeight(BuildContext context) => getSpacing(context, 56, 64, 68);
  static double getProgressSize(BuildContext context) => getSpacing(context, 24, 28, 30);
  
  // Border radius
  static const double cardRadius = 12;
  static const double inputRadius = 8;
  static const double buttonRadius = 12;
  static const double badgeRadius = 20;
  static const double notificationRadius = 25;
  static const double headerRadius = 24;
  static const double iconContainerRadius = 8;
  static const double iconContainerLargeRadius = 10;
  
  // Border widths
  static const double borderWidth = 1.5;
  static const double borderWidthThin = 1;
  static const double borderWidthThick = 3;
  
  // Icon sizes
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 18;
  static const double iconSizeLarge = 20;
  static const double iconSizeExtraLarge = 22;
}