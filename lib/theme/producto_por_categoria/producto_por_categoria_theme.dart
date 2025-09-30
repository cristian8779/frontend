import 'package:flutter/material.dart';

class ProductoPorCategoriaTheme {
  // Colores principales
  static const Color backgroundColor = Color(0xFFF8F8F8);
  static const Color cardBackgroundColor = Colors.white;
  static const Color primaryTextColor = Colors.black87;
  static const Color secondaryTextColor = Colors.grey;
  static const Color errorColor = Colors.redAccent;
  
  // Colores para el precio
  static final Color priceBackgroundColor = Colors.green.shade50;
  static final Color priceBorderColor = Colors.green.shade200;
  static final Color priceTextColor = Colors.green.shade700;
  static final Color priceIconColor = Colors.green.shade700;
  
  // Bordes redondeados
  static const double cardBorderRadius = 20.0;
  static const double priceBorderRadius = 12.0;
  
  // Espaciado
  static const double gridPadding = 12.0;
  static const double gridSpacing = 12.0;
  static const double cardPadding = 12.0;
  static const double contentPadding = 12.0;
  static const double priceVerticalPadding = 4.0;
  static const double priceHorizontalPadding = 8.0;
  
  // Tamaños de fuente
  static const double titleFontSize = 16.0;
  static const double priceFontSize = 16.0;
  static const double productNameFontSize = 12.0;
  static const double errorTextFontSize = 16.0;
  static const double emptyStateTextFontSize = 16.0;
  static const double noImageTextFontSize = 12.0;
  
  // Tamaños de iconos
  static const double errorIconSize = 48.0;
  static const double emptyStateIconSize = 64.0;
  static const double noImageIconSize = 40.0;
  static const double priceIconSize = 16.0;
  
  // Aspect ratios y cross axis extent
  static const double childAspectRatio = 0.63;
  static double maxCrossAxisExtent(Size screenSize) => screenSize.width * 0.5;
  
  // Shimmer colors
  static final Color shimmerBaseColor = Colors.grey[300]!;
  static final Color shimmerHighlightColor = Colors.grey[100]!;
  
  // Box shadows
  static List<BoxShadow> get cardBoxShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
  
  // AppBar Theme
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: backgroundColor,
    elevation: 0,
    iconTheme: IconThemeData(color: primaryTextColor),
    titleTextStyle: TextStyle(
      color: primaryTextColor,
      fontSize: titleFontSize,
      fontWeight: FontWeight.normal,
    ),
  );
  
  // Text Styles
  static const TextStyle titleTextStyle = TextStyle(
    color: primaryTextColor,
  );
  
  static const TextStyle errorTextStyle = TextStyle(
    fontSize: errorTextFontSize,
    color: errorColor,
  );
  
  static const TextStyle emptyStateTextStyle = TextStyle(
    fontSize: emptyStateTextFontSize,
    color: secondaryTextColor,
  );
  
  static const TextStyle emptyStateSubtitleTextStyle = TextStyle(
    fontSize: 12,
    color: secondaryTextColor,
  );
  
  static TextStyle get priceTextStyle => TextStyle(
    color: priceTextColor,
    fontSize: priceFontSize,
    fontWeight: FontWeight.bold,
  );
  
  static TextStyle get productNameTextStyle => TextStyle(
    color: Colors.grey[700],
    fontSize: productNameFontSize,
    height: 1.2,
  );
  
  static TextStyle get noImageTextStyle => TextStyle(
    color: Colors.grey[500],
    fontSize: noImageTextFontSize,
  );
  
  // Decorations
  static BoxDecoration get cardDecoration => BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(cardBorderRadius),
    boxShadow: cardBoxShadow,
  );
  
  static BoxDecoration get shimmerDecoration => BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(cardBorderRadius),
  );
  
  static BoxDecoration get priceDecoration => BoxDecoration(
    color: priceBackgroundColor,
    borderRadius: BorderRadius.circular(priceBorderRadius),
    border: Border.all(
      color: priceBorderColor,
      width: 1,
    ),
  );
  
  // Border Radius
  static BorderRadius get cardBorderRadiusGeometry => 
      BorderRadius.circular(cardBorderRadius);
  
  static BorderRadius get imageTopBorderRadius => 
      const BorderRadius.vertical(top: Radius.circular(cardBorderRadius));
  
  // Grid Delegates
  static SliverGridDelegate gridDelegate(Size screenSize) => 
      SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent(screenSize),
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: childAspectRatio,
      );
  
  static const SliverGridDelegate shimmerGridDelegate = 
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: gridSpacing,
        crossAxisSpacing: gridSpacing,
        childAspectRatio: childAspectRatio,
      );
  
  // Edge Insets
  static const EdgeInsets gridPaddingInsets = EdgeInsets.all(gridPadding);
  static const EdgeInsets cardPaddingInsets = EdgeInsets.all(cardPadding);
  static const EdgeInsets contentPaddingInsets = EdgeInsets.all(contentPadding);
  static const EdgeInsets pricePaddingInsets = EdgeInsets.symmetric(
    horizontal: priceHorizontalPadding,
    vertical: priceVerticalPadding,
  );
  
  // SizedBox heights
  static const SizedBox errorSpacing = SizedBox(height: 12);
  static const SizedBox emptyStateSpacing = SizedBox(height: 12);
  static const SizedBox emptyStateSubtitleSpacing = SizedBox(height: 8);
  static const SizedBox priceSpacing = SizedBox(height: 8);
  static const SizedBox noImageSpacing = SizedBox(height: 8);
  
  // Icons
  static Icon get errorIcon => const Icon(
    Icons.error_outline,
    size: errorIconSize,
    color: errorColor,
  );
  
  static Icon get emptyStateIcon => Icon(
    Icons.shopping_cart_outlined,
    size: emptyStateIconSize,
    color: Colors.grey[400],
  );
  
  static Icon get noImageIcon => Icon(
    Icons.image_not_supported_outlined,
    size: noImageIconSize,
    color: Colors.grey[400],
  );
  
  static Icon get priceIcon => Icon(
    Icons.attach_money,
    color: priceIconColor,
    size: priceIconSize,
  );
}