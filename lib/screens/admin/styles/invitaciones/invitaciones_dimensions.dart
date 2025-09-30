import 'package:flutter/material.dart';

class InvitacionesDimensions {
  // Padding
  static double getPadding(Size size) {
    if (size.width < 600) return 16.0;
    if (size.width < 900) return 20.0;
    return 24.0;
  }

  static EdgeInsets getCardPadding(bool isSmall) => EdgeInsets.all(isSmall ? 16 : 20);
  
  static EdgeInsets getContentPadding(bool isSmall) => EdgeInsets.all(isSmall ? 12 : 16);
  
  static EdgeInsets getSmallPadding(bool isSmall) => EdgeInsets.all(isSmall ? 10 : 12);

  static EdgeInsets getDialogPadding(bool isSmall) => EdgeInsets.all(isSmall ? 12 : 16);

  static EdgeInsets getButtonPadding(bool isSmall) => EdgeInsets.symmetric(
    horizontal: isSmall ? 24 : 32,
    vertical: isSmall ? 12 : 16,
  );

  static EdgeInsets getSmallButtonPadding(bool isSmall) => EdgeInsets.symmetric(
    horizontal: isSmall ? 16 : 24,
    vertical: isSmall ? 10 : 12,
  );

  static EdgeInsets getIconButtonPadding(bool isSmall) => EdgeInsets.all(isSmall ? 8 : 10);

  // Spacing
  static double getTitleSpacing(bool isSmall) => isSmall ? 24 : 32;
  static double getSectionSpacing(bool isSmall) => isSmall ? 16 : 20;
  static double getItemSpacing(bool isSmall) => isSmall ? 12 : 16;
  static double getSmallSpacing(bool isSmall) => isSmall ? 6 : 8;
  static double getTinySpacing(bool isSmall) => isSmall ? 3 : 4;
  static double getExtraSmallSpacing(bool isSmall) => isSmall ? 10 : 12;

  // Icon sizes
  static double getIconSize(bool isSmall) => isSmall ? 20 : 24;
  static double getSmallIconSize(bool isSmall) => isSmall ? 18 : 20;
  static double getTinyIconSize(bool isSmall) => isSmall ? 14 : 16;
  static double getLargeIconSize(bool isSmall) => isSmall ? 24 : 28;
  static double getExtraLargeIconSize(bool isSmall) => isSmall ? 50 : 70;

  // Container sizes
  static double getAvatarSize(bool isSmall) => isSmall ? 40 : 48;
  static double getIconContainerSize(bool isSmall) => isSmall ? 6 : 8;
  static double getLargeIconContainerSize(bool isSmall) => isSmall ? 10 : 12;
  static double getDialogIconContainerSize(bool isSmall) => isSmall ? 8 : 12;

  // Button sizes
  static double getButtonHeight(bool isSmall) => isSmall ? 50 : 56;
  static double getProgressIndicatorSize(bool isSmall) => isSmall ? 18 : 20;
  static double getSmallProgressIndicatorSize(bool isSmall) => isSmall ? 18 : 20;

  // Border radius
  static double getCardRadius = 12.0;
  static double getLargeCardRadius = 16.0;
  static double getButtonRadius = 16.0;
  static double getSmallRadius = 8.0;
  static double getDialogRadius = 20.0;
  static double getBadgeRadius = 20.0;

  // Empty state
  static double getEmptyStateIconSize(bool isSmall) => isSmall ? 64 : 80;
  static double getEmptyStateIconInnerSize(bool isSmall) => isSmall ? 32 : 40;

  // Restricted access
  static double getRestrictedIconSize(bool isSmall) => isSmall ? 100 : 140;
  static double getRestrictedIconInnerSize(bool isSmall) => isSmall ? 50 : 70;

  // Margins
  static EdgeInsets getItemMargin(bool isSmall) => EdgeInsets.only(bottom: isSmall ? 12 : 16);
  static EdgeInsets getSummaryMargin = const EdgeInsets.only(bottom: 20);
  static EdgeInsets getShimmerMargin = const EdgeInsets.only(bottom: 16);

  // Shimmer sizes
  static const double shimmerAvatarSize = 50.0;
  static const double shimmerTitleHeight = 18.0;
  static const double shimmerSubtitleHeight = 14.0;
  static const double shimmerSmallHeight = 14.0;
  static const double shimmerTitleWidth = double.infinity;
  static const double shimmerSubtitleWidth = 180.0;
  static const double shimmerSmallWidth = 120.0;
  static const double shimmerIconSize = 32.0;

  // Elevation
  static const double cardElevation = 0.0;
  static const double buttonElevation = 4.0;
  static const double dialogElevation = 8.0;

  // Duration for snackbar
  static Duration getSnackbarDuration({bool error = false, bool importante = false}) {
    if (importante) return const Duration(seconds: 8);
    if (error) return const Duration(seconds: 6);
    return const Duration(seconds: 4);
  }

  // Animation duration
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
}