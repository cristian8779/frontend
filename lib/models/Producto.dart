import 'variacion.dart';

class Producto {
  final String id;
  final String nombre;
  final String descripcion;
  final String imagenUrl;
  final double precio;
  final int stock;
  final String categoriaId;
  final String subcategoriaId;
  final bool disponible;
  final bool estado;
  final List<Variacion> variaciones;

  Producto({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.imagenUrl,
    required this.precio,
    required this.stock,
    required this.categoriaId,
    required this.subcategoriaId,
    required this.disponible,
    required this.estado,
    required this.variaciones,
  });

  factory Producto.fromJson(Map<String, dynamic> json) {
    String categoriaId = '';
    String subcategoriaId = '';

    if (json['categoria'] is String) {
      categoriaId = json['categoria'];
    } else if (json['categoria'] is Map<String, dynamic>) {
      categoriaId = json['categoria']['_id'] ?? '';
    }

    if (json['subcategoria'] is String) {
      subcategoriaId = json['subcategoria'];
    } else if (json['subcategoria'] is Map<String, dynamic>) {
      subcategoriaId = json['subcategoria']['_id'] ?? '';
    }

    List<Variacion> variaciones = [];
    if (json['variaciones'] != null && json['variaciones'] is List) {
      variaciones = (json['variaciones'] as List)
          .map((v) => Variacion.fromJson(v))
          .toList();
    }

    return Producto(
      id: json['_id'] ?? json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      descripcion: json['descripcion'] ?? '',
      imagenUrl: json['imagen'] ?? '',
      precio: (json['precio'] ?? 0).toDouble(),
      stock: json['stock'] ?? 0,
      categoriaId: categoriaId,
      subcategoriaId: subcategoriaId,
      disponible: json['disponible'] == true || json['disponible'] == 'true',
      estado: json['estado'] == true || json['estado'] == 'true',
      variaciones: variaciones,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen': imagenUrl,
      'precio': precio,
      'stock': stock,
      'categoria': categoriaId,
      'subcategoria': subcategoriaId,
      'disponible': disponible,
      'estado': estado,
      'variaciones': variaciones.map((v) => v.toJson()).toList(),
    };
  }
}
