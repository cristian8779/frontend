import 'package:flutter/material.dart';
import 'categoria_colors.dart';
import 'categoria_dimensions.dart';

/// Estilos para widgets específicos de la pantalla de categorías
class CategoriaWidgetStyles {
  // Decoración para las cards de producto
  static BoxDecoration getProductCardDecoration() {
    return BoxDecoration(
      color: CategoriaColors.cardBackground,
      borderRadius: BorderRadius.circular(CategoriaDimensions.cardRadius),
      boxShadow: [CategoriaColors.cardShadow],
    );
  }
  
  // Decoración para el overlay de agotado
  static BoxDecoration getOutOfStockOverlay() {
    return BoxDecoration(
      color: CategoriaColors.outOfStockOverlay.withOpacity(0.7),
      borderRadius: BorderRadius.circular(CategoriaDimensions.cardRadius),
    );
  }
  
  // Decoración para el container de stock warning
  static BoxDecoration getStockWarningDecoration() {
    return BoxDecoration(
      color: CategoriaColors.stockWarningBackground,
      borderRadius: BorderRadius.circular(CategoriaDimensions.badgeRadius),
    );
  }
  
  // Decoración para el placeholder de imagen
  static BoxDecoration getImagePlaceholderDecoration() {
    return BoxDecoration(
      color: CategoriaColors.placeholderGrey,
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  // Decoración para el container de error
  static BoxDecoration getErrorIconDecoration(bool isTablet) {
    return BoxDecoration(
      color: CategoriaColors.errorBackground,
      shape: BoxShape.circle,
    );
  }
  
  // Decoración para el container de estado vacío
  static BoxDecoration getEmptyStateIconDecoration(bool isTablet) {
    return BoxDecoration(
      color: CategoriaColors.emptyStateBackground,
      shape: BoxShape.circle,
    );
  }
  
  // Decoración para el mensaje de fin de productos
  static BoxDecoration getEndMessageDecoration() {
    return BoxDecoration(
      color: CategoriaColors.backgroundGrey,
      borderRadius: BorderRadius.circular(8),
    );
  }
  
  // Estilo para botones principales
  static ButtonStyle getPrimaryButtonStyle(bool isTablet) {
    return ElevatedButton.styleFrom(
      backgroundColor: CategoriaColors.primaryButton,
      foregroundColor: CategoriaColors.buttonText,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 28 : 24,
        vertical: isTablet ? 16 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(CategoriaDimensions.buttonRadius),
      ),
    );
  }
  
  // Estilo para botones secundarios
  static ButtonStyle getSecondaryButtonStyle(bool isTablet) {
    return TextButton.styleFrom(
      foregroundColor: CategoriaColors.infoColor,
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20,
        vertical: isTablet ? 12 : 8,
      ),
    );
  }
  
  // Padding para el stock warning badge
  static EdgeInsets getStockWarningPadding(bool isTablet) {
    return EdgeInsets.symmetric(
      horizontal: isTablet ? 8 : 6, 
      vertical: isTablet ? 3 : 2,
    );
  }
  
  // Tamaños de iconos
  static double getErrorIconSize(bool isTablet) => isTablet ? 56 : 48;
  static double getEmptyStateIconSize(bool isTablet) => isTablet ? 72 : 64;
  static double getImagePlaceholderIconSize(double screenWidth) {
    return screenWidth >= 1200 ? 48 : screenWidth >= 600 ? 44 : 40;
  }
  static double getEndMessageIconSize() => 16;
  
  // Espaciados específicos para estados
  static double getStateIconSpacing(bool isTablet) => isTablet ? 20 : 16;
  static double getStateDescriptionSpacing(bool isTablet) => isTablet ? 12 : 8;
  static double getStateButtonSpacing(bool isTablet) => isTablet ? 28 : 24;
  static double getImagePlaceholderTextSpacing(bool isTablet) => isTablet ? 10 : 8;
}