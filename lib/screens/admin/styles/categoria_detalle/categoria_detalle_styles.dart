import 'package:flutter/material.dart';

class CategoriaDetalleStyles {
  // Constantes de color
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryColor = Colors.blue;
  static const Color successColor = Colors.green;
  static const Color errorColor = Colors.red;
  static const Color warningColor = Colors.orange;
  static const Color textPrimary = Colors.black87;
  static final Color textSecondary = Colors.grey[600]!;
  static final Color textTertiary = Colors.grey[500]!;
  static const Color whiteColor = Colors.white;

  // Breakpoints responsive
  static const double tabletBreakpoint = 600;
  static const double desktopBreakpoint = 1200;
  static const double smallScreenBreakpoint = 360;

  // Métodos helper para responsive
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width > tabletBreakpoint;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width > desktopBreakpoint;
  
  static bool isSmallScreen(BuildContext context) => 
      MediaQuery.of(context).size.width < smallScreenBreakpoint;
  
  static double screenWidth(BuildContext context) => 
      MediaQuery.of(context).size.width;

  // Dimensiones responsive
  static double maxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 800;
    if (isTablet(context)) return 600;
    return screenWidth(context);
  }

  static EdgeInsets responsivePadding(BuildContext context) {
    if (isDesktop(context)) return const EdgeInsets.all(32);
    if (isTablet(context)) return const EdgeInsets.all(24);
    if (isSmallScreen(context)) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  static double imageHeight(BuildContext context) {
    if (isDesktop(context)) return 300;
    if (isTablet(context)) return 250;
    if (isSmallScreen(context)) return 180;
    return 220;
  }

  static double fontSize(BuildContext context) {
    if (isTablet(context)) return 20;
    if (isSmallScreen(context)) return 16;
    return 18;
  }

  static double iconSize(BuildContext context) {
    if (isTablet(context)) return 28;
    if (isSmallScreen(context)) return 20;
    return 24;
  }

  static double smallFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 13;
    if (isTablet(context)) return 16;
    return 14;
  }

  static double appBarExpandedHeight(BuildContext context) {
    if (isSmallScreen(context)) return 100;
    if (isTablet(context)) return 140;
    return 120;
  }

  static double appBarTitleFontSize(BuildContext context) {
    if (isSmallScreen(context)) return 14;
    if (screenWidth(context) < 350) return 16;
    if (isTablet(context)) return 20;
    return 18;
  }

  // Estilos de texto
  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: fontSize(context),
    fontWeight: FontWeight.w600,
  );

  static TextStyle appBarTitleStyle(BuildContext context) => TextStyle(
    color: textPrimary,
    fontSize: appBarTitleFontSize(context),
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyTextStyle(BuildContext context) => TextStyle(
    color: textSecondary,
    height: 1.4,
    fontSize: smallFontSize(context),
  );

  static TextStyle dialogTitleStyle(BuildContext context) => TextStyle(
    fontSize: fontSize(context) + 2,
    fontWeight: FontWeight.w600,
  );

  static TextStyle buttonTextStyle(BuildContext context) => TextStyle(
    fontSize: smallFontSize(context),
  );

  static TextStyle badgeTextStyle(BuildContext context, {Color? color}) => TextStyle(
    fontSize: isTablet(context) ? 14 : 12,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle smallBadgeTextStyle(BuildContext context, {Color? color}) => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: color,
  );

  static TextStyle placeholderTextStyle(BuildContext context) => TextStyle(
    color: textSecondary,
    fontSize: isSmallScreen(context) ? 14 : (isTablet(context) ? 18 : 16),
    fontWeight: FontWeight.w500,
  );

  static TextStyle placeholderSubtitleStyle(BuildContext context) => TextStyle(
    color: textTertiary,
    fontSize: isSmallScreen(context) ? 12 : (isTablet(context) ? 16 : 14),
  );

  static TextStyle textFieldStyle(BuildContext context, bool enabled) => TextStyle(
    color: enabled ? textPrimary : textSecondary,
    fontSize: isSmallScreen(context) ? 14 : (isTablet(context) ? 18 : 16),
  );

  // Border radius
  static double cardBorderRadius(BuildContext context) {
    if (isSmallScreen(context)) return 16;
    if (isTablet(context)) return 24;
    return 20;
  }

  static double smallBorderRadius(BuildContext context) {
    if (isSmallScreen(context)) return 12;
    if (isTablet(context)) return 16;
    return 12;
  }

  static double buttonBorderRadius(BuildContext context) {
    if (isSmallScreen(context)) return 12;
    if (isTablet(context)) return 20;
    return 16;
  }

  // Decoraciones de contenedor
  static BoxDecoration cardDecoration(BuildContext context, {Border? border}) => BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(cardBorderRadius(context)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: isSmallScreen(context) ? 8 : (isTablet(context) ? 12 : 10),
        offset: Offset(0, isSmallScreen(context) ? 3 : (isTablet(context) ? 6 : 4)),
      ),
    ],
    border: border,
  );

  static BoxDecoration imageContainerDecoration(BuildContext context, bool isEditing) => BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(cardBorderRadius(context)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: isSmallScreen(context) ? 8 : (isTablet(context) ? 12 : 10),
        offset: Offset(0, isSmallScreen(context) ? 3 : (isTablet(context) ? 6 : 4)),
      ),
    ],
    border: isEditing ? Border.all(color: primaryColor.withOpacity(0.3), width: 2) : null,
  );

  static BoxDecoration badgeDecoration(BuildContext context, Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration circleBadgeDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    shape: BoxShape.circle,
  );

  static BoxDecoration loadingOverlayDecoration(BuildContext context) => BoxDecoration(
    color: whiteColor,
    borderRadius: BorderRadius.circular(
      isSmallScreen(context) ? 16 : (isTablet(context) ? 24 : 20)
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
    ],
  );

  static BoxDecoration imageOverlayDecoration(BuildContext context) => BoxDecoration(
    borderRadius: BorderRadius.circular(cardBorderRadius(context)),
    color: Colors.black.withOpacity(0.05),
    border: Border.all(
      color: primaryColor.withOpacity(0.3),
      width: 2,
    ),
  );

  static BoxDecoration iconCircleDecoration(BuildContext context) => BoxDecoration(
    color: whiteColor.withOpacity(0.95),
    borderRadius: BorderRadius.circular(
      isSmallScreen(context) ? 20 : (isTablet(context) ? 30 : 25)
    ),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: isSmallScreen(context) ? 6 : (isTablet(context) ? 10 : 8),
        offset: Offset(0, isSmallScreen(context) ? 2 : (isTablet(context) ? 3 : 2)),
      ),
    ],
  );

  static Gradient placeholderGradient() => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.grey[100]!,
      Colors.grey[200]!,
    ],
  );

  // Estilos de InputDecoration
  static InputDecoration textFieldDecoration(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool enabled,
    Widget? suffixIcon,
  }) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(
      color: enabled ? primaryColor : Colors.grey[500],
      fontSize: smallFontSize(context),
    ),
    prefixIcon: Icon(
      icon,
      color: enabled ? primaryColor : Colors.grey[400],
      size: iconSize(context),
    ),
    filled: true,
    fillColor: enabled ? whiteColor : Colors.grey[50],
    contentPadding: EdgeInsets.symmetric(
      horizontal: isSmallScreen(context) ? 12 : (isTablet(context) ? 20 : 16),
      vertical: isSmallScreen(context) ? 14 : (isTablet(context) ? 22 : 18),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius(context)),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius(context)),
      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius(context)),
      borderSide: const BorderSide(color: primaryColor, width: 2),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(buttonBorderRadius(context)),
      borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
    ),
    suffixIcon: suffixIcon,
  );

  // Estilos de botones
  static ButtonStyle primaryButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: whiteColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen(context) ? 12 : (isTablet(context) ? 24 : 16),
      vertical: isSmallScreen(context) ? 8 : (isTablet(context) ? 16 : 12),
    ),
  );

  static ButtonStyle destructiveButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: whiteColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen(context) ? 12 : (isTablet(context) ? 24 : 16),
      vertical: isSmallScreen(context) ? 8 : (isTablet(context) ? 16 : 12),
    ),
  );

  static ButtonStyle successButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: successColor,
    foregroundColor: whiteColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen(context) ? 24 : (isTablet(context) ? 40 : 32),
      vertical: isSmallScreen(context) ? 8 : (isTablet(context) ? 16 : 12),
    ),
  );

  static ButtonStyle errorButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: errorColor,
    foregroundColor: whiteColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
    padding: EdgeInsets.symmetric(
      horizontal: isSmallScreen(context) ? 24 : (isTablet(context) ? 40 : 32),
      vertical: isSmallScreen(context) ? 8 : (isTablet(context) ? 16 : 12),
    ),
  );

  // Padding y márgenes
  static EdgeInsets cardPadding(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 16 : (isTablet(context) ? 28 : 24),
  );

  static EdgeInsets dialogPadding(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 12 : (isTablet(context) ? 20 : 16),
  );

  static EdgeInsets loadingOverlayPadding(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 20 : (isTablet(context) ? 32 : 24),
  );

  static EdgeInsets loadingOverlayMargin(BuildContext context) => EdgeInsets.symmetric(
    horizontal: isSmallScreen(context) ? 24 : (isTablet(context) ? 40 : 32),
  );

  static EdgeInsets snackBarMargin(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 12 : (isTablet(context) ? 20 : 16),
  );

  static EdgeInsets iconCirclePadding(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 10 : (isTablet(context) ? 16 : 12),
  );

  static EdgeInsets buttonIconPadding(BuildContext context) => EdgeInsets.all(
    isSmallScreen(context) ? 4 : (isTablet(context) ? 8 : 6),
  );

  // SizedBox helpers
  static SizedBox verticalSpaceSmall(BuildContext context) => SizedBox(
    height: isSmallScreen(context) ? 6 : (isTablet(context) ? 12 : 8),
  );

  static SizedBox verticalSpaceMedium(BuildContext context) => SizedBox(
    height: isSmallScreen(context) ? 12 : (isTablet(context) ? 20 : 16),
  );

  static SizedBox verticalSpaceLarge(BuildContext context) => SizedBox(
    height: isSmallScreen(context) ? 24 : (isTablet(context) ? 40 : 32),
  );

  static SizedBox horizontalSpaceSmall(BuildContext context) => SizedBox(
    width: isSmallScreen(context) ? 6 : (isTablet(context) ? 12 : 8),
  );

  static SizedBox horizontalSpaceMedium(BuildContext context) => SizedBox(
    width: isSmallScreen(context) ? 12 : (isTablet(context) ? 20 : 16),
  );

  // Tamaños de CircularProgressIndicator
  static double loadingIndicatorSize(BuildContext context) =>
    isSmallScreen(context) ? 40 : (isTablet(context) ? 56 : 48);

  static double loadingIndicatorStrokeWidth(BuildContext context) =>
    isSmallScreen(context) ? 3 : (isTablet(context) ? 5 : 4);

  // Tamaños de iconos placeholder
  static double placeholderIconSize(BuildContext context) =>
    isSmallScreen(context) ? 48 : (isTablet(context) ? 80 : 64);
}