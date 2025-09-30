import 'package:flutter/material.dart';
import 'new_password_colors.dart';
import 'new_password_dimensions.dart';

class NewPasswordStyles {
  
  // Text Styles
  static TextStyle getHeadingStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontXXLarge),
      fontWeight: FontWeight.w700,
      color: NewPasswordColors.textPrimary,
    );
  }
  
  static TextStyle getSubheadingStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium),
      color: NewPasswordColors.textSecondary,
    );
  }
  
  static TextStyle getAppBarTitleStyle(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontXLarge),
    );
  }
  
  static TextStyle getBodyStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontLarge),
    );
  }
  
  static TextStyle getButtonTextStyle(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontLarge),
      letterSpacing: 0.5,
      color: NewPasswordColors.buttonText,
    );
  }
  
  static TextStyle getSectionTitleStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontLarge),
      fontWeight: FontWeight.w700,
      color: NewPasswordColors.textPrimary,
    );
  }
  
  static TextStyle getChipTextStyle(BuildContext context, bool isValid) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, 13.0),
      fontWeight: FontWeight.w600,
      color: isValid ? NewPasswordColors.requirementValidText : NewPasswordColors.requirementInvalidText,
    );
  }
  
  static TextStyle getPasswordStrengthLabelStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium),
      fontWeight: FontWeight.w600,
      color: NewPasswordColors.textHint,
    );
  }
  
  static TextStyle getPasswordStrengthValueStyle(BuildContext context, Color color) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium),
      fontWeight: FontWeight.w600,
      color: color,
    );
  }
  
  static TextStyle getSnackbarTextStyle(BuildContext context) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium),
    );
  }
  
  static TextStyle getChipCountStyle(BuildContext context, bool isComplete) {
    return TextStyle(
      fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontSmall),
      fontWeight: FontWeight.w600,
      color: isComplete ? NewPasswordColors.chipSuccessText : NewPasswordColors.chipNeutralText,
    );
  }
  
  // Input Decoration Styles
  static InputDecoration getTextFieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: NewPasswordColors.textHint,
        fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium),
      ),
      filled: true,
      fillColor: NewPasswordColors.surface,
      contentPadding: EdgeInsets.symmetric(
        horizontal: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge),
        vertical: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
        ),
        borderSide: BorderSide(color: NewPasswordColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
        ),
        borderSide: BorderSide(color: NewPasswordColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
        ),
        borderSide: BorderSide(color: NewPasswordColors.borderFocused, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(
          NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
        ),
        borderSide: BorderSide(color: NewPasswordColors.borderError, width: 2),
      ),
    );
  }
  
  // Container Decorations
  static BoxDecoration getCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: NewPasswordColors.surface,
      borderRadius: BorderRadius.circular(
        NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusXLarge)
      ),
      boxShadow: [
        BoxShadow(
          color: NewPasswordColors.shadowMedium,
          blurRadius: NewPasswordDimensions.elevationXLarge,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getRequirementsCardDecoration(BuildContext context) {
    return BoxDecoration(
      color: NewPasswordColors.surface,
      borderRadius: BorderRadius.circular(
        NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusXLarge)
      ),
      border: Border.all(color: NewPasswordColors.surfaceTint, width: 1),
      boxShadow: [
        BoxShadow(
          color: NewPasswordColors.shadowLight,
          blurRadius: NewPasswordDimensions.elevationLarge,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getChipDecoration(BuildContext context, bool isValid) {
    return BoxDecoration(
      color: isValid ? NewPasswordColors.requirementValidBg : NewPasswordColors.requirementInvalidBg,
      borderRadius: BorderRadius.circular(
        NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusXLarge)
      ),
      border: Border.all(
        color: isValid ? NewPasswordColors.requirementValidBorder : NewPasswordColors.requirementInvalidBorder,
        width: 1.5,
      ),
      boxShadow: isValid ? [
        BoxShadow(
          color: NewPasswordColors.greenWithOpacity(0.1),
          blurRadius: NewPasswordDimensions.elevationSmall * 2,
          offset: const Offset(0, 2),
        ),
      ] : null,
    );
  }
  
  static BoxDecoration getIconContainerDecoration(BuildContext context, Color backgroundColor) {
    return BoxDecoration(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(
        NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
      ),
    );
  }
  
  static BoxDecoration getChipCountDecoration(BuildContext context, bool isComplete) {
    return BoxDecoration(
      color: isComplete ? NewPasswordColors.chipSuccessBackground : NewPasswordColors.chipNeutralBackground,
      borderRadius: BorderRadius.circular(
        NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusLarge)
      ),
    );
  }
  
  // Button Styles
  static ButtonStyle getPrimaryButtonStyle(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: NewPasswordColors.buttonPrimary,
      disabledBackgroundColor: NewPasswordColors.buttonDisabled,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusXLarge)
        ),
      ),
      elevation: NewPasswordDimensions.elevationNone,
      shadowColor: NewPasswordColors.primaryWithOpacity(0.3),
    );
  }
  
  static ButtonStyle getSecondaryButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: NewPasswordColors.textHint,
      padding: EdgeInsets.symmetric(
        horizontal: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge),
        vertical: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium),
      ),
    );
  }
  
  // SnackBar Styles
  static SnackBar getSnackBar(BuildContext context, String message, bool isSuccess) {
    return SnackBar(
      content: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: Colors.white,
            size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconXLarge),
          ),
          SizedBox(width: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceLarge)),
          Expanded(
            child: Text(
              message, 
              style: getSnackbarTextStyle(context),
            )
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: isSuccess ? NewPasswordColors.snackbarSuccess : NewPasswordColors.snackbarError,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NewPasswordDimensions.radiusMedium)
      ),
      margin: EdgeInsets.all(NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),
      duration: Duration(seconds: isSuccess ? 3 : 4),
    );
  }
  
  // AppBar Style
  static AppBarTheme getAppBarTheme() {
    return AppBarTheme(
      backgroundColor: NewPasswordColors.surface,
      foregroundColor: NewPasswordColors.primary,
      elevation: NewPasswordDimensions.elevationNone,
      shadowColor: NewPasswordColors.shadowDark,
      scrolledUnderElevation: 1,
    );
  }
}