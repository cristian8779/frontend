import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración centralizada
class ProductoConfig {
  static const Duration timeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
}

/// Excepciones personalizadas
class ProductoException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;

  ProductoException(this.message, {this.code, this.statusCode});

  @override
  String toString() => 'ProductoException: $message';
}

class NetworkException extends ProductoException {
  NetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class AuthException extends ProductoException {
  AuthException(String message)
      : super(message, code: 'AUTH_ERROR', statusCode: 401);
}

/// DTO para filtros de búsqueda - CORREGIDO CON PAGINACIÓN
class FiltrosBusqueda {
  final String? query;
  final String? categoria;
  final String? subcategoria;
  final List<String>? colores;
  final List<String>? tallas;
  final List<String>? tallasLetra;
  final List<String>? tallasNumero;
  final double? precioMin;
  final double? precioMax;

  /// Parámetros de paginación
  final int? page;
  final int? limit;

  FiltrosBusqueda({
    this.query,
    this.categoria,
    this.subcategoria,
    this.colores,
    this.tallas,
    this.tallasLetra,
    this.tallasNumero,
    this.precioMin,
    this.precioMax,
    this.page,
    this.limit,
  });

  List<String>? get tallasLetraCalculadas {
    if (tallasLetra != null && tallasLetra!.isNotEmpty) return tallasLetra;
    if (tallas == null || tallas!.isEmpty) return null;

    return tallas!
        .where((t) => !RegExp(r'^\d+(\.\d+)?$').hasMatch(t.trim()))
        .toList();
  }

  List<String>? get tallasNumeroCalculadas {
    if (tallasNumero != null && tallasNumero!.isNotEmpty) return tallasNumero;
    if (tallas == null || tallas!.isEmpty) return null;

    return tallas!
        .where((t) => RegExp(r'^\d+(\.\d+)?$').hasMatch(t.trim()))
        .toList();
  }

  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};

    if (query?.isNotEmpty == true) params['busqueda'] = query!;
    if (categoria?.isNotEmpty == true) params['categoria'] = categoria!;
    if (subcategoria?.isNotEmpty == true) params['subcategoria'] = subcategoria!;
    if (colores?.isNotEmpty == true) params['colores'] = colores!.join(',');

    final tallasL = tallasLetraCalculadas;
    final tallasN = tallasNumeroCalculadas;

    if (tallasL?.isNotEmpty == true) params['tallaLetra'] = tallasL!.join(',');
    if (tallasN?.isNotEmpty == true) params['tallaNumero'] = tallasN!.join(',');

    if (precioMin != null) params['precioMin'] = precioMin.toString();
    if (precioMax != null) params['precioMax'] = precioMax.toString();

    /// 🔥 Paginación incluida
    if (page != null) params['page'] = page.toString();
    if (limit != null) params['limit'] = limit.toString();

    print('Query params generados: $params');
    return params;
  }

  @override
  String toString() {
    return 'FiltrosBusqueda(query: $query, categoria: $categoria, subcategoria: $subcategoria, '
        'colores: $colores, tallasLetra: $tallasLetraCalculadas, tallasNumero: $tallasNumeroCalculadas, '
        'precioMin: $precioMin, precioMax: $precioMax, page: $page, limit: $limit)';
  }
}

/// Servicio principal de productos
class ProductoService {
  final String _baseUrl = 'https://api.soportee.store/api';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _httpClient = http.Client();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  // === MANEJO DE AUTENTICACIÓN ===

  Future<String?> _getAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    _cachedToken = await _secureStorage.read(key: 'accessToken');
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

