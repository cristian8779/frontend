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
  final dynamic color;
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
      'nombre': nombreProducto,
      'nombreProducto': nombreProducto,
      if (talla != null) 'talla': talla,
      if (color != null) 'color': color,
      'cantidad': cantidad,
      'precio': precioUnitario,
      'precioUnitario': precioUnitario,
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

  // === FUNCIONES DE SANITIZACIÓN ===
  
  String _sanitize(String value, {int visibleChars = 4}) {
    if (value.isEmpty) return '***';
    if (value.length <= visibleChars) return '***';
    return '${value.substring(0, visibleChars)}***';
  }

  String _sanitizeId(String id) {
    if (id.length <= 8) return '***';
    return '${id.substring(0, 4)}...${id.substring(id.length - 4)}';
  }

  String _sanitizeToken(String? token) {
    if (token == null || token.isEmpty) return '[NO_TOKEN]';
    if (token.length < 20) return '***';
    return '${token.substring(0, 10)}...${token.substring(token.length - 10)}';
  }

  Map<String, dynamic> _sanitizeResponseBody(String body, {int maxLength = 200}) {
    try {
      final data = jsonDecode(body);
      // Sanitizar campos sensibles si existen
      if (data is Map) {
        final sanitized = Map<String, dynamic>.from(data);
        if (sanitized.containsKey('token')) sanitized['token'] = '[SANITIZED]';
        if (sanitized.containsKey('accessToken')) sanitized['accessToken'] = '[SANITIZED]';
        if (sanitized.containsKey('refreshToken')) sanitized['refreshToken'] = '[SANITIZED]';
        
        final jsonStr = jsonEncode(sanitized);
        if (jsonStr.length > maxLength) {
          return {'info': 'Respuesta muy larga', 'length': jsonStr.length};
        }
        return sanitized;
      }
      return {'data': 'Respuesta recibida'};
    } catch (_) {
      return {'error': 'No se pudo parsear respuesta'};
    }
  }

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
      print('🔄 [VentaService] Intentando renovar token');
      
      final refreshToken = await _secureStorage.read(key: 'refreshToken');
      if (refreshToken == null) {
        print('❌ [VentaService] No hay refresh token');
        return false;
      }

      final response = await _httpClient.post(
        Uri.parse('${dotenv.env['API_URL']}/auth/refresh'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refreshToken": refreshToken}),
      ).timeout(VentaConfig.timeout);

      print('📥 [VentaService] Renovación - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['accessToken'];
        
        await _secureStorage.write(key: 'accessToken', value: newToken);
        _cachedToken = newToken;
        _tokenExpiry = DateTime.now().add(const Duration(hours: 1));
        print('✅ [VentaService] Token renovado exitosamente');
        return true;
      }
      print('❌ [VentaService] Error al renovar token');
      return false;
    } catch (e) {
      print('❌ [VentaService] Excepción renovando token: ${e.toString()}');
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
        print('⚠️ [VentaService] Token expirado (401), renovando...');
        if (await _renovarToken()) {
          return _makeRequest(request, parser, requiresAuth: requiresAuth, retries: 1);
        }
        throw VentaAuthException('No se pudo renovar el token');
      }
      
      print('📥 [VentaService] Status: ${response.statusCode}');
      
      // Sanitizar el body antes de mostrarlo
      final sanitizedBody = _sanitizeResponseBody(response.body);
      print('📦 [VentaService] Respuesta: $sanitizedBody');
      
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
      print('❌ [VentaService] Error inesperado: ${e.toString()}');
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
      return [data];
    }
    return <Map<String, dynamic>>[];
  }

  // === MÉTODO PARA OBTENER INFORMACIÓN DE USUARIO ===
  Future<String?> obtenerNombreUsuario(String usuarioId) async {
    print('🔍 [VentaService] Obteniendo nombre de usuario');
    print('   • Usuario ID: ${_sanitizeId(usuarioId)}');
    
    try {
      final token = await _obtenerTokenValido();
      
      final url = '$_baseUrl/usuario/$usuarioId';
      
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: _getHeaders(token),
      ).timeout(VentaConfig.timeout);

      print('📥 [VentaService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['usuario']?['nombre'] != null) {
          final nombre = data['usuario']['nombre'].toString().trim();
          print('✅ [VentaService] Nombre obtenido exitosamente');
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
    } catch (e) {
      print('❌ [VentaService] Error obteniendo nombre: ${e.toString()}');
      return 'Usuario desconocido';
    }
  }

  // === MÉTODOS PÚBLICOS PRINCIPALES ===

  /// 🆕 Crear venta pendiente
  Future<Map<String, dynamic>> crearVentaPendiente({
    required List<ProductoVenta> productos,
    required double total,
    required String referenciaPago,
  }) async {
    print('🆕 [VentaService] Creando venta pendiente');
    print('   • Productos: ${productos.length} items');
    print('   • Total: \$${total.toStringAsFixed(2)}');
    print('   • Referencia: ${_sanitize(referenciaPago, visibleChars: 6)}');
    
    _validarDatosVenta(productos, total);
    
    final usuarioId = await _secureStorage.read(key: 'usuarioId');
    if (usuarioId == null || usuarioId.isEmpty) {
      throw VentaAuthException('No se encontró usuarioId en el dispositivo');
    }

    print('   • Usuario ID: ${_sanitizeId(usuarioId)}');

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
      (data) {
        print('✅ [VentaService] Venta creada exitosamente');
        return data;
      },
      requiresAuth: false,
    );
  }

  /// 🔍 Buscar venta por referencia de pago
  Future<Map<String, dynamic>?> buscarVentaPorReferencia(String referenciaPago, {String? usuarioId}) async {
    print('🔍 [VentaService] Buscando venta por referencia');
    print('   • Referencia: ${_sanitize(referenciaPago, visibleChars: 6)}');
    if (usuarioId != null) {
      print('   • Usuario ID: ${_sanitizeId(usuarioId)}');
    }
    
    try {
      final queryParams = <String, String>{};
      if (usuarioId != null) queryParams['usuarioId'] = usuarioId;
      
      final uri = Uri.parse('$_baseUrl/ventas/referencia/$referenciaPago').replace(
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      return _makeRequest(
        () => _httpClient.get(uri, headers: {'Content-Type': 'application/json'}),
        (data) {
          print('✅ [VentaService] Venta encontrada');
          return data;
        },
        requiresAuth: false,
      );
    } catch (e) {
      if (e is VentaException && e.statusCode == 404) {
        print('ℹ️ [VentaService] Venta no encontrada');
        return null;
      }
      rethrow;
    }
  }

  /// 💳 Confirmar pago de una venta
  Future<Map<String, dynamic>> confirmarPago({
    required String referenciaPago,
    required String estadoPagoBold,
  }) async {
    print('💳 [VentaService] Confirmando pago');
    print('   • Referencia: ${_sanitize(referenciaPago, visibleChars: 6)}');
    print('   • Estado Bold: $estadoPagoBold');
    
    return _makeRequest(
      () => _httpClient.post(
        Uri.parse('$_baseUrl/ventas/confirmar-pago'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'referenciaPago': referenciaPago,
          'estadoPagoBold': estadoPagoBold,
        }),
      ),
      (data) {
        print('✅ [VentaService] Pago confirmado');
        return data;
      },
      requiresAuth: false,
    );
  }

  /// 👤 Obtener ventas del usuario autenticado
  Future<List<Map<String, dynamic>>> obtenerVentasUsuario() async {
    print('👤 [VentaService] Obteniendo ventas del usuario');
    
    final token = await _obtenerTokenValido();
    return _makeRequest(
      () => _httpClient.get(
        Uri.parse('$_baseUrl/ventas/usuario'),
        headers: _getHeaders(token),
      ),
      (data) {
        final ventas = _mapearVentas(data);
        print('✅ [VentaService] ${ventas.length} ventas obtenidas');
        return ventas;
      },
      requiresAuth: true,
    );
  }

  /// 📊 Obtener todas las ventas con filtros (Admin)
  Future<List<Map<String, dynamic>>> obtenerTodasLasVentas([FiltrosVenta? filtros]) async {
    print('📊 [VentaService] Obteniendo todas las ventas');
    
    final token = await _obtenerTokenValido();
    final queryParams = filtros?.toQueryParams() ?? <String, String>{};
    
    if (queryParams.isNotEmpty) {
      print('   • Filtros aplicados: ${queryParams.keys.join(", ")}');
    }
    
    final uri = Uri.parse('$_baseUrl/ventas').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    return _makeRequest(
      () => _httpClient.get(uri, headers: _getHeaders(token)),
      (data) {
        final ventas = _mapearVentas(data);
        print('✅ [VentaService] ${ventas.length} ventas obtenidas');
        return ventas;
      },
      requiresAuth: true,
    );
  }

  /// 🗑️ Eliminar venta (Admin)
  Future<Map<String, dynamic>> eliminarVenta(String ventaId) async {
    print('🗑️ [VentaService] Eliminando venta');
    print('   • Venta ID: ${_sanitizeId(ventaId)}');
    
    final token = await _obtenerTokenValido();
    return _makeRequest(
      () => _httpClient.delete(
        Uri.parse('$_baseUrl/ventas/$ventaId'),
        headers: _getHeaders(token),
      ),
      (data) {
        print('✅ [VentaService] Venta eliminada');
        return data;
      },
      requiresAuth: true,
    );
  }

  // === MÉTODOS HEREDADOS (mantenemos compatibilidad) ===

  @Deprecated('Usar crearVentaPendiente para el nuevo flujo de pagos')
  Future<Map<String, dynamic>> crearVenta({
    required List<ProductoVenta> productos,
    required double total,
    String? estadoPago,
    String? referenciaPago,
  }) async {
    if (referenciaPago != null) {
      return crearVentaPendiente(
        productos: productos,
        total: total,
        referenciaPago: referenciaPago,
      );
    }
    
    throw VentaException('Este método está deprecado. Use crearVentaPendiente con referenciaPago.');
  }

  @Deprecated('El flujo de pagos se maneja internamente por el backend')
  Future<Map<String, dynamic>> actualizarEstadoVenta({
    required String ventaId,
    required String estadoPago,
  }) async {
    throw VentaException('Esta funcionalidad no está disponible. El estado se actualiza automáticamente por webhooks.');
  }

  @Deprecated('Esta funcionalidad no está implementada en el backend')
  Future<List<int>> exportarVentasExcel({int? mes, int? anio}) async {
    throw VentaException('La exportación de Excel no está disponible.');
  }

  // === MÉTODOS DE BÚSQUEDA ===

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