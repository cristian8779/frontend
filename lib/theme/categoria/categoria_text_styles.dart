import 'package:flutter/material.dart';
import 'categoria_colors.dart';

/// Estilos de texto para la pantalla de categorías
class CategoriaTextStyles {
  // Estilos del AppBar
  static TextStyle getAppBarTitle(double screenWidth) {
    return TextStyle(
      color: CategoriaColors.primaryText,
      fontWeight: FontWeight.w600,
      fontSize: screenWidth < 600 ? 18 : 20,
    );
  }
  
  // Estilos de las cards de producto
  static TextStyle getProductTitle(double screenWidth) {
    final fontSize = screenWidth >= 1200 ? 15.0 : screenWidth >= 600 ? 14.0 : 13.0;
    return TextStyle(
      color: CategoriaColors.primaryText,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
  }
  
  static TextStyle getProductPrice(double screenWidth) {
    final fontSize = screenWidth >= 1200 ? 18.0 : screenWidth >= 600 ? 17.0 : 16.0;
    return TextStyle(
      color: CategoriaColors.primaryText,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle getStockWarning(double screenWidth) {
    final fontSize = screenWidth >= 1200 ? 11.0 : screenWidth >= 600 ? 10.0 : 9.0;
    return TextStyle(
      color: CategoriaColors.stockWarningText,
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle getOutOfStockBadge(double screenWidth) {
    final fontSize = screenWidth >= 1200 ? 14.0 : screenWidth >= 600 ? 13.0 : 12.0;
    return TextStyle(
      color: CategoriaColors.outOfStockText,
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
    );
  }
  
  static TextStyle getPlaceholderText(bool isTablet) {
    return TextStyle(
      color: CategoriaColors.textPlaceholder,
      fontSize: isTablet ? 14 : 12,
    );
  }
  
  // Estilos de estados de error y vacío
  static TextStyle getErrorTitle(bool isTablet) {
    return TextStyle(
      fontSize: isTablet ? 20 : 18,
      fontWeight: FontWeight.w600,
      color: CategoriaColors.primaryText,
    );
  }
  
  static TextStyle getErrorDescription(bool isTablet) {
    return TextStyle(
      fontSize: isTablet ? 16 : 14,
      color: CategoriaColors.iconGrey,
    );
  }
  
  static TextStyle getEmptyStateTitle(bool isTablet) {
    return TextStyle(
      fontSize: isTablet ? 20 : 18,
      fontWeight: FontWeight.w600,
      color: CategoriaColors.primaryText,
    );
  }
  
  static TextStyle getEmptyStateDescription(bool isTablet) {
    return TextStyle(
      fontSize: isTablet ? 16 : 14,
      color: CategoriaColors.iconGrey,
    );
  }
  
  // Estilo del mensaje de fin de productos
  static TextStyle getEndMessage(double screenWidth) {
    return TextStyle(
      color: CategoriaColors.iconGrey,
      fontSize: screenWidth < 600 ? 14 : 16,
    );
  }
}