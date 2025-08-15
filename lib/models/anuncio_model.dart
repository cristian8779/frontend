class AnuncioModel {
  final String id;
  final String imagen;
  final String publicId;
  final String deeplink;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String? productoId;
  final String? categoriaId;
  final String usuarioId;

  AnuncioModel({
    required this.id,
    required this.imagen,
    required this.publicId,
    required this.deeplink,
    required this.fechaInicio,
    required this.fechaFin,
    this.productoId,
    this.categoriaId,
    required this.usuarioId,
  });

  factory AnuncioModel.fromJson(Map<String, dynamic> json) {
    return AnuncioModel(
      id: json['_id'],
      imagen: json['imagen'],
      publicId: json['publicId'],
      deeplink: json['deeplink'],
      fechaInicio: DateTime.parse(json['fechaInicio']),
      fechaFin: DateTime.parse(json['fechaFin']),
      productoId: json['productoId'],
      categoriaId: json['categoriaId'],
      usuarioId: json['usuarioId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'imagen': imagen,
      'publicId': publicId,
      'deeplink': deeplink,
      'fechaInicio': fechaInicio.toIso8601String(),
      'fechaFin': fechaFin.toIso8601String(),
      'productoId': productoId,
      'categoriaId': categoriaId,
      'usuarioId': usuarioId,
    };
  }
}
