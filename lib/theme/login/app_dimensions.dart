// lib/theme/app_dimensions.dart
import 'package:flutter/material.dart';

class AppDimensions {
  // Breakpoints
  static const double smallScreenBreakpoint = 360.0;
  static const double tabletBreakpoint = 768.0;
  
  // Padding y márgenes
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(16.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(24.0);
  
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 16.0);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: 24.0);
  
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: 8.0);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: 16.0);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: 24.0);
  
  // Border radius
  static const double radiusSmall = 12.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 20.0;
  static const double radiusExtraLarge = 40.0;
  
  // Tamaños de iconos
  static const double iconSmall = 20.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;
  
  // Alturas de botones
  static const double buttonHeightSmall = 45.0;
  static const double buttonHeightMedium = 50.0;
  static const double buttonHeightLarge = 56.0;
  
  // Espaciado
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 16.0;
  static const double spaceLarge = 24.0;
  static const double spaceXLarge = 32.0;
  
  // Elevación
  static const double elevationLow = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationHigh = 8.0;
  
  // Métodos helper para dimensiones responsivas (métodos seguros)
  static bool isSmallScreen(BuildContext context) {
    // Usar try-catch para evitar errores de contexto
    try {
      return MediaQuery.of(context).size.width < smallScreenBreakpoint;
    } catch (e) {
      return false; // Valor por defecto seguro
    }
  }
  
  static bool isTablet(BuildContext context) {
    try {
      return MediaQuery.of(context).size.width > tabletBreakpoint;
    } catch (e) {
      return false; // Valor por defecto seguro
    }
  }
  
  // Obtener dimensiones responsivas con manejo de errores
  static double getResponsivePadding(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > tabletBreakpoint) {
        return screenWidth * 0.15;
      } else if (screenWidth < smallScreenBreakpoint) {
        return screenWidth * 0.04;
      } else {
        return screenWidth * 0.06;
      }
    } catch (e) {
      return 16.0; // Valor por defecto seguro
    }
  }
  
  static double getResponsiveLogoSize(BuildContext context) {
    try {
      final screenWidth = MediaQuery.of(context).size.width;
      if (screenWidth > tabletBreakpoint) {
        return screenWidth * 0.25;
      } else if (screenWidth < smallScreenBreakpoint) {
        return screenWidth * 0.35;
      } else {
        return screenWidth * 0.45;
      }
    } catch (e) {
      return 150.0; // Valor por defecto seguro
    }
  }
  
  static double getResponsiveContainerHeight(BuildContext context) {
    try {
      final screenHeight = MediaQuery.of(context).size.height;
      final screenWidth = MediaQuery.of(context).size.width;
      
      if (screenWidth > tabletBreakpoint) {
        return screenHeight * 0.5;
      } else if (screenWidth < smallScreenBreakpoint) {
        return screenHeight * 0.65;
      } else {
        return screenHeight * 0.6;
      }
    } catch (e) {
      return 400.0; // Valor por defecto seguro
    }
  }
  
  // Métodos estáticos alternativos que no requieren contexto
  static bool isSmallScreenStatic(double screenWidth) {
    return screenWidth < smallScreenBreakpoint;
  }
  
  static bool isTabletStatic(double screenWidth) {
    return screenWidth > tabletBreakpoint;
  }
  
  static double getResponsivePaddingStatic(double screenWidth) {
    if (screenWidth > tabletBreakpoint) {
      return screenWidth * 0.15;
    } else if (screenWidth < smallScreenBreakpoint) {
      return screenWidth * 0.04;
    } else {
      return screenWidth * 0.06;
    }
  }
  
  static double getResponsiveLogoSizeStatic(double screenWidth) {
    if (screenWidth > tabletBreakpoint) {
      return screenWidth * 0.25;
    } else if (screenWidth < smallScreenBreakpoint) {
      return screenWidth * 0.35;
    } else {
      return screenWidth * 0.45;
    }
  }
  
  static double getResponsiveContainerHeightStatic(double screenWidth, double screenHeight) {
    if (screenWidth > tabletBreakpoint) {
      return screenHeight * 0.5;
    } else if (screenWidth < smallScreenBreakpoint) {
      return screenHeight * 0.65;
    } else {
      return screenHeight * 0.6;
    }
  }
}