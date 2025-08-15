import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  final String baseUrl = '${dotenv.env['API_URL']}/auth';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _errorMessage;
  String? get message => _errorMessage;

  late final GoogleSignIn _googleSignIn;

  AuthService() {
    // 📌 Siempre usar Client ID Web, incluso en Android/iOS para validación en backend
    final clientIdWeb = dotenv.env['GOOGLE_CLIENT_ID_WEB'];

    _googleSignIn = GoogleSignIn(
      clientId: clientIdWeb,
      scopes: ['email', 'profile'],
    );

    print("✅ BASE URL: $baseUrl");
    print("✅ GOOGLE CLIENT ID USADO (WEB): $clientIdWeb");
  }

  // -------------------------------
  // LOGIN CLÁSICO
  // -------------------------------
  Future<bool> login(String email, String password) async {
    _errorMessage = null;

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = "Email y contraseña son obligatorios.";
      return false;
    }

    try {
      final url = Uri.parse('$baseUrl/login');
      print("🚀 Login URL: $url");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email.trim(),
          "password": password.trim(),
        }),
      );

      print("🔐 LOGIN STATUS: ${response.statusCode}");
      print("📦 LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _guardarCredenciales(data);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Correo o contraseña incorrectos.';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Error de conexión: $e';
      return false;
    }
  }

  // -------------------------------
  // LOGIN CON GOOGLE
  // -------------------------------
  Future<bool> loginConGoogle() async {
    _errorMessage = null;

    try {
      await _googleSignIn.signOut();
      final cuenta = await _googleSignIn.signIn();

      if (cuenta == null) {
        return false; // Usuario canceló
      }

      final auth = await cuenta.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        _errorMessage = "No se pudo obtener el token de Google.";
        return false;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/google'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"idToken": idToken}),
      );

      print("🔐 GOOGLE LOGIN STATUS: ${response.statusCode}");
      print("📦 GOOGLE LOGIN BODY: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return await _guardarCredenciales(data);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'No se pudo iniciar sesión con Google.';
        return false;
      }
    } catch (e) {
      _errorMessage = "Error de Google Login: $e";
      return false;
    }
  }

  // -------------------------------
  // REGISTRO
  // -------------------------------
  Future<bool> register(String nombre, String email, String password) async {
    _errorMessage = null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre.trim(),
          "email": email.trim(),
          "password": password.trim(),
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return await _guardarCredenciales(data);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Error al registrar usuario.';
        return false;
      }
    } catch (e) {
      _errorMessage = "Error al registrar: $e";
      return false;
    }
  }

  // -------------------------------
  // GUARDAR CREDENCIALES
  // -------------------------------
  Future<bool> _guardarCredenciales(Map<String, dynamic> data) async {
    try {
      final token = data['token'] ?? data['accessToken'] ?? '';
      if (token.isEmpty) throw Exception("Token vacío");

      await _secureStorage.write(key: 'accessToken', value: token);

      if (data.containsKey('refreshToken')) {
        await _secureStorage.write(key: 'refreshToken', value: data['refreshToken']);
      }

      final usuario = data['usuario'] ?? {};
      await _secureStorage.write(key: 'rol', value: usuario['rol'] ?? '');
      await _secureStorage.write(key: 'nombre', value: usuario['nombre'] ?? '');
      await _secureStorage.write(key: 'email', value: usuario['email'] ?? '');
      await _secureStorage.write(key: 'foto', value: usuario['foto'] ?? '');

      return true;
    } catch (e) {
      _errorMessage = "Error al guardar credenciales: $e";
      return false;
    }
  }

  // -------------------------------
  // RENOVAR TOKEN
  // -------------------------------
  Future<String?> renovarToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nuevoAccessToken = data['accessToken'] ?? data['token'];

        if (nuevoAccessToken != null && nuevoAccessToken is String) {
          await guardarAccessToken(nuevoAccessToken);
          return nuevoAccessToken;
        }
        return null;
      } else {
        _errorMessage = "Token expirado";
        return null;
      }
    } catch (e) {
      _errorMessage = "Error al renovar token: $e";
      return null;
    }
  }

  Future<void> guardarAccessToken(String token) async {
    await _secureStorage.write(key: 'accessToken', value: token);
  }

  // -------------------------------
  // CERRAR SESIÓN
  // -------------------------------
  Future<void> logout() async {
    await _secureStorage.deleteAll();
    await _googleSignIn.signOut();
  }

  // -------------------------------
  // GETTERS
  // -------------------------------
  Future<String?> getAccessToken() => _secureStorage.read(key: 'accessToken');
  Future<String?> getRefreshToken() => _secureStorage.read(key: 'refreshToken');
  Future<String?> getRol() => _secureStorage.read(key: 'rol');
  Future<String?> getNombre() => _secureStorage.read(key: 'nombre');
  Future<String?> getEmail() => _secureStorage.read(key: 'email');
  Future<String?> getFoto() => _secureStorage.read(key: 'foto');

  // -------------------------------
  // VERIFICAR EMAIL EXISTENTE
  // -------------------------------
  Future<bool?> verificarEmailExiste(String email) async {
    _errorMessage = null;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/email-existe'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['existe'] ?? false;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Error al verificar correo.';
        return null;
      }
    } catch (e) {
      _errorMessage = "Error al verificar correo: $e";
      return null;
    }
  }
}
