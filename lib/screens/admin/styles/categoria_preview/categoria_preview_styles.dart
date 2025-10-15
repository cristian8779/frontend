import 'package:flutter/material.dart';

class CategoriaPreviewStyles {
  // Colores
  static const Color backgroundColor = Color(0xFFF5F5F5);
  static const Color textPrimaryColor = Colors.black87;
  static const Color iconColor = Colors.black87;
  
  // Tamaños
  static const double appBarTitleSize = 22.0;
  static const double bodyMediumSize = 16.0;
  static const double bodyLargeSize = 18.0;
  static const double iconLargeSize = 80.0;
  
  // Espaciado
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing80 = 80.0;
  static const double spacing120 = 120.0;
  
  // Border radius
  static const double borderRadius4 = 4.0;
  static const double borderRadius12 = 12.0;
  static const double borderRadius16 = 16.0;
  
  // Grid
  static const int minCrossAxisCount = 2;
  static const int maxCrossAxisCount = 4;
  static const double gridItemWidth = 200.0;
  static const double gridCrossAxisSpacing = 16.0;
  static const double gridMainAxisSpacing = 16.0;
  static const double gridChildAspectRatio = 0.75;
  static const int shimmerItemCount = 6;
  
  // Padding
  static const EdgeInsets gridPadding = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets gridBottomPadding = EdgeInsets.only(bottom: 80);
  static const EdgeInsets containerPadding = EdgeInsets.all(12);
  
  // Animaciones
  static const Duration animationDuration = Duration(milliseconds: 500);
  static const Duration scrollAnimationDuration = Duration(milliseconds: 300);
  static const Curve animationCurve = Curves.easeInOut;
  static const Curve scrollCurve = Curves.easeOut;
  
  // AppBar Style
  static TextStyle appBarTitleStyle() {
    return const TextStyle(
      fontSize: appBarTitleSize,
      fontWeight: FontWeight.w600,
      color: textPrimaryColor,
    );
  }
  
  // Shimmer Colors
  static Color shimmerBaseColor() => Colors.grey.shade200;
  static Color shimmerHighlightColor() => Colors.grey.shade100;
  static Color shimmerContainerColor() => Colors.grey.shade300;
  
  // Container Decoration
  static BoxDecoration containerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(borderRadius16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  // Shimmer Item Decoration
  static BoxDecoration shimmerItemDecoration() {
    return BoxDecoration(
      color: shimmerContainerColor(),
      borderRadius: BorderRadius.circular(borderRadius12),
    );
  }
  
  // Shimmer Bar Decoration
  static BoxDecoration shimmerBarDecoration() {
    return BoxDecoration(
      color: shimmerContainerColor(),
      borderRadius: BorderRadius.circular(borderRadius4),
    );
  }
  
  // Empty State
  static Widget emptyIcon() {
    return Icon(
      Icons.inventory_2_outlined,
      size: iconLargeSize,
      color: Colors.grey.shade400,
    );
  }
  
  static TextStyle emptyTextStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyLargeSize,
    ) ?? const TextStyle(fontSize: bodyLargeSize);
  }
  
  // Error State
  static Widget errorIcon(ThemeData theme) {
    return Icon(
      Icons.error_outline,
      size: iconLargeSize,
      color: theme.colorScheme.error.withOpacity(0.6),
    );
  }
  
  static TextStyle errorTextStyle(ThemeData theme) {
    return theme.textTheme.bodyMedium?.copyWith(
      fontSize: bodyMediumSize,
    ) ?? const TextStyle(fontSize: bodyMediumSize);
  }
  
  // Grid Delegate
  static SliverGridDelegate gridDelegate(BoxConstraints constraints) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: (constraints.maxWidth / gridItemWidth)
          .floor()
          .clamp(minCrossAxisCount, maxCrossAxisCount),
      crossAxisSpacing: gridCrossAxisSpacing,
      mainAxisSpacing: gridMainAxisSpacing,
      childAspectRatio: gridChildAspectRatio,
    );
  }
  
  // Shimmer Grid Delegate
  static const SliverGridDelegate shimmerGridDelegate = 
    SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      crossAxisSpacing: gridCrossAxisSpacing,
      mainAxisSpacing: gridMainAxisSpacing,
      childAspectRatio: gridChildAspectRatio,
    );
}