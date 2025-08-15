import 'dart:convert';
import 'package:http/http.dart' as http;

class AdminService {
  String token; // Access Token que puede cambiar si se renueva
  final void Function(String nuevoToken)? onTokenRenovado; // Callback para actualizar token global
  final String _baseUrl = 'https://api.soportee.store/api/admin';
  final String baseUrl = 'https://api.soportee.store/api'; // Base para auth

  AdminService({
    required this.token,
    this.onTokenRenovado,
  });

  /// Listar todos los administradores
  Future<Map<String, dynamic>> listarAdmins() async {
    final url = Uri.parse('$_baseUrl/admins');

    http.Response response = await _getConToken(url, token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'ok': true,
        'data': data['admins'] ?? [],
      };
    } else {
      final data = _parseError(response.body);
      return {
        'ok': false,
        'mensaje': data['mensaje'] ?? 'Error al obtener administradores.',
      };
    }
  }

  /// Eliminar un administrador por ID
  Future<bool> eliminarAdmin(String id) async {
    final url = Uri.parse('$_baseUrl/admins/$id');

    http.Response response = await _deleteConToken(url, token);

    return response.statusCode == 200;
  }

  Future<http.Response> _getConToken(Uri url, String token) {
    return http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  Future<http.Response> _deleteConToken(Uri url, String token) {
    return http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
  }

  Map<String, dynamic> _parseError(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return {};
    }
  }
}
