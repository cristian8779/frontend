// lib/services/anuncio_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AnuncioService {
  final String _baseUrl = 'https://api.soportee.store/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;
  String? _errorMessage;

  String? get message => _errorMessage;

  AnuncioService() {
    print("✅ AnuncioService base URL: $_baseUrl");
  }

  // ------------------------------
  // TOKEN MANAGEMENT
  // ------------------------------
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
        print("❌ No se pudo renovar el token. Status: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Error renovando token: $e");
      return false;
    }
  }

  Map<String, dynamic>? _decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      return jsonDecode(payload);
    } catch (_) {
      return null;
    }
  }

  Future<String> _obtenerTokenValido() async {
    String? token = await _getAccessToken();
    if (token == null) throw Exception('❌ El token de acceso es nulo.');

    // Verificar expiración del JWT
    final payload = _decodeJwt(token);
    if (payload != null && payload.containsKey('exp')) {
      final expiry = DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000);
      if (expiry.isBefore(DateTime.now())) {
        print("⚠️ Token expirado. Intentando renovar...");
        final renovado = await _renovarToken();
        if (!renovado) throw Exception('❌ No se pudo renovar el token');
        token = await _getAccessToken();
      }
    }

    return token!;
  }

  // ------------------------------
  // ANUNCIOS
  // ------------------------------
  Future<List<Map<String, String>>> obtenerAnunciosActivos() async {
    final url = Uri.parse('$_baseUrl/anuncios/activos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) {
          return {
            'imagen': (e['imagen'] ?? '') as String,
            'deeplink': (e['deeplink'] ?? '') as String,
          };
        }).toList();
      } else {
        _errorMessage = 'Error ${response.statusCode}: ${response.reasonPhrase ?? "Respuesta inválida"}';
        return [];
      }
    } catch (e) {
      _errorMessage = "❌ Error al obtener anuncios: $e";
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> obtenerAnunciosActivosConId() async {
    final url = Uri.parse('$_baseUrl/anuncios/activos');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) {
          return {
            '_id': e['_id'],
            'imagen': e['imagen'] ?? '',
            'deeplink': e['deeplink'] ?? '',
            'fechaInicio': e['fechaInicio'],
            'fechaFin': e['fechaFin'],
            'productoId': e['productoId'],
            'categoriaId': e['categoriaId'],
          };
        }).toList();
      } else {
        _errorMessage = 'Error ${response.statusCode}: ${response.reasonPhrase ?? "Respuesta inválida"}';
        return [];
      }
    } catch (e) {
      _errorMessage = "❌ Error al obtener anuncios con ID: $e";
      return [];
    }
  }

  Future<bool> crearAnuncio({
    required String fechaInicio,
    required String fechaFin,
    String? productoId,
    String? categoriaId,
    required String imagenPath,
  }) async {
    _errorMessage = null;
    final token = await _obtenerTokenValido();
    final uri = Uri.parse('$_baseUrl/anuncios');

    try {
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['fechaInicio'] = fechaInicio
        ..fields['fechaFin'] = fechaFin;

      if (productoId != null && productoId.isNotEmpty) {
        request.fields['productoId'] = productoId;
      }
      if (categoriaId != null && categoriaId.isNotEmpty) {
        request.fields['categoriaId'] = categoriaId;
      }

      request.files.add(await http.MultipartFile.fromPath('imagen', imagenPath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        print("✅ Anuncio creado correctamente.");
        return true;
      } else {
        try {
          final data = jsonDecode(response.body);
          _errorMessage = data['error'] ?? 'Error al crear anuncio.';
        } catch (_) {
          _errorMessage = 'Error desconocido al crear anuncio.';
        }
        print("❌ Error crearAnuncio: ${response.statusCode} - $_errorMessage");
        return false;
      }
    } catch (e) {
      _errorMessage = "❌ Error interno al crear anuncio: $e";
      return false;
    }
  }

  Future<bool> eliminarAnuncio(String id) async {
    _errorMessage = null;
    final token = await _obtenerTokenValido();
    print("🧨 Intentando eliminar anuncio con ID: $id");

    final url = Uri.parse('$_baseUrl/anuncios/$id');

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        print("✅ Anuncio eliminado correctamente.");
        return true;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['error'] ?? 'No se pudo eliminar el anuncio.';
        print("❌ Error eliminarAnuncio: ${response.statusCode} - $_errorMessage");
        return false;
      }
    } catch (e) {
      _errorMessage = "❌ Error interno al eliminar anuncio: $e";
      return false;
    }
  }

  // ------------------------------
  // PRODUCTOS
  // ------------------------------
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/anuncios/productos');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> productos =
            (data['productos'] is List)
                ? data['productos']
                : (data['productos']?['productos'] ?? []);

        print("📦 Productos recibidos: ${productos.length}");
        if (productos.isNotEmpty) {
          print("🔍 Ejemplo de producto: ${productos.first}");
        }

        return productos.cast<Map<String, dynamic>>();
      } else {
        _errorMessage = 'Error al cargar productos: ${response.statusCode}';
        return [];
      }
    } catch (e) {
      _errorMessage = '❌ Error al cargar productos: $e';
      return [];
    }
  }

  // ------------------------------
  // CATEGORÍAS
  // ------------------------------
  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/anuncios/categorias');

    try {
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final List<dynamic> categorias =
            (data['categorias'] is List)
                ? data['categorias']
                : (data['categorias']?['categorias'] ?? []);

        print("📂 Categorías recibidas: ${categorias.length}");
        if (categorias.isNotEmpty) {
          print("🔍 Ejemplo de categoría: ${categorias.first}");
        }

        return categorias.cast<Map<String, dynamic>>();
      } else {
        _errorMessage = 'Error al cargar categorías: ${response.statusCode}';
        return [];
      }
    } catch (e) {
      _errorMessage = '❌ Error al cargar categorías: $e';
      return [];
    }
  }
}
