// top_icons_styles.dart
import 'package:flutter/material.dart';

class TopIconsTheme {
  // Colores principales
  static const Color settingsIconColor = Colors.black87;
  static const Color notificationIconColor = Colors.red;
  static const Color backgroundColor = Colors.transparent;
  
  // Iconos
  static const IconData settingsIcon = Icons.settings;
  static const IconData notificationIcon = Icons.notifications;
  
  // Configuraciones por defecto
  static const bool defaultShowNotification = true;
  static const double defaultBorderRadius = 12.0;
}

class TopIconsDimensions {
  // Breakpoints
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  
  // Función para obtener dimensiones responsivas
  static Map<String, double> getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= tabletBreakpoint;
    final isDesktop = screenWidth >= desktopBreakpoint;
    
    if (isDesktop) {
      return {
        'iconSize': 32.0,
        'buttonSize': 56.0,
        'spacing': 16.0,
      };
    } else if (isTablet) {
      return {
        'iconSize': 30.0,
        'buttonSize': 52.0,
        'spacing': 12.0,
      };
    } else {
      return {
        'iconSize': 28.0,
        'buttonSize': 48.0,
        'spacing': 8.0,
      };
    }
  }
  
  // Helpers para breakpoints
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}

class TopIconsDecorations {
  // Decoración del contenedor de botón
  static BoxDecoration getButtonContainerDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(TopIconsTheme.defaultBorderRadius),
      color: TopIconsTheme.backgroundColor,
    );
  }
}

class TopIconsLayout {
  // Layout principal
  static const MainAxisAlignment mainAxisAlignment = MainAxisAlignment.spaceBetween;
  
  // Constraints para los botones
  static BoxConstraints getButtonConstraints(Map<String, double> dimensions) {
    return BoxConstraints(
      minWidth: dimensions['buttonSize']!,
      minHeight: dimensions['buttonSize']!,
    );
  }
  
  // Padding para los íconos
  static EdgeInsets getIconPadding(Map<String, double> dimensions) {
    return EdgeInsets.all(dimensions['spacing']!);
  }
}