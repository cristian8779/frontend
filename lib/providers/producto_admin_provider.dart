import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/producto_service.dart';
import 'dart:io';
import 'dart:async';

enum ProductoState {
  initial,
  loading,
  loaded,
  error,
  refreshing,
  loadingMore,
  creating,
  updating,
  deleting,
}

class ProductoProvider extends ChangeNotifier {
  final ProductoService _productoService = ProductoService();

  // === ESTADO PRINCIPAL ===
  ProductoState _state = ProductoState.initial;
  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _productosFiltrados = [];
  List<Map<String, dynamic>> _categorias = [];
  Map<String, dynamic> _filtrosDisponibles = {};
  
  // === PAGINACION ===
  int _page = 0;
  int _totalProductos = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // === CACHE ===
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // === FILTROS Y BUSQUEDA ===
  String _busqueda = '';
  String? _categoriaSeleccionada;
  String? _subcategoriaSeleccionada;
  List<String> _coloresFiltrados = [];
  List<String> _tallasFiltradas = [];
  double? _precioMin;
  double? _precioMax;
  
  // === ORDENAMIENTO ===
  String _sortBy = 'nombre';
  bool _sortAscending = true;

  // === ERROR HANDLING ===
  String? _errorMessage;
  String? _lastErrorCode;

  // === PRODUCTOS INDIVIDUALES ===
  Map<String, dynamic>? _productoSeleccionado;

  // === CONTROL DE ELIMINACIONES ===
  final Set<String> _idsEliminadosRecientes = {};
  final Map<String, DateTime> _timestampsEliminacion = {};
  static const Duration _esperaPostEliminacion = Duration(milliseconds: 800);
  static const Duration _tiempoMemoriaEliminacion = Duration(minutes: 3);

  // === GETTERS ===
  ProductoState get state => _state;
  List<Map<String, dynamic>> get productos => _productos;
  List<Map<String, dynamic>> get productosFiltrados => _productosFiltrados;
  List<Map<String, dynamic>> get categorias => _categorias;
  Map<String, dynamic> get filtrosDisponibles => _filtrosDisponibles;
  
  int get currentPage => _page;
  int get totalProductos => _totalProductos;
  bool get hasMore => _hasMore;
  bool get isLoading => _state == ProductoState.loading;
  bool get isLoadingMore => _state == ProductoState.loadingMore;
  bool get isRefreshing => _state == ProductoState.refreshing;
  bool get isCreating => _state == ProductoState.creating;
  bool get isUpdating => _state == ProductoState.updating;
  bool get isDeleting => _state == ProductoState.deleting;
  bool get hasError => _state == ProductoState.error;
  bool get isEmpty => _productos.isEmpty && !isLoading;

  String get busqueda => _busqueda;
  String? get categoriaSeleccionada => _categoriaSeleccionada;
  String? get subcategoriaSeleccionada => _subcategoriaSeleccionada;
  List<String> get coloresFiltrados => _coloresFiltrados;
  List<String> get tallasFiltradas => _tallasFiltradas;
  double? get precioMin => _precioMin;
  double? get precioMax => _precioMax;
  String get sortBy => _sortBy;
  bool get sortAscending => _sortAscending;
  
  String? get errorMessage => _errorMessage;
  String? get lastErrorCode => _lastErrorCode;
  Map<String, dynamic>? get productoSeleccionado => _productoSeleccionado;

  int get totalFiltrados => _productosFiltrados.length;
  int get totalCategorias => _categorias.length;

  // === METODOS AUXILIARES PARA MANEJAR IDs ===
  
  String _obtenerIdProducto(Map<String, dynamic> producto) {
    return producto['_id']?.toString() ?? producto['id']?.toString() ?? '';
  }
  
  Map<String, dynamic>? _encontrarProductoPorId(String id, List<Map<String, dynamic>> lista) {
    try {
      return lista.firstWhere((producto) => producto['_id']?.toString() == id);
    } catch (e) {
      try {
        return lista.firstWhere((producto) => producto['id']?.toString() == id);
      } catch (e) {
        return null;
      }
    }
  }

