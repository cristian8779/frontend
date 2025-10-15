import 'package:flutter/material.dart';

class AppColors {
  // Colores principales
  static const Color primary = Colors.blue;
  static const Color secondary = Colors.green;
  static const Color accent = Colors.orange;
  static const Color error = Colors.red;
  static const Color warning = Colors.orange;
  
  // Colores de fondo
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;
  
  // Colores de texto
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.grey;
  
  // Gradientes
  static LinearGradient get primaryGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.blue[50]!,
      Colors.white,
    ],
  );
  
  static LinearGradient get appBarGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.blue[50]!,
      Colors.white,
    ],
  );
  
  // Colores con opacidad
  static Color primaryLight(double opacity) => primary.withOpacity(opacity);
  static Color secondaryLight(double opacity) => secondary.withOpacity(opacity);
  static Color accentLight(double opacity) => accent.withOpacity(opacity);
  static Color errorLight(double opacity) => error.withOpacity(opacity);
  static Color warningLight(double opacity) => warning.withOpacity(opacity);
}