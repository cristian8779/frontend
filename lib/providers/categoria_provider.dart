import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/categoria_service.dart';

class CategoriaProvider extends ChangeNotifier {
  final CategoriaService _service = CategoriaService();

  List<Map<String, dynamic>> categorias = [];
  bool isLoading = false;
  String? error;

  CategoriaProvider() {
    cargarCategorias();
  }

  /// 🔹 Cargar categorías
  /// mostrarLoading: si es false, no cambia el estado de loading para refresh
  Future<void> cargarCategorias({bool forceRefresh = false, bool mostrarLoading = true}) async {
    if (categorias.isNotEmpty && !forceRefresh) return;

    // 🔹 Revisar conectividad antes de hacer la llamada
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // No hay conexión, dejamos que el toast global lo maneje
      error = null;
      return;
    }

    try {
      if (mostrarLoading) {
        isLoading = true;
        notifyListeners();
      }

      final nuevasCategorias = await _service.obtenerCategorias();

      if (nuevasCategorias.isNotEmpty) {
        categorias = nuevasCategorias;
      }

      error = null;
    } catch (e) {
      // Guardamos errores solo si no hay datos
      if (categorias.isEmpty) {
        error = e.toString();
      }
    } finally {
      if (mostrarLoading) {
        isLoading = false;
        notifyListeners();
      } else {
        // 🔹 Refrescar datos sin mostrar loading
        notifyListeners();
      }
    }
  }
}
