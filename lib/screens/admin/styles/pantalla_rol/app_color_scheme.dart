import 'package:flutter/material.dart';

/// Sistema de colores para modo claro y oscuro
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

  /// Obtiene el esquema de colores basado en el tema actual
  static AppColorScheme of(BuildContext context, bool isDark) {
    if (isDark) {
      return const AppColorScheme(
        primary: Color(0xFFFF6B6B),
        onPrimary: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB0B0B0),
        surfaceVariant: Color(0xFF2A2A2A),
        background: Color(0xFF121212),
        onBackground: Colors.white,
        error: Color(0xFFFF5252),
        outline: Color(0xFF404040),
        isDark: true,
      );
    } else {
      return const AppColorScheme(
        primary: Color(0xFFBE0C0C),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        onSurfaceVariant: Color(0xFF6B6B6B),
        surfaceVariant: Color(0xFFF5F5F5),
        background: Color(0xFFF8FAFC),
        onBackground: Color(0xFF1A1A1A),
        error: Color(0xFFD32F2F),
        outline: Color(0xFFE0E0E0),
        isDark: false,
      );
    }
  }
}