// lib/providers/anuncio_provider.dart
import 'package:flutter/material.dart';
import '../services/anuncio_service.dart';
import '../services/connectivity_service.dart'; // Importar el servicio de conectividad

class AnunciosProvider with ChangeNotifier {
  final AnuncioService _anuncioService = AnuncioService();
  final ConnectivityService _connectivityService = ConnectivityService();

  // Estados de carga
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isDeleting = false;
  bool _hasInitialized = false; // Nuevo estado para saber si ya se inicializó

  // Datos
  List<Map<String, dynamic>> _anunciosActivos = [];
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _categorias = [];

  // Error management
  String? _errorMessage;

  // Getters
  bool get isLoading => _isLoading;
  bool get isCreating => _isCreating;
  bool get isDeleting => _isDeleting;
  bool get hasInitialized => _hasInitialized; // Nuevo getter
  List<Map<String, dynamic>> get anunciosActivos => _anunciosActivos;
  List<Map<String, dynamic>> get productos => _productos;
  List<Map<String, dynamic>> get categorias => _categorias;
  String? get errorMessage => _errorMessage;

  // Getter para saber si hay datos cargados
  bool get hasData => _productos.isNotEmpty || _categorias.isNotEmpty;

  // ------------------------------
  // MÉTODOS DE ANUNCIOS
  // ------------------------------

  /// Obtiene los anuncios activos (versión simple)
  Future<List<Map<String, String>>> obtenerAnunciosActivosSimple() async {
    // Verificar conectividad antes de hacer la llamada
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return [];
    }

    _setLoading(true);
    try {
      final anuncios = await _anuncioService.obtenerAnunciosActivos();
      _clearError();
      return anuncios;
    } catch (e) {
      _setError("Error al obtener anuncios: $e");
      return [];
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene los anuncios activos con todos los datos
  Future<void> cargarAnunciosActivos() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return;
    }

    _setLoading(true);
    try {
      _anunciosActivos = await _anuncioService.obtenerAnunciosActivosConId();
      _setError(_anuncioService.message);
      _clearError();
    } catch (e) {
      _setError("Error al cargar anuncios: $e");
    } finally {
      _setLoading(false);
    }
  }

  /// Crea un nuevo anuncio
  Future<bool> crearAnuncio({
    required String fechaInicio,
    required String fechaFin,
    String? productoId,
    String? categoriaId,
    required String imagenPath,
  }) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return false;
    }

    _setCreating(true);
    try {
      final success = await _anuncioService.crearAnuncio(
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        productoId: productoId,
        categoriaId: categoriaId,
        imagenPath: imagenPath,
      );

      if (success) {
        _clearError();
        // Recargar anuncios después de crear uno nuevo
        await cargarAnunciosActivos();
      } else {
        _setError(_anuncioService.message ?? "Error al crear anuncio");
      }

      return success;
    } catch (e) {
      _setError("Error al crear anuncio: $e");
      return false;
    } finally {
      _setCreating(false);
    }
  }

  /// Elimina un anuncio
  Future<bool> eliminarAnuncio(String id) async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return false;
    }

    _setDeleting(true);
    try {
      final success = await _anuncioService.eliminarAnuncio(id);

      if (success) {
        _clearError();
        // Remover el anuncio de la lista local
        _anunciosActivos.removeWhere((anuncio) => anuncio['_id'] == id);
        notifyListeners();
      } else {
        _setError(_anuncioService.message ?? "Error al eliminar anuncio");
      }

      return success;
    } catch (e) {
      _setError("Error al eliminar anuncio: $e");
      return false;
    } finally {
      _setDeleting(false);
    }
  }

  // ------------------------------
  // MÉTODOS DE PRODUCTOS
  // ------------------------------

  /// Carga la lista de productos
  Future<void> cargarProductos() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return;
    }

    _setLoading(true);
    try {
      _productos = await _anuncioService.obtenerProductos();
      if (_anuncioService.message != null) {
        _setError(_anuncioService.message);
      } else {
        _clearError();
      }
    } catch (e) {
      if (e.toString().contains('Sin conexión a Internet')) {
        _setError("Sin conexión a Internet");
      } else {
        _setError("Error al cargar productos: $e");
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene un producto por ID
  Map<String, dynamic>? obtenerProductoPorId(String id) {
    try {
      return _productos.firstWhere((producto) => producto['_id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ------------------------------
  // MÉTODOS DE CATEGORÍAS
  // ------------------------------

  /// Carga la lista de categorías
  Future<void> cargarCategorias() async {
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      return;
    }

    _setLoading(true);
    try {
      _categorias = await _anuncioService.obtenerCategorias();
      if (_anuncioService.message != null) {
        _setError(_anuncioService.message);
      } else {
        _clearError();
      }
    } catch (e) {
      if (e.toString().contains('Sin conexión a Internet')) {
        _setError("Sin conexión a Internet");
      } else {
        _setError("Error al cargar categorías: $e");
      }
    } finally {
      _setLoading(false);
    }
  }

  /// Obtiene una categoría por ID
  Map<String, dynamic>? obtenerCategoriaPorId(String id) {
    try {
      return _categorias.firstWhere((categoria) => categoria['_id'] == id);
    } catch (e) {
      return null;
    }
  }

  // ------------------------------
  // MÉTODOS DE UTILIDAD
  // ------------------------------

  /// Carga todos los datos iniciales
  Future<void> inicializar() async {
    // Verificar conectividad antes de inicializar
    final isConnected = await _connectivityService.checkConnectivity();
    if (!isConnected) {
      _setError("Sin conexión a Internet");
      _hasInitialized = true; // Marcar como inicializado aunque haya fallado
      return;
    }

    _setLoading(true);
    try {
      await Future.wait([
        cargarAnunciosActivos(),
        cargarProductos(),
        cargarCategorias(),
      ]);
      _hasInitialized = true;
    } catch (e) {
      _setError("Error al inicializar datos: $e");
      _hasInitialized = true;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresca todos los datos
  Future<void> refrescarTodo() async {
    _hasInitialized = false; // Reset el estado de inicialización
    await inicializar();
  }

  /// Limpia todos los datos
  void limpiarDatos() {
    _anunciosActivos.clear();
    _productos.clear();
    _categorias.clear();
    _hasInitialized = false;
    _clearError();
    notifyListeners();
  }

  /// Resetea el estado de inicialización (útil cuando se recupera la conexión)
  void resetInitialization() {
    _hasInitialized = false;
    _clearError();
    notifyListeners();
  }

  // ------------------------------
  // MÉTODOS PRIVADOS DE ESTADO
  // ------------------------------

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setCreating(bool creating) {
    _isCreating = creating;
    notifyListeners();
  }

  void _setDeleting(bool deleting) {
    _isDeleting = deleting;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    if (error != null) {
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  /// Limpia solo el mensaje de error
  void clearError() {
    _clearError();
  }
}