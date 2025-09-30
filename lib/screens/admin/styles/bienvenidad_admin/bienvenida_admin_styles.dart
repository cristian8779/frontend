// bienvenida_admin_styles.dart
import 'package:flutter/material.dart';

class BienvenidaAdminTheme {
  // Colores principales
  static const Color primaryColor = Color(0xFFBE0C0C);
  static const Color accentColor = Color(0xFFE8F4FD);
  static const Color gradientStart = Color(0xFFFAFAFA);
  static const Color gradientEnd = Color(0xFFE3F2FD);
  
  // Colores de texto
  static const Color titleTextColor = Colors.black87;
  static const Color subtitleTextColor = Colors.black54;
  static const Color buttonTextColor = Colors.black54;
  static const Color buttonIconColor = Colors.white;
  
  // Colores de rol
  static const Color superAdminColor = Color(0xFFFFD700);
  static const Color superAdminTextColor = Color(0xFFB8860B);
  static const Color adminBorderColor = primaryColor;
  
  // Colores de sombra y efectos
  static final Color shadowColor = Colors.black.withOpacity(0.1);
  static final Color cardShadowColor = Colors.black.withOpacity(0.1);
  static final Color buttonShadowColor = primaryColor.withOpacity(0.4);
  static final Color highlightShadowColor = Colors.white.withOpacity(0.8);
  
  // Iconos
  static const IconData superAdminIcon = Icons.admin_panel_settings;
  static const IconData adminIcon = Icons.shield;
  static const IconData continueIcon = Icons.arrow_forward_ios_rounded;
  
  // Gradientes
  static const List<Color> backgroundGradient = [gradientStart, gradientEnd];
  static const List<double> backgroundGradientStops = [0.0, 1.0];
  
  static List<Color> getButtonGradient() => [
    primaryColor,
    primaryColor.withOpacity(0.8),
  ];
  
  static List<Color> getCardGradient() => [
    Colors.white,
    Colors.white.withOpacity(0.95),
  ];
}

class BienvenidaAdminDimensions {
  // Breakpoints
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  static const double smallHeightBreakpoint = 700.0;
  
  // Espaciado estándar
  static const double roleIndicatorSpacing = 20.0;
  static const double titleSubtitleSpacing = 8.0;
  static const double titleSubtitleSpacingLarge = 12.0;
  static const double contentImageSpacing = 20.0;
  static const double contentImageSpacingLarge = 32.0;
  static const double buttonTextSpacing = 16.0;
  
  // Border radius
  static const double roleIndicatorRadius = 20.0;
  static const double cardRadius = 24.0;
  
  // Tamaños fijos
  static const double roleIconSize = 18.0;
  static const double roleFontSize = 14.0;
  static const double roleBorderWidth = 1.5;
  static const double cardElevation = 12.0;
  
  // Función para obtener dimensiones responsivas
  static Map<String, double> getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= tabletBreakpoint;
    final isDesktop = screenWidth >= desktopBreakpoint;
    final isSmallHeight = screenHeight < smallHeightBreakpoint;
    
    if (isDesktop) {
      return {
        'titleFontSize': isSmallHeight ? 32.0 : 42.0,
        'subtitleFontSize': 18.0,
        'horizontalPadding': 80.0,
        'verticalPadding': 40.0,
        'buttonSize': 88.0,
        'iconSize': 40.0,
        'buttonTextSize': 18.0,
        'imageWidthRatio': 0.45,
        'maxWidth': 1000.0,
        'bottomSpacing': 32.0,
        'cardPadding': 40.0,
      };
    } else if (isTablet) {
      return {
        'titleFontSize': isSmallHeight ? 28.0 : 36.0,
        'subtitleFontSize': 16.0,
        'horizontalPadding': 48.0,
        'verticalPadding': 32.0,
        'buttonSize': 80.0,
        'iconSize': 36.0,
        'buttonTextSize': 17.0,
        'imageWidthRatio': 0.55,
        'maxWidth': 750.0,
        'bottomSpacing': 28.0,
        'cardPadding': 32.0,
      };
    } else {
      return {
        'titleFontSize': isSmallHeight ? 26.0 : 32.0,
        'subtitleFontSize': 15.0,
        'horizontalPadding': 28.0,
        'verticalPadding': 24.0,
        'buttonSize': 72.0,
        'iconSize': 32.0,
        'buttonTextSize': 16.0,
        'imageWidthRatio': 0.65,
        'maxWidth': double.infinity,
        'bottomSpacing': 24.0,
        'cardPadding': 24.0,
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
  
  static bool isSmallHeight(BuildContext context) {
    return MediaQuery.of(context).size.height < smallHeightBreakpoint;
  }
}

class BienvenidaAdminTextStyles {
  static TextStyle getTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['titleFontSize']!,
      fontWeight: FontWeight.w800,
      color: BienvenidaAdminTheme.titleTextColor,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle getSubtitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['subtitleFontSize']!,
      fontWeight: FontWeight.w500,
      color: BienvenidaAdminTheme.subtitleTextColor,
      letterSpacing: 0.5,
    );
  }
  
