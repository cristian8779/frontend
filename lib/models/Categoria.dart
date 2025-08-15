import 'producto.dart';

class Categoria {
  final String id;
  final String nombre;
  final String descripcion;
  final String? imagen;
  final List<Producto> productos;

  Categoria({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.imagen,
    required this.productos,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['_id'] ?? json['id'] ?? 'ID no disponible',
      nombre: json['nombre'] ?? 'Sin nombre',
      descripcion: json['descripcion'] ?? 'Sin descripción',
      imagen: json['imagen'],
      productos: (json['productos'] as List<dynamic>?)
              ?.map((prodJson) => Producto.fromJson(prodJson))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'imagen': imagen,
      'productos': productos.map((p) => p.toJson()).toList(),
    };
  }
}
