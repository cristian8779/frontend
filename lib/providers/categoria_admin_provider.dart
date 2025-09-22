import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/categoria_service.dart';
import '/models/categoria.dart';

enum CategoriaState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
  creating,
  updating,
  deleting,
}

class CategoriasProvider extends ChangeNotifier {
  final CategoriaService _categoriaService = CategoriaService();

  // === ESTADO PRINCIPAL ===
  CategoriaState _state = CategoriaState.initial;
  List<Map<String, dynamic>> _categorias = [];
  List<Map<String, dynamic>> _categoriasFiltradas = [];
  
  // === BÚSQUEDA Y FILTROS ===
  String _busqueda = '';
  
  // === ORDENAMIENTO ===
  String _sortBy = 'nombre';
  bool _sortAscending = true;

  // === ERROR HANDLING ===
  String? _errorMessage;
  String? _lastErrorCode;

  // === CATEGORIA SELECCIONADA ===
  Categoria? _categoriaSeleccionada;

  // === GETTERS ===
  CategoriaState get state => _state;
  List<Map<String, dynamic>> get categorias => _categorias;
  List<Map<String, dynamic>> get categoriasFiltradas => _categoriasFiltradas;
  
  bool get isLoading => _state == CategoriaState.loading;
  bool get isRefreshing => _state == CategoriaState.refreshing;
  bool get isCreating => _state == CategoriaState.creating;
  bool get isUpdating => _state == CategoriaState.updating;
  bool get isDeleting => _state == CategoriaState.deleting;
  bool get hasError => _state == CategoriaState.error;
  bool get isEmpty => _categorias.isEmpty && !isLoading;

  String get busqueda => _busqueda;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  
  String? get errorMessage => _errorMessage;
  String? get lastErrorCode => _lastErrorCode;
  Categoria? get categoriaSeleccionada => _categoriaSeleccionada;

  int get totalCategorias => _categorias.length;
  int get totalFiltradas => _categoriasFiltradas.length;

  // === MÉTODOS PRINCIPALES ===

  /// Inicializar datos
  Future<void> inicializar() async {
    if (_state == CategoriaState.loading) return;

    _setState(CategoriaState.loading);
    _limpiarError();

    try {
      await _cargarCategorias();
      _setState(CategoriaState.loaded);
    } catch (e) {
      _manejarError(e, 'Error al inicializar categorías');
    }
  }

  /// Cargar categorías (inicial o refresh)
  Future<void> cargarCategorias({bool refresh = false}) async {
    if (!refresh && (_state == CategoriaState.loading || _state == CategoriaState.refreshing)) {
      return;
    }

    if (refresh) {
      _setState(CategoriaState.refreshing);
    } else {
      _setState(CategoriaState.loading);
    }

    _limpiarError();

    try {
      await _cargarCategorias();
      _setState(CategoriaState.loaded);
    } catch (e) {
      _manejarError(e, 'Error al cargar categorías');
    }
  }

  /// Refrescar categorías sin romper UI
  Future<void> refrescar() async {
    await cargarCategorias(refresh: true);
  }

  /// NUEVO MÉTODO: Refrescar sin mostrar skeleton (para pull-to-refresh)
  Future<void> refrescarSilencioso() async {
    _limpiarError();

    try {
      await _cargarCategorias();
      // Solo notificar cambios sin cambiar estado si ya estamos en loaded
      if (_state == CategoriaState.loaded || _state == CategoriaState.error) {
        notifyListeners();
      } else {
        _setState(CategoriaState.loaded);
      }
    } catch (e) {
      // En caso de error, sí cambiar el estado
      _manejarError(e, 'Error al refrescar categorías');
    }
  }

  /// Buscar categorías
  void buscarCategorias(String query) {
    _busqueda = query.trim();
    _aplicarFiltrosLocales();
    notifyListeners();
  }

  /// Cambiar ordenamiento
  void cambiarOrdenamiento(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = _sortBy == sortBy ? !_sortAscending : true;
    }

