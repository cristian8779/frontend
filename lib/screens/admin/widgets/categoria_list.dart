import 'package:flutter/material.dart';
import '../../../services/categoria_service.dart';
import '../categoria_preview_screen.dart';
import '../create_category_screen.dart';
import '/models/categoria.dart';

class CategoriaList extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final VoidCallback onCategoriasActualizadas; // 👈 Callback para actualizar

  const CategoriaList({
    super.key,
    required this.categorias,
    required this.onCategoriasActualizadas,
  });

  @override
  Widget build(BuildContext context) {
    if (categorias.isEmpty) {
      return SizedBox(
        height: 210,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.category_outlined,
                size: 48,
                color: Colors.blueGrey,
              ),
              const SizedBox(height: 8),
              const Text(
                'No se encontraron categorías.\n¡Puedes crear nuevas desde aquí!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              _agregarCategoriaBoton(context),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categorias.length + 1,
        itemBuilder: (context, index) {
          if (index == categorias.length) {
            return _agregarCategoriaBoton(context);
          }

          final categoriaMap = categorias[index];
          late Categoria categoria;
          try {
            categoria = Categoria.fromJson(categoriaMap);
          } catch (e) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () async {
                final actualizado = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoriaPreviewScreen(
                      categoria: categoria,
                    ),
                  ),
                );

                if (actualizado == true) {
                  onCategoriasActualizadas(); // 👈 Actualiza después de editar/ver
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey[200],
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: categoria.imagen != null && categoria.imagen!.isNotEmpty
                          ? Image.network(
                              categoria.imagen!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 40),
                            )
                          : Image.asset(
                              'assets/imagen.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 130,
                    child: Text(
                      categoria.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _agregarCategoriaBoton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          GestureDetector(
            onTap: () async {
              final creado = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateCategoryScreen(),
                ),
              );

              if (creado == true) {
                onCategoriasActualizadas(); // 👈 Actualiza después de crear
              }
            },
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: Colors.red[400],
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Agregar",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
