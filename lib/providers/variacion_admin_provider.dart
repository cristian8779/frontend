import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/variacion.dart';
import '../services/variacion_service.dart';

enum VariacionEstado { initial, loading, loaded, error }

class VariacionProvider extends ChangeNotifier {
  final VariacionService _variacionService = VariacionService();
  
  // --- ESTADO ---
  VariacionEstado _estado = VariacionEstado.initial;
  List<Map<String, dynamic>> _variaciones = [];
  String? _mensajeError;
  bool _cargandoAccion = false;

  // --- GETTERS ---
  VariacionEstado get estado => _estado;
  List<Map<String, dynamic>> get variaciones => List.unmodifiable(_variaciones);
  String? get mensajeError => _mensajeError;
  bool get cargandoAccion => _cargandoAccion;
  bool get isLoading => _estado == VariacionEstado.loading;
  bool get hasError => _estado == VariacionEstado.error;
  bool get hasData => _estado == VariacionEstado.loaded && _variaciones.isNotEmpty;
  bool get isEmpty => _estado == VariacionEstado.loaded && _variaciones.isEmpty;

  // --- MÉTODOS PRINCIPALES ---

  /// Obtiene todas las variaciones de un producto
  Future<void> cargarVariaciones(String productoId) async {
    if (productoId.isEmpty) {
      _setError('❌ ID de producto inválido');
      return;
    }

    _setEstado(VariacionEstado.loading);
    
    try {
      debugPrint('🔄 Cargando variaciones para producto: $productoId');
      final variaciones = await _variacionService.obtenerVariacionesPorProducto(productoId);
      
      _variaciones = variaciones;
      _setEstado(VariacionEstado.loaded);
      debugPrint('✅ Variaciones cargadas: ${_variaciones.length}');
      
    } catch (e) {
      debugPrint('❌ Error al cargar variaciones: $e');
      _setError(e.toString());
    }
  }

