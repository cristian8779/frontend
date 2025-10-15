import 'package:flutter/material.dart';
import '../services/carrito_service.dart';
import '../models/carrito.dart';
import '../models/resumen_carrito.dart';
import '../models/request_models.dart';

class CarritoProvider with ChangeNotifier {
  final CarritoService _carritoService = CarritoService();
  
  // Estado del carrito
  Map<String, dynamic>? _carritoData;
  Carrito? _carritoModelo;
  ResumenCarrito? _resumen;
  
  // Estados de carga y error
  bool _isLoading = false;
  bool _isAdding = false;
  bool _isUpdating = false;
  bool _isDeleting = false;
  String? _error;
  
  // Getters para el estado
  Map<String, dynamic>? get carritoData => _carritoData;
  Carrito? get carritoModelo => _carritoModelo;
  ResumenCarrito? get resumen => _resumen;
  
  bool get isLoading => _isLoading;
  bool get isAdding => _isAdding;
  bool get isUpdating => _isUpdating;
  bool get isDeleting => _isDeleting;
  String? get error => _error;
  
  // Getters de conveniencia
  List<dynamic> get items => _carritoData?['items'] ?? [];
  double get total => _carritoData?['total']?.toDouble() ?? 0.0;
  int get cantidadTotal => items.fold<int>(0, (acc, item) => acc + (item['cantidad'] as int? ?? 0));
  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;

  /// Limpiar errores
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Obtener stock disponible de un producto
  int obtenerStockDisponible(String productoId, {String? variacionId}) {
    try {
      final item = items.firstWhere(
        (i) => i['productoId'] == productoId && (variacionId == null || i['variacionId'] == variacionId),
        orElse: () => <String, dynamic>{},
      );
      
      if (item.isNotEmpty) {
        // El stock puede venir en diferentes formatos según el backend
        return (item['stock'] as int? ?? 
                item['stockDisponible'] as int? ?? 
                item['available_stock'] as int? ?? 
                999); // Si no hay stock definido, asumir que hay suficiente
      }
      return 999; // Si no se encuentra el item, asumir stock alto
    } catch (e) {
      print('Error al obtener stock disponible: $e');
      return 999;
    }
  }

  /// Verificar si se puede aumentar la cantidad
  bool puedeAumentarCantidad(String productoId, {String? variacionId}) {
    try {
      final cantidadActual = obtenerCantidadProducto(productoId, variacionId: variacionId);
      final stockDisponible = obtenerStockDisponible(productoId, variacionId: variacionId);
      
      return cantidadActual < stockDisponible;
    } catch (e) {
      print('Error al verificar si puede aumentar cantidad: $e');
      return true; // En caso de error, permitir aumentar
    }
  }

