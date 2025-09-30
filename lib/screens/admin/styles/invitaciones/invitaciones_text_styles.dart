import 'package:flutter/material.dart';
import 'invitaciones_colors.dart';

class InvitacionesTextStyles {
  // Títulos
  static TextStyle title(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: isSmall ? 18 : 20,
    letterSpacing: -0.5,
  );

  static TextStyle sectionTitle(bool isSmall) => TextStyle(
    fontSize: isSmall ? 16 : 18,
    fontWeight: FontWeight.w700,
    color: InvitacionesColors.primaryText,
    letterSpacing: -0.5,
  );

  static TextStyle cardTitle(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: isSmall ? 14 : 16,
    color: InvitacionesColors.primaryText,
  );

  static TextStyle dialogTitle(bool isSmall) => TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: isSmall ? 18 : 20,
  );

  // Subtítulos y labels
  static TextStyle label(bool isSmall) => TextStyle(
    fontSize: isSmall ? 13 : 14,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF374151),
  );

  static TextStyle subtitle(bool isSmall) => TextStyle(
    color: InvitacionesColors.secondaryText,
    fontSize: isSmall ? 12 : 14,
  );

  static TextStyle hint(bool isSmall) => TextStyle(
    fontSize: isSmall ? 13 : 14,
  );

  // Body text
  static TextStyle body(bool isSmall) => TextStyle(
    fontSize: isSmall ? 14 : 16,
    color: InvitacionesColors.secondaryText,
    height: 1.6,
  );

  static TextStyle bodySmall(bool isSmall) => TextStyle(
    fontSize: isSmall ? 12 : 13,
    color: InvitacionesColors.secondaryText,
    height: 1.4,
  );

  static TextStyle description(bool isSmall) => TextStyle(
    color: InvitacionesColors.accent,
    fontSize: isSmall ? 12 : 13,
    height: 1.4,
    fontWeight: FontWeight.w500,
  );

  // Estados
  static TextStyle estadoText(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: isSmall ? 11 : 12,
  );

  static TextStyle timeText(bool isSmall, {bool isExpired = false}) => TextStyle(
    color: isExpired 
        ? Colors.red.shade600 
        : InvitacionesColors.secondaryText,
    fontSize: isSmall ? 12 : 13,
    fontWeight: FontWeight.w500,
  );

  // Botones
  static TextStyle button(bool isSmall) => TextStyle(
    fontSize: isSmall ? 14 : 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle buttonSmall(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: isSmall ? 13 : 14,
  );

  // Mensajes de error/éxito
  static TextStyle snackbarTitle(Color color, bool isSmall) => TextStyle(
    fontWeight: FontWeight.bold,
    color: color,
    fontSize: isSmall ? 14 : 14,
  );

  static TextStyle snackbarMessage(Color color) => TextStyle(
    color: color,
    fontSize: 13,
    height: 1.2,
  );

  // Empty state
  static TextStyle emptyStateTitle(bool isSmall) => TextStyle(
    fontSize: isSmall ? 18 : 20,
    fontWeight: FontWeight.w700,
    color: const Color(0xFF374151),
  );

  static TextStyle emptyStateMessage(bool isSmall) => TextStyle(
    color: InvitacionesColors.secondaryText,
    fontSize: isSmall ? 13 : 15,
    height: 1.4,
  );

  // Info sections
  static TextStyle infoTitle(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w700,
    fontSize: isSmall ? 14 : 15,
    color: InvitacionesColors.primaryText,
  );

  static TextStyle infoDescription(bool isSmall) => TextStyle(
    fontSize: isSmall ? 12 : 13,
    color: InvitacionesColors.secondaryText,
    height: 1.5,
  );

  // Stats
  static TextStyle statLabel(bool isSmall) => TextStyle(
    fontSize: isSmall ? 11 : 12,
    color: InvitacionesColors.secondaryText,
  );

  static TextStyle statValue(bool isSmall, Color color) => TextStyle(
    fontSize: isSmall ? 11 : 12,
    fontWeight: FontWeight.w600,
    color: color,
  );

  // Monospace
  static TextStyle monospace(bool isSmall) => TextStyle(
    fontWeight: FontWeight.bold,
    fontFamily: 'monospace',
    fontSize: isSmall ? 14 : 16,
  );

  // Warning text
  static TextStyle warningText(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.red,
    fontSize: isSmall ? 12 : 14,
  );

  static TextStyle confirmationText(bool isSmall) => TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: isSmall ? 12 : 14,
  );
}