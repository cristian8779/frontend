import 'package:flutter/material.dart';

/// Dimensiones y espaciados específicos para la pantalla de favoritos
class FavoritoDimensions {
  // Espaciados generales
  static EdgeInsets screenPadding(bool isTablet) => EdgeInsets.all(isTablet ? 32 : 24);
  static EdgeInsets cardPadding(bool isTablet) => EdgeInsets.all(isTablet ? 18 : 14);
  static EdgeInsets cardPaddingTablet(bool isTablet) => EdgeInsets.all(isTablet ? 16 : 14);
  static EdgeInsets listPadding = const EdgeInsets.all(24);
  static EdgeInsets cardMargin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
  
  // Espaciados para contenido
  static EdgeInsets dialogContentPadding = const EdgeInsets.fromLTRB(24, 0, 24, 24);
  static EdgeInsets dialogTitlePadding = const EdgeInsets.all(24);
  static EdgeInsets dialogActionsPadding = const EdgeInsets.all(20);
  static EdgeInsets snackbarMargin(BuildContext context) => EdgeInsets.all(MediaQuery.of(context).size.width * 0.04);
  
  // Tamaños de imágenes
  static double imageSize(double screenWidth) => screenWidth > 400 ? 100 : 85;
  static const double imageTabletSize = 150;
  
  // Tamaños de iconos
  static double appBarIconSize = 20;
  static double favoriteIconSize(bool isTablet) => isTablet ? 80 : 64;
  static double emptyStateIconSize(bool isTablet) => isTablet ? 100 : 80;
  static double errorIconSize(bool isTablet) => isTablet ? 80 : 64;
  static double buttonIconSize = 18;
  static double smallIconSize = 20;
  static double cartIconSize = 20;
  static double deleteIconSize = 20;
  static double snackbarIconSize = 20;
  
  // Tamaños de botones
  static double buttonHeight(bool isTablet) => isTablet ? 64 : 56;
  static double smallButtonSize = 40;
  static Size buttonSize(bool isTablet) => Size(isTablet ? 160 : double.infinity, isTablet ? 56 : 56);
  static const Size iconButtonSize = Size(40, 40);
  
  // Bordes redondeados
  static const double cardBorderRadius = 20;
  static const double cardBorderRadiusTablet = 24;
  static const double buttonBorderRadius = 16;
  static const double smallBorderRadius = 12;
  static const double dialogBorderRadius = 24;
  static const double snackbarBorderRadius = 16;
  static const double imageBorderRadius = 16;
  
  // Elevaciones
  static const double cardElevation = 2;
  static const double cardElevationTablet = 3;
  static const double buttonElevation = 3;
  static const double snackbarElevation = 6;
  
  // Espacios entre elementos
  static const SizedBox smallVerticalSpace = SizedBox(height: 8);
  static const SizedBox mediumVerticalSpace = SizedBox(height: 16);
  static const SizedBox largeVerticalSpace = SizedBox(height: 24);
  static const SizedBox extraLargeVerticalSpace = SizedBox(height: 32);
  static SizedBox adaptiveVerticalSpace(bool isTablet) => SizedBox(height: isTablet ? 32 : 24);
  
  static const SizedBox smallHorizontalSpace = SizedBox(width: 8);
  static const SizedBox mediumHorizontalSpace = SizedBox(width: 16);
  static const SizedBox largeHorizontalSpace = SizedBox(width: 24);
  static SizedBox adaptiveHorizontalSpace(double screenWidth) => SizedBox(width: screenWidth > 400 ? 16 : 12);
  
  // Configuración de grids
  static const SliverGridDelegateWithFixedCrossAxisCount tabletGridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.85,
    crossAxisSpacing: 20,
    mainAxisSpacing: 20,
  );
  
  // Configuración de animaciones
  static const Duration shortAnimationDuration = Duration(milliseconds: 300);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 800);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1800);
  static const Duration staggerAnimationDuration = Duration(milliseconds: 1200);
  
  // Delays
  static const Duration shortDelay = Duration(milliseconds: 200);
  static const Duration mediumDelay = Duration(milliseconds: 600);
  static const Duration longDelay = Duration(milliseconds: 800);
  
  // Configuración de stroke width
  static const double circularProgressStrokeWidth = 3.5;
  static const double shimmerProgressStrokeWidth = 2.5;
  static const double smallProgressStrokeWidth = 2.0;
  
  // Opacidades
  static const double shimmerBaseOpacity = 0.3;
  static const double shimmerHighlightOpacity = 1.0;
  static const double disabledOpacity = 0.3;
  static const double overlayOpacity = 0.1;
  
  // Configuraciones específicas para responsive
  static bool isTablet(BuildContext context) => MediaQuery.of(context).size.width > 600;
  static bool isLargeScreen(BuildContext context) => MediaQuery.of(context).size.width > 400;
  
  // Alturas específicas
  static double screenHeightWithoutAppBar(BuildContext context) => 
    MediaQuery.of(context).size.height - 120;
}