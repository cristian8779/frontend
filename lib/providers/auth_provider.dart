import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  String? _refreshToken;
  String? _rol;
  String? _nombre;
  String? _email;
  String? _userId; // ✅ Nuevo
  bool _cargando = true;

  // Getters públicos
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get rol => _rol;
  String? get nombre => _nombre;
  String? get email => _email;
  String? get userId => _userId; // ✅ Nuevo getter
  bool get cargando => _cargando;

  bool get isAuthenticated => _token != null && _rol != null && _userId != null;

  AuthProvider() {
    _inicializar();
  }

  Future<void> _inicializar() async {
    debugPrint("🔄 Inicializando AuthProvider...");
    await cargarSesion();
  }

  Future<void> cargarSesion() async {
    _cargando = true;
    notifyListeners();

    await _cargarDesdeStorage();

    if (_token == null || _rol == null || _userId == null) {
      _resetearEstado();
    }

    _cargando = false;
    notifyListeners();
  }

  Future<bool> login(String correo, String password) async {
    _cargando = true;
    notifyListeners();

    try {
      final success = await _authService.login(correo, password);
      if (success) {
        await _cargarDesdeStorage();
        notifyListeners();

        debugPrint('✅ Login exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('✅ Usuario logueado: $_nombre ($_email) ID: $_userId');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> loginConGoogle() async {
    _cargando = true;
    notifyListeners();

    try {
      final success = await _authService.loginConGoogle();
      if (success) {
        await _cargarDesdeStorage();
        notifyListeners();

        debugPrint('✅ Login con Google exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('✅ Usuario logueado: $_nombre ($_email) ID: $_userId');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error en loginConGoogle: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<bool> register(String nombre, String email, String password) async {
    _cargando = true;
    notifyListeners();

    try {
      final success = await _authService.register(nombre, email, password);
      if (success) {
        await _cargarDesdeStorage();
        notifyListeners();

        debugPrint('✅ Registro exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('✅ Usuario registrado: $_nombre ($_email) ID: $_userId');
      }
      return success;
    } catch (e) {
      debugPrint('❌ Error en register: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  Future<void> _cargarDesdeStorage() async {
    try {
      final oldIsAuthenticated = isAuthenticated;

      _token = await _authService.getAccessToken();
      _refreshToken = await _authService.getRefreshToken();
      _rol = await _authService.getRol();
      _nombre = await _authService.getNombre();
      _email = await _authService.getEmail();

      // ✅ Decodificar el userId del JWT si hay token
      if (_token != null && _token!.isNotEmpty) {
        try {
          Map<String, dynamic> decoded = JwtDecoder.decode(_token!);
          _userId = decoded['id'];
        } catch (e) {
          debugPrint("⚠️ Error al decodificar JWT: $e");
          _userId = null;
        }
      }

      debugPrint('✅ Token recuperado: ${_token != null ? 'SÍ' : 'NO'}');
      debugPrint('🧾 ROL detectado: $_rol');
      debugPrint('👤 Usuario: $_nombre ($_email)');
      debugPrint('🆔 UserId: $_userId');
      debugPrint('🔐 Estado autenticación: $isAuthenticated');

      if (_token == null || _rol == null || _userId == null) {
        _resetearEstado();
      }

      if (oldIsAuthenticated != isAuthenticated) {
        debugPrint('🔄 Estado de autenticación cambió: $oldIsAuthenticated -> $isAuthenticated');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar desde storage: $e');
      _resetearEstado();
    }
  }

  void _resetearEstado() {
    debugPrint("♻️ Reseteando estado de sesión...");
    final wasAuthenticated = isAuthenticated;

    _token = null;
    _refreshToken = null;
    _rol = null;
    _nombre = null;
    _email = null;
    _userId = null;

    if (wasAuthenticated) {
      debugPrint("🔄 Usuario desautenticado - notificando cambios");
      notifyListeners();
    }
  }

  Future<void> cerrarSesion() async {
    try {
      debugPrint("🚪 Cerrando sesión...");
      await _authService.logout();
    } catch (e) {
      debugPrint('⚠️ Error al cerrar sesión: $e');
    }

    _resetearEstado();
  }

  String getTokenOrThrow() {
    if (_token == null) {
      throw Exception('⚠️ No hay token disponible. El usuario no está autenticado.');
    }
    return _token!;
  }

  Future<bool> renovarToken() async {
    try {
      final nuevoToken = await _authService.renovarToken();
      if (nuevoToken != null && nuevoToken.isNotEmpty) {
        _token = nuevoToken;

        await _authService.guardarAccessToken(nuevoToken);

        // ✅ actualizar userId con el nuevo token
        try {
          Map<String, dynamic> decoded = JwtDecoder.decode(nuevoToken);
          _userId = decoded['id'];
        } catch (e) {
          debugPrint("⚠️ Error al decodificar nuevo JWT: $e");
          _userId = null;
        }

        debugPrint("🔑 Token renovado correctamente.");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('⚠️ Error al renovar token: $e');
      return false;
    }
  }

  Future<void> actualizarEstado() async {
    debugPrint("🔄 Forzando actualización del estado...");
    await _cargarDesdeStorage();
    notifyListeners();
  }
}
