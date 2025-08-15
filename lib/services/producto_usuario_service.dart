import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/variacion.dart';
import '../utils/colores.dart';

class ProductoUsuarioService {
  final String _baseUrl = 'https://api.soportee.store/api'; // URL base de la API
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Función para obtener la lista de productos sin necesidad de token
  Future<List<Map<String, dynamic>>> obtenerProductos() async {
    final url = Uri.parse('$_baseUrl/productos');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['productos'] != null && data['productos'] is List) {
          return List<Map<String, dynamic>>.from(data['productos']);
        } else {
          return [];
        }
      } else {
        throw Exception('❌ Error al cargar productos: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al obtener productos: $e');
    }
  }

  // Función para obtener un producto por ID sin necesidad de token
  Future<Map<String, dynamic>> obtenerProductoPorId(String id) async {
    final url = Uri.parse('$_baseUrl/productos/$id');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic> && data.containsKey('producto')) {
          return data['producto'];
        } else {
          throw Exception('❌ Formato inesperado al obtener el producto.');
        }
      } else {
        throw Exception('❌ Error al obtener el producto: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ Sin conexión: revisa tu Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al obtener el producto: $e');
    }
  }

  // Función para obtener las variaciones de un producto
  Future<List<Map<String, dynamic>>> obtenerVariacionesPorProducto(String productoId) async {
    final url = Uri.parse('$_baseUrl/productos/$productoId/variaciones');

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['variaciones'] != null && data['variaciones'] is List) {
          return List<Map<String, dynamic>>.from(data['variaciones']);
        } else {
          return [];
        }
      } else {
        throw Exception('❌ Error al obtener variaciones: ${response.body}');
      }
    } on SocketException {
      throw Exception('❌ Error de conexión: No hay Internet.');
    } catch (e) {
      throw Exception('❌ Error inesperado al obtener variaciones: $e');
    }
  }

  // Función para agregar un producto al carrito (requiere autenticación del usuario)
  Future<void> agregarAlCarrito(String productId) async {
    final token = await _obtenerTokenValido();  // Se obtiene el token

    final url = Uri.parse('$_baseUrl/carrito');
    final response = await http.post(
      url,
      headers: _getHeaders(token),  // Usamos el token para la autenticación
      body: jsonEncode({"productoId": productId}),
    );

    if (response.statusCode == 200) {
      print("Producto agregado al carrito");
    } else {
      throw Exception("❌ Error al agregar al carrito: ${response.body}");
    }
  }

  // Función para agregar una resena
  Future<void> agregarResena(String productoId, String resena) async {
    final token = await _obtenerTokenValido();  // Se obtiene el token

    final url = Uri.parse('$_baseUrl/productos/$productoId/resenas');
    final response = await http.post(
      url,
      headers: _getHeaders(token),  // Usamos el token para la autenticación
      body: jsonEncode({"resena": resena}),
    );

    if (response.statusCode == 200) {
      print("resena agregada correctamente");
    } else {
      throw Exception("❌ Error al agregar la resena: ${response.body}");
    }
  }

  // Función para marcar un producto como favorito
  Future<void> marcarComoFavorito(String productoId) async {
    final token = await _obtenerTokenValido();  // Se obtiene el token

    final url = Uri.parse('$_baseUrl/productos/$productoId/favorito');
    final response = await http.post(
      url,
      headers: _getHeaders(token),  // Usamos el token para la autenticación
      body: jsonEncode({"productoId": productoId}),
    );

    if (response.statusCode == 200) {
      print("Producto marcado como favorito");
    } else {
      throw Exception("❌ Error al marcar el producto como favorito: ${response.body}");
    }
  }

  // Función para obtener el token de acceso
  Future<String?> _getAccessToken() async {
    return await _secureStorage.read(key: 'accessToken');
  }

  // Función para obtener los encabezados con el token
  Map<String, String> _getHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  // Función para obtener un token válido (si está presente)
  Future<String> _obtenerTokenValido() async {
    String? token = await _getAccessToken();

    if (token == null) {
      throw Exception('❌ El token de acceso es nulo.');
    }

    return token;
  }
}
