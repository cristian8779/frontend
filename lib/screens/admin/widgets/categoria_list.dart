import 'package:flutter/material.dart';
import '../../../services/categoria_service.dart';
import '../categoria_preview_screen.dart';
import '../create_category_screen.dart';
import '/models/categoria.dart';

class CategoriaList extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final VoidCallback onCategoriasActualizadas; // Callback para actualizar

  const CategoriaList({
    super.key,
    required this.categorias,
    required this.onCategoriasActualizadas,
  });

  // Función para obtener dimensiones responsivas
  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'containerHeight': 240.0,
        'itemWidth': 160.0,
        'itemHeight': 160.0,
        'fontSize': 16.0,
        'iconSize': 50.0,
        'padding': 16.0,
      };
    } else if (isTablet) {
      return {
        'containerHeight': 225.0,
        'itemWidth': 145.0,
        'itemHeight': 145.0,
        'fontSize': 15.0,
        'iconSize': 45.0,
        'padding': 14.0,
      };
    } else {
      return {
        'containerHeight': 210.0,
        'itemWidth': 130.0,
        'itemHeight': 130.0,
        'fontSize': 14.0,
        'iconSize': 40.0,
        'padding': 12.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _getResponsiveDimensions(context);
        
        if (categorias.isEmpty) {
          return SizedBox(
            height: dimensions['containerHeight']!,
            child: Row(
              children: [
                // Mensaje y botón alineados horizontalmente
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.only(right: dimensions['padding']!),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: dimensions['iconSize']! + 4,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No se encontraron categorías.',
                          style: TextStyle(
                            fontSize: dimensions['fontSize']! + 1,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Puedes crear nuevas desde aquí',
                          style: TextStyle(
                            fontSize: dimensions['fontSize']! - 1,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Botón de agregar
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                          onCategoriasActualizadas(); // Actualiza después de crear
                        }
                      },
                      child: Container(
                        width: dimensions['itemWidth']!,
                        height: dimensions['itemHeight']!,
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
                        child: Icon(
                          Icons.add, 
                          color: Colors.white, 
                          size: dimensions['iconSize']!,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Agregar",
                      style: TextStyle(
                        fontSize: dimensions['fontSize']!,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        return SizedBox(
          height: dimensions['containerHeight']!,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categorias.length + 1,
            itemBuilder: (context, index) {
              if (index == categorias.length) {
                return _agregarCategoriaBoton(context, dimensions);
              }

              final categoriaMap = categorias[index];
              late Categoria categoria;
              try {
                categoria = Categoria.fromJson(categoriaMap);
              } catch (e) {
                return const SizedBox();
              }

              return Padding(
                padding: EdgeInsets.only(right: dimensions['padding']!),
                child: GestureDetector(
                  onTap: () async {
                    // Navegar a CategoriaPreviewScreen
                    final resultado = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoriaPreviewScreen(
                          categoria: categoria,
                        ),
                      ),
                    );

                    // Si se retornó true, significa que hubo cambios (actualización o eliminación)
                    if (resultado == true) {
                      onCategoriasActualizadas(); // Actualiza la lista
                    }
                  },
                  child: Column(
                    children: [
                      Container(
                        width: dimensions['itemWidth']!,
                        height: dimensions['itemHeight']!,
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
                                      Icon(Icons.broken_image, size: dimensions['iconSize']!),
                                )
                              : Image.asset(
                                  'assets/imagen.png',
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: dimensions['itemWidth']!,
                        child: Text(
                          categoria.nombre,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: dimensions['fontSize']!,
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
      },
    );
  }

  Widget _agregarCategoriaBoton(BuildContext context, Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.only(right: dimensions['padding']!),
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
                onCategoriasActualizadas(); // Actualiza después de crear
              }
            },
            child: Container(
              width: dimensions['itemWidth']!,
              height: dimensions['itemHeight']!,
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
              child: Icon(
                Icons.add, 
                color: Colors.white, 
                size: dimensions['iconSize']!,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Agregar",
            style: TextStyle(
              fontSize: dimensions['fontSize']!,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}