  void _removerProductoPorId(String id, List<Map<String, dynamic>> lista) {
    lista.removeWhere((p) => p['_id']?.toString() == id);
    lista.removeWhere((p) => p['id']?.toString() == id);
  }

  // === METODOS PRINCIPALES ===

  Future<void> inicializar() async {
    if (_state == ProductoState.loading) return;

    debugPrint('Inicializando ProductoProvider...');
    _setState(ProductoState.loading);
    _limpiarError();

    try {
      await Future.wait([
        _cargarCategorias(),
        _cargarFiltrosDisponibles(),
      ]);
      debugPrint('Categorias y filtros cargados');

      await cargarProductos(forceRefresh: true);
      debugPrint('Productos iniciales cargados');
      
    } catch (e) {
      debugPrint('Error en inicializar: $e');
      _manejarError(e, 'Error al inicializar datos');
    }
  }

  Future<void> cargarProductos({
    bool forceRefresh = false,
    bool mostrarLoading = true,
  }) async {
    debugPrint('cargarProductos - forceRefresh: $forceRefresh');
    debugPrint('  IDs eliminados activos: ${_idsEliminadosRecientes.length}');
    if (_idsEliminadosRecientes.isNotEmpty) {
      debugPrint('  IDs: ${_idsEliminadosRecientes.take(3).toList()}');
    }
    
    if (forceRefresh) {
      debugPrint('Force refresh activado - limpiando datos...');
      _productos.clear();
      _productosFiltrados.clear();
      _page = 0;
      _hasMore = true;
      _lastFetch = null;
      _setState(ProductoState.refreshing);
      notifyListeners();
    } else {
      if (_productos.isNotEmpty &&
          _lastFetch != null &&
          DateTime.now().difference(_lastFetch!) < _cacheDuration) {
        debugPrint("Usando cache (ultima carga hace menos de 5 min)");
        
        // Pero si hay IDs eliminados, forzar refresh
        if (_idsEliminadosRecientes.isNotEmpty) {
          debugPrint("⚠️  Hay productos eliminados - forzando refresh");
          _productos.clear();
          _productosFiltrados.clear();
          _page = 0;
          _hasMore = true;
          _lastFetch = null;
        } else {
          return;
        }
      }
      
      _page = 0;
      _hasMore = true;
    }

    await _fetchProductos(isFirstLoad: true, mostrarLoading: mostrarLoading);
  }

  Future<void> cargarMasProductos({bool mostrarLoading = true}) async {
    if (isLoadingMore || !_hasMore) {
      debugPrint("No se cargan mas productos (isLoadingMore=$isLoadingMore, hasMore=$_hasMore)");
      return;
    }
    
    debugPrint("Cargando mas productos (pagina ${_page + 1})...");
    await _fetchProductos(isFirstLoad: false, mostrarLoading: mostrarLoading);
  }

