import 'package:flutter/material.dart';

/// Colores utilizados en la pantalla de Crear Producto
class CrearProductoColors {
  // Colores primarios
  static const Color primary = Color(0xFF6366F1);
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color background = Color(0xFFF8FAFC);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF374151);
  static const Color textTertiary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  
  // Colores de estado
  static const Color success = Color(0xFF38A169);
  static const Color successAlt = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFE53E3E);
  
  // Colores de bordes y fondos
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBackground = Colors.white;
  static const Color disabled = Color(0xFF9CA3AF);
  
  // Colores con opacidad (para usar con withOpacity)
  static Color primaryOpacity(double opacity) => primary.withOpacity(opacity);
  static Color shadowOpacity(double opacity) => Colors.black.withOpacity(opacity);
}