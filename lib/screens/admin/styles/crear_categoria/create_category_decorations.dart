import 'package:flutter/material.dart';
import 'create_category_colors.dart';

/// Decoraciones y estilos visuales para la pantalla de crear categoría
class CreateCategoryDecorations {
  // Decoración del contenedor de imagen
  static BoxDecoration imageContainer = BoxDecoration(
    color: CreateCategoryColors.blanco,
    border: Border.all(color: CreateCategoryColors.gris300),
    borderRadius: BorderRadius.circular(14),
    boxShadow: const [
      BoxShadow(
        color: CreateCategoryColors.negro12,
        blurRadius: 6,
        offset: Offset(0, 3),
      ),
    ],
  );

  // Decoración de inputs
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: CreateCategoryColors.blanco,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Estilo del botón principal
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: CreateCategoryColors.colorPrimario,
    foregroundColor: CreateCategoryColors.blanco,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    ),
  );

  // Estilo del dialog
  static RoundedRectangleBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  // Border radius para imágenes
  static BorderRadius imageBorderRadius = BorderRadius.circular(14);
}