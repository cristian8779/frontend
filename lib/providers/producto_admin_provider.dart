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
  
  // === PAGINACIÓN - CORREGIDA ===
  int _page = 0; // ← CAMBIO: Empezar desde 0 como el provider funcional
  int _totalProductos = 0;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // === CACHE ===
  DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 5);

  // === FILTROS Y BÚSQUEDA ===
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

  // === MÉTODOS AUXILIARES PARA MANEJAR IDs ===
  
  /// Método auxiliar para obtener el ID de un producto de manera consistente
  String _obtenerIdProducto(Map<String, dynamic> producto) {
    return producto['_id']?.toString() ?? producto['id']?.toString() ?? '';
  }
  
  /// Método auxiliar para encontrar un producto por ID (maneja tanto _id como id)
  Map<String, dynamic>? _encontrarProductoPorId(String id, List<Map<String, dynamic>> lista) {
    try {
      // Buscar por _id primero
      return lista.firstWhere((producto) => producto['_id']?.toString() == id);
    } catch (e) {
      try {
        // Si no encuentra por _id, buscar por id
        return lista.firstWhere((producto) => producto['id']?.toString() == id);
      } catch (e) {
        return null;
      }
    }
  }

  /// Método auxiliar para remover un producto por ID (maneja tanto _id como id)
  void _removerProductoPorId(String id, List<Map<String, dynamic>> lista) {
    // Remover por _id
    lista.removeWhere((p) => p['_id']?.toString() == id);
    // Remover por id (por si acaso)
    lista.removeWhere((p) => p['id']?.toString() == id);
  }

  // === MÉTODOS PRINCIPALES CORREGIDOS ===

  /// Inicializar datos (categorías y productos iniciales)
  Future<void> inicializar() async {
    if (_state == ProductoState.loading) return;

    debugPrint('🔄 Inicializando ProductoProvider...');
    _setState(ProductoState.loading);
    _limpiarError();

    try {
      // Cargar categorías y filtros en paralelo
      await Future.wait([
        _cargarCategorias(),
        _cargarFiltrosDisponibles(),
      ]);
      debugPrint('✅ Categorías y filtros cargados');

      // Cargar productos iniciales
      await cargarProductos(forceRefresh: true);
      debugPrint('✅ Productos iniciales cargados');
      
    } catch (e) {
      debugPrint('❌ Error en inicializar: $e');
      _manejarError(e, 'Error al inicializar datos');
    }
  }

  /// Cargar productos iniciales o con filtros nuevos
  Future<void> cargarProductos({
    bool forceRefresh = false,
    bool mostrarLoading = true,
  }) async {
    // Cache check
    if (!forceRefresh &&
        _productos.isNotEmpty &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      debugPrint("⏩ Usando cache de productos (última carga hace menos de 5 min)");
      return;
    }

    // ✅ CORREGIDO: Reset completo para nueva búsqueda/filtros
    _page = 0;
    _hasMore = true;
    
    if (forceRefresh) {
      debugPrint("🔄 Refrescando productos (forceRefresh: true)...");
      _productos.clear();
      _setState(ProductoState.refreshing);
      notifyListeners();
    }

    await _fetchProductos(isFirstLoad: true, mostrarLoading: mostrarLoading);
  }

  /// ✅ CORREGIDO: Método separado para cargar más productos
  Future<void> cargarMasProductos({bool mostrarLoading = true}) async {
    if (isLoadingMore || !_hasMore) {
      debugPrint("⚠️ No se cargan más productos (isLoadingMore=$isLoadingMore, hasMore=$_hasMore)");
      return;
    }
    
    debugPrint("➡️ Cargando más productos (página ${_page + 1})...");
    await _fetchProductos(isFirstLoad: false, mostrarLoading: mostrarLoading);
  }

  /// ✅ NUEVO: Método interno simplificado y claro
  Future<void> _fetchProductos({
    required bool isFirstLoad,
    bool mostrarLoading = true,
  }) async {
    if (mostrarLoading) {
      _setState(isFirstLoad ? ProductoState.loading : ProductoState.loadingMore);
      _limpiarError();
    }

    try {
      // ✅ CORREGIDO: Solo incrementar página si NO es primera carga
      if (!isFirstLoad) {
        _page++;
      }
      
      final filtros = _construirFiltros();
      debugPrint('🌐 Llamando API - Página: $_page, Límite: $_pageSize');
      
      final response = await _productoService.obtenerProductosPaginados(filtros);

      final nuevosProductos = List<Map<String, dynamic>>.from(
        response['productos'] ?? []
      );
      final total = response['total'] ?? 0;

      // ✅ CORREGIDO: Lógica clara de append/replace
      if (isFirstLoad) {
        _productos = nuevosProductos;
        debugPrint('🔄 Productos reemplazados: ${nuevosProductos.length}');
      } else {
        _productos.addAll(nuevosProductos);
        debugPrint('➕ Productos añadidos: ${nuevosProductos.length}');
      }

      // ✅ CORREGIDO: Actualizar estado de paginación
      _hasMore = _productos.length < total;
      _totalProductos = total;
      _lastFetch = DateTime.now();

      debugPrint('📦 Página $_page cargada: ${nuevosProductos.length} productos (total: ${_productos.length}/$total, hasMore: $_hasMore)');

      // ✅ CORREGIDO: Auto-carga solo en primera carga y si faltan pocos
      if (isFirstLoad &&
          _productos.length < total &&
          (total - _productos.length) <= _pageSize &&
          total <= 40) { // Limitar auto-carga para listas muy grandes
        debugPrint('⚡ Auto-cargando página restante...');
        await cargarMasProductos(mostrarLoading: false);
      }

      _aplicarFiltrosLocales();
      _setState(ProductoState.loaded);

    } on SocketException {
      _errorMessage = 'Sin conexión a internet';
      debugPrint("❌ Error: $_errorMessage");
      _setState(ProductoState.error);
    } on TimeoutException {
      _errorMessage = 'Tiempo de espera agotado';
      debugPrint("❌ Error: $_errorMessage");
      _setState(ProductoState.error);
    } catch (e) {
      debugPrint('❌ Error cargando productos: $e');
      _manejarError(e, 'Error al cargar productos');
    }
  }

  /// Refrescar todos los datos
  Future<void> refrescar() async {
    debugPrint('🔄 Refrescando datos...');
    await cargarProductos(forceRefresh: true);
  }

  /// Buscar productos - CORREGIDO
  void buscarProductos(String query) {
    final nuevaBusqueda = query.trim();
    debugPrint('🔍 Buscando productos: "$nuevaBusqueda"');
    
    if (_busqueda != nuevaBusqueda) {
      _busqueda = nuevaBusqueda;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    } else {
      _aplicarFiltrosLocales();
      notifyListeners();
    }
  }

  /// Filtrar por categoría - CORREGIDO
  void filtrarPorCategoria(String? categoriaId) {
    debugPrint('🏷️ Filtrando por categoría: $categoriaId');
    
    if (_categoriaSeleccionada != categoriaId) {
      _categoriaSeleccionada = categoriaId;
      _subcategoriaSeleccionada = null;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    }
  }

  /// Filtrar por subcategoría
  void filtrarPorSubcategoria(String? subcategoriaId) {
    if (_subcategoriaSeleccionada != subcategoriaId) {
      _subcategoriaSeleccionada = subcategoriaId;
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    }
  }

  /// Aplicar filtros múltiples
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

  /// Limpiar filtros
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

  /// Cambiar ordenamiento
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

  /// Crear producto
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

      // NUEVO: Si el servicio retorna el producto creado, agregarlo localmente
      if (productoCreado != null) {
        _productos.insert(0, Map<String, dynamic>.from(productoCreado));
        _aplicarFiltrosLocales();
        _setState(ProductoState.loaded);
        debugPrint('✅ Producto creado y agregado localmente: $nombre');
        return true;
      } else {
        // Si no retorna el producto, recargar todo
        await refrescar();
        return true;
      }

    } catch (e) {
      _manejarError(e, 'Error al crear producto');
      return false;
    }
  }

  /// Obtener producto por ID - CORREGIDO
  Future<Map<String, dynamic>?> obtenerProductoPorId(String id) async {
    try {
      // Primero intentar encontrar en la lista local
      Map<String, dynamic>? producto = _encontrarProductoPorId(id, _productos);
      
      if (producto != null) {
        _productoSeleccionado = producto;
        notifyListeners();
        return _productoSeleccionado;
      }

      // Si no está en local, hacer llamada al servicio
      _productoSeleccionado = await _productoService.obtenerProductoPorId(id);
      notifyListeners();
      return _productoSeleccionado;
    } catch (e) {
      _manejarError(e, 'Error al obtener producto');
      return null;
    }
  }

