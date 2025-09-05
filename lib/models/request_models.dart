// lib/models/request_models.dart
class AgregarAlCarritoRequest {
  final String productoId;
  final String? variacionId;
  final int cantidad;

  AgregarAlCarritoRequest({
    required this.productoId,
    this.variacionId,
    this.cantidad = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'variacionId': variacionId,
      'cantidad': cantidad,
    };
  }
}

class ActualizarCantidadRequest {
  final String productoId;
  final String? variacionId;
  final int cantidad;

  ActualizarCantidadRequest({
    required this.productoId,
    this.variacionId,
    required this.cantidad,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'variacionId': variacionId,
      'cantidad': cantidad,
    };
  }
}

class EliminarDelCarritoRequest {
  final String productoId;
  final String? variacionId;

  EliminarDelCarritoRequest({
    required this.productoId,
    this.variacionId,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      'variacionId': variacionId,
    };
  }
}