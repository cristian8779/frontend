import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/producto_service.dart';
import '../producto/producto_screen.dart'; // 👈 Import de detalle

class ProductosPorCategoriaScreen extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;

  const ProductosPorCategoriaScreen({
    Key? key,
    required this.categoriaId,
    required this.categoriaNombre,
  }) : super(key: key);

  @override
  State<ProductosPorCategoriaScreen> createState() =>
      _ProductosPorCategoriaScreenState();
}

class _ProductosPorCategoriaScreenState
    extends State<ProductosPorCategoriaScreen> {
  final ProductoService _productoService = ProductoService();
  List<Map<String, dynamic>> productos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final allProducts = await _productoService.obtenerProductos();
      final filtered = allProducts
          .where((p) => p['categoria']?.toString() == widget.categoriaId)
          .toList();

      setState(() {
        productos = filtered;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refrescarLista() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    await _cargarProductos();
  }

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  String _formatPrice(double price) => _currencyFormatter.format(price);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8), // Blanco pastel
      appBar: AppBar(
        title: Text(
          widget.categoriaNombre,
          style: const TextStyle(color: Colors.black87),
        ),
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarLista,
        child: isLoading
            ? _buildShimmerGrid()
            : error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.redAccent),
                        const SizedBox(height: 12),
                        Text("Error: $error"),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refrescarLista,
                          child: const Text("Reintentar"),
                        ),
                      ],
                    ),
                  )
                : productos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            const Text(
                              "No hay productos disponibles",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: size.width * 0.5,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.63,
                        ),
                        itemCount: productos.length,
                        itemBuilder: (context, index) {
                          final producto = productos[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(20), // 🔥 Bordes redondeados para el tap
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductoScreen(
                                    productId: producto['_id'],
                                    
                                  ),
                                ),
                              );
                            },
                            child: _ProductoCard(
                              id: producto['_id'] ?? '',
                              nombre: producto['nombre'] ?? 'Sin nombre',
                              imagenUrl: producto['imagen'] ??
                                  'https://via.placeholder.com/400x280/f5f5f5/cccccc?text=Sin+Imagen',
                              precio: producto['precio'] is double
                                  ? producto['precio']
                                  : double.tryParse(
                                          producto['precio']?.toString() ??
                                              '0') ??
                                      0,
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.63,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20), // 🔥 Bordes redondeados en shimmer
            ),
          ),
        );
      },
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String imagenUrl;
  final double precio;

  const _ProductoCard({
    Key? key,
    required this.id,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final NumberFormat currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    String formatPrice(double price) => currencyFormatter.format(price);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // 🔥 Bordes más redondeados (era 8)
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12, // 🔥 Sombra más suave
            offset: const Offset(0, 4), // 🔥 Sombra más pronunciada
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.all(12),
              width: double.infinity,
              child: ClipRRect( // 🔥 Para que la imagen respete los bordes redondeados
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  imagenUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2));
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_not_supported_outlined,
                            size: 40, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'Sin imagen',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Información con precio destacado
          Padding(
            padding: const EdgeInsets.all(12), // 🔥 Más padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 PRECIO MÁS PROMINENTE
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50, // 🔥 Fondo verde claro
                    borderRadius: BorderRadius.circular(12), // 🔥 Bordes redondeados
                    border: Border.all(
                      color: Colors.green.shade200, // 🔥 Borde verde
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.attach_money, // 🔥 Icono de dinero
                        color: Colors.green.shade700,
                        size: 16,
                      ),
                      Text(
                        NumberFormat('#,###', 'es_CO').format(precio), // 🔥 Solo el número sin símbolo
                        style: TextStyle(
                          color: Colors.green.shade700, // 🔥 Color verde
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // 🔥 Texto en negrita
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8), // 🔥 Más espacio
                Text(
                  nombre,
                  maxLines: 2, // 🔥 Permitir 2 líneas para el nombre
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}