  Future<void> _fetchProductos({
    required bool isFirstLoad,
    bool mostrarLoading = true,
  }) async {
    if (mostrarLoading) {
      _setState(isFirstLoad ? ProductoState.loading : ProductoState.loadingMore);
      _limpiarError();
    }

    try {
      if (!isFirstLoad) {
        _page++;
      }
      
      final filtros = _construirFiltros();
      debugPrint('=== FETCHING PRODUCTOS ===');
      debugPrint('Pagina: $_page, Limite: $_pageSize');
      
      final response = await _productoService.obtenerProductosPaginados(filtros);

      var nuevosProductos = List<Map<String, dynamic>>.from(
        response['productos'] ?? []
      );
      final total = response['total'] ?? 0;

      debugPrint('Respuesta del servidor:');
      debugPrint('  - Productos recibidos: ${nuevosProductos.length}');
      debugPrint('  - Total en servidor: $total');
      
      // ⭐ CRÍTICO: Filtrar productos que fueron eliminados recientemente
      if (_idsEliminadosRecientes.isNotEmpty) {
        final cantidadOriginal = nuevosProductos.length;
        
        nuevosProductos = nuevosProductos.where((producto) {
          final productoId = producto['_id']?.toString() ?? 
                            producto['id']?.toString() ?? '';
          
          if (productoId.isEmpty) return true;
          
          final fueEliminado = _idsEliminadosRecientes.contains(productoId);
          
          if (fueEliminado) {
            final tiempoEliminacion = _timestampsEliminacion[productoId];
            final segundosDesdeEliminacion = tiempoEliminacion != null
                ? DateTime.now().difference(tiempoEliminacion).inSeconds
                : 0;
            
            debugPrint('🚫 BLOQUEANDO producto eliminado:');
            debugPrint('   - Nombre: ${producto['nombre']}');
            debugPrint('   - ID: $productoId');
            debugPrint('   - Eliminado hace: ${segundosDesdeEliminacion}s');
          }
          
          return !fueEliminado;
        }).toList();
        
        if (cantidadOriginal != nuevosProductos.length) {
          final productosEliminados = cantidadOriginal - nuevosProductos.length;
          debugPrint('');
          debugPrint('⚠️  PRODUCTOS FILTRADOS:');
          debugPrint('   - Recibidos del servidor: $cantidadOriginal');
          debugPrint('   - Bloqueados (eliminados): $productosEliminados');
          debugPrint('   - Permitidos: ${nuevosProductos.length}');
          debugPrint('');
        }
      }

      if (isFirstLoad) {
        _productos = nuevosProductos;
        debugPrint('✅ Productos REEMPLAZADOS: ${nuevosProductos.length}');
      } else {
        _productos.addAll(nuevosProductos);
        debugPrint('✅ Productos AÑADIDOS: ${nuevosProductos.length}');
      }

      _hasMore = _productos.length < total;
      _totalProductos = total;
      _lastFetch = DateTime.now();

      debugPrint('Estado final:');
      debugPrint('  - Total local: ${_productos.length}');
      debugPrint('  - Total servidor: $_totalProductos');
      debugPrint('  - Hay mas: $_hasMore');
      debugPrint('  - IDs eliminados en memoria: ${_idsEliminadosRecientes.length}');

      if (isFirstLoad &&
          _productos.length < total &&
          (total - _productos.length) <= _pageSize &&
          total <= 40) {
        debugPrint('Auto-cargando pagina restante...');
        await cargarMasProductos(mostrarLoading: false);
      }

      _aplicarFiltrosLocales();
      _setState(ProductoState.loaded);

    } on SocketException {
      _errorMessage = 'Sin conexion a internet';
      debugPrint("Error: $_errorMessage");
      _setState(ProductoState.error);
    } on TimeoutException {
      _errorMessage = 'Tiempo de espera agotado';
      debugPrint("Error: $_errorMessage");
      _setState(ProductoState.error);
    } catch (e) {
      debugPrint('Error cargando productos: $e');
      _manejarError(e, 'Error al cargar productos');
    }
  }

  Future<void> refrescar() async {
    debugPrint('=== REFRESH MANUAL ===');
    
    // Verificar si hay eliminaciones recientes
    if (_idsEliminadosRecientes.isNotEmpty) {
      debugPrint('⚠️  Hay ${_idsEliminadosRecientes.length} productos eliminados recientemente');
      debugPrint('   Los filtraremos automáticamente si el servidor los devuelve');
      
      // Mostrar cuánto tiempo hace que se eliminaron
      _idsEliminadosRecientes.forEach((id) {
        final timestamp = _timestampsEliminacion[id];
        if (timestamp != null) {
          final segundos = DateTime.now().difference(timestamp).inSeconds;
          debugPrint('   - ID: $id (hace ${segundos}s)');
        }
      });
    }
    
    _productos.clear();
    _productosFiltrados.clear();
    _page = 0;
    _hasMore = true;
    _lastFetch = null;
    
    debugPrint('Cache limpiado - iniciando carga...');
    debugPrint('');
    
    await cargarProductos(forceRefresh: true);
  }

