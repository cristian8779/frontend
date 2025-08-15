import 'package:flutter/material.dart';

class GestionVentasScreen extends StatelessWidget {
  const GestionVentasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestión de Ventas')),
      body: const Center(
        child: Text('Pantalla de gestión de ventas'),
      ),
    );
  }
}
