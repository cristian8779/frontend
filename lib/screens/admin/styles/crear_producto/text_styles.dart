import 'package:flutter/material.dart';
import 'colors.dart';

/// Estilos de texto para la pantalla de Crear Producto
class CrearProductoTextStyles {
  // Estilos de AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 20,
    letterSpacing: -0.5,
  );
  
  // Estilos de encabezados de sección
  static const TextStyle sectionHeader = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: CrearProductoColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  // Estilos de labels
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CrearProductoColors.textSecondary,
  );
  
  static const TextStyle labelRequired = TextStyle(
    color: CrearProductoColors.error,
    fontWeight: FontWeight.w600,
  );
  
  // Estilos de botones
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle buttonLoading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  // Estilos de subida de imagen
  static const TextStyle imageUploadTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: CrearProductoColors.textSecondary,
  );
  
  static const TextStyle imageUploadHint = TextStyle(
    fontSize: 14,
    color: CrearProductoColors.textTertiary,
  );
  
  // Estilos de SnackBar
  static const TextStyle snackBar = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}