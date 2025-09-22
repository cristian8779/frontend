import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

import '../models/variacion.dart';
import '../utils/colores.dart';

class VariacionService {
  final String _baseUrl = dotenv.env['API_URL'] ?? 'https://api.soportee.store/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  // --- MÉTODOS DE AUTENTICACIÓN ---
  Future<String?> _getAccessToken() async {
    _token ??= await _secureStorage.read(key: 'accessToken');
    debugPrint('ℹ️ Token de acceso obtenido: ${_token != null ? '✅' : '❌'}');
    return _token;
  }

  Future<bool> _renovarToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) {
        debugPrint('❌ No se encontró refreshToken.');
        return false;
      }
      debugPrint('ℹ️ Intentando renovar token...');

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      debugPrint('ℹ️ Respuesta de renovación de token: Status ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: 'accessToken', value: data['accessToken']);
        _token = data['accessToken'];
        debugPrint('✅ Token renovado exitosamente.');
        return true;
      } else {
        debugPrint('❌ Falló la renovación del token. Cuerpo: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Excepción al renovar token: $e');
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
    if (token == null) throw Exception('❌ El token de acceso es nulo.');
    return token;
  }

  // --- CRUD VARIACIONES ---

  /// ✅ Crear variación con imagen y color
  Future<void> crearVariacionDesdeModelo(Variacion variacion) async {
    if (variacion.imagenes.isEmpty || variacion.imagenes.first.localFile == null) {
      throw Exception('⚠️ No se ha proporcionado una imagen local válida.');
    }

    final File imagenLocal = variacion.imagenes.first.localFile!;
    final String token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/${variacion.productoId}/variaciones');

    final String colorHex = variacion.colorHex ?? '';
    final String nombreColor = variacion.colorNombre ?? Colores.getNombreColor(colorHex);
    final String fileName = p.basename(imagenLocal.path);

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['tallaNumero'] = variacion.tallaNumero ?? ''
      ..fields['tallaLetra'] = variacion.tallaLetra ?? ''
      ..fields['color'] = jsonEncode({'nombre': nombreColor, 'hex': colorHex})
      ..fields['stock'] = variacion.stock.toString()
      ..fields['precio'] = variacion.precio.toString();

    final mimeTypeData = lookupMimeType(imagenLocal.path)?.split('/');
    if (mimeTypeData == null || mimeTypeData.length != 2) {
      throw Exception('❌ No se pudo determinar el tipo MIME del archivo.');
    }

    request.files.add(
      await http.MultipartFile.fromPath(
        'imagenes',
        imagenLocal.path,
        filename: fileName,
        contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
      ),
    );

    debugPrint('➡️ Creando variación en: $url');
    debugPrint('➡️ Campos: ${request.fields}');
    debugPrint('➡️ Archivo: $fileName (${mimeTypeData.join("/")})');

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint('⬅️ Respuesta crear variación: Status ${response.statusCode}');
      debugPrint('⬅️ Body: $body');

      if (response.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) return await crearVariacionDesdeModelo(variacion);
        throw Exception('❌ Sesión expirada.');
      }

      if (response.statusCode != 201) {
        final error = _tryDecodeError(body);
        throw Exception(error);
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  Future<List<Map<String, dynamic>>> obtenerVariacionesPorProducto(String productoId) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones');

    debugPrint('➡️ Obteniendo variaciones: $url');

    try {
      final response = await http.get(url, headers: _getHeaders(token));

      debugPrint('⬅️ Respuesta obtener variaciones: ${response.statusCode}');
      debugPrint('⬅️ Body: ${response.body}');

      if (response.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) return await obtenerVariacionesPorProducto(productoId);
        throw Exception('❌ Sesión expirada.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final variaciones = List<Map<String, dynamic>>.from(data['variaciones'] ?? []);

        for (final v in variaciones) {
          debugPrint("🆔 VARIACIÓN ID: ${v['_id']}");
        }

        return variaciones;
      } else {
        throw Exception('❌ Error al obtener variaciones: ${response.reasonPhrase}');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  Future<Map<String, dynamic>> actualizarVariacion({
    required String productoId,
    required String variacionId,
    String? tallaNumero,
    String? tallaLetra,
    String? colorHex,
    String? colorNombre,
    int? stock,
    double? precio,
    File? imagenLocal,
  }) async {
    if (variacionId.isEmpty || variacionId.length != 24) {
      throw Exception('❌ ID de variación inválido: $variacionId');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones/$variacionId');

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token';

    if (tallaNumero != null) request.fields['tallaNumero'] = tallaNumero;
    if (tallaLetra != null) request.fields['tallaLetra'] = tallaLetra;
    if (colorHex != null) {
      request.fields['color'] = jsonEncode({
        'nombre': colorNombre ?? Colores.getNombreColor(colorHex),
        'hex': colorHex,
      });
    }
    if (stock != null) request.fields['stock'] = stock.toString();
    if (precio != null) request.fields['precio'] = precio.toString();

    if (imagenLocal != null) {
      final String fileName = p.basename(imagenLocal.path);
      final mimeTypeData = lookupMimeType(imagenLocal.path)?.split('/');
      if (mimeTypeData == null || mimeTypeData.length != 2) {
        throw Exception('❌ Tipo MIME inválido.');
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'imagenes',
          imagenLocal.path,
          filename: fileName,
          contentType: MediaType(mimeTypeData[0], mimeTypeData[1]),
        ),
      );
    }

    debugPrint('➡️ Actualizando variación en: $url');
    debugPrint('➡️ Campos: ${request.fields}');

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint('⬅️ Respuesta actualizar variación: ${response.statusCode}');
      debugPrint('⬅️ Body: $body');

      if (response.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) {
          return await actualizarVariacion(
            productoId: productoId,
            variacionId: variacionId,
            tallaNumero: tallaNumero,
            tallaLetra: tallaLetra,
            colorHex: colorHex,
            colorNombre: colorNombre,
            stock: stock,
            precio: precio,
            imagenLocal: imagenLocal,
          );
        }
        throw Exception('❌ Sesión expirada.');
      }

      if (response.statusCode == 404) {
        throw Exception('❌ Variación no encontrada.');
      }

      if (response.statusCode == 200) {
        return jsonDecode(body);
      } else {
        final error = _tryDecodeError(body);
        throw Exception(error);
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    }
  }

  Future<void> actualizarVariacionDesdeModelo(Variacion variacion) async {
    await actualizarVariacion(
      productoId: variacion.productoId,
      variacionId: variacion.id!,
      tallaNumero: variacion.tallaNumero,
      tallaLetra: variacion.tallaLetra,
      colorHex: variacion.colorHex,
      colorNombre: variacion.colorNombre,
      stock: variacion.stock,
      precio: variacion.precio,
      imagenLocal: variacion.imagenes.isNotEmpty && variacion.imagenes.first.isLocal == true
          ? variacion.imagenes.first.localFile
          : null,
    );
  }

  Future<void> eliminarVariacion({
    required String productoId,
    required String variacionId,
  }) async {
    if (variacionId.isEmpty || variacionId.length != 24) {
      throw Exception('❌ ID de variación inválido: $variacionId');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones/$variacionId');

    debugPrint('➡️ Eliminando variación en: $url');

    final response = await http.delete(url, headers: _getHeaders(token));
    debugPrint('⬅️ Respuesta eliminar: ${response.statusCode}');
    debugPrint('⬅️ Body: ${response.body}');

    if (response.statusCode == 404) {
      throw Exception('❌ Variación no encontrada.');
    }

    if (response.statusCode != 200) {
      final error = _tryDecodeError(response.body);
      throw Exception('❌ No se pudo eliminar: $error');
    }
  }

  Future<Map<String, dynamic>> reducirStockVariacion({
    required String productoId,
    required String variacionId,
    required int cantidad,
  }) async {
    if (variacionId.isEmpty || variacionId.length != 24) {
      throw Exception('❌ ID de variación inválido: $variacionId');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones/$variacionId/reducir-stock');

    debugPrint('➡️ Reduciendo stock en: $url (cantidad: $cantidad)');

    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'cantidad': cantidad}),
    );

    debugPrint('⬅️ Respuesta reducir stock: ${response.statusCode}');
    debugPrint('⬅️ Body: ${response.body}');

    if (response.statusCode == 404) {
      throw Exception('❌ Variación no encontrada.');
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = _tryDecodeError(response.body);
      throw Exception('❌ Error al reducir stock: $error');
    }
  }

  // --- HELPER ---
  String _tryDecodeError(String body) {
    try {
      final error = jsonDecode(body);
      return error['mensaje'] ?? body;
    } catch (_) {
      return body;
    }
  }
}
