import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuración centralizada para ventas
class VentaConfig {
  static const Duration timeout = Duration(seconds: 15);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(milliseconds: 500);
}

/// Excepciones personalizadas para ventas
class VentaException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  
  VentaException(this.message, {this.code, this.statusCode});
  
  @override
  String toString() => 'VentaException: $message';
}

class VentaNetworkException extends VentaException {
  VentaNetworkException(String message) : super(message, code: 'NETWORK_ERROR');
}

class VentaAuthException extends VentaException {
  VentaAuthException(String message) : super(message, code: 'AUTH_ERROR', statusCode: 401);
}

/// DTO para productos en una venta
class ProductoVenta {
  final String productoId;
  final String? variacionId;
  final String nombreProducto;
  final String? talla;
  final dynamic color; // Puede ser String o Map
  final int cantidad;
  final double precioUnitario;
  final String? imagen;

  ProductoVenta({
    required this.productoId,
    this.variacionId,
    required this.nombreProducto,
    this.talla,
    this.color,
    required this.cantidad,
    required this.precioUnitario,
    this.imagen,
  });

  Map<String, dynamic> toJson() {
    return {
      'productoId': productoId,
      if (variacionId != null) 'variacionId': variacionId,
      'nombre': nombreProducto, // Cambio: usar 'nombre' como en el backend
      'nombreProducto': nombreProducto, // Mantener compatibilidad
      if (talla != null) 'talla': talla,
      if (color != null) 'color': color,
      'cantidad': cantidad,
      'precio': precioUnitario, // Cambio: usar 'precio' como en el backend
      'precioUnitario': precioUnitario, // Mantener compatibilidad
      if (imagen != null) 'imagen': imagen,
      if (talla != null || color != null || imagen != null) 'atributos': {
        if (talla != null) 'tallaLetra': talla,
        if (color != null) 'color': color,
        if (imagen != null) 'imagen': imagen,
      },
    };
  }

  factory ProductoVenta.fromJson(Map<String, dynamic> json) {
    return ProductoVenta(
      productoId: json['productoId'] ?? '',
      variacionId: json['variacionId'],
      nombreProducto: json['nombreProducto'] ?? json['nombre'] ?? 'Producto eliminado',
      talla: json['talla'] ?? json['atributos']?['tallaLetra'],
      color: json['color'] ?? json['atributos']?['color'],
      cantidad: json['cantidad'] ?? 0,
      precioUnitario: (json['precioUnitario'] ?? json['precio'] ?? 0).toDouble(),
      imagen: json['imagen'] ?? json['atributos']?['imagen'],
    );
  }
}

/// DTO para filtros de ventas
class FiltrosVenta {
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? usuarioId;
  final String? producto;
  final String? estado;

  FiltrosVenta({
    this.fechaInicio,
    this.fechaFin,
    this.usuarioId,
    this.producto,
    this.estado,
  });

  Map<String, String> toQueryParams() {
    final Map<String, String> params = {};
    
    if (fechaInicio != null) {
      params['fechaInicio'] = fechaInicio!.toIso8601String();
    }
    if (fechaFin != null) {
      params['fechaFin'] = fechaFin!.toIso8601String();
    }
    if (usuarioId?.isNotEmpty == true) params['usuarioId'] = usuarioId!;
    if (producto?.isNotEmpty == true) params['producto'] = producto!;
    if (estado?.isNotEmpty == true) params['estado'] = estado!;
    
    print('🔎 Query params para ventas: $params');
    return params;
  }
}

