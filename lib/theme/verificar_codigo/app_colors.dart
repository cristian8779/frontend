import 'package:flutter/material.dart';

class AppColors {
  // Colores primarios
  static const Color primaryLight = Color(0xFFBE0C0C);
  static const Color primaryDark = Color(0xFFFF6B6B);
  
  // Colores de superficie - Modo claro
  static const Color surfaceLight = Colors.white;
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color surfaceVariantLight = Color(0xFFF5F5F5);
  
  // Colores de superficie - Modo oscuro
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceVariantDark = Color(0xFF2A2A2A);
  
  // Colores de texto - Modo claro
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color onSurfaceVariantLight = Color(0xFF6B6B6B);
  static const Color onBackgroundLight = Color(0xFF1A1A1A);
  
  // Colores de texto - Modo oscuro
  static const Color onSurfaceDark = Colors.white;
  static const Color onSurfaceVariantDark = Color(0xFFB0B0B0);
  static const Color onBackgroundDark = Colors.white;
  
  // Colores de estado
  static const Color errorLight = Color(0xFFD32F2F);
  static const Color errorDark = Color(0xFFFF5252);
  
  // Colores de borde
  static const Color outlineLight = Color(0xFFE0E0E0);
  static const Color outlineDark = Color(0xFF404040);
  
  // Colores para notificaciones
  static const Color successColor = Color(0xFF10B981);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Colores adicionales
  static const Color onPrimary = Colors.white;
}

class AppColorScheme {
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceVariant;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color outline;
  final bool isDark;

  const AppColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.outline,
    required this.isDark,
  });

  static AppColorScheme of(BuildContext context, bool isDark) {
    if (isDark) {
      return const AppColorScheme(
        primary: AppColors.primaryDark,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        onSurfaceVariant: AppColors.onSurfaceVariantDark,
        surfaceVariant: AppColors.surfaceVariantDark,
        background: AppColors.backgroundDark,
        onBackground: AppColors.onBackgroundDark,
        error: AppColors.errorDark,
        outline: AppColors.outlineDark,
        isDark: true,
      );
    } else {
      return const AppColorScheme(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.onPrimary,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurfaceLight,
        onSurfaceVariant: AppColors.onSurfaceVariantLight,
        surfaceVariant: AppColors.surfaceVariantLight,
        background: AppColors.backgroundLight,
        onBackground: AppColors.onBackgroundLight,
        error: AppColors.errorLight,
        outline: AppColors.outlineLight,
        isDark: false,
      );
    }
  }
}