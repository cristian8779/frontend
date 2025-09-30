import 'package:flutter/material.dart';
import 'color_scheme.dart';
import 'responsive_helper.dart';

/// Estilos para los widgets de la pantalla Forgot Password
class ForgotPasswordStyles {
  
  /// Estilo para el título principal
  static TextStyle titleStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.titleSize,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Estilo para el título con color primario
  static TextStyle titlePrimaryStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.titleSize,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  /// Estilo para el subtítulo
  static TextStyle subtitleStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.bodySize,
      color: colorScheme.onSurfaceVariant,
      height: 1.5,
      letterSpacing: 0.1,
    );
  }

  /// Estilo para las etiquetas de campo
  static TextStyle labelStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.labelSize,
      fontWeight: FontWeight.w600,
      color: colorScheme.onSurface,
      letterSpacing: 0.1,
    );
  }

  /// Estilo para el texto del botón genérico
  static TextStyle buttonTextStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.buttonTextSize,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  /// Estilo para el texto de entrada
  static TextStyle inputTextStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.inputTextSize,
      color: colorScheme.onSurface,
      letterSpacing: 0.2,
    );
  }

  /// Estilo para el texto de ayuda/hint
  static TextStyle hintTextStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      color: colorScheme.onSurfaceVariant.withOpacity(0.6),
      fontSize: responsive.inputTextSize,
    );
  }

  /// Estilo para mensajes de error
  static TextStyle errorTextStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.captionSize,
      color: colorScheme.error,
      fontWeight: FontWeight.w500,
    );
  }

  /// Estilo para información de reenvío
  static TextStyle resendInfoStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      fontSize: responsive.captionSize,
      color: colorScheme.primary,
      fontWeight: FontWeight.w500,
    );
  }

  /// Estilo para el texto del botón de volver
  static TextStyle backButtonTextStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: responsive.labelSize,
      letterSpacing: 0.1,
    );
  }

  /// Decoración para el contenedor principal
  static BoxDecoration mainCardDecoration(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(responsive.borderRadius),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(colorScheme.isDark ? 0.3 : 0.08),
          blurRadius: responsive.shadowBlur,
          offset: const Offset(0, 10),
          spreadRadius: 0,
        ),
        if (!colorScheme.isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: responsive.shadowBlur * 2,
            offset: const Offset(0, 20),
          ),
      ],
    );
  }

  /// Decoración para el campo de entrada
  static BoxDecoration inputFieldDecoration(
    AppColorScheme colorScheme, 
    ResponsiveHelper responsive,
    {bool hasError = false, bool hasFocus = false, bool isValid = false}
  ) {
    Color borderColor = Colors.transparent;
    
    if (hasError) {
      borderColor = colorScheme.error.withOpacity(0.6);
    } else if (hasFocus) {
      borderColor = colorScheme.primary.withOpacity(0.6);
    } else if (isValid) {
      borderColor = Colors.green.withOpacity(0.6);
    }

    return BoxDecoration(
      borderRadius: BorderRadius.circular(responsive.inputRadius),
      border: Border.all(
        color: borderColor,
        width: 2,
      ),
    );
  }

  /// Decoración para el input
  static InputDecoration inputDecoration(
    AppColorScheme colorScheme, 
    ResponsiveHelper responsive,
    {required String hintText, IconData? prefixIcon}
  ) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: hintTextStyle(colorScheme, responsive),
      filled: true,
      fillColor: colorScheme.isDark 
          ? colorScheme.onSurface.withOpacity(0.05)
          : colorScheme.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.inputPadding,
        vertical: responsive.inputPadding * 0.9,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.inputRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.inputRadius),
        borderSide: BorderSide.none,
      ),
      prefixIcon: prefixIcon != null 
          ? Padding(
              padding: EdgeInsets.only(
                left: responsive.inputPadding,
                right: responsive.inputPadding * 0.6,
              ),
              child: Icon(
                prefixIcon,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                size: responsive.iconSize,
              ),
            )
          : null,
    );
  }

  /// Decoración para la ilustración hero
  static BoxDecoration heroDecoration(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withOpacity(0.1),
          colorScheme.primary.withOpacity(0.05),
        ],
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.1),
          blurRadius: responsive.shadowBlur,
          spreadRadius: 5,
        ),
      ],
    );
  }

  /// Decoración para el contenedor de información de reenvío
  static BoxDecoration resendInfoDecoration(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return BoxDecoration(
      color: colorScheme.primary.withOpacity(0.08),
      borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
      border: Border.all(
        color: colorScheme.primary.withOpacity(0.2),
        width: 1,
      ),
    );
  }

  /// Decoración para el indicador de validez del email
  static BoxDecoration emailValidityDecoration(bool isValid, ResponsiveHelper responsive) {
    final color = isValid ? Colors.green : Colors.red;
    return BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    );
  }

  /// Estilo para el botón principal
  static ButtonStyle primaryButtonStyle(AppColorScheme colorScheme, ResponsiveHelper responsive, {bool isLoading = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isLoading 
          ? colorScheme.primary.withOpacity(0.7)
          : colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: isLoading ? 0 : (responsive.isDesktop ? 16 : 12),
      shadowColor: colorScheme.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.inputRadius),
      ),
      padding: EdgeInsets.zero,
    );
  }

  /// Estilo para el botón de volver
  static ButtonStyle backButtonButtonStyle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return TextButton.styleFrom(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.inputPadding,
        vertical: responsive.inputPadding * 0.7,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
      ),
    );
  }
}
