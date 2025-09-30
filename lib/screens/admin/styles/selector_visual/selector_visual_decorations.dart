import 'package:flutter/material.dart';
import 'selector_visual_colors.dart';
import 'selector_visual_text_styles.dart';

class SelectorVisualDecorations {
  // Contenedor de loading
  static BoxDecoration loadingContainer = BoxDecoration(
    color: SelectorVisualColors.cardBackground,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: SelectorVisualColors.shadowColor,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Contenedor de estado vacío
  static BoxDecoration emptyContainer = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        SelectorVisualColors.emptyGradientStart,
        SelectorVisualColors.emptyGradientEnd,
      ],
    ),
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: SelectorVisualColors.shadowColorLight,
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );
  
  // Contenedor de búsqueda
  static BoxDecoration searchContainer = BoxDecoration(
    color: SelectorVisualColors.cardBackground,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: SelectorVisualColors.shadowColor,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Decoración del ícono de búsqueda
  static BoxDecoration searchIconDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [
        SelectorVisualColors.searchIconGradientStart,
        SelectorVisualColors.searchIconGradientEnd,
      ],
    ),
    borderRadius: BorderRadius.circular(12),
  );
  
  // Input decoration de búsqueda
  static InputDecoration searchInputDecoration(String tipo, bool hasText) {
    return InputDecoration(
      hintText: 'Buscar $tipo...',
      hintStyle: SelectorVisualTextStyles.searchHint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(8),
        decoration: searchIconDecoration,
        child: const Icon(
          Icons.search_rounded,
          color: SelectorVisualColors.searchIconColor,
          size: 20,
        ),
      ),
      suffixIcon: hasText
          ? IconButton(
              icon: const Icon(
                Icons.clear_rounded,
                color: SelectorVisualColors.searchClearIcon,
              ),
              onPressed: null, // Se asigna en el widget
            )
          : null,
      filled: true,
      fillColor: SelectorVisualColors.cardBackground,
      contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(
          color: SelectorVisualColors.searchBorderFocus,
          width: 2,
        ),
      ),
    );
  }
  
  // Decoración de sin resultados
  static BoxDecoration noResultsContainer = BoxDecoration(
    color: SelectorVisualColors.noResultsShadow,
    shape: BoxShape.circle,
  );
  
  // Decoración de tarjeta
  static BoxDecoration cardDecoration = BoxDecoration(
    color: SelectorVisualColors.cardBackground,
    borderRadius: BorderRadius.circular(24),
    boxShadow: [
      BoxShadow(
        color: SelectorVisualColors.shadowColor,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );
  
  // Decoración de placeholder de imagen
  static BoxDecoration imagePlaceholder = BoxDecoration(
    color: SelectorVisualColors.cardImagePlaceholder,
  );
  
  // Botón cerrar
  static BoxDecoration closeButtonDecoration = BoxDecoration(
    color: SelectorVisualColors.closeButtonBackground,
    borderRadius: BorderRadius.circular(12),
  );
  
  // SnackBar shape
  static RoundedRectangleBorder snackBarShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );
}