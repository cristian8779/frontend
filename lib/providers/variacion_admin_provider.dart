import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/variacion.dart';
import '../services/variacion_service.dart';

class VariacionProvider with ChangeNotifier {
  final VariacionService _service = VariacionService();
  
  List<Variacion> _variaciones = [];
  bool _isLoading = false;
  String? _error;
  
  // Getters
  List<Variacion> get variaciones => _variaciones;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasError => _error != null;

  // Limpiar error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // --- CARGAR VARIACIONES ---
  Future<void> cargarVariaciones(String productoId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final variacionesData = await _service.obtenerVariacionesPorProducto(productoId);
      _variaciones = variacionesData.map((v) => Variacion.fromJson(v)).toList();
      debugPrint('✅ ${_variaciones.length} variaciones cargadas');
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error al cargar variaciones: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- CREAR VARIACIÓN ---
  Future<bool> crearVariacion(Variacion variacion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.crearVariacionDesdeModelo(variacion);
      
      // Recargar variaciones después de crear
      await cargarVariaciones(variacion.productoId);
      
      debugPrint('✅ Variación creada exitosamente');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error al crear variación: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- ACTUALIZAR VARIACIÓN ---
  Future<bool> actualizarVariacion(Variacion variacion) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.actualizarVariacionDesdeModelo(variacion);
      
      // Actualizar en la lista local
      final index = _variaciones.indexWhere((v) => v.id == variacion.id);
      if (index != -1) {
        _variaciones[index] = variacion;
      }
      
      // O recargar todas las variaciones
      await cargarVariaciones(variacion.productoId);
      
      debugPrint('✅ Variación actualizada exitosamente');
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error al actualizar variación: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- ELIMINAR VARIACIÓN ---
  Future<bool> eliminarVariacion({
    required String productoId,
    required String variacionId,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.eliminarVariacion(
        productoId: productoId,
        variacionId: variacionId,
      );
      
      // Eliminar de la lista local
      _variaciones.removeWhere((v) => v.id == variacionId);
      
      debugPrint('✅ Variación eliminada exitosamente');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error al eliminar variación: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- REDUCIR STOCK ---
  Future<bool> reducirStock({
    required String productoId,
    required String variacionId,
    required int cantidad,
  }) async {
    _error = null;

    try {
      final result = await _service.reducirStockVariacion(
        productoId: productoId,
        variacionId: variacionId,
        cantidad: cantidad,
      );
      
      // Actualizar stock localmente
      final index = _variaciones.indexWhere((v) => v.id == variacionId);
      if (index != -1) {
        _variaciones[index] = _variaciones[index].copyWith(
          stock: result['variacion']['stock'] as int,
        );
      }
      
      debugPrint('✅ Stock reducido exitosamente');
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('❌ Error al reducir stock: $e');
      notifyListeners();
      return false;
    }
  }

  // --- MÉTODOS AUXILIARES ---

  // Obtener variación por ID
  Variacion? obtenerVariacionPorId(String variacionId) {
    try {
      return _variaciones.firstWhere((v) => v.id == variacionId);
    } catch (e) {
      return null;
    }
  }

  // Filtrar variaciones por color
  List<Variacion> filtrarPorColor(String colorHex) {
    return _variaciones.where((v) => v.colorHex == colorHex).toList();
  }

  // Filtrar variaciones por talla
  List<Variacion> filtrarPorTalla({String? tallaNumero, String? tallaLetra}) {
    return _variaciones.where((v) {
      if (tallaNumero != null && v.tallaNumero == tallaNumero) return true;
      if (tallaLetra != null && v.tallaLetra == tallaLetra) return true;
      return false;
    }).toList();
  }

  // Obtener variaciones con stock disponible
  List<Variacion> obtenerConStock() {
    return _variaciones.where((v) => v.stock > 0).toList();
  }

  // Obtener variaciones sin stock
  List<Variacion> obtenerSinStock() {
    return _variaciones.where((v) => v.stock == 0).toList();
  }

  // Obtener total de stock
  int get totalStock {
    return _variaciones.fold(0, (sum, v) => sum + v.stock);
  }

  // Obtener colores únicos
  List<String> get coloresUnicos {
    final colores = _variaciones
        .where((v) => v.colorHex != null)
        .map((v) => v.colorHex!)
        .toSet()
        .toList();
    return colores;
  }

  // Obtener tallas únicas
  Map<String, List<String>> get tallasUnicas {
    final tallasNumero = _variaciones
        .where((v) => v.tallaNumero != null && v.tallaNumero!.isNotEmpty)
        .map((v) => v.tallaNumero!)
        .toSet()
        .toList();
    
    final tallasLetra = _variaciones
        .where((v) => v.tallaLetra != null && v.tallaLetra!.isNotEmpty)
        .map((v) => v.tallaLetra!)
        .toSet()
        .toList();
    
    return {
      'numero': tallasNumero,
      'letra': tallasLetra,
    };
  }

  // Limpiar variaciones
  void limpiar() {
    _variaciones = [];
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _variaciones = [];
    super.dispose();
  }
}