  /// Crea una nueva variación
  Future<bool> crearVariacion(Variacion variacion) async {
    if (variacion.productoId.isEmpty) {
      _setError('❌ ID de producto requerido');
      return false;
    }

    _setCargandoAccion(true);
    
    try {
      debugPrint('🔄 Creando nueva variación...');
      await _variacionService.crearVariacionDesdeModelo(variacion);
      
      // Recargar las variaciones para mostrar la nueva
      await cargarVariaciones(variacion.productoId);
      
      _setCargandoAccion(false);
      _showSuccessMessage('✅ Variación creada exitosamente');
      debugPrint('✅ Variación creada correctamente');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error al crear variación: $e');
      _setCargandoAccion(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Actualiza una variación existente
  Future<bool> actualizarVariacion({
    required String productoId,
    required String variacionId,
    String? tallaNumero,
    String? tallaLetra,
    String? colorHex,
    String? colorNombre,
    int? stock,
    double? precio,
    File? imagenLocal,
  }) async {
    if (productoId.isEmpty || variacionId.isEmpty) {
      _setError('❌ IDs de producto y variación requeridos');
      return false;
    }

    _setCargandoAccion(true);
    
    try {
      debugPrint('🔄 Actualizando variación: $variacionId');
      
      await _variacionService.actualizarVariacion(
        productoId: productoId,
        variacionId: variacionId,
        tallaNumero: tallaNumero,
        tallaLetra: tallaLetra,
        colorHex: colorHex,
        colorNombre: colorNombre,
        stock: stock,
        precio: precio,
        imagenLocal: imagenLocal,
      );

      // Recargar variaciones para mostrar cambios
      await cargarVariaciones(productoId);
      
      _setCargandoAccion(false);
      _showSuccessMessage('✅ Variación actualizada exitosamente');
      debugPrint('✅ Variación actualizada correctamente');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error al actualizar variación: $e');
      _setCargandoAccion(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Actualiza una variación usando el modelo completo
  Future<bool> actualizarVariacionDesdeModelo(Variacion variacion) async {
    if (variacion.id == null || variacion.productoId.isEmpty) {
      _setError('❌ Variación incompleta para actualización');
      return false;
    }

    _setCargandoAccion(true);
    
    try {
      debugPrint('🔄 Actualizando variación desde modelo...');
      await _variacionService.actualizarVariacionDesdeModelo(variacion);
      
      // Recargar variaciones
      await cargarVariaciones(variacion.productoId);
      
      _setCargandoAccion(false);
      _showSuccessMessage('✅ Variación actualizada exitosamente');
      return true;
      
    } catch (e) {
      debugPrint('❌ Error al actualizar variación: $e');
      _setCargandoAccion(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Elimina una variación
  Future<bool> eliminarVariacion({
    required String productoId,
    required String variacionId,
  }) async {
    if (productoId.isEmpty || variacionId.isEmpty) {
      _setError('❌ IDs de producto y variación requeridos');
      return false;
    }

    _setCargandoAccion(true);
    
    try {
      debugPrint('🔄 Eliminando variación: $variacionId');
      await _variacionService.eliminarVariacion(
        productoId: productoId,
        variacionId: variacionId,
      );

      // Remover de la lista local
      _variaciones.removeWhere((v) => v['_id'] == variacionId);
      
      _setCargandoAccion(false);
      _showSuccessMessage('✅ Variación eliminada exitosamente');
      debugPrint('✅ Variación eliminada correctamente');
      notifyListeners();
      return true;
      
    } catch (e) {
      debugPrint('❌ Error al eliminar variación: $e');
      _setCargandoAccion(false);
      _setError(e.toString());
      return false;
    }
  }

  /// Reduce el stock de una variación
  Future<Map<String, dynamic>?> reducirStock({
    required String productoId,
    required String variacionId,
    required int cantidad,
  }) async {
    if (productoId.isEmpty || variacionId.isEmpty || cantidad <= 0) {
      _setError('❌ Parámetros inválidos para reducir stock');
      return null;
    }

    _setCargandoAccion(true);
    
    try {
      debugPrint('🔄 Reduciendo stock: $cantidad unidades');
      final resultado = await _variacionService.reducirStockVariacion(
        productoId: productoId,
        variacionId: variacionId,
        cantidad: cantidad,
      );

      // Actualizar el stock en la lista local
      _actualizarStockLocal(variacionId, resultado);
      
      _setCargandoAccion(false);
      _showSuccessMessage('✅ Stock reducido exitosamente');
      debugPrint('✅ Stock reducido correctamente');
      return resultado;
      
    } catch (e) {
      debugPrint('❌ Error al reducir stock: $e');
      _setCargandoAccion(false);
      _setError(e.toString());
      return null;
    }
  }

  // --- MÉTODOS DE UTILIDAD ---

  /// Obtiene una variación específica por ID
  Map<String, dynamic>? obtenerVariacionPorId(String variacionId) {
    try {
      return _variaciones.firstWhere((v) => v['_id'] == variacionId);
    } catch (e) {
      debugPrint('⚠️ Variación no encontrada: $variacionId');
      return null;
    }
  }

  /// Filtra variaciones por color
  List<Map<String, dynamic>> obtenerVariacionesPorColor(String colorHex) {
    return _variaciones.where((v) {
      final color = v['color'];
      return color != null && color['hex'] == colorHex;
    }).toList();
  }

  /// Filtra variaciones por talla
  List<Map<String, dynamic>> obtenerVariacionesPorTalla({
    String? tallaNumero,
    String? tallaLetra,
  }) {
    return _variaciones.where((v) {
      if (tallaNumero != null && v['tallaNumero'] != tallaNumero) return false;
      if (tallaLetra != null && v['tallaLetra'] != tallaLetra) return false;
      return true;
    }).toList();
  }

  /// Obtiene variaciones con stock disponible
  List<Map<String, dynamic>> obtenerVariacionesConStock() {
    return _variaciones.where((v) => (v['stock'] ?? 0) > 0).toList();
  }

  /// Limpia el estado del provider
  void limpiarEstado() {
    _variaciones.clear();
    _mensajeError = null;
    _estado = VariacionEstado.initial;
    _cargandoAccion = false;
    notifyListeners();
    debugPrint('🧹 Estado del provider limpiado');
  }

  /// Limpia solo el mensaje de error
  void limpiarError() {
    _mensajeError = null;
    if (_estado == VariacionEstado.error) {
      _estado = _variaciones.isEmpty ? VariacionEstado.initial : VariacionEstado.loaded;
    }
    notifyListeners();
  }

  // --- MÉTODOS PRIVADOS ---

  void _setEstado(VariacionEstado nuevoEstado) {
    _estado = nuevoEstado;
    if (nuevoEstado != VariacionEstado.error) {
      _mensajeError = null;
    }
    notifyListeners();
  }

  void _setError(String mensaje) {
    _mensajeError = mensaje;
    _estado = VariacionEstado.error;
    notifyListeners();
  }

  void _setCargandoAccion(bool cargando) {
    _cargandoAccion = cargando;
    notifyListeners();
  }

  void _showSuccessMessage(String mensaje) {
    debugPrint(mensaje);
    // Aquí podrías mostrar un SnackBar o notificación de éxito
    // si tienes acceso al context o un servicio de notificaciones
  }

  void _actualizarStockLocal(String variacionId, Map<String, dynamic> nuevosdatos) {
    final index = _variaciones.indexWhere((v) => v['_id'] == variacionId);
    if (index != -1) {
      _variaciones[index] = {..._variaciones[index], ...nuevosdatos};
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ VariacionProvider disposed');
    super.dispose();
  }
}