import 'dart:convert';
import 'dart:io'; // Para SocketException
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CategoriaService {
  final String _baseUrl = 'https://api.soportee.store/api'; // Cambia si tu API tiene otra base
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  CategoriaService();

  Future<String?> _getAccessToken() async {
    if (_token == null) {
      _token = await _secureStorage.read(key: 'accessToken');
    }
    return _token;
  }

  Future<bool> _renovarToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: 'accessToken', value: data['accessToken']);
        _token = data['accessToken'];
        return true;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<String> _obtenerTokenValido() async {
    String? token = await _getAccessToken();

    if (token == null) {
      throw Exception('❌ El token de acceso es nulo.');
    }

    final response = await http.get(
      Uri.parse('$_baseUrl/categorias'),
      headers: _getHeaders(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final tokenRenovado = await _renovarToken();
      if (tokenRenovado) {
        token = await _getAccessToken();
      } else {
        throw Exception('❌ No se pudo renovar el token.');
      }
    }

    if (token == null) {
      throw Exception('❌ No se pudo obtener un token válido.');
    }

    return token;
  }

  /// ✅ Obtener todas las categorías
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/categorias');

    try {
      final response = await http.get(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['categorias'] != null && data['categorias'] is List) {
          return List<Map<String, dynamic>>.from(data['categorias']);
        } else {
          return [];
        }
      } else {
        throw Exception('❌ Error al cargar categorías: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ No hay conexión a Internet.');
    }
  }

  /// 🆕 Obtener productos por categoría (por ID)
  Future<List<Map<String, dynamic>>> obtenerProductosPorCategoria(String categoriaId) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/por-categoria/$categoriaId');

    try {
      final response = await http.get(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['productos'] != null && data['productos'] is List) {
          return List<Map<String, dynamic>>.from(data['productos']);
        } else {
          return [];
        }
      } else {
        throw Exception('❌ Error al cargar productos: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ No hay conexión a Internet.');
    } catch (e) {
      throw Exception('❌ Error al obtener productos: $e');
    }
  }

  /// ✅ Crear categoría con imagen local
  Future<Map<String, dynamic>> crearCategoriaConImagenLocal({
    required String nombre,
    required String descripcion,
    required File imagenLocal,
  }) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/categorias');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..files.add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));

    try {
      final response = await request.send().timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['mensaje'] ?? '❌ Error al crear categoría.');
      }
    } catch (e) {
      throw Exception('❌ Error al enviar solicitud: $e');
    }
  }

  /// ✅ Actualizar categoría
  Future<Map<String, dynamic>> actualizarCategoria({
    required String id,
    required String nombre,
    required String descripcion,
    File? imagenLocal,
  }) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/categorias/$id');

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim();

    if (imagenLocal != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));
    }

    try {
      final response = await request.send().timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['mensaje'] ?? '❌ Error al actualizar categoría.');
      }
    } catch (e) {
      throw Exception('❌ Error al enviar solicitud: $e');
    }
  }

  /// ✅ Eliminar categoría
  Future<bool> eliminarCategoria(String id) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/categorias/$id');

    try {
      final response = await http.delete(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['mensaje'] ?? '❌ Error al eliminar categoría.');
      }
    } catch (e) {
      throw Exception('❌ Error al eliminar categoría: $e');
    }
  }
}
