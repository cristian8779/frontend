import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RolService {
  final String _baseUrl = '${dotenv.env['API_URL']}/rol';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _token;

  /// 🔒 Sanitizar información sensible
  String _sanitize(String value, {int visibleChars = 3}) {
    if (value.isEmpty) return '***';
    if (value.length <= visibleChars) return '***';
    return '${value.substring(0, visibleChars)}***';
  }

  /// 🔒 Sanitizar email
  String _sanitizeEmail(String email) {
    if (!email.contains('@')) return _sanitize(email);
    final parts = email.split('@');
    return '${_sanitize(parts[0], visibleChars: 2)}@${parts[1]}';
  }

  /// 🔒 Sanitizar token JWT
  String _sanitizeToken(String? token) {
    if (token == null || token.isEmpty) return '[NO_TOKEN]';
    if (token.length < 20) return '***';
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  /// ✅ Headers base para peticiones
  Map<String, String> _getHeaders(String? token) {
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  /// 🔄 Obtener access token del almacenamiento
  Future<String?> _getAccessToken() async {
    if (_token == null) {
      _token = await _secureStorage.read(key: 'accessToken');
    }
    return _token;
  }

  /// 🔄 Renovar token usando refresh token
  Future<bool> _renovarToken() async {
    try {
      print("🔄 [RolService] Intentando renovar token");
      
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) {
        print("❌ [RolService] No hay refresh token disponible");
        return false;
      }

      print("📡 [RolService] Solicitando renovación de token");

      final response = await http.post(
        Uri.parse('${dotenv.env['API_URL']}/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      print("📥 [RolService] Respuesta renovación - Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _secureStorage.write(key: 'accessToken', value: data['accessToken']);
        _token = data['accessToken'];
        print("✅ [RolService] Token renovado exitosamente");
        return true;
      } else {
        print("❌ [RolService] Error al renovar token");
        return false;
      }
    } catch (e) {
      print("❌ [RolService] Excepción al renovar token: ${e.toString()}");
      return false;
    }
  }

  /// 🔑 Recuperar token válido con renovación automática
  Future<String> _obtenerTokenValido() async {
    try {
      String? token = await _getAccessToken();

      if (token == null) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      }

      // Verificar si el token es válido haciendo una petición de prueba
      final testUrl = Uri.parse('$_baseUrl/pendiente');
      final testResponse = await http.get(
        testUrl,
        headers: _getHeaders(token),
      );

      // Si el token está expirado (401), intentar renovarlo
      if (testResponse.statusCode == 401) {
        print("⚠️ [RolService] Token expirado, renovando...");
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
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception("Error de autenticación: ${e.toString()}");
    }
  }

  /// 📩 Enviar invitación de cambio de rol (Solo SuperAdmin)
  Future<Map<String, dynamic>> invitarCambioRol(String email, String nuevoRol) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/invitar');

      print("📩 [RolService] Enviando invitación");
      print("   • Email: ${_sanitizeEmail(email)}");
      print("   • Nuevo rol: $nuevoRol");

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({
          "email": email,
          "nuevoRol": nuevoRol,
        }),
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta invitar - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ [RolService] Invitación enviada exitosamente");
        return {
          "success": true, 
          "mensaje": data["mensaje"],
          "email": data["email"],
          "nuevoRol": data["nuevoRol"],
          "expiracion": data["expiracion"]
        };
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 403) {
        throw Exception("No tienes permisos para realizar esta acción.");
      } else if (response.statusCode == 404) {
        throw Exception("Usuario no encontrado con ese correo electrónico.");
      } else if (response.statusCode == 400) {
        throw Exception(data["mensaje"] ?? "Datos inválidos para la invitación.");
      } else if (response.statusCode == 409) {
        throw Exception("Este usuario ya tiene una invitación pendiente.");
      } else {
        throw Exception(data["mensaje"] ?? "Error al enviar invitación.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en invitarCambioRol: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 🔑 Confirmar código de invitación
  Future<Map<String, dynamic>> confirmarCodigoRol(String codigo) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/confirmar');

      print("🔑 [RolService] Confirmando código de invitación");
      print("   • Código: ${_sanitize(codigo, visibleChars: 2)}");

      final response = await http.post(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({"codigo": codigo}),
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta confirmar - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ [RolService] Código confirmado exitosamente");
        return {"success": true, "mensaje": data["mensaje"]};
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 404) {
        throw Exception("Código inválido o no coincide con tu invitación.");
      } else if (response.statusCode == 400) {
        throw Exception(data["mensaje"] ?? "Código expirado o inválido.");
      } else if (response.statusCode == 502) {
        throw Exception("No se pudo confirmar el cambio de rol. Intenta nuevamente.");
      } else {
        throw Exception(data["mensaje"] ?? "Error al confirmar código.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en confirmarCodigoRol: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// ⏳ Verificar invitación pendiente
  Future<Map<String, dynamic>> verificarInvitacionPendiente() async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/pendiente');

      print("⏳ [RolService] Verificando invitación pendiente");

      final response = await http.get(
        url, 
        headers: _getHeaders(token)
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta pendiente - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final pendiente = data["pendiente"] ?? false;
        print(pendiente 
          ? "✅ [RolService] Invitación pendiente encontrada" 
          : "ℹ️ [RolService] No hay invitaciones pendientes");
        
        return {
          "success": true, 
          "pendiente": pendiente,
          "email": data["email"], 
          "nuevoRol": data["nuevoRol"],
          "expiracion": data["expiracion"],
          "mensaje": data["mensaje"]
        };
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else {
        throw Exception(data["mensaje"] ?? "Error al verificar invitación.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en verificarInvitacionPendiente: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 🚫 Rechazar invitación de cambio de rol
  Future<Map<String, dynamic>> rechazarInvitacion() async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/rechazar');

      print("🚫 [RolService] Rechazando invitación");

      final response = await http.post(
        url, 
        headers: _getHeaders(token)
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta rechazar - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ [RolService] Invitación rechazada exitosamente");
        return {"success": true, "mensaje": data["mensaje"]};
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 404) {
        throw Exception("No tienes invitaciones pendientes.");
      } else {
        throw Exception(data["mensaje"] ?? "Error al rechazar invitación.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en rechazarInvitacion: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 📜 Listar todas las invitaciones (Solo SuperAdmin)
  Future<Map<String, dynamic>> listarInvitaciones() async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/invitaciones');

      print("📜 [RolService] Listando invitaciones");

      final response = await http.get(
        url, 
        headers: _getHeaders(token)
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta listar - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final invitaciones = data["invitaciones"] ?? [];
        print("✅ [RolService] ${invitaciones.length} invitaciones encontradas");
        return {"success": true, "invitaciones": invitaciones};
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 403) {
        throw Exception("No tienes permisos para ver las invitaciones.");
      } else {
        throw Exception(data["mensaje"] ?? "Error al cargar invitaciones.");
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en listarInvitaciones: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 🚫 Cancelar invitación específica por SuperAdmin
  Future<Map<String, dynamic>> cancelarInvitacionPorSuperAdmin(String email) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/cancelar/$email');

      print("🚫 [RolService] Cancelando invitación");
      print("   • Email: ${_sanitizeEmail(email)}");

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta cancelar - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ [RolService] Invitación cancelada exitosamente");
        return {
          'success': true,
          'mensaje': data['mensaje'] ?? 'Invitación cancelada exitosamente',
        };
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 404) {
        throw Exception("No se encontró invitación pendiente para este usuario.");
      } else if (response.statusCode == 403) {
        throw Exception("No tienes permisos para cancelar invitaciones.");
      } else {
        throw Exception(data['mensaje'] ?? 'Error al cancelar la invitación.');
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en cancelarInvitacionPorSuperAdmin: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 🚨 Eliminar TODAS las invitaciones (solo SuperAdmin con confirmación de seguridad)
  Future<Map<String, dynamic>> eliminarTodasLasInvitaciones(String confirmacion) async {
    try {
      final token = await _obtenerTokenValido();
      final url = Uri.parse('$_baseUrl/invitaciones/todas');

      print("⚠️ [RolService] Eliminando todas las invitaciones");
      print("   • Confirmación recibida: ${confirmacion == 'ELIMINAR TODO' ? '✓' : '✗'}");

      final response = await http.delete(
        url,
        headers: _getHeaders(token),
        body: jsonEncode({"confirmacion": confirmacion}),
      ).timeout(const Duration(seconds: 15));

      print("📥 [RolService] Respuesta eliminar todas - Status: ${response.statusCode}");

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print("✅ [RolService] Todas las invitaciones eliminadas");
        return {
          'success': true,
          'mensaje': data['mensaje'] ?? 'Todas las invitaciones han sido eliminadas',
        };
      } else if (response.statusCode == 401) {
        throw Exception("Sesión expirada. Por favor, inicia sesión nuevamente.");
      } else if (response.statusCode == 400) {
        throw Exception("Debes escribir exactamente 'ELIMINAR TODO' para confirmar.");
      } else if (response.statusCode == 403) {
        throw Exception("Solo el SuperAdmin puede eliminar todas las invitaciones.");
      } else {
        throw Exception(data['mensaje'] ?? 'Error al eliminar invitaciones.');
      }
    } on SocketException {
      throw Exception("Sin conexión a Internet. Verifica tu conexión.");
    } on FormatException {
      throw Exception("Respuesta inválida del servidor.");
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      print("❌ [RolService] Error en eliminarTodasLasInvitaciones: ${e.toString()}");
      throw Exception("Error de conexión: $e");
    }
  }

  /// 🔄 Verificar si el token es válido
  Future<bool> verificarToken() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      return token != null && token.isNotEmpty;
    } catch (e) {
      print("❌ [RolService] Error al verificar token: ${e.toString()}");
      return false;
    }
  }

  /// 🚪 Limpiar tokens (para logout)
  Future<void> limpiarToken() async {
    try {
      await _secureStorage.delete(key: 'accessToken');
      await _secureStorage.delete(key: 'refreshToken');
      _token = null;
      print("✅ [RolService] Tokens limpiados exitosamente");
    } catch (e) {
      print("❌ [RolService] Error al limpiar tokens: ${e.toString()}");
    }
  }
}