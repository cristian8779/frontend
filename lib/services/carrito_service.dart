import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/carrito.dart';
import '../models/resumen_carrito.dart';
import '../models/request_models.dart';

class CarritoService {
  final String _baseUrl = '${dotenv.env['API_URL']}/carrito';

  // -------------------------------
  // UTILIDAD PARA ENMASCARAR TOKENS
  // -------------------------------
  String _enmascararId(String? id) {
    if (id == null || id.isEmpty) return 'VACIO';
    if (id.length <= 8) return '***';
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  /// Agregar producto al carrito - Método con debugging mejorado
  Future<bool> agregarProducto(String token, String productoId, int cantidad) async {
    try {
      // 🔍 Debug: Mostrar qué se está enviando (SIN token ni IDs completos)
      final requestBody = {
        'productoId': productoId,
        'cantidad': cantidad,
      };
      
      print('📤 Enviando al carrito:');
      print('   - URL: $_baseUrl');
      print('   - ProductoId: ${_enmascararId(productoId)}');
      print('   - Cantidad: $cantidad');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📥 Respuesta del servidor:');
      print('   - Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Producto agregado exitosamente');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al agregar producto (${response.statusCode})');
        
        // 🔍 Intentar parsear el error para más detalles
        try {
          final errorData = json.decode(response.body);
          if (errorData is Map && errorData.containsKey('mensaje')) {
            throw Exception(errorData['mensaje']);
          } else if (errorData is Map && errorData.containsKey('error')) {
            throw Exception(errorData['error']);
          }
        } catch (parseError) {
          // Si no se puede parsear, usar mensaje genérico
        }
        
        return false;
      }
    } catch (e) {
      print('❌ Excepción en agregarProducto: $e');
      rethrow; // Re-lanzar la excepción para que se muestre en la UI
    }
  }

  /// Agregar producto con validación de ID
  Future<bool> agregarProductoConValidacion(String token, String productoId, int cantidad) async {
    // 🔍 Validar que el productoId no esté vacío y tenga formato correcto
    if (productoId.isEmpty) {
      throw Exception('ID de producto vacío');
    }
    
    // Si parece ser un ID de variación (muy largo o con formato específico),
    // podría necesitar un endpoint diferente
    if (productoId.length > 50) {
      print('⚠️  ID muy largo, podría ser ID de variación');
    }
    
    return await agregarProducto(token, productoId, cantidad);
  }

  /// Método alternativo: Agregar producto base siempre
  Future<bool> agregarProductoBase(String token, String productoBaseId, int cantidad, {Map<String, dynamic>? variacionSeleccionada}) async {
    try {
      final requestBody = {
        'productoId': productoBaseId, // Siempre el ID del producto base
        'cantidad': cantidad,
      };

      // Si hay variación seleccionada, agregarla como metadata
      if (variacionSeleccionada != null) {
        // Dependiendo de cómo maneje tu backend las variaciones:
        if (variacionSeleccionada['id'] != null) {
          requestBody['variacionId'] = variacionSeleccionada['id'];
        }
        if (variacionSeleccionada['color'] != null) {
          requestBody['color'] = variacionSeleccionada['color'];
        }
        if (variacionSeleccionada['talla'] != null) {
          requestBody['talla'] = variacionSeleccionada['talla'];
        }
      }

      print('📤 Enviando producto base');
      print('   - ProductoId: ${_enmascararId(productoBaseId)}');
      print('   - Cantidad: $cantidad');
      print('   - Con variación: ${variacionSeleccionada != null}');

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      print('📥 Respuesta: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al agregar producto base (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en agregarProductoBase: $e');
      return false;
    }
  }

