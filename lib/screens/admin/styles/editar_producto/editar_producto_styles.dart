import 'package:flutter/material.dart';

/// Clase que contiene todos los estilos para la pantalla de editar producto
class EditarProductoStyles {
  // Colores principales
  static const Color primaryColor = Color(0xFF6366F1);
  static const Color backgroundColor = Color(0xFFF8FAFC);
  static const Color textPrimaryColor = Color(0xFF1F2937);
  static const Color textSecondaryColor = Color(0xFF374151);
  static const Color textTertiaryColor = Color(0xFF6B7280);
  static const Color borderColor = Color(0xFFE5E7EB);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFFB923C);
  
  // Funciones de tamaño responsivo
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return baseSize * 1.2; // Tablets
    if (screenWidth < 360) return baseSize * 0.9; // Pantallas pequeñas
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return const EdgeInsets.all(32);
    if (screenWidth < 360) return const EdgeInsets.all(12);
    return const EdgeInsets.all(20);
  }

  // Estilos de texto
  static TextStyle appBarTitle(BuildContext context) => TextStyle(
        fontWeight: FontWeight.w700,
        fontSize: getResponsiveSize(context, 20),
        letterSpacing: -0.5,
      );

  static TextStyle sectionHeader(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 18),
        fontWeight: FontWeight.w700,
        color: textPrimaryColor,
        letterSpacing: -0.5,
      );

  static TextStyle fieldLabel(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 14),
        fontWeight: FontWeight.w600,
        color: textSecondaryColor,
      );

  static TextStyle fieldHint(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 14),
        color: textTertiaryColor,
      );

  static TextStyle fieldText(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 16),
      );

  static TextStyle requiredMark(BuildContext context) => TextStyle(
        color: errorColor,
        fontWeight: FontWeight.w600,
        fontSize: getResponsiveSize(context, 14),
      );

  static TextStyle buttonText(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 16),
        fontWeight: FontWeight.w600,
      );

  static TextStyle statusText(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 12),
        fontWeight: FontWeight.w600,
      );

  static TextStyle helpText(BuildContext context) => TextStyle(
        fontSize: getResponsiveSize(context, 14),
      );

  // Decoraciones de contenedores
  static BoxDecoration cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: borderColor),
  );

  static BoxDecoration imageContainerDecoration({bool hasImage = false}) => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasImage ? primaryColor : borderColor,
          width: hasImage ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );

  static BoxDecoration iconContainerDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      );

  // Decoraciones de inputs
  static InputDecoration textFieldDecoration({
    required BuildContext context,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: fieldHint(context),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: EdgeInsets.only(
                left: getResponsiveSize(context, 16),
                right: getResponsiveSize(context, 12),
              ),
              child: Icon(
                prefixIcon,
                color: const Color(0xFF9CA3AF),
                size: getResponsiveSize(context, 20),
              ),
            )
          : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(context, 16),
        vertical: getResponsiveSize(context, 16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
    );
  }

  static InputDecoration dropdownDecoration({
    required BuildContext context,
    String? hintText,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: fieldHint(context),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: EdgeInsets.only(
                left: getResponsiveSize(context, 16),
                right: getResponsiveSize(context, 12),
              ),
              child: Icon(
                prefixIcon,
                color: const Color(0xFF9CA3AF),
                size: getResponsiveSize(context, 20),
              ),
            )
          : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(
        horizontal: getResponsiveSize(context, 16),
        vertical: getResponsiveSize(context, 16),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  // Estilos de botones
  static ButtonStyle primaryButtonStyle(BuildContext context, {bool isLoading = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: const Color(0xFF9CA3AF),
      elevation: isLoading ? 0 : 8,
      shadowColor: primaryColor.withOpacity(0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle secondaryButtonStyle(BuildContext context) {
    return TextButton.styleFrom(
      foregroundColor: warningColor,
      padding: EdgeInsets.symmetric(vertical: getResponsiveSize(context, 12)),
    );
  }

  static ButtonStyle dangerButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.red[600],
    foregroundColor: Colors.white,
  );

  // Estilos de diálogos
  static ShapeBorder dialogShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );

  // Estilos de SnackBar
  static ShapeBorder snackBarShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  );

  static Color snackBarErrorColor = errorColor;
  static Color snackBarSuccessColor = const Color(0xFF38A169);

  // Animaciones
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 1000);

  // Espaciados
  static double smallSpacing(BuildContext context) => getResponsiveSize(context, 8);
  static double mediumSpacing(BuildContext context) => getResponsiveSize(context, 16);
  static double largeSpacing(BuildContext context) => getResponsiveSize(context, 24);

  // Tamaños de iconos
  static double smallIconSize(BuildContext context) => getResponsiveSize(context, 16);
  static double mediumIconSize(BuildContext context) => getResponsiveSize(context, 20);
  static double largeIconSize(BuildContext context) => getResponsiveSize(context, 24);
  static double extraLargeIconSize(BuildContext context) => getResponsiveSize(context, 40);

  // Estilos de estado
  static BoxDecoration statusBadgeDecoration(Color color) => BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      );

  static TextStyle statusBadgeText(BuildContext context, Color color) => TextStyle(
        fontSize: getResponsiveSize(context, 12),
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Estilos de overlay
  static BoxDecoration overlayDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.7),
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration imageOverlayDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.7),
    borderRadius: BorderRadius.circular(8),
  );

  // Métodos helper para obtener colores según estado
  static Color getStatusColor(String? estado) {
    if (estado == 'activo') return successColor;
    return warningColor;
  }

  static Color getAvailabilityColor(bool disponible) {
    return disponible ? successColor : errorColor;
  }

  static IconData getAvailabilityIcon(bool disponible) {
    return disponible ? Icons.check_circle_outline : Icons.cancel_outlined;
  }
}