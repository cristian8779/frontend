class Usuario {
  final String rol;
  final String nombre;
  final String email;
  final String? foto;

  Usuario({
    required this.rol,
    required this.nombre,
    required this.email,
    this.foto,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      rol: json['rol'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      foto: json['foto'],
    );
  }
}
