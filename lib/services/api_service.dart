import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Nota: La URL base apunta directamente a la ruta de productos.
  final String baseUrl = 'https://crud-master-api.onrender.com/api/productos';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token no encontrado");

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse is List) {
          return List<Map<String, dynamic>>.from(jsonResponse);
        } else if (jsonResponse is Map<String, dynamic> &&
            jsonResponse.containsKey('productos')) {
          return List<Map<String, dynamic>>.from(jsonResponse['productos']);
        }
        return [];
      } else {
        throw Exception("Error ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      print("❌ Error en getProducts: $e");
      return [];
    }
  }

  // 🔹 Crear producto enviando la imagen en el mismo request
  Future<bool> createProduct(
      String nombre, String descripcion, double precio, String filePath) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token no encontrado");

      var uri = Uri.parse(baseUrl);
      var request = http.MultipartRequest('POST', uri);
      request.headers["Authorization"] = "Bearer $token";

      request.fields['nombre'] = nombre;
      request.fields['descripcion'] = descripcion;
      request.fields['precio'] = precio.toString();

      if (filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('imagen', filePath));
      }

      var response = await request.send();
      if (response.statusCode == 201) {
        return true;
      } else {
        var responseData = await response.stream.bytesToString();
        throw Exception("Error ${response.statusCode}: $responseData");
      }
    } catch (e) {
      print("❌ Error en createProduct: $e");
      return false;
    }
  }

  // 🔹 Actualizar producto enviando opcionalmente una nueva imagen
  Future<bool> updateProduct(String id, String nombre, String descripcion,
      double precio, String? filePath) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token no encontrado");

      var uri = Uri.parse('$baseUrl/$id');
      var request = http.MultipartRequest('PUT', uri);
      request.headers["Authorization"] = "Bearer $token";

      request.fields['nombre'] = nombre;
      request.fields['descripcion'] = descripcion;
      request.fields['precio'] = precio.toString();

      if (filePath != null && filePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('imagen', filePath));
      }

      var response = await request.send();
      if (response.statusCode == 200) {
        return true;
      } else {
        var responseData = await response.stream.bytesToString();
        throw Exception("Error ${response.statusCode}: $responseData");
      }
    } catch (e) {
      print("❌ Error en updateProduct: $e");
      return false;
    }
  }

  Future<bool> deleteProduct(String id) async {
    try {
      final token = await _getToken();
      if (token == null) throw Exception("Token no encontrado");

      final response = await http.delete(
        Uri.parse('$baseUrl/$id'),
        headers: {
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) return true;
      throw Exception("Error ${response.statusCode}: ${response.body}");
    } catch (e) {
      print("❌ Error en deleteProduct: $e");
      return false;
    }
  }
}
