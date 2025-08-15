import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class AuthHttpClient {
  final http.Client _client = http.Client();
  final AuthService _authService = AuthService();

  // GET con token
  Future<http.Response> get(Uri url) async {
    return await _withAuth(() => _client.get(url, headers: await _headers()));
  }

  // POST con token
  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    return await _withAuth(() => _client.post(
          url,
          headers: await _headers(extraHeaders: headers),
          body: body,
        ));
  }

  // PUT con token
  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    return await _withAuth(() => _client.put(
          url,
          headers: await _headers(extraHeaders: headers),
          body: body,
        ));
  }

  // DELETE con token
  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) async {
    return await _withAuth(() => _client.delete(
          url,
          headers: await _headers(extraHeaders: headers),
          body: body,
        ));
  }

  // Generar headers con token
  Future<Map<String, String>> _headers({Map<String, String>? extraHeaders}) async {
    final token = await _authService.getAccessToken();
    final baseHeaders = {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    if (extraHeaders != null) {
      baseHeaders.addAll(extraHeaders);
    }

    return baseHeaders;
  }

  // Manejo automático de token expirado
  Future<http.Response> _withAuth(Future<http.Response> Function() requestFn) async {
    http.Response response = await requestFn();

    if (response.statusCode == 401 || response.statusCode == 403) {
      print("🔐 Token expirado. Intentando renovar...");

      final renewed = await _authService.renovarToken();

      if (renewed) {
        print("✅ Token renovado. Reintentando petición...");
        response = await requestFn();
      } else {
        print("❌ No se pudo renovar el token. Cerrando sesión...");
        await _authService.logout();
        throw Exception("Tu sesión ha expirado. Por favor, vuelve a iniciar sesión.");
      }
    }

    return response;
  }

  // Cierra el cliente HTTP cuando ya no se necesita
  void close() {
    _client.close();
  }
}
