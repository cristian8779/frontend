import 'package:flutter/material.dart';
import 'tipografia.dart';
import 'colores.dart';

/// Estilos de texto reutilizables para toda la pantalla
class ProductoTextStyles {
  // Headings - XL
  static TextStyle get headingXLDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopHeadingXL,
    fontWeight: FontWeight.w300,
  );
  
  static TextStyle get headingXLMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileHeadingXL,
    fontWeight: FontWeight.w300,
  );
  
  // Headings - Large
  static TextStyle get headingLgDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopHeadingLg,
    fontWeight: FontWeight.w400,
  );
  
  static TextStyle get headingLgMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileHeadingLg,
    fontWeight: FontWeight.w400,
  );
  
  // Headings - Medium
  static TextStyle get headingMdDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopHeadingMd,
    fontWeight: FontWeight.w600,
    color: ProductoColores.textDark,
  );
  
  static TextStyle get headingMdMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileHeadingMd,
    fontWeight: FontWeight.w600,
    color: ProductoColores.textDark,
  );
  
  // Body - Large
  static TextStyle get bodyLgDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopBodyLg,
    color: ProductoColores.textMedium,
    height: 1.5,
  );
  
  static TextStyle get bodyLgMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileBodyLg,
    color: ProductoColores.textMedium,
    height: 1.5,
  );
  
  // Body - Medium
  static TextStyle get bodyMdDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopBodyMd,
    color: ProductoColores.textMedium,
  );
  
  static TextStyle get bodyMdMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileBodyMd,
    color: ProductoColores.textMedium,
  );
  
  // Label - Small
  static TextStyle get labelSmDesktop => const TextStyle(
    fontSize: ProductoFontSizes.desktopLabelSm,
    color: ProductoColores.textLight,
  );
  
  static TextStyle get labelSmMobile => const TextStyle(
    fontSize: ProductoFontSizes.mobileLabelSm,
    color: ProductoColores.textLight,
  );
}