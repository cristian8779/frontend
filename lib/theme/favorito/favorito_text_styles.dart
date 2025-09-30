import 'package:flutter/material.dart';
import 'favorito_colors.dart';

/// Estilos de texto específicos para la pantalla de favoritos
class FavoritoTextStyles {
  // Estilos de título
  static TextStyle get appBarTitle => const TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 22,
    letterSpacing: -0.5,
  );
  
  // Estilos de carga
  static TextStyle loadingTitle(bool isTablet) => TextStyle(
    color: FavoritoColors.textColor,
    fontSize: isTablet ? 18 : 16,
    fontWeight: FontWeight.w600,
  );
  
  static TextStyle loadingSubtitle(bool isTablet) => TextStyle(
    color: FavoritoColors.subtextColor,
    fontSize: isTablet ? 15 : 14,
  );
  
  // Estilos de error
  static TextStyle errorTitle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 28 : 22,
    fontWeight: FontWeight.bold,
    color: FavoritoColors.textColor,
  );
  
  static TextStyle errorMessage(bool isTablet) => TextStyle(
    color: FavoritoColors.subtextColor,
    fontSize: isTablet ? 16 : 14,
    height: 1.4,
  );
  
  // Estilos de estado vacío
  static TextStyle emptyStateTitle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 32 : 24,
    fontWeight: FontWeight.bold,
    color: FavoritoColors.textColor,
  );
  
  static TextStyle emptyStateDescription(bool isTablet) => TextStyle(
    fontSize: isTablet ? 18 : 16,
    color: FavoritoColors.subtextColor,
    height: 1.5,
  );
  
  // Estilos de botones
  static TextStyle buttonText(bool isTablet) => TextStyle(
    fontSize: isTablet ? 18 : 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle buttonLabel = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 16,
  );
  
  static const TextStyle elevatedButtonLabel = TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: 16,
  );
  
  // Estilos de productos
  static const TextStyle productNameTablet = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: FavoritoColors.textColor,
    letterSpacing: -0.2,
  );
  
  static TextStyle productNameMobile(double screenWidth) => TextStyle(
    fontSize: screenWidth > 400 ? 16 : 15,
    fontWeight: FontWeight.w600,
    color: FavoritoColors.textColor,
    letterSpacing: -0.2,
  );
  
  static const TextStyle productPriceTablet = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: FavoritoColors.textColor,
    letterSpacing: -0.3,
  );
  
  static TextStyle productPriceMobile(double screenWidth) => TextStyle(
    fontSize: screenWidth > 400 ? 18 : 16,
    fontWeight: FontWeight.w800,
    color: FavoritoColors.textColor,
    letterSpacing: -0.3,
  );
  
  // Estilos de badges y descuentos
  static const TextStyle discountBadge = TextStyle(
    color: Colors.white,
    fontSize: 12,
    fontWeight: FontWeight.bold,
  );
  
  static const TextStyle discountBadgeSmall = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.bold,
  );
  
  // Estilos de contadores
  static TextStyle favoriteCounter(bool isTablet) => TextStyle(
    fontSize: isTablet ? 16 : 15,
    fontWeight: FontWeight.w700,
    color: FavoritoColors.favoriteColor,
  );
  
  // Estilos de diálogos
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: FavoritoColors.textColor,
  );
  
  static const TextStyle dialogContent = TextStyle(
    fontSize: 16,
    color: FavoritoColors.subtextColor,
    height: 1.5,
  );
  
  // Estilos de snackbar
  static const TextStyle snackbarText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
}