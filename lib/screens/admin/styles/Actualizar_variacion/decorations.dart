import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

class ActualizarVariacionDecorations {
  // Card decoration
  static BoxDecoration cardDecoration = BoxDecoration(
    color: ActualizarVariacionColors.cardBackground,
    borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusCard),
    boxShadow: [
      BoxShadow(
        color: ActualizarVariacionColors.shadowColor(0.08),
        blurRadius: ActualizarVariacionDimensions.blurCard,
        offset: const Offset(0, ActualizarVariacionDimensions.offsetY),
      ),
    ],
  );
  
  // Image container decoration
  static BoxDecoration imageContainerDecoration({required bool hasImage}) {
    return BoxDecoration(
      color: ActualizarVariacionColors.cardBackground,
      borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusImage),
      border: Border.all(
        color: hasImage 
            ? ActualizarVariacionColors.primary 
            : ActualizarVariacionColors.border,
        width: hasImage 
            ? ActualizarVariacionDimensions.borderWidthSelected 
            : ActualizarVariacionDimensions.borderWidthNormal,
      ),
      boxShadow: [
        BoxShadow(
          color: ActualizarVariacionColors.shadowColor(0.08),
          blurRadius: ActualizarVariacionDimensions.blurCard,
          offset: const Offset(0, ActualizarVariacionDimensions.offsetY),
        ),
      ],
    );
  }
  
  // Preview container decoration
  static BoxDecoration previewDecoration = BoxDecoration(
    color: ActualizarVariacionColors.primaryLight(0.1),
    borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusPreview),
    border: Border.all(color: ActualizarVariacionColors.primaryLight(0.3)),
  );
  
  // Edit icon container decoration
  static BoxDecoration editIconDecoration = BoxDecoration(
    color: ActualizarVariacionColors.blackWithOpacity(0.6),
    borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusIcon),
  );
  
  // Icon background decoration
  static BoxDecoration iconBackgroundDecoration = BoxDecoration(
    color: ActualizarVariacionColors.primaryLight(0.1),
    shape: BoxShape.circle,
  );
  
  // Color preview decoration
  static BoxDecoration colorPreviewDecoration(String colorHex) {
    return BoxDecoration(
      color: Color(int.parse('0xFF${colorHex.substring(1)}')),
      shape: BoxShape.circle,
      border: Border.all(
        color: Colors.white, 
        width: ActualizarVariacionDimensions.borderWidthColorPreview,
      ),
      boxShadow: [
        BoxShadow(
          color: ActualizarVariacionColors.shadowColor(0.2),
          blurRadius: 4,
          offset: const Offset(0, ActualizarVariacionDimensions.offsetY),
        ),
      ],
    );
  }
  
  // TextField decoration
  static InputDecoration textFieldDecoration({
    required String label,
    String? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: ActualizarVariacionDimensions.paddingLarge, 
        vertical: ActualizarVariacionDimensions.paddingLarge,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusTextField),
        borderSide: BorderSide(color: ActualizarVariacionColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusTextField),
        borderSide: BorderSide(color: ActualizarVariacionColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusTextField),
        borderSide: const BorderSide(
          color: ActualizarVariacionColors.primary, 
          width: ActualizarVariacionDimensions.borderWidthSelected,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusTextField),
        borderSide: BorderSide(color: ActualizarVariacionColors.errorBorder),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusTextField),
        borderSide: BorderSide(
          color: ActualizarVariacionColors.errorBorder, 
          width: ActualizarVariacionDimensions.borderWidthSelected,
        ),
      ),
    );
  }
  
  // Button style
  static ButtonStyle buttonStyle({required bool isLoading}) {
    return ElevatedButton.styleFrom(
      backgroundColor: ActualizarVariacionColors.primary,
      foregroundColor: Colors.white,
      disabledBackgroundColor: ActualizarVariacionColors.disabled,
      elevation: isLoading 
          ? ActualizarVariacionDimensions.elevationNone 
          : ActualizarVariacionDimensions.elevationButton,
      shadowColor: ActualizarVariacionColors.primaryLight(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(ActualizarVariacionDimensions.borderRadiusButton),
      ),
    );
  }
}