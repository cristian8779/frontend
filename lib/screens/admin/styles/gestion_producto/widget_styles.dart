import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class WidgetStyles {
  // Decoraciones de contenedores
  static BoxDecoration cardDecoration({Color? shadowColor}) {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      boxShadow: [
        BoxShadow(
          color: (shadowColor ?? Colors.black).withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  static BoxDecoration searchBarDecoration({required bool isFocused}) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppDimensions.searchRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.blue.withOpacity(isFocused ? 0.15 : 0.08),
          blurRadius: isFocused ? 12 : 8,
          offset: const Offset(0, 4),
        ),
      ],
      border: Border.all(
        color: isFocused ? Colors.blue.withOpacity(0.5) : Colors.transparent,
        width: 2,
      ),
    );
  }
  
  static BoxDecoration statsContainerDecoration() {
    return BoxDecoration(
      gradient: AppColors.primaryGradient,
      borderRadius: BorderRadius.circular(AppDimensions.containerRadius),
      boxShadow: [
        BoxShadow(
          color: AppColors.primaryLight(0.1),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
  
  static BoxDecoration iconContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(AppDimensions.iconContainerRadius),
    );
  }
  
  static BoxDecoration errorContainerDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
    );
  }
  
  static BoxDecoration statusBarDecoration(Color color) {
    return BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    );
  }
  
  static BoxDecoration filterContainerDecoration() {
    return BoxDecoration(
      color: AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppDimensions.cardRadius),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }
  
  // InputDecoration para campos de texto
  static InputDecoration dropdownDecoration({
    required String labelText,
    required IconData prefixIcon,
    required double screenWidth,
  }) {
    final fontSize = AppDimensions.getLabelFontSize(screenWidth);
    final iconSize = AppDimensions.getFilterIconSize(screenWidth);
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    
    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        fontSize: fontSize - 1,
        color: AppColors.textPrimary,
      ),
      prefixIcon: Icon(
        prefixIcon,
        size: iconSize,
        color: Colors.grey[600],
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
    );
  }
  
  // Estilos de texto
  static TextStyle searchHintStyle(double screenWidth) {
    return TextStyle(
      color: Colors.grey[500],
      fontSize: AppDimensions.getSearchFontSize(screenWidth),
    );
  }
  
  static TextStyle searchTextStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getSearchFontSize(screenWidth),
    );
  }
  
  static TextStyle filterTitleStyle(double screenWidth) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: AppDimensions.getLabelFontSize(screenWidth),
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle dropdownItemStyle(double screenWidth) {
    final fontSize = AppDimensions.getLabelFontSize(screenWidth);
    return TextStyle(
      fontSize: fontSize - 1,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle statsNumberStyle(double screenWidth, Color color) {
    return TextStyle(
      fontSize: AppDimensions.getNumberFontSize(screenWidth),
      fontWeight: FontWeight.bold,
      color: color,
    );
  }
  
  static TextStyle statsLabelStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getSubtitleFontSize(screenWidth),
      color: Colors.grey,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle statsTitleStyle(double screenWidth) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: AppDimensions.getTitleFontSize(screenWidth),
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle emptyStateTitleStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getEmptyStateTitleFontSize(screenWidth),
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle emptyStateSubtitleStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getEmptyStateSubtitleFontSize(screenWidth),
      color: Colors.grey[600],
      height: 1.4,
    );
  }
  
  static TextStyle errorTitleStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getErrorTitleFontSize(screenWidth),
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle errorMessageStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getErrorMessageFontSize(screenWidth),
      color: Colors.grey[600],
      height: 1.5,
    );
  }
  
  static TextStyle headerTitleStyle(double screenWidth) {
    return TextStyle(
      fontSize: AppDimensions.getHeaderFontSize(screenWidth),
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    );
  }
  
  static TextStyle appBarTitleStyle(double screenWidth) {
    return TextStyle(
      color: AppColors.textPrimary,
      fontSize: AppDimensions.getAppBarFontSize(screenWidth),
      fontWeight: FontWeight.w600,
    );
  }
  
  static TextStyle resultsBadgeStyle(double screenWidth) {
    return TextStyle(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
      fontSize: AppDimensions.isSmallScreen(screenWidth) ? 11 : 12,
    );
  }
  
  static TextStyle loadingMoreStyle() {
    return TextStyle(
      color: Colors.grey[600],
      fontSize: 14,
    );
  }
  
  static TextStyle endOfListStyle() {
    return TextStyle(
      color: Colors.grey[500],
      fontSize: 12,
    );
  }
  
  static TextStyle statusTextStyle(double screenWidth, Color color) {
    return TextStyle(
      color: color.withOpacity(0.8),
      fontWeight: FontWeight.w600,
      fontSize: AppDimensions.isSmallScreen(screenWidth) ? 14 : 16,
    );
  }
  
  // Estilos de botones
  static ButtonStyle primaryButtonStyle(double screenWidth) {
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 24,
        vertical: isSmallScreen ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
    );
  }
  
  static ButtonStyle secondaryButtonStyle(double screenWidth, Color color) {
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 24,
        vertical: isSmallScreen ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
    );
  }
  
  static ButtonStyle outlinedButtonStyle(double screenWidth, Color color) {
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 20 : 24,
        vertical: isSmallScreen ? 10 : 12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
      ),
    );
  }
}