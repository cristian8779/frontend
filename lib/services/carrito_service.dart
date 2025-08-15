import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CarritoService {
  final String _baseUrl = '${dotenv.env['API_URL']}/carrito';

  /// Obtener carrito (JWT)
  Future<Map<String, dynamic>?> obtenerCarrito(String token) async {
    final response = await http.get(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('❌ Error al obtener carrito: ${response.body}');
      return null;
    }
  }

  /// Obtener resumen del carrito (JWT)
  Future<Map<String, dynamic>?> obtenerResumen(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resumen'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('❌ Error al obtener resumen: ${response.body}');
      return null;
    }
  }

  /// Agregar producto al carrito
  Future<bool> agregarProducto(String token, String productoId, int cantidad) async {
    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productoId': productoId,
        'cantidad': cantidad,
      }),
    );

    return response.statusCode == 200;
  }

  /// Actualizar cantidad de un producto
  Future<bool> actualizarCantidad(String token, String productoId, int cantidad) async {
    final response = await http.put(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productoId': productoId,
        'cantidad': cantidad,
      }),
    );

    return response.statusCode == 200;
  }

  /// Eliminar producto del carrito
  Future<bool> eliminarProducto(String token, String productoId) async {
    final response = await http.delete(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'productoId': productoId,
      }),
    );

    return response.statusCode == 200;
  }

  /// Vaciar carrito usando API Key (solo microservicio)
  Future<bool> vaciarCarritoInterno(String userId, String apiKey) async {
    final response = await http.delete(
      Uri.parse('${dotenv.env['API_URL']}/vaciar/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    );

    return response.statusCode == 200;
  }

  /// Obtener resumen usando API Key (solo microservicio)
  Future<Map<String, dynamic>?> obtenerResumenInterno(String userId, String apiKey) async {
    final response = await http.get(
      Uri.parse('${dotenv.env['API_URL']}/resumen/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print('❌ Error al obtener resumen interno: ${response.body}');
      return null;
    }
  }
}
