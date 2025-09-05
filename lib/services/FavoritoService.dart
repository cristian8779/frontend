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
    } catch (e) {
      print('Error en agregarFavorito: $e');
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// 📋 Obtener lista de favoritos
  Future<List<Map<String, dynamic>>> obtenerFavoritos() async {
    final token = await _obtenerToken();

    try {
      print('🔍 Obteniendo favoritos desde: $_baseUrl');
      
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      print('📱 Status Code: ${response.statusCode}');
      print('📱 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Verificar si existe la clave 'favoritos'
        if (data['favoritos'] != null) {
          final favoritos = List<Map<String, dynamic>>.from(data['favoritos']);
          print('✅ Favoritos obtenidos: ${favoritos.length} items');
          return favoritos;
        } else {
          print('⚠️ No se encontró la clave favoritos en la respuesta');
          return [];
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['mensaje'] ?? '❌ Error al obtener favoritos (${response.statusCode})');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión: revisa tu Internet.');
    } catch (e) {
      print('❌ Error en obtenerFavoritos: $e');
      throw Exception('❌ Error al cargar favoritos: $e');
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
    } catch (e) {
      print('Error en eliminarFavorito: $e');
      throw Exception('❌ Error inesperado: $e');
    }
  }

  /// 🔄 Método para verificar la estructura de datos
  Future<void> debugFavoritos() async {
    try {
      final favoritos = await obtenerFavoritos();
      print('🐛 DEBUG - Total favoritos: ${favoritos.length}');
      
      for (int i = 0; i < favoritos.length; i++) {
        final favorito = favoritos[i];
        print('🐛 DEBUG - Favorito $i: ${favorito.keys}');
        
        if (favorito['producto'] != null) {
          final producto = favorito['producto'];
          print('🐛 DEBUG - Producto: ${producto['nombre']} - ${producto['precio']}');
        }
      }
    } catch (e) {
      print('🐛 DEBUG ERROR: $e');
    }
  }
}