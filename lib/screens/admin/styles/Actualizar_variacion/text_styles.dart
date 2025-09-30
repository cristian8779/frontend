import 'package:flutter/material.dart';
import 'colors.dart';

class ActualizarVariacionTextStyles {
  // Títulos de secciones
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: ActualizarVariacionColors.textPrimary,
  );
  
  // Texto del AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.w600,
  );
  
  // Textos de botones
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  // Textos de preview
  static const TextStyle previewText = TextStyle(
    fontWeight: FontWeight.w500,
    color: ActualizarVariacionColors.textPrimary,
  );
  
  // Placeholder de imagen
  static const TextStyle imagePlaceholder = TextStyle(
    color: ActualizarVariacionColors.textSecondary,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  // Texto secundario de placeholder
  static TextStyle imagePlaceholderSecondary = TextStyle(
    color: ActualizarVariacionColors.placeholderText,
    fontSize: 12,
  );
}