  /// Obtener carrito completo
  Future<void> obtenerCarrito(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _carritoData = await _carritoService.obtenerCarrito(token);
      
      // También obtener el modelo si lo necesitas
      _carritoModelo = await _carritoService.obtenerCarritoModelo(token);
      
      _error = null;
    } catch (e) {
      _error = _handleError(e);
      _carritoData = null;
      _carritoModelo = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtener resumen del carrito
  Future<void> obtenerResumen(String token) async {
    try {
      _resumen = await _carritoService.obtenerResumen(token);
      notifyListeners();
    } catch (e) {
      print('Error al obtener resumen: $e');
      _resumen = null;
    }
  }

  /// Agregar producto al carrito (método simple)
  Future<bool> agregarProducto(String token, String productoId, int cantidad) async {
    _isAdding = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.agregarProducto(token, productoId, cantidad);
      
      if (success) {
        // Recargar carrito después de agregar
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo agregar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  /// Agregar producto con validación
  Future<bool> agregarProductoConValidacion(String token, String productoId, int cantidad) async {
    _isAdding = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.agregarProductoConValidacion(token, productoId, cantidad);
      
      if (success) {
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo agregar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  /// Agregar producto base con variaciones
  Future<bool> agregarProductoBase(
    String token,
    String productoBaseId,
    int cantidad, {
    Map<String, dynamic>? variacionSeleccionada,
  }) async {
    _isAdding = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.agregarProductoBase(
        token,
        productoBaseId,
        cantidad,
        variacionSeleccionada: variacionSeleccionada,
      );
      
      if (success) {
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo agregar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  /// Agregar producto completo (con request model)
  Future<bool> agregarProductoCompleto(String token, AgregarAlCarritoRequest request) async {
    _isAdding = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.agregarProductoCompleto(token, request);
      
      if (success) {
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo agregar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isAdding = false;
      notifyListeners();
    }
  }

  /// Actualizar cantidad de producto
  Future<bool> actualizarCantidad(String token, String productoId, int cantidad) async {
    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.actualizarCantidad(token, productoId, cantidad);
      
      if (success) {
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo actualizar la cantidad';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Actualizar cantidad con variación (sin recargar todo el carrito) y validación de stock
  Future<bool> actualizarCantidadConVariacion(
    String token,
    String productoId,
    int cantidad, {
    String? variacionId,
  }) async {
    // Validar stock ANTES de hacer la petición
    final stockDisponible = obtenerStockDisponible(productoId, variacionId: variacionId);
    
    if (cantidad > stockDisponible) {
      _error = 'Stock insuficiente. Solo hay $stockDisponible unidades disponibles';
      notifyListeners();
      return false;
    }

    _isUpdating = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.actualizarCantidadConVariacion(
        token,
        productoId,
        cantidad,
        variacionId: variacionId,
      );
      
      if (success) {
        // NO recargar todo el carrito, solo actualizar localmente
        _actualizarCantidadLocal(productoId, cantidad, variacionId);
        return true;
      } else {
        _error = 'No se pudo actualizar la cantidad';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }

  /// Actualizar cantidad localmente sin recargar desde el servidor
  void _actualizarCantidadLocal(String productoId, int nuevaCantidad, String? variacionId) {
    if (_carritoData == null || _carritoData!['items'] == null) return;

    final items = _carritoData!['items'] as List<dynamic>;
    
    for (int i = 0; i < items.length; i++) {
      final itemId = items[i]['productoId'] ?? items[i]['id'] ?? '';
      final itemVariacionId = items[i]['variacionId'] ?? items[i]['variation_id'] ?? '';
      
      bool esElMismoItem = itemId == productoId;
      if (variacionId != null && variacionId.isNotEmpty) {
        esElMismoItem = esElMismoItem && (itemVariacionId == variacionId);
      } else {
        esElMismoItem = esElMismoItem && (itemVariacionId.isEmpty);
      }
      
      if (esElMismoItem) {
        final precioUnitario = (items[i]['precioUnitario'] ?? items[i]['unitPrice'] ?? 0.0).toDouble();
        
        items[i]['cantidad'] = nuevaCantidad;
        items[i]['quantity'] = nuevaCantidad;
        items[i]['precio'] = precioUnitario * nuevaCantidad;
        items[i]['price'] = precioUnitario * nuevaCantidad;
        
        // Recalcular el total
        _recalcularTotal();
        notifyListeners();
        break;
      }
    }
  }

  /// Recalcular el total del carrito
  void _recalcularTotal() {
    if (_carritoData == null || _carritoData!['items'] == null) return;

    final items = _carritoData!['items'] as List<dynamic>;
    double total = 0.0;

    for (var item in items) {
      final precio = (item['precio'] ?? item['price'] ?? 0.0).toDouble();
      total += precio;
    }

    _carritoData!['total'] = total;
  }

  /// Incrementar cantidad de un producto CON VALIDACIÓN DE STOCK
  Future<bool> incrementarCantidad(String token, String productoId, {String? variacionId}) async {
    try {
      final item = items.firstWhere(
        (i) => i['productoId'] == productoId && (variacionId == null || i['variacionId'] == variacionId),
        orElse: () => <String, dynamic>{},
      );
      
      if (item.isNotEmpty) {
        final cantidadActual = item['cantidad'] as int;
        final stockDisponible = obtenerStockDisponible(productoId, variacionId: variacionId);
        
        // Validar si se puede aumentar
        if (cantidadActual >= stockDisponible) {
          _error = 'Stock máximo alcanzado ($stockDisponible unidades disponibles)';
          notifyListeners();
          return false;
        }
        
        final nuevaCantidad = cantidadActual + 1;
        return await actualizarCantidadConVariacion(token, productoId, nuevaCantidad, variacionId: variacionId);
      }
      return false;
    } catch (e) {
      print('Error en incrementarCantidad: $e');
      _error = 'Error al aumentar la cantidad';
      notifyListeners();
      return false;
    }
  }

  /// Decrementar cantidad de un producto
  Future<bool> decrementarCantidad(String token, String productoId, {String? variacionId}) async {
    try {
      final item = items.firstWhere(
        (i) => i['productoId'] == productoId && (variacionId == null || i['variacionId'] == variacionId),
        orElse: () => <String, dynamic>{},
      );
      
      if (item.isNotEmpty) {
        final cantidadActual = item['cantidad'] as int;
        if (cantidadActual > 1) {
          final nuevaCantidad = cantidadActual - 1;
          return await actualizarCantidadConVariacion(token, productoId, nuevaCantidad, variacionId: variacionId);
        } else {
          // Si la cantidad es 1, eliminar el producto
          return await eliminarProductoConVariacion(token, productoId, variacionId: variacionId);
        }
      }
      return false;
    } catch (e) {
      print('Error en decrementarCantidad: $e');
      return false;
    }
  }

  /// Eliminar producto del carrito
  Future<bool> eliminarProducto(String token, String productoId) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.eliminarProducto(token, productoId);
      
      if (success) {
        await obtenerCarrito(token);
        return true;
      } else {
        _error = 'No se pudo eliminar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Eliminar producto con variación (sin recargar todo)
  Future<bool> eliminarProductoConVariacion(
    String token,
    String productoId, {
    String? variacionId,
  }) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.eliminarProductoConVariacion(
        token,
        productoId,
        variacionId: variacionId,
      );
      
      if (success) {
        // NO recargar todo, solo eliminar localmente
        _eliminarProductoLocal(productoId, variacionId);
        return true;
      } else {
        _error = 'No se pudo eliminar el producto';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Eliminar producto localmente
  void _eliminarProductoLocal(String productoId, String? variacionId) {
    if (_carritoData == null || _carritoData!['items'] == null) return;

    final items = _carritoData!['items'] as List<dynamic>;
    
    items.removeWhere((item) {
      final itemId = item['productoId'] ?? item['id'] ?? '';
      final itemVariacionId = item['variacionId'] ?? item['variation_id'] ?? '';
      
      bool esElMismoItem = itemId == productoId;
      if (variacionId != null && variacionId.isNotEmpty) {
        esElMismoItem = esElMismoItem && (itemVariacionId == variacionId);
      } else {
        esElMismoItem = esElMismoItem && (itemVariacionId.isEmpty);
      }
      
      return esElMismoItem;
    });

    _carritoData!['items'] = items;
    _recalcularTotal();
    notifyListeners();
  }

  /// Vaciar carrito completamente
  Future<bool> vaciarCarrito(String token) async {
    _isDeleting = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _carritoService.vaciarCarrito(token);
      
      if (success) {
        _carritoData = {'items': [], 'total': 0.0};
        _carritoModelo = null;
        _resumen = null;
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo vaciar el carrito';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _handleError(e);
      notifyListeners();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }

  /// Verificar si un producto está en el carrito
  bool tieneProducto(String productoId, {String? variacionId}) {
    return items.any((item) =>
      item['productoId'] == productoId &&
      (variacionId == null || item['variacionId'] == variacionId)
    );
  }

  /// Obtener cantidad de un producto específico
  int obtenerCantidadProducto(String productoId, {String? variacionId}) {
    try {
      final item = items.firstWhere(
        (i) => i['productoId'] == productoId && (variacionId == null || i['variacionId'] == variacionId),
        orElse: () => <String, dynamic>{},
      );
      return item.isNotEmpty ? (item['cantidad'] as int? ?? 0) : 0;
    } catch (e) {
      print('Error en obtenerCantidadProducto: $e');
      return 0;
    }
  }

  /// Limpiar el estado local del carrito
  void limpiarEstado() {
    _carritoData = null;
    _carritoModelo = null;
    _resumen = null;
    _error = null;
    _isLoading = false;
    _isAdding = false;
    _isUpdating = false;
    _isDeleting = false;
    notifyListeners();
  }

  /// Manejo centralizado de errores
  String _handleError(dynamic error) {
    final errorString = error.toString();
    
    if (errorString.contains('Unauthorized') || errorString.contains('401')) {
      return 'Sesión expirada. Por favor, inicia sesión nuevamente.';
    } else if (errorString.contains('ID de producto vacío')) {
      return 'Error: ID de producto inválido';
    } else if (errorString.contains('Connection') || errorString.contains('Network')) {
      return 'Error de conexión. Verifica tu internet.';
    } else if (errorString.contains('stock') || errorString.contains('Stock')) {
      return errorString.replaceFirst('Exception: ', '');
    } else if (errorString.contains('Exception: ')) {
      return errorString.replaceFirst('Exception: ', '');
    } else {
      return 'Ha ocurrido un error. Por favor, intenta nuevamente.';
    }
  }

  /// Refrescar carrito (útil para pull-to-refresh)
  Future<void> refrescarCarrito(String token) async {
    await obtenerCarrito(token);
    await obtenerResumen(token);
  }
}