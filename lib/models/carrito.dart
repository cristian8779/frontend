// lib/models/carrito.dart
import 'package:crud/models/producto_carrito.dart';

class Carrito {
  final String? id;
  final String usuarioId;
  final List<ProductoCarrito> productos;
  final DateTime? fechaCreacion;
  final DateTime? fechaActualizacion;

  Carrito({
    this.id,
    required this.usuarioId,
    required this.productos,
    this.fechaCreacion,
    this.fechaActualizacion,
  });

  factory Carrito.fromJson(Map<String, dynamic> json) {
    final productosList = json['productos'] as List<dynamic>? ?? [];
    final productos = productosList.map((item) => ProductoCarrito.fromJson(item)).toList();
    
    return Carrito(
      id: json['_id']?.toString() ?? json['id']?.toString(),
      usuarioId: json['usuarioId']?.toString() ?? '',
      productos: productos,
      fechaCreacion: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      fechaActualizacion: json['updatedAt'] != null 
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'productos': productos.map((p) => p.toJson()).toList(),
      'createdAt': fechaCreacion?.toIso8601String(),
      'updatedAt': fechaActualizacion?.toIso8601String(),
    };
  }

  // Carrito vacío
  static Carrito empty(String usuarioId) {
    return Carrito(
      usuarioId: usuarioId,
      productos: [],
    );
  }

  // Verificaciones básicas
  bool get isEmpty => productos.isEmpty;
  bool get isNotEmpty => productos.isNotEmpty;

  // Cálculos
  int get totalItems => productos.fold(0, (sum, p) => sum + p.cantidad);
  
  double get total => productos.fold(0.0, (sum, p) => sum + p.subtotal);

  // Buscar producto específico
  ProductoCarrito? buscarProducto(String productoId, [String? variacionId]) {
    try {
      return productos.firstWhere(
        (p) => p.productoId == productoId && p.variacionId == variacionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Verificar si contiene un producto específico
  bool contieneProducto(String productoId, [String? variacionId]) {
    return productos.any(
      (p) => p.productoId == productoId && p.variacionId == variacionId,
    );
  }

  // Obtener cantidad de un producto específico
  int cantidadProducto(String productoId, [String? variacionId]) {
    final producto = buscarProducto(productoId, variacionId);
    return producto?.cantidad ?? 0;
  }

  @override
  String toString() {
    return 'Carrito{id: $id, usuarioId: $usuarioId, productos: ${productos.length}, total: \$${total.toStringAsFixed(2)}}';
  }
}