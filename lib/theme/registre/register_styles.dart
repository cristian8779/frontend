// lib/theme/register_styles.dart
import 'package:flutter/material.dart';
import 'app_theme.dart';

class RegisterStyles {
  // Espaciados responsivos mejorados para evitar overflow
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Considera también la altura para evitar overflow
    if (screenHeight < 600) return baseSize * 0.8; // Pantallas muy pequeñas
    if (screenWidth > 600) return baseSize * 1.1;   // Tablets
    if (screenWidth < 360) return baseSize * 0.85;  // Pantallas estrechas
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Padding más conservador para evitar overflow
    if (screenHeight < 600) return const EdgeInsets.all(8);  // Pantallas pequeñas
    if (screenWidth > 600) return const EdgeInsets.all(24);  // Tablets
    if (screenWidth < 360) return const EdgeInsets.all(8);   // Pantallas estrechas
    return const EdgeInsets.all(16); // Por defecto reducido
  }

  // Función para obtener constraints seguros
  static BoxConstraints getSafeConstraints(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return BoxConstraints(
      minHeight: size.height * 0.1,
      maxHeight: size.height * 0.9,
      maxWidth: size.width > 600 ? 600 : size.width * 0.95,
    );
  }

  // Estilos de texto responsivos
  static TextStyle titleStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 24).clamp(20, 32), // Límites seguros
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    letterSpacing: -0.5,
    height: 1.2, // Altura de línea para evitar cortes
  );

  static TextStyle subtitleStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 14).clamp(12, 18),
    color: AppTheme.textSecondary,
    height: 1.3,
  );

  static TextStyle sectionHeaderStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 16).clamp(14, 20),
    fontWeight: FontWeight.w700,
    color: AppTheme.textPrimary,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static TextStyle labelStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 14).clamp(12, 16),
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
    height: 1.2,
  );

  static TextStyle requiredLabelStyle(BuildContext context) => TextStyle(
    color: AppTheme.errorColor,
    fontWeight: FontWeight.w600,
    fontSize: getResponsiveSize(context, 14).clamp(12, 16),
  );

  static TextStyle progressTextStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 12).clamp(10, 14),
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );

  static TextStyle progressPercentStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 12).clamp(10, 14),
    fontWeight: FontWeight.w600,
    color: AppTheme.primaryColor,
  );

  // Decoraciones de contenedores con dimensiones seguras
  static BoxDecoration iconContainerDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(getResponsiveSize(context, 32).clamp(24, 40)),
    boxShadow: [
      BoxShadow(
        color: AppTheme.primaryColor.withOpacity(0.2),
        blurRadius: 15,
        offset: const Offset(0, 6),
      ),
    ],
  );

  static BoxDecoration sectionIconDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
  );

  static BoxDecoration summaryContainerDecoration() => BoxDecoration(
    color: AppTheme.secondaryColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(AppTheme.largeRadius),
    border: Border.all(color: AppTheme.secondaryColor.withOpacity(0.2)),
  );

  static BoxDecoration summaryItemDecoration() => BoxDecoration(
    color: AppTheme.surfaceColor,
    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
    border: Border.all(color: AppTheme.borderColor),
  );

  static BoxDecoration connectionStatusDecoration() => BoxDecoration(
    color: const Color(0xFFFEF3C7),
    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
    border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
  );

  // Decoraciones para progreso y validación
  static BoxDecoration progressIndicatorDecoration(bool isActive, bool isCurrent) => BoxDecoration(
    borderRadius: BorderRadius.circular(3),
    color: isActive
        ? (isCurrent ? AppTheme.primaryColor : AppTheme.secondaryColor)
        : AppTheme.borderColor,
    boxShadow: isActive && isCurrent
        ? [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ]
        : null,
  );

  // Decoraciones para chips de validación
  static BoxDecoration chipDecoration(bool isValid) => BoxDecoration(
    color: isValid 
        ? AppTheme.secondaryColor.withOpacity(0.1) 
        : AppTheme.textTertiary.withOpacity(0.08),
    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
    border: Border.all(
      color: isValid 
          ? AppTheme.secondaryColor.withOpacity(0.3) 
          : AppTheme.textTertiary.withOpacity(0.2),
      width: 1,
    ),
  );

  // Estilos para validación de contraseña
  static Color getStrengthColor(double strength) {
    if (strength < 0.3) return AppTheme.errorColor;
    if (strength < 0.6) return AppTheme.warningColor;
    if (strength < 0.8) return AppTheme.secondaryColor;
    return const Color(0xFF059669);
  }

  static String getStrengthText(double strength) {
    if (strength < 0.3) return 'Muy débil';
    if (strength < 0.6) return 'Débil';
    if (strength < 0.8) return 'Buena';
    return 'Muy fuerte';
  }

  static TextStyle strengthTextStyle(BuildContext context, Color color) => TextStyle(
    fontSize: getResponsiveSize(context, 12).clamp(10, 14),
    fontWeight: FontWeight.w600,
    color: color,
  );

  static TextStyle strengthPercentStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 11).clamp(9, 13),
    color: AppTheme.textSecondary,
  );

  static TextStyle chipTextStyle(BuildContext context, bool isValid) => TextStyle(
    fontSize: getResponsiveSize(context, 11).clamp(9, 13),
    fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
    color: isValid 
        ? const Color(0xFF059669) 
        : AppTheme.textSecondary,
  );

  // Estilos para botones con tamaños seguros
  static ButtonStyle nextButtonStyle(BuildContext context) => ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: Colors.white,
    disabledBackgroundColor: AppTheme.textTertiary,
    elevation: 6,
    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: getResponsiveSize(context, 24).clamp(16, 32),
      vertical: getResponsiveSize(context, 12).clamp(8, 16),
    ),
    minimumSize: Size(
      getResponsiveSize(context, 120).clamp(100, 160),
      getResponsiveSize(context, 44).clamp(40, 56),
    ),
  );

  static ButtonStyle backButtonStyle(BuildContext context) => TextButton.styleFrom(
    foregroundColor: AppTheme.textSecondary,
    padding: EdgeInsets.symmetric(
      horizontal: getResponsiveSize(context, 16).clamp(12, 24),
      vertical: getResponsiveSize(context, 8).clamp(6, 12),
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
      side: const BorderSide(color: AppTheme.borderColor),
    ),
    minimumSize: Size(
      getResponsiveSize(context, 80).clamp(70, 120),
      getResponsiveSize(context, 40).clamp(36, 48),
    ),
  );

  static TextStyle buttonTextStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 14).clamp(12, 16),
    fontWeight: FontWeight.w600,
  );

  static TextStyle smallButtonTextStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 12).clamp(10, 14),
  );

  // Handle superior
  static BoxDecoration handleDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.borderColor,
    borderRadius: BorderRadius.circular(2),
  );

  // Decoración para el contenedor de fortaleza de la contraseña
  static BoxDecoration summaryIconContainerDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.secondaryColor.withOpacity(0.1),
    shape: BoxShape.circle,
  );

  static BoxDecoration summaryItemIconDecoration(BuildContext context) => BoxDecoration(
    color: AppTheme.primaryColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppTheme.smallRadius),
  );

  // Decoración para el estado sin guardar
  static BoxDecoration unsavedChangesDecoration() => BoxDecoration(
    color: AppTheme.warningColor.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
  );

  static TextStyle unsavedChangesTextStyle(BuildContext context) => TextStyle(
    fontSize: getResponsiveSize(context, 10).clamp(8, 12),
    fontWeight: FontWeight.w500,
  );

  // Márgenes y espaciados seguros
  static EdgeInsets defaultMargin(BuildContext context) => EdgeInsets.only(
    bottom: getResponsiveSize(context, 16).clamp(8, 24),
  );
  
  static EdgeInsets sectionHeaderMargin(BuildContext context) => EdgeInsets.only(
    top: getResponsiveSize(context, 20).clamp(12, 32),
    bottom: getResponsiveSize(context, 12).clamp(8, 16),
  );
  
  static EdgeInsets summaryItemMargin(BuildContext context) => EdgeInsets.only(
    bottom: getResponsiveSize(context, 8).clamp(4, 12),
  );
  
  // Paddings seguros
  static EdgeInsets defaultPadding(BuildContext context) => EdgeInsets.all(
    getResponsiveSize(context, 12).clamp(8, 20),
  );
  
  static EdgeInsets largePadding(BuildContext context) => EdgeInsets.all(
    getResponsiveSize(context, 20).clamp(12, 32),
  );
  
  // Tamaños de iconos seguros
  static double smallIcon(BuildContext context) => getResponsiveSize(context, 16).clamp(14, 20);
  static double mediumIcon(BuildContext context) => getResponsiveSize(context, 20).clamp(16, 24);
  static double largeIcon(BuildContext context) => getResponsiveSize(context, 32).clamp(24, 40);
  static double xlIcon(BuildContext context) => getResponsiveSize(context, 48).clamp(32, 64);

  // Función para altura segura de campos de texto
  static double getTextFieldHeight(BuildContext context) {
    return getResponsiveSize(context, 56).clamp(48, 64);
  }

  // Función para espaciado vertical seguro
  static double getVerticalSpacing(BuildContext context, double baseSpacing) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) return baseSpacing * 0.7;
    return baseSpacing;
  }
}