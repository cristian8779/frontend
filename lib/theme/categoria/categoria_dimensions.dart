import 'package:flutter/material.dart';

/// Dimensiones y medidas responsivas para la pantalla de categorías
class CategoriaDimensions {
  // Breakpoints para responsive
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 800;
  static const double desktopBreakpoint = 1200;
  
  // Padding responsivo
  static EdgeInsets getResponsivePadding(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return const EdgeInsets.all(24);
    if (screenWidth >= tabletBreakpoint) return const EdgeInsets.all(20);
    if (screenWidth >= mobileBreakpoint) return const EdgeInsets.all(18);
    return const EdgeInsets.all(16);
  }
  
  // Spacing responsivo
  static double getResponsiveSpacing(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return 20;
    if (screenWidth >= tabletBreakpoint) return 18;
    if (screenWidth >= mobileBreakpoint) return 16;
    return 14;
  }
  
  // Número de columnas en grid
  static int getCrossAxisCount(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return 4; // Desktop grande
    if (screenWidth >= tabletBreakpoint) return 3;  // Tablet horizontal
    if (screenWidth >= mobileBreakpoint) return 2;  // Tablet vertical
    return 2; // Móvil
  }
  
  // Aspect ratio para cards
  static double getChildAspectRatio(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return 0.75; // Desktop
    if (screenWidth >= tabletBreakpoint) return 0.70;  // Tablet horizontal
    if (screenWidth >= mobileBreakpoint) return 0.68;  // Tablet vertical
    return 0.65; // Móvil
  }
  
  // Dimensiones de cards
  static double getCardPadding(double screenWidth) {
    if (screenWidth >= desktopBreakpoint) return 16.0;
    if (screenWidth >= mobileBreakpoint) return 14.0;
    return 12.0;
  }
  
  // Radios
  static const double cardRadius = 12.0;
  static const double buttonRadius = 8.0;
  static const double badgeRadius = 4.0;
  
  // Espaciados específicos
  static double getErrorStatePadding(double screenWidth) {
    return screenWidth >= mobileBreakpoint ? 32 : 24;
  }
  
  static double getLoadingIndicatorPadding(double screenWidth) {
    return screenWidth < mobileBreakpoint ? 16 : 20;
  }
  
  static double getEndMessagePadding(double screenWidth) {
    return screenWidth < mobileBreakpoint ? 16 : 20;
  }
  
  static double getEndMessageInternalPadding(double screenWidth) {
    return screenWidth < mobileBreakpoint ? 12 : 16;
  }
  
  static double getBottomSpacing(double screenWidth) {
    return screenWidth < mobileBreakpoint ? 24 : 32;
  }
  
  // Utilidades para detección de dispositivos
  static bool isMobile(double screenWidth) => screenWidth < mobileBreakpoint;
  static bool isTablet(double screenWidth) => screenWidth >= mobileBreakpoint && screenWidth < desktopBreakpoint;
  static bool isDesktop(double screenWidth) => screenWidth >= desktopBreakpoint;
}