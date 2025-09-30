import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'responsive_helper.dart';

class InputDecorations {
  // Estilo base con contexto
  static InputDecoration getFieldDecoration(
    String label,
    BuildContext context, {
    Widget? suffixIcon,
  }) {
    final responsive = ResponsiveHelper.of(context);

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: responsive.labelFontSize,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: responsive.fieldPadding,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(responsive.borderRadius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
    );
  }

  // Campo para contraseñas
  static InputDecoration getPasswordFieldDecoration(
    String label,
    BuildContext context,
    bool obscurePassword,
    VoidCallback toggleVisibility,
  ) {
    return getFieldDecoration(label, context).copyWith(
      suffixIcon: IconButton(
        icon: Icon(
          obscurePassword
              ? Icons.visibility_off_rounded
              : Icons.visibility_rounded,
          color: AppColors.secondary,
        ),
        onPressed: toggleVisibility,
      ),
    );
  }

  // Método de respaldo sin contexto (ej: tests, pantallas mínimas)
  static InputDecoration getSafeFieldDecoration(
    String label, {
    Widget? suffixIcon,
    bool isSmallScreen = false,
  }) {
    final fontSize = isSmallScreen ? 14.0 : 16.0;
    final radius = isSmallScreen ? AppDimensions.radiusMedium : AppDimensions.radiusLarge;

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: fontSize,
      ),
      filled: true,
      fillColor: AppColors.surfaceVariant,
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 12 : 16, // 🔑 más balanceado
      ),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
    );
  }
}
