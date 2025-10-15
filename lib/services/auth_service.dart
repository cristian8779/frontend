import 'dart:convert';
import 'dart:io' show SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final String apiUrl = dotenv.env['API_URL'] ?? '';
  final String authUrl = '${dotenv.env['API_URL']}/auth';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String? _errorMessage;
  String? get message => _errorMessage;

  late final GoogleSignIn _googleSignIn;

  // Guardar la CUENTA de Google, no solo el token
  GoogleSignInAccount? _googleAccountPendiente;

  AuthService() {
    final clientIdWeb = dotenv.env['GOOGLE_CLIENT_ID_WEB'];

    _googleSignIn = GoogleSignIn(
      clientId: clientIdWeb,
      scopes: ['email', 'profile'],
    );

    print("API URL: $apiUrl");
    print("AUTH URL: $authUrl");
    print("GOOGLE CLIENT ID configurado: ${clientIdWeb != null ? 'SI' : 'NO'}");
  }

  // -------------------------------
  // UTILIDADES DE ENMASCARAMIENTO
  // -------------------------------
  String _enmascararEmail(String? email) {
    if (email == null || email.isEmpty) return 'VACIO';
    final partes = email.split('@');
    if (partes.length != 2) return '***@***';
    final usuario = partes[0].length > 2 
        ? '${partes[0].substring(0, 2)}***' 
        : '***';
    return '$usuario@${partes[1]}';
  }

  String _enmascarar(String? texto) {
    if (texto == null || texto.isEmpty) return 'VACIO';
    if (texto.length <= 4) return '***';
    return '${texto.substring(0, 2)}...${texto.substring(texto.length - 2)}';
  }

  // -------------------------------
  // VERIFICACION DE CONECTIVIDAD
  // -------------------------------
  Future<bool> _tieneConexion() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  // -------------------------------
  // LOGIN CLASICO
  // -------------------------------
  Future<bool> login(String email, String password) async {
    _errorMessage = null;

    if (email.isEmpty || password.isEmpty) {
      _errorMessage = "Email y contraseña son obligatorios.";
      return false;
    }

    if (!await _tieneConexion()) {
      _errorMessage = "sin_conexion";
      return false;
    }

    try {
      final url = Uri.parse('$authUrl/login');
      print("Login URL: $url");
      print("Intentando login para: ${_enmascararEmail(email)}");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim(), "password": password.trim()}),
      ).timeout(const Duration(seconds: 15));

      print("LOGIN STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Login exitoso");
        return await _guardarCredenciales(data);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Correo o contraseña incorrectos.';
        return false;
      }
    } on SocketException catch (e) {
      print("SocketException en login: $e");
      _errorMessage = "sin_conexion";
      return false;
    } on http.ClientException catch (e) {
      print("ClientException en login: $e");
      _errorMessage = "error_red";
      return false;
    } catch (e) {
      print("Error en login: $e");
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _errorMessage = "timeout";
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Network is unreachable')) {
        _errorMessage = "sin_conexion";
      } else {
        _errorMessage = 'Error de conexion: $e';
      }
      return false;
    }
  }

  // -------------------------------
  // OBTENER TOKEN FRESCO DE GOOGLE
  // -------------------------------
  Future<String?> _obtenerTokenFrescoDeGoogle() async {
    try {
      if (_googleAccountPendiente == null) {
        print('[_obtenerTokenFrescoDeGoogle] No hay cuenta de Google guardada');
        return null;
      }

      final auth = await _googleAccountPendiente!.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        print('[_obtenerTokenFrescoDeGoogle] No se pudo obtener token fresco');
        return null;
      }

      print('[_obtenerTokenFrescoDeGoogle] Token fresco obtenido de Google');
      return idToken;
    } catch (e, st) {
      print('[_obtenerTokenFrescoDeGoogle] Error obteniendo token fresco: $e');
      print(st);
      return null;
    }
  }

  // -------------------------------
  // LOGIN CON GOOGLE (CON TOKEN FRESCO)
  // -------------------------------
  Future<bool> loginConGoogle({bool terminosAceptados = false}) async {
    _errorMessage = null;

    if (!await _tieneConexion()) {
      _errorMessage = "sin_conexion";
      return false;
    }

    try {
      if (!terminosAceptados && _googleAccountPendiente == null) {
        print("[loginConGoogle] No hay cuenta previa, haciendo signIn()");
        await _googleSignIn.signOut();
        final cuenta = await _googleSignIn.signIn();

        if (cuenta == null) {
          print("[loginConGoogle] Usuario canceló el login de Google");
          _errorMessage = "Inicio de sesion cancelado";
          return false;
        }

        _googleAccountPendiente = cuenta;
        print('[loginConGoogle] Cuenta de Google guardada: ${_enmascararEmail(cuenta.email)}');
      }

      if (_googleAccountPendiente == null) {
        print("[loginConGoogle] ERROR: _googleAccountPendiente sigue null");
        _errorMessage = "No hay cuenta de Google disponible";
        return false;
      }

      final tokenFresco = await _obtenerTokenFrescoDeGoogle();
      if (tokenFresco == null) {
        _errorMessage = "No se pudo obtener token de autenticacion";
        _googleAccountPendiente = null;
        return false;
      }

      print('[loginConGoogle] Enviando al backend con terminosAceptados=$terminosAceptados');

      final googleLoginUrl = '$authUrl/google';
      print('[loginConGoogle] URL endpoint: $googleLoginUrl');

      final body = {
        "idToken": tokenFresco,
        "terminosAceptados": terminosAceptados,
      };
      
      // DEBUG: Verificar estructura del token (sin mostrar contenido)
      try {
        final parts = tokenFresco.split('.');
        print('[loginConGoogle] Token tiene ${parts.length} partes (estructura válida: ${parts.length == 3})');
      } catch (e) {
        print('[loginConGoogle] Error al validar estructura del token: $e');
      }

      final response = await http.post(
        Uri.parse(googleLoginUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      print("[loginConGoogle] RESPONSE STATUS: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _googleAccountPendiente = null;
        print("[loginConGoogle] Login Google exitoso");
        return await _guardarCredenciales(data);
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        if (data['requiereTerminos'] == true) {
          print("[loginConGoogle] Usuario nuevo - requiere aceptar terminos");
          _errorMessage = "requiere_terminos";
          return false;
        }
        _errorMessage = data['mensaje'] ?? 'No se pudo iniciar sesion con Google.';
        _googleAccountPendiente = null;
        return false;
      } else if (response.statusCode == 401) {
        final data = jsonDecode(response.body);
        final mensaje = data['mensaje'] ?? 'Error de autenticacion con Google.';
        final error = data['error'] ?? '';
        
        print('[loginConGoogle] Error 401 - Token inválido');
        print('[loginConGoogle] Mensaje: $mensaje');
        
        // Proporcionar mensaje más específico
        if (error.contains('404')) {
          _errorMessage = "Error de configuración del servidor. Contacta al soporte.";
        } else {
          _errorMessage = mensaje;
        }
        
        _googleAccountPendiente = null;
        await _googleSignIn.signOut();
        return false;
      } else {
        print("[loginConGoogle] Error inesperado status=${response.statusCode}");
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'No se pudo iniciar sesion con Google.';
        _googleAccountPendiente = null;
        return false;
      }
    } on SocketException catch (e) {
      print("[loginConGoogle] SocketException: $e");
      _errorMessage = "sin_conexion";
      _googleAccountPendiente = null;
      return false;
    } on http.ClientException catch (e) {
      print("[loginConGoogle] ClientException: $e");
      _errorMessage = "error_red";
      _googleAccountPendiente = null;
      return false;
    } catch (e, st) {
      print("[loginConGoogle] Excepción: $e");
      print(st);
      if (e.toString().contains('timeout')) {
        _errorMessage = "timeout";
      } else {
        _errorMessage = "Error de Google Login: $e";
      }
      _googleAccountPendiente = null;
      return false;
    }
  }

  // -------------------------------
  // LIMPIAR DATOS PENDIENTES DE GOOGLE
  // -------------------------------
  void limpiarDatosGooglePendientes() {
    _googleAccountPendiente = null;
    print('Datos de Google pendientes limpiados');
  }

  // -------------------------------
  // REGISTRO
  // -------------------------------
  Future<bool> register(String nombre, String email, String password) async {
    _errorMessage = null;

    if (!await _tieneConexion()) {
      _errorMessage = "sin_conexion";
      return false;
    }

    try {
      print("Intentando registro para: ${_enmascararEmail(email)}");
      
      final response = await http.post(
        Uri.parse('$authUrl/registrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nombre": nombre.trim(),
          "email": email.trim(),
          "password": password.trim(),
        }),
      ).timeout(const Duration(seconds: 15));

      print("REGISTRO STATUS: ${response.statusCode}");

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print("Registro exitoso");
        return await _guardarCredenciales(data);
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Error al registrar usuario.';
        return false;
      }
    } on SocketException catch (e) {
      print("SocketException en registro: $e");
      _errorMessage = "sin_conexion";
      return false;
    } on http.ClientException catch (e) {
      print("ClientException en registro: $e");
      _errorMessage = "error_red";
      return false;
    } catch (e) {
      print("Error en registro: $e");
      if (e.toString().contains('timeout') || e.toString().contains('TimeoutException')) {
        _errorMessage = "timeout";
      } else if (e.toString().contains('Failed host lookup') || e.toString().contains('Network is unreachable')) {
        _errorMessage = "sin_conexion";
      } else {
        _errorMessage = "Error al registrar: $e";
      }
      return false;
    }
  }

  // -------------------------------
  // GUARDAR CREDENCIALES
  // -------------------------------
  Future<bool> _guardarCredenciales(Map<String, dynamic> data) async {
    try {
      final token = data['token'] ?? data['accessToken'] ?? '';
      if (token.isEmpty) throw Exception("Token vacio");

      await _secureStorage.write(key: 'accessToken', value: token);

      if (data.containsKey('refreshToken')) {
        await _secureStorage.write(key: 'refreshToken', value: data['refreshToken']);
      }

      final usuario = data['usuario'] ?? {};
      await _secureStorage.write(key: 'rol', value: usuario['rol'] ?? '');
      await _secureStorage.write(key: 'nombre', value: usuario['nombre'] ?? '');
      await _secureStorage.write(key: 'email', value: usuario['email'] ?? '');
      await _secureStorage.write(key: 'foto', value: usuario['foto'] ?? '');

      print("Credenciales guardadas - Rol: ${usuario['rol']}, Email: ${_enmascararEmail(usuario['email'])}");
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
    if (!await _tieneConexion()) {
      _errorMessage = "sin_conexion";
      return null;
    }

    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) {
        print("No hay refresh token disponible");
        return null;
      }

      print("Renovando token...");

      final response = await http.post(
        Uri.parse('$authUrl/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final nuevoAccessToken = data['accessToken'] ?? data['token'];

        if (nuevoAccessToken != null && nuevoAccessToken is String) {
          await guardarAccessToken(nuevoAccessToken);
          print("Token renovado exitosamente");
          return nuevoAccessToken;
        }
        return null;
      } else {
        print("Error al renovar token: ${response.statusCode}");
        _errorMessage = "Token expirado";
        return null;
      }
    } on SocketException catch (e) {
      print("SocketException en renovar token: $e");
      _errorMessage = "sin_conexion";
      return null;
    } catch (e) {
      if (e.toString().contains('timeout')) {
        _errorMessage = "timeout";
      } else {
        _errorMessage = "Error al renovar token: $e";
      }
      return null;
    }
  }

  Future<void> guardarAccessToken(String token) async {
    await _secureStorage.write(key: 'accessToken', value: token);
    print("Access token actualizado en storage");
  }

  Future<void> guardarRol(String rol) async {
    await _secureStorage.write(key: 'rol', value: rol);
  }

  Future<void> guardarNombre(String nombre) async {
    await _secureStorage.write(key: 'nombre', value: nombre);
  }

  Future<void> guardarEmail(String email) async {
    await _secureStorage.write(key: 'email', value: email);
  }

  // -------------------------------
  // CERRAR SESION
  // -------------------------------
  Future<void> logout() async {
    print("Cerrando sesión y limpiando datos...");
    await _secureStorage.deleteAll();
    await _googleSignIn.signOut();
    _googleAccountPendiente = null;
    print("Sesión cerrada exitosamente");
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

    if (!await _tieneConexion()) {
      _errorMessage = "sin_conexion";
      return null;
    }

    try {
      print("Verificando disponibilidad de email: ${_enmascararEmail(email)}");
      
      final response = await http.post(
        Uri.parse('$authUrl/email-existe'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email.trim()}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final existe = data['existe'] ?? false;
        print("Email ${existe ? 'ya existe' : 'disponible'}");
        return existe;
      } else {
        final data = jsonDecode(response.body);
        _errorMessage = data['mensaje'] ?? 'Error al verificar correo.';
        return null;
      }
    } on SocketException catch (e) {
      print("SocketException en verificar email: $e");
      _errorMessage = "sin_conexion";
      return null;
    } catch (e) {
      if (e.toString().contains('timeout')) {
        _errorMessage = "timeout";
      } else {
        _errorMessage = "Error al verificar correo: $e";
      }
      return null;
    }
  }
}