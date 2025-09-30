// lib/theme/more/more_styles.dart
import 'package:flutter/material.dart';

class MoreStyles {
  // Colores principales
  static const Color primaryColor = Color(0xFF3483FA);
  static const Color primaryDarkColor = Color(0xFF2968C8);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardColor = Colors.white;
  static const Color headerColor = Color(0xFFFAFAFA);
  static const Color successColor = Color(0xFF00A650);
  
  // Colores de texto
  static const Color primaryTextColor = Colors.black87;
  static Color secondaryTextColor = Colors.grey[600]!;
  static Color tertiaryTextColor = Colors.grey[400]!;
  
  // Colores destructivos
  static const Color destructiveColor = Colors.red;
  static Color destructiveBackgroundColor = Colors.red.shade50;
  static Color destructiveBorderColor = Colors.red.shade200;
  static Color destructiveTextColor = Colors.red.shade600;
  
  // Espaciado responsivo
  static double getHorizontalPadding(double screenWidth) {
    if (screenWidth >= 1024) return screenWidth * 0.15; // Desktop
    if (screenWidth >= 768) return 24; // Tablet
    return 0; // Mobile
  }
  
  static double getCardMargin(bool isTablet) => isTablet ? 0 : 12;
  static double getCardPadding(bool isTablet) => isTablet ? 24 : 16;
  static double getSectionSpacing(bool isTablet) => isTablet ? 20 : 12;
  static double getIconSize(bool isTablet) => isTablet ? 28 : 20;
  static double getAvatarSize(bool isTablet) => isTablet ? 80 : 64;
  static double getBottomSpacing(bool isTablet) => isTablet ? 100 : 80;
  
  // Estilos de AppBar
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: headerColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryTextColor),
  );
  
  // Estilos de texto del AppBar
  static TextStyle appBarTitleStyle(bool isTablet) => TextStyle(
    color: primaryTextColor,
    fontSize: isTablet ? 24 : 20,
    fontWeight: FontWeight.w600,
  );
  
  // Estilos del header de usuario
  static BoxDecoration get userHeaderDecoration => const BoxDecoration(
    color: cardColor,
  );
  
  static EdgeInsets userHeaderPadding(bool isTablet) => EdgeInsets.all(isTablet ? 28 : 20);
  
  // Estilos del avatar
  static BoxDecoration avatarDecoration(bool isTablet) => BoxDecoration(
    gradient: const LinearGradient(
      colors: [primaryColor, primaryDarkColor],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
    boxShadow: [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );
  
  static TextStyle avatarTextStyle(bool isTablet) => TextStyle(
    color: Colors.white,
    fontSize: isTablet ? 36 : 28,
    fontWeight: FontWeight.bold,
  );
  
  // Estilos del botón de editar avatar
  static BoxDecoration editButtonDecoration(bool isTablet) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(isTablet ? 14 : 10),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Estilos de texto del usuario
  static TextStyle greetingTextStyle(bool isTablet) => TextStyle(
    color: secondaryTextColor,
    fontSize: isTablet ? 18 : 14,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle userNameTextStyle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 26 : 20,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );
  
  static TextStyle loginLinkStyle(bool isTablet) => TextStyle(
    color: primaryColor,
    fontSize: isTablet ? 18 : 14,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
  );
  
  // Estilos de cards
  static BoxDecoration cardDecoration(bool isTablet) => BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: isTablet ? 12 : 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  // Estilos de títulos de sección
  static TextStyle sectionTitleStyle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 20 : 16,
    fontWeight: FontWeight.w600,
    color: primaryTextColor,
  );
  
  static EdgeInsets sectionTitlePadding(bool isTablet) => EdgeInsets.fromLTRB(
    isTablet ? 24 : 16,
    isTablet ? 24 : 16,
    isTablet ? 24 : 16,
    isTablet ? 12 : 8,
  );
  
  // Estilos de items de menú
  static EdgeInsets menuItemPadding(bool isTablet) => EdgeInsets.all(isTablet ? 24 : 16);
  
  static BoxDecoration menuIconDecoration({
    required bool isTablet,
    bool highlighted = false,
    bool isDestructive = false,
  }) {
    Color backgroundColor;
    
    if (highlighted) {
      backgroundColor = primaryColor.withOpacity(0.1);
    } else if (isDestructive) {
      backgroundColor = destructiveColor.withOpacity(0.1);
    } else {
      backgroundColor = Colors.grey.withOpacity(0.1);
    }
    
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
    );
  }
  
  static Color getMenuIconColor({
    bool highlighted = false,
    bool isDestructive = false,
  }) {
    if (highlighted) return primaryColor;
    if (isDestructive) return destructiveTextColor;
    return secondaryTextColor;
  }
  
  static TextStyle menuItemTitleStyle({
    required bool isTablet,
    bool isDestructive = false,
  }) => TextStyle(
    fontSize: isTablet ? 20 : 16,
    fontWeight: FontWeight.w500,
    color: isDestructive ? destructiveTextColor : primaryTextColor,
  );
  
  static TextStyle menuItemSubtitleStyle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 16 : 13,
    color: secondaryTextColor,
    fontWeight: FontWeight.w400,
  );
  
  // Estilos de modal bottom sheet
  static BoxDecoration get modalDecoration => const BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  );
  
  static BoxDecoration get modalHandleDecoration => BoxDecoration(
    color: Colors.grey[300],
    borderRadius: BorderRadius.circular(2),
  );
  
  static const TextStyle modalTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  // Estilos de error
  static BoxDecoration get errorCardDecoration => BoxDecoration(
    color: destructiveBackgroundColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: destructiveBorderColor),
  );
  
  static EdgeInsets errorCardPadding(bool isTablet) => EdgeInsets.all(isTablet ? 20 : 16);
  
  static TextStyle errorTitleStyle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 16 : 14,
    fontWeight: FontWeight.w500,
    color: Colors.red.shade800,
  );
  
  static TextStyle errorMessageStyle(bool isTablet) => TextStyle(
    fontSize: isTablet ? 14 : 12,
    color: Colors.red.shade700,
  );
  
  // Estilos de loading
  static BoxDecoration get loadingOverlayDecoration => const BoxDecoration(
    color: Colors.black26,
  );
  
  // Estilos de SnackBar
  static SnackBarThemeData get snackBarTheme => SnackBarThemeData(
    backgroundColor: successColor,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
  
  // Utilidades para determinar el tipo de dispositivo
  static bool isTablet(double screenWidth) => screenWidth >= 768;
  static bool isDesktop(double screenWidth) => screenWidth >= 1024;
  
  // Espaciado vertical entre elementos
  static SizedBox verticalSpacing(bool isTablet, [double? customSpacing]) {
    double spacing = customSpacing ?? (isTablet ? 12 : 8);
    return SizedBox(height: spacing);
  }
  
  // Espaciado horizontal entre elementos
  static SizedBox horizontalSpacing(bool isTablet, [double? customSpacing]) {
    double spacing = customSpacing ?? (isTablet ? 16 : 12);
    return SizedBox(width: spacing);
  }
}