  void buscarProductos(String query) {
    final nuevaBusqueda = query.trim();
    debugPrint('Buscando productos: "$nuevaBusqueda"');
    
    if (_busqueda != nuevaBusqueda) {
      _busqueda = nuevaBusqueda;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    } else {
      _aplicarFiltrosLocales();
      notifyListeners();
    }
  }

  void filtrarPorCategoria(String? categoriaId) {
    debugPrint('Filtrando por categoria: $categoriaId');
    
    if (_categoriaSeleccionada != categoriaId) {
      _categoriaSeleccionada = categoriaId;
      _subcategoriaSeleccionada = null;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    }
  }

  void filtrarPorSubcategoria(String? subcategoriaId) {
    if (_subcategoriaSeleccionada != subcategoriaId) {
      _subcategoriaSeleccionada = subcategoriaId;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    }
  }

  void aplicarFiltros({
    String? busqueda,
    String? categoria,
    String? subcategoria,
    List<String>? colores,
    List<String>? tallas,
    double? precioMin,
    double? precioMax,
  }) {
    bool filtrosChanged = false;

    if (busqueda != null && busqueda != _busqueda) {
      _busqueda = busqueda;
      filtrosChanged = true;
    }
    if (categoria != null && categoria != _categoriaSeleccionada) {
      _categoriaSeleccionada = categoria;
      filtrosChanged = true;
    }
    if (subcategoria != null && subcategoria != _subcategoriaSeleccionada) {
      _subcategoriaSeleccionada = subcategoria;
      filtrosChanged = true;
    }
    if (colores != null && !_listEquals(_coloresFiltrados, colores)) {
      _coloresFiltrados = colores;
      filtrosChanged = true;
    }
    if (tallas != null && !_listEquals(_tallasFiltradas, tallas)) {
      _tallasFiltradas = tallas;
      filtrosChanged = true;
    }
    if (precioMin != null && precioMin != _precioMin) {
      _precioMin = precioMin;
      filtrosChanged = true;
    }
    if (precioMax != null && precioMax != _precioMax) {
      _precioMax = precioMax;
      filtrosChanged = true;
    }

    if (filtrosChanged) {
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    } else {
      _aplicarFiltrosLocales();
      notifyListeners();
    }
  }

  void limpiarFiltros() {
    _busqueda = '';
    _categoriaSeleccionada = null;
    _subcategoriaSeleccionada = null;
    _coloresFiltrados.clear();
    _tallasFiltradas.clear();
    _precioMin = null;
    _precioMax = null;

    _resetearPaginacion();
    cargarProductos(forceRefresh: true);
  }

  void cambiarOrdenamiento(String sortBy, {bool? ascending}) {
    _sortBy = sortBy;
    if (ascending != null) {
      _sortAscending = ascending;
    } else {
      _sortAscending = _sortBy == sortBy ? !_sortAscending : true;
    }

    _aplicarOrdenamiento();
    notifyListeners();
  }

  // === CRUD OPERATIONS ===

