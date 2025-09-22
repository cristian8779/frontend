import 'package:flutter/material.dart';
import '../../services/SuperAdminService.dart';
import 'package:another_flushbar/flushbar.dart';

class ConfirmarCodigoRolScreen extends StatefulWidget {
  const ConfirmarCodigoRolScreen({super.key});

  @override
  State<ConfirmarCodigoRolScreen> createState() =>
      _ConfirmarTransferenciaScreenState();
}

class _ConfirmarTransferenciaScreenState
    extends State<ConfirmarCodigoRolScreen> {
  final TextEditingController _codigoController = TextEditingController();
  final Color primaryColor = const Color(0xFFBE0C0C);
  bool _isLoading = false;

  final SuperAdminService _service = SuperAdminService();

  void _confirmarTransferencia() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _mostrarFlushbar("❌ Ingresa el código de transferencia");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final respuesta = await _service.confirmarTransferencia(codigo);

      if (respuesta['exito'] == true) {
        // 🔹 Redirigir a la pantalla de BienvenidaAdminScreen
        Navigator.pushReplacementNamed(context, '/bienvenida-admin');
        _mostrarFlushbar("✅ Transferencia confirmada");
      } else {
        _mostrarFlushbar(
            "❌ Código inválido o transferencia expirada: ${respuesta['mensaje']}");
      }
    } catch (e) {
      _mostrarFlushbar("❌ Error al confirmar transferencia: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarFlushbar(String mensaje) {
    Flushbar(
      message: mensaje,
      icon: const Icon(Icons.info, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: primaryColor,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  @override
  void dispose() {
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirmar Transferencia"),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Text(
                "Introduce el código de transferencia que el SuperAdmin te dio",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codigoController,
                decoration: const InputDecoration(
                  labelText: "Código de transferencia",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _confirmarTransferencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text("Confirmar"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