  static TextStyle getButtonTextStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['buttonTextSize']!,
      fontWeight: FontWeight.w500,
      color: BienvenidaAdminTheme.buttonTextColor,
      letterSpacing: 0.3,
    );
  }
  
  static const TextStyle roleTextStyle = TextStyle(
    fontSize: BienvenidaAdminDimensions.roleFontSize,
    fontWeight: FontWeight.w600,
  );
}

class BienvenidaAdminDecorations {
  // Decoración del fondo principal
  static BoxDecoration getBackgroundDecoration() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: BienvenidaAdminTheme.backgroundGradient,
        stops: BienvenidaAdminTheme.backgroundGradientStops,
      ),
    );
  }
  
  // Decoración del indicador de rol
  static BoxDecoration getRoleIndicatorDecoration({required bool isSuper}) {
    return BoxDecoration(
      color: isSuper 
        ? BienvenidaAdminTheme.superAdminColor.withOpacity(0.2)
        : BienvenidaAdminTheme.primaryColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(BienvenidaAdminDimensions.roleIndicatorRadius),
      border: Border.all(
        color: isSuper 
          ? BienvenidaAdminTheme.superAdminColor
          : BienvenidaAdminTheme.adminBorderColor,
        width: BienvenidaAdminDimensions.roleBorderWidth,
      ),
    );
  }
  
  // Decoración de la tarjeta principal
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(BienvenidaAdminDimensions.cardRadius),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: BienvenidaAdminTheme.getCardGradient(),
      ),
    );
  }
  
  // Decoración del botón circular
  static BoxDecoration getButtonDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: BienvenidaAdminTheme.getButtonGradient(),
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: BienvenidaAdminTheme.buttonShadowColor,
          blurRadius: 15,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
        BoxShadow(
          color: BienvenidaAdminTheme.highlightShadowColor,
          blurRadius: 10,
          offset: const Offset(-5, -5),
          spreadRadius: 0,
        ),
      ],
    );
  }
}

class BienvenidaAdminLayout {
  // Padding del indicador de rol
  static const EdgeInsets roleIndicatorPadding = EdgeInsets.symmetric(
    horizontal: 16, 
    vertical: 8
  );
  
  // Constraints de imagen
  static BoxConstraints getImageConstraints({
    required double maxWidth,
    required double maxHeight,
    required double widthRatio,
  }) {
    return BoxConstraints(
      maxWidth: maxWidth * widthRatio,
      maxHeight: maxHeight * 0.4,
    );
  }
  
  // Offsets para animaciones
  static const Offset slideAnimationBegin = Offset(0, 0.3);
  static const Offset slideAnimationEnd = Offset.zero;
  
  static Offset getFloatingOffset(double value) {
    return Offset(0, 8 * (0.5 - (value % 1.0 - 0.5).abs()));
  }
}

class BienvenidaAdminAnimations {
  // Duraciones de animación
  static const Duration mainDuration = Duration(milliseconds: 600);
  static const Duration slideDuration = Duration(milliseconds: 1200);
  static const Duration fadeDuration = Duration(milliseconds: 1500);
  static const Duration floatingDuration = Duration(seconds: 3);
  
  // Delays para secuencia de animaciones
  static const Duration slideDelay = Duration(milliseconds: 300);
  static const Duration fadeDelay = Duration(milliseconds: 500);
  static const Duration scaleDelay = Duration(milliseconds: 800);
  static const Duration tapDelay = Duration(milliseconds: 100);
  static const Duration navigationDelay = Duration(milliseconds: 200);
  
  // Curvas de animación
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve slideEaseCurve = Curves.easeOutCubic;
  static const Curve fadeEaseCurve = Curves.easeInOut;
  
  // Valores de animación
  static const double scaleBegin = 0.95;
  static const double scaleEnd = 1.0;
  static const double bounceBegin = 1.0;
  static const double bounceEnd = 1.1;
  
  // Configuraciones de Tween
  static Tween<double> getScaleTween() {
    return Tween<double>(begin: scaleBegin, end: scaleEnd);
  }
  
  static Tween<Offset> getSlideTween() {
    return Tween<Offset>(
      begin: BienvenidaAdminLayout.slideAnimationBegin,
      end: BienvenidaAdminLayout.slideAnimationEnd,
    );
  }
  
  static Tween<double> getBounceTween() {
    return Tween<double>(begin: bounceBegin, end: bounceEnd);
  }
  
  static Tween<double> getFloatingTween() {
    return Tween(begin: 0.0, end: 1.0);
  }
}

class BienvenidaAdminConstants {
  // Textos de la UI
  static const String welcomeTitle = "¡Bienvenido!";
  static const String adminPanelSubtitle = "Panel de Administración";
  static const String continueText = "Toca para continuar";
  static const String superAdminRole = "Super Admin";
  static const String adminRole = "Admin";
  
  // Asset paths
  static const String welcomeImagePath = 'assets/bienvenida.png';
  
  // Navigation
  static const String controlPanelRoute = '/control-panel';
  
  // Roles
  static const String superAdminRoleKey = 'superadmin';
  static const String adminRoleKey = 'admin';
  
  // Configuraciones de Card
  static RoundedRectangleBorder getCardShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(BienvenidaAdminDimensions.cardRadius),
    );
  }
}