import 'package:flutter/material.dart';
import '../../../utils/show_settings_modal.dart';

class TopIcons extends StatelessWidget {
  final String rol;
  final bool showNotificationIcon;  // <-- Nuevo parámetro opcional

  const TopIcons({
    super.key,
    required this.rol,
    this.showNotificationIcon = true, // Por defecto visible
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.black87, size: 28),
          onPressed: () {
            mostrarOpcionesDeConfiguracion(
              context: context,
              rol: rol,
            );
          },
        ),

        // Solo mostramos el ícono si showNotificationIcon es true
        if (showNotificationIcon)
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.red, size: 28),
            onPressed: () {},
          ),
      ],
    );
  }
}
