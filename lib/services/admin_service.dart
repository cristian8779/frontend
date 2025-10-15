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

  // -------------------------------
  // UTILIDAD PARA ENMASCARAR DATOS
  // -------------------------------
  String _enmascararId(String? id) {
    if (id == null || id.isEmpty) return 'VACIO';
    if (id.length <= 8) return '***';
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  String _enmascararEmail(String? email) {
    if (email == null || email.isEmpty) return 'VACIO';
    final partes = email.split('@');
    if (partes.length != 2) return '***@***';
    final usuario = partes[0].length > 2 
        ? '${partes[0].substring(0, 2)}***' 
        : '***';
    return '$usuario@${partes[1]}';
  }

  Map<String, dynamic> _limpiarDatosSensibles(Map<String, dynamic> data) {
    final limpio = Map<String, dynamic>.from(data);
    
    // Enmascarar campos sensibles comunes
    if (limpio.containsKey('email')) {
      limpio['email'] = _enmascararEmail(limpio['email']);
    }
    if (limpio.containsKey('_id')) {
      limpio['_id'] = _enmascararId(limpio['_id']);
    }
    if (limpio.containsKey('id')) {
      limpio['id'] = _enmascararId(limpio['id']);
    }
    
    // Remover tokens y contraseñas
    limpio.remove('token');
    limpio.remove('accessToken');
    limpio.remove('refreshToken');
    limpio.remove('password');
    limpio.remove('contrasena');
    
    return limpio;
  }

  List<dynamic> _limpiarListaDatos(List<dynamic> lista) {
    return lista.map((item) {
      if (item is Map<String, dynamic>) {
        return _limpiarDatosSensibles(item);
      }
      return item;
    }).toList();
  }

  /// Listar todos los administradores
  Future<Map<String, dynamic>> listarAdmins() async {
    final url = Uri.parse('$_baseUrl/admins');

    print('🔍 Obteniendo lista de administradores');

    http.Response response = await _getConToken(url, token);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final admins = data['admins'] ?? [];
      
      print('✅ Administradores obtenidos: ${admins.length} registros');
      
      // Log seguro con datos enmascarados
      if (admins.isNotEmpty && admins is List) {
        print('🔍 Ejemplo de admin (datos enmascarados): ${_limpiarDatosSensibles(admins[0])}');
      }

      return {
        'ok': true,
        'data': admins,
      };
    } else {
      print('❌ Error al obtener administradores (${response.statusCode})');
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

    print('🗑️ Eliminando administrador: ${_enmascararId(id)}');

    http.Response response = await _deleteConToken(url, token);

    if (response.statusCode == 200) {
      print('✅ Administrador eliminado exitosamente');
      return true;
    } else {
      print('❌ Error al eliminar administrador (${response.statusCode})');
      return false;
    }
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