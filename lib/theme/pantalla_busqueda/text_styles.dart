import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

/// Estilos de texto para la pantalla de búsqueda
class BusquedaTextStyles {
  BusquedaTextStyles._();

  // Estilos para el header stats
  static TextStyle headerTitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 14),
      fontWeight: FontWeight.w600,
      color: BusquedaColors.textPrimary,
    );
  }

  static TextStyle headerSubtitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 12),
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w500,
    );
  }

  // Estilos para el estado de carga
  static TextStyle loadingTitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 16),
      fontWeight: FontWeight.w500,
      color: Colors.grey.shade700,
    );
  }

  static TextStyle loadingSubtitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 14),
      color: Colors.grey.shade500,
    );
  }

  // Estilos para headers de sección
  static TextStyle sectionHeader(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 16),
      fontWeight: FontWeight.w600,
      color: BusquedaColors.textPrimary,
    );
  }

  // Estilos para tarjetas de categoría
  static TextStyle categoryName(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 16),
      color: BusquedaColors.textPrimary,
    );
  }

  static TextStyle categoryBadge(BuildContext context) {
    return TextStyle(
      color: BusquedaColors.primaryBlue,
      fontWeight: FontWeight.w500,
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 12),
    );
  }

  // Estilos para tarjetas de producto
  static TextStyle productName(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 16),
      color: BusquedaColors.textPrimary,
      height: 1.3,
    );
  }

  static TextStyle productPrice(BuildContext context) {
    return TextStyle(
      color: BusquedaColors.primaryGreen,
      fontWeight: FontWeight.w700,
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 15),
    );
  }

  // Estilos para estado vacío
  static TextStyle emptyStateTitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 20),
      fontWeight: FontWeight.w600,
      color: BusquedaColors.textPrimary,
    );
  }

  static TextStyle emptyStateSubtitle(BuildContext context) {
    return TextStyle(
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 14),
      color: Colors.grey.shade600,
      fontWeight: FontWeight.w500,
    );
  }

  // Estilos para botones
  static TextStyle buttonText(BuildContext context) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: const Color(0xFF6B7280),
      fontSize: BusquedaDimensions.getResponsiveFontSize(context, 14),
    );
  }

  // Estilos para SnackBar
  static const TextStyle snackBarText = TextStyle(
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );
}