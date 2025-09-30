import 'package:flutter/material.dart';
import 'favorito_colors.dart';

/// Decoraciones y estilos de contenedores para la pantalla de favoritos
class FavoritoDecorations {
  // Decoración de cards
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: FavoritoColors.cardColor,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.primaryColor.withOpacity(0.06),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get cardDecorationTablet => BoxDecoration(
    color: FavoritoColors.cardColor,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.primaryColor.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Decoración de contenedores de iconos
  static BoxDecoration pulseIconDecoration(bool isTablet) => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        FavoritoColors.favoriteColor.withOpacity(0.1),
        FavoritoColors.favoriteColor.withOpacity(0.05),
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.favoriteColor.withOpacity(0.2),
        blurRadius: 30,
        offset: const Offset(0, 15),
      ),
    ],
  );
  
  static BoxDecoration emptyStateIconDecoration(bool isTablet) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        FavoritoColors.favoriteColor.withOpacity(0.15),
        FavoritoColors.favoriteColor.withOpacity(0.05),
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.favoriteColor.withOpacity(0.15),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ],
  );
  
  // Decoración de contenedores de error
  static BoxDecoration get errorIconDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        FavoritoColors.errorColor.withOpacity(0.1),
        FavoritoColors.errorColor.withOpacity(0.05),
      ],
    ),
    shape: BoxShape.circle,
    border: Border.all(color: FavoritoColors.errorColor.withOpacity(0.2), width: 2),
  );
  
  static BoxDecoration get errorMessageDecoration => BoxDecoration(
    color: FavoritoColors.errorColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: FavoritoColors.errorColor.withOpacity(0.1)),
  );
  
  // Decoración de badges y elementos pequeños
  static BoxDecoration get favoriteCounterDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        FavoritoColors.favoriteColor.withOpacity(0.2),
        FavoritoColors.favoriteColor.withOpacity(0.1),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
    border: Border.all(
      color: FavoritoColors.favoriteColor.withOpacity(0.3),
      width: 1.5,
    ),
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.favoriteColor.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  static BoxDecoration get discountBadgeDecoration => BoxDecoration(
    gradient: FavoritoColors.discountGradient,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.successColor.withOpacity(0.3),
        blurRadius: 6,
        offset: const Offset(0, 3),
      ),
    ],
  );
  
  static BoxDecoration get discountBadgeDecorationSmall => BoxDecoration(
    gradient: FavoritoColors.discountGradient,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: FavoritoColors.successColor.withOpacity(0.3),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Decoración de botones
  static BoxDecoration get deleteButtonDecoration => BoxDecoration(
    color: FavoritoColors.backgroundColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(
      color: FavoritoColors.subtextColor.withOpacity(0.2),
      width: 1,
    ),
  );
  
  static BoxDecoration cartButtonDecoration(bool disponible) => BoxDecoration(
    gradient: disponible 
      ? FavoritoColors.successGradient
      : LinearGradient(
          colors: [
            FavoritoColors.subtextColor.withOpacity(0.3), 
            FavoritoColors.subtextColor.withOpacity(0.2)
          ],
        ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: disponible ? [
      BoxShadow(
        color: FavoritoColors.successColor.withOpacity(0.2),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ] : null,
  );
  
  static BoxDecoration get whiteButtonDecoration => BoxDecoration(
    color: FavoritoColors.cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Decoración de contenedores de imagen
  static BoxDecoration get imageContainerDecoration => BoxDecoration(
    color: FavoritoColors.backgroundColor,
    borderRadius: BorderRadius.circular(16),
  );
  
  // Decoración de diálogos
  static BoxDecoration get dialogIconDecoration => BoxDecoration(
    gradient: LinearGradient(
      colors: [
        FavoritoColors.errorColor.withOpacity(0.15),
        FavoritoColors.errorColor.withOpacity(0.05),
      ],
    ),
    borderRadius: BorderRadius.circular(16),
  );
  
  // Decoración de snackbar
  static BoxDecoration get snackbarIconDecoration => BoxDecoration(
    color: Colors.white.withOpacity(0.2),
    borderRadius: BorderRadius.circular(12),
  );
  
  // Formas redondeadas
  static RoundedRectangleBorder get cardShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );
  
  static RoundedRectangleBorder get cardShapeTablet => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  );
  
  static RoundedRectangleBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  );
  
  static RoundedRectangleBorder buttonShape(bool isTablet) => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
  );
  
  static RoundedRectangleBorder get smallButtonShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
  
  static RoundedRectangleBorder get snackbarShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
}