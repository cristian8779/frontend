import 'package:flutter/material.dart';

/// Dimensiones y medidas responsivas para la pantalla de búsqueda
class BusquedaDimensions {
  BusquedaDimensions._();

  // Breakpoints
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1200.0;

  /// Determina si estamos en tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  /// Determina si estamos en desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Obtiene el número de columnas para el grid según el ancho de pantalla
  static int getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return 3; // Desktop
    if (width >= tabletBreakpoint) return 2;  // Tablet
    return 1; // Mobile
  }

  /// Obtiene padding responsivo horizontal
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  /// Obtiene tamaño de fuente responsivo
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopBreakpoint) return baseFontSize + 2;
    if (width >= tabletBreakpoint) return baseFontSize + 1;
    return baseFontSize;
  }

  /// Obtiene el tamaño de imagen de producto según el dispositivo
  static double getProductImageSize(BuildContext context) {
    return isTablet(context) ? 90.0 : 75.0;
  }

  // Radios de borde
  static double cardBorderRadius(BuildContext context) {
    return isTablet(context) ? 20.0 : 16.0;
  }

  static double buttonBorderRadius(BuildContext context) {
    return isTablet(context) ? 16.0 : 12.0;
  }

  // Espaciados
  static double headerTopPadding(BuildContext context) {
    return isTablet(context) ? 16.0 : 12.0;
  }

  static double headerBottomPadding(BuildContext context) {
    return isTablet(context) ? 12.0 : 8.0;
  }

  static double sectionSpacing(BuildContext context) {
    return isTablet(context) ? 32.0 : 24.0;
  }
}