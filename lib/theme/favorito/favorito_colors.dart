import 'package:flutter/material.dart';

/// Colores específicos para la pantalla de favoritos
class FavoritoColors {
  // Colores principales
  static const Color primaryColor = Color(0xFF6C5CE7);      // Púrpura suave
  static const Color accentColor = Color(0xFFA29BFE);       // Púrpura claro
  static const Color backgroundColor = Color(0xFFFBFBFC);    // Blanco cálido
  static const Color cardColor = Colors.white;              // Blanco puro
  
  // Colores de texto
  static const Color textColor = Color(0xFF2D3436);         // Gris oscuro
  static const Color subtextColor = Color(0xFF636E72);      // Gris medio
  
  // Colores de estado
  static const Color successColor = Color(0xFF00B894);      // Verde menta
  static const Color warningColor = Color(0xFFE17055);      // Coral suave
  static const Color errorColor = Color(0xFFFF6B9D);        // Rosa suave
  static const Color favoriteColor = Color(0xFFE74C3C);     // Rojo para favoritos
  
  // Gradientes
  static LinearGradient get authLoadingGradient => const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [cardColor, backgroundColor],
  );
  
  static LinearGradient get favoriteIconGradient => LinearGradient(
    colors: [
      favoriteColor.withOpacity(0.1),
      favoriteColor.withOpacity(0.05),
    ],
  );
  
  static LinearGradient get successGradient => LinearGradient(
    colors: [successColor, successColor.withOpacity(0.8)],
  );
  
  static LinearGradient get errorGradient => LinearGradient(
    colors: [
      errorColor.withOpacity(0.1),
      errorColor.withOpacity(0.05),
    ],
  );
  
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryColor, primaryColor.withOpacity(0.8)],
  );
  
  static LinearGradient get discountGradient => LinearGradient(
    colors: [successColor, successColor.withOpacity(0.8)],
  );
  
  // Sombras
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: primaryColor.withOpacity(0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get favoriteIconShadow => [
    BoxShadow(
      color: favoriteColor.withOpacity(0.2),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];
  
  static List<BoxShadow> get successShadow => [
    BoxShadow(
      color: successColor.withOpacity(0.2),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get errorShadow => [
    BoxShadow(
      color: errorColor.withOpacity(0.15),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];
}