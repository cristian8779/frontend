import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/producto_service.dart';

class ProductosProvider extends ChangeNotifier {
  final ProductoService _productoService = ProductoService();

  List<Map<String, dynamic>> _productos = [];
  bool _isLoading = false;
  String? _error;

  int _page = 0;
  final int _limit = 20;
  bool _hasMore = true;

  // Cache con timestamp
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  List<Map<String, dynamic>> get productos => _productos;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;

  /// 🔹 Cargar productos iniciales o refrescar
  Future<void> cargarProductos({
    bool forceRefresh = false,
    bool mostrarLoading = true,
  }) async {
    if (!forceRefresh &&
        _productos.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      print("⏩ Usando cache de productos (última carga hace menos de 5 min)");
      return;
    }

    _page = 0;

    if (forceRefresh) {
      print("🔄 Refrescando productos (forceRefresh: true)...");
      _productos.clear();
      notifyListeners(); // ✅ Notificar inmediatamente para limpiar la UI
    }

    _hasMore = true;
    await _fetchProductos(append: false, mostrarLoading: mostrarLoading);
  }

  /// 🔹 Cargar más productos (scroll infinito)
  Future<void> cargarMasProductos({bool mostrarLoading = true}) async {
    if (_isLoading || !_hasMore) {
      print("⚠️ No se cargan más productos (isLoading=$_isLoading, hasMore=$_hasMore)");
      return;
    }
    _page++;
    print("➡️ Cargando más productos (página $_page)...");
    await _fetchProductos(append: true, mostrarLoading: mostrarLoading);
  }

  /// 🔹 Lógica interna
  Future<void> _fetchProductos({
    bool append = false,
    bool mostrarLoading = true,
  }) async {
    if (mostrarLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final response = await _productoService.obtenerProductosPaginados(
        FiltrosBusqueda(page: _page, limit: _limit),
      );

      final nuevosProductos =
          List<Map<String, dynamic>>.from(response['productos'] ?? []);
      final total = response['total'] ?? 0;

      if (append) {
        _productos.addAll(nuevosProductos);
      } else {
        _productos = nuevosProductos;
      }

      _hasMore = _productos.length < total;
      _lastFetch = DateTime.now();
      _error = null;

      print('📦 Página $_page cargada: ${nuevosProductos.length} productos (total: $total, hasMore: $_hasMore)');

      // 🔹 Auto-cargar la última página si falta menos de un "limit"
      if (!append &&
          _productos.length < total &&
          (total - _productos.length) <= _limit) {
        print('⚡ Auto-cargando la última página porque faltan pocos productos...');
        await cargarMasProductos(mostrarLoading: false);
      }
    } on SocketException {
      _error = 'Sin conexión a internet';
      print("❌ Error: $_error");
    } on TimeoutException {
      _error = 'Tiempo de espera agotado';
      print("❌ Error: $_error");
    } catch (e) {
      _error = 'Error inesperado: $e';
      print('❌ Error cargando productos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Productos aleatorios
  List<Map<String, dynamic>> obtenerProductosAleatorios(int cantidad) {
    if (_productos.isEmpty) return [];
    final copia = List<Map<String, dynamic>>.from(_productos);
    copia.shuffle();
    return copia.take(cantidad).toList();
  }

  /// 🔹 Filtrar por categoría
  List<Map<String, dynamic>> filtrarPorCategoria(String? categoria) {
    if (categoria == null || categoria.isEmpty) return _productos;
    return _productos.where((p) {
      final cat = p['categoria']?.toString().toLowerCase();
      return cat == categoria.toLowerCase();
    }).toList();
  }

  /// 🔹 Reset
  void limpiarCache() {
    print("🧹 Limpiando cache de productos...");
    _productos.clear();
    _page = 0;
    _hasMore = true;
    _lastFetch = null;
    _error = null;
    notifyListeners();
  }
}
