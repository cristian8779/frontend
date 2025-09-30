import 'package:flutter/material.dart';
import 'favorito_colors.dart';
import 'favorito_text_styles.dart';
import 'favorito_decorations.dart';
import 'favorito_dimensions.dart';

/// Tema principal que centraliza todos los estilos de favoritos
class FavoritoTheme {
  /// Configuración del AppBar
  static AppBarTheme get appBarTheme => AppBarTheme(
    backgroundColor: FavoritoColors.cardColor,
    foregroundColor: FavoritoColors.textColor,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: FavoritoTextStyles.appBarTitle,
    iconTheme: IconThemeData(
      size: FavoritoDimensions.appBarIconSize,
      color: FavoritoColors.textColor,
    ),
  );
  
  /// Configuración de botones elevados
  static ElevatedButtonThemeData get elevatedButtonTheme => ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: FavoritoColors.primaryColor,
      foregroundColor: Colors.white,
      shape: FavoritoDecorations.smallButtonShape,
      elevation: FavoritoDimensions.buttonElevation,
      textStyle: FavoritoTextStyles.elevatedButtonLabel,
    ),
  );
  
  /// Configuración de botones de texto
  static TextButtonThemeData get textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: FavoritoColors.subtextColor,
      shape: FavoritoDecorations.smallButtonShape,
      textStyle: FavoritoTextStyles.buttonLabel,
    ),
  );
  
  /// Configuración de botones outlined
  static OutlinedButtonThemeData get outlinedButtonTheme => OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: FavoritoColors.subtextColor,
      side: BorderSide(color: FavoritoColors.subtextColor),
      shape: FavoritoDecorations.smallButtonShape,
      textStyle: FavoritoTextStyles.buttonLabel,
    ),
  );
  
  /// Configuración de cards
  static CardTheme get cardTheme => CardTheme(
    color: FavoritoColors.cardColor,
    elevation: FavoritoDimensions.cardElevation,
    shadowColor: FavoritoColors.primaryColor.withOpacity(0.06),
    shape: FavoritoDecorations.cardShape,
    margin: EdgeInsets.zero,
  );
  
  /// Configuración de diálogos
  static DialogTheme get dialogTheme => DialogTheme(
    backgroundColor: FavoritoColors.cardColor,
    shape: FavoritoDecorations.dialogShape,
    contentTextStyle: FavoritoTextStyles.dialogContent,
    titleTextStyle: FavoritoTextStyles.dialogTitle,
  );
  
  /// Configuración del SnackBar
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: FavoritoColors.successColor,
    behavior: SnackBarBehavior.floating,
    shape: FavoritoDecorations.snackbarShape,
    elevation: FavoritoDimensions.snackbarElevation,
    contentTextStyle: FavoritoTextStyles.snackbarText,
  );
  
  /// Configuración del RefreshIndicator
  static Color get refreshIndicatorColor => FavoritoColors.primaryColor;
  
  /// Configuración del CircularProgressIndicator
  static Color get progressIndicatorColor => FavoritoColors.primaryColor;
  static Color get progressIndicatorBackground => FavoritoColors.accentColor.withOpacity(0.2);
  
  /// Tema completo para la aplicación (específico para favoritos)
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: FavoritoColors.backgroundColor,
    appBarTheme: appBarTheme,
    elevatedButtonTheme: elevatedButtonTheme,
    textButtonTheme: textButtonTheme,
    outlinedButtonTheme: outlinedButtonTheme,
    cardTheme: cardTheme,
    dialogTheme: dialogTheme,
    snackBarTheme: snackBarTheme,
    colorScheme: ColorScheme.light(
      primary: FavoritoColors.primaryColor,
      secondary: FavoritoColors.accentColor,
      surface: FavoritoColors.cardColor,
      background: FavoritoColors.backgroundColor,
      error: FavoritoColors.errorColor,
      onPrimary: Colors.white,
      onSecondary: FavoritoColors.textColor,
      onSurface: FavoritoColors.textColor,
      onBackground: FavoritoColors.textColor,
      onError: Colors.white,
    ),
  );
  
  /// Configuraciones específicas para componentes
  
  /// Botón de favoritos en el AppBar
  static Widget favoriteCounterWidget({
    required int count,
    required bool isTablet,
  }) {
    return Container(
      margin: EdgeInsets.only(
        right: isTablet ? 24 : 16, 
        top: 12, 
        bottom: 12
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12, 
        vertical: 8
      ),
      decoration: FavoritoDecorations.favoriteCounterDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_rounded, size: 18, color: FavoritoColors.favoriteColor),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: FavoritoTextStyles.favoriteCounter(isTablet),
          ),
        ],
      ),
    );
  }
  
  /// Badge de descuento
  static Widget discountBadge({
    required int discount,
    bool isSmall = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 10, 
        vertical: isSmall ? 3 : 6
      ),
      decoration: isSmall 
        ? FavoritoDecorations.discountBadgeDecorationSmall
        : FavoritoDecorations.discountBadgeDecoration,
      child: Text(
        '-$discount%',
        style: isSmall 
          ? FavoritoTextStyles.discountBadgeSmall
          : FavoritoTextStyles.discountBadge,
      ),
    );
  }
  
  /// Configuración de animaciones
  static Duration getStaggeredAnimationDuration(int index) {
    return Duration(milliseconds: 300 + (index * 80));
  }
  
  static Duration getStaggeredAnimationDurationTablet(int index) {
    return Duration(milliseconds: 300 + (index * 100));
  }
  
  /// Configuración de espaciados responsive
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final isTablet = FavoritoDimensions.isTablet(context);
    return FavoritoDimensions.screenPadding(isTablet);
  }
  
  static EdgeInsets getResponsiveCardPadding(BuildContext context) {
    final isTablet = FavoritoDimensions.isTablet(context);
    return FavoritoDimensions.cardPadding(isTablet);
  }
  
  /// Configuración de tamaños responsive
  static double getResponsiveImageSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return FavoritoDimensions.imageSize(screenWidth);
  }
  
  static double getResponsiveIconSize(BuildContext context) {
    final isTablet = FavoritoDimensions.isTablet(context);
    return FavoritoDimensions.favoriteIconSize(isTablet);
  }
}