/// Servicio principal de ventas
class VentaService {
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
      ).timeout(VentaConfig.timeout);

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
      print('❌ Error renovando token: $e');
      return false;
    }
  }

  Future<String> _obtenerTokenValido() async {
    final token = await _getAccessToken();
    if (token == null) {
      throw VentaAuthException('No hay token de acceso disponible');
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
    T Function(dynamic) parser, {
    bool requiresAuth = false,
    int retries = 0,
  }) async {
    try {
      final response = await request().timeout(VentaConfig.timeout);
      
      if (response.statusCode == 401 && requiresAuth && retries == 0) {
        if (await _renovarToken()) {
          return _makeRequest(request, parser, requiresAuth: requiresAuth, retries: 1);
        }
        throw VentaAuthException('No se pudo renovar el token');
      }
      
      print('📡 Status Code: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return parser(data);
      } else {
        throw VentaException(
          data['mensaje'] ?? 'Error del servidor',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw VentaNetworkException('Sin conexión a internet');
    } on TimeoutException {
      throw VentaNetworkException('Tiempo de espera agotado');
    } catch (e) {
      if (e is VentaException) rethrow;
      throw VentaException('Error inesperado: $e');
    }
  }

  // === HELPER PARA MAPEAR RESPUESTAS ===
  List<Map<String, dynamic>> _mapearVentas(dynamic data) {
    if (data is List) {
      return List<Map<String, dynamic>>.from(data);
    } else if (data is Map<String, dynamic>) {
      if (data.containsKey('ventas') && data['ventas'] is List) {
        return List<Map<String, dynamic>>.from(data['ventas']);
      }
      // Si la respuesta es una sola venta, devolverla como lista
      return [data];
    }
    return <Map<String, dynamic>>[];
  }

  // === MÉTODO PARA OBTENER INFORMACIÓN DE USUARIO ===
  Future<String?> obtenerNombreUsuario(String usuarioId) async {
    print('🔍 [VentaService] === OBTENIENDO NOMBRE USUARIO ===');
    print('👤 [VentaService] Usuario ID: $usuarioId');
    
    try {
      final token = await _obtenerTokenValido();
      print('🔑 [VentaService] Token obtenido para consulta de usuario');
      
      final url = '$_baseUrl/usuario/$usuarioId';
      print('🌐 [VentaService] URL de consulta: $url');
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      ).timeout(VentaConfig.timeout);

      print('📡 [VentaService] Status Code: ${response.statusCode}');
      print('📦 [VentaService] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📊 [VentaService] Datos del usuario recibidos: $data');
        
        if (data['usuario']?['nombre'] != null) {
          final nombre = data['usuario']['nombre'].toString().trim();
          print('✅ [VentaService] Nombre encontrado: $nombre');
          return nombre;
        } else {
          print('⚠️ [VentaService] No se encontró campo usuario.nombre');
          return 'Usuario ${usuarioId.substring(usuarioId.length - 8)}';
        }
      } else if (response.statusCode == 404) {
        print('❌ [VentaService] Usuario no encontrado (404)');
        return 'Usuario eliminado';
      } else {
        print('⚠️ [VentaService] Error HTTP: ${response.statusCode}');
        return 'Usuario desconocido';
      }
    } catch (e, stackTrace) {
      print('❌ [VentaService] Error obteniendo nombre de usuario $usuarioId: $e');
      print('📍 [VentaService] Stack trace: $stackTrace');
      return 'Usuario desconocido';
    } finally {
      print('🏁 [VentaService] === FIN OBTENER NOMBRE USUARIO ===');
    }
  }

  // === MÉTODOS PÚBLICOS PRINCIPALES ===

  /// 🆕 Crear venta pendiente (nueva funcionalidad del backend)
  Future<Map<String, dynamic>> crearVentaPendiente({
    required List<ProductoVenta> productos,
    required double total,
    required String referenciaPago,
  }) async {
    _validarDatosVenta(productos, total);
    
    final usuarioId = await _secureStorage.read(key: 'usuarioId');
    if (usuarioId == null || usuarioId.isEmpty) {
      throw VentaAuthException('No se encontró usuarioId en el dispositivo');
    }

    // No usar token para esta ruta, usa API key del backend
    return _makeRequest(
      () => _httpClient.post(
        Uri.parse('$_baseUrl/ventas/crear'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'usuarioId': usuarioId,
          'productos': productos.map((p) => p.toJson()).toList(),
          'total': total,
          'referenciaPago': referenciaPago,
        }),
      ),
      (data) => data,
      requiresAuth: false, // Esta ruta usa API key, no token de usuario
    );
  }

  /// 🔍 Buscar venta por referencia de pago
  Future<Map<String, dynamic>?> buscarVentaPorReferencia(String referenciaPago, {String? usuarioId}) async {
    try {
      final queryParams = <String, String>{};
      if (usuarioId != null) queryParams['usuarioId'] = usuarioId;
      
      final uri = Uri.parse('$_baseUrl/ventas/referencia/$referenciaPago').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _makeRequest(
        () => _httpClient.get(uri, headers: {'Content-Type': 'application/json'}),
        (data) => data,
        requiresAuth: false, // Esta ruta usa API key
      );
    } catch (e) {
      if (e is VentaException && e.statusCode == 404) {
        return null; // Venta no encontrada
      }
      rethrow;
    }
  }

  /// 💳 Confirmar pago de una venta (webhook interno)
  /// Nota: Este método probablemente no se use desde Flutter, es para webhooks
  Future<Map<String, dynamic>> confirmarPago({
    required String referenciaPago,
    required String estadoPagoBold,
  }) async {
    return _makeRequest(
      () => _httpClient.post(
        Uri.parse('$_baseUrl/ventas/confirmar-pago'), // Esta ruta no existe en las routes, sería necesario agregarla
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'referenciaPago': referenciaPago,
          'estadoPagoBold': estadoPagoBold,
        }),
      ),
      (data) => data,
      requiresAuth: false,
    );
  }

  /// 👤 Obtener ventas del usuario autenticado
  Future<List<Map<String, dynamic>>> obtenerVentasUsuario() async {
    final token = await _obtenerTokenValido();
    return _makeRequest(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/ventas/usuario'),
        headers: _getHeaders(token),
      ),
      (data) => _mapearVentas(data),
      requiresAuth: true,
    );
  }

  /// 📊 Obtener todas las ventas con filtros (Admin)
  Future<List<Map<String, dynamic>>> obtenerTodasLasVentas([FiltrosVenta? filtros]) async {
    final token = await _obtenerTokenValido();
    final queryParams = filtros?.toQueryParams() ?? <String, String>{};
    
    final uri = Uri.parse('$_baseUrl/ventas').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    print('🌐 URL para obtener todas las ventas: $uri');

    return _makeRequest(
      () => _httpClient.get(uri, headers: _getHeaders(token)),
      (data) => _mapearVentas(data),
      requiresAuth: true,
    );
  }

  /// 🗑️ Eliminar venta (Admin)
  Future<Map<String, dynamic>> eliminarVenta(String ventaId) async {
    final token = await _obtenerTokenValido();
    return _makeRequest(
      () => _httpClient.delete(
        Uri.parse('$_baseUrl/ventas/$ventaId'),
        headers: _getHeaders(token),
      ),
      (data) => data,
      requiresAuth: true,
    );
  }

  // === MÉTODOS HEREDADOS (mantenemos compatibilidad) ===

  /// ⚠️ DEPRECATED: Usar crearVentaPendiente en su lugar
  @Deprecated('Usar crearVentaPendiente para el nuevo flujo de pagos')
  Future<Map<String, dynamic>> crearVenta({
    required List<ProductoVenta> productos,
    required double total,
    String? estadoPago,
    String? referenciaPago,
  }) async {
    // Redirigir al nuevo método si se proporciona referenciaPago
    if (referenciaPago != null) {
      return crearVentaPendiente(
        productos: productos,
        total: total,
        referenciaPago: referenciaPago,
      );
    }
    
    throw VentaException('Este método está deprecado. Use crearVentaPendiente con referenciaPago.');
  }

  /// ⚠️ DEPRECATED: El backend no soporta actualización directa de estado
  @Deprecated('El flujo de pagos se maneja internamente por el backend')
  Future<Map<String, dynamic>> actualizarEstadoVenta({
    required String ventaId,
    required String estadoPago,
  }) async {
    throw VentaException('Esta funcionalidad no está disponible. El estado se actualiza automáticamente por webhooks.');
  }

  /// ⚠️ DEPRECATED: El backend no soporta exportación de Excel
  @Deprecated('Esta funcionalidad no está implementada en el backend')
  Future<List<int>> exportarVentasExcel({int? mes, int? anio}) async {
    throw VentaException('La exportación de Excel no está disponible.');
  }

  // === MÉTODOS DE BÚSQUEDA (usando la funcionalidad existente) ===

  Future<List<Map<String, dynamic>>> buscarVentas({
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? usuarioId,
    String? producto,
    String? estado,
  }) async {
    final filtros = FiltrosVenta(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      usuarioId: usuarioId,
      producto: producto,
      estado: estado,
    );
    return obtenerTodasLasVentas(filtros);
  }

  Future<List<Map<String, dynamic>>> obtenerVentasPorFecha({
    required DateTime fechaInicio,
    required DateTime fechaFin,
  }) async {
    return buscarVentas(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
    );
  }

  Future<List<Map<String, dynamic>>> obtenerVentasPorUsuario(String usuarioId) async {
    return buscarVentas(usuarioId: usuarioId);
  }

  Future<List<Map<String, dynamic>>> obtenerVentasPorEstado(String estado) async {
    return buscarVentas(estado: estado);
  }

  // === MÉTODOS DE ESTADÍSTICAS ===
  Map<String, dynamic> obtenerResumenVentas(List<Map<String, dynamic>> ventas) {
    if (ventas.isEmpty) {
      return {
        'totalVentas': 0,
        'montoTotal': 0.0,
        'promedioVenta': 0.0,
        'ventasPendientes': 0,
        'ventasAprobadas': 0,
        'ventasFallidas': 0,
        'productosVendidos': 0,
      };
    }

    double montoTotal = 0.0;
    int ventasPendientes = 0;
    int ventasAprobadas = 0;
    int ventasFallidas = 0;
    int productosVendidos = 0;

    for (final venta in ventas) {
      final total = _convertirADouble(venta['total']) ?? 0.0;
      montoTotal += total;

      final estado = venta['estadoPago']?.toString().toLowerCase() ?? 'pending';
      switch (estado) {
        case 'pending':
          ventasPendientes++;
          break;
        case 'approved':
          ventasAprobadas++;
          break;
        case 'failed':
          ventasFallidas++;
          break;
      }

      if (venta['productos'] is List) {
        for (final producto in venta['productos'] as List) {
          if (producto is Map) {
            productosVendidos += (producto['cantidad'] as int? ?? 0);
          }
        }
      }
    }

    return {
      'totalVentas': ventas.length,
      'montoTotal': montoTotal,
      'promedioVenta': montoTotal / ventas.length,
      'ventasPendientes': ventasPendientes,
      'ventasAprobadas': ventasAprobadas,
      'ventasFallidas': ventasFallidas,
      'productosVendidos': productosVendidos,
    };
  }

  void _validarDatosVenta(List<ProductoVenta> productos, double total) {
    if (productos.isEmpty) {
      throw VentaException('Debe incluir al menos un producto en la venta');
    }
    if (total <= 0) {
      throw VentaException('El total de la venta debe ser mayor a 0');
    }

    for (final producto in productos) {
      if (producto.productoId.isEmpty) {
        throw VentaException('Todos los productos deben tener un ID válido');
      }
      if (producto.cantidad <= 0) {
        throw VentaException('La cantidad de cada producto debe ser mayor a 0');
      }
      if (producto.precioUnitario < 0) {
        throw VentaException('El precio unitario no puede ser negativo');
      }
    }
  }

  double? _convertirADouble(dynamic valor) {
    if (valor == null) return null;
    if (valor is double) return valor;
    if (valor is int) return valor.toDouble();
    if (valor is String) return double.tryParse(valor);
    return null;
  }

  void dispose() {
    _httpClient.close();
  }
}