import 'package:flutter/material.dart';
import '../services/rol_service.dart'; // Ajusta la ruta según tu proyecto

Future<void> mostrarInvitacionDialog(BuildContext context) async {
  final rolService = RolService();

  try {
    // 🔹 Consulta al backend si hay invitación pendiente
    final invitacion = await rolService.verificarInvitacionPendiente();

    // Verificar si realmente hay una invitación pendiente
    if (!(invitacion["pendiente"] ?? false)) {
      return; // No hay invitación → no muestra nada
    }

    // 🔹 Verificar que el contexto siga montado antes de mostrar el diálogo
    if (!context.mounted) return;

    // 🔹 Si hay invitación, muestra el diálogo
    final resultado = await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Evita cerrar tocando fuera del diálogo
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Evita cerrar con el botón de atrás
          child: AlertDialog(
            title: const Text("Invitación a Administrador"),
            content: const Text(
              "Tienes una invitación pendiente para convertirte en administrador. "
              "Si aceptas, deberás ingresar el código de confirmación."
            ),
            actions: [
              TextButton(
                child: const Text("Cancelar"),
                onPressed: () async {
                  // Cerrar el diálogo primero y retornar false
                  Navigator.of(dialogContext).pop(false);
                  
                  try {
                    await rolService.rechazarInvitacion();
                  } catch (e) {
                    print("❌ Error al rechazar invitación: $e");
                  }
                },
              ),
              ElevatedButton(
                child: const Text("Aceptar"),
                onPressed: () {
                  // Cerrar el diálogo y retornar true
                  Navigator.of(dialogContext).pop(true);
                },
              ),
            ],
          ),
        );
      },
    );

    // 🔹 Esperar a que el diálogo se cierre completamente
    await Future.delayed(const Duration(milliseconds: 100));

    // 🔹 Verificar que el contexto siga montado después del diálogo
    if (!context.mounted) return;

    // 🔹 Manejar el resultado después de cerrar el diálogo
    if (resultado == true) {
      // Usuario aceptó la invitación
      Navigator.pushNamed(context, '/pantalla-rol');
    } else if (resultado == false) {
      // Usuario canceló la invitación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invitación rechazada"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  } catch (e) {
    print("❌ Error verificando invitación: $e");
  }
}