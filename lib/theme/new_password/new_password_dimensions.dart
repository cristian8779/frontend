import 'package:flutter/material.dart';

class NewPasswordDimensions {
  // Breakpoints responsivos
  static const double mobileBreakpoint = 360.0;
  static const double tabletBreakpoint = 600.0;
  static const double desktopBreakpoint = 500.0;
  
  // Multiplicadores responsivos
  static const double mobileScale = 0.8;
  static const double tabletScale = 1.0;
  static const double desktopScale = 1.2;
  
  // Función para obtener tamaño responsivo
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobileBreakpoint) {
      return baseSize * mobileScale;
    } else if (screenWidth > desktopBreakpoint) {
      return baseSize * desktopScale;
    }
    return baseSize;
  }
  
  // Función para obtener padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobileBreakpoint) {
      return const EdgeInsets.all(16);
    } else if (screenWidth > desktopBreakpoint) {
      return const EdgeInsets.all(32);
    }
    return const EdgeInsets.all(24);
  }
  
  // Función para verificar si es tablet
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width > tabletBreakpoint;
  }
  
  // Tamaños de fuente base
  static const double fontSmall = 12.0;
  static const double fontMedium = 14.0;
  static const double fontLarge = 16.0;
  static const double fontXLarge = 18.0;
  static const double fontXXLarge = 20.0;
  
  // Tamaños de íconos base
  static const double iconSmall = 14.0;
  static const double iconMedium = 16.0;
  static const double iconLarge = 18.0;
  static const double iconXLarge = 20.0;
  static const double iconXXLarge = 24.0;
  
  // Espaciados base
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 6.0;
  static const double spaceMedium = 8.0;
  static const double spaceLarge = 12.0;
  static const double spaceXLarge = 16.0;
  static const double spaceXXLarge = 20.0;
  static const double spaceXXXLarge = 24.0;
  static const double spaceGiant = 32.0;
  
  // Border radius base
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 10.0;
  static const double radiusLarge = 12.0;
  static const double radiusXLarge = 16.0;
  
  // Elevaciones/sombras
  static const double elevationNone = 0.0;
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 10.0;
  
  // Alturas de componentes
  static const double buttonHeight = 54.0;
  static const double textFieldMinHeight = 56.0;
  static const double chipHeight = 32.0;
  
  // Anchos máximos
  static const double maxWidthMobile = double.infinity;
  static const double maxWidthTablet = 600.0;
  
  // Paddings específicos
  static const EdgeInsets paddingSmall = EdgeInsets.all(8.0);
  static const EdgeInsets paddingMedium = EdgeInsets.all(12.0);
  static const EdgeInsets paddingLarge = EdgeInsets.all(16.0);
  static const EdgeInsets paddingXLarge = EdgeInsets.all(20.0);
  
  // Paddings simétricos
  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(horizontal: 8.0);
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(horizontal: 12.0);
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(horizontal: 16.0);
  
  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(vertical: 4.0);
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(vertical: 6.0);
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(vertical: 8.0);
  
  // Constraints para contenido
  static BoxConstraints getContentConstraints(BuildContext context) {
    return BoxConstraints(
      maxWidth: isTablet(context) ? maxWidthTablet : maxWidthMobile,
    );
  }
}