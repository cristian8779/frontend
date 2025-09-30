import 'package:flutter/material.dart';
import 'profile_colors.dart';
import 'profile_dimensions.dart';

class ProfileButtonStyles {
  // Primary elevated button
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: ProfileColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProfileDimensions.buttonRadius),
      ),
      elevation: 3,
      shadowColor: ProfileColors.primary.withOpacity(0.3),
    );
  }
  
  // Secondary outlined button
  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide(
        color: ProfileColors.textHint,
        width: ProfileDimensions.borderWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProfileDimensions.buttonRadius),
      ),
    );
  }
  
  // Danger outlined button
  static ButtonStyle getDangerButtonStyle() {
    return OutlinedButton.styleFrom(
      side: BorderSide(
        color: Colors.red,
        width: ProfileDimensions.borderWidth,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ProfileDimensions.buttonRadius),
      ),
      foregroundColor: Colors.red,
    );
  }
  
  // Text button styles
  static ButtonStyle getTextButtonStyle({Color? color}) {
    return TextButton.styleFrom(
      foregroundColor: color ?? ProfileColors.primary,
    );
  }
  
  static ButtonStyle getCancelTextButtonStyle() {
    return TextButton.styleFrom(
      foregroundColor: Colors.red,
    );
  }
  
  // Icon button for camera
  static Widget getCameraIconButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required bool hasSelectedImage,
  }) {
    return Container(
      padding: EdgeInsets.all(
        ProfileDimensions.getCameraIconPadding(context),
      ),
      decoration: BoxDecoration(
        gradient: hasSelectedImage
            ? ProfileColors.orangeGradient
            : ProfileColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: hasSelectedImage
            ? ProfileColors.orangeShadow
            : ProfileColors.blueShadow,
      ),
      child: GestureDetector(
        onTap: onPressed,
        child: Icon(
          hasSelectedImage ? Icons.photo : Icons.camera_alt,
          color: Colors.white,
          size: ProfileDimensions.getCameraIconSize(context),
        ),
      ),
    );
  }
  
  // Progress indicator widget for buttons
  static Widget getButtonProgressIndicator(BuildContext context) {
    return SizedBox(
      height: ProfileDimensions.getProgressSize(context),
      width: ProfileDimensions.getProgressSize(context),
      child: const CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      ),
    );
  }
  
  // Modal progress indicator
  static Widget getModalProgressIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  // Loading overlay for images
  static Widget getImageLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
