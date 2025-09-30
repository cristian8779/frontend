import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'app_colors.dart';

class VerificarCodigoStyles {
  
  // Estilos de texto
  static TextStyle titleTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle titleAccentTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
      height: 1.2,
      letterSpacing: -0.5,
    );
  }

  static TextStyle subtitleTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 16,
      color: colorScheme.onSurfaceVariant,
      height: 1.4,
    );
  }

  static TextStyle emailTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 16,
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
  }

  static TextStyle appBarTitleStyle(AppColorScheme colorScheme) {
    return TextStyle(
      color: colorScheme.onBackground,
      fontWeight: FontWeight.w600,
      fontSize: 18,
    );
  }

  static TextStyle pinFieldTextStyle(AppColorScheme colorScheme, double fieldWidth) {
    return TextStyle(
      fontSize: fieldWidth > 45 ? 20 : 16,
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
    );
  }

  static TextStyle errorMessageTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 14,
      color: colorScheme.error,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle buttonTextStyle() {
    return const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
    );
  }

  static TextStyle loadingTextStyle() {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white.withOpacity(0.9),
    );
  }

  static TextStyle resendQuestionStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 14,
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle resendButtonTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 15,
      color: colorScheme.primary,
      fontWeight: FontWeight.w600,
    );
  }

  static TextStyle countdownTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      fontSize: 14,
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
    );
  }

  static TextStyle backButtonTextStyle(AppColorScheme colorScheme) {
    return TextStyle(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontSize: 15,
      letterSpacing: 0.1,
    );
  }

  // Decoraciones de contenedores
  static BoxDecoration heroIllustrationDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary.withOpacity(0.15),
          colorScheme.primary.withOpacity(0.05),
        ],
      ),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: colorScheme.primary.withOpacity(0.1),
          blurRadius: 30,
          spreadRadius: 5,
        ),
      ],
    );
  }

  static BoxDecoration mainCardDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: colorScheme.outline.withOpacity(0.1),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(colorScheme.isDark ? 0.3 : 0.08),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
        if (!colorScheme.isDark)
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
      ],
    );
  }

  static BoxDecoration errorMessageDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: colorScheme.error.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  static BoxDecoration resendButtonDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.primary.withOpacity(0.1),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(
        color: colorScheme.primary.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  static BoxDecoration countdownContainerDecoration(AppColorScheme colorScheme) {
    return BoxDecoration(
      color: colorScheme.surfaceVariant,
      borderRadius: BorderRadius.circular(25),
    );
  }

  // Estilos de botones
  static ButtonStyle elevatedButtonStyle(AppColorScheme colorScheme, bool isLoading) {
    return ElevatedButton.styleFrom(
      backgroundColor: isLoading 
          ? colorScheme.primary.withOpacity(0.7)
          : colorScheme.primary,
      foregroundColor: Colors.white,
      elevation: isLoading ? 0 : 12,
      shadowColor: colorScheme.primary.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle textButtonStyle() {
    return TextButton.styleFrom(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  // Configuración de PinTheme
  static PinTheme pinTheme(AppColorScheme colorScheme, double fieldWidth, double fieldHeight) {
    return PinTheme(
      shape: PinCodeFieldShape.box,
      borderRadius: BorderRadius.circular(16),
      fieldHeight: fieldHeight,
      fieldWidth: fieldWidth,
      borderWidth: 2,
      activeColor: colorScheme.primary,
      inactiveColor: colorScheme.outline.withOpacity(0.3),
      selectedColor: colorScheme.primary,
      selectedFillColor: colorScheme.primary.withOpacity(0.08),
      inactiveFillColor: colorScheme.surfaceVariant,
      activeFillColor: colorScheme.primary.withOpacity(0.12),
      disabledColor: colorScheme.outline.withOpacity(0.2),
      errorBorderColor: colorScheme.error,
    );
  }

  // Constantes de diseño
  static const double heroIllustrationSize = 0.5; // Porcentaje del ancho de pantalla
  static const double heroIconSize = 0.2; // Porcentaje del ancho de pantalla
  static const double mainCardPadding = 32.0;
  static const double mainCardBorderRadius = 28.0;
  static const double buttonHeight = 58.0;
  static const double buttonBorderRadius = 16.0;
  static const double pinFieldBorderRadius = 16.0;
  static const double errorMessageBorderRadius = 12.0;
  static const double resendButtonBorderRadius = 25.0;
  
  // Espaciados
  static const double spacingXS = 8.0;
  static const double spacingS = 12.0;
  static const double spacingM = 16.0;
  static const double spacingL = 20.0;
  static const double spacingXL = 24.0;
  static const double spacingXXL = 32.0;
  static const double spacingXXXL = 40.0;

  // Tamaños de iconos
  static const double appBarIconSize = 22.0;
  static const double errorIconSize = 20.0;
  static const double buttonIconSize = 20.0;
  static const double resendIconSize = 18.0;
  static const double countdownIconSize = 16.0;
  static const double backIconSize = 18.0;
  static const double loadingIndicatorSize = 18.0;

  // Duraciones de animación
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration slideAnimationDuration = Duration(milliseconds: 600);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 100);
  static const Duration shakeAnimationDuration = Duration(milliseconds: 600);
  static const Duration pulseAnimationDuration = Duration(milliseconds: 1000);
  static const Duration containerAnimationDuration = Duration(milliseconds: 300);
  static const Duration switcherAnimationDuration = Duration(milliseconds: 400);
  static const Duration notificationAnimationDuration = Duration(milliseconds: 600);

  // Delays de animación
  static const Duration fadeAnimationDelay = Duration(milliseconds: 100);
  static const Duration slideAnimationDelay = Duration(milliseconds: 200);
  
  // Configuración de PinCode
  static const int pinLength = 6;
  static const double minFieldWidth = 40.0;
  static const double maxFieldWidth = 60.0;
  static const double minFieldHeight = 50.0;
  static const double maxFieldHeight = 70.0;
  static const double fieldAspectRatio = 1.2;
  static const double fieldsSpacing = 50.0; // Espacio entre campos

  // Configuración de contador
  static const int resendCountdownSeconds = 60;
  static const int maxAttempts = 3;

  // Configuración de notificaciones
  static const int notificationDurationMs = 4000;
  static const double notificationTopOffset = 16.0;
  static const double notificationHorizontalPadding = 20.0;
  static const double notificationBorderRadius = 20.0;
  static const double notificationProgressBarHeight = 3.0;
}