    return _cachedToken;
  }

  Future<bool> _renovarToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) return false;

      final response = await _httpClient.post(
        Uri.parse('${dotenv.env['API_URL']}/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      ).timeout(ProductoConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];

        await _secureStorage.write(key: 'accessToken', value: newToken);
        _cachedToken = newToken;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

        return true;
      }
      return false;
    } catch (e) {
      print('Error renovando token: $e');
      return false;
    }
  }

  Future<String> _obtenerTokenValido() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw AuthException('No hay token de acceso disponible');
    }
    return token;
  }

  // === UTILIDADES HTTP ===

  Map<String, String> _getHeaders([String? token]) {
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<T> _makeRequest<T>(
    Future<http.Response> Function() request,
    T Function(Map<String, dynamic>) parser, {
    bool requiresAuth = false,
    int retries = 0,
  }) async {
    try {
      final response = await request().timeout(ProductoConfig.timeout);

      if (response.statusCode == 401 && requiresAuth && retries == 0) {
        if (await _renovarToken()) {
          return _makeRequest(request, parser,
              requiresAuth: requiresAuth, retries: 1);
        }
        throw AuthException('No se pudo renovar el token');
      }

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(data);
      } else {
        throw ProductoException(
          data['mensaje'] ?? 'Error del servidor',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado');
    } catch (e) {
      if (e is ProductoException) rethrow;
      throw ProductoException('Error inesperado: $e');
    }
  }

  // === MÉTODOS PÚBLICOS PRINCIPALES ===

  /// ✅ Método con paginación incluida
  Future<Map<String, dynamic>> obtenerProductosPaginados(
      FiltrosBusqueda filtros) async {
    final queryParams = filtros.toQueryParams();
    final uri =
        Uri.parse('$_baseUrl/productos').replace(queryParameters: queryParams);

    print('URL final generada (paginada): $uri');

    return _makeRequest(
      () async {
        final token = await _getAccessToken();
        return _httpClient.get(uri, headers: _getHeaders(token));
      },
      (data) {
        if (data is Map<String, dynamic>) {
          return {
            'productos':
                List<Map<String, dynamic>>.from(data['productos'] ?? []),
            'total': data['total'] ?? 0,
            'hasMore': data['hasMore'] ?? false,
          };
        }
        return {
          'productos': <Map<String, dynamic>>[],
          'total': 0,
          'hasMore': false
        };
      },
    );
  }

  /// Versión sin paginación (devuelve lista directa)
  Future<List<Map<String, dynamic>>> obtenerProductos(
      [FiltrosBusqueda? filtros]) async {
    final queryParams = filtros?.toQueryParams() ?? <String, String>{};
    final uri =
        Uri.parse('$_baseUrl/productos').replace(queryParameters: queryParams);

    print('URL final generada: $uri');

    return _makeRequest(
      () async {
        final token = await _getAccessToken();
        return _httpClient.get(uri, headers: _getHeaders(token));
      },
      (data) {
        if (data is Map<String, dynamic> && data['productos'] is List) {
          final productos = List<Map<String, dynamic>>.from(data['productos']);
          print('Total productos encontrados: ${productos.length}');
          return productos;
        }
        return <Map<String, dynamic>>[];
      },
    );
  }

  Future<List<Map<String, dynamic>>> buscarProductos({
    String? query,
    String? categoria,
    String? subcategoria,
    List<String>? colores,
    List<String>? tallas,
    double? precioMin,
    double? precioMax,
  }) async {
    print('Iniciando búsqueda de productos con parámetros:');
    print('  Query: $query');
    print('  Categoria: $categoria');
    print('  Subcategoria: $subcategoria');
    print('  Colores: $colores');
    print('  Tallas: $tallas');
    print('  Rango precio: $precioMin - $precioMax');

    final filtros = FiltrosBusqueda(
      query: query,
      categoria: categoria,
      subcategoria: subcategoria,
      colores: colores,
      tallas: tallas,
      precioMin: precioMin,
      precioMax: precioMax,
    );

    print('Filtros construidos: $filtros');
    return obtenerProductos(filtros);
  }

  Future<List<Map<String, dynamic>>> buscarProductosConFiltros(
      FiltrosBusqueda filtros) async {
    return obtenerProductos(filtros);
  }

  Future<List<Map<String, dynamic>>> aplicarFiltros(
      Map<String, dynamic> filtrosMap) async {
    print('Aplicando filtros desde PantallaFiltros: $filtrosMap');

    final filtros = FiltrosBusqueda(
      query: filtrosMap['query'] as String?,
      categoria: filtrosMap['categoria'] as String?,
      subcategoria: filtrosMap['subcategoria'] as String?,
      colores: (filtrosMap['colores'] as List<dynamic>?)?.cast<String>(),
      tallas: (filtrosMap['tallas'] as List<dynamic>?)?.cast<String>(),
      precioMin: filtrosMap['precioMin'] as double?,
      precioMax: filtrosMap['precioMax'] as double?,
    );

    print('Filtros convertidos a FiltrosBusqueda: $filtros');
    return obtenerProductos(filtros);
  }

  Future<Map<String, dynamic>> obtenerProductoPorId(String id) async {
    final token = await _obtenerTokenValido();

    return _makeRequest(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/productos/$id'),
        headers: _getHeaders(token),
      ),
      (data) {
        if (data.containsKey('producto')) {
          return Map<String, dynamic>.from(data['producto']);
        }
        throw ProductoException('Formato de respuesta inválido');
      },
      requiresAuth: true,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerCategorias() async {
    final token = await _obtenerTokenValido();

    return _makeRequest(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/categorias'),
        headers: _getHeaders(token),
      ),
      (data) {
        if (data['categorias'] is List) {
          return List<Map<String, dynamic>>.from(data['categorias']);
        }
        throw ProductoException('Formato de categorías inválido');
      },
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> obtenerFiltrosDisponibles() async {
    final token = await _obtenerTokenValido();

    return _makeRequest(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/productos/filtros'),
        headers: _getHeaders(token),
      ),
      (data) {
        print('Filtros disponibles recibidos: $data');
        if (data is Map<String, dynamic>) {
          if (data.containsKey('filtros')) {
            return Map<String, dynamic>.from(data['filtros']);
          } else if (data.containsKey('filtrosDisponibles')) {
            return Map<String, dynamic>.from(data['filtrosDisponibles']);
          }
          return data;
        }
        return <String, dynamic>{};
      },
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> crearProducto({
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    String? subcategoria,
    int stock = 1,
    bool disponible = true,
    required String estado,
    required File imagenLocal,
  }) async {
    _validarDatosProducto(nombre, descripcion, precio, stock);

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos');

    final request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..fields['precio'] = precio.toString()
      ..fields['categoria'] = categoria
      ..fields['subcategoria'] = subcategoria ?? ''
      ..fields['stock'] = stock.toString()
      ..fields['disponible'] = disponible.toString()
      ..fields['estado'] = estado
      ..files.add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));

    try {
      final response = await request.send().timeout(ProductoConfig.timeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw ProductoException(
          error['mensaje'] ?? 'Error al crear el producto',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ProductoException) rethrow;
      throw ProductoException('Error al crear producto: $e');
    }
  }

  Future<Map<String, dynamic>> actualizarProducto({
    required String id,
    required String nombre,
    required String descripcion,
    required double precio,
    required String categoria,
    String? subcategoria,
    int stock = 1,
    bool disponible = true,
    required String estado,
    File? imagenLocal,
  }) async {
    _validarDatosProducto(nombre, descripcion, precio, stock);

    if (categoria.isEmpty) {
      throw ProductoException('La categoría es obligatoria');
    }

    final token = await _obtenerTokenValido();
    final url = Uri.parse('$_baseUrl/productos/$id');

    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..fields['nombre'] = nombre.trim()
      ..fields['descripcion'] = descripcion.trim()
      ..fields['precio'] = precio.toString()
      ..fields['categoria'] = categoria
      ..fields['subcategoria'] = subcategoria ?? ''
      ..fields['stock'] = stock.toString()
      ..fields['disponible'] = disponible.toString()
      ..fields['estado'] = estado;

    if (imagenLocal != null) {
      request.files
          .add(await http.MultipartFile.fromPath('imagen', imagenLocal.path));
    }

    try {
      final response = await request.send().timeout(ProductoConfig.timeout);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        final error = jsonDecode(responseBody);
        throw ProductoException(
          error['mensaje'] ?? 'Error al actualizar el producto',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ProductoException) rethrow;
      throw ProductoException('Error al actualizar producto: $e');
    }
  }

  Future<void> eliminarProducto(String id) async {
    final token = await _obtenerTokenValido();

    await _makeRequest(
      () => _httpClient.delete(
        Uri.parse('$_baseUrl/productos/$id'),
        headers: _getHeaders(token),
      ),
      (data) => null,
      requiresAuth: true,
    );
  }

  Future<Map<String, dynamic>> reducirStock(String id, int cantidad) async {
    final token = await _obtenerTokenValido();

    return _makeRequest(
      () => _httpClient.put(
        Uri.parse('$_baseUrl/productos/$id/reducir-stock'),
        headers: _getHeaders(token),
        body: jsonEncode({'cantidad': cantidad}),
      ),
      (data) => data,
      requiresAuth: true,
    );
  }

  Future<List<Map<String, dynamic>>> filtrarProductosConVariaciones({
    String? query,
    String? categoria,
    String? subcategoria,
    List<String>? colores,
    List<String>? tallas,
    double? precioMin,
    double? precioMax,
  }) async {
    print(
        'Llamando a filtrarProductosConVariaciones - delegando a buscarProductos');
    return buscarProductos(
      query: query,
      categoria: categoria,
      subcategoria: subcategoria,
      colores: colores,
      tallas: tallas,
      precioMin: precioMin,
      precioMax: precioMax,
    );
  }

  Map<String, dynamic> obtenerDetalleVariacion(Map<String, dynamic> producto) {
    if (!producto.containsKey('variaciones') ||
        (producto['variaciones'] as List).isEmpty) {
      return {};
    }

    return Map<String, dynamic>.from(producto['variaciones'][0]);
  }

  void _validarDatosProducto(
      String nombre, String descripcion, double precio, int stock) {
    if (nombre.trim().isEmpty) {
      throw ProductoException('El nombre es obligatorio');
    }
    if (descripcion.trim().isEmpty) {
      throw ProductoException('La descripción es obligatoria');
    }
    if (precio <= 0) {
      throw ProductoException('El precio debe ser mayor a 0');
    }
    if (stock < 0) {
      throw ProductoException('El stock no puede ser negativo');
    }
  }
}
