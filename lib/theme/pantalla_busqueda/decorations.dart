import 'package:flutter/material.dart';
import 'colors.dart';
import 'dimensions.dart';

/// Decoraciones reutilizables para la pantalla de búsqueda
class BusquedaDecorations {
  BusquedaDecorations._();

  /// Decoración para las tarjetas principales
  static BoxDecoration cardDecoration({
    bool isTablet = false,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: BusquedaColors.card,
      borderRadius: BorderRadius.circular(16),
      border: borderColor != null
          ? Border.all(color: borderColor, width: 1.5)
          : null,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Decoración con gradiente para header stats
  static BoxDecoration headerStatsDecoration(BuildContext context) {
    final isTablet = BusquedaDimensions.isTablet(context);
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [BusquedaColors.primaryPastel, BusquedaColors.accentPastel],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: isTablet ? 12 : 8,
          offset: Offset(0, isTablet ? 3 : 2),
        ),
      ],
    );
  }

  /// Decoración para el contenedor de carga
  static BoxDecoration loadingContainerDecoration({
    required bool isTablet,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [BusquedaColors.primaryPastel, BusquedaColors.lavenderPastel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: isTablet ? 16 : 12,
          offset: Offset(0, isTablet ? 6 : 4),
        ),
      ],
    );
  }

  /// Decoración para el estado vacío
  static BoxDecoration emptyStateDecoration({
    required bool isTablet,
  }) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [BusquedaColors.primaryPastel, BusquedaColors.lavenderPastel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: isTablet ? 16 : 12,
          offset: Offset(0, isTablet ? 6 : 4),
        ),
      ],
    );
  }

  /// Decoración para el icono de categoría
  static BoxDecoration categoryIconDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [BusquedaColors.primaryPastel, BusquedaColors.accentPastel],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Decoración para el contenedor de imagen de producto
  static BoxDecoration productImageContainerDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Colors.grey.shade200,
        width: 1,
      ),
    );
  }

  /// Decoración para el placeholder de imagen
  static BoxDecoration imagePlaceholderDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(10),
    );
  }

  /// Decoración para el contenedor de precio
  static BoxDecoration priceContainerDecoration(BuildContext context) {
    final isTablet = BusquedaDimensions.isTablet(context);
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [
          BusquedaColors.accentPastel,
          BusquedaColors.accentPastel.withOpacity(0.7)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: BusquedaColors.primaryGreen.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Decoración para el badge de "Ver productos"
  static BoxDecoration viewProductsBadgeDecoration() {
    return BoxDecoration(
      color: BusquedaColors.primaryPastel,
      borderRadius: BorderRadius.circular(6),
    );
  }

  /// Decoración para el contenedor del icono de sección
  static BoxDecoration sectionIconContainerDecoration({
    required bool isTablet,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.8),
      borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
    );
  }

  /// Decoración para el header de sección
  static BoxDecoration sectionHeaderDecoration() {
    return BoxDecoration(
      color: BusquedaColors.lavenderPastel,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Decoración para el botón de nueva búsqueda
  static BoxDecoration newSearchButtonDecoration(BuildContext context) {
    final isTablet = BusquedaDimensions.isTablet(context);
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [BusquedaColors.primaryPastel, BusquedaColors.accentPastel],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
    );
  }

  /// Decoración para el contenedor del botón de flecha
  static BoxDecoration arrowButtonDecoration() {
    return BoxDecoration(
      color: BusquedaColors.primaryPastel,
      borderRadius: BorderRadius.circular(10),
    );
  }

  /// Decoración para el botón de retroceso en el AppBar
  static BoxDecoration backButtonDecoration() {
    return BoxDecoration(
      color: Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
    );
  }

  /// Gradiente para el divisor del AppBar
  static Gradient appBarDividerGradient() {
    return LinearGradient(
      colors: [
        Colors.grey.shade200,
        Colors.transparent,
        Colors.grey.shade200,
      ],
    );
  }
}