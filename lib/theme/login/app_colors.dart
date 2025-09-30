// lib/theme/app_colors.dart
import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primary = Color(0xFFD32F2F);
  static const Color secondary = Color(0xFF212121);
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  
  // Colores de estado
  static const Color success = Colors.green;
  static const Color warning = Colors.orange;
  static const Color error = Colors.red;
  static const Color errorAccent = Colors.redAccent;
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Colors.black87;
  static const Color textOnPrimary = Colors.white;
  
  // Colores de superficie
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Colors.black87;
  
  // Sombras
  static Color shadow = Colors.black.withOpacity(0.1);
  static Color shadowPrimary = primary.withOpacity(0.3);
}