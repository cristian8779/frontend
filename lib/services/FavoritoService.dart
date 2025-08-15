import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FavoritoService {
  final String _baseUrl = '${dotenv.env['API_URL']}/favoritos';
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

  /// ❤️ Agregar producto a favoritos
  Future<Map<String, dynamic>> agregarFavorito(String productoId) async {
    final token = await _obtenerToken();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
        body: jsonEncode({'productoId': productoId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al agregar favorito');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    }
  }

  /// 📋 Obtener lista de favoritos
  Future<List<Map<String, dynamic>>> obtenerFavoritos() async {
    final token = await _obtenerToken();

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['favoritos'] ?? []);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al obtener favoritos');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión: revisa tu Internet.');
    }
  }

  /// 🗑️ Eliminar producto de favoritos
  Future<void> eliminarFavorito(String productoId) async {
    final token = await _obtenerToken();

    try {
      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
        body: jsonEncode({'productoId': productoId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al eliminar favorito');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    }
  }
}
