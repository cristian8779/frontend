// lib/theme/responsive_helper.dart
import 'package:flutter/material.dart';

class ResponsiveHelper {
  final BuildContext context;
  final MediaQueryData _mediaQuery;
  final double screenWidth;
  final double screenHeight;
  final bool isSmallScreen;
  final bool isTablet;
  
  // Breakpoints
  static const double smallScreenBreakpoint = 360.0;
  static const double tabletBreakpoint = 768.0;
  
  ResponsiveHelper._(this.context) 
    : _mediaQuery = MediaQuery.of(context),
      screenWidth = MediaQuery.of(context).size.width,
      screenHeight = MediaQuery.of(context).size.height,
      isSmallScreen = MediaQuery.of(context).size.width < smallScreenBreakpoint,
      isTablet = MediaQuery.of(context).size.width > tabletBreakpoint;
  
  factory ResponsiveHelper.of(BuildContext context) {
    return ResponsiveHelper._(context);
  }
  
  // Métodos de dimensiones
  double get responsivePadding {
    if (isTablet) {
      return screenWidth * 0.15;
    } else if (isSmallScreen) {
      return screenWidth * 0.04;
    } else {
      return screenWidth * 0.06;
    }
  }
  
  double get responsiveLogoSize {
    if (isTablet) {
      return screenWidth * 0.25;
    } else if (isSmallScreen) {
      return screenWidth * 0.35;
    } else {
      return screenWidth * 0.45;
    }
  }
  
  double get responsiveContainerHeight {
    if (isTablet) {
      return screenHeight * 0.5;
    } else if (isSmallScreen) {
      return screenHeight * 0.65;
    } else {
      return screenHeight * 0.6;
    }
  }
  
  // Tamaños de fuente
  double get titleFontSize {
    if (isTablet) {
      return 36;
    } else if (isSmallScreen) {
      return 22;
    } else if (screenWidth < 400) {
      return 24;
    } else {
      return 30;
    }
  }
  
  double get buttonFontSize => isSmallScreen ? 16 : 18;
  double get inputFontSize => isSmallScreen ? 14 : 16;
  double get labelFontSize => isSmallScreen ? 14 : 16;
  double get linkFontSize => isSmallScreen ? 13 : 15;
  
  // Tamaños de iconos
  double get iconSize => isSmallScreen ? 20 : 24;
  
  // Dimensiones de botones
  double get buttonHeight => isSmallScreen ? 45 : 50;
  
  // Radios
  double get borderRadius => isSmallScreen ? 16 : 20;
  double get containerRadius => isSmallScreen ? 40 : 50;
  
  // Espaciado
  double get smallSpace => isSmallScreen ? 12 : 16;
  double get mediumSpace => isSmallScreen ? 16 : 20;
  double get largeSpace => isSmallScreen ? 20 : 24;
  
  // Padding
  EdgeInsets get horizontalPadding => EdgeInsets.symmetric(horizontal: responsivePadding);
  EdgeInsets get fieldPadding => EdgeInsets.symmetric(
    horizontal: isSmallScreen ? 12 : 16,
    vertical: isSmallScreen ? 12 : 14,
  );
  
  // SafeArea superior
  double get topSafeArea => _mediaQuery.padding.top + (isSmallScreen ? 20 : 40);
  
  // ViewInsets para teclado
  double get keyboardInset => _mediaQuery.viewInsets.bottom;
}