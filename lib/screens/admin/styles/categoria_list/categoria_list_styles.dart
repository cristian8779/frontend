// categoria_list_styles.dart
import 'package:flutter/material.dart';

class CategoriaTheme {
  // Colores principales
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color whiteColor = Colors.white;
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.black54;
  static const Color hintTextColor = Colors.blueGrey;
  
  // Colores de botones
  static const Color addButtonColor = Colors.red;
  static const Color viewMoreButtonColor = Colors.blue;
  static final Color? addButtonShade = Colors.red[400];
  static final Color? viewMoreButtonShade = Colors.blue[400];
  
  // Colores de sombra
  static const Color shadowLight = Colors.black12;
  static const Color shadowMedium = Colors.black26;
  static final Color shadowDark = Colors.black.withOpacity(0.05);
  
  // Colores de placeholder
  static final Color? placeholderBackground = Colors.grey[200];
  static final Color? placeholderIcon = Colors.grey[400];
  static final Color? placeholderText = Colors.grey[500];
  static final Color? placeholderTextSecondary = Colors.grey[600];
  
  // Iconos
  static const IconData categoryIcon = Icons.category_outlined;
  static const IconData addIcon = Icons.add;
  static const IconData viewMoreIcon = Icons.grid_view;
  static const IconData brokenImageIcon = Icons.broken_image;
  static const IconData refreshIcon = Icons.refresh;
}

class CategoriaDimensions {
  // Breakpoints
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  
  // Valores por defecto
  static const int defaultMaxItems = 8;
  static const double defaultSpacing = 8.0;
  static const double defaultBorderRadius = 16.0;
  static const double gridSpacing = 16.0;
  static const double cardPadding = 12.0;
  
  // Grid
  static const int mobileGridColumns = 2;
  static const int tabletGridColumns = 4;
  static const double gridAspectRatio = 0.85;
  
  // Función para obtener dimensiones responsivas
  static Map<String, double> getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= tabletBreakpoint;
    final isDesktop = screenWidth >= desktopBreakpoint;
    
    if (isDesktop) {
      return {
        'containerHeight': 240.0,
        'itemWidth': 160.0,
        'itemHeight': 160.0,
        'fontSize': 16.0,
        'iconSize': 50.0,
        'padding': 16.0,
      };
    } else if (isTablet) {
      return {
        'containerHeight': 225.0,
        'itemWidth': 145.0,
        'itemHeight': 145.0,
        'fontSize': 15.0,
        'iconSize': 45.0,
        'padding': 14.0,
      };
    } else {
      return {
        'containerHeight': 210.0,
        'itemWidth': 130.0,
        'itemHeight': 130.0,
        'fontSize': 14.0,
        'iconSize': 40.0,
        'padding': 12.0,
      };
    }
  }
  
  // Helpers para breakpoints
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  static int getGridCrossAxisCount(BuildContext context) {
    return isTablet(context) ? tabletGridColumns : mobileGridColumns;
  }
}

