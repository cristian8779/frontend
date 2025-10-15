import 'package:flutter/material.dart';
import 'create_category_colors.dart';

/// Estilos de texto para la pantalla de crear categoría
class CreateCategoryTextStyles {
  // AppBar
  static const TextStyle appBarTitle = TextStyle(
    color: CreateCategoryColors.negro87,
    fontWeight: FontWeight.w600,
  );

  // Títulos de sección
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Placeholder de imagen
  static TextStyle imagePlaceholder = TextStyle(
    color: CreateCategoryColors.gris600,
  );

  // Botón
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
  );

  // Dialog
  static const TextStyle dialogTitle = TextStyle(
    fontWeight: FontWeight.bold,
  );

  // Loading overlay
  static const TextStyle loadingText = TextStyle();
}