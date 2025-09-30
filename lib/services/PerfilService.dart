import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:math' as math;

class PerfilService {
  // ==========================
  // Config
  // ==========================
  final String baseUrl = '${dotenv.env['API_URL']}/perfil';
  final String usuarioBaseUrl = '${dotenv.env['API_URL']}/usuario';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Duration _timeoutShort = const Duration(seconds: 15);
  final Duration _timeoutLong = const Duration(seconds: 20);

  String? _errorMessage;
  String? get message => _errorMessage;

  // ==========================
  // Logging helpers
  // ==========================
  static const String _tag = '📘 PerfilService';
  String _newRid() => DateTime.now().microsecondsSinceEpoch.toString();
  void _log(String msg, {String? rid}) {
    final ts = DateTime.now().toIso8601String();
    print('$_tag${rid != null ? ' [$rid]' : ''} $ts — $msg');
  }

  void _logLarge(String label, String text, {String? rid, int chunk = 800}) {
    if (text.isEmpty) {
      _log('$label: <empty>', rid: rid);
      return;
    }
    for (var i = 0; i < text.length; i += chunk) {
      final end = (i + chunk < text.length) ? i + chunk : text.length;
      _log('$label [${i.toString().padLeft(4)}..${(end - 1).toString().padLeft(4)}]: ${text.substring(i, end)}', rid: rid);
    }
  }

  String _safeTokenPreview(String? token) {
    if (token == null) return 'null';
    final len = token.length;
    final shown = math.min(len, 12);
    return '${token.substring(0, shown)}…($len chars)';
  }

  Map<String, String> _jsonHeaders({String? token}) => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  // Pretty print headers (only a few keys)
  void _logHeaders(Map<String, String> headers, {String? rid}) {
    final keys = ['content-type', 'cf-ray', 'x-powered-by', 'server', 'date'];
    final filtered = headers.entries
        .where((e) => keys.contains(e.key.toLowerCase()))
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');
    _log('Headers: {$filtered}', rid: rid);
  }

