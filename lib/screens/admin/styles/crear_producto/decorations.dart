import 'package:flutter/material.dart';
import 'colors.dart';

/// Decoraciones y estilos de contenedores para la pantalla de Crear Producto
class CrearProductoDecorations {
  // Decoración del contenedor de encabezado de sección
  static BoxDecoration sectionIconContainer = BoxDecoration(
    color: CrearProductoColors.primaryOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
  );
  
  // Decoraciones de campos de texto
  static InputDecoration inputDecoration({
    String? hintText,
    IconData? icon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: icon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(icon, color: CrearProductoColors.textHint, size: 20),
            )
          : null,
      filled: true,
      fillColor: CrearProductoColors.inputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrearProductoColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrearProductoColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrearProductoColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrearProductoColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: CrearProductoColors.error, width: 2),
      ),
    );
  }
  
  // Decoración del contenedor de imagen
  static BoxDecoration imageContainer({bool hasImage = false}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: hasImage ? CrearProductoColors.primary : CrearProductoColors.border,
        width: hasImage ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: CrearProductoColors.shadowOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Decoración del botón de editar imagen
  static BoxDecoration imageEditButton = BoxDecoration(
    color: CrearProductoColors.shadowOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
  );
  
  // Decoración del círculo de upload
  static BoxDecoration uploadCircle = BoxDecoration(
    color: CrearProductoColors.primaryOpacity(0.1),
    shape: BoxShape.circle,
  );
  
  // Estilo de botones
  static ButtonStyle primaryButton({required bool isLoading}) {
    return ElevatedButton.styleFrom(
      backgroundColor: CrearProductoColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: CrearProductoColors.disabled,
      elevation: isLoading ? 0 : 8,
      shadowColor: CrearProductoColors.primaryOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
  
  static ButtonStyle fabButton = ElevatedButton.styleFrom(
    backgroundColor: CrearProductoColors.successAlt,
    foregroundColor: Colors.white,
    elevation: 8,
  );
  
  // Decoración de SnackBar
  static ShapeBorder snackBarShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
}