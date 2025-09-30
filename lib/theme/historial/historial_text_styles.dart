// theme/historial/historial_text_styles.dart
import 'package:flutter/material.dart';
import 'historial_colors.dart';

class HistorialTextStyles {
  // Estilos del AppBar
  static const TextStyle appBarTitle = TextStyle(
    color: HistorialColors.textPrimary,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );
  
  // Estilos de estado
  static const TextStyle loadingText = TextStyle(
    color: HistorialColors.textSecondary,
  );
  
  static const TextStyle errorTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle errorDescription = TextStyle(
    color: HistorialColors.textSecondary,
  );
  
  static const TextStyle emptyStateTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle emptyStateDescription = TextStyle(
    color: HistorialColors.textSecondary,
  );
  
  // Estilos de fecha
  static const TextStyle dateSection = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: HistorialColors.textPrimary,
  );
  
  static TextStyle dateCard = TextStyle(
    fontSize: 12,
    color: HistorialColors.iconSecondary,
    fontWeight: FontWeight.w500,
  );
  
  // Estilos de producto
  static const TextStyle productName = TextStyle(
    fontSize: 16,
    color: HistorialColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle productNameCard = TextStyle(
    fontSize: 14,
    color: HistorialColors.textPrimary,
    height: 1.3,
  );
  
  static const TextStyle productPrice = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: HistorialColors.textPrimary,
  );
  
  static const TextStyle productPriceCard = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: HistorialColors.textPrimary,
  );
  
  // Estilos de botones
  static const TextStyle buttonPrimary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle buttonCancel = TextStyle(
    fontWeight: FontWeight.w500,
  );
  
  static const TextStyle buttonDelete = TextStyle(
    fontWeight: FontWeight.w600,
  );
  
  // Estilos de diálogo
  static const TextStyle dialogTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle dialogContent = TextStyle(
    fontSize: 15,
    height: 1.4,
  );
}