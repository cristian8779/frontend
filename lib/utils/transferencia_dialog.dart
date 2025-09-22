import 'package:flutter/material.dart';
import '../services/SuperAdminService.dart';

Future<void> mostrarTransferenciaSuperAdminDialog(BuildContext context) async {
  final superAdminService = SuperAdminService();

  try {
    // 🔹 Consulta al backend si hay transferencia pendiente
    final transferencia = await superAdminService.verificarTransferenciaPendiente();

    if (!(transferencia["pendiente"] ?? false)) {
      return; // No hay transferencia → no muestra nada
    }

    final solicitante = transferencia['solicitante'] ?? 'otro usuario';
    final expiracion = transferencia['expiracion'] != null
        ? DateTime.parse(transferencia['expiracion']).toLocal()
        : null;

    // 🔹 Mostrar diálogo con explicación detallada
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Transferencia de SuperAdmin pendiente"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "El usuario $solicitante ha iniciado una transferencia del rol de SuperAdmin a tu cuenta.",
              ),
              const SizedBox(height: 10),
              const Text(
                "⚠️ Antes de aceptar, asegúrate de que conoces y confías en esta acción. "
                "Ser SuperAdmin te dará control completo sobre la gestión de administradores y permisos."
              ),
              if (expiracion != null) ...[
                const SizedBox(height: 10),
                Text(
                  "⏰ Esta invitación expira el ${expiracion.day}/${expiracion.month}/${expiracion.year} a las ${expiracion.hour}:${expiracion.minute.toString().padLeft(2, '0')}.",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Rechazar", style: TextStyle(color: Colors.red)),
              onPressed: () async {
                try {
                  await superAdminService.rechazarTransferencia();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Has rechazado la transferencia de SuperAdmin"),
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
                Navigator.pushNamed(context, '/confirmar-codigo-rol'); // Ajusta la ruta
              },
            ),
          ],
        );
      },
    );
  } catch (e) {
    print("❌ Error verificando transferencia de SuperAdmin: $e");
  }
}
