import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ResenaService {
  final String _baseUrl = '${dotenv.env['API_URL']}/resenas';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<String?> _obtenerToken() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      return token;
    } catch (e) {
      return null;
    }
  }

  Map<String, String> _getHeaders(String? token) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  /// ✍ Crear reseña (requiere autenticación)
  Future<Map<String, dynamic>> crearResena({
    required String productoId,
    required String comentario,
    required int calificacion,
  }) async {
    final token = await _obtenerToken();
    
    if (token == null) {
      throw Exception('❌ Debes iniciar sesión para crear una reseña.');
    }

    try {
      final url = Uri.parse('$_baseUrl/producto/$productoId');
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

  /// 📋 Obtener reseñas de un producto (público - no requiere autenticación)
  Future<List<Map<String, dynamic>>> obtenerResenasPorProducto(String productoId) async {
    final token = await _obtenerToken();

    try {
      final url = Uri.parse('$_baseUrl/producto/$productoId');
      final response = await http.get(
        url, 
        headers: _getHeaders(token)
      ).timeout(const Duration(seconds: 15));

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

  /// 🛠 Actualizar reseña (requiere autenticación)
  Future<Map<String, dynamic>> actualizarResena({
    required String id,
    String? comentario,
    int? calificacion,
  }) async {
    final token = await _obtenerToken();
    
    if (token == null) {
      throw Exception('❌ Debes iniciar sesión para actualizar una reseña.');
    }

    try {
      final url = Uri.parse('$_baseUrl/id/$id');
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

  /// 🗑 Eliminar reseña (requiere autenticación)
  Future<void> eliminarResena({
    required String id,
    required String productoId,
  }) async {
    final token = await _obtenerToken();
    
    if (token == null) {
      throw Exception('❌ Debes iniciar sesión para eliminar una reseña.');
    }

    try {
      final url = Uri.parse('$_baseUrl/producto/$productoId/$id');
      final response = await http.delete(
        url, 
        headers: _getHeaders(token)
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(jsonDecode(response.body)['mensaje'] ?? '❌ Error al eliminar reseña');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  /// 🔐 Verificar si el usuario está autenticado
  Future<bool> estaAutenticado() async {
    final token = await _obtenerToken();
    return token != null && token.isNotEmpty;
  }

  /// 👤 Obtener ID del usuario actual decodificando el JWT
  Future<String?> obtenerIdUsuarioActual() async {
    try {
      final token = await _obtenerToken();
      
      if (token == null || token.isEmpty) {
        print('❌ No hay token disponible');
        return null;
      }

      // Decodificar el JWT para obtener el userId
      try {
        Map<String, dynamic> decoded = JwtDecoder.decode(token);
        final userId = decoded['id']?.toString();
        print('✅ UserId decodificado del JWT: $userId');
        return userId;
      } catch (e) {
        print('❌ Error al decodificar JWT: $e');
        return null;
      }
    } catch (e) {
      print('❌ Error al obtener userId: $e');
      return null;
    }
  }

  /// 👤 Obtener nombre del usuario actual desde secure storage
  Future<String?> obtenerNombreUsuarioActual() async {
    try {
      final nombre = await _secureStorage.read(key: 'nombre');
      print('✅ Nombre de usuario: $nombre');
      return nombre;
    } catch (e) {
      print('❌ Error al obtener nombre: $e');
      return null;
    }
  }
}