import 'package:flutter/material.dart';
import 'invitaciones_colors.dart';

class InvitacionesDecorations {
  // Container decorations
  static BoxDecoration cardDecoration = BoxDecoration(
    color: InvitacionesColors.cardBackground,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: InvitacionesColors.border),
  );

  static BoxDecoration cardWithShadowDecoration = BoxDecoration(
    color: InvitacionesColors.cardBackground,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: InvitacionesColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration dialogDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(20),
  );

  // Icon containers
  static BoxDecoration iconContainer(Color color, {double radius = 8}) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(radius),
  );

  static BoxDecoration circleIconContainer(Color color, {Border? border}) => BoxDecoration(
    color: color,
    shape: BoxShape.circle,
    border: border,
  );

  // Estado decorations
  static BoxDecoration estadoBadge(Color backgroundColor, Color borderColor) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: borderColor.withOpacity(0.3)),
  );

  static BoxDecoration estadoIconContainer(Color backgroundColor, Color borderColor, double radius) => BoxDecoration(
    color: backgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor.withOpacity(0.3)),
  );

  // Info containers
  static BoxDecoration infoContainer(bool isSmall) => BoxDecoration(
    color: InvitacionesColors.accent.withOpacity(0.05),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: InvitacionesColors.accent.withOpacity(0.2)),
  );

  static BoxDecoration warningContainer(bool isSmall) => BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.red.shade200),
  );

  static BoxDecoration confirmationBox(bool isSmall) => BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.grey.shade300),
  );

  static BoxDecoration timeInfoContainer(bool isSmall) => BoxDecoration(
    color: const Color(0xFFF8FAFC),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: InvitacionesColors.border),
  );

  // Gradient decorations
  static BoxDecoration gradientContainer(List<Color> colors, {double radius = 12}) => BoxDecoration(
    gradient: LinearGradient(
      colors: colors,
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(radius),
  );

  static BoxDecoration restrictedAccessIconDecoration(bool isSmall) => BoxDecoration(
    gradient: LinearGradient(
      colors: [Colors.red.shade400, Colors.red.shade600],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(isSmall ? 50 : 70),
    boxShadow: [
      BoxShadow(
        color: Colors.red.shade200,
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  );

  static BoxDecoration whiteCardWithShadow(bool isSmall) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade200,
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );

  // Input decorations
  static InputDecoration textFieldDecoration(bool isSmall, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(fontSize: isSmall ? 13 : 14),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: EdgeInsets.symmetric(
      horizontal: isSmall ? 12 : 16,
      vertical: isSmall ? 14 : 16,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: InvitacionesColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: InvitacionesColors.border),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: InvitacionesColors.accent, width: 2),
    ),
  );

  static InputDecoration dialogTextFieldDecoration(bool isSmall) => InputDecoration(
    labelText: "Confirmación",
    hintText: "Escribe: ELIMINAR TODO",
    prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
    ),
    filled: true,
    fillColor: Colors.grey.shade50,
  );

  // Shimmer decoration
  static BoxDecoration shimmerContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration shimmerElement = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(4),
  );

  // Summary container
  static BoxDecoration summaryContainer = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: InvitacionesColors.border),
  );

  // Stat item decoration
  static BoxDecoration statBadge(Color color) => BoxDecoration(
    color: color.withOpacity(0.1),
    borderRadius: BorderRadius.circular(6),
  );

  // Empty state decoration
  static BoxDecoration emptyStateContainer(bool isSmall) => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: InvitacionesColors.border),
  );

  static BoxDecoration emptyStateIcon(bool isSmall) => BoxDecoration(
    color: InvitacionesColors.accent.withOpacity(0.1),
    shape: BoxShape.circle,
  );
}