/// Actualizar producto - CORREGIDO
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
    _setState(ProductoState.updating);
    _limpiarError();

    // Almacenar el producto que se está actualizando
    _productoSeleccionado = _encontrarProductoPorId(id, _productos);

    try {
      // Llamada al servicio
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

      // CORREGIDO: Actualizar producto localmente sin recargar todo
      final index = _productos.indexWhere((p) => 
        p['_id']?.toString() == id || p['id']?.toString() == id);
      
      if (index != -1) {
        // Si el servicio retorna el producto actualizado, usarlo
        // Si no, construir el producto actualizado con los datos locales
        final productoActualizadoLocal = productoActualizado ?? {
          ..._productos[index], // Mantener datos existentes
          'nombre': nombre,
          'descripcion': descripcion,
          'precio': precio,
          'categoria': categoria,
          'subcategoria': subcategoria,
          'stock': stock,
          'disponible': disponible,
          'estado': estado,
          'updatedAt': DateTime.now().toIso8601String(),
          // NUEVO: Si hay imagen local, actualizar también el campo imagen
          if (imagenLocal != null) 'imagen': productoActualizado?['imagen'] ?? _productos[index]['imagen'],
        };
        
        // Actualizar el producto en la lista local
        _productos[index] = Map<String, dynamic>.from(productoActualizadoLocal);
        debugPrint('✅ Producto actualizado localmente: $nombre');
        
        // IMPORTANTE: Aplicar filtros para actualizar AMBAS listas
        _aplicarFiltrosLocales();
        
        // Notificar cambios inmediatamente
        _setState(ProductoState.loaded);
        notifyListeners(); // Forzar notificación adicional
        return true;
      } else {
        // Si no se encuentra localmente, recargar todo
        debugPrint('⚠️ Producto no encontrado localmente, recargando...');
        await refrescar();
        return true;
      }

    } catch (e) {
      _manejarError(e, 'Error al actualizar producto');
      return false;
    } finally {
      _productoSeleccionado = null;
    }
  }

  /// Eliminar producto - CORREGIDO
  Future<bool> eliminarProducto(String id) async {
    _setState(ProductoState.deleting);
    _limpiarError();

    try {
      await _productoService.eliminarProducto(id);
      
      // Remover de lista local (maneja tanto _id como id)
      _removerProductoPorId(id, _productos);
      _aplicarFiltrosLocales();
      
      _setState(ProductoState.loaded);
      return true;

    } catch (e) {
      _manejarError(e, 'Error al eliminar producto');
      return false;
    }
  }

  /// Reducir stock - CORREGIDO
  Future<bool> reducirStock(String id, int cantidad) async {
    try {
      await _productoService.reducirStock(id, cantidad);
      
      // Actualizar stock local
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

  // === MÉTODOS PRIVADOS ===

  void _setState(ProductoState newState) {
    debugPrint('🔄 Cambiando estado: $_state -> $newState');
    _state = newState;
    notifyListeners();
  }

  void _limpiarError() {
    _errorMessage = null;
    _lastErrorCode = null;
  }

  void _manejarError(dynamic error, [String? contexto]) {
    debugPrint('❌ Error en ProductoProvider: $error');
    
    if (error is ProductoException) {
      _errorMessage = error.message;
      _lastErrorCode = error.code;
    } else {
      _errorMessage = contexto ?? error.toString();
    }
    
    _setState(ProductoState.error);
  }

  Future<void> _cargarCategorias() async {
    debugPrint('🏷️ Cargando categorías...');
    _categorias = await _productoService.obtenerCategorias();
    debugPrint('✅ Categorías cargadas: ${_categorias.length}');
  }

  Future<void> _cargarFiltrosDisponibles() async {
    debugPrint('🔧 Cargando filtros disponibles...');
    _filtrosDisponibles = await _productoService.obtenerFiltrosDisponibles();
    debugPrint('✅ Filtros disponibles cargados: ${_filtrosDisponibles.keys}');
  }

  /// CORREGIDO: Reset paginación igual que el provider funcional
  void _resetearPaginacion() {
    _page = 0; // ← CAMBIO: Reset a 0
    _hasMore = true;
    _productos.clear();
    _lastFetch = null; // Invalidar cache
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
      page: _page, // ← CORREGIDO: Usar _page en lugar de _currentPage
      limit: _pageSize,
    );
    
    // DEBUG
    debugPrint('🔍 FILTROS: page=$_page, limit=$_pageSize, query=${_busqueda}');
    
    return filtros;
  }

  void _aplicarFiltrosLocales() {
    debugPrint('🏷️ Aplicando filtros locales a ${_productos.length} productos...');
    
    // Para filtros del servidor, usar la lista completa
    if (_tieneServidorFiltros()) {
      _productosFiltrados = List.from(_productos);
    } else {
      _productosFiltrados = _productos.where((producto) {
        return true; // Mostrar todos si no hay filtros del servidor
      }).toList();
    }

    debugPrint('✅ Productos después del filtro: ${_productosFiltrados.length}');
    _aplicarOrdenamiento();
  }

  bool _tieneServidorFiltros() {
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
        default: // nombre
          final nombreA = a['nombre']?.toString().toLowerCase() ?? '';
          final nombreB = b['nombre']?.toString().toLowerCase() ?? '';
          comparison = nombreA.compareTo(nombreB);
      }
      
      return _sortAscending ? comparison : -comparison;
    });
    debugPrint('🔄 Productos ordenados por $_sortBy (${_sortAscending ? 'ASC' : 'DESC'})');
  }

  bool _listEquals<T>(List<T> list1, List<T> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (list1[i] != list2[i]) return false;
    }
    return true;
  }

  // === UTILIDADES PÚBLICAS ===

  /// Método para mostrar todos los productos (quitar filtros de categoría pero mantener búsqueda)
  void mostrarTodosLosProductos() {
    debugPrint('🔄 Mostrando todos los productos (quitando filtro de categoría)');
    
    // Solo limpiar filtro de categoría, mantener búsqueda si existe
    final busquedaActual = _busqueda;
    
    _categoriaSeleccionada = null;
    _subcategoriaSeleccionada = null;
    
    // Si había búsqueda, mantenerla y recargar con ese filtro
    if (busquedaActual.isNotEmpty) {
      _resetearPaginacion();
      cargarProductos(forceRefresh: true);
    } else {
      // Si no hay búsqueda, simplemente aplicar filtros locales sin recargar
      _aplicarFiltrosLocales();
      notifyListeners();
    }
  }

  /// Productos aleatorios - igual que el provider funcional
  List<Map<String, dynamic>> obtenerProductosAleatorios(int cantidad) {
    if (_productos.isEmpty) return [];
    final copia = List<Map<String, dynamic>>.from(_productos);
    copia.shuffle();
    return copia.take(cantidad).toList();
  }

  /// Filtrar por categoría - igual que el provider funcional
  List<Map<String, dynamic>> filtrarPorCategoriaLocal(String? categoria) {
    if (categoria == null || categoria.isEmpty) return _productos;
    return _productos.where((p) {
      final cat = p['categoria']?.toString().toLowerCase();
      return cat == categoria.toLowerCase();
    }).toList();
  }

  /// Reintentar última operación fallida
  Future<void> reintentar() async {
    debugPrint('🔄 Reintentando operación...');
    switch (_state) {
      case ProductoState.error:
        await inicializar();
        break;
      default:
        await refrescar();
    }
  }

  /// Limpiar datos - igual que el provider funcional
  void limpiar() {
    debugPrint('🧹 Limpiando datos del provider...');
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
    _limpiarError();
    _setState(ProductoState.initial);
  }

  /// Obtener nombre de categoría por ID
  String obtenerNombreCategoria(String? categoriaId) {
    if (categoriaId == null) return 'Sin categoría';
    
    final categoria = _categorias.firstWhere(
      (cat) => cat['_id'] == categoriaId,
      orElse: () => <String, dynamic>{},
    );
    
    return categoria['nombre']?.toString() ?? 'Categoría desconocida';
  }

  /// Verificar si hay filtros activos
  bool get tieneFiltrosActivos {
    return _busqueda.isNotEmpty ||
           _categoriaSeleccionada != null ||
           _subcategoriaSeleccionada != null ||
           _coloresFiltrados.isNotEmpty ||
           _tallasFiltradas.isNotEmpty ||
           _precioMin != null ||
           _precioMax != null;
  }

  @override
  void dispose() {
    debugPrint('🧹 Disposing ProductoProvider...');
    super.dispose();
  }
}