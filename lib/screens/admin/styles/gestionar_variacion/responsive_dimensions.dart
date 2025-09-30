enum ResponsiveBreakpoints {
  mobile,
  tabletSmall,
  tablet,
  desktop,
}

class ResponsiveDimensions {
  final double horizontalMargin;
  final double imageSize;
  final double contentPadding;
  final double titleFontSize;
  final double priceFontSize;
  final double iconSize;
  final double actionButtonSize;
  final double spacingLarge;
  final double spacingMedium;
  final int columns;

  const ResponsiveDimensions({
    required this.horizontalMargin,
    required this.imageSize,
    required this.contentPadding,
    required this.titleFontSize,
    required this.priceFontSize,
    required this.iconSize,
    required this.actionButtonSize,
    required this.spacingLarge,
    required this.spacingMedium,
    required this.columns,
  });
  
  // Factory constructors para cada breakpoint
  factory ResponsiveDimensions.desktop() {
    return const ResponsiveDimensions(
      horizontalMargin: 0.15,
      imageSize: 100,
      contentPadding: 32,
      titleFontSize: 20,
      priceFontSize: 18,
      iconSize: 28,
      actionButtonSize: 52,
      spacingLarge: 40,
      spacingMedium: 20,
      columns: 2,
    );
  }
  
  factory ResponsiveDimensions.tablet() {
    return const ResponsiveDimensions(
      horizontalMargin: 0.12,
      imageSize: 90,
      contentPadding: 28,
      titleFontSize: 19,
      priceFontSize: 17,
      iconSize: 26,
      actionButtonSize: 50,
      spacingLarge: 36,
      spacingMedium: 18,
      columns: 2,
    );
  }
  
  factory ResponsiveDimensions.tabletSmall() {
    return const ResponsiveDimensions(
      horizontalMargin: 0.08,
      imageSize: 80,
      contentPadding: 24,
      titleFontSize: 18,
      priceFontSize: 16,
      iconSize: 24,
      actionButtonSize: 48,
      spacingLarge: 32,
      spacingMedium: 16,
      columns: 1,
    );
  }
  
  factory ResponsiveDimensions.mobile() {
    return const ResponsiveDimensions(
      horizontalMargin: 0.05,
      imageSize: 60,
      contentPadding: 16,
      titleFontSize: 16,
      priceFontSize: 15,
      iconSize: 20,
      actionButtonSize: 40,
      spacingLarge: 24,
      spacingMedium: 12,
      columns: 1,
    );
  }
  
  // Método estático para obtener dimensiones según breakpoint
  static ResponsiveDimensions fromBreakpoint(ResponsiveBreakpoints breakpoint) {
    switch (breakpoint) {
      case ResponsiveBreakpoints.desktop:
        return ResponsiveDimensions.desktop();
      case ResponsiveBreakpoints.tablet:
        return ResponsiveDimensions.tablet();
      case ResponsiveBreakpoints.tabletSmall:
        return ResponsiveDimensions.tabletSmall();
      case ResponsiveBreakpoints.mobile:
        return ResponsiveDimensions.mobile();
    }
  }
  
  // Método estático para obtener breakpoint según ancho
  static ResponsiveBreakpoints getBreakpoint(double width) {
    if (width >= 1200) {
      return ResponsiveBreakpoints.desktop;
    } else if (width >= 800) {
      return ResponsiveBreakpoints.tablet;
    } else if (width >= 600) {
      return ResponsiveBreakpoints.tabletSmall;
    } else {
      return ResponsiveBreakpoints.mobile;
    }
  }
}