  /// Obtener carrito completo (JWT) - Retorna modelo Carrito
  Future<Carrito?> obtenerCarritoModelo(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // ✅ Soporte para ambas respuestas: {carrito: {...}} o {...}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('carrito')) {
            return Carrito.fromJson(data['carrito']);
          } else {
            return Carrito.fromJson(data);
          }
        }
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al obtener carrito (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('❌ Excepción en obtenerCarritoModelo: $e');
      return null;
    }
  }

  /// Obtener carrito en formato JSON (método principal para tu UI actual)
  Future<Map<String, dynamic>?> obtenerCarrito(String token) async {
    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print('🔍 Carrito obtenido correctamente');

        // ✅ Adaptar respuesta del backend (productos → items + total)
        if (data is Map<String, dynamic> && data.containsKey('productos')) {
          final productos = data['productos'] as List<dynamic>;
          final items = productos.map((p) {
            final cantidad = p['cantidad'] ?? 1;
            final precioUnitario = (p['precio'] ?? 0).toDouble();
            
            return {
              'productoId': p['productoId'],
              'nombre': p['nombre'] ?? 'Producto',
              'precioUnitario': precioUnitario,
              'cantidad': cantidad,
              'precio': cantidad * precioUnitario,
              // 🖼️ AGREGAR CAMPOS DE IMAGEN - prueba diferentes nombres
              'imagen': p['imagen'] ?? p['image'] ?? p['imagenUrl'] ?? p['imageUrl'] ?? p['foto'] ?? '',
              'descripcion': p['descripcion'] ?? p['description'] ?? '',
              // ✨ NUEVOS CAMPOS PARA VARIACIONES
              'variacionId': p['variacionId'] ?? p['variation_id'] ?? '',
              'variacionNombre': p['variacionNombre'] ?? p['variation_name'] ?? '',
              'variacionValor': p['variacionValor'] ?? p['variation_value'] ?? '',
              'talla': p['talla'] ?? p['size'] ?? '',
              'color': p['color'] ?? '',
              // Incluir cualquier otro campo que pueda venir
              'categoria': p['categoria'] ?? p['category'] ?? '',
              'marca': p['marca'] ?? p['brand'] ?? '',
            };
          }).toList();

          final total = items.fold<double>(0.0, (acc, item) => acc + (item['precio'] as double));

          print('🔍 Total de items en carrito: ${items.length}');
          return {
            'items': items,
            'total': total,
          };
        }

        // Si ya viene en formato correcto, retornar tal como está
        return data;
        
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized'); // 🔐 solo en este caso mandamos al login
      } else {
        print('❌ Error al obtener carrito (${response.statusCode})');
        return {}; // devolvemos mapa vacío para no romper la UI
      }
    } catch (e) {
      print('❌ Excepción en obtenerCarrito: $e');
      return {};
    }
  }

  /// Obtener resumen del carrito (JWT) - Retorna modelo ResumenCarrito
  Future<ResumenCarrito?> obtenerResumen(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/resumen'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ResumenCarrito.fromJson(data);
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al obtener resumen (${response.statusCode})');
        return null;
      }
    } catch (e) {
      print('❌ Excepción en obtenerResumen: $e');
      return null;
    }
  }

  /// Obtener resumen en formato JSON (para compatibilidad)
  Future<Map<String, dynamic>?> obtenerResumenRaw(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/resumen'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      print('❌ Error al obtener resumen raw (${response.statusCode})');
      return {};
    }
  }

  /// Agregar producto al carrito - Método completo (con variaciones)
  Future<bool> agregarProductoCompleto(String token, AgregarAlCarritoRequest request) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al agregar producto completo (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en agregarProductoCompleto: $e');
      return false;
    }
  }

  /// Actualizar cantidad - Método simple (sin variaciones)
  Future<bool> actualizarCantidad(String token, String productoId, int cantidad) async {
    try {
      print('🔄 Actualizando cantidad: ProductoId ${_enmascararId(productoId)} -> Cantidad: $cantidad');
      
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productoId': productoId,
          'cantidad': cantidad,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Cantidad actualizada');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al actualizar cantidad (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en actualizarCantidad: $e');
      return false;
    }
  }

  /// Actualizar cantidad - Método con soporte para variaciones
  Future<bool> actualizarCantidadConVariacion(String token, String productoId, int cantidad, {String? variacionId}) async {
    try {
      final body = {
        'productoId': productoId,
        'cantidad': cantidad,
      };
      
      // Solo agregar variacionId si no está vacío
      if (variacionId != null && variacionId.isNotEmpty) {
        body['variacionId'] = variacionId;
      }

      print('🔄 Actualizando cantidad con variación');
      print('   - ProductoId: ${_enmascararId(productoId)}');
      print('   - Cantidad: $cantidad');
      print('   - VariacionId: ${variacionId != null ? _enmascararId(variacionId) : 'N/A'}');

      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Cantidad actualizada');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al actualizar cantidad con variación (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en actualizarCantidadConVariacion: $e');
      return false;
    }
  }

  /// Actualizar cantidad - Método completo (con variaciones usando request model)
  Future<bool> actualizarCantidadCompleto(String token, ActualizarCantidadRequest request) async {
    try {
      final response = await http.put(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al actualizar cantidad completo (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en actualizarCantidadCompleto: $e');
      return false;
    }
  }

  /// Eliminar producto - Método simple (sin variaciones)
  Future<bool> eliminarProducto(String token, String productoId) async {
    try {
      print('🗑️ Eliminando producto: ${_enmascararId(productoId)}');
      
      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'productoId': productoId,
        }),
      );

      if (response.statusCode == 200) {
        print('✅ Producto eliminado');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al eliminar producto (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en eliminarProducto: $e');
      return false;
    }
  }

  /// Eliminar producto - Método con soporte para variaciones
  Future<bool> eliminarProductoConVariacion(String token, String productoId, {String? variacionId}) async {
    try {
      final body = {
        'productoId': productoId,
      };
      
      // Solo agregar variacionId si no está vacío
      if (variacionId != null && variacionId.isNotEmpty) {
        body['variacionId'] = variacionId;
      }

      print('🗑️ Eliminando producto con variación');
      print('   - ProductoId: ${_enmascararId(productoId)}');
      print('   - VariacionId: ${variacionId != null ? _enmascararId(variacionId) : 'N/A'}');

      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        print('✅ Producto eliminado');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al eliminar producto con variación (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en eliminarProductoConVariacion: $e');
      return false;
    }
  }

  /// Eliminar producto - Método completo (con variaciones usando request model)
  Future<bool> eliminarProductoCompleto(String token, EliminarDelCarritoRequest request) async {
    try {
      final response = await http.delete(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al eliminar producto completo (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en eliminarProductoCompleto: $e');
      return false;
    }
  }

  /// Vaciar carrito usando JWT (método principal para usuarios)
  Future<bool> vaciarCarrito(String token) async {
    try {
      print('🗑️ Vaciando carrito completo');
      
      final response = await http.delete(
        Uri.parse('$_baseUrl/vaciar'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('✅ Carrito vaciado');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized');
      } else {
        print('❌ Error al vaciar carrito (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en vaciarCarrito: $e');
      return false;
    }
  }

  /// Vaciar carrito usando API Key (solo para microservicios)
  Future<bool> vaciarCarritoInterno(String userId, String apiKey) async {
    try {
      print('🗑️ Vaciando carrito interno para usuario: ${_enmascararId(userId)}');
      
      final response = await http.delete(
        Uri.parse('${dotenv.env['API_URL']}/carrito/vaciar/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Carrito interno vaciado');
        return true;
      } else {
        print('❌ Error al vaciar carrito interno (${response.statusCode})');
        return false;
      }
    } catch (e) {
      print('❌ Excepción en vaciarCarritoInterno: $e');
      return false;
    }
  }

  /// Obtener resumen usando API Key (solo para microservicios)
  Future<Map<String, dynamic>?> obtenerResumenInterno(String userId, String apiKey) async {
    try {
      print('🔍 Obteniendo resumen interno para usuario: ${_enmascararId(userId)}');
      
      final response = await http.get(
        Uri.parse('${dotenv.env['API_URL']}/carrito/resumen/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
        },
      );

      if (response.statusCode == 200) {
        print('✅ Resumen interno obtenido');
        return json.decode(response.body);
      } else {
        print('❌ Error al obtener resumen interno (${response.statusCode})');
        return {};
      }
    } catch (e) {
      print('❌ Excepción en obtenerResumenInterno: $e');
      return {};
    }
  }

  /// Obtener resumen interno como modelo ResumenCarrito
  Future<ResumenCarrito?> obtenerResumenInternoModelo(String userId, String apiKey) async {
    try {
      final data = await obtenerResumenInterno(userId, apiKey);
      if (data != null && data.isNotEmpty) {
        return ResumenCarrito.fromJson(data);
      }
      return null;
    } catch (e) {
      print('❌ Excepción en obtenerResumenInternoModelo: $e');
      return null;
    }
  }
}