class CategoriaTextStyles {
  static TextStyle getTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['fontSize']! + 1,
      fontWeight: FontWeight.w600,
      color: CategoriaTheme.primaryTextColor,
    );
  }
  
  static TextStyle getSubtitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['fontSize']! - 1,
      color: CategoriaTheme.secondaryTextColor,
    );
  }
  
  static TextStyle getLabelStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['fontSize']!,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle getCategoryNameStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['fontSize']!,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle getCounterStyle(Map<String, double> dimensions) {
    return TextStyle(
      color: CategoriaTheme.whiteColor,
      fontSize: dimensions['fontSize']! - 2,
      fontWeight: FontWeight.bold,
    );
  }
  
  // Estilos para pantalla completa
  static const TextStyle appBarTitleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: CategoriaTheme.primaryTextColor,
  );
  
  static const TextStyle gridCategoryNameStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: CategoriaTheme.primaryTextColor,
  );
  
  static TextStyle getEmptyStateMainStyle() {
    return TextStyle(
      fontSize: 18,
      color: CategoriaTheme.placeholderTextSecondary,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle getEmptyStateSubStyle() {
    return TextStyle(
      fontSize: 14,
      color: CategoriaTheme.placeholderText,
    );
  }
}

class CategoriaDecorations {
  // Decoración del contenedor de categoría
  static BoxDecoration getCategoryItemDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(CategoriaDimensions.defaultBorderRadius),
      color: CategoriaTheme.placeholderBackground,
      boxShadow: const [
        BoxShadow(
          color: CategoriaTheme.shadowLight,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
  
  // Decoración del botón agregar
  static BoxDecoration getAddButtonDecoration() {
    return BoxDecoration(
      color: CategoriaTheme.addButtonShade,
      borderRadius: BorderRadius.circular(CategoriaDimensions.defaultBorderRadius),
      boxShadow: const [
        BoxShadow(
          color: CategoriaTheme.shadowMedium,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
  
  // Decoración del botón ver más
  static BoxDecoration getViewMoreButtonDecoration() {
    return BoxDecoration(
      color: CategoriaTheme.viewMoreButtonShade,
      borderRadius: BorderRadius.circular(CategoriaDimensions.defaultBorderRadius),
      boxShadow: const [
        BoxShadow(
          color: CategoriaTheme.shadowMedium,
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    );
  }
  
  // Decoración del contador en "Ver más"
  static BoxDecoration getCounterDecoration() {
    return BoxDecoration(
      color: CategoriaTheme.whiteColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
    );
  }
  
  // Decoración para las tarjetas de la grid
  static BoxDecoration getGridCardDecoration() {
    return BoxDecoration(
      color: CategoriaTheme.whiteColor,
      borderRadius: BorderRadius.circular(CategoriaDimensions.defaultBorderRadius),
      boxShadow: [
        BoxShadow(
          color: CategoriaTheme.shadowDark,
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // Decoración del placeholder de imagen
  static BoxDecoration getImagePlaceholderDecoration() {
    return BoxDecoration(
      color: CategoriaTheme.placeholderBackground,
    );
  }
}

class CategoriaLayout {
  // Padding del contador
  static const EdgeInsets counterPadding = EdgeInsets.symmetric(
    horizontal: 8, 
    vertical: 4
  );
  
  // Padding de las tarjetas de grid
  static const EdgeInsets gridPadding = EdgeInsets.all(CategoriaDimensions.gridSpacing);
  
  // Padding interno de las tarjetas
  static const EdgeInsets cardPadding = EdgeInsets.all(CategoriaDimensions.cardPadding);
  
  // Border radius para imágenes
  static const BorderRadius topBorderRadius = BorderRadius.vertical(
    top: Radius.circular(CategoriaDimensions.defaultBorderRadius),
  );
  
  static const BorderRadius fullBorderRadius = BorderRadius.all(
    Radius.circular(CategoriaDimensions.defaultBorderRadius),
  );
  
  // Grid delegate
  static SliverGridDelegate getGridDelegate(BuildContext context) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: CategoriaDimensions.getGridCrossAxisCount(context),
      crossAxisSpacing: CategoriaDimensions.gridSpacing,
      mainAxisSpacing: CategoriaDimensions.gridSpacing,
      childAspectRatio: CategoriaDimensions.gridAspectRatio,
    );
  }
}

class CategoriaConstants {
  // Textos
  static const String noCategoriesTitle = 'No se encontraron categorías.';
  static const String noCategoriesSubtitle = 'Puedes crear nuevas desde aquí';
  static const String addButtonLabel = 'Agregar';
  static const String viewMoreButtonLabel = 'Ver más';
  static const String allCategoriesTitle = 'Todas las categorías';
  static const String noCategoriesAvailable = 'No hay categorías disponibles';
  static const String createNewCategory = 'Toca el botón + para crear una nueva';
  static const String errorLoadingCategories = 'Error al cargar categorías: ';
  
  // Assets
  static const String defaultImagePath = 'assets/imagen.png';
  
  // Configuraciones
  static const int maxLines = 2;
  static const double emptyStateIconSize = 64;
  static const double gridImageIconSize = 48;
}