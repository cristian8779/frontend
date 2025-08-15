import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  String? _token;
  String? _refreshToken;
  String? _rol;
  String? _nombre;
  String? _email;
  bool _cargando = true;

  // Getters públicos
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get rol => _rol;
  String? get nombre => _nombre;
  String? get email => _email;
  bool get cargando => _cargando;

  bool get isAuthenticated => _token != null && _rol != null;

  AuthProvider() {
    _inicializar();
  }

  Future<void> _inicializar() async {
    debugPrint("🔄 Inicializando AuthProvider...");
    await cargarSesion();
  }

  Future<void> cargarSesion() async {
    await _cargarDesdeStorage();

    if (_token == null || _rol == null) {
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
      _token = await _authService.getAccessToken();
      _refreshToken = await _authService.getRefreshToken();
      _rol = await _authService.getRol();
      _nombre = await _authService.getNombre();
      _email = await _authService.getEmail();

      debugPrint('✅ Token recuperado: $_token');
      debugPrint('🧾 ROL detectado: $_rol');
      debugPrint('👤 Usuario: $_nombre ($_email)');

      if (_token == null || _rol == null) {
        _resetearEstado();
      }
    } catch (e) {
      debugPrint('⚠️ Error al cargar desde storage: $e');
      _resetearEstado();
    }

    notifyListeners();
  }

  void _resetearEstado() {
    debugPrint("♻️ Reseteando estado de sesión...");
    _token = null;
    _refreshToken = null;
    _rol = null;
    _nombre = null;
    _email = null;
  }

  /// 🔐 Cierra sesión, limpia estado y almacenamiento
  Future<void> cerrarSesion() async {
    try {
      debugPrint("🚪 Cerrando sesión...");
      await _authService.logout(); // Limpia almacenamiento seguro
    } catch (e) {
      debugPrint('⚠️ Error al cerrar sesión: $e');
    }

    _resetearEstado();
    notifyListeners();
  }

  String getTokenOrThrow() {
    if (_token == null) {
      throw Exception('⚠️ No hay token disponible. El usuario no está autenticado.');
    }
    return _token!;
  }

  /// 🔄 Renovar token con servicio y guardar en storage
  Future<bool> renovarToken() async {
    try {
      final nuevoToken = await _authService.renovarToken();
      if (nuevoToken != null && nuevoToken.isNotEmpty) {
        _token = nuevoToken;

        // Guardar el token renovado en almacenamiento seguro
        await _authService.guardarAccessToken(nuevoToken);

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
}
