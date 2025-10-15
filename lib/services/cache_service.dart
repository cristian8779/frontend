import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const String _productosKey = 'productos_cache';
  static const String _categoriasKey = 'categorias_cache';
  static const String _timestampKey = 'cache_timestamp';
  static const Duration _cacheDuration = Duration(minutes: 10);

  // Guardar productos en caché
  static Future<void> guardarProductos(List<Map<String, dynamic>> productos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final productosJson = jsonEncode(productos);
      await prefs.setString(_productosKey, productosJson);
      await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      print('Error guardando productos en caché: $e');
    }
  }

  // Obtener productos del caché
  static Future<List<Map<String, dynamic>>?> obtenerProductos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Verificar si el caché ha expirado
      if (!_esCacheValido(prefs)) {
        return null;
      }

      final productosJson = prefs.getString(_productosKey);
      if (productosJson == null) return null;

      final List<dynamic> decoded = jsonDecode(productosJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo productos del caché: $e');
      return null;
    }
  }

  // Guardar categorías en caché
  static Future<void> guardarCategorias(List<Map<String, dynamic>> categorias) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriasJson = jsonEncode(categorias);
      await prefs.setString(_categoriasKey, categoriasJson);
    } catch (e) {
      print('Error guardando categorías en caché: $e');
    }
  }

  // Obtener categorías del caché
  static Future<List<Map<String, dynamic>>?> obtenerCategorias() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (!_esCacheValido(prefs)) {
        return null;
      }

      final categoriasJson = prefs.getString(_categoriasKey);
      if (categoriasJson == null) return null;

      final List<dynamic> decoded = jsonDecode(categoriasJson);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error obteniendo categorías del caché: $e');
      return null;
    }
  }

  // Verificar si el caché es válido
  static bool _esCacheValido(SharedPreferences prefs) {
    final timestamp = prefs.getInt(_timestampKey);
    if (timestamp == null) return false;

    final cacheDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    return now.difference(cacheDate) < _cacheDuration;
  }

  // Limpiar caché
  static Future<void> limpiarCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_productosKey);
      await prefs.remove(_categoriasKey);
      await prefs.remove(_timestampKey);
    } catch (e) {
      print('Error limpiando caché: $e');
    }
  }

  // Verificar si hay datos en caché
  static Future<bool> tieneDatosEnCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _esCacheValido(prefs) && 
             prefs.containsKey(_productosKey) && 
             prefs.containsKey(_categoriasKey);
    } catch (e) {
      return false;
    }
  }
}