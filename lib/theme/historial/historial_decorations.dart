// theme/historial/historial_decorations.dart
import 'package:flutter/material.dart';
import 'historial_colors.dart';
import 'historial_dimensions.dart';

class HistorialDecorations {
  // Decoración de containers principales
  static BoxDecoration get errorContainer => BoxDecoration(
    color: HistorialColors.cardBackground,
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusLarge),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(HistorialDimensions.shadowOpacity),
        blurRadius: HistorialDimensions.elevationHigh,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get emptyContainer => BoxDecoration(
    color: HistorialColors.cardBackground,
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusLarge),
  );
  
  // Decoración de productos
  static BoxDecoration get productBorder => const BoxDecoration(
    color: HistorialColors.cardBackground,
    border: Border(
      bottom: BorderSide(
        color: HistorialColors.sectionBackground,
        width: 1,
      ),
    ),
  );
  
  // Decoración de imágenes
  static BoxDecoration get imageContainer => BoxDecoration(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusMedium),
    color: HistorialColors.imageBackground,
    border: Border.all(color: HistorialColors.imageBorder),
  );
  
  static BoxDecoration get imageContainerCard => BoxDecoration(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusSmall),
    color: HistorialColors.imageBackground,
    border: Border.all(color: HistorialColors.imageBorder),
  );
  
  // Decoración de cards
  static ShapeBorder get cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusMedium),
  );
  
  // Decoración de diálogos
  static ShapeBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusLarge),
  );
  
  // Decoración de botones (OutlinedBorder para ElevatedButton)
  static OutlinedBorder get buttonShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusSmall),
  );
  
  // Decoración de SnackBar
  static ShapeBorder get snackBarShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(HistorialDimensions.borderRadiusSmall),
  );
}
