import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Asegúrate de que los servicios estén bien importados
import '../../services/producto_usuario_service.dart';  // Cambié el import aquí para usar el servicio de usuario

class ProductoScreen extends StatefulWidget {
  final String productId;
  const ProductoScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> {
  late Future<Map<String, dynamic>> producto;
  late Future<List<Map<String, dynamic>>> variaciones;  // Variaciones del producto

  int selectedImageIndex = 0;
  bool showDescription = true;

  @override
  void initState() {
    super.initState();
    producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId); // Obtener producto sin necesidad de login
    variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId); // Obtener variaciones del producto
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: BackButton(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite_border, color: Colors.black),
            onPressed: () {
              ProductoUsuarioService().marcarComoFavorito(widget.productId); // Marcar producto como favorito
              print('❤️ Producto agregado a favoritos');
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([producto, variaciones]), // Cargar producto y variaciones
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          Map<String, dynamic> productData = snapshot.data![0];
          List<Map<String, dynamic>> variations = snapshot.data![1];

          // Depuración: Imprimir las variaciones para ver su estructura
          print("Variaciones recibidas: $variations");

          // Verifica si las variaciones están correctamente formateadas
          if (variations is! List) {
            print('❌ Las variaciones no son una lista. Verifica la respuesta de la API.');
            return Center(child: Text('Error al obtener las variaciones.'));
          }

          // Verifica el tipo de datos en cada variación
          variations.forEach((variacion) {
            print("Variación individual: $variacion");

            // Asegurarse de que la variación es un mapa
            if (variacion is! Map) {
              print("❌ Error: una variación no es un mapa.");
              return;
            }

            // Verificar si las claves necesarias existen y son del tipo esperado
            if (variacion.containsKey('tallaNumero') || variacion.containsKey('tallaLetra')) {
              print("Talla: ${variacion['tallaNumero'] ?? variacion['tallaLetra']}");
            } else {
              print("❌ No se encontró talla en la variación.");
            }

            if (variacion.containsKey('color') && variacion['color'] is Map) {
              print("Color: ${variacion['color']['nombre'] ?? 'Desconocido'}");
            } else {
              print("❌ No se encontró color en la variación.");
            }

            if (variacion.containsKey('precio')) {
              print("Precio: \$${variacion['precio'] ?? 'N/A'}");
            } else {
              print("❌ No se encontró precio en la variación.");
            }
          });

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                // Imagen principal
                SizedBox(
                  height: 250,
                  child: Image.network(productData['imagen']),
                ),

                const SizedBox(height: 12),

                // Nombre y precio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      productData['nombre'],
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "\$${productData['precio']}",
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Descripción
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      showDescription ? productData['descripcion'] : "No hay reseñas aún.",
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),

                // Mostrar variaciones (talla, color, etc.)
                const SizedBox(height: 16),
                Text(
                  "Variaciones",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Lista de variaciones
                variations.isEmpty
                    ? Text("No hay variaciones disponibles.")
                    : Column(
                        children: variations.map((variacion) {
                          // Verifica que la variación esté bien formada
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Mostrar talla
                                Text(
                                  "Talla: ${variacion['tallaNumero'] ?? variacion['tallaLetra'] ?? 'Desconocida'}",
                                  style: TextStyle(fontSize: 16),
                                ),
                                // Mostrar color
                                Text(
                                  "Color: ${variacion['color'] != null ? variacion['color']['nombre'] ?? 'Desconocido' : 'Desconocido'}",
                                  style: TextStyle(fontSize: 16),
                                ),
                                // Precio de la variación
                                Text(
                                  "\$${variacion['precio'] ?? 'N/A'}",
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                // Botón Comprar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text("Comprar ahora", style: TextStyle(fontSize: 18)),
                    onPressed: () {
                      print('🛒 Iniciando el proceso de compra');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
