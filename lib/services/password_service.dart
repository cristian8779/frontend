import 'dart:convert';
import 'package:http/http.dart' as http;

class PasswordService {
  final String baseUrl = 'https://api.soportee.store/api/password';
  String? message;

  // Enviar código al correo
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      );

      print("📨 Recuperar contraseña: ${response.body}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "No pudimos enviar el código.";
        return false;
      }
    } catch (e) {
      message = "Error al enviar código: $e";
      print(message);
      return false;
    }
  }

  // Verificar código enviado al correo
  Future<bool> verificarCodigo(String email, String codigo) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verificar-codigo'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "codigo": codigo.trim(),
        }),
      );

      print("🧩 Verificar código: ${response.body}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "Código inválido o expirado.";
        return false;
      }
    } catch (e) {
      message = "Error al verificar el código: $e";
      print(message);
      return false;
    }
  }

  // Restablecer la contraseña (requiere email, código y nueva contraseña)
  Future<bool> resetPassword(String email, String codigo, String nuevaPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),               // ✅ requerido por el backend
          "codigo": codigo.trim(),             // ✅ requerido por el backend
          "nuevaPassword": nuevaPassword.trim()// ✅ requerido por el backend
        }),
      );

      print("🔁 Reset password response: ${response.body}");

      if (response.statusCode == 200) {
        final data = _decodeResponse(response.body);
        message = data['mensaje'];
        return true;
      } else {
        final data = _decodeResponse(response.body);
        message = data['mensaje'] ?? "No se pudo cambiar la contraseña.";
        return false;
      }
    } catch (e) {
      message = "Error al restablecer contraseña: $e";
      print(message);
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
