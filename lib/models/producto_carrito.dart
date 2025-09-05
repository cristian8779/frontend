// lib/models/producto_carrito.dart
import 'package:crud/models/atributos_producto.dart';

class ProductoCarrito {
  final String productoId;
  final String? variacionId;
  final int cantidad;
  final double precio;
  final AtributosProducto atributos;

  ProductoCarrito({
    required this.productoId,
    this.variacionId,
    required this.cantidad,
    required this.precio,
    AtributosProducto? atributos,
  }) : atributos = atributos ?? AtributosProducto();

  factory ProductoCarrito.fromJson(Map<String, dynamic> json) {
    return ProductoCarrito(
      productoId: json['productoId']?.toString() ?? '',
      variacionId: json['variacionId']?.toString(),
      cantidad: json['cantidad'] ?? 1,
      precio: (json['precio'] ?? 0.0).toDouble(),
      atributos: json['atributos'] != null 
          ? AtributosProducto.fromJson(json['atributos'])
          : AtributosProducto(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'variacionId': variacionId,
      'cantidad': cantidad,
      'precio': precio,
      'atributos': atributos.toJson(),
    };
  }

  ProductoCarrito copyWith({
    String? productoId,
    String? variacionId,
    int? cantidad,
    double? precio,
    AtributosProducto? atributos,
  }) {
    return ProductoCarrito(
      productoId: productoId ?? this.productoId,
      variacionId: variacionId ?? this.variacionId,
      cantidad: cantidad ?? this.cantidad,
      precio: precio ?? this.precio,
      atributos: atributos ?? this.atributos,
    );
  }

  // Calcular subtotal del producto
  double get subtotal => precio * cantidad;

  // Identificador único para el producto en el carrito (producto + variación)
  String get identificadorUnico => '$productoId${variacionId != null ? '_$variacionId' : ''}';

  @override
  String toString() {
    return 'ProductoCarrito{productoId: $productoId, variacionId: $variacionId, cantidad: $cantidad, precio: $precio}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductoCarrito && 
           other.productoId == productoId && 
           other.variacionId == variacionId;
  }

  @override
  int get hashCode => identificadorUnico.hashCode;
}