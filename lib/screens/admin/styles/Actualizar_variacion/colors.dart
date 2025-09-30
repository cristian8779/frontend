import 'package:flutter/material.dart';

class ActualizarVariacionColors {
  // Colores primarios
  static const Color primary = Color(0xFF3A86FF);
  static const Color background = Color(0xFFF7FAFC);
  static const Color textPrimary = Color(0xFF2D3748);
  static const Color textSecondary = Color(0xFF718096);
  
  // Colores de estado
  static final Color success = Colors.green.shade600;
  static final Color error = Colors.red.shade600;
  static final Color errorBorder = Colors.red.shade400;
  
  // Colores de bordes
  static final Color border = Colors.grey.shade300;
  static final Color borderLight = Colors.grey.shade200;
  
  // Colores de fondo
  static const Color cardBackground = Colors.white;
  static final Color disabled = Colors.grey.shade300;
  static final Color placeholderIcon = Colors.grey.shade400;
  static final Color placeholderText = Colors.grey.shade500;
  static final Color imageBackground = Colors.grey.shade100;
  
  // Colores con opacidad
  static Color primaryLight(double opacity) => primary.withOpacity(opacity);
  static Color blackWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  static Color shadowColor(double opacity) => Colors.black.withOpacity(opacity);
}