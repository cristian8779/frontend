import 'package:flutter/material.dart';
import 'invitaciones_colors.dart';
import 'invitaciones_dimensions.dart';

class InvitacionesButtonStyles {
  // Primary button
  static ButtonStyle primaryButton(bool isSmall) => ElevatedButton.styleFrom(
    backgroundColor: InvitacionesColors.success,
    foregroundColor: Colors.white,
    disabledBackgroundColor: InvitacionesColors.tertiaryText,
    elevation: InvitacionesDimensions.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(InvitacionesDimensions.getButtonRadius),
    ),
  );

  // Danger button
  static ButtonStyle dangerButton(bool isSmall) => ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade600,
    foregroundColor: Colors.white,
    padding: InvitacionesDimensions.getSmallButtonPadding(isSmall),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  // Back button
  static ButtonStyle backButton(bool isSmall) => ElevatedButton.styleFrom(
    backgroundColor: Colors.blue.shade600,
    foregroundColor: Colors.white,
    padding: InvitacionesDimensions.getButtonPadding(isSmall),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    elevation: InvitacionesDimensions.buttonElevation,
  );

  // Text button
  static ButtonStyle textButton(bool isSmall) => TextButton.styleFrom(
    padding: InvitacionesDimensions.getSmallButtonPadding(isSmall),
  );

  // Dialog text button
  static ButtonStyle dialogTextButton(bool isSmall) => TextButton.styleFrom(
    padding: EdgeInsets.symmetric(
      horizontal: isSmall ? 20 : 24,
      vertical: isSmall ? 10 : 12,
    ),
  );

  // Icon button
  static ButtonStyle iconButton(bool isSmall) => IconButton.styleFrom(
    backgroundColor: Colors.red.shade50,
    padding: InvitacionesDimensions.getIconButtonPadding(isSmall),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  // Shaped button
  static ShapeBorder roundedBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  );

  static ShapeBorder dialogBorder = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  );
}