  Map<String, dynamic>? _tryJson(String body, {String? rid}) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'_raw': decoded};
    } catch (e) {
      _log('⚠️ No es JSON válido: $e', rid: rid);
      return null;
    }
  }

  // ==========================
  // Conectividad & Token
  // ==========================
  Future<bool> _tieneConexion() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      _log('❌ Error verificando conectividad: $e');
      return false;
    }
  }

  Future<String?> _getToken({String? rid}) async {
    final token = await _secureStorage.read(key: 'accessToken');
    _log('🔑 Token obtenido: ${_safeTokenPreview(token)}', rid: rid);
    return token;
  }

  // ==========================
  // JWT debug (usa base64Url)
  // ==========================
  void _debugToken(String? token, {String? rid}) {
    if (token == null) {
      _log('❌ No hay token', rid: rid);
      return;
    }
    try {
      final parts = token.split('.');
      if (parts.length == 3) {
        final payload = parts[1];
        final normalized = base64Url.normalize(payload);
        final decoded = utf8.decode(base64Url.decode(normalized));
        final data = jsonDecode(decoded);
        _log("🔍 Usuario ID del token: ${data['id'] ?? data['userId'] ?? data['_id']}", rid: rid);
        _log("🔍 Token expira: ${data['exp'] != null ? DateTime.fromMillisecondsSinceEpoch(data['exp'] * 1000) : 'No definido'}", rid: rid);
      } else {
        _log('⚠️ Token JWT con formato inesperado (parts: ${parts.length})', rid: rid);
      }
    } catch (e) {
      _log('❌ Error al decodificar token: $e', rid: rid);
    }
  }

  // ==========================
  // PERFIL - Métodos corregidos según el controller
  // ==========================
  
  /// Crear perfil inicial - llamado desde el microservicio de autenticación
  Future<bool> crearPerfil(String nombre, String credenciales, {String? imagenPerfil}) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return false;
    }

    try {
      final url = Uri.parse(baseUrl);
      _log("📤 POST $url", rid: rid);
      _log("Payload: {nombre: '${nombre.trim()}', credenciales: '$credenciales', imagenPerfil: '${imagenPerfil ?? ''}'}", rid: rid);

      final response = await http
          .post(url, headers: _jsonHeaders(), body: jsonEncode({
            'nombre': nombre.trim(),
            'credenciales': credenciales,
            'imagenPerfil': imagenPerfil ?? ''
          }))
          .timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logHeaders(response.headers, rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 201) {
        return true;
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = data != null ? (data['mensaje']?.toString() ?? 'Error al crear perfil.') : 'Error al crear perfil.';
      return false;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout creando perfil', rid: rid);
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red creando perfil: $e', rid: rid);
      return false;
    } catch (e) {
      _errorMessage = 'Error en crear perfil: $e';
      _log('❌ Error en crear perfil: $e', rid: rid);
      return false;
    }
  }

  /// Obtener perfil del usuario autenticado (incluye credenciales del microservicio auth)
  Future<Map<String, dynamic>?> obtenerPerfil() async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {

      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return null;
    }

    try {
      final token = await _getToken(rid: rid);
      if (token == null) {
        _errorMessage = 'no_autorizado';
        _log('🔒 No hay token de autenticación', rid: rid);
        return null;
      }

      _debugToken(token, rid: rid);
      final url = Uri.parse(baseUrl);
      _log('📤 GET $url', rid: rid);

      final response = await http
          .get(url, headers: _jsonHeaders(token: token))
          .timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logHeaders(response.headers, rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 200) {
        final data = _tryJson(response.body, rid: rid) ?? <String, dynamic>{};
        _log('✅ Claves recibidas: ${data.keys.toList()}', rid: rid);
        return data;
      }

      if (response.statusCode == 404) {
        final data = _tryJson(response.body, rid: rid);
        _errorMessage = data?['mensaje']?.toString() ?? 'Perfil no encontrado.';
        _log('⚠️ Perfil no encontrado', rid: rid);
        return null;
      }

      if (response.statusCode == 401) {
        _errorMessage = 'no_autorizado';
        _log('🔒 401 No autorizado al obtener perfil', rid: rid);
        return null;
      }

      if (response.statusCode == 502) {
        final data = _tryJson(response.body, rid: rid);
        _errorMessage = data?['mensaje']?.toString() ?? 'Error del servidor de credenciales.';
        _log('🌐 502 Error del servidor de credenciales', rid: rid);
        return null;
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = data?['mensaje']?.toString() ?? 'Error al obtener perfil.';
      _log('❌ Error al obtener perfil: $_errorMessage', rid: rid);
      return null;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout obteniendo perfil', rid: rid);
      return null;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red obteniendo perfil: $e', rid: rid);
      return null;
    } catch (e) {
      _errorMessage = 'Error en obtener perfil: $e';
      _log('❌ Error en obtener perfil: $e', rid: rid);
      return null;
    }
  }

  /// El endpoint cambió de /datos a /
 /// Actualizar datos básicos del perfil (nombre, teléfono, dirección)
