import 'package:flutter/material.dart';

class CartPageStyles {
  // Colores principales
  static const Color primaryBlue = Color(0xFF3483FA);
  static const Color successGreen = Color(0xFF00A650);
  static const Color errorRed = Color(0xFFE74C3C);
  static const Color warningOrange = Color(0xFFFF8C00);
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color cardBackgroundColor = Colors.white;
  
  // Función para obtener dimensiones responsive
  static Map<String, dynamic> getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    bool isSmall = screenWidth < 480;
    bool isMedium = screenWidth >= 480 && screenWidth < 768;
    bool isTablet = screenWidth >= 768 && screenWidth < 1024;
    bool isDesktop = screenWidth >= 1024;
    bool isLargeDesktop = screenWidth >= 1440;
    
    return {
      'isSmall': isSmall,
      'isMedium': isMedium,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
      'isLargeDesktop': isLargeDesktop,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'horizontalPadding': isLargeDesktop ? 32.0 : 
                          isDesktop ? 24.0 : 
                          isTablet ? 20.0 : 
                          isMedium ? 16.0 : 16.0,
      'verticalPadding': isDesktop ? 20.0 : 
                        isTablet ? 16.0 : 16.0,
      'headerFontSize': isLargeDesktop ? 24.0 : 
                       isDesktop ? 22.0 :
                       isTablet ? 20.0 : 
                       isMedium ? 18.0 : 18.0,
      'cardPadding': isDesktop ? 20.0 : 
                    isTablet ? 16.0 : 
                    isMedium ? 14.0 : 12.0,
      'itemImageSize': isDesktop ? 90.0 : 
                      isTablet ? 75.0 : 
                      isMedium ? 65.0 : 60.0,
      'buttonHeight': isDesktop ? 56.0 : 
                     isTablet ? 52.0 : 48.0,
    };
  }

  // AppBar Style
  static AppBarTheme get appBarTheme => const AppBarTheme(
    backgroundColor: cardBackgroundColor,
    elevation: 1,
    iconTheme: IconThemeData(color: Colors.grey),
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Colors.black87,
    ),
  );

  // AppBar con responsive
  static PreferredSizeWidget buildAppBar({
    required BuildContext context,
    required VoidCallback onBack,
    required int totalItems,
  }) {
    final responsive = getResponsiveDimensions(context);
    
    return AppBar(
      backgroundColor: cardBackgroundColor,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      leading: IconButton(
        onPressed: onBack,
        icon: Icon(
          Icons.arrow_back,
          color: Colors.grey.shade700,
          size: 24,
        ),
      ),
      title: Text(
        'Tu carrito',
        style: TextStyle(
          fontSize: responsive['headerFontSize'],
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade800,
        ),
      ),
      centerTitle: false,
      actions: [
        if (totalItems > 0)
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$totalItems item${totalItems != 1 ? 's' : ''}',
              style: const TextStyle(
                color: primaryBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  // Container Style para items del carrito
  static BoxDecoration get cartItemDecoration => BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade200),
  );

  // Shimmer Container Style
  static Widget buildShimmerContainer({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }

  // Empty cart container style
  static Widget buildEmptyCartIcon() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.shopping_cart_outlined,
        size: 64,
        color: Colors.grey.shade400,
      ),
    );
  }

  // Text Styles
  static TextStyle get emptyCartTitleStyle => TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade700,
  );

  static TextStyle get emptyCartSubtitleStyle => TextStyle(
    fontSize: 16,
    color: Colors.grey.shade500,
  );

  static TextStyle get productNameStyle => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade800,
    height: 1.3,
  );

  static TextStyle get priceStyle => const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.black,
  );

  static TextStyle get quantityLabelStyle => TextStyle(
    fontSize: 14,
    color: Colors.grey.shade600,
  );

  static TextStyle get quantityValueStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade800,
  );

  static TextStyle get totalLabelStyle => TextStyle(
    fontSize: 14,
    color: Colors.grey.shade600,
  );

  static TextStyle get totalPriceStyle => const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: successGreen,
  );

  // Button Styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: cardBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    elevation: 0,
  );

  static ButtonStyle get discoverButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryBlue,
    foregroundColor: cardBackgroundColor,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    elevation: 0,
  );

  static ButtonStyle get deleteButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: errorRed,
    foregroundColor: cardBackgroundColor,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    elevation: 0,
  );

  // Image container style
  static BoxDecoration buildImageDecoration() => BoxDecoration(
    borderRadius: BorderRadius.circular(8),
    color: Colors.grey.shade100,
    border: Border.all(color: Colors.grey.shade200),
  );

  // Variation chip style
  static Widget buildVariationChip(String text, MaterialColor colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: colorScheme.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.shade200),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: colorScheme.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Quantity controls container style
  static BoxDecoration get quantityControlsDecoration => BoxDecoration(
    color: cardBackgroundColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: Colors.grey.shade300),
  );

  // Summary container style
  static BoxDecoration get summaryContainerDecoration => BoxDecoration(
    color: Colors.grey.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade200),
  );

  // Payment panel decoration
  static BoxDecoration get paymentPanelDecoration => BoxDecoration(
    color: cardBackgroundColor,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, -2),
      ),
    ],
  );

  // SnackBar styles
  static SnackBar buildSuccessSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle, color: cardBackgroundColor, size: 20),
          const SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: successGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      duration: const Duration(seconds: 2),
    );
  }

  static SnackBar buildErrorSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: cardBackgroundColor, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: errorRed,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  static SnackBar buildWarningSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.info_outline, color: cardBackgroundColor, size: 20),
          const SizedBox(width: 8),
          Text(message),
        ],
      ),
      backgroundColor: warningOrange,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // Dialog styles
  static AlertDialog buildDeleteConfirmationDialog({
    required BuildContext context,
    required VoidCallback onConfirm,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.delete_outline, color: errorRed, size: 24),
          SizedBox(width: 12),
          Text(
            'Eliminar producto',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Text(
        '¿Estás seguro de que deseas eliminar este producto del carrito?',
        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: deleteButtonStyle,
          child: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  // Loading indicator
  static Widget get loadingIndicator => const CircularProgressIndicator(color: primaryBlue);

  // Shimmer colors
  static Color get shimmerBaseColor => Colors.grey.shade300;
  static Color get shimmerHighlightColor => Colors.grey.shade100;

  // Icon styles
  static Widget buildDeleteIcon() => Icon(
    Icons.delete_outline,
    color: Colors.grey.shade500,
    size: 20,
  );

  static Widget buildQuantityIcon(IconData icon, {required bool enabled}) => Icon(
    icon,
    color: enabled ? primaryBlue : Colors.grey.shade400,
    size: 16,
  );

  static Widget buildShippingIcon() => const Icon(
    Icons.local_shipping_outlined,
    color: successGreen,
    size: 28,
  );

  static Widget buildArrowIcon() => const Icon(Icons.arrow_forward, size: 20);

  static Widget buildImagePlaceholderIcon() => Icon(
    Icons.shopping_bag_outlined,
    size: 32,
    color: Colors.grey.shade400,
  );

  static Widget buildImageErrorIcon() => Icon(
    Icons.image_not_supported_outlined,
    size: 32,
    color: Colors.grey.shade400,
  );
}