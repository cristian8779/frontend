import 'package:flutter/material.dart';

class CrearVariacionStyles {
  // Colores principales
  static const Color primaryBlue = Color(0xFF3A86FF);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textGray = Color(0xFF718096);
  static const Color backgroundLight = Color(0xFFF7FAFC);

  // Decoraciones de contenedores
  static BoxDecoration whiteCardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration modeToggleDecoration = BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(12),
  );

  static BoxDecoration modeActiveDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static BoxDecoration previewContainerDecoration = BoxDecoration(
    color: primaryBlue.withOpacity(0.1),
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: primaryBlue.withOpacity(0.3)),
  );

  static BoxDecoration imageContainerDecoration(bool hasImage) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: hasImage ? primaryBlue : Colors.grey.shade300,
        width: hasImage ? 2 : 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration colorCircleDecoration(String colorHex) {
    return BoxDecoration(
      color: Color(int.parse('0xFF${colorHex.substring(1)}')),
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration editBadgeDecoration = BoxDecoration(
    color: Colors.black.withOpacity(0.6),
    borderRadius: BorderRadius.circular(20),
  );

  static BoxDecoration photoPlaceholderDecoration = BoxDecoration(
    color: primaryBlue.withOpacity(0.1),
    shape: BoxShape.circle,
  );

  static BoxDecoration resumenLotesDecoration = BoxDecoration(
    color: Colors.orange.shade50,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.orange.shade200),
  );

  static BoxDecoration infoContainerDecoration = BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300),
  );

  static BoxDecoration colorChipDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300),
  );

  // InputDecoration para TextFields
  static InputDecoration textFieldDecoration({
    required String label,
    String? prefix,
    String? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red.shade400, width: 2),
      ),
    );
  }

  // Estilos de texto
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textDark,
  );

  static TextStyle modeTextStyle(bool isActive) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      color: isActive ? primaryBlue : Colors.grey.shade600,
    );
  }

  static const TextStyle previewTitleStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle colorNameStyle = TextStyle(
    fontWeight: FontWeight.w500,
    color: textDark,
  );

  static const TextStyle photoPlaceholderTextStyle = TextStyle(
    color: textGray,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle photoSizeTextStyle = TextStyle(
    color: Colors.grey.shade500,
    fontSize: 12,
  );

  static TextStyle resumenTitleStyle = TextStyle(
    fontWeight: FontWeight.w600,
    color: Colors.orange.shade800,
    fontSize: 14,
  );

  static TextStyle resumenSubtitleStyle = TextStyle(
    color: Colors.orange.shade700,
    fontSize: 12,
  );

  static const TextStyle smallTextStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle previewDetailStyle = TextStyle(fontSize: 12);

  static TextStyle infoTextStyle = TextStyle(
    color: Colors.grey.shade600,
    fontSize: 14,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  static TextStyle clearButtonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.grey.shade600,
  );

  // Estilos de botones
  static ButtonStyle primaryButtonStyle({bool isEnabled = true}) {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryBlue,
      foregroundColor: Colors.white,
      disabledBackgroundColor: Colors.grey.shade300,
      elevation: isEnabled ? 2 : 0,
      shadowColor: primaryBlue.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    side: BorderSide(color: Colors.grey.shade400),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
  );

  // Iconos y tamaños
  static const double sectionIconSize = 20.0;
  static const double checkIconSize = 16.0;
  static const double editIconSize = 16.0;
  static const double smallEditIconSize = 12.0;
  static const double photoIconSize = 32.0;
  static const double infoIconSize = 20.0;
  static const double buttonIconSize = 20.0;

  static const double colorCircleSize = 24.0;
  static const double smallColorCircleSize = 16.0;

  // Paddings y márgenes
  static const EdgeInsets cardPadding = EdgeInsets.all(16);
  static const EdgeInsets sectionPadding = EdgeInsets.only(bottom: 12);
  static const EdgeInsets containerMargin = EdgeInsets.symmetric(vertical: 8);
  static const EdgeInsets screenPadding = EdgeInsets.all(20);
  static const EdgeInsets modeTogglePadding = EdgeInsets.all(4);
  static const EdgeInsets modeToggleMargin = EdgeInsets.only(bottom: 20);
  static const EdgeInsets modeButtonPadding = EdgeInsets.symmetric(vertical: 12);

  // Espaciados
  static const SizedBox smallSpacing = SizedBox(height: 8);
  static const SizedBox mediumSpacing = SizedBox(height: 16);
  static const SizedBox largeSpacing = SizedBox(height: 24);
  static const SizedBox xlargeSpacing = SizedBox(height: 32);

  static const SizedBox smallHorizontalSpacing = SizedBox(width: 8);
  static const SizedBox mediumHorizontalSpacing = SizedBox(width: 12);

  // Tamaños de contenedores
  static const double imageContainerHeight = 200.0;
  static const double buttonHeight = 56.0;

  // BorderRadius
  static BorderRadius cardBorderRadius = BorderRadius.circular(16);
  static BorderRadius smallBorderRadius = BorderRadius.circular(8);
  static BorderRadius mediumBorderRadius = BorderRadius.circular(12);

  // Colores de iconos
  static Color get primaryIconColor => primaryBlue;
  static Color get grayIconColor => Colors.grey.shade600;
  static Color get orangeIconColor => Colors.orange.shade600;
  static Color get infoIconColor => Colors.grey.shade600;
}