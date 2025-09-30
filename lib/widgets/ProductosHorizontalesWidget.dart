import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/producto_provider.dart';
import '../screens/producto/producto_screen.dart';

class ProductosHorizontalesWidget extends StatefulWidget {
  final String? categoria;

  const ProductosHorizontalesWidget({super.key, this.categoria});

  @override
  State<ProductosHorizontalesWidget> createState() =>
      _ProductosHorizontalesWidgetState();
}

class _ProductosHorizontalesWidgetState
    extends State<ProductosHorizontalesWidget> {
  
  @override
  void initState() {
    super.initState();
    // Cargar productos al inicializar solo si no están cargados
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductosProvider>().cargarProductos();
    });
  }

  // Widget para crear el shimmer effect
  Widget _buildShimmerCard(Map<String, double> dimensiones) {
    return Container(
      width: dimensiones['cardWidth']!,
      margin: EdgeInsets.symmetric(horizontal: dimensiones['spacing']! / 2),
      child: Card(
        elevation: 3,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20), // Más redondeado
        ),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen shimmer
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20), // Más redondeado
                    ),
                  ),
                ),
              ),
              // Info shimmer
              Padding(
                padding: EdgeInsets.all(dimensiones['spacing']!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Shimmer precio
                    Container(
                      width: dimensiones['cardWidth']! * 0.6,
                      height: dimensiones['fontSize']! + 2,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6), // Más redondeado
                      ),
                    ),
                    SizedBox(height: dimensiones['spacing']! / 2),
                    // Shimmer nombre línea 1
                    Container(
                      width: dimensiones['cardWidth']! * 0.9,
                      height: dimensiones['titleSize']! + 1,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6), // Más redondeado
                      ),
                    ),
                    SizedBox(height: 4),
                    // Shimmer nombre línea 2
                    Container(
                      width: dimensiones['cardWidth']! * 0.7,
                      height: dimensiones['titleSize']! + 1,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6), // Más redondeado
                      ),
                    ),
                    SizedBox(height: dimensiones['spacing']! / 2),
                    // Shimmer envío
                    Container(
                      width: dimensiones['cardWidth']! * 0.5,
                      height: dimensiones['titleSize']!,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6), // Más redondeado
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para calcular dimensiones responsive
  Map<String, double> _getDimensiones(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth > 1200) {
      // Desktop grande
      return {
        'cardWidth': 200.0,
        'height': 280.0,
        'fontSize': 18.0,
        'titleSize': 14.0,
        'spacing': 12.0,
      };
    } else if (screenWidth > 800) {
      // Tablet/Desktop pequeño
      return {
        'cardWidth': 170.0,
        'height': 260.0,
        'fontSize': 16.0,
        'titleSize': 13.0,
        'spacing': 10.0,
      };
    } else if (screenWidth > 600) {
      // Tablet vertical
      return {
        'cardWidth': 150.0,
        'height': 240.0,
        'fontSize': 15.0,
        'titleSize': 12.0,
        'spacing': 8.0,
      };
    } else {
      // Móvil
      return {
        'cardWidth': 130.0,
        'height': 220.0,
        'fontSize': 14.0,
        'titleSize': 11.0,
        'spacing': 6.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final dimensiones = _getDimensiones(context);
    
    return SizedBox(
      height: dimensiones['height']!,
      child: Consumer<ProductosProvider>(
        builder: (context, productosProvider, child) {
          // Mostrar shimmer solo en la carga inicial (cuando no hay productos)
          if (productosProvider.isLoading && productosProvider.productos.isEmpty) {
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: dimensiones['spacing']! / 2),
              itemCount: 6, // Mostrar 6 shimmer cards
              itemBuilder: (context, index) => _buildShimmerCard(dimensiones),
            );
          }

          if (productosProvider.error != null && productosProvider.productos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error al cargar productos',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => productosProvider.cargarProductos(forceRefresh: true),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Botón más redondeado
                      ),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          List<Map<String, dynamic>> productos = widget.categoria != null
              ? productosProvider.filtrarPorCategoria(widget.categoria)
              : productosProvider.productos;

          if (productos.isEmpty) {
            return const Center(
              child: Text(
                "No hay productos disponibles",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Obtener productos aleatorios
          final productosLimitados = productosProvider.obtenerProductosAleatorios(6);
          final formatoPesos = NumberFormat("#,###", "es_CO");

          return Stack(
            children: [
              ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: dimensiones['spacing']! / 2),
                itemCount: productosLimitados.length,
                itemBuilder: (context, index) {
                  final producto = productosLimitados[index];
                  final precio = producto['precio'] ?? 0;
                  final precioFormateado = "\$${formatoPesos.format(precio)}";

                  return Container(
                    width: dimensiones['cardWidth']!,
                    margin: EdgeInsets.symmetric(horizontal: dimensiones['spacing']! / 2),
                    child: Card(
                      elevation: 3,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20), // Más redondeado
                      ),
                      child: InkWell(
                        onTap: () {
                          // Navegar al detalle del producto
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductoScreen(
                                  productId: producto['_id'],

                              ),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(20), // Coincide con el Card
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Imagen con loading indicator
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(20), // Más redondeado
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      color: Colors.grey[100],
                                      child: Image.network(
                                        producto['imagen'] ?? "https://via.placeholder.com/200",
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[200],
                                            child: Icon(
                                              Icons.image_not_supported,
                                              size: dimensiones['fontSize']! * 2,
                                              color: Colors.grey,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Badge de descuento si existe
                                    if (producto['descuento'] != null && producto['descuento'] > 0)
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(12), // Badge más redondeado
                                          ),
                                          child: Text(
                                            '-${producto['descuento']}%',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // Información del producto
                            Padding(
                              padding: EdgeInsets.all(dimensiones['spacing']!),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Precio
                                  Text(
                                    precioFormateado,
                                    style: TextStyle(
                                      fontSize: dimensiones['fontSize']!,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  SizedBox(height: dimensiones['spacing']! / 2),
                                  // Nombre del producto
                                  Text(
                                    producto['nombre'] ?? 'Producto',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: dimensiones['titleSize']!,
                                      color: Colors.black87,
                                      height: 1.2,
                                    ),
                                  ),
                                  SizedBox(height: dimensiones['spacing']! / 2),
                                  // Envío gratis
                                  if (producto['envioGratis'] == true)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10), // Contenedor más redondeado
                                        border: Border.all(
                                          color: Colors.green.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.local_shipping,
                                            size: dimensiones['titleSize']! - 1,
                                            color: Colors.green,
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              "Envío gratis",
                                              style: TextStyle(
                                                fontSize: dimensiones['titleSize']! - 1,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              // Indicador de carga cuando se actualiza en background
              if (productosProvider.isLoading && productosProvider.productos.isNotEmpty)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20), // Indicador más redondeado
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        backgroundColor: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}