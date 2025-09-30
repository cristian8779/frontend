import 'package:flutter/material.dart';

class VerAdminsColors {
  // Colores principales
  static Color? get primaryBlue => Colors.blue[600];
  static Color? get primaryBlueDark => Colors.blue[800];
  static Color? get backgroundGrey => Colors.grey[50];
  
  // Colores de avatares
  static final List<MaterialColor> avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
  ];
  
  // Colores de estados
  static Color? get errorRed => Colors.red[600];
  static Color? get successGreen => Colors.green[600];
  static Color? get warningOrange => Colors.orange[600];
  
  // Colores de texto
  static Color? get textPrimary => Colors.black87;
  static Color? get textSecondary => Colors.grey[600];
  static Color? get textTertiary => Colors.grey[500];
  static Color? get textDark => Colors.grey[800];
  
  // Colores de fondos
  static Color? get cardBackground => Colors.white;
  static Color? get blueLight => Colors.blue[100];
  static Color? get blueLighter => Colors.blue[50];
  static Color? get redLight => Colors.red[50];
  static Color? get redButton => Colors.red[400];
  
  // Método auxiliar para obtener color de avatar por índice
  static MaterialColor getAvatarColor(int index) {
    return avatarColors[index % avatarColors.length];
  }
}