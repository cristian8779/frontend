// lib/models/resumen_carrito.dart
import 'package:crud/models/producto_carrito.dart';
import 'package:crud/models/atributos_producto.dart';

class ResumenCarrito {
  final List<ProductoCarrito> productos;
  final double total;
  final String? mensaje;

  ResumenCarrito({
    required this.productos,
    required this.total,
    this.mensaje,
  });

  factory ResumenCarrito.fromJson(Map<String, dynamic> json) {
    final productosList = json['productos'] as List<dynamic>? ?? [];
    final productos = productosList.map((item) {
      // El resumen viene con estructura ligeramente diferente
      return ProductoCarrito(
        productoId: item['productoId']?.toString() ?? '',
        variacionId: item['variacionId']?.toString(),
        cantidad: item['cantidad'] ?? 1,
        precio: (item['precio'] ?? 0.0).toDouble(),
        atributos: item['atributos'] != null 
            ? AtributosProducto.fromJson(item['atributos'])
            : AtributosProducto(),
      );
    }).toList();

    return ResumenCarrito(
      productos: productos,
      total: (json['total'] ?? 0.0).toDouble(),
      mensaje: json['mensaje']?.toString(),
    );
  }

  bool get isEmpty => productos.isEmpty;
  int get totalItems => productos.fold(0, (sum, p) => sum + p.cantidad);
}