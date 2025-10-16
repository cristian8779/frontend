import 'package:flutter/material.dart';

/// Bordes redondeados estándar
class ProductoBorderRadius {
  static const double none = 0.0;
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 24.0;
  static const double full = 999.0;
}

/// Sombras predefinidas
class ProductoShadows {
  static const BoxShadow small = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  
  static const BoxShadow medium = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 8,
    offset: Offset(0, 4),
  );
}