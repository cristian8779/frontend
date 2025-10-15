import 'package:flutter/material.dart';

class AppDimensions {
  // Breakpoints ampliados
  static const double extraSmallScreen = 320.0;  // Teléfonos muy pequeños
  static const double smallScreen = 360.0;        // Teléfonos pequeños
  static const double mediumScreen = 600.0;       // Teléfonos grandes / Tablets pequeñas
  static const double largeScreen = 900.0;        // Tablets
  static const double extraLargeScreen = 1200.0; // Tablets grandes / Escritorio
  static const double xxlScreen = 1600.0;         // Escritorio grande
  
  // Función auxiliar para escalar valores de forma fluida
  static double _scaleValue(double screenWidth, double minValue, double maxValue, {
    double minScreen = extraSmallScreen,
    double maxScreen = xxlScreen,
  }) {
    if (screenWidth <= minScreen) return minValue;
    if (screenWidth >= maxScreen) return maxValue;
    
    final progress = (screenWidth - minScreen) / (maxScreen - minScreen);
    return minValue + (maxValue - minValue) * progress;
  }
  
  // Padding y márgenes con escala fluida
  static double getScreenPadding(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 32.0, maxScreen: extraLargeScreen);
  }
  
  static double getHorizontalPadding(double screenWidth) {
    return _scaleValue(screenWidth, 16.0, 48.0, maxScreen: extraLargeScreen);
  }
  
  static double getCardPadding(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 24.0, maxScreen: largeScreen);
  }
  
  static double getContainerPadding(double screenWidth) {
    return _scaleValue(screenWidth, 16.0, 32.0, maxScreen: largeScreen);
  }
  
  // Tamaños de fuente escalables
  static double getSearchFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 14.0, 18.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getLabelFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 17.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getButtonTextFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 11.0, 14.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getTitleFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 16.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getNumberFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 32.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getSubtitleFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 15.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getHeaderFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 18.0, 28.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getEmptyStateTitleFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 18.0, 26.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getEmptyStateSubtitleFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 14.0, 18.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getErrorTitleFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 28.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getErrorMessageFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 14.0, 18.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getAppBarFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 18.0, 24.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getBodyFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 14.0, 16.0, maxScreen: largeScreen).roundToDouble();
  }
  
  static double getCaptionFontSize(double screenWidth) {
    return _scaleValue(screenWidth, 11.0, 13.0, maxScreen: largeScreen).roundToDouble();
  }
  
  // Tamaños de iconos escalables
  static double getSearchIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 28.0, maxScreen: largeScreen);
  }
  
  static double getStatsIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 24.0, 40.0, maxScreen: largeScreen);
  }
  
  static double getFilterIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 18.0, 24.0, maxScreen: largeScreen);
  }
  
  static double getEmptyStateIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 40.0, 80.0, maxScreen: largeScreen);
  }
  
  static double getErrorIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 40.0, 80.0, maxScreen: largeScreen);
  }
  
  static double getActionIconSize(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 28.0, maxScreen: largeScreen);
  }
  
  // Border radius - versiones escalables y constantes para compatibilidad
  static double getSearchRadius(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 30.0, maxScreen: largeScreen);
  }
  
  static double getCardRadius(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 20.0, maxScreen: largeScreen);
  }
  
  static double getContainerRadius(double screenWidth) {
    return _scaleValue(screenWidth, 16.0, 24.0, maxScreen: largeScreen);
  }
  
  static double getButtonRadius(double screenWidth) {
    return _scaleValue(screenWidth, 20.0, 30.0, maxScreen: largeScreen);
  }
  
  static double getIconContainerRadius(double screenWidth) {
    return _scaleValue(screenWidth, 10.0, 16.0, maxScreen: largeScreen);
  }
  
  // Constantes para compatibilidad con código legacy
  static const double searchRadius = 25.0;
  static const double cardRadius = 16.0;
  static const double containerRadius = 20.0;
  static const double buttonRadius = 25.0;
  static const double iconContainerRadius = 12.0;
  
  // Espaciado escalable
  static double getVerticalSpacing(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 20.0, maxScreen: largeScreen);
  }
  
  static double getSectionSpacing(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 32.0, maxScreen: largeScreen);
  }
  
  static double getEmptyStatePadding(double screenWidth) {
    return _scaleValue(screenWidth, 16.0, 48.0, maxScreen: largeScreen);
  }
  
  static double getIconPadding(double screenWidth) {
    return _scaleValue(screenWidth, 12.0, 28.0, maxScreen: largeScreen);
  }
  
  static double getItemSpacing(double screenWidth) {
    return _scaleValue(screenWidth, 8.0, 16.0, maxScreen: largeScreen);
  }
  
  // Grid mejorado con más breakpoints
  static int getCrossAxisCount(double screenWidth) {
    if (screenWidth < extraSmallScreen) return 1;
    if (screenWidth < smallScreen) return 1;
    if (screenWidth < mediumScreen) return 2;
    if (screenWidth < largeScreen) return 3;
    if (screenWidth < extraLargeScreen) return 4;
    if (screenWidth < xxlScreen) return 5;
    return 6;
  }
  
  static double getGridSpacing(double screenWidth) {
    return _scaleValue(screenWidth, 8.0, 24.0, maxScreen: extraLargeScreen);
  }
  
  static double getChildAspectRatio(double screenWidth) {
    if (screenWidth < extraSmallScreen) return 0.9;
    if (screenWidth < smallScreen) return 0.85;
    if (screenWidth < mediumScreen) return 0.8;
    if (screenWidth < largeScreen) return 0.75;
    return 0.8;
  }
  
  // Alturas adaptativas
  static double getEmptyStateHeight(double screenWidth, double screenHeight) {
    // Ajustar según ambas dimensiones
    final baseHeight = _scaleValue(screenWidth, 200.0, 500.0, maxScreen: largeScreen);
    final maxHeight = screenHeight * 0.5; // Máximo 50% de la altura de pantalla
    return baseHeight.clamp(200.0, maxHeight);
  }
  
  static double getErrorStateHeight(double screenWidth) {
    return _scaleValue(screenWidth, 350.0, 550.0, maxScreen: largeScreen);
  }
  
  static double getAppBarHeight(double screenWidth) {
    return _scaleValue(screenWidth, 90.0, 140.0, maxScreen: largeScreen);
  }
  
  static double getListItemHeight(double screenWidth) {
    return _scaleValue(screenWidth, 70.0, 90.0, maxScreen: largeScreen);
  }
  
  // Anchos máximos para contenido en pantallas grandes
  static double getMaxContentWidth(double screenWidth) {
    if (screenWidth < largeScreen) return screenWidth;
    if (screenWidth < extraLargeScreen) return 1000.0;
    if (screenWidth < xxlScreen) return 1400.0;
    return 1800.0;
  }
  
  // Verificadores mejorados
  static bool isExtraSmallScreen(double screenWidth) {
    return screenWidth < extraSmallScreen;
  }
  
  static bool isSmallScreen(double screenWidth) {
    return screenWidth < smallScreen;
  }
  
  static bool isMediumScreen(double screenWidth) {
    return screenWidth >= mediumScreen && screenWidth < largeScreen;
  }
  
  static bool isLargeScreen(double screenWidth) {
    return screenWidth >= largeScreen && screenWidth < extraLargeScreen;
  }
  
  static bool isExtraLargeScreen(double screenWidth) {
    return screenWidth >= extraLargeScreen;
  }
  
  static bool isVerySmallScreen(double screenHeight) {
    return screenHeight < 600;
  }
  
  static bool isShortScreen(double screenHeight) {
    return screenHeight < 700;
  }
  
  // Tipo de dispositivo
  static DeviceType getDeviceType(double screenWidth) {
    if (screenWidth < smallScreen) return DeviceType.mobile;
    if (screenWidth < mediumScreen) return DeviceType.mobileLarge;
    if (screenWidth < largeScreen) return DeviceType.tablet;
    if (screenWidth < extraLargeScreen) return DeviceType.desktop;
    return DeviceType.desktopLarge;
  }
  
  // Orientación
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  // Densidad de píxeles
  static double getScaleFactor(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    if (pixelRatio > 3.0) return 0.9; // Pantallas muy densas
    if (pixelRatio > 2.0) return 1.0; // Pantallas normales
    return 1.1; // Pantallas de baja densidad
  }
}

enum DeviceType {
  mobile,
  mobileLarge,
  tablet,
  desktop,
  desktopLarge,
}