    _aplicarOrdenamiento();
    notifyListeners();
  }

  /// Limpiar filtros
  void limpiarFiltros() {
    _busqueda = '';
    _aplicarFiltrosLocales();
    notifyListeners();
  }

  // === CRUD OPERATIONS ===

  Future<bool> crearCategoria({
    required String nombre,
    required File imagenLocal,
  }) async {
    _setState(CategoriaState.creating);
    _limpiarError();

    try {
      await _categoriaService.crearCategoriaConImagenLocal(
        nombre: nombre,
        imagenLocal: imagenLocal,
      );

      await refrescarSilencioso(); // Usar refresh silencioso
      return true;
    } catch (e) {
      _manejarError(e, 'Error al crear categoría');
      return false;
    }
  }

  Future<Categoria?> obtenerCategoriaPorId(String id) async {
    try {
      final categoriaData = await _categoriaService.obtenerCategoriaPorId(id);
      if (categoriaData != null) {
        _categoriaSeleccionada = Categoria.fromJson(categoriaData);
        notifyListeners();
        return _categoriaSeleccionada;
      }
      return null;
    } catch (e) {
      _manejarError(e, 'Error al obtener categoría');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerProductosPorCategoria(String categoriaId) async {
    try {
      return await _categoriaService.obtenerProductosPorCategoria(categoriaId);
    } catch (e) {
      _manejarError(e, 'Error al obtener productos de la categoría');
      return [];
    }
  }

  Future<bool> actualizarCategoria({
    required String id,
    required String nombre,
    File? imagenLocal,
  }) async {
    _setState(CategoriaState.updating);
    _limpiarError();

    try {
      await _categoriaService.actualizarCategoria(
        id: id,
        nombre: nombre,
        imagenLocal: imagenLocal,
      );

      await refrescarSilencioso(); // Usar refresh silencioso
      return true;
    } catch (e) {
      _manejarError(e, 'Error al actualizar categoría');
      return false;
    }
  }

  Future<bool> eliminarCategoria(String id) async {
    _setState(CategoriaState.deleting);
    _limpiarError();

    try {
      final success = await _categoriaService.eliminarCategoria(id);
      
      if (success) {
        _categorias.removeWhere((c) => c['_id'] == id);
        _aplicarFiltrosLocales();
        _setState(CategoriaState.loaded);
        return true;
      }
      return false;
    } catch (e) {
      _manejarError(e, 'Error al eliminar categoría');
      return false;
    }
  }

  // === MÉTODOS PRIVADOS ===

  void _setState(CategoriaState newState) {
    _state = newState;
    notifyListeners();
  }

  void _limpiarError() {
    _errorMessage = null;
    _lastErrorCode = null;
  }

  void _manejarError(dynamic error, [String? contexto]) {
    print('Error en CategoriasProvider: $error');
    
    String mensajeError = error.toString();

    if (mensajeError.contains('! No se puede eliminar')) {
      final inicio = mensajeError.indexOf('! No se puede eliminar');
      mensajeError = mensajeError.substring(inicio);
      if (mensajeError.endsWith('.')) {
        mensajeError = mensajeError.substring(0, mensajeError.length - 1);
      }
    } else if (mensajeError.contains('❌') && mensajeError.contains(':')) {
      final partes = mensajeError.split(':');
      if (partes.length >= 2) {
        mensajeError = partes.last.trim();
        if (mensajeError.startsWith('Exception')) {
          mensajeError = mensajeError.substring('Exception'.length).trim();
        }
        if (mensajeError.startsWith(':')) {
          mensajeError = mensajeError.substring(1).trim();
        }
      }
    }

    _errorMessage = mensajeError.isEmpty ? (contexto ?? error.toString()) : mensajeError;
    print('Mensaje de error procesado: $_errorMessage');
    _setState(CategoriaState.error);
  }

  Future<void> _cargarCategorias() async {
    _categorias = await _categoriaService.obtenerCategorias();
    _aplicarFiltrosLocales();
  }

  void _aplicarFiltrosLocales() {
    _categoriasFiltradas = _categorias.where((categoria) {
      if (_busqueda.isNotEmpty) {
        final nombre = categoria['nombre']?.toString().toLowerCase() ?? '';
        final busquedaLower = _busqueda.toLowerCase();
        if (!nombre.contains(busquedaLower)) return false;
      }
      return true;
    }).toList();

    _aplicarOrdenamiento();
  }

  void _aplicarOrdenamiento() {
    _categoriasFiltradas.sort((a, b) {
      int comparison;
      switch (_sortBy) {
        case 'fecha':
          final fechaA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
          final fechaB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
          comparison = fechaA.compareTo(fechaB);
          break;
        default: // nombre
          final nombreA = a['nombre']?.toString().toLowerCase() ?? '';
          final nombreB = b['nombre']?.toString().toLowerCase() ?? '';
          comparison = nombreA.compareTo(nombreB);
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  // === UTILIDADES PÚBLICAS ===

  Future<void> reintentar() async {
    if (_state == CategoriaState.error) {
      await inicializar();
    } else {
      await refrescarSilencioso(); // Usar refresh silencioso
    }
  }

  void limpiar() {
    _categorias.clear();
    _categoriasFiltradas.clear();
    _categoriaSeleccionada = null;
    limpiarFiltros();
    _limpiarError();
    _setState(CategoriaState.initial);
  }

  bool get tieneFiltrosActivos => _busqueda.isNotEmpty;

  List<Map<String, dynamic>> obtenerCategoriasPorRango(int inicio, int limite) {
    final fin = (inicio + limite).clamp(0, _categoriasFiltradas.length);
    if (inicio >= _categoriasFiltradas.length) return [];
    return _categoriasFiltradas.sublist(inicio, fin);
  }

  Map<String, dynamic>? obtenerCategoriaPorIndice(int index) {
    if (index >= 0 && index < _categoriasFiltradas.length) {
      return _categoriasFiltradas[index];
    }
    return null;
  }

  @override
  void dispose() {
    super.dispose();
  }
}