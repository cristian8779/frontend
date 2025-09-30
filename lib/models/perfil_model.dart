class Perfil {
  final String id;
  final String nombre;
  final Direccion direccion; // 👈 ahora es objeto
  final String telefono;
  final String imagenPerfil;
  final String cloudinaryId;
  final Credenciales credenciales;
  final DateTime createdAt;
  final DateTime updatedAt;

  Perfil({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.telefono,
    required this.imagenPerfil,
    required this.cloudinaryId,
    required this.credenciales,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['_id'] ?? '',
      nombre: json['nombre'] ?? '',
      direccion: Direccion.fromJson(json['direccion'] ?? {}), // 👈 se parsea como objeto
      telefono: json['telefono'] ?? '',
      imagenPerfil: json['imagenPerfil'] ?? '',
      cloudinaryId: json['cloudinaryId'] ?? '',
      credenciales: Credenciales.fromJson(json['credenciales']),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "nombre": nombre,
      "direccion": direccion.toJson(), // 👈 exporta como objeto JSON
      "telefono": telefono,
      "imagenPerfil": imagenPerfil,
      "cloudinaryId": cloudinaryId,
      "credenciales": credenciales.toJson(),
      "createdAt": createdAt.toIso8601String(),
      "updatedAt": updatedAt.toIso8601String(),
    };
  }
}

class Direccion {
  final String departamento;
  final String ciudad;
  final String barrio;
  final String calle;

  Direccion({
    required this.departamento,
    required this.ciudad,
    required this.barrio,
    required this.calle,
  });

  factory Direccion.fromJson(Map<String, dynamic> json) {
    return Direccion(
      departamento: json['departamento'] ?? '',
      ciudad: json['ciudad'] ?? '',
      barrio: json['barrio'] ?? '',
      calle: json['calle'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "departamento": departamento,
      "ciudad": ciudad,
      "barrio": barrio,
      "calle": calle,
    };
  }
}

class Credenciales {
  final String id;
  final String email;
  final String rol;

  Credenciales({
    required this.id,
    required this.email,
    required this.rol,
  });

  factory Credenciales.fromJson(Map<String, dynamic> json) {
    return Credenciales(
      id: json['_id'] ?? '',
      email: json['email'] ?? '',
      rol: json['rol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "email": email,
      "rol": rol,
    };
  }
}
