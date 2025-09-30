import 'package:flutter/material.dart';

class GestionarVariacionesStyles {
  // Colores
  static const Color primaryColor = Color(0xFF3A86FF);
  static const Color backgroundColor = Color(0xFFF7FAFC);
  static const Color textPrimaryColor = Color(0xFF2D3748);
  static const Color textSecondaryColor = Color(0xFF718096);
  static const Color whiteColor = Colors.white;
  
  // Colores de stock
  static Color stockLowColor = Colors.red.shade600;
  static Color stockMediumColor = Colors.orange.shade600;
  static Color stockHighColor = Colors.green.shade600;
  
  // Colores de error y éxito
  static Color errorColor = Colors.red.shade600;
  static Color successColor = Colors.green.shade600;
  
  // Sombras
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.08),
    blurRadius: 8,
    offset: const Offset(0, 2),
  );
  
  // Border Radius
  static BorderRadius cardBorderRadius = BorderRadius.circular(16);
  static BorderRadius buttonBorderRadius = BorderRadius.circular(12);
  static BorderRadius smallBorderRadius = BorderRadius.circular(8);
  static BorderRadius imageBorderRadius = BorderRadius.circular(12);
  
  // Estilos de AppBar
  static AppBarTheme appBarTheme(double fontSize) {
    return AppBarTheme(
      titleTextStyle: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: fontSize,
        color: textPrimaryColor,
      ),
      backgroundColor: whiteColor,
      foregroundColor: textPrimaryColor,
      centerTitle: true,
      elevation: 0,
    );
  }
  
  // Estilos de texto
  static TextStyle titleStyle(double fontSize) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: fontSize,
      color: textPrimaryColor,
    );
  }
  
  static TextStyle subtitleStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      color: Colors.grey.shade600,
    );
  }
  
  static TextStyle priceStyle(double fontSize) {
    return TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: fontSize,
      color: primaryColor,
    );
  }
  
  static TextStyle stockLabelStyle(double fontSize, Color color) {
    return TextStyle(
      color: color,
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle dialogContentStyle(double fontSize) {
    return TextStyle(
      color: textSecondaryColor,
      fontSize: fontSize,
    );
  }
  
  // Decoraciones de contenedores
  static BoxDecoration cardDecoration = BoxDecoration(
    color: whiteColor,
    borderRadius: cardBorderRadius,
    boxShadow: [cardShadow],
  );
  
  static BoxDecoration imageContainerDecoration = BoxDecoration(
    borderRadius: imageBorderRadius,
    border: Border.all(color: Colors.grey.shade200),
  );
  
  static BoxDecoration priceContainerDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    borderRadius: smallBorderRadius,
  );
  
  static BoxDecoration stockChipDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    );
  }
  
  static BoxDecoration iconContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: smallBorderRadius,
    );
  }
  
  static BoxDecoration circleIconDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
    );
  }
  
  static BoxDecoration deleteBackgroundDecoration = BoxDecoration(
    color: errorColor,
    borderRadius: cardBorderRadius,
  );
  
  // Estilos de botones
  static ButtonStyle primaryButtonStyle(double horizontalPadding, double verticalPadding) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: whiteColor,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: buttonBorderRadius,
      ),
      elevation: 2,
    );
  }
  
  static ButtonStyle deleteButtonStyle(double horizontalPadding, double verticalPadding) {
    return ElevatedButton.styleFrom(
      backgroundColor: errorColor,
      foregroundColor: whiteColor,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: smallBorderRadius,
      ),
    );
  }
  
  static ButtonStyle cancelButtonStyle(double horizontalPadding, double verticalPadding) {
    return TextButton.styleFrom(
      foregroundColor: Colors.grey.shade600,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
    );
  }
  
  // Estilos de SnackBar
  static SnackBar buildSnackBar(String message, bool isError) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? errorColor : successColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: Duration(seconds: isError ? 4 : 3),
    );
  }
  
  // Shimmer colors
  static Color shimmerBaseColor = Colors.grey.shade300;
  static Color shimmerHighlightColor = Colors.grey.shade100;
  
  // Empty state
  static BoxDecoration emptyStateIconDecoration = BoxDecoration(
    color: primaryColor.withOpacity(0.1),
    shape: BoxShape.circle,
  );
}