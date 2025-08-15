import 'dart:io';

class Variacion {
  String? id; // ID MongoDB
  String productoId; // Relación con el producto
  String? tallaLetra; // Ej: "M", "L"
  String? tallaNumero; // Ej: "38", "40"
  String? colorHex; // Ej: "#FF0000"
  String? colorNombre; // Ej: "Rojo"
  double precio;
  int stock;
  List<ImagenVariacion> imagenes;

  Variacion({
    this.id,
    required this.productoId,
    this.tallaLetra,
    this.tallaNumero,
    this.colorHex,
    this.colorNombre,
    this.precio = 0.0,
    this.stock = 0,
    List<ImagenVariacion>? imagenes,
  }) : imagenes = imagenes ?? [];

  factory Variacion.fromJson(Map<String, dynamic> json) {
    return Variacion(
      id: json['_id'] as String?,
      productoId: json['productoId'] as String? ?? '',
      tallaLetra: json['tallaLetra'] as String?,
      tallaNumero: json['tallaNumero'] as String?,
      colorHex: json['color'] != null && json['color'] is Map
          ? json['color']['hex'] as String?
          : null,
      colorNombre: json['color'] != null && json['color'] is Map
          ? json['color']['nombre'] as String?
          : null,
      precio: (json['precio'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 0,
      imagenes: (json['imagenes'] as List<dynamic>?)
              ?.map((e) => ImagenVariacion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null && !id!.contains('-')) '_id': id,
      'productoId': productoId,
      'tallaLetra': tallaLetra,
      'tallaNumero': tallaNumero,
      'color': {
        'hex': colorHex,
        'nombre': colorNombre,
      },
      'precio': precio,
      'stock': stock,
      'imagenes': imagenes.map((img) => img.toJson()).toList(),
    };
  }
}

class ImagenVariacion {
  String? url;
  String? publicId;
  bool isLocal;
  File? localFile;

  ImagenVariacion({
    this.url,
    this.publicId,
    this.isLocal = false,
    this.localFile,
  });

  factory ImagenVariacion.fromJson(Map<String, dynamic> json) {
    return ImagenVariacion(
      url: json['url'] as String?,
      publicId: json['public_id'] as String?,
      isLocal: false,
      localFile: null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'public_id': publicId,
    };
  }
}
