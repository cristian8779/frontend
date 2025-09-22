// 🎨 ESTILOS PROFESIONALES DE LA APLICACIÓN
import 'package:flutter/material.dart';

class AppStyles {
  // 🎯 COLORES PRINCIPALES
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8A65);
  
  // 🎯 COLORES DE ESTADO
  static const Color successColor = Color(0xFF00C853);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF29B6F6);
  
  // 🎯 COLORES DE SUPERFICIE Y FONDO
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E7FF);
  
  // 🎯 COLORES DE TEXTO
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnPrimary = Colors.white;
  
  // 🎯 DIMENSIONES ESTANDARIZADAS
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusMax = 32.0;
  
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;
  
  // 🎯 DURACIONES DE ANIMACIÓN OPTIMIZADAS
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 4);

  // 🎯 SHADOWS MEJORADAS
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // 🎯 CONFIGURACIONES ESPECÍFICAS PARA CARRUSEL
  static const double aspectRatioML = 10 / 3; // Relación similar a Mercado Libre (~3.33:1)
  static const double maxBannerHeight = 240;
  static const double minBannerHeight = 120;
  static const EdgeInsets containerMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  // 🎯 MÉTODOS UTILITARIOS PARA ESTILOS
  
  /// Calcula la altura del banner según el ancho de pantalla
  static double calculateBannerHeight(double screenWidth) {
    double height = (screenWidth - 32) / aspectRatioML; // margen horizontal
    return height.clamp(minBannerHeight, maxBannerHeight);
  }

  /// Obtiene la fracción del viewport según el ancho de pantalla
  static double getViewportFraction(double screenWidth) {
    if (screenWidth >= 1024) return 0.85;
    if (screenWidth >= 768) return 0.88;
    if (screenWidth >= 600) return 0.9;
    return 0.92;
  }

  /// Retorna el color y configuración para badges de estado
  static Map<String, dynamic> getStatusBadgeConfig(DateTime fechaInicio, DateTime fechaFin) {
    final DateTime now = DateTime.now();
    final bool isActive = now.isAfter(fechaInicio) && now.isBefore(fechaFin);
    final bool isExpired = now.isAfter(fechaFin);
    final bool isPending = now.isBefore(fechaInicio);

    if (isExpired) {
      return {
        'status': 'Expirado',
        'color': errorColor,
        'icon': Icons.schedule_rounded,
      };
    } else if (isPending) {
      return {
        'status': 'Programado',
        'color': warningColor,
        'icon': Icons.schedule_rounded,
      };
    } else {
      return {
        'status': 'Activo',
        'color': successColor,
        'icon': Icons.check_circle_rounded,
      };
    }
  }

  /// Retorna el color e icono apropiado para errores
  static Map<String, dynamic> getErrorConfig(String? errorMessage) {
    String errorStr = (errorMessage ?? '').toLowerCase();
    
    if (errorStr.contains('socket') || 
        errorStr.contains('network') || 
        errorStr.contains('connection') ||
        errorStr.contains('internet') ||
        errorStr.contains('conexión')) {
      return {
        'icon': Icons.wifi_off_rounded,
        'color': errorColor,
        'title': 'Sin conexión a internet',
        'subtitle': 'Verifica tu conexión e intenta nuevamente',
      };
    } else if (errorStr.contains('server') || 
               errorStr.contains('servidor') ||
               errorStr.contains('502') || 
               errorStr.contains('503') || 
               errorStr.contains('500')) {
      return {
        'icon': Icons.dns_rounded,
        'color': errorColor,
        'title': 'Servidor no disponible',
        'subtitle': 'El servicio no está disponible en este momento',
      };
    } else {
      return {
        'icon': Icons.error_outline_rounded,
        'color': errorColor,
        'title': errorMessage ?? 'Error desconocido',
        'subtitle': 'No se pudieron cargar los anuncios',
      };
    }
  }
}