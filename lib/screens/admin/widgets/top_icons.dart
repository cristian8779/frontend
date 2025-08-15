import 'package:flutter/material.dart';
import '../../../utils/show_settings_modal.dart';

class TopIcons extends StatelessWidget {
  final String rol;
  final bool showNotificationIcon; // <-- Nuevo parámetro opcional

  const TopIcons({
    super.key,
    required this.rol,
    this.showNotificationIcon = true, // Por defecto visible
  });

  // Función para obtener dimensiones responsivas
  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'iconSize': 32.0,
        'buttonSize': 56.0,
        'spacing': 16.0,
      };
    } else if (isTablet) {
      return {
        'iconSize': 30.0,
        'buttonSize': 52.0,
        'spacing': 12.0,
      };
    } else {
      return {
        'iconSize': 28.0,
        'buttonSize': 48.0,
        'spacing': 8.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _getResponsiveDimensions(context);
        
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: dimensions['buttonSize']!,
              height: dimensions['buttonSize']!,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.transparent,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.settings,
                  color: Colors.black87,
                  size: dimensions['iconSize']!,
                ),
                onPressed: () {
                  mostrarOpcionesDeConfiguracion(
                    context: context,
                    rol: rol,
                  );
                },
                padding: EdgeInsets.all(dimensions['spacing']!),
                constraints: BoxConstraints(
                  minWidth: dimensions['buttonSize']!,
                  minHeight: dimensions['buttonSize']!,
                ),
              ),
            ),

            // Solo mostramos el ícono si showNotificationIcon es true
            if (showNotificationIcon)
              Container(
                width: dimensions['buttonSize']!,
                height: dimensions['buttonSize']!,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications,
                    color: Colors.red,
                    size: dimensions['iconSize']!,
                  ),
                  onPressed: () {},
                  padding: EdgeInsets.all(dimensions['spacing']!),
                  constraints: BoxConstraints(
                    minWidth: dimensions['buttonSize']!,
                    minHeight: dimensions['buttonSize']!,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}