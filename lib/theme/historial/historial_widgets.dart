// theme/historial/historial_widgets.dart
import 'package:flutter/material.dart';
import 'historial_colors.dart';
import 'historial_text_styles.dart';
import 'historial_dimensions.dart';
import 'historial_decorations.dart';

class HistorialWidgets {
  // Widget de loading
  static Widget get loading => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(HistorialColors.primaryBlue),
        ),
        SizedBox(height: HistorialDimensions.paddingMedium),
        Text(
          "Cargando historial...",
          style: HistorialTextStyles.loadingText,
        ),
      ],
    ),
  );
  
  // Widget de error
  static Widget buildError(String error, VoidCallback onRetry) => Center(
    child: Container(
      margin: const EdgeInsets.all(HistorialDimensions.paddingXLarge),
      padding: const EdgeInsets.all(HistorialDimensions.paddingXXLarge),
      decoration: HistorialDecorations.errorContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline,
            size: HistorialDimensions.iconSizeXXLarge,
            color: Colors.red,
          ),
          const SizedBox(height: HistorialDimensions.paddingMedium),
          const Text(
            "Error al cargar",
            style: HistorialTextStyles.errorTitle,
          ),
          const SizedBox(height: HistorialDimensions.paddingSmall),
          Text(
            error,
            textAlign: TextAlign.center,
            style: HistorialTextStyles.errorDescription,
          ),
          const SizedBox(height: HistorialDimensions.paddingXLarge),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text("Reintentar"),
          ),
        ],
      ),
    ),
  );
  
  // Widget de estado vacío
  static Widget get emptyState => Center(
    child: Container(
      margin: const EdgeInsets.all(HistorialDimensions.paddingXLarge),
      padding: const EdgeInsets.all(HistorialDimensions.paddingXXLarge),
      decoration: HistorialDecorations.emptyContainer,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: HistorialDimensions.iconSizeEmpty,
            color: HistorialColors.iconPrimary,
          ),
          const SizedBox(height: HistorialDimensions.paddingMedium),
          const Text(
            "No hay productos en el historial",
            style: HistorialTextStyles.emptyStateTitle,
          ),
          const SizedBox(height: HistorialDimensions.paddingSmall),
          const Text(
            "Los productos que veas aparecerán aquí",
            style: HistorialTextStyles.emptyStateDescription,
          ),
        ],
      ),
    ),
  );
  
  // Widget de cabecera de fecha
  static Widget buildDateHeader(String fecha) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: HistorialDimensions.paddingMedium,
      vertical: HistorialDimensions.paddingMedium,
    ),
    color: HistorialColors.sectionBackground,
    child: Text(
      fecha,
      style: HistorialTextStyles.dateSection,
    ),
  );
  
  // SnackBar de éxito
  static SnackBar buildSuccessSnackBar(String message, {int seconds = 2}) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.check_circle, color: Colors.white, size: HistorialDimensions.iconSizeMedium),
        const SizedBox(width: HistorialDimensions.paddingSmall),
        Flexible(child: Text(message)),
      ],
    ),
    backgroundColor: HistorialColors.successGreen,
    behavior: SnackBarBehavior.floating,
    shape: HistorialDecorations.snackBarShape,
    duration: Duration(seconds: seconds),
  );
  
  // SnackBar de error
  static SnackBar buildErrorSnackBar(String message) => SnackBar(
    content: Row(
      children: [
        const Icon(Icons.error, color: Colors.white, size: HistorialDimensions.iconSizeMedium),
        const SizedBox(width: HistorialDimensions.paddingSmall),
        Expanded(child: Text(message)),
      ],
    ),
    backgroundColor: HistorialColors.errorRed,
    behavior: SnackBarBehavior.floating,
    shape: HistorialDecorations.snackBarShape,
  );
  
  // Diálogo de confirmación de borrado
  static AlertDialog buildDeleteDialog(
    BuildContext context,
    VoidCallback onConfirm,
  ) => AlertDialog(
    shape: HistorialDecorations.dialogShape,
    title: Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: HistorialColors.warningOrange,
          size: HistorialDimensions.iconSizeLarge,
        ),
        const SizedBox(width: HistorialDimensions.paddingSmall),
        const Flexible(
          child: Text(
            "Borrar historial",
            style: HistorialTextStyles.dialogTitle,
          ),
        ),
      ],
    ),
    content: const Text(
      "¿Seguro que quieres borrar todo el historial? Esta acción no se puede deshacer.",
      style: HistorialTextStyles.dialogContent,
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        style: TextButton.styleFrom(
          foregroundColor: HistorialColors.iconSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: HistorialDimensions.paddingMedium,
            vertical: HistorialDimensions.paddingSmall,
          ),
        ),
        child: const Text(
          "Cancelar",
          style: HistorialTextStyles.buttonCancel,
        ),
      ),
      ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          onConfirm();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: HistorialColors.errorRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: HistorialDimensions.paddingMedium,
            vertical: HistorialDimensions.paddingSmall,
          ),
          shape: HistorialDecorations.buttonShape,
        ),
        child: const Text(
          "Borrar todo",
          style: HistorialTextStyles.buttonDelete,
        ),
      ),
    ],
  );
}