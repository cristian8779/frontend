import 'package:flutter/material.dart';
import 'profile_colors.dart';
import 'profile_dimensions.dart';

class ProfileDecorations {
  // Header decoration
  static BoxDecoration getHeaderDecoration() {
    return BoxDecoration(
      gradient: ProfileColors.headerGradient,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(ProfileDimensions.headerRadius),
        bottomRight: Radius.circular(ProfileDimensions.headerRadius),
      ),
    );
  }
  
  // Avatar border decoration
  static BoxDecoration getAvatarBorderDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: ProfileColors.borderBlue, width: ProfileDimensions.borderWidthThick),
      boxShadow: ProfileColors.primaryShadow,
    );
  }
  
  // Badge decoration
  static BoxDecoration getBadgeDecoration() {
    return BoxDecoration(
      gradient: ProfileColors.primaryGradient,
      borderRadius: BorderRadius.circular(ProfileDimensions.badgeRadius),
      boxShadow: ProfileColors.buttonShadow,
    );
  }
  
  // Notification decoration
  static BoxDecoration getNotificationDecoration() {
    return BoxDecoration(
      color: ProfileColors.orangeLight.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ProfileDimensions.notificationRadius),
      border: Border.all(color: ProfileColors.borderOrange),
    );
  }
  
  // Card decorations
  static BoxDecoration getCardDecoration() {
    return BoxDecoration(
      color: ProfileColors.surface,
      borderRadius: BorderRadius.circular(ProfileDimensions.cardRadius),
      border: Border.all(color: ProfileColors.borderLight, width: ProfileDimensions.borderWidthThin),
      boxShadow: ProfileColors.cardShadowMedium,
    );
  }
  
  static BoxDecoration getInputFieldDecoration() {
    return BoxDecoration(
      color: ProfileColors.surface,
      borderRadius: BorderRadius.circular(ProfileDimensions.inputRadius),
      border: Border.all(color: ProfileColors.border, width: ProfileDimensions.borderWidth),
      boxShadow: ProfileColors.cardShadow,
    );
  }
  
  static BoxDecoration getAddressContainerDecoration() {
    return BoxDecoration(
      color: ProfileColors.surface,
      borderRadius: BorderRadius.circular(ProfileDimensions.cardRadius),
      border: Border.all(color: ProfileColors.borderLight, width: ProfileDimensions.borderWidth),
      boxShadow: ProfileColors.cardShadowMedium,
    );
  }
  
  // Icon container decorations
  static BoxDecoration getIconContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ProfileDimensions.iconContainerRadius),
    );
  }
  
  static BoxDecoration getLargeIconContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(ProfileDimensions.iconContainerLargeRadius),
    );
  }
  
  // Modal decorations
  static BoxDecoration getModalDecoration() {
    return const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    );
  }
  
  static BoxDecoration getModalHandleDecoration() {
    return BoxDecoration(
      color: ProfileColors.borderLight,
      borderRadius: BorderRadius.circular(2),
    );
  }
  
  // Dialog decoration
  static ShapeBorder getDialogShape() {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
  }
}