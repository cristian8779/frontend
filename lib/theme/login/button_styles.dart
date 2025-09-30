import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class ButtonStyles {
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);

    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      elevation: AppDimensions.elevationLow,
      shadowColor: AppColors.shadowPrimary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isSmallScreen ? AppDimensions.radiusMedium : AppDimensions.radiusLarge,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: 24,
      ),
      textStyle: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static ButtonStyle getOutlinedButtonStyle(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);

    return OutlinedButton.styleFrom(
      backgroundColor: AppColors.surface,
      side: const BorderSide(color: AppColors.secondary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isSmallScreen ? AppDimensions.radiusMedium : AppDimensions.radiusLarge,
        ),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isSmallScreen ? 12 : 16,
        horizontal: 24,
      ),
      textStyle: TextStyle(
        fontSize: isSmallScreen ? 14 : 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static Widget getLoadingIndicator(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);

    return SizedBox(
      height: isSmallScreen ? 20 : 24,
      width: isSmallScreen ? 20 : 24,
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
      ),
    );
  }

  static Widget getGoogleButtonContent(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);

    return Row(
      mainAxisSize: MainAxisSize.min, // 🔑 evita expansión innecesaria
      children: [
        Image.asset(
          'assets/google.png',
          height: isSmallScreen ? AppDimensions.iconSmall : AppDimensions.iconMedium,
          width: isSmallScreen ? AppDimensions.iconSmall : AppDimensions.iconMedium,
        ),
        SizedBox(width: isSmallScreen ? AppDimensions.spaceSmall : 12),
        Flexible( // 🔑 evita que se corte el texto
          child: Text(
            "Iniciar con Google",
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isSmallScreen ? 14 : 16,
              color: AppColors.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
