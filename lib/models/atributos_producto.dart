class AtributosProducto {
  final String? talla;
  final String? colorHex;
  final String? colorNombre;

  AtributosProducto({
    this.talla,
    this.colorHex,
    this.colorNombre,
  });

  factory AtributosProducto.fromJson(Map<String, dynamic> json) {
    return AtributosProducto(
      talla: json['talla'],
      colorHex: json['colorHex'],
      colorNombre: json['colorNombre'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'talla': talla,
      'colorHex': colorHex,
      'colorNombre': colorNombre,
    };
  }
}
