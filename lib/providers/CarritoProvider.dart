// lib/providers/CarritoProvider.dart
import 'package:flutter/material.dart';
import '../services/carrito_service.dart';
import '../models/resumen_carrito.dart';

class CarritoProvider with ChangeNotifier {
  final CarritoService _carritoService = CarritoService();

  int _cantidadTotal = 0;
  double _totalPrecio = 0.0;
  List productos = [];

  int get cantidadTotal => _cantidadTotal;
  double get totalPrecio => _totalPrecio;
  List get productosCarrito => productos;

  /// 🔹 Cargar el resumen completo del carrito desde el backend
  Future<void> cargarCarrito(String token) async {
    try {
      final ResumenCarrito? resumen = await _carritoService.obtenerResumen(token);
      if (resumen != null) {
        _cantidadTotal = resumen.totalItems;
        _totalPrecio = resumen.total;
        productos = resumen.productos;

        print("🛒 Carrito cargado: $_cantidadTotal items - Total: $_totalPrecio");
        notifyListeners();
      }
    } catch (e) {
      print("❌ Error cargando carrito: $e");
    }
  }

  /// 🔹 Incrementar cantidad (tiempo real en la UI)
  void incrementarCantidad() {
    _cantidadTotal++;
    notifyListeners();
  }

  /// 🔹 Decrementar cantidad (tiempo real en la UI)
  void decrementarCantidad() {
    if (_cantidadTotal > 0) {
      _cantidadTotal--;
      notifyListeners();
    }
  }

  /// 🔹 Reemplazar cantidad directamente
  void actualizarCantidad(int nuevaCantidad) {
    _cantidadTotal = nuevaCantidad;
    notifyListeners();
  }

  /// 🔹 Vaciar carrito localmente
  void limpiarCarrito() {
    _cantidadTotal = 0;
    _totalPrecio = 0.0;
    productos = [];
    notifyListeners();
  }
}
