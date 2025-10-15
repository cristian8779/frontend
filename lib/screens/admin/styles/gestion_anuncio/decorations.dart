import 'package:flutter/material.dart';
import 'colors.dart';

/// Decoraciones reutilizables para la gestión de anuncios
class GestionAnunciosDecorations {
  
  /// BoxDecoration para contenedores con sombra suave
  static BoxDecoration containerWithShadow({
    Color? color,
    Color? borderColor,
    double borderWidth = 1,
    double borderRadius = 16,
  }) {
    return BoxDecoration(
      color: color ?? Colors.white,
      borderRadius: BorderRadius.circular(borderRadius),
      border: borderColor != null 
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// BoxDecoration para imagen del anuncio
  static BoxDecoration imagenAnuncioDecoration({
    required bool tieneImagen,
  }) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: tieneImagen ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris300,
        width: tieneImagen ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// BoxDecoration para el badge de éxito en imagen
  static BoxDecoration successBadgeDecoration() {
    return BoxDecoration(
      color: GestionAnunciosColors.verdePrimario,
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// BoxDecoration para iconos contenedores
  static BoxDecoration iconContainerDecoration({
    required bool isActive,
  }) {
    return BoxDecoration(
      color: (isActive 
          ? GestionAnunciosColors.rojo 
          : GestionAnunciosColors.gris400).withOpacity(0.1),
      borderRadius: BorderRadius.circular(10),
    );
  }

  /// BoxDecoration para opciones de tipo (producto/categoría)
  static BoxDecoration tipoOpcionDecoration({
    required bool isSelected,
  }) {
    return BoxDecoration(
      color: isSelected 
          ? GestionAnunciosColors.rojo.withOpacity(0.1) 
          : GestionAnunciosColors.gris50,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isSelected 
            ? GestionAnunciosColors.rojo 
            : GestionAnunciosColors.gris300,
        width: isSelected ? 2 : 1,
      ),
    );
  }

  /// BoxDecoration para indicador de sin conexión (compacto)
  static BoxDecoration noConnectionCompactDecoration() {
    return BoxDecoration(
      color: GestionAnunciosColors.naranja100,
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: GestionAnunciosColors.naranja300),
    );
  }

  /// BoxDecoration para mensaje sin conexión (grande)
  static BoxDecoration noConnectionMessageDecoration() {
    return BoxDecoration(
      color: GestionAnunciosColors.naranja50,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: GestionAnunciosColors.naranja200),
    );
  }

  /// BoxDecoration para contenedor de icono en estado sin conexión
  static BoxDecoration noConnectionIconContainerDecoration() {
    return BoxDecoration(
      color: GestionAnunciosColors.naranja50,
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// BoxDecoration para placeholder de imagen
  static BoxDecoration imagePlaceholderIconDecoration() {
    return BoxDecoration(
      color: GestionAnunciosColors.gris100,
      borderRadius: BorderRadius.circular(50),
    );
  }

  /// InputDecoration para campos de formulario
  static InputDecoration inputDecoration({
    required String label,
    required IconData icon,
    bool hasValue = false,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon, 
        color: hasValue ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris600,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: GestionAnunciosColors.gris200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: GestionAnunciosColors.rojo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: hasValue 
          ? Icon(Icons.check_circle, color: GestionAnunciosColors.verdePrimario, size: 20) 
          : null,
    );
  }

  /// ButtonStyle para el botón principal
  static ButtonStyle primaryButtonStyle({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: GestionAnunciosColors.rojo,
      disabledBackgroundColor: GestionAnunciosColors.gris300,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 4,
      shadowColor: GestionAnunciosColors.rojo.withOpacity(0.3),
    );
  }

  /// ButtonStyle para el botón de reintentar conexión
  static ButtonStyle retryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: GestionAnunciosColors.naranja600,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}