// lib/screens/admin/styles/control_panel_styles.dart
import 'package:flutter/material.dart';

class ControlPanelStyles {
  // === BREAKPOINTS RESPONSIVOS ===
  static const double mobileSmall = 320;   // iPhone SE, móviles pequeños
  static const double mobile = 375;        // iPhone estándar
  static const double mobileLarge = 480;   // Móviles grandes
  static const double tablet = 768;        // iPad portrait
  static const double tabletLarge = 1024;  // iPad landscape
  static const double desktop = 1280;      // Escritorio estándar
  static const double desktopLarge = 1440; // Escritorio grande
  static const double desktopXL = 1920;    // Full HD
  static const double desktopUltra = 2560; // 2K/4K

  // === HELPER PARA DETECTAR TIPO DE PANTALLA ===
  static String getScreenType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < mobile) return 'mobileSmall';
    if (width < mobileLarge) return 'mobile';
    if (width < tablet) return 'mobileLarge';
    if (width < tabletLarge) return 'tablet';
    if (width < desktop) return 'tabletLarge';
    if (width < desktopLarge) return 'desktop';
    if (width < desktopXL) return 'desktopLarge';
    if (width < desktopUltra) return 'desktopXL';
    return 'desktopUltra';
  }

  // === DIMENSIONES PARA ERROR SCREEN ===
  static Map<String, double> getErrorScreenDimensions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    // Pantallas ultra grandes (2K/4K)
    if (width >= desktopUltra) {
      return {
        'iconSize': 160.0,
        'titleFontSize': 42.0,
        'bodyFontSize': 24.0,
        'buttonFontSize': 22.0,
        'horizontalMargin': 200.0,
        'verticalPadding': 64.0,
        'horizontalPadding': 60.0,
        'buttonPadding': 28.0,
      };
    }
    
    // Pantallas Full HD
    if (width >= desktopXL) {
      return {
        'iconSize': 140.0,
        'titleFontSize': 38.0,
        'bodyFontSize': 22.0,
        'buttonFontSize': 21.0,
        'horizontalMargin': 160.0,
        'verticalPadding': 56.0,
        'horizontalPadding': 50.0,
        'buttonPadding': 24.0,
      };
    }
    
    // Desktop grande
    if (width >= desktopLarge) {
      return {
        'iconSize': 130.0,
        'titleFontSize': 36.0,
        'bodyFontSize': 21.0,
        'buttonFontSize': 20.0,
        'horizontalMargin': 140.0,
        'verticalPadding': 52.0,
        'horizontalPadding': 45.0,
        'buttonPadding': 22.0,
      };
    }
    
    // Desktop estándar
    if (width >= desktop) {
      return {
        'iconSize': 120.0,
        'titleFontSize': 32.0,
        'bodyFontSize': 20.0,
        'buttonFontSize': 20.0,
        'horizontalMargin': 120.0,
        'verticalPadding': 48.0,
        'horizontalPadding': 40.0,
        'buttonPadding': 20.0,
      };
    }
    
    // Tablet landscape
    if (width >= tabletLarge) {
      return {
        'iconSize': 110.0,
        'titleFontSize': 30.0,
        'bodyFontSize': 19.5,
        'buttonFontSize': 19.5,
        'horizontalMargin': 100.0,
        'verticalPadding': 44.0,
        'horizontalPadding': 36.0,
        'buttonPadding': 19.0,
      };
    }
    
    // Tablet portrait
    if (width >= tablet) {
      return {
        'iconSize': 100.0,
        'titleFontSize': 28.0,
        'bodyFontSize': 19.0,
        'buttonFontSize': 19.0,
        'horizontalMargin': 80.0,
        'verticalPadding': 40.0,
        'horizontalPadding': 32.0,
        'buttonPadding': 18.0,
      };
    }
    
    // Móvil grande
    if (width >= mobileLarge) {
      return {
        'iconSize': 92.0,
        'titleFontSize': 25.0,
        'bodyFontSize': 17.5,
        'buttonFontSize': 17.5,
        'horizontalMargin': 28.0,
        'verticalPadding': 32.0,
        'horizontalPadding': 22.0,
        'buttonPadding': 16.0,
      };
    }
    
    // Móvil estándar
    if (width >= mobile) {
      return {
        'iconSize': 88.0,
        'titleFontSize': 24.0,
        'bodyFontSize': 17.0,
        'buttonFontSize': 17.0,
        'horizontalMargin': 24.0,
        'verticalPadding': 28.0,
        'horizontalPadding': 20.0,
        'buttonPadding': 14.0,
      };
    }
    
    // Móvil pequeño
    return {
      'iconSize': 80.0,
      'titleFontSize': 22.0,
      'bodyFontSize': 16.0,
      'buttonFontSize': 16.0,
      'horizontalMargin': 16.0,
      'verticalPadding': 24.0,
      'horizontalPadding': 16.0,
      'buttonPadding': 12.0,
    };
  }

  // === DIMENSIONES PARA CONTENIDO PRINCIPAL ===
  static Map<String, double> getContentDimensions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= desktopUltra) {
      return {
        'padding': 48.0,
        'titleFontSize': 36.0,
        'adminTitleFontSize': 38.0,
        'maxWidth': 1800.0,
      };
    }
    
    if (width >= desktopXL) {
      return {
        'padding': 40.0,
        'titleFontSize': 32.0,
        'adminTitleFontSize': 34.0,
        'maxWidth': 1600.0,
      };
    }
    
    if (width >= desktopLarge) {
      return {
        'padding': 36.0,
        'titleFontSize': 30.0,
        'adminTitleFontSize': 32.0,
        'maxWidth': 1400.0,
      };
    }
    
    if (width >= desktop) {
      return {
        'padding': 32.0,
        'titleFontSize': 28.0,
        'adminTitleFontSize': 29.0,
        'maxWidth': 1200.0,
      };
    }
    
    if (width >= tabletLarge) {
      return {
        'padding': 28.0,
        'titleFontSize': 27.0,
        'adminTitleFontSize': 28.0,
        'maxWidth': 1000.0,
      };
    }
    
    if (width >= tablet) {
      return {
        'padding': 24.0,
        'titleFontSize': 26.0,
        'adminTitleFontSize': 27.0,
        'maxWidth': 800.0,
      };
    }
    
    if (width >= mobileLarge) {
      return {
        'padding': 18.0,
        'titleFontSize': 23.0,
        'adminTitleFontSize': 24.0,
        'maxWidth': double.infinity,
      };
    }
    
    if (width >= mobile) {
      return {
        'padding': 16.0,
        'titleFontSize': 22.0,
        'adminTitleFontSize': 23.0,
        'maxWidth': double.infinity,
      };
    }
    
    return {
      'padding': 12.0,
      'titleFontSize': 20.0,
      'adminTitleFontSize': 21.0,
      'maxWidth': double.infinity,
    };
  }

  // === DIMENSIONES PARA TARJETAS ADMIN ===
  static Map<String, double> getAdminCardDimensions(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= desktopUltra) {
      return {
        'horizontalPadding': 36.0,
        'verticalPadding': 36.0,
        'imageSize': 90.0,
        'spacing': 32.0,
        'fontSize': 26.0,
        'iconSize': 24.0,
      };
    }
    
    if (width >= desktopXL) {
      return {
        'horizontalPadding': 32.0,
        'verticalPadding': 32.0,
        'imageSize': 80.0,
        'spacing': 28.0,
        'fontSize': 24.0,
        'iconSize': 22.0,
      };
    }
    
    if (width >= desktopLarge) {
      return {
        'horizontalPadding': 28.0,
        'verticalPadding': 28.0,
        'imageSize': 75.0,
        'spacing': 26.0,
        'fontSize': 23.0,
        'iconSize': 21.0,
      };
    }
    
    if (width >= desktop) {
      return {
        'horizontalPadding': 24.0,
        'verticalPadding': 24.0,
        'imageSize': 70.0,
        'spacing': 24.0,
        'fontSize': 22.0,
        'iconSize': 20.0,
      };
    }
    
    if (width >= tabletLarge) {
      return {
        'horizontalPadding': 22.0,
        'verticalPadding': 22.0,
        'imageSize': 68.0,
        'spacing': 22.0,
        'fontSize': 21.5,
        'iconSize': 19.0,
      };
    }
    
    if (width >= tablet) {
      return {
        'horizontalPadding': 20.0,
        'verticalPadding': 20.0,
        'imageSize': 65.0,
        'spacing': 20.0,
        'fontSize': 21.0,
        'iconSize': 18.0,
      };
    }
    
    if (width >= mobileLarge) {
      return {
        'horizontalPadding': 18.0,
        'verticalPadding': 18.0,
        'imageSize': 58.0,
        'spacing': 18.0,
        'fontSize': 19.5,
        'iconSize': 17.0,
      };
    }
    
    if (width >= mobile) {
      return {
        'horizontalPadding': 16.0,
        'verticalPadding': 16.0,
        'imageSize': 55.0,
        'spacing': 16.0,
        'fontSize': 19.0,
        'iconSize': 16.0,
      };
    }
    
    return {
      'horizontalPadding': 14.0,
      'verticalPadding': 14.0,
      'imageSize': 50.0,
      'spacing': 14.0,
      'fontSize': 18.0,
      'iconSize': 15.0,
    };
  }

  // === CONFIGURACIÓN DE GRID MEJORADA ===
  static Map<String, dynamic> getGridConfig(double screenWidth) {
    int crossAxisCount;
    double childAspectRatio;
    double spacing;

    if (screenWidth >= desktopUltra) {
      // 2K/4K - 4 columnas
      crossAxisCount = 4;
      childAspectRatio = 3.5;
      spacing = 24.0;
    } else if (screenWidth >= desktopXL) {
      // Full HD - 4 columnas
      crossAxisCount = 4;
      childAspectRatio = 3.3;
      spacing = 20.0;
    } else if (screenWidth >= desktopLarge) {
      // Desktop grande - 3 columnas
      crossAxisCount = 3;
      childAspectRatio = 3.4;
      spacing = 20.0;
    } else if (screenWidth >= desktop) {
      // Desktop estándar - 3 columnas
      crossAxisCount = 3;
      childAspectRatio = 3.2;
      spacing = 18.0;
    } else if (screenWidth >= tabletLarge) {
      // Tablet landscape - 3 columnas
      crossAxisCount = 3;
      childAspectRatio = 3.0;
      spacing = 16.0;
    } else if (screenWidth >= tablet) {
      // Tablet portrait - 2 columnas
      crossAxisCount = 2;
      childAspectRatio = 3.0;
      spacing = 16.0;
    } else if (screenWidth >= mobileLarge) {
      // Móvil grande - 2 columnas
      crossAxisCount = 2;
      childAspectRatio = 2.6;
      spacing = 12.0;
    } else if (screenWidth >= mobile) {
      // Móvil estándar - 1 columna
      crossAxisCount = 1;
      childAspectRatio = 3.5;
      spacing = 12.0;
    } else {
      // Móvil pequeño - 1 columna
      crossAxisCount = 1;
      childAspectRatio = 3.2;
      spacing = 10.0;
    }

    return {
      'crossAxisCount': crossAxisCount,
      'childAspectRatio': childAspectRatio,
      'spacing': spacing,
    };
  }

  // === HELPER: Obtener spacing del grid ===
  static double getGridSpacing(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final config = getGridConfig(width);
    return config['spacing'] as double;
  }

  // === COLORES ===
  static const Color arrowColor = Colors.grey;
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static final Color errorScreenBackground = Colors.grey[100]!;
  static final Color restrictedAccessIconColor = Colors.deepOrange.shade400;
  static final Color restrictedAccessTitle = Colors.deepOrange.shade700;
  static final Color restrictedAccessBody = Colors.grey.shade800;
  static final Color restrictedAccessButton = Colors.deepOrange.shade400;
  static final Color productosCardBackground = Colors.blue.shade50;
  static final Color ventasCardBackground = Colors.green.shade50;
  static final Color anunciosCardBackground = Colors.orange.shade50;

  // === ESTILOS DE TEXTO ===
  static TextStyle getRestrictedAccessTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: restrictedAccessTitle,
      letterSpacing: -0.5,
    );
  }

  static TextStyle getRestrictedAccessBodyStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      color: restrictedAccessBody,
      height: 1.5,
      letterSpacing: 0.2,
    );
  }

  static TextStyle getRestrictedAccessButtonStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );
  }

  static TextStyle getSectionTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
    );
  }

  static TextStyle getAdminCardTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
      letterSpacing: 0.2,
    );
  }

  // === DECORACIONES ===
  static BoxDecoration getErrorCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
    );
  }

  static BoxDecoration getAdminCardDecoration(Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }

  static RoundedRectangleBorder getButtonShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
  }

  // === ESPACIADO DINÁMICO ===
  static double getDynamicSpacing(BuildContext context, {double multiplier = 1.0}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= desktopUltra) return 16.0 * multiplier;
    if (width >= desktopXL) return 14.0 * multiplier;
    if (width >= desktop) return 12.0 * multiplier;
    if (width >= tablet) return 10.0 * multiplier;
    if (width >= mobile) return 8.0 * multiplier;
    return 6.0 * multiplier;
  }

  // === CONSTANTES DE ESPACIADO ===
  static const double defaultSpacing = 12.0;
  static const double smallSpacing = 8.0;
  static const double tinySpacing = 2.0;
  static const double cardElevation = 6.0;
  static const double buttonElevation = 4.0;
  static const double gridSpacing = 16.0;

  // === ICONOS ===
  static const IconData restrictedAccessIcon = Icons.lock_outline;
  static const IconData homeIcon = Icons.home_outlined;
  static const IconData arrowForwardIcon = Icons.arrow_forward_ios;

  // === MAPEO DE ERRORES ===
  static String mapErrorMessage(String error) {
    final errorLower = error.toLowerCase();

    if (error.contains('SocketException') ||
        error.contains('NetworkException') ||
        errorLower.contains('network') ||
        errorLower.contains('no internet') ||
        errorLower.contains('connection failed') ||
        errorLower.contains('unreachable')) {
      return "❌ Sin conexión a Internet. Verifica tu WiFi o datos móviles.";
    }

    if (error.contains('TimeoutException') ||
        errorLower.contains('timeout') ||
        errorLower.contains('timed out')) {
      return "❌ La conexión está tardando demasiado. Intenta nuevamente.";
    }

    if (error.contains('500') ||
        error.contains('502') ||
        error.contains('503') ||
        error.contains('504') ||
        errorLower.contains('server error') ||
        errorLower.contains('internal server') ||
        errorLower.contains('bad gateway') ||
        errorLower.contains('service unavailable')) {
      return "❌ Nuestros servidores están experimentando problemas. Intenta más tarde.";
    }

    if (error.contains('Token expirado') ||
        error.contains('401') ||
        error.contains('Unauthorized') ||
        errorLower.contains('token') ||
        errorLower.contains('unauthorized')) {
      return "❌ Tu sesión ha expirado. Por favor, inicia sesión nuevamente.";
    }

    if (error.contains('403') ||
        error.contains('Forbidden') ||
        errorLower.contains('forbidden') ||
        errorLower.contains('access denied')) {
      return "❌ No tienes permisos para realizar esta acción.";
    }

    if (error.contains('404') ||
        error.contains('Not Found') ||
        errorLower.contains('not found')) {
      return "❌ El recurso solicitado no fue encontrado.";
    }

    if (errorLower.contains('format') ||
        errorLower.contains('parse') ||
        errorLower.contains('json') ||
        errorLower.contains('xml')) {
      return "❌ Error en el formato de los datos recibidos.";
    }

    return "❌ Ha ocurrido un error inesperado. Por favor, intenta nuevamente.";
  }
}