Future<bool> actualizarPerfil({String? nombre, Map<String, dynamic>? direccion, String? telefono}) async {
  _errorMessage = null;
  final rid = _newRid();

  if (!await _tieneConexion()) {
    _errorMessage = 'sin_conexion';
    _log('🌐 Sin conexión', rid: rid);
    return false;
  }

  try {
    final token = await _getToken(rid: rid);
    if (token == null) {
      _errorMessage = 'no_autorizado';
      _log('🔒 No hay token de autenticación', rid: rid);
      return false;
    }

    // 👉 Ahora sí coincide con el backend (/perfil/datos)
    final url = Uri.parse('$baseUrl/datos');
    _log('📤 PUT $url', rid: rid);
    
    final payload = <String, dynamic>{
      if (nombre != null) 'nombre': nombre.trim(),
      if (direccion != null) 'direccion': direccion,
      if (telefono != null) 'telefono': telefono.trim(),
    };
    
    if (payload.isEmpty) {
      _errorMessage = 'No hay datos para actualizar';
      _log('⚠️ Payload vacío', rid: rid);
      return false;
    }
    
    _log('Payload: $payload', rid: rid);

    final response = await http
        .put(url, headers: _jsonHeaders(token: token), body: jsonEncode(payload))
        .timeout(_timeoutShort);

    _log('📥 Status: ${response.statusCode}', rid: rid);
    _logLarge('Body', response.body, rid: rid);

    if (response.statusCode == 200) return true;

    final data = _tryJson(response.body, rid: rid);
    _errorMessage = (response.statusCode == 401)
        ? 'no_autorizado'
        : (response.statusCode == 404)
          ? 'Perfil no encontrado'
          : (data?['mensaje']?.toString() ?? 'Error al actualizar perfil.');
    return false;
  } on TimeoutException {
    _errorMessage = 'timeout';
    _log('⏳ Timeout actualizando perfil', rid: rid);
    return false;
  } on SocketException catch (e) {
    _errorMessage = 'sin_conexion';
    _log('🌐 Error de red actualizando perfil: $e', rid: rid);
    return false;
  } catch (e) {
    _errorMessage = 'Error en actualizar perfil: $e';
    _log('❌ Error en actualizar perfil: $e', rid: rid);
    return false;
  }
}


  /// Actualizar imagen de perfil usando multipart
  /// El endpoint es /perfil/imagen con POST
  Future<bool> actualizarImagenPerfil(String filePath) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return false;
    }

    try {
      final token = await _getToken(rid: rid);
      if (token == null) {
        _errorMessage = 'no_autorizado';
        _log('🔒 No hay token de autenticación', rid: rid);
        return false;
      }

      final url = Uri.parse('$baseUrl/imagen');
      _log('📤 POST (multipart) $url — file: $filePath', rid: rid);

      final request = http.MultipartRequest('POST', url);
      request.headers['Authorization'] = 'Bearer $token';
      // El controller espera el campo 'imagen' (no 'file')
      request.files.add(await http.MultipartFile.fromPath('imagen', filePath));

      final streamed = await request.send().timeout(_timeoutLong);
      final responseBody = await streamed.stream.bytesToString();

      _log('📥 Status: ${streamed.statusCode}', rid: rid);
      _logLarge('Body', responseBody, rid: rid);

      if (streamed.statusCode == 200 || streamed.statusCode == 201) {
        return true;
      }

      final data = _tryJson(responseBody, rid: rid);
      _errorMessage = (streamed.statusCode == 401)
          ? 'no_autorizado'
          : (streamed.statusCode == 404)
            ? 'Perfil no encontrado'
            : (streamed.statusCode == 400)
              ? (data?['mensaje']?.toString() ?? 'Imagen no válida')
              : (data?['mensaje']?.toString() ?? 'Error al actualizar imagen.');
      return false;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout actualizando imagen de perfil', rid: rid);
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red subiendo imagen: $e', rid: rid);
      return false;
    } catch (e) {
      _errorMessage = 'Error en actualizar imagen: $e';
      _log('❌ Error en actualizar imagen: $e', rid: rid);
      return false;
    }
  }

  /// Eliminar imagen de perfil
  /// El endpoint es /perfil/imagen con DELETE
  Future<bool> eliminarImagenPerfil() async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return false;
    }

    try {
      final token = await _getToken(rid: rid);
      if (token == null) {
        _errorMessage = 'no_autorizado';
        _log('🔒 No hay token de autenticación', rid: rid);
        return false;
      }

      final url = Uri.parse('$baseUrl/imagen');
      _log('📤 DELETE $url', rid: rid);

      final response = await http
          .delete(url, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 200) return true;

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = (response.statusCode == 401)
          ? 'no_autorizado'
          : (response.statusCode == 404)
            ? (data?['mensaje']?.toString() ?? 'No tienes imagen para eliminar')
            : (data?['mensaje']?.toString() ?? 'Error al eliminar imagen.');
      return false;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout eliminando imagen de perfil', rid: rid);
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red eliminando imagen: $e', rid: rid);
      return false;
    } catch (e) {
      _errorMessage = 'Error en eliminar imagen: $e';
      _log('❌ Error en eliminar imagen: $e', rid: rid);
      return false;
    }
  }

  // ==========================
  // USUARIO - Mantienen la misma estructura
  // ==========================
  Future<Map<String, dynamic>?> crearUsuario({
    required String nombre,
    required String credenciales,
    String? direccion,
    String? telefono,
    String? imagenPerfilPath,
  }) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return null;
    }

    try {
      _log("📤 Creando usuario: nombre='${nombre.trim()}', credenciales='${credenciales.trim()}'", rid: rid);
      final url = Uri.parse(usuarioBaseUrl);

      http.Response response;
      if (imagenPerfilPath != null) {
        _log('Usando multipart con imagen: $imagenPerfilPath', rid: rid);
        final request = http.MultipartRequest('POST', url);
        request.fields['nombre'] = nombre.trim();
        request.fields['credenciales'] = credenciales.trim();
        if (direccion != null) request.fields['direccion'] = direccion.trim();
        if (telefono != null) request.fields['telefono'] = telefono.trim();
        request.files.add(await http.MultipartFile.fromPath('imagen', imagenPerfilPath));

        final streamedResponse = await request.send().timeout(_timeoutLong);
        final body = await streamedResponse.stream.bytesToString();
        _log('📥 Status: ${streamedResponse.statusCode}', rid: rid);
        _logLarge('Body', body, rid: rid);
        response = http.Response(body, streamedResponse.statusCode);
      } else {
        final payload = {
          'nombre': nombre.trim(),
          'credenciales': credenciales.trim(),
          if (direccion != null) 'direccion': direccion.trim(),
          if (telefono != null) 'telefono': telefono.trim(),
        };
        _log('POST $url', rid: rid);
        _log('Payload: $payload', rid: rid);
        response = await http
            .post(url, headers: _jsonHeaders(), body: jsonEncode(payload))
            .timeout(_timeoutShort);
        _log('📥 Status: ${response.statusCode}', rid: rid);
        _logLarge('Body', response.body, rid: rid);
      }

      if (response.statusCode == 201) {
        return _tryJson(response.body, rid: rid);
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = data?['mensaje']?.toString() ?? 'Error al crear usuario.';
      return null;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout creando usuario', rid: rid);
      return null;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red creando usuario: $e', rid: rid);
      return null;
    } catch (e) {
      _errorMessage = 'Error en crear usuario: $e';
      _log('❌ Error en crear usuario: $e', rid: rid);
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioPorCredencial(String credencial) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return null;
    }

    try {
      final url = Uri.parse('$usuarioBaseUrl/credencial/$credencial');
      _log('📤 GET $url', rid: rid);

      final response = await http.get(url, headers: {'Accept': 'application/json'}).timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 200) {
        return _tryJson(response.body, rid: rid);
      }

      if (response.statusCode == 404) {
        final data = _tryJson(response.body, rid: rid);
        _errorMessage = data?['mensaje']?.toString() ?? 'Usuario no encontrado.';
        return null;
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = data?['mensaje']?.toString() ?? 'Error al obtener usuario.';
      return null;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout obtenerUsuarioPorCredencial', rid: rid);
      return null;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red obtenerUsuarioPorCredencial: $e', rid: rid);
      return null;
    } catch (e) {
      _errorMessage = 'Error en obtener usuario por credencial: $e';
      _log('❌ Error en obtener usuario por credencial: $e', rid: rid);
      return null;
    }
  }

  Future<Map<String, dynamic>?> obtenerUsuarioPorId(String usuarioId) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return null;
    }

    try {
      final url = Uri.parse('$usuarioBaseUrl/$usuarioId');
      _log('📤 GET $url', rid: rid);

      final response = await http.get(url, headers: {'Accept': 'application/json'}).timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 200) {
        return _tryJson(response.body, rid: rid);
      }

      if (response.statusCode == 404) {
        final data = _tryJson(response.body, rid: rid);
        _errorMessage = data?['mensaje']?.toString() ?? 'Usuario no encontrado.';
        return null;
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = data?['mensaje']?.toString() ?? 'Error al obtener usuario.';
      return null;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout obtenerUsuarioPorId', rid: rid);
      return null;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red obtenerUsuarioPorId: $e', rid: rid);
      return null;
    } catch (e) {
      _errorMessage = 'Error en obtener usuario por ID: $e';
      _log('❌ Error en obtener usuario por ID: $e', rid: rid);
      return null;
    }
  }

  Future<Map<String, dynamic>?> actualizarUsuarioCompleto({
    required String usuarioId,
    String? nombre,
    String? direccion,
    String? telefono,
    String? imagenPerfilPath,
  }) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return null;
    }

    try {
      final token = await _getToken(rid: rid);
      final url = Uri.parse('$usuarioBaseUrl/$usuarioId');
      _log('📤 PUT $url', rid: rid);

      http.Response response;
      if (imagenPerfilPath != null) {
        _log('Usando multipart con imagen: $imagenPerfilPath', rid: rid);
        final request = http.MultipartRequest('PUT', url);
        request.headers['Authorization'] = 'Bearer $token';
        if (nombre != null) request.fields['nombre'] = nombre.trim();
        if (direccion != null) request.fields['direccion'] = direccion.trim();
        if (telefono != null) request.fields['telefono'] = telefono.trim();
        request.files.add(await http.MultipartFile.fromPath('imagen', imagenPerfilPath));

        final streamedResponse = await request.send().timeout(_timeoutLong);
        final body = await streamedResponse.stream.bytesToString();
        _log('📥 Status: ${streamedResponse.statusCode}', rid: rid);
        _logLarge('Body', body, rid: rid);
        response = http.Response(body, streamedResponse.statusCode);
      } else {
        final payload = <String, String>{
          if (nombre != null) 'nombre': nombre.trim(),
          if (direccion != null) 'direccion': direccion.trim(),
          if (telefono != null) 'telefono': telefono.trim(),
        };
        _log('Payload: $payload', rid: rid);
        response = await http
            .put(url, headers: _jsonHeaders(token: token), body: jsonEncode(payload))
            .timeout(_timeoutShort);
        _log('📥 Status: ${response.statusCode}', rid: rid);
        _logLarge('Body', response.body, rid: rid);
      }

      if (response.statusCode == 200) {
        return _tryJson(response.body, rid: rid);
      }

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = (response.statusCode == 401)
          ? 'no_autorizado'
          : (data?['mensaje']?.toString() ?? 'Error al actualizar usuario.');
      return null;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout actualizarUsuarioCompleto', rid: rid);
      return null;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red actualizarUsuarioCompleto: $e', rid: rid);
      return null;
    } catch (e) {
      _errorMessage = 'Error en actualizar usuario: $e';
      _log('❌ Error en actualizar usuario: $e', rid: rid);
      return null;
    }
  }

  Future<bool> eliminarUsuario(String usuarioId) async {
    _errorMessage = null;
    final rid = _newRid();

    if (!await _tieneConexion()) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Sin conexión', rid: rid);
      return false;
    }

    try {
      final token = await _getToken(rid: rid);
      final url = Uri.parse('$usuarioBaseUrl/$usuarioId');
      _log('📤 DELETE $url', rid: rid);

      final response = await http
          .delete(url, headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          })
          .timeout(_timeoutShort);

      _log('📥 Status: ${response.statusCode}', rid: rid);
      _logLarge('Body', response.body, rid: rid);

      if (response.statusCode == 200) return true;

      final data = _tryJson(response.body, rid: rid);
      _errorMessage = (response.statusCode == 401)
          ? 'no_autorizado'
          : (data?['mensaje']?.toString() ?? 'Error al eliminar usuario.');
      return false;
    } on TimeoutException {
      _errorMessage = 'timeout';
      _log('⏳ Timeout eliminarUsuario', rid: rid);
      return false;
    } on SocketException catch (e) {
      _errorMessage = 'sin_conexion';
      _log('🌐 Error de red eliminarUsuario: $e', rid: rid);
      return false;
    } catch (e) {
      _errorMessage = 'Error en eliminar usuario: $e';
      _log('❌ Error en eliminar usuario: $e', rid: rid);
      return false;
    }
  }
}