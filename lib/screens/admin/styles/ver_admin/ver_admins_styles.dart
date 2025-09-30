import 'package:flutter/material.dart';
import 'ver_admins_colors.dart';
import 'ver_admins_dimensions.dart';

class VerAdminsStyles {
  final VerAdminsDimensions dimensions;
  
  VerAdminsStyles(this.dimensions);
  
  // App Bar Text Style
  TextStyle get appBarTitleStyle => TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    fontSize: dimensions.appBarTitleSize,
  );
  
  // Stats Card Styles
  TextStyle get statsTitleStyle => TextStyle(
    fontSize: dimensions.statsTitleSize,
    color: VerAdminsColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  
  TextStyle get statsCountStyle => TextStyle(
    fontSize: dimensions.statsCountSize,
    fontWeight: FontWeight.bold,
    color: VerAdminsColors.textPrimary,
  );
  
  BoxDecoration get statsCardDecoration => BoxDecoration(
    color: VerAdminsColors.cardBackground,
    borderRadius: BorderRadius.circular(dimensions.statsRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: dimensions.isTablet ? 15 : 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  BoxDecoration get statsIconDecoration => BoxDecoration(
    color: VerAdminsColors.blueLight,
    borderRadius: BorderRadius.circular(dimensions.statsIconRadius),
  );
  
  // Admin Card Styles
  TextStyle get cardTitleStyle => TextStyle(
    fontSize: dimensions.cardTitleSize,
    fontWeight: FontWeight.w600,
    color: VerAdminsColors.textPrimary,
  );
  
  TextStyle get cardSubtitleStyle => TextStyle(
    fontSize: dimensions.cardSubtitleSize,
    color: VerAdminsColors.textSecondary,
  );
  
  TextStyle cardRolStyle(Color color) => TextStyle(
    fontSize: dimensions.cardRolTextSize,
    fontWeight: FontWeight.w600,
    color: color,
  );
  
  BoxDecoration get cardDecoration => BoxDecoration(
    color: VerAdminsColors.cardBackground,
    borderRadius: BorderRadius.circular(dimensions.cardRadius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: dimensions.isTablet ? 15 : 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
  
  BoxDecoration avatarDecoration(MaterialColor color) => BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color[400]!,
        color[600]!,
      ],
    ),
    borderRadius: BorderRadius.circular(dimensions.avatarRadius),
  );
  
  TextStyle get avatarTextStyle => TextStyle(
    color: Colors.white,
    fontSize: dimensions.avatarTextSize,
    fontWeight: FontWeight.bold,
  );
  
  BoxDecoration rolBadgeDecoration(MaterialColor color) => BoxDecoration(
    color: color[100],
    borderRadius: BorderRadius.circular(dimensions.cardRolRadius),
  );
  
  // Dialog Styles
  ShapeBorder get dialogShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(dimensions.dialogRadius),
  );
  
  TextStyle get dialogTitleStyle => TextStyle(
    fontSize: dimensions.dialogTitleSize,
  );
  
  TextStyle get dialogContentStyle => TextStyle(
    fontSize: dimensions.dialogContentSize,
  );
  
  TextStyle get dialogNameStyle => TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: dimensions.dialogNameSize,
  );
  
  TextStyle get dialogWarningStyle => TextStyle(
    color: VerAdminsColors.textSecondary,
    fontSize: dimensions.dialogWarningSize,
  );
  
  TextStyle get dialogCancelStyle => TextStyle(
    color: VerAdminsColors.textSecondary,
    fontSize: dimensions.dialogButtonSize,
  );
  
  TextStyle get dialogDeleteStyle => TextStyle(
    fontSize: dimensions.dialogButtonSize,
  );
  
  ButtonStyle get dialogDeleteButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: VerAdminsColors.errorRed,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(dimensions.dialogButtonRadius),
    ),
    padding: EdgeInsets.symmetric(
      horizontal: dimensions.dialogButtonPaddingH,
      vertical: dimensions.dialogButtonPaddingV,
    ),
  );
  
  // Loading Dialog Styles
  TextStyle get loadingTextStyle => TextStyle(
    fontSize: dimensions.loadingDialogTextSize,
  );
  
  // Empty State Styles
  BoxDecoration get emptyIconDecoration => BoxDecoration(
    color: VerAdminsColors.blueLighter,
    borderRadius: BorderRadius.circular(dimensions.stateIconRadius),
  );
  
  TextStyle get emptyTitleStyle => TextStyle(
    fontSize: dimensions.stateTitleSize,
    fontWeight: FontWeight.bold,
    color: VerAdminsColors.textDark,
  );
  
  TextStyle get emptySubtitleStyle => TextStyle(
    fontSize: dimensions.stateSubtitleSize,
    color: VerAdminsColors.textSecondary,
    height: 1.5,
  );
  
  TextStyle get emptyHintStyle => TextStyle(
    fontSize: dimensions.stateHintSize,
    color: VerAdminsColors.textTertiary,
    fontStyle: FontStyle.italic,
  );
  
  // Error State Styles
  BoxDecoration get errorIconDecoration => BoxDecoration(
    color: VerAdminsColors.redLight,
    borderRadius: BorderRadius.circular(dimensions.errorIconRadius),
  );
  
  TextStyle get errorTitleStyle => TextStyle(
    fontSize: dimensions.errorTitleSize,
    fontWeight: FontWeight.bold,
    color: VerAdminsColors.textDark,
  );
  
  TextStyle get errorMessageStyle => TextStyle(
    fontSize: dimensions.stateSubtitleSize,
    color: VerAdminsColors.textSecondary,
  );
  
  // SnackBar Styles
  ShapeBorder get snackBarShape => RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(dimensions.snackBarRadius),
  );
  
  TextStyle get snackBarTextStyle => TextStyle(
    fontSize: dimensions.snackBarTextSize,
  );
  
  // Gradient
  LinearGradient get appBarGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      VerAdminsColors.primaryBlue!,
      VerAdminsColors.primaryBlueDark!,
    ],
  );
}