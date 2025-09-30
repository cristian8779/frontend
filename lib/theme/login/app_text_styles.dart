import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTextStyles {
  // Base Styles
  static const _basePrimary = TextStyle(color: AppColors.textPrimary);
  static const _baseOnPrimary = TextStyle(color: AppColors.textOnPrimary);

  // Headers
  static final headingLarge = _basePrimary.copyWith(
    fontSize: 36,
    fontWeight: FontWeight.bold,
  );
  static final headingMedium = headingLarge.copyWith(fontSize: 30);
  static final headingSmall = headingLarge.copyWith(fontSize: 24);
  static final headingXSmall = headingLarge.copyWith(fontSize: 22);

  // Body
  static final bodyLarge = _baseOnPrimary.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static final bodyMedium = bodyLarge.copyWith(fontSize: 16);
  static final bodySmall = bodyLarge.copyWith(fontSize: 14);

  // Buttons
  static final buttonLarge = _baseOnPrimary.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );
  static final buttonMedium = buttonLarge.copyWith(fontSize: 16);
  static final buttonSmall = buttonLarge.copyWith(fontSize: 14);

  // Outlined Buttons
  static final outlinedButtonMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );
  static final outlinedButtonSmall = outlinedButtonMedium.copyWith(fontSize: 14);

  // Links
  static final linkMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
  );
  static final linkSmall = linkMedium.copyWith(fontSize: 13);

  // Regular text
  static final textMedium = _basePrimary.copyWith(fontSize: 15);
  static final textSmall = textMedium.copyWith(fontSize: 13);

  // Inputs
  static final inputMedium = _basePrimary.copyWith(fontSize: 16);
  static final inputSmall = inputMedium.copyWith(fontSize: 14);

  // Labels
  static final labelMedium = _basePrimary.copyWith(fontSize: 16);
  static final labelSmall = labelMedium.copyWith(fontSize: 14);

  // SnackBars
  static final snackBarMedium = _baseOnPrimary.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static final snackBarSmall = snackBarMedium.copyWith(fontSize: 14);

  // Responsive helpers
  static TextStyle getResponsiveHeading(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > AppDimensions.tabletBreakpoint) return headingLarge;
    if (screenWidth < AppDimensions.smallScreenBreakpoint) return headingXSmall;
    if (screenWidth < 400) return headingSmall;
    return headingMedium;
  }

  static TextStyle getResponsiveButton(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? buttonSmall : buttonMedium;

  static TextStyle getResponsiveOutlinedButton(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? outlinedButtonSmall : outlinedButtonMedium;

  static TextStyle getResponsiveLink(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? linkSmall : linkMedium;

  static TextStyle getResponsiveText(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? textSmall : textMedium;

  static TextStyle getResponsiveInput(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? inputSmall : inputMedium;

  static TextStyle getResponsiveLabel(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? labelSmall : labelMedium;

  static TextStyle getResponsiveSnackBar(BuildContext context) =>
      AppDimensions.isSmallScreen(context) ? snackBarSmall : snackBarMedium;
}
