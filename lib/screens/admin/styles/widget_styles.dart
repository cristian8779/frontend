// 🎨 ESTILOS ESPECÍFICOS PARA WIDGETS
import 'package:flutter/material.dart';
import 'app_styles.dart';

class WidgetStyles {
  // 🎯 ESTILOS DE BOTONES
  
  /// Estilo para botones elevados principales
  static ButtonStyle get primaryElevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppStyles.accentColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: AppStyles.spacingXLarge,
      vertical: AppStyles.spacingLarge,
    ),
    textStyle: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.bold,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppStyles.radiusMax),
    ),
  );

  /// Estilo para botones de error/eliminación
  static ButtonStyle get errorElevatedButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: AppStyles.errorColor,
    foregroundColor: Colors.white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(
      horizontal: AppStyles.spacingLarge,
      vertical: AppStyles.spacingMedium,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
    ),
  );

  /// Estilo para botones de texto secundarios
  static ButtonStyle get secondaryTextButtonStyle => TextButton.styleFrom(
    foregroundColor: AppStyles.textSecondary,
    padding: const EdgeInsets.symmetric(
      horizontal: AppStyles.spacingLarge,
      vertical: AppStyles.spacingMedium,
    ),
  );

  /// Estilo para FloatingActionButton extendido
  static BoxDecoration get fabDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(AppStyles.radiusMax),
    boxShadow: AppStyles.elevatedShadow,
  );

  // 🎯 ESTILOS DE TARJETAS

  /// Estilo base para tarjetas
  static BoxDecoration get baseCardDecoration => BoxDecoration(
    color: AppStyles.cardColor,
    borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
    border: Border.all(
      color: AppStyles.dividerColor,
      width: 1,
    ),
    boxShadow: AppStyles.cardShadow,
  );

  /// Estilo para tarjetas de información
  static BoxDecoration get infoCardDecoration => BoxDecoration(
    color: AppStyles.infoColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
    border: Border.all(
      color: AppStyles.infoColor.withOpacity(0.2),
      width: 1,
    ),
  );

  /// Estilo para tarjetas de éxito
  static BoxDecoration get successCardDecoration => BoxDecoration(
    color: AppStyles.successColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
    border: Border.all(
      color: AppStyles.successColor.withOpacity(0.2),
      width: 1,
    ),
  );

  /// Estilo para tarjetas de error
  static BoxDecoration get errorCardDecoration => BoxDecoration(
    color: AppStyles.errorColor.withOpacity(0.05),
    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
    border: Border.all(
      color: AppStyles.errorColor.withOpacity(0.2),
      width: 1,
    ),
  );

  // 🎯 ESTILOS DE TEXTO

  /// Estilo para títulos de sección
  static TextStyle get sectionTitleStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppStyles.textPrimary,
  );

  /// Estilo para subtítulos
  static TextStyle get subtitleStyle => const TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppStyles.textSecondary,
  );

  /// Estilo para texto de cuerpo
  static TextStyle get bodyTextStyle => const TextStyle(
    fontSize: 14,
    color: AppStyles.textSecondary,
    height: 1.4,
  );

  /// Estilo para texto pequeño/secundario
  static TextStyle get captionStyle => const TextStyle(
    fontSize: 12,
    color: AppStyles.textTertiary,
  );

  /// Estilo para etiquetas en badges
  static TextStyle get badgeLabelStyle => const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  // 🎯 ESTILOS DE CONTENEDORES

  /// Decoración para badges de estado
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
    color: color,
    borderRadius: BorderRadius.circular(AppStyles.radiusMax),
    boxShadow: [
      BoxShadow(
        color: color.withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  /// Decoración para chips informativos
  static BoxDecoration infoChipDecoration(Color color) => BoxDecoration(
    color: AppStyles.backgroundColor,
    borderRadius: BorderRadius.circular(AppStyles.radiusMax),
    border: Border.all(
      color: color.withOpacity(0.3),
      width: 1,
    ),
  );

  /// Decoración para contenedores de iconos
  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
  );

  /// Decoración para botones circulares
  static BoxDecoration circularButtonDecoration(Color color, {bool isDisabled = false}) => BoxDecoration(
    color: isDisabled 
        ? AppStyles.textSecondary.withOpacity(0.8)
        : color,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: (isDisabled 
            ? AppStyles.textSecondary 
            : color).withOpacity(0.4),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  // 🎯 GRADIENTES

  /// Gradiente principal de la app
  static LinearGradient get primaryGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppStyles.primaryColor,
      AppStyles.primaryLight,
    ],
  );

  /// Gradiente de acento
  static LinearGradient get accentGradient => const LinearGradient(
    colors: [AppStyles.accentColor, AppStyles.accentLight],
  );

  /// Gradiente para overlays de imágenes
  static LinearGradient get imageOverlayGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Colors.black.withOpacity(0.3),
    ],
    stops: const [0.6, 1.0],
  );

  // 🎯 DECORACIONES PARA CARRUSEL

  /// Decoración para items del carrusel
  static BoxDecoration get carouselItemDecoration => BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.12),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  /// Decoración para placeholder de imagen de error
  static BoxDecoration get errorImagePlaceholderDecoration => BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(16),
  );

  // 🎯 DECORACIONES PARA DIÁLOGOS

  /// Forma para diálogos de alerta
  static RoundedRectangleBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
  );

  /// Forma para SnackBars
  static RoundedRectangleBorder get snackBarShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
  );
}