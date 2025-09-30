import 'package:flutter/material.dart';

class SelectorVisualColors {
  // Colores de fondo
  static final Color backgroundColor = Colors.grey[50]!;
  static const Color appBarBackground = Colors.white;
  static const Color appBarForeground = Colors.black87;
  static const Color cardBackground = Colors.white;
  
  // Colores de búsqueda
  static final Color searchHintColor = Colors.grey[400]!;
  static final Color searchIconGradientStart = Colors.blue[400]!;
  static final Color searchIconGradientEnd = Colors.blue[600]!;
  static final Color searchBorderFocus = Colors.blue[400]!;
  static const Color searchIconColor = Colors.white;
  static const Color searchClearIcon = Colors.grey;
  
  // Colores de loading
  static final Color loadingIndicator = Colors.blue[600]!;
  static final Color loadingTextColor = Colors.grey[700]!;
  
  // Colores de estado vacío
  static final Color emptyIconColor = Colors.grey[400]!;
  static final Color emptyGradientStart = Colors.grey[100]!;
  static final Color emptyGradientEnd = Colors.grey[50]!;
  static const Color emptyTitleColor = Colors.black87;
  static final Color emptySubtitleColor = Colors.grey[600]!;
  
  // Colores de error
  static const Color errorIcon = Colors.white;
  static final Color errorBackground = Colors.red[600]!;
  static const Color errorActionText = Colors.white;
  
  // Colores de búsqueda sin resultados
  static const Color noResultsIcon = Colors.orange;
  static const Color noResultsBackground = Colors.orange;
  static const Color noResultsTitle = Colors.black87;
  static final Color noResultsSubtitle = Colors.grey[600]!;
  
  // Colores de contador
  static final Color counterTextColor = Colors.grey[600]!;
  
  // Colores de tarjetas
  static final Color cardImagePlaceholder = Colors.grey[100]!;
  static final Color cardIconColor = Colors.grey[400]!;
  static final Color cardImageLoadingIndicator = Colors.blue[400]!;
  static const Color cardTitleColor = Colors.black87;
  
  // Colores de botón cerrar
  static final Color closeButtonBackground = Colors.grey[100]!;
  
  // Sombras
  static Color shadowColor = Colors.black.withOpacity(0.08);
  static Color shadowColorLight = Colors.grey.withOpacity(0.2);
  static Color noResultsShadow = Colors.orange.withOpacity(0.1);
}