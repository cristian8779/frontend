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

    // 🔹 Si hay invitación, muestra el diálogo
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Invitación a Administrador"),
          content: const Text(
            "Tienes una invitación pendiente para convertirte en administrador. "
            "Si aceptas, deberás ingresar el código de confirmación."
          ),
          actions: [
            TextButton(
              child: const Text("Cancelar"),
              onPressed: () async {
                try {
                  await rolService.rechazarInvitacion(); // ⬅️ Llamada para rechazar
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Invitación rechazada"),
                      backgroundColor: Colors.red,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Error al rechazar: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              child: const Text("Aceptar"),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/pantalla-rol');
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    print("❌ Error verificando invitación: $e");
  }
}
