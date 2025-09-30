import 'package:flutter/material.dart';

/// Colores específicos para la pantalla de categorías
class CategoriaColors {
  // Colores principales
  static const Color background = Color(0xFFF8F8F8);
  static const Color cardBackground = Colors.white;
  static const Color primaryText = Colors.black87;
  static const Color secondaryText = Colors.black54;
  
  // Colores de estado
  static const Color errorColor = Colors.redAccent;
  static const Color successColor = Colors.green;
  static const Color warningColor = Colors.orange;
  static const Color infoColor = Colors.blue;
  
  // Colores específicos de elementos
  static final Color shimmerBase = Colors.grey[300]!;
  static final Color shimmerHighlight = Colors.grey[100]!;
  static final Color iconGrey = Colors.grey[600]!;
  static final Color backgroundGrey = Colors.grey[100]!;
  static final Color placeholderGrey = Colors.grey[50]!;
  static final Color iconPlaceholder = Colors.grey[400]!;
  static final Color textPlaceholder = Colors.grey[500]!;
  
  // Colores de stock
  static final Color stockWarningBackground = Colors.orange[100]!;
  static final Color stockWarningText = Colors.orange[700]!;
  
  // Colores de estados del producto
  static const Color outOfStockOverlay = Colors.black;
  static const Color outOfStockText = Colors.white;
  
  // Colores de botones
  static const Color primaryButton = Colors.blue;
  static const Color buttonText = Colors.white;
  
  // Colores de error
  static final Color errorBackground = Colors.red.withOpacity(0.1);
  static final Color emptyStateBackground = Colors.blue.withOpacity(0.1);
  static final Color emptyStateIcon = Colors.blue;
  
  // Sombras
  static BoxShadow get cardShadow => BoxShadow(
    color: Colors.black.withOpacity(0.06),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );
}