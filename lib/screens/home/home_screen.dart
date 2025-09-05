import 'package:flutter/material.dart';
import '../../widgets/CategoriasWidget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          CategoriasWidget(
            onVerMas: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('👉 Ver más categorías')),
              );
            },
            onCategoriaSeleccionada: (categoriaId) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('✅ Categoría: $categoriaId')),
              );
            },
          ),
        ],
      ),
    );
  }
}
