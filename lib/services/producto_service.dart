import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ProductoService {
  final String _baseUrl = 'https://api.soportee.store/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

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
      Uri.parse('$_baseUrl/productos'),
      headers: _getHeaders(token),
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 401) {
      final tokenRenovado = await _renovarToken();
      if (tokenRenovado) {
        token = await _getAccessToken();
      } else {
        throw Exception('❌ No se pudo renovar el token');
      }
    }

    if (token == null) {
      throw Exception('❌ No se pudo obtener un token válido');
    }

    return token;
  }

  /// 📦 Crear un producto con estado
  Future<Map<String, dynamic>> crearProducto({
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    String? subcategoria,
    int stock = 0,
    bool disponible = true,
    required String estado,
    required File imagenLocal,
  }) async {
    if (nombre.isEmpty || descripcion.isEmpty || precio <= 0 || stock < 0) {
      throw Exception('❌ Los campos del producto son inválidos.');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..fields['precio'] = precio.toString()
      ..fields['categoria'] = categoria
      ..fields['subcategoria'] = subcategoria ?? ''
      ..fields['stock'] = stock.toString()
      ..fields['disponible'] = disponible.toString()
      ..fields['estado'] = estado
      ..files.add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));

    try {
      final response = await request.send().timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString();

      print('📤 Crear producto - Respuesta: $responseBody');

      if (response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['mensaje'] ?? '❌ Error al crear el producto');
      }
    } catch (e) {
      throw Exception('❌ Error al enviar la solicitud: $e');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos');

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
      throw Exception('❌ Error de conexión: No hay Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al obtener productos: $e');
    }
  }

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
          throw Exception('❌ Formato inesperado en la respuesta de categorías.');
        }
      } else {
        throw Exception('❌ Error al obtener categorías: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión: revisa tu Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al cargar categorías: $e');
    }
  }

  Future<Map<String, dynamic>> reducirStock(String id, int cantidad) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$id/reducir-stock');

    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: {'cantidad': cantidad.toString()},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('❌ Error al reducir el stock');
    }
  }

  Future<void> eliminarProducto(String id) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$id');

    final response = await http.delete(url, headers: _getHeaders(token));

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('❌ No se pudo eliminar el producto: ${error['mensaje'] ?? 'Error desconocido'}');
    }
  }

 Future<Map<String, dynamic>> obtenerProductoPorId(String id) async {
  final token = await _obtenerTokenValido();
  final url = Uri.parse('$_baseUrl/productos/$id');

  print('🔄 Cargando producto con ID: $id');

  try {
    final response = await http.get(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

    print('📥 Respuesta: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic> && data.containsKey('producto')) {
        return data['producto'];
      } else {
        throw Exception('❌ Formato inesperado al obtener el producto.');
      }
    } else {
      throw Exception('❌ Error al obtener el producto: ${response.body}');
    }
  } on SocketException {
    throw Exception('❌ Sin conexión: revisa tu Internet.');
  } catch (e) {
    throw Exception('❌ Error inesperado al obtener el producto: $e');
  }
}


  /// 🛠️ Actualizar producto con campo `estado`
  Future<Map<String, dynamic>> actualizarProducto({
    required String id,
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    String? subcategoria,
    int stock = 0,
    bool disponible = true,
    required String estado,
    File? imagenLocal,
  }) async {
    if (categoria.isEmpty) {
      throw Exception('❌ La categoría es obligatoria para actualizar el producto.');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$id');

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..fields['precio'] = precio.toString()
      ..fields['categoria'] = categoria
      ..fields['subcategoria'] = subcategoria ?? ''
      ..fields['stock'] = stock.toString()
      ..fields['disponible'] = disponible.toString()
      ..fields['estado'] = estado;

    if (imagenLocal != null) {
      request.files.add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));
    }

    try {
      print('🛠️ Actualizando producto $id con los siguientes datos:');
      request.fields.forEach((key, value) => print(' - $key: $value'));
      if (imagenLocal != null) print(' - Imagen: ${imagenLocal.path}');

      final response = await request.send().timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString();

      print('📥 Respuesta status: ${response.statusCode}');
      print('📥 Body: $responseBody');

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw Exception(error['mensaje'] ?? '❌ Error al actualizar el producto.');
      }
    } catch (e) {
      throw Exception('❌ Ocurrió un error al actualizar el producto: $e');
    }
  }
}
