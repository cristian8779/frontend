// top_icons.dart
import 'package:flutter/material.dart';
import '../../../utils/show_settings_modal.dart';
import '../styles/top_icons_styles.dart'; // Import de los estilos

class TopIcons extends StatelessWidget {
  final String rol;
  final bool showNotificationIcon;

  const TopIcons({
    super.key,
    required this.rol,
    this.showNotificationIcon = TopIconsTheme.defaultShowNotification,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = TopIconsDimensions.getResponsiveDimensions(context);
        
        return Row(
          mainAxisAlignment: TopIconsLayout.mainAxisAlignment,
          children: [
            _buildSettingsButton(context, dimensions),
            if (showNotificationIcon)
              _buildNotificationButton(context, dimensions),
          ],
        );
      },
    );
  }

  Widget _buildSettingsButton(BuildContext context, Map<String, double> dimensions) {
    return _buildIconButton(
      dimensions: dimensions,
      icon: TopIconsTheme.settingsIcon,
      color: TopIconsTheme.settingsIconColor,
      onPressed: () => _handleSettingsPressed(context),
    );
  }

  Widget _buildNotificationButton(BuildContext context, Map<String, double> dimensions) {
    return _buildIconButton(
      dimensions: dimensions,
      icon: TopIconsTheme.notificationIcon,
      color: TopIconsTheme.notificationIconColor,
      onPressed: _handleNotificationPressed,
    );
  }

  Widget _buildIconButton({
    required Map<String, double> dimensions,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: dimensions['buttonSize']!,
      height: dimensions['buttonSize']!,
      decoration: TopIconsDecorations.getButtonContainerDecoration(),
      child: IconButton(
        icon: Icon(
          icon,
          color: color,
          size: dimensions['iconSize']!,
        ),
        onPressed: onPressed,
        padding: TopIconsLayout.getIconPadding(dimensions),
        constraints: TopIconsLayout.getButtonConstraints(dimensions),
      ),
    );
  }

  // Handlers de eventos
  void _handleSettingsPressed(BuildContext context) {
    mostrarOpcionesDeConfiguracion(
      context: context,
      rol: rol,
    );
  }

  void _handleNotificationPressed() {
    // TODO: Implementar lógica de notificaciones
  }
}