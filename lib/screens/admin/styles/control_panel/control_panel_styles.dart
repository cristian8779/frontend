// lib/screens/admin/styles/control_panel_styles.dart
import 'package:flutter/material.dart';

class ControlPanelStyles {
  // === DIMENSIONES PARA ERROR SCREEN ===
  static Map<String, double> getErrorScreenDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
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
    } else if (isTablet) {
      return {
        'iconSize': 108.0,
        'titleFontSize': 28.0,
        'bodyFontSize': 19.0,
        'buttonFontSize': 19.0,
        'horizontalMargin': 80.0,
        'verticalPadding': 42.0,
        'horizontalPadding': 32.0,
        'buttonPadding': 18.0,
      };
    } else {
      return {
        'iconSize': 96.0,
        'titleFontSize': 26.0,
        'bodyFontSize': 18.0,
        'buttonFontSize': 18.0,
        'horizontalMargin': 32.0,
        'verticalPadding': 36.0,
        'horizontalPadding': 24.0,
        'buttonPadding': 14.0,
      };
    }
  }

  // === DIMENSIONES PARA CONTENIDO PRINCIPAL ===
  static Map<String, double> getContentDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return {
        'padding': 32.0,
        'titleFontSize': 28.0,
        'adminTitleFontSize': 29.0,
        'maxWidth': 1200.0,
      };
    } else if (isTablet) {
      return {
        'padding': 24.0,
        'titleFontSize': 26.0,
        'adminTitleFontSize': 27.0,
        'maxWidth': 800.0,
      };
    } else {
      return {
        'padding': 20.0,
        'titleFontSize': 24.0,
        'adminTitleFontSize': 25.0,
        'maxWidth': double.infinity,
      };
    }
  }

  // === DIMENSIONES PARA TARJETAS ADMIN ===
  static Map<String, double> getAdminCardDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    if (isDesktop) {
      return {
        'horizontalPadding': 24.0,
        'verticalPadding': 24.0,
        'imageSize': 70.0,
        'spacing': 24.0,
        'fontSize': 22.0,
        'iconSize': 20.0,
      };
    } else if (isTablet) {
      return {
        'horizontalPadding': 22.0,
        'verticalPadding': 22.0,
        'imageSize': 65.0,
        'spacing': 22.0,
        'fontSize': 21.0,
        'iconSize': 18.0,
      };
    } else {
      return {
        'horizontalPadding': 20.0,
        'verticalPadding': 20.0,
        'imageSize': 60.0,
        'spacing': 20.0,
        'fontSize': 20.0,
        'iconSize': 16.0,
      };
    }
  }

  // === CONFIGURACIÓN DE GRID ===
  static Map<String, dynamic> getGridConfig(double maxWidth) {
    int crossAxisCount;
    double childAspectRatio;

    if (maxWidth >= 1200) {
      crossAxisCount = 3;
      childAspectRatio = 3.2;
    } else if (maxWidth >= 768) {
      crossAxisCount = 2;
      childAspectRatio = 3.0;
    } else if (maxWidth >= 600) {
      crossAxisCount = 2;
      childAspectRatio = 2.8;
    } else {
      crossAxisCount = 1;
      childAspectRatio = 3.5;
    }

    return {
      'crossAxisCount': crossAxisCount,
      'childAspectRatio': childAspectRatio,
    };
  }

  // === COLORES ===
  static const Color arrowColor = Colors.grey; // ✅ solo una definición
  static const Color backgroundColor = Color(0xFFF7F9FC);
  static final Color errorScreenBackground = Colors.grey[100]!;
  static final Color restrictedAccessIconColor = Colors.deepOrange.shade400;
  static final Color restrictedAccessTitle = Colors.deepOrange.shade700;
  static final Color restrictedAccessBody = Colors.grey.shade800;
  static final Color restrictedAccessButton = Colors.deepOrange.shade400;

  // === COLORES PARA TARJETAS ADMIN ===
  static final Color productosCardBackground = Colors.blue.shade50;
  static final Color ventasCardBackground = Colors.green.shade50;
  static final Color anunciosCardBackground = Colors.orange.shade50;

  // === ESTILOS DE TEXTO ===
  static TextStyle getRestrictedAccessTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: restrictedAccessTitle,
    );
  }

  static TextStyle getRestrictedAccessBodyStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      color: restrictedAccessBody,
      height: 1.4,
    );
  }

  static TextStyle getRestrictedAccessButtonStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle getSectionTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }

  static TextStyle getAdminCardTitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
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
