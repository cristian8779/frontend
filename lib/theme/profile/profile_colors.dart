import 'package:flutter/material.dart';

class ProfileColors {
  // Colores principales
  static Color primary = Colors.blue[600]!;
  static Color primaryLight = Colors.blue[400]!;
  static Color primaryDark = Colors.blue[700]!;
  static Color primaryBackground = Colors.blue[50]!;
  
  // Colores secundarios
  static Color orange = Colors.orange[600]!;
  static Color orangeLight = Colors.orange[400]!;
  static Color green = Colors.green[600]!;
  static Color greenLight = Colors.green[50]!;
  static Color red = Colors.red[600]!;
  static Color redLight = Colors.red[50]!;
  
  // Colores de texto
  static Color textPrimary = Colors.grey[800]!;
  static Color textSecondary = Colors.grey[600]!;
  static Color textHint = Colors.grey[400]!;
  static Color textLabel = Colors.grey[700]!;
  
  // Colores de superficie
  static Color surface = Colors.white;
  static Color surfaceVariant = Colors.grey[50]!;
  static Color surfaceContainer = Colors.grey[100]!;
  
  // Colores de bordes
  static Color border = Colors.grey[300]!;
  static Color borderLight = Colors.grey[200]!;
  static Color borderBlue = Colors.blue[200]!;
  static Color borderOrange = Colors.orange[200]!;
  
  // Gradientes
  static LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary],
  );
  
  static LinearGradient orangeGradient = LinearGradient(
    colors: [orangeLight, orange],
  );
  
  static LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryBackground, surface],
  );
  
  // Sombras
  static List<BoxShadow> primaryShadow = [
    BoxShadow(
      color: primary.withOpacity(0.1),
      spreadRadius: 2,
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> blueShadow = [
    BoxShadow(
      color: primary.withOpacity(0.3),
      spreadRadius: 2,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> orangeShadow = [
    BoxShadow(
      color: orange.withOpacity(0.3),
      spreadRadius: 2,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.08),
      spreadRadius: 1,
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> cardShadowMedium = [
    BoxShadow(
      color: Colors.grey.withOpacity(0.06),
      spreadRadius: 1,
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: primary.withOpacity(0.2),
      spreadRadius: 1,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}