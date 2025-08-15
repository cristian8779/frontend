import 'package:flutter/material.dart';
import '../../services/anuncio_service.dart';

class SelectorVisualScreen extends StatefulWidget {
  final bool esProducto;

  const SelectorVisualScreen({super.key, required this.esProducto});

  @override
  State<SelectorVisualScreen> createState() => _SelectorVisualScreenState();
}

class _SelectorVisualScreenState extends State<SelectorVisualScreen> {
  final AnuncioService _service = AnuncioService();
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _loading = true;
  String _busqueda = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);

    final data = widget.esProducto
        ? await _service.obtenerProductos()
        : await _service.obtenerCategorias();

    setState(() {
      _items = data;
      _filteredItems = data;
      _loading = false;
    });
  }

  void _filtrar(String query) {
    setState(() {
      _busqueda = query;
      _filteredItems = _items
          .where((item) =>
              (item['nombre'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.esProducto ? 'producto' : 'categoría';

    return Scaffold(
      appBar: AppBar(
        title: Text('Seleccionar $tipo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(
                  child: Text(
                    'No hay elementos disponibles.',
                    style: TextStyle(fontSize: 16),
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: TextField(
                        onChanged: _filtrar,
                        decoration: InputDecoration(
                          hintText: 'Buscar $tipo...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: _filteredItems.isEmpty
                          ? const Center(
                              child: Text(
                                'No se encontraron resultados.',
                                style: TextStyle(fontSize: 16),
                              ),
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredItems.length,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                              ),
                              itemBuilder: (_, index) {
                                final item = _filteredItems[index];
                                final nombre = item['nombre'] ?? 'Sin nombre';
                                final imagen = item['imagen'] ?? '';

                                return GestureDetector(
                                  onTap: () => Navigator.pop(context, item),
                                  child: Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: imagen.isNotEmpty
                                                ? Image.network(
                                                    imagen,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Center(
                                                      child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                                    ),
                                                  )
                                                : const Center(
                                                    child: Icon(
                                                      Icons.image_not_supported,
                                                      size: 50,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            nombre,
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
