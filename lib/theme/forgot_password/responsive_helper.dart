import 'package:flutter/material.dart';

/// Helper class para manejar diseño responsive
class ResponsiveHelper {
  final Size size;
  
  ResponsiveHelper(this.size);
  
  // Breakpoints
  bool get isMobile => size.width < 600;
  bool get isTablet => size.width >= 600 && size.width < 1024;
  bool get isDesktop => size.width >= 1024;
  
  // Dimensiones adaptativas
  double get padding => isMobile ? 24 : (isTablet ? 32 : 40);
  double get cardPadding => isMobile ? 24 : (isTablet ? 32 : 40);
  double get verticalSpacing => isMobile ? 20 : (isTablet ? 24 : 28);
  double get horizontalSpacing => isMobile ? 16 : (isTablet ? 20 : 24);
  
  // Tamaños de fuente
  double get titleSize => isMobile ? 28 : (isTablet ? 32 : 36);
  double get bodySize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get labelSize => isMobile ? 15 : (isTablet ? 16 : 17);
  double get buttonTextSize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get inputTextSize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get captionSize => isMobile ? 13 : (isTablet ? 14 : 15);
  
  // Tamaños de iconos
  double get iconSize => isMobile ? 20 : (isTablet ? 22 : 24);
  double get smallIconSize => isMobile ? 16 : (isTablet ? 18 : 20);
  double get loadingSize => isMobile ? 18 : (isTablet ? 20 : 22);
  
  // Dimensiones de componentes
  double get buttonHeight => isMobile ? 54 : (isTablet ? 58 : 62);
  double get inputPadding => isMobile ? 18 : (isTablet ? 20 : 22);
  double get borderRadius => isMobile ? 16 : (isTablet ? 18 : 20);
  double get inputRadius => isMobile ? 14 : (isTablet ? 16 : 18);
  
  // Hero illustration
  double get heroSize => isMobile ? size.width * 0.45 : (isTablet ? 200 : 240);
  double get heroIconSize => isMobile ? size.width * 0.18 : (isTablet ? 80 : 96);
  
  // Sombras
  double get shadowBlur => isMobile ? 20 : (isTablet ? 25 : 30);
  
  // Ancho máximo para desktop
  double get maxCardWidth => isDesktop ? 480 : double.infinity;
}