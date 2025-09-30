import 'package:flutter/material.dart';
import 'selector_visual_colors.dart';

class SelectorVisualTextStyles {
  // AppBar
  static const TextStyle appBarTitle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 20,
  );
  
  // Loading
  static TextStyle loadingText = TextStyle(
    fontSize: 16,
    color: SelectorVisualColors.loadingTextColor,
    fontWeight: FontWeight.w600,
  );
  
  // Estado vacío
  static const TextStyle emptyTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: SelectorVisualColors.emptyTitleColor,
  );
  
  static TextStyle emptySubtitle = TextStyle(
    fontSize: 16,
    color: SelectorVisualColors.emptySubtitleColor,
    fontWeight: FontWeight.w400,
  );
  
  // Búsqueda
  static const TextStyle searchInput = TextStyle(fontSize: 16);
  
  static TextStyle searchHint = TextStyle(
    color: SelectorVisualColors.searchHintColor,
    fontSize: 16,
  );
  
  // Contador de resultados
  static TextStyle counterText = TextStyle(
    fontSize: 14,
    color: SelectorVisualColors.counterTextColor,
    fontWeight: FontWeight.w500,
  );
  
  // Sin resultados
  static const TextStyle noResultsTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: SelectorVisualColors.noResultsTitle,
  );
  
  static TextStyle noResultsSubtitle = TextStyle(
    fontSize: 14,
    color: SelectorVisualColors.noResultsSubtitle,
  );
  
  // Tarjetas
  static const TextStyle cardTitle = TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: 14,
    color: SelectorVisualColors.cardTitleColor,
    height: 1.2,
  );
  
  static TextStyle cardImageError = TextStyle(
    fontSize: 10,
    color: SelectorVisualColors.cardIconColor,
  );
  
  static TextStyle cardNoImage = TextStyle(
    fontSize: 10,
    color: SelectorVisualColors.cardIconColor,
  );
}