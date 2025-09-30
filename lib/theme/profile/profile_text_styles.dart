import 'package:flutter/material.dart';
import 'profile_colors.dart';
import 'profile_dimensions.dart';

class ProfileTextStyles {
  // Title styles
  static TextStyle getMainTitleStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getTitleFontSize(context),
    fontWeight: FontWeight.bold,
    color: ProfileColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static TextStyle getCreateTitleStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getCreateTitleFontSize(context),
    fontWeight: FontWeight.bold,
    color: ProfileColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static TextStyle getSubtitleStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getSubtitleFontSize(context),
    color: ProfileColors.textSecondary,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle getSectionTitleStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getFontSize(context, 16, 18, 18),
    fontWeight: FontWeight.w600,
    color: ProfileColors.textLabel,
  );
  
  static TextStyle getAppBarTitleStyle(BuildContext context) => TextStyle(
    color: Colors.black87,
    fontWeight: FontWeight.w600,
    fontSize: ProfileDimensions.getFontSize(context, 18, 20, 22),
  );
  
  // Badge and notification styles
  static TextStyle getBadgeStyle(BuildContext context) => TextStyle(
    color: Colors.white,
    fontSize: ProfileDimensions.getSmallFontSize(context),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );
  
  static TextStyle getNotificationStyle(BuildContext context) => TextStyle(
    color: ProfileColors.orange,
    fontSize: ProfileDimensions.getHintFontSize(context),
    fontWeight: FontWeight.w500,
  );
  
  // Label styles
  static TextStyle getLabelStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getLabelFontSize(context),
    fontWeight: FontWeight.w500,
    color: ProfileColors.textLabel,
  );
  
  static TextStyle getRequiredLabelStyle() => const TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.bold,
    fontSize: 16,
  );
  
  // Input styles
  static TextStyle getInputStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getBodyFontSize(context),
    color: ProfileColors.textPrimary,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle getHintStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getBodyFontSize(context),
    color: ProfileColors.textHint,
    fontWeight: FontWeight.normal,
  );
  
  // Display value styles
  static TextStyle getDisplayValueStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getBodyFontSize(context),
    color: ProfileColors.textPrimary,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  static TextStyle getEmptyValueStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getBodyFontSize(context),
    color: ProfileColors.textHint,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
  
  // Button styles
  static TextStyle getButtonTextStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getButtonFontSize(context),
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static TextStyle getSecondaryButtonTextStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getButtonFontSize(context),
    fontWeight: FontWeight.w600,
    color: ProfileColors.textSecondary,
  );
  
  static TextStyle getActionButtonStyle(BuildContext context, {Color? color}) => TextStyle(
    color: color ?? ProfileColors.primary,
    fontWeight: FontWeight.w600,
    fontSize: ProfileDimensions.getLabelFontSize(context),
  );
  
  static TextStyle getCancelButtonStyle(BuildContext context) => TextStyle(
    color: Colors.red,
    fontWeight: FontWeight.w600,
    fontSize: ProfileDimensions.getLabelFontSize(context),
  );
  
  // Dialog styles
  static TextStyle getDialogTitleStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getFontSize(context, 16, 18, 20),
  );
  
  static TextStyle getDialogContentStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getLabelFontSize(context),
  );
  
  static TextStyle getDialogActionStyle(BuildContext context) => TextStyle(
    fontSize: ProfileDimensions.getLabelFontSize(context),
  );
  
  // Toast style
  static double getToastFontSize(BuildContext context) => ProfileDimensions.getToastFontSize(context);
}