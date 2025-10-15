import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'editar_producto_styles.dart';

/// Clase que contiene todos los widgets reutilizables para la pantalla de editar producto
class EditarProductoWidgets {
  
  /// Header de sección con icono y línea decorativa
  static Widget buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Animation<Offset> slideAnimation,
  ) {
    return SlideTransition(
      position: slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: EditarProductoStyles.iconContainerDecoration(
                EditarProductoStyles.primaryColor,
              ),
              child: Icon(
                icon,
                color: EditarProductoStyles.primaryColor,
                size: EditarProductoStyles.mediumIconSize(context),
              ),
            ),
            SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
            Expanded(
              child: Text(
                title,
                style: EditarProductoStyles.sectionHeader(context),
              ),
            ),
            SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EditarProductoStyles.primaryColor.withOpacity(0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Campo de texto personalizado
  static Widget buildTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required VoidCallback onChanged,
    IconData? icon,
    TextInputType tipo = TextInputType.text,
    bool obligatorio = true,
    int maxLines = 1,
    String? hint,
    FocusNode? nextFocus,
    String? Function(String?, String, {bool isNumeric})? validator,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: EditarProductoStyles.getResponsiveSize(context, 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(label, style: EditarProductoStyles.fieldLabel(context)),
              ),
              if (obligatorio)
                Text(' *', style: EditarProductoStyles.requiredMark(context)),
            ],
          ),
          SizedBox(height: EditarProductoStyles.smallSpacing(context)),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: tipo,
            maxLines: maxLines,
            textInputAction:
                nextFocus != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                nextFocus.requestFocus();
              } else {
                focusNode.unfocus();
              }
            },
            onChanged: (value) => onChanged(),
            validator: (value) => validator?.call(
              value,
              label,
              isNumeric: tipo == TextInputType.number,
            ),
            style: EditarProductoStyles.fieldText(context),
            decoration: EditarProductoStyles.textFieldDecoration(
              context: context,
              hintText: hint,
              prefixIcon: icon,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: EditarProductoStyles.mediumIconSize(context),
                      ),
                      onPressed: () {
                        controller.clear();
                        onChanged();
                      },
                      color: const Color(0xFF9CA3AF),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  /// Dropdown personalizado
  static Widget buildDropdownField<T>({
    required BuildContext context,
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool obligatorio = true,
    IconData? icon,
    String? hint,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: EditarProductoStyles.getResponsiveSize(context, 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(label, style: EditarProductoStyles.fieldLabel(context)),
              ),
              if (obligatorio)
                Text(' *', style: EditarProductoStyles.requiredMark(context)),
            ],
          ),
          SizedBox(height: EditarProductoStyles.smallSpacing(context)),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: (val) =>
                obligatorio && val == null ? 'Campo obligatorio' : null,
            style: EditarProductoStyles.fieldText(context).copyWith(
              color: Colors.black,
            ),
            decoration: EditarProductoStyles.dropdownDecoration(
              context: context,
              hintText: hint,
              prefixIcon: icon,
            ),
          ),
        ],
      ),
    );
  }

  /// Switch de disponibilidad
  static Widget buildStatusSwitch({
    required BuildContext context,
    required bool disponible,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: EditarProductoStyles.getResponsiveSize(context, 20),
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(EditarProductoStyles.mediumSpacing(context)),
          decoration: EditarProductoStyles.cardDecoration,
          child: Row(
            children: [
              AnimatedContainer(
                duration: EditarProductoStyles.mediumAnimationDuration,
                padding: EdgeInsets.all(EditarProductoStyles.smallSpacing(context)),
                decoration: EditarProductoStyles.iconContainerDecoration(
                  EditarProductoStyles.getAvailabilityColor(disponible),
                ),
                child: Icon(
                  EditarProductoStyles.getAvailabilityIcon(disponible),
                  color: EditarProductoStyles.getAvailabilityColor(disponible),
                  size: EditarProductoStyles.largeIconSize(context),
                ),
              ),
              SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad del producto',
                      style: EditarProductoStyles.fieldLabel(context),
                    ),
                    Text(
                      disponible
                          ? 'Producto disponible para venta'
                          : 'Producto no disponible para venta',
                      style: EditarProductoStyles.fieldHint(context),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: disponible ? 1.1 : 1.0,
                duration: EditarProductoStyles.shortAnimationDuration,
                child: Switch(
                  value: disponible,
                  onChanged: (val) {
                    onChanged(val);
                    HapticFeedback.selectionClick();
                  },
                  activeColor: EditarProductoStyles.successColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Resumen rápido de estadísticas
  static Widget buildQuickStats({
    required BuildContext context,
    required String? estadoSeleccionado,
    required bool disponible,
    required String stock,
  }) {
    return Container(
      margin: EdgeInsets.only(
        bottom: EditarProductoStyles.getResponsiveSize(context, 20),
      ),
      padding: EdgeInsets.all(EditarProductoStyles.mediumSpacing(context)),
      decoration: EditarProductoStyles.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del producto',
            style: EditarProductoStyles.fieldLabel(context),
          ),
          SizedBox(height: EditarProductoStyles.mediumSpacing(context)),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 400) {
                return Row(
                  children: [
                    _buildStatItem(
                      context,
                      'Estado',
                      estadoSeleccionado?.toUpperCase() ?? 'NO DEFINIDO',
                      EditarProductoStyles.getStatusColor(estadoSeleccionado),
                    ),
                    SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
                    _buildStatItem(
                      context,
                      'Disponible',
                      disponible ? 'SÍ' : 'NO',
                      EditarProductoStyles.getAvailabilityColor(disponible),
                    ),
                    SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
                    _buildStatItem(context, 'Stock', stock, Colors.blue),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatItem(
                          context,
                          'Estado',
                          estadoSeleccionado?.toUpperCase() ?? 'NO DEFINIDO',
                          EditarProductoStyles.getStatusColor(estadoSeleccionado),
                        ),
                        SizedBox(width: EditarProductoStyles.mediumSpacing(context)),
                        _buildStatItem(
                          context,
                          'Disponible',
                          disponible ? 'SÍ' : 'NO',
                          EditarProductoStyles.getAvailabilityColor(disponible),
                        ),
                      ],
                    ),
                    SizedBox(height: EditarProductoStyles.mediumSpacing(context)),
                    Row(
                      children: [
                        _buildStatItem(context, 'Stock', stock, Colors.blue),
                        const Spacer(),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: EditarProductoStyles.fieldHint(context)),
          SizedBox(height: EditarProductoStyles.smallSpacing(context) / 2),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: EditarProductoStyles.smallSpacing(context),
              vertical: EditarProductoStyles.smallSpacing(context) / 2,
            ),
            decoration: EditarProductoStyles.statusBadgeDecoration(color),
            child: Text(
              value,
              style: EditarProductoStyles.statusBadgeText(context, color),
            ),
          ),
        ],
      ),
    );
  }

  /// Placeholder para imagen
  static Widget buildImagePlaceholder(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(EditarProductoStyles.mediumSpacing(context)),
          decoration: EditarProductoStyles.iconContainerDecoration(
            EditarProductoStyles.primaryColor,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: EditarProductoStyles.extraLargeIconSize(context),
            color: EditarProductoStyles.primaryColor,
          ),
        ),
        SizedBox(height: EditarProductoStyles.mediumSpacing(context)),
        Text(
          'Seleccionar imagen',
          style: EditarProductoStyles.fieldLabel(context).copyWith(
            fontSize: EditarProductoStyles.getResponsiveSize(context, 16),
          ),
        ),
        SizedBox(height: EditarProductoStyles.smallSpacing(context) / 2),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: EditarProductoStyles.mediumSpacing(context),
          ),
          child: Text(
            'Toca para cambiar o seleccionar nueva imagen',
            style: EditarProductoStyles.fieldHint(context),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: EditarProductoStyles.smallSpacing(context)),
        Text(
          'PNG, JPG hasta 5MB',
          style: EditarProductoStyles.fieldHint(context).copyWith(
            fontSize: EditarProductoStyles.getResponsiveSize(context, 12),
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  /// Vista previa de imagen con controles
  static Widget buildImagePreview({
    required BuildContext context,
    required Widget image,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
    required bool showPreview,
    required bool isNewImage,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: image,
          ),
        ),
        Positioned(
          top: EditarProductoStyles.mediumSpacing(context) / 1.5,
          right: EditarProductoStyles.mediumSpacing(context) / 1.5,
          child: Container(
            decoration: EditarProductoStyles.overlayDecoration,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: EditarProductoStyles.smallIconSize(context),
                  ),
                  onPressed: onEdit,
                  constraints: BoxConstraints(
                    minWidth: EditarProductoStyles.getResponsiveSize(context, 32),
                    minHeight: EditarProductoStyles.getResponsiveSize(context, 32),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: EditarProductoStyles.smallIconSize(context),
                  ),
                  onPressed: onDelete,
                  constraints: BoxConstraints(
                    minWidth: EditarProductoStyles.getResponsiveSize(context, 32),
                    minHeight: EditarProductoStyles.getResponsiveSize(context, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (showPreview)
          Positioned(
            bottom: EditarProductoStyles.mediumSpacing(context) / 1.5,
            left: EditarProductoStyles.mediumSpacing(context) / 1.5,
            right: EditarProductoStyles.mediumSpacing(context) / 1.5,
            child: Container(
              padding: EdgeInsets.all(EditarProductoStyles.mediumSpacing(context) / 1.5),
              decoration: EditarProductoStyles.imageOverlayDecoration,
              child: Text(
                isNewImage ? 'Imagen nueva seleccionada' : 'Imagen actual del producto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: EditarProductoStyles.getResponsiveSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  /// Pantalla de carga
  static Widget buildLoadingScreen(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: EditarProductoStyles.getResponsiveSize(context, 80),
            height: EditarProductoStyles.getResponsiveSize(context, 80),
            decoration: EditarProductoStyles.iconContainerDecoration(
              EditarProductoStyles.primaryColor,
            ),
            child: Center(
              child: CircularProgressIndicator(
                color: EditarProductoStyles.primaryColor,
                strokeWidth: EditarProductoStyles.getResponsiveSize(context, 3),
              ),
            ),
          ),
          SizedBox(height: EditarProductoStyles.largeIconSize(context)),
          Text(
            'Cargando producto...',
            style: EditarProductoStyles.fieldLabel(context).copyWith(
              fontSize: EditarProductoStyles.getResponsiveSize(context, 18),
            ),
          ),
          SizedBox(height: EditarProductoStyles.smallSpacing(context)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: EditarProductoStyles.getResponsiveSize(context, 32),
            ),
            child: Text(
              'Obteniendo información del producto',
              style: EditarProductoStyles.fieldHint(context),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Badge de cambios sin guardar
  static Widget buildUnsavedChangesBadge(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        right: EditarProductoStyles.smallSpacing(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: EditarProductoStyles.smallSpacing(context),
        vertical: EditarProductoStyles.smallSpacing(context) / 2,
      ),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            color: Colors.orange,
            size: EditarProductoStyles.smallSpacing(context),
          ),
          SizedBox(width: EditarProductoStyles.smallSpacing(context) / 2),
          Text(
            'Sin guardar',
            style: TextStyle(
              fontSize: EditarProductoStyles.getResponsiveSize(context, 12),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}