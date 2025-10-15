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
  String? _userId;
  bool _cargando = true;

  // Variables para mantener datos de Google temporalmente
  String? _googleIdTokenPendiente;
  Map<String, dynamic>? _googleUserDataPendiente;

  // Getters públicos
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  String? get rol => _rol;
  String? get nombre => _nombre;
  String? get email => _email;
  String? get userId => _userId;
  bool get cargando => _cargando;

  bool get isAuthenticated => _token != null && _rol != null && _userId != null;

  // Getter para mensajes de error
  String? get mensaje => _authService.message;

  AuthProvider() {
    _inicializar();
  }

  // -------------------------------
  // UTILIDAD PARA ENMASCARAR DATOS
  // -------------------------------
  String _enmascarar(String? texto) {
    if (texto == null || texto.isEmpty) return 'VACIO';
    if (texto.length <= 4) return '***';
    return '${texto.substring(0, 2)}...${texto.substring(texto.length - 2)}';
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

  Future<void> _inicializar() async {
    debugPrint("Inicializando AuthProvider...");
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

        debugPrint('Login exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('Usuario logueado: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)}) ID: ${_enmascarar(_userId)}');
      }
      return success;
    } catch (e) {
      debugPrint('Error en login: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // -------------------------------
  // LOGIN CON GOOGLE (CON TÉRMINOS)
  // -------------------------------
  Future<bool> loginConGoogle({bool terminosAceptados = false}) async {
    _cargando = true;
    notifyListeners();

    try {
      // Si NO hay términos aceptados y NO hay datos pendientes, hacer sign in completo
      if (!terminosAceptados && _googleIdTokenPendiente == null) {
        // Obtener los datos de Google (el AuthService maneja el GoogleSignIn)
        final success = await _authService.loginConGoogle(terminosAceptados: false);
        
        if (!success) {
          // Si el mensaje es "requiere_terminos", guardar los datos temporalmente
          if (_authService.message == "requiere_terminos") {
            // Los datos ya deberían estar en el AuthService
            // Solo notificamos que se requieren términos
            debugPrint('Usuario nuevo con Google - requiere aceptar términos');
            _cargando = false;
            notifyListeners();
            return false;
          }
          
          // Otro tipo de error
          _cargando = false;
          notifyListeners();
          return false;
        }

        // Login exitoso (usuario existente)
        await _cargarDesdeStorage();
        debugPrint('Login con Google exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('Usuario logueado: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)}) ID: ${_enmascarar(_userId)}');
        _cargando = false;
        notifyListeners();
        return true;
      }

      // Si se aceptaron términos, intentar con los datos guardados
      if (terminosAceptados) {
        final success = await _authService.loginConGoogle(terminosAceptados: true);
        
        if (success) {
          await _cargarDesdeStorage();
          debugPrint('Cuenta creada con Google exitosamente');
          debugPrint('Usuario logueado: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)}) ID: ${_enmascarar(_userId)}');
          _cargando = false;
          notifyListeners();
          return true;
        }
        
        _cargando = false;
        notifyListeners();
        return false;
      }

      _cargando = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      debugPrint('Error en loginConGoogle: $e');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  // -------------------------------
  // ACEPTAR TÉRMINOS Y CREAR CUENTA
  // -------------------------------
  Future<bool> aceptarTerminosYCrearCuenta() async {
    _cargando = true;
    notifyListeners();

    try {
      // Llamar al servicio con términos aceptados
      final success = await _authService.loginConGoogle(terminosAceptados: true);
      
      if (success) {
        await _cargarDesdeStorage();
        debugPrint('Cuenta creada exitosamente con Google');
        debugPrint('Usuario logueado: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)}) ID: ${_enmascarar(_userId)}');
        _cargando = false;
        notifyListeners();
        return true;
      }
      
      _cargando = false;
      notifyListeners();
      return false;
      
    } catch (e) {
      debugPrint('Error al aceptar términos: $e');
      _cargando = false;
      notifyListeners();
      return false;
    }
  }

  // -------------------------------
  // LIMPIAR DATOS PENDIENTES DE GOOGLE
  // -------------------------------
  void limpiarDatosGooglePendientes() {
    _authService.limpiarDatosGooglePendientes();
    _googleIdTokenPendiente = null;
    _googleUserDataPendiente = null;
    debugPrint('Datos de Google pendientes limpiados en AuthProvider');
    notifyListeners();
  }

  // -------------------------------
  // REGISTRO
  // -------------------------------
  Future<bool> register(String nombre, String email, String password) async {
    _cargando = true;
    notifyListeners();

    try {
      final success = await _authService.register(nombre, email, password);
      if (success) {
        await _cargarDesdeStorage();
        notifyListeners();

        debugPrint('Registro exitoso - isAuthenticated: $isAuthenticated');
        debugPrint('Usuario registrado: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)}) ID: ${_enmascarar(_userId)}');
      }
      return success;
    } catch (e) {
      debugPrint('Error en register: $e');
      return false;
    } finally {
      _cargando = false;
      notifyListeners();
    }
  }

  // -------------------------------
  // CARGAR DESDE STORAGE
  // -------------------------------
  Future<void> _cargarDesdeStorage() async {
    try {
      final oldIsAuthenticated = isAuthenticated;

      _token = await _authService.getAccessToken();
      _refreshToken = await _authService.getRefreshToken();
      _rol = await _authService.getRol();
      _nombre = await _authService.getNombre();
      _email = await _authService.getEmail();

      // Decodificar el userId del JWT si hay token
      if (_token != null && _token!.isNotEmpty) {
        try {
          Map<String, dynamic> decoded = JwtDecoder.decode(_token!);
          _userId = decoded['id'];
        } catch (e) {
          debugPrint("Error al decodificar JWT: $e");
          _userId = null;
        }
      }

      debugPrint('Token recuperado: ${_token != null ? 'SI' : 'NO'}');
      debugPrint('ROL detectado: $_rol');
      debugPrint('Usuario: ${_enmascarar(_nombre)} (${_enmascararEmail(_email)})');
      debugPrint('UserId: ${_enmascarar(_userId)}');
      debugPrint('Estado autenticacion: $isAuthenticated');

      if (_token == null || _rol == null || _userId == null) {
        _resetearEstado();
      }

      if (oldIsAuthenticated != isAuthenticated) {
        debugPrint('Estado de autenticacion cambio: $oldIsAuthenticated -> $isAuthenticated');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error al cargar desde storage: $e');
      _resetearEstado();
    }
  }

  // -------------------------------
  // RESETEAR ESTADO
  // -------------------------------
  void _resetearEstado() {
    debugPrint("Reseteando estado de sesion...");
    final wasAuthenticated = isAuthenticated;

    _token = null;
    _refreshToken = null;
    _rol = null;
    _nombre = null;
    _email = null;
    _userId = null;
    _googleIdTokenPendiente = null;
    _googleUserDataPendiente = null;

    if (wasAuthenticated) {
      debugPrint("Usuario desautenticado - notificando cambios");
      notifyListeners();
    }
  }

  // -------------------------------
  // CERRAR SESIÓN
  // -------------------------------
  Future<void> cerrarSesion() async {
    try {
      debugPrint("Cerrando sesion...");
      await _authService.logout();
    } catch (e) {
      debugPrint('Error al cerrar sesion: $e');
    }

    _resetearEstado();
  }

  // -------------------------------
  // OBTENER TOKEN O LANZAR EXCEPCIÓN
  // -------------------------------
  String getTokenOrThrow() {
    if (_token == null) {
      throw Exception('No hay token disponible. El usuario no esta autenticado.');
    }
    return _token!;
  }

  // -------------------------------
  // RENOVAR TOKEN
  // -------------------------------
  Future<bool> renovarToken() async {
    try {
      final nuevoToken = await _authService.renovarToken();
      if (nuevoToken != null && nuevoToken.isNotEmpty) {
        _token = nuevoToken;

        await _authService.guardarAccessToken(nuevoToken);

        // Actualizar userId con el nuevo token
        try {
          Map<String, dynamic> decoded = JwtDecoder.decode(nuevoToken);
          _userId = decoded['id'];
        } catch (e) {
          debugPrint("Error al decodificar nuevo JWT: $e");
          _userId = null;
        }

        debugPrint("Token renovado correctamente");
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error al renovar token: $e');
      return false;
    }
  }

  // -------------------------------
  // ACTUALIZAR ESTADO
  // -------------------------------
  Future<void> actualizarEstado() async {
    debugPrint("Forzando actualizacion del estado...");
    await _cargarDesdeStorage();
    notifyListeners();
  }
}