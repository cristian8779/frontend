import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SuperAdminService {
  // ✅ Base URL corregida
  final String _baseUrl = '${dotenv.env['API_URL']}/rol/superadmin';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  /// ✅ Headers base
  Map<String, String> _getHeaders(String? token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// 🔄 Obtener access token
  Future<String?> _getAccessToken() async {
    if (_token == null) {
      _token = await _secureStorage.read(key: 'accessToken');
    }
    return _token;
  }

  /// 🔄 Renovar token con refresh
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

  /// 🔑 Obtener token válido
  Future<String> _obtenerTokenValido() async {
    try {
      String? token = await _getAccessToken();

      if (token == null) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      }

      final testUrl = Uri.parse('$_baseUrl/pendiente');
      final testResponse = await http.get(testUrl, headers: _getHeaders(token));

      if (testResponse.statusCode == 401) {
        final renovado = await _renovarToken();
        if (renovado) {
          token = await _getAccessToken();
          if (token == null) {
            throw Exception("Error al renovar el token de sesión.");
          }
        } else {
          throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
        }
      }

      return token;
    } catch (e) {
      if (e.toString().contains('Exception:')) rethrow;
      throw Exception("Error de autenticación: ${e.toString()}");
    }
  }

  /// 📩 1. Iniciar transferencia de SuperAdmin
  Future<Map<String, dynamic>> transferirSuperAdmin(String email) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/transferir');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({"email": email}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "mensaje": data["mensaje"],
          "expiracion": data["expiracion"],
        };
      } else {
        throw Exception(data["mensaje"] ?? "Error al transferir SuperAdmin.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet.");
    }
  }

  /// 🔑 2. Confirmar transferencia
  Future<Map<String, dynamic>> confirmarTransferencia(String codigo) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/confirmar');

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({"codigo": codigo}),
      ).timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "mensaje": data["mensaje"]};
      } else {
        throw Exception(data["mensaje"] ?? "Error al confirmar transferencia.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet.");
    }
  }

  /// 🚫 3. Rechazar transferencia
  Future<Map<String, dynamic>> rechazarTransferencia() async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/rechazar');

      final response = await http.post(url, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {"success": true, "mensaje": data["mensaje"]};
      } else {
        throw Exception(data["mensaje"] ?? "Error al rechazar transferencia.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet.");
    }
  }

  /// ⏳ 4. Verificar transferencia pendiente
  Future<Map<String, dynamic>> verificarTransferenciaPendiente() async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/pendiente');

      final response = await http.get(url, headers: _getHeaders(token))
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {
          "success": true,
          "pendiente": data["pendiente"] ?? false,
          "expiracion": data["expiracion"],
          "solicitante": data["solicitante"],
          "mensaje": data["mensaje"],
        };
      } else {
        throw Exception(data["mensaje"] ?? "Error al verificar transferencia.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet.");
    }
  }
}