  Future<bool> crearProducto({
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
    _setState(ProductoState.creating);
    _limpiarError();

    try {
      final productoCreado = await _productoService.crearProducto(
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        categoria: categoria,
        subcategoria: subcategoria,
        stock: stock,
        disponible: disponible,
        estado: estado,
        imagenLocal: imagenLocal,
      );

      if (productoCreado != null) {
        _productos.insert(0, Map<String, dynamic>.from(productoCreado));
        _aplicarFiltrosLocales();
        _setState(ProductoState.loaded);
        debugPrint('Producto creado y agregado localmente: $nombre');
        return true;
      } else {
        await refrescar();
        return true;
      }

    } catch (e) {
      _manejarError(e, 'Error al crear producto');
      return false;
    }
  }

  Future<Map<String, dynamic>?> obtenerProductoPorId(String id) async {
    try {
      Map<String, dynamic>? producto = _encontrarProductoPorId(id, _productos);
      
      if (producto != null) {
        _productoSeleccionado = producto;
        notifyListeners();
        return _productoSeleccionado;
      }

      _productoSeleccionado = await _productoService.obtenerProductoPorId(id);
      notifyListeners();
      return _productoSeleccionado;
    } catch (e) {
      _manejarError(e, 'Error al obtener producto');
      return null;
    }
  }

  Future<bool> actualizarProducto({
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
    debugPrint('Iniciando actualizacion - ID: $id');
    _setState(ProductoState.updating);
    _limpiarError();

    _productoSeleccionado = _encontrarProductoPorId(id, _productos);
    debugPrint('   - Producto encontrado para actualizar: ${_productoSeleccionado?['nombre']}');

    try {
      final productoActualizado = await _productoService.actualizarProducto(
        id: id,
        nombre: nombre,
        descripcion: descripcion,
        precio: precio,
        categoria: categoria,
        subcategoria: subcategoria,
        stock: stock,
        disponible: disponible,
        estado: estado,
        imagenLocal: imagenLocal,
      );

      final index = _productos.indexWhere((p) => 
        p['_id']?.toString() == id || p['id']?.toString() == id);
      
      debugPrint('   - Producto encontrado en indice: $index');
      
      if (index != -1) {
        final productoOriginal = _productos[index];
        debugPrint('   - ID original: ${productoOriginal['_id']}');
        
        final productoActualizadoLocal = {
          '_id': productoOriginal['_id'],
          'id': productoOriginal['id'] ?? productoOriginal['_id'],
          
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'categoria': categoria,
          'subcategoria': subcategoria,
          'stock': stock,
          'disponible': disponible,
          'estado': estado,
          'updatedAt': DateTime.now().toIso8601String(),
          
          'createdAt': productoOriginal['createdAt'],
          'imagen': imagenLocal != null 
            ? (productoActualizado?['imagen'] ?? productoOriginal['imagen'])
            : productoOriginal['imagen'],
          'imagenUrl': imagenLocal != null 
            ? (productoActualizado?['imagenUrl'] ?? productoOriginal['imagenUrl'])
            : productoOriginal['imagenUrl'],
          
          ...Map.from(productoOriginal)..removeWhere((key, value) => [
            'nombre', 'descripcion', 'precio', 'categoria', 'subcategoria', 
            'stock', 'disponible', 'estado', 'updatedAt', 'imagen', 'imagenUrl'
          ].contains(key)),
        };
        
        debugPrint('Producto actualizado - ID preservado: ${productoActualizadoLocal['_id']}');
        debugPrint('   - Nombre: ${productoActualizadoLocal['nombre']}');
        
        _productos[index] = Map<String, dynamic>.from(productoActualizadoLocal);
        
        _aplicarFiltrosLocales();
        
        debugPrint('DEBUG POST-ACTUALIZACION:');
        debugPrint('   - Total productos: ${_productos.length}');
        debugPrint('   - Total filtrados: ${_productosFiltrados.length}');
        
        _setState(ProductoState.loaded);
        
        debugPrint('Actualizacion completada exitosamente');
        return true;
      } else {
        debugPrint('Producto no encontrado localmente, recargando...');
        await refrescar();
        return true;
      }

    } catch (e) {
      debugPrint('Error actualizando producto: $e');
      _manejarError(e, 'Error al actualizar producto');
      return false;
    } finally {
      _productoSeleccionado = null;
    }
  }

  Future<bool> eliminarProducto(String id) async {
    debugPrint('=== ELIMINANDO PRODUCTO ===');
    debugPrint('ID: $id');
    
    final productoAEliminar = _encontrarProductoPorId(id, _productos);
    String? nombreProducto;
    
    if (productoAEliminar != null) {
      nombreProducto = productoAEliminar['nombre'];
      debugPrint('Producto: $nombreProducto');
    }
    
    _setState(ProductoState.deleting);
    _limpiarError();

    try {
      // 1. REGISTRAR eliminación ANTES de eliminar (para evitar race conditions)
      _idsEliminadosRecientes.add(id);
      _timestampsEliminacion[id] = DateTime.now();
      debugPrint('1. ✅ ID registrado como eliminado: $id');
      
      // 2. Eliminar del servidor
      debugPrint('2. 🔄 Eliminando en servidor...');
      await _productoService.eliminarProducto(id);
      debugPrint('   ✅ Servidor confirma eliminación');
      
      // 3. Eliminar localmente
      debugPrint('3. 🔄 Eliminando localmente...');
      final cantidadAntes = _productos.length;
      
      _removerProductoPorId(id, _productos);
      _removerProductoPorId(id, _productosFiltrados);
      
      final cantidadDespues = _productos.length;
      debugPrint('   ✅ Productos: $cantidadAntes -> $cantidadDespues');
      
      // 4. Actualizar contadores
      _totalProductos = _productos.length;
      
      // 5. IMPORTANTE: Invalidar cache completamente
      _lastFetch = null;
      _page = 0;
      _hasMore = true;
      
      debugPrint('4. ✅ Cache invalidado completamente');
      
      // 6. Aplicar filtros y notificar
      _aplicarFiltrosLocales();
      _setState(ProductoState.loaded);
      
      debugPrint('5. ✅ UI actualizada');
      debugPrint('=== ELIMINACIÓN EXITOSA ===');
      debugPrint('');
      
      // 7. Limpiar el registro después del tiempo configurado
      Future.delayed(_tiempoMemoriaEliminacion, () {
        if (_idsEliminadosRecientes.contains(id)) {
          _idsEliminadosRecientes.remove(id);
          _timestampsEliminacion.remove(id);
          debugPrint('🧹 ID removido de memoria (expiró): $id');
        }
      });
      
      // 8. Esperar un poco antes de permitir refresh
      // Esto da tiempo al servidor para sincronizar
      await Future.delayed(_esperaPostEliminacion);
      debugPrint('⏱️  Tiempo de espera completado - listo para refresh');
      
      return true;

    } catch (e) {
      debugPrint('❌ Error eliminando: $e');
      
      // Si falla, remover de la lista de eliminados
      _idsEliminadosRecientes.remove(id);
      _timestampsEliminacion.remove(id);
      
      _manejarError(e, 'Error al eliminar producto');
      return false;
    }
  }

  bool productoExiste(String id) {
    return _encontrarProductoPorId(id, _productos) != null;
  }

  void forzarActualizacion() {
    debugPrint('Forzando actualizacion de UI');
    notifyListeners();
  }

  Future<bool> reducirStock(String id, int cantidad) async {
    try {
      await _productoService.reducirStock(id, cantidad);
      
      final producto = _encontrarProductoPorId(id, _productos);
      if (producto != null) {
        final stockActual = (producto['stock'] as int?) ?? 0;
        producto['stock'] = (stockActual - cantidad).clamp(0, double.infinity).toInt();
        _aplicarFiltrosLocales();
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      _manejarError(e, 'Error al reducir stock');
      return false;
    }
  }

  // === METODOS PRIVADOS ===

  void _setState(ProductoState newState) {
    debugPrint('Cambiando estado: $_state -> $newState');
    _state = newState;
    notifyListeners();
  }

  void _limpiarError() {
    _errorMessage = null;
    _lastErrorCode = null;
  }

  void _manejarError(dynamic error, [String? contexto]) {
    debugPrint('Error en ProductoProvider: $error');
    
    if (error is ProductoException) {
      _errorMessage = error.message;
      _lastErrorCode = error.code;
    } else {
      _errorMessage = contexto ?? error.toString();
    }
    
    _setState(ProductoState.error);
  }

  Future<void> _cargarCategorias() async {
    debugPrint('Cargando categorias...');
    _categorias = await _productoService.obtenerCategorias();
    debugPrint('Categorias cargadas: ${_categorias.length}');
  }

  Future<void> _cargarFiltrosDisponibles() async {
    debugPrint('Cargando filtros disponibles...');
    _filtrosDisponibles = await _productoService.obtenerFiltrosDisponibles();
    debugPrint('Filtros disponibles cargados: ${_filtrosDisponibles.keys}');
  }

  void _resetearPaginacion() {
    _page = 0;
    _hasMore = true;
    _productos.clear();
    _lastFetch = null;
  }

  FiltrosBusqueda _construirFiltros() {
    final filtros = FiltrosBusqueda(
      query: _busqueda.isNotEmpty ? _busqueda : null,
      categoria: _categoriaSeleccionada,
      subcategoria: _subcategoriaSeleccionada,
      colores: _coloresFiltrados.isNotEmpty ? _coloresFiltrados : null,
      tallas: _tallasFiltradas.isNotEmpty ? _tallasFiltradas : null,
      precioMin: _precioMin,
      precioMax: _precioMax,
      page: _page,
      limit: _pageSize,
    );
    
    debugPrint('FILTROS: page=$_page, limit=$_pageSize, query=${_busqueda}');
    
    return filtros;
  }

  void _aplicarFiltrosLocales() {
    debugPrint('Aplicando filtros locales a ${_productos.length} productos...');
    
    _productosFiltrados = _productos.map((producto) {
      return Map<String, dynamic>.from(producto);
    }).toList();

    debugPrint('Productos despues del filtro: ${_productosFiltrados.length}');
    if (_productosFiltrados.isNotEmpty) {
      debugPrint('   - Primer producto ID: ${_productosFiltrados.first['_id']}');
      debugPrint('   - Primer producto nombre: ${_productosFiltrados.first['nombre']}');
    }
    
    _aplicarOrdenamiento();
  }

  bool _tieneFiltrosActivos() {
    return _busqueda.isNotEmpty ||
           _categoriaSeleccionada != null ||
           _subcategoriaSeleccionada != null ||
           _coloresFiltrados.isNotEmpty ||
           _tallasFiltradas.isNotEmpty ||
           _precioMin != null ||
           _precioMax != null;
  }

  void _aplicarOrdenamiento() {
    _productosFiltrados.sort((a, b) {
      int comparison = 0;
      
      switch (_sortBy) {
        case 'precio':
          final precioA = (a['precio'] as num?)?.toDouble() ?? 0.0;
          final precioB = (b['precio'] as num?)?.toDouble() ?? 0.0;
          comparison = precioA.compareTo(precioB);
          break;
        case 'stock':
          final stockA = (a['stock'] as num?)?.toInt() ?? 0;
          final stockB = (b['stock'] as num?)?.toInt() ?? 0;
          comparison = stockA.compareTo(stockB);
          break;
        case 'fecha':
          final fechaA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ?? DateTime.now();
          final fechaB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ?? DateTime.now();
          comparison = fechaA.compareTo(fechaB);
          break;
        default:
          final nombreA = a['nombre']?.toString().toLowerCase() ?? '';
          final nombreB = b['nombre']?.toString().toLowerCase() ?? '';
          comparison = nombreA.compareTo(nombreB);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    debugPrint('Productos ordenados por $_sortBy (${_sortAscending ? 'ASC' : 'DESC'})');
  }

  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // === UTILIDADES PUBLICAS ===

  void mostrarTodosLosProductos() {
    debugPrint('Mostrando todos los productos (quitando filtro de categoria)');
    
    final busquedaActual = _busqueda;
    
    _categoriaSeleccionada = null;
    _subcategoriaSeleccionada = null;
    
    if (busquedaActual.isNotEmpty) {
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    } else {
      _aplicarFiltrosLocales();
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> obtenerProductosAleatorios(int cantidad) {
    if (_productos.isEmpty) return [];
    final copia = List<Map<String, dynamic>>.from(_productos);
    copia.shuffle();
    return copia.take(cantidad).toList();
  }

  List<Map<String, dynamic>> filtrarPorCategoriaLocal(String? categoria) {
    if (categoria == null || categoria.isEmpty) return _productos;
    return _productos.where((p) {
      final cat = p['categoria']?.toString().toLowerCase();
      return cat == categoria.toLowerCase();
    }).toList();
  }

  Future<void> reintentar() async {
    debugPrint('Reintentando operacion...');
    switch (_state) {
      case ProductoState.error:
        await inicializar();
        break;
      default:
        await refrescar();
    }
  }

  void limpiar() {
    debugPrint('Limpiando datos del provider...');
    _productos.clear();
    _productosFiltrados.clear();
    _categorias.clear();
    _filtrosDisponibles.clear();
    _productoSeleccionado = null;
    _page = 0;
    _hasMore = true;
    _lastFetch = null;
    _busqueda = '';
    _categoriaSeleccionada = null;
    _subcategoriaSeleccionada = null;
    _coloresFiltrados.clear();
    _tallasFiltradas.clear();
    _precioMin = null;
    _precioMax = null;
    
    // Limpiar registros de eliminación
    _idsEliminadosRecientes.clear();
    _timestampsEliminacion.clear();
    
    _limpiarError();
    _setState(ProductoState.initial);
  }

  String obtenerNombreCategoria(String? categoriaId) {
    if (categoriaId == null) return 'Sin categoria';
    
    final categoria = _categorias.firstWhere(
      (cat) => cat['_id'] == categoriaId,
      orElse: () => <String, dynamic>{},
    );
    
    return categoria['nombre']?.toString() ?? 'Categoria desconocida';
  }

  bool get tieneFiltrosActivos {
    return _busqueda.isNotEmpty ||
           _categoriaSeleccionada != null ||
           _subcategoriaSeleccionada != null ||
           _coloresFiltrados.isNotEmpty ||
           _tallasFiltradas.isNotEmpty ||
           _precioMin != null ||
           _precioMax != null;
  }

  // === MÉTODOS PARA CONTROL DE ELIMINACIONES ===

  /// Limpia el registro de productos eliminados manualmente
  void limpiarRegistroEliminados() {
    final cantidad = _idsEliminadosRecientes.length;
    if (cantidad > 0) {
      debugPrint('🧹 Limpiando $cantidad IDs eliminados de la memoria');
      _idsEliminadosRecientes.clear();
      _timestampsEliminacion.clear();
      notifyListeners();
    }
  }

  /// Verifica si un producto fue eliminado recientemente
  bool fueEliminadoRecientemente(String id) {
    final eliminado = _idsEliminadosRecientes.contains(id);
    if (eliminado) {
      final timestamp = _timestampsEliminacion[id];
      if (timestamp != null) {
        final segundos = DateTime.now().difference(timestamp).inSeconds;
        debugPrint('ℹ️  Producto $id fue eliminado hace ${segundos}s');
      }
    }
    return eliminado;
  }

  /// Obtiene cuántos segundos hace que se eliminó un producto
  int? getSegundosDesdeEliminacion(String id) {
    if (!_idsEliminadosRecientes.contains(id)) return null;
    
    final timestamp = _timestampsEliminacion[id];
    if (timestamp == null) return null;
    
    return DateTime.now().difference(timestamp).inSeconds;
  }

  /// Obtiene la cantidad de productos eliminados que están en memoria
  int get cantidadProductosEliminadosEnMemoria => _idsEliminadosRecientes.length;

  /// Obtiene la lista de IDs eliminados (útil para debugging)
  List<String> get idsEliminadosActivos => _idsEliminadosRecientes.toList();

  @override
  void dispose() {
    debugPrint('Disposing ProductoProvider...');
    _idsEliminadosRecientes.clear();
    _timestampsEliminacion.clear();
    super.dispose();
  }
}