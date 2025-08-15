import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HistorialService {
  final String _baseUrl = '${dotenv.env['API_URL']}/historial';
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

  /// ➕ Agregar producto al historial
  Future<Map<String, dynamic>> agregarAlHistorial(String productoId) async {
    final token = await _obtenerToken();

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
        body: jsonEncode({'productoId': productoId}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al agregar al historial');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    }
  }

  /// 📋 Obtener historial agrupado por fecha
  Future<Map<String, dynamic>> obtenerHistorial() async {
    final token = await _obtenerToken();

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['historial'] ?? {};
      } else {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al obtener historial');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión: revisa tu Internet.');
    }
  }

  /// ❌ Eliminar un solo ítem del historial
  Future<void> eliminarDelHistorial(String id) async {
    final token = await _obtenerToken();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$id'),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al eliminar del historial');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    }
  }

  /// 🗑 Borrar todo el historial
  Future<void> borrarHistorialCompleto() async {
    final token = await _obtenerToken();

    try {
      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al borrar historial');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    }
  }
}
