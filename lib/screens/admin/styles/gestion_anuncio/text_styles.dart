import 'package:flutter/material.dart';
import 'colors.dart';

/// Estilos de texto reutilizables para la gestión de anuncios
class GestionAnunciosTextStyles {
  
  // Títulos de sección
  static const TextStyle seccionTitulo = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.w600,
  );

  // Títulos de tarjetas
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  static const TextStyle cardTitleBold = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  // Subtítulos y descripciones
  static TextStyle cardSubtitle({required Color color}) {
    return TextStyle(
      fontSize: 12,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle subtituloGris = TextStyle(
    fontSize: 12,
    color: GestionAnunciosColors.gris500,
    fontWeight: FontWeight.w500,
  );

  static TextStyle subtituloVerde = TextStyle(
    fontSize: 12,
    color: GestionAnunciosColors.verdePrimario,
    fontWeight: FontWeight.w500,
  );

  // Textos de placeholder
  static TextStyle placeholder = TextStyle(
    color: GestionAnunciosColors.gris600,
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  static TextStyle placeholderSubtitle = TextStyle(
    color: GestionAnunciosColors.gris400,
    fontSize: 12,
  );

  // Textos de opciones (producto/categoría)
  static TextStyle opcionTexto({required bool isSelected}) {
    return TextStyle(
      color: isSelected 
          ? GestionAnunciosColors.rojo 
          : GestionAnunciosColors.gris700,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
    );
  }

  // Textos de botones
  static const TextStyle botonPrimario = TextStyle(
    color: Colors.white,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle botonSecundario = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  // Toast/SnackBar
  static const TextStyle toast = TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  // Estados sin conexión
  static TextStyle sinConexionTitulo = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: GestionAnunciosColors.gris800,
  );

  static TextStyle sinConexionDescripcion = TextStyle(
    fontSize: 16,
    color: GestionAnunciosColors.gris600,
    height: 1.5,
  );

  static TextStyle sinConexionCompacto = TextStyle(
    color: GestionAnunciosColors.naranja700,
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );

  static TextStyle sinConexionMensaje = TextStyle(
    color: GestionAnunciosColors.naranja800,
    fontWeight: FontWeight.w600,
    fontSize: 14,
  );

  static TextStyle sinConexionSubmensaje = TextStyle(
    color: GestionAnunciosColors.naranja700,
    fontSize: 12,
  );

  // Selector deshabilitado
  static TextStyle selectorDeshabilitadoTitulo = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: GestionAnunciosColors.gris600,
  );

  static TextStyle selectorDeshabilitadoSubtitulo = TextStyle(
    fontSize: 12,
    color: GestionAnunciosColors.gris500,
    fontWeight: FontWeight.w500,
  );

  // Fecha selector
  static const TextStyle fechaTitulo = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.black87,
  );

  // Item seleccionado
  static TextStyle itemNombre({required bool seleccionado}) {
    return TextStyle(
      fontSize: 16,
      fontWeight: seleccionado ? FontWeight.w600 : FontWeight.w500,
      color: seleccionado ? Colors.black87 : GestionAnunciosColors.gris600,
    );
  }
}