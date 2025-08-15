// screens/categoria/categoria_screen.dart
import 'package:flutter/material.dart';

class CategoriaScreen extends StatelessWidget {
  final String categoriaId;
  const CategoriaScreen({required this.categoriaId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Mostrar productos filtrados por categoríaId
    return Scaffold(
      appBar: AppBar(title: Text('Categoría $categoriaId')),
      body: Center(
        child: Text('Productos de la categoría con ID: $categoriaId'),
      ),
    );
  }
}
