import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  static double getImageSize(BuildContext context) {
    return isMobile(context) ? 95.0 : 130.0;
  }

  static EdgeInsets getCardPadding(BuildContext context) {
    return isMobile(context) 
        ? const EdgeInsets.all(14) 
        : const EdgeInsets.all(18);
  }

  static double getCardMargin(BuildContext context) {
    return isMobile(context) ? 12 : 16;
  }

  static double getFontSize(BuildContext context, {
    required double mobile,
    required double desktop,
  }) {
    return isMobile(context) ? mobile : desktop;
  }

  static EdgeInsets getResponsivePadding(BuildContext context, {
    required EdgeInsets mobile,
    required EdgeInsets desktop,
  }) {
    return isMobile(context) ? mobile : desktop;
  }

  static T getResponsiveValue<T>(BuildContext context, {
    required T mobile,
    required T desktop,
  }) {
    return isMobile(context) ? mobile : desktop;
  }
}