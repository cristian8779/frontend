import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
// ✅ NUEVAS IMPORTACIONES
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

  // --- MÉTODOS DEL CRUD DE VARIACIONES (Corregidos) ---

  /// ✅ Crear variación con imagen y nombre del color
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
      ..fields['color'] = jsonEncode({
        'nombre': nombreColor,
        'hex': colorHex,
      })
      ..fields['stock'] = variacion.stock.toString()
      ..fields['precio'] = variacion.precio.toString();

    // ✅ CORRECCIÓN CLAVE: Obtener y especificar el tipo MIME del archivo
    final mimeTypeData = lookupMimeType(imagenLocal.path, headerBytes: [0xFF, 0xD8])?.split('/');
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
    debugPrint('➡️ Campos a enviar: ${request.fields}');
    debugPrint('➡️ Archivo a enviar: $fileName con tipo MIME: ${mimeTypeData.join('/')}');

    try {
      final response = await request.send();
      final body = await response.stream.bytesToString();

      debugPrint('⬅️ Respuesta de crear variación: Status ${response.statusCode}');
      debugPrint('⬅️ Cuerpo de la respuesta: $body');

      if (response.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) {
          return await crearVariacionDesdeModelo(variacion);
        } else {
          throw Exception('❌ Sesión expirada. No se pudo renovar.');
        }
      }

      if (response.statusCode != 201) {
        try {
          final error = jsonDecode(body);
          throw Exception(error['mensaje'] ?? '❌ Error al crear la variación');
        } on FormatException {
          throw Exception('❌ Error del servidor: Respuesta inesperada. Cuerpo: $body');
        }
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet. Por favor, verifica tu red.');
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> obtenerVariacionesPorProducto(String productoId) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones');

    debugPrint('➡️ Obteniendo variaciones para producto $productoId en: $url');

    try {
      final response = await http.get(url, headers: _getHeaders(token)).timeout(const Duration(seconds: 15));

      debugPrint('⬅️ Respuesta de obtener variaciones: Status ${response.statusCode}');
      debugPrint('⬅️ Cuerpo de la respuesta: ${response.body}');

      if (response.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) return await obtenerVariacionesPorProducto(productoId);
        throw Exception('❌ Sesión expirada.');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['variaciones'] ?? []);
      } else {
        throw Exception('❌ Error al obtener variaciones: ${response.reasonPhrase}');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al obtener variaciones: $e');
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
      // ✅ CORRECCIÓN CLAVE: Obtener y especificar el tipo MIME
      final mimeTypeData = lookupMimeType(imagenLocal.path, headerBytes: [0xFF, 0xD8])?.split('/');
      if (mimeTypeData == null || mimeTypeData.length != 2) {
        throw Exception('❌ No se pudo determinar el tipo MIME del archivo para la actualización.');
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
    debugPrint('➡️ Campos a enviar: ${request.fields}');

    try {
      final response = await request.send().timeout(const Duration(seconds: 15));
      final body = await response.stream.bytesToString();

      debugPrint('⬅️ Respuesta de actualizar variación: Status ${response.statusCode}');
      debugPrint('⬅️ Cuerpo de la respuesta: $body');
      
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

      if (response.statusCode == 200) {
        return jsonDecode(body);
      } else {
        try {
          final error = jsonDecode(body);
          throw Exception(error['mensaje'] ?? '❌ Error al actualizar la variación');
        } on FormatException {
          throw Exception('❌ Error del servidor: Respuesta inesperada. Cuerpo: $body');
        }
      }
    } on SocketException {
      throw Exception('❌ Sin conexión a Internet.');
    } catch (e) {
      throw Exception('❌ Error al actualizar la variación: $e');
    }
  }

  Future<void> eliminarVariacion({
    required String productoId,
    required String variacionId,
  }) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones/$variacionId');

    debugPrint('➡️ Eliminando variación en: $url');

    final response = await http.delete(url, headers: _getHeaders(token));
    debugPrint('⬅️ Respuesta de eliminar variación: Status ${response.statusCode}');
    debugPrint('⬅️ Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body);
      throw Exception('❌ No se pudo eliminar la variación: ${error['mensaje'] ?? 'Error desconocido'}');
    }
  }

  Future<Map<String, dynamic>> reducirStockVariacion({
    required String productoId,
    required String variacionId,
    required int cantidad,
  }) async {
    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones/$variacionId/reducir-stock');

    debugPrint('➡️ Reduciendo stock de la variación en: $url');
    debugPrint('➡️ Cantidad a reducir: $cantidad');

    final response = await http.put(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'cantidad': cantidad}),
    );

    debugPrint('⬅️ Respuesta de reducir stock: Status ${response.statusCode}');
    debugPrint('⬅️ Cuerpo de la respuesta: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['mensaje'] ?? '❌ Error al reducir el stock');
    }
  }
}