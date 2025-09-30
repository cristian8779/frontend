class VerAdminsDimensions {
  final double screenWidth;
  
  VerAdminsDimensions(this.screenWidth);
  
  // Breakpoints
  bool get isTablet => screenWidth > 600;
  bool get isDesktop => screenWidth > 1200;
  
  // App Bar
  double get appBarHeight => isDesktop ? 160 : (isTablet ? 140 : 120);
  double get appBarTitleSize => isDesktop ? 24 : (isTablet ? 22 : 20);
  
  // Stats Card
  double get statsMargin => isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
  double get statsPadding => isDesktop ? 32.0 : (isTablet ? 24.0 : 20.0);
  double get statsIconSize => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get statsIconPadding => isTablet ? 16 : 12;
  double get statsTitleSize => isDesktop ? 18 : (isTablet ? 16 : 14);
  double get statsCountSize => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get statsSpacing => isTablet ? 20 : 16;
  double get statsRadius => isTablet ? 20 : 16;
  double get statsIconRadius => isTablet ? 16 : 12;
  
  // Content Padding
  double get contentHorizontalPadding => isDesktop ? 32 : (isTablet ? 24 : 16);
  double get contentBottomPadding => isDesktop ? 32 : (isTablet ? 24 : 16);
  
  // Admin Card
  double get cardMarginBottom => isTablet ? 16 : 12;
  double get cardRadius => isTablet ? 20 : 16;
  double get cardPadding => isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
  double get avatarSize => isDesktop ? 64.0 : (isTablet ? 60.0 : 56.0);
  double get avatarRadius => isTablet ? 20 : 16;
  double get avatarTextSize => isDesktop ? 28 : (isTablet ? 26 : 24);
  double get cardTitleSize => isDesktop ? 20 : (isTablet ? 19 : 18);
  double get cardSubtitleSize => isDesktop ? 16 : (isTablet ? 15 : 14);
  double get cardIconSize => isDesktop ? 20 : (isTablet ? 18 : 16);
  double get cardIconSpacing => isTablet ? 8 : 6;
  double get cardSubtitleSpacing => isTablet ? 8 : 4;
  double get cardRolSpacing => isTablet ? 12 : 8;
  double get cardRolPaddingH => isTablet ? 12 : 8;
  double get cardRolPaddingV => isTablet ? 6 : 4;
  double get cardRolRadius => isTablet ? 10 : 8;
  double get cardRolTextSize => isDesktop ? 14 : (isTablet ? 13 : 12);
  double get deleteIconSize => isDesktop ? 28 : (isTablet ? 26 : 24);
  double get deleteIconPadding => isTablet ? 12 : 8;
  double get deleteIconRadius => isTablet ? 16 : 12;
  
  // Skeleton Card
  double get skeletonMargin => isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
  double get skeletonPadding => isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
  double get skeletonAvatarRadius => isDesktop ? 35.0 : (isTablet ? 32.0 : 30.0);
  double get skeletonTitleHeight => isDesktop ? 20 : (isTablet ? 18 : 16);
  double get skeletonSubtitleHeight => isDesktop ? 18 : (isTablet ? 16 : 14);
  double get skeletonSubtitleWidth => isTablet ? 180 : 150;
  double get skeletonSpacing => isTablet ? 12 : 8;
  
  // Dialog
  double get dialogRadius => isTablet ? 20 : 16;
  double get dialogPadding => isTablet ? 32 : 16;
  double get dialogIconSize => isTablet ? 28 : 24;
  double get dialogIconSpacing => isTablet ? 16 : 12;
  double get dialogTitleSize => isTablet ? 20 : 18;
  double get dialogContentSize => isTablet ? 16 : 14;
  double get dialogNameSize => isTablet ? 18 : 16;
  double get dialogWarningSize => isTablet ? 15 : 14;
  double get dialogButtonSize => isTablet ? 16 : 14;
  double get dialogButtonRadius => isTablet ? 12 : 8;
  double get dialogButtonPaddingH => isTablet ? 24 : 16;
  double get dialogButtonPaddingV => isTablet ? 12 : 8;
  double get dialogSpacingSmall => isTablet ? 12 : 8;
  double get dialogSpacingMedium => isTablet ? 16 : 12;
  double get dialogMaxWidth => isTablet ? 500 : double.infinity;
  
  // Loading Dialog
  double get loadingDialogMargin => isTablet ? 48 : 24;
  double get loadingDialogPadding => isTablet ? 32 : 24;
  double get loadingDialogSpacing => isTablet ? 24 : 16;
  double get loadingDialogTextSize => isTablet ? 18 : 16;
  
  // Empty/Error State
  double get statePadding => isDesktop ? 48.0 : (isTablet ? 32.0 : 24.0);
  double get stateIconSize => isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);
  double get stateIconPadding => isDesktop ? 40 : (isTablet ? 36 : 32);
  double get stateIconRadius => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get stateTitleSize => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get stateSubtitleSize => isDesktop ? 18 : (isTablet ? 17 : 16);
  double get stateHintSize => isDesktop ? 16 : (isTablet ? 15 : 14);
  double get stateSpacingLarge => isDesktop ? 40 : (isTablet ? 36 : 32);
  double get stateSpacingMedium => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get stateSpacingSmall => isTablet ? 16 : 12;
  
  // Error State específico
  double get errorIconSize => isDesktop ? 80.0 : (isTablet ? 72.0 : 64.0);
  double get errorIconPadding => isDesktop ? 32 : (isTablet ? 28 : 24);
  double get errorIconRadius => isTablet ? 24 : 16;
  double get errorTitleSize => isDesktop ? 28 : (isTablet ? 24 : 20);
  
  // SnackBar
  double get snackBarIconSize => isTablet ? 24 : 20;
  double get snackBarIconSpacing => isTablet ? 16 : 12;
  double get snackBarTextSize => isTablet ? 16 : 15;
  double get snackBarMargin => isTablet ? 24 : 16;
  double get snackBarRadius => 12;
  
  // Grid
  int get gridCrossAxisCount => isDesktop ? 2 : 1;
  double get gridChildAspectRatio => 3.5;
  double get gridCrossAxisSpacing => 16;
  double get gridMainAxisSpacing => 12;
}