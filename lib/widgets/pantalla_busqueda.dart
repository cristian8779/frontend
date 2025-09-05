// lib/widgets/pantalla_busqueda.dart
import 'package:flutter/material.dart';
import '../../services/producto_service.dart';
import '../../widgets/pantalla_filtros.dart';
import 'buscador.dart'; // Importa correctamente el widget BuscadorProductos

class PantallaBusqueda extends StatefulWidget {
  final Map<String, dynamic> filtrosDisponibles;

  const PantallaBusqueda({Key? key, required this.filtrosDisponibles}) : super(key: key);

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  final ProductoService _productoService = ProductoService();
  final TextEditingController _controller = TextEditingController();

  List<Map<String, dynamic>> _resultados = [];
  bool _cargando = false;
  String _busqueda = "";
  Map<String, dynamic> _filtrosActuales = {};

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _buscarProductos(_controller.text);
    });
    _filtrosActuales = widget.filtrosDisponibles;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _buscarProductos(String query) async {
    setState(() {
      _cargando = true;
      _busqueda = query;
    });

    try {
      final productos = await _productoService.obtenerProductos();

      // Convertimos correctamente cada producto a Map<String, dynamic>
      final filtrados = productos
          .map<Map<String, dynamic>>((p) => Map<String, dynamic>.from(p))
          .where((p) =>
              query.isEmpty ? false : (p['nombre'] ?? "").toString().toLowerCase().contains(query.toLowerCase()))
          .toList();

      // Actualizamos filtros internamente, pero no abrimos ningún panel
      _actualizarFiltros(filtrados);

      setState(() {
        _resultados = filtrados;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error al buscar productos: $e")),
      );
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _actualizarFiltros(List<Map<String, dynamic>> productosFiltrados) {
    final subcategorias = <String>{};
    final tallasLetra = <String>{};
    final colores = <Map<String, dynamic>>[];

    for (var p in productosFiltrados) {
      if (p['subcategoria'] != null) subcategorias.add(p['subcategoria']);
      if (p['variaciones'] != null && p['variaciones'] is List) {
        for (var v in p['variaciones']) {
          if (v['tallaLetra'] != null) tallasLetra.add(v['tallaLetra']);
          if (v['color'] != null) {
            colores.add({
              'nombre': v['color']['nombre'] ?? 'Desconocido',
              'hex': v['color']['hex'] ?? '#FFFFFF',
            });
          }
        }
      }
    }

    setState(() {
      _filtrosActuales = {
        'subcategorias': subcategorias.toList(),
        'tallasLetra': tallasLetra.toList(),
        'colores': colores,
      };
    });
  }

  void _mostrarFiltros() {
    if (_filtrosActuales.isEmpty) return; // No abrir si no hay filtros

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => FiltrosPanel(filtros: _filtrosActuales),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneResultados = _resultados.isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: true,
        title: BuscadorProductos(
          busqueda: _busqueda,
          controller: _controller,
          onBusquedaChanged: (value) => _buscarProductos(value),
          onTap: () {},
          onClear: () {
            _controller.clear();
            _buscarProductos('');
          },
        ),
      ),
      body: Column(
        children: [
          if (tieneResultados)
            _barraFiltros(), // Se muestra solo si hay resultados
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : tieneResultados
                    ? ListView.builder(
                        itemCount: _resultados.length,
                        itemBuilder: (_, i) {
                          final producto = _resultados[i];
                          return ListTile(
                            leading: producto['imagen'] != null
                                ? Image.network(
                                    producto['imagen'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  )
                                : const Icon(Icons.shopping_bag_outlined),
                            title: Text(producto['nombre'] ?? "Sin nombre"),
                            subtitle: Text(
                              "\$${producto['precio'] ?? '--'}",
                              style: const TextStyle(color: Colors.green),
                            ),
                          );
                        },
                      )
                    : const Center(child: Text("Empieza a buscar...")),
          ),
        ],
      ),
    );
  }

  Widget _barraFiltros() {
    return Container(
      height: 48,
      color: Colors.grey.shade200,
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(Icons.filter_list, color: Colors.black54),
          const SizedBox(width: 8),
          const Text("Filtros", style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            onPressed: _mostrarFiltros,
          ),
        ],
      ),
    );
  }
}
