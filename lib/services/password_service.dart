import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordService {
  final String baseUrl = 'https://api.soportee.store/api/password';
  String? message;

  /// Oculta información sensible en los logs
  String _sanitize(String value, {int visibleChars = 3}) {
    if (value.isEmpty) return '***';
    if (value.length <= visibleChars) return '***';
    return '${value.substring(0, visibleChars)}***';
  }

  /// Oculta email mostrando solo inicio y dominio
  String _sanitizeEmail(String email) {
    if (!email.contains('@')) return _sanitize(email);
    final parts = email.split('@');
    return '${_sanitize(parts[0], visibleChars: 2)}@${parts[1]}';
  }

  // Enviar código al correo
  Future<bool> sendPasswordResetEmail(String email) async {
    print("📨 Solicitando código de recuperación");
    print("   • Email: ${_sanitizeEmail(email.trim())}");
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      );

      print("📥 Respuesta recibida - Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        print("✅ Código enviado exitosamente");
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "No pudimos enviar el código.";
        print("❌ Error al enviar código - Status: ${response.statusCode}");
        if (data['mensaje'] != null) {
          print("   • Mensaje: ${data['mensaje']}");
        }
        return false;
      }
    } catch (e) {
      message = "Error al enviar código: $e";
      print("❌ Excepción en sendPasswordResetEmail: ${e.toString()}");
      return false;
    }
  }

  // Verificar código enviado al correo
  Future<bool> verificarCodigo(String email, String codigo) async {
    print("🧩 Verificando código de recuperación");
    print("   • Email: ${_sanitizeEmail(email.trim())}");
    print("   • Código: ${_sanitize(codigo.trim(), visibleChars: 2)}");
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-codigo'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "codigo": codigo.trim(),
        }),
      );

      print("📥 Respuesta recibida - Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        print("✅ Código verificado correctamente");
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "Código inválido o expirado.";
        print("❌ Error en verificación - Status: ${response.statusCode}");
        if (data['mensaje'] != null) {
          print("   • Mensaje: ${data['mensaje']}");
        }
        return false;
      }
    } catch (e) {
      message = "Error al verificar el código: $e";
      print("❌ Excepción en verificarCodigo: ${e.toString()}");
      return false;
    }
  }

  // Restablecer la contraseña (requiere email, código y nueva contraseña)
  Future<bool> resetPassword(String email, String codigo, String nuevaPassword) async {
    print("🔁 Restableciendo contraseña");
    print("   • Email: ${_sanitizeEmail(email.trim())}");
    print("   • Código: ${_sanitize(codigo.trim(), visibleChars: 2)}");
    print("   • Nueva contraseña: [OCULTA - ${nuevaPassword.trim().length} caracteres]");
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "codigo": codigo.trim(),
          "nuevaPassword": nuevaPassword.trim()
        }),
      );

      print("📥 Respuesta recibida - Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        print("✅ Contraseña restablecida exitosamente");
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "No se pudo cambiar la contraseña.";
        print("❌ Error al restablecer - Status: ${response.statusCode}");
        if (data['mensaje'] != null) {
          print("   • Mensaje: ${data['mensaje']}");
        }
        return false;
      }
    } catch (e) {
      message = "Error al restablecer contraseña: $e";
      print("❌ Excepción en resetPassword: ${e.toString()}");
      return false;
    }
  }

  // Función auxiliar para decodificar JSON de forma segura
  Map<String, dynamic> _decodeResponse(String body) {
    try {
      return body.isNotEmpty ? jsonDecode(body) as Map<String, dynamic> : {};
    } catch (_) {
      return {};
    }
  }
}