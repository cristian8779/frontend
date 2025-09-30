// lib/theme/theme_utils.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class ThemeUtils {
  /// Crea un BoxShadow estándar para contenedores
  static List<BoxShadow> getContainerShadow() {
    return [
      BoxShadow(
        color: AppColors.shadow,
        spreadRadius: 2,
        blurRadius: 10,
        offset: const Offset(0, -2),
      ),
    ];
  }
  
  /// Obtiene el padding horizontal responsivo basado en el tamaño de pantalla
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > AppDimensions.tabletBreakpoint) {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.15);
    } else if (screenWidth < AppDimensions.smallScreenBreakpoint) {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.04);
    } else {
      return EdgeInsets.symmetric(horizontal: screenWidth * 0.06);
    }
  }
  
  /// Obtiene el padding vertical responsivo
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    return EdgeInsets.symmetric(
      vertical: isSmallScreen ? 20 : 24,
    );
  }
  
  /// Crea un SizedBox con altura responsiva
  static Widget getResponsiveVerticalSpace(BuildContext context, {
    double smallScreenSpace = 12,
    double normalScreenSpace = 16,
  }) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    return SizedBox(height: isSmallScreen ? smallScreenSpace : normalScreenSpace);
  }
  
  /// Crea un SizedBox con ancho responsivo
  static Widget getResponsiveHorizontalSpace(BuildContext context, {
    double smallScreenSpace = 6,
    double normalScreenSpace = 8,
  }) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    return SizedBox(width: isSmallScreen ? smallScreenSpace : normalScreenSpace);
  }
  
  /// Obtiene el tamaño de fuente responsivo para títulos
  static double getResponsiveTitleFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > AppDimensions.tabletBreakpoint) {
      return 36;
    } else if (screenWidth < AppDimensions.smallScreenBreakpoint) {
      return 22;
    } else if (screenWidth < 400) {
      return 24;
    } else {
      return 30;
    }
  }
  
  /// Valida el formato de email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su correo';
    }
    final reg = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!reg.hasMatch(value)) {
      return 'Correo no válido';
    }
    return null;
  }
  
  /// Valida que el campo no esté vacío
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return 'Ingrese su $fieldName';
    }
    return null;
  }
  
  /// Obtiene la decoración para contenedores principales
  static BoxDecoration getMainContainerDecoration(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(
          isSmallScreen ? AppDimensions.radiusExtraLarge : 50
        )
      ),
      boxShadow: getContainerShadow(),
    );
  }
  
  /// Crea un Hero widget para el logo con animación
  static Widget buildLogoHero(BuildContext context, {
    String tag = 'logo',
    String assetPath = 'assets/bola.png',
  }) {
    final logoSize = AppDimensions.getResponsiveLogoSize(context);
    
    return Hero(
      tag: tag,
      child: Image.asset(
        assetPath,
        width: logoSize,
        height: logoSize,
        fit: BoxFit.contain,
      ),
    );
  }
  
  /// Construye un AppBar responsivo con estilo consistente
  static PreferredSizeWidget buildResponsiveAppBar(
    BuildContext context, {
    String? title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
  }) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    
    return AppBar(
      title: title != null 
        ? Text(
            title,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          )
        : null,
      backgroundColor: AppColors.surface,
      elevation: AppDimensions.elevationLow,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      iconTheme: IconThemeData(
        color: AppColors.textSecondary,
        size: isSmallScreen ? AppDimensions.iconSmall : AppDimensions.iconMedium,
      ),
    );
  }
  
  /// Obtiene el SafeArea superior responsivo
  static double getResponsiveTopSafeArea(BuildContext context) {
    final media = MediaQuery.of(context);
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    
    return media.padding.top + (isSmallScreen ? 20 : 40);
  }
}