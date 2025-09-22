import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/ProductosHorizontalesWidget.dart';
import '../../widgets/ListaProductosWidget.dart';
import '../../providers/producto_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFB),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          const SizedBox(height: 16),

          // 🔹 Sección "Te puede interesar" - Mostrar según estado del provider
          Consumer<ProductosProvider>(
            builder: (context, productosProvider, child) {
              // 🔹 Si hay productos, mostrarlos siempre
              if (productosProvider.productos.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Te puede interesar",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ProductosHorizontalesWidget(),
                  ],
                );
              }

              // 🔹 Si está cargando y no hay productos, mostrar shimmer
              if (productosProvider.isLoading) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Te puede interesar",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          width: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ],
                );
              }

              // 🔹 Si hay error y no hay productos
              if (productosProvider.error != null &&
                  productosProvider.productos.isEmpty) {
                return Center(
                  child: Text(
                    "❌ Error al cargar productos",
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                );
              }

              // 🔹 Default: no mostrar nada
              return const SizedBox.shrink();
            },
          ),

          const SizedBox(height: 16),

          // 🔹 Lista de productos con scroll infinito (sin título)
          const ListaProductosWidget(),
        ],
      ),
    );
  }
}
