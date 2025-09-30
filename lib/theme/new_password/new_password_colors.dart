import 'package:flutter/material.dart';

class NewPasswordColors {
  // Colores principales
  static const Color primary = Color(0xFFBE0C0C);
  static const Color background = Color(0xFFF8F9FA);
  
  // Colores de texto
  static const Color textPrimary = Colors.black87;
  static const Color textSecondary = Colors.black54;
  static final Color textHint = Colors.grey[600]!;
  static final Color textDisabled = Colors.grey[400]!;
  
  // Colores de estado de requisitos
  static final Color requirementValid = Colors.green[600]!;
  static final Color requirementInvalid = Colors.grey[400]!;
  static final Color requirementValidBg = Colors.green[50]!;
  static final Color requirementInvalidBg = Colors.grey[50]!;
  static final Color requirementValidBorder = Colors.green[300]!;
  static final Color requirementInvalidBorder = Colors.grey[300]!;
  static final Color requirementValidText = Colors.green[700]!;
  static final Color requirementInvalidText = Colors.grey[600]!;
  
  // Colores de fortaleza de contraseña
  static const Color strengthWeak = Colors.red;
  static const Color strengthFair = Colors.orange;
  static final Color strengthGood = Colors.yellow[700]!;
  static const Color strengthStrong = Colors.green;
  
  // Colores de superficie
  static const Color surface = Colors.white;
  static final Color surfaceTint = Colors.grey[200]!;
  static final Color border = Colors.grey[300]!;
  static final Color borderFocused = primary;
  static const Color borderError = Colors.red;
  
  // Colores de sombra
  static Color shadowLight = Colors.black.withOpacity(0.03);
  static Color shadowMedium = Colors.black.withOpacity(0.05);
  static Color shadowDark = Colors.black12;
  
  // Colores de íconos
  static final Color iconPrimary = Colors.blue[600]!;
  static final Color iconSecondary = Colors.grey[600]!;
  static final Color iconSuccess = Colors.green[600]!;
  static final Color iconError = Colors.red[600]!;
  
  // Colores de botones
  static const Color buttonPrimary = primary;
  static final Color buttonDisabled = Colors.grey[300]!;
  static const Color buttonText = Colors.white;
  
  // Colores de snackbar
  static final Color snackbarSuccess = Colors.green[600]!;
  static final Color snackbarError = Colors.red[600]!;
  
  // Colores de chips de requisitos
  static final Color chipSuccessBackground = Colors.green[100]!;
  static final Color chipSuccessText = Colors.green[700]!;
  static final Color chipNeutralBackground = Colors.grey[100]!;
  static final Color chipNeutralText = Colors.grey[600]!;
  
  // Colores con opacidad
  static Color primaryWithOpacity(double opacity) => primary.withOpacity(opacity);
  static Color shadowWithOpacity(double opacity) => Colors.black.withOpacity(opacity);
  static Color greenWithOpacity(double opacity) => Colors.green.withOpacity(opacity);
}