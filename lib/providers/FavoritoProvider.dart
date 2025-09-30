import 'package:flutter/material.dart';
import '../../services/FavoritoService.dart';

class FavoritoProvider extends ChangeNotifier {
  final FavoritoService _favoritoService = FavoritoService();
  List<Map<String, dynamic>> _favoritos = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get favoritos => _favoritos;
  bool get isLoading => _isLoading;

  /// 📋 Cargar lista inicial
  Future<void> cargarFavoritos() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _favoritoService.obtenerFavoritos();
      // 🔄 Filtrar favoritos con datos válidos
      _favoritos = data.where((fav) {
        return fav != null &&
                fav['producto'] != null &&
                fav['producto']['_id'] != null;
      }).toList();
    } catch (e) {
      print('❌ Error en cargarFavoritos: $e');
      _favoritos = []; // Asegurar que no quede null
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ❤️ Agregar favorito
  Future<void> agregarFavorito(String productoId) async {
    try {
      final nuevo = await _favoritoService.agregarFavorito(productoId);
      
      // ✅ Verificar que el favorito tenga datos válidos antes de agregarlo
      if (nuevo != null &&
          nuevo['producto'] != null &&
          nuevo['producto']['_id'] != null) {
        _favoritos.add(nuevo);
        notifyListeners();
      } else {
        print('⚠️ Favorito agregado pero con datos incompletos');
        // Recargar la lista completa para mantener consistencia
        await cargarFavoritos();
      }
    } catch (e) {
      print('❌ Error en agregarFavorito: $e');
      rethrow;
    }
  }

  /// 🗑️ Eliminar favorito
  Future<void> eliminarFavorito(String productoId) async {
    try {
      await _favoritoService.eliminarFavorito(productoId);
      
      // 🔄 Eliminar usando null safety
      _favoritos.removeWhere((fav) {
        if (fav == null || fav['producto'] == null) return false;
        return fav['producto']['_id'] == productoId;
      });
      
      notifyListeners();
    } catch (e) {
      print('❌ Error en eliminarFavorito: $e');
      rethrow;
    }
  }

  /// 🔄 Limpiar todos los favoritos (para logout)
  void limpiarFavoritos() {
    _favoritos.clear();
    _isLoading = false;
    notifyListeners();
    print('🧹 Favoritos limpiados después del logout');
  }

  /// 🔍 Verificar si un producto está en favoritos (con null safety)
  bool esFavorito(String productoId) {
    if (productoId.isEmpty || _favoritos.isEmpty) return false;
    
    try {
      return _favoritos.any((fav) {
        // ✅ Verificaciones de null safety
        if (fav == null) return false;
        if (fav['producto'] == null) return false;
        if (fav['producto']['_id'] == null) return false;
        
        return fav['producto']['_id'] == productoId;
      });
    } catch (e) {
      print('❌ Error en esFavorito: $e');
      return false; // En caso de error, asumir que no es favorito
    }
  }

  /// 🧹 Limpiar favoritos inválidos (método de utilidad)
  void limpiarFavoritosInvalidos() {
    final favoritosValidos = _favoritos.where((fav) {
      return fav != null &&
             fav['producto'] != null &&
             fav['producto']['_id'] != null;
    }).toList();
    
    if (favoritosValidos.length != _favoritos.length) {
      _favoritos = favoritosValidos;
      notifyListeners();
      print('🧹 Se eliminaron ${_favoritos.length - favoritosValidos.length} favoritos inválidos');
    }
  }

  /// 📊 Obtener información de debug
  Map<String, dynamic> getDebugInfo() {
    final validos = _favoritos.where((fav) {
      return fav != null &&
             fav['producto'] != null &&
             fav['producto']['_id'] != null;
    }).length;
    
    return {
      'total': _favoritos.length,
      'validos': validos,
      'invalidos': _favoritos.length - validos,
      'isLoading': _isLoading,
    };
  }

  /// 🔄 Refrescar favoritos (útil para pull-to-refresh)
  Future<void> refrescarFavoritos() async {
    await cargarFavoritos();
  }

  /// 🔢 Obtener cantidad de favoritos
  int get cantidadFavoritos => _favoritos.length;

  /// 🆔 Obtener IDs de productos favoritos
  List<String> get idsFavoritos {
    return _favoritos
        .where((fav) => 
            fav != null && 
            fav['producto'] != null && 
            fav['producto']['_id'] != null)
        .map((fav) => fav['producto']['_id'] as String)
        .toList();
  }
}