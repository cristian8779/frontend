import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ResenaService {
  final String _baseUrl = '${dotenv.env['API_URL']}/resenas';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String> _obtenerToken() async {
    final token = await _secureStorage.read(key: 'accessToken');
    if (token == null) {
      throw Exception('❌ No se encontró el token de acceso.');
    }
    return token;
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// ✍ Crear reseña
  Future<Map<String, dynamic>> crearResena({
    required String productoId,
    required String comentario,
    required int calificacion,
  }) async {
    final token = await _obtenerToken();

    try {
      final url = Uri.parse('$_baseUrl/$productoId');
      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          'comentario': comentario,
          'calificacion': calificacion,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al crear reseña');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  /// 📋 Obtener reseñas de un producto
  Future<List<Map<String, dynamic>>> obtenerResenasPorProducto(String productoId) async {
    final token = await _obtenerToken();

    try {
      final url = Uri.parse('$_baseUrl/producto/$productoId');
      final response = await http.get(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['resenas'] ?? []);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al obtener reseñas');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  /// 🛠 Actualizar reseña
  Future<Map<String, dynamic>> actualizarResena({
    required String id,
    String? comentario,
    int? calificacion,
  }) async {
    final token = await _obtenerToken();

    try {
      final url = Uri.parse('$_baseUrl/$id');
      final body = <String, dynamic>{};
      if (comentario != null) body['comentario'] = comentario;
      if (calificacion != null) body['calificacion'] = calificacion;

      final response = await http.put(
        url,
        headers: _getHeaders(token),
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al actualizar reseña');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  /// 🗑 Eliminar reseña
  Future<void> eliminarResena(String id) async {
    final token = await _obtenerToken();

    try {
      final url = Uri.parse('$_baseUrl/$id');
      final response = await http.delete(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al eliminar reseña');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }
}
