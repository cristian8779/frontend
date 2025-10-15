import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppStyles {
  // Text Styles
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const heading2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const heading3 = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textGreyDark,
    height: 1.4,
    letterSpacing: -0.1,
  );

  static const bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.textGreyDark,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    color: AppColors.textGreyDark,
    fontWeight: FontWeight.w500,
  );

  static const caption = TextStyle(
    fontSize: 13,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.w500,
  );

  static const label = TextStyle(
    fontSize: 12,
    color: AppColors.textTertiary,
    fontWeight: FontWeight.w400,
  );

  static const priceText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const priceLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: Colors.white,
  );

  // Button Text Styles
  static const buttonText = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );

  // Border Radius
  static const radiusSmall = BorderRadius.all(Radius.circular(8));
  static const radiusMedium = BorderRadius.all(Radius.circular(12));
  static const radiusLarge = BorderRadius.all(Radius.circular(16));
  static const radiusXLarge = BorderRadius.all(Radius.circular(20));

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> lightShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static BoxShadow successShadow = BoxShadow(
    color: AppColors.success.withOpacity(0.3),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );

  // Paddings
  static const paddingSmall = EdgeInsets.all(8);
  static const paddingMedium = EdgeInsets.all(16);
  static const paddingLarge = EdgeInsets.all(20);

  static const paddingHorizontal = EdgeInsets.symmetric(horizontal: 20);
  static const paddingVertical = EdgeInsets.symmetric(vertical: 16);
}