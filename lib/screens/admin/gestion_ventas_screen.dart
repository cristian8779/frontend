import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/venta_service.dart'; // Importa tu servicio desde la ruta correcta

class GestionVentasScreen extends StatefulWidget {
  const GestionVentasScreen({super.key});

  @override
  State<GestionVentasScreen> createState() => _GestionVentasScreenState();
}

class _GestionVentasScreenState extends State<GestionVentasScreen> {
  final VentaService _ventaService = VentaService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _ventas = [];
  List<Map<String, dynamic>> _ventasFiltradas = [];
  Map<String, String> _usuariosCache = {}; // Cache para nombres de usuarios

  bool _isLoading = false;
  bool _isAdmin = true; // Cambiar según el rol del usuario
  String _filtroEstado = 'todos';
  String? _usuarioSeleccionado;
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    print('🚀 [GestionVentas] Iniciando pantalla de gestión de ventas');
    print('👤 [GestionVentas] Modo admin: $_isAdmin');
    _cargarVentas();
  }

  @override
  void dispose() {
    print('🗑️ [GestionVentas] Disposing recursos');
    _searchController.dispose();
    _ventaService.dispose();
    super.dispose();
  }

  // === MÉTODOS DE CARGA DE DATOS ===

  Future<void> _cargarVentas() async {
    if (_isLoading) {
      print('⏳ [GestionVentas] Ya se están cargando las ventas, ignorando llamada');
      return;
    }

    print('📥 [GestionVentas] Iniciando carga de ventas');
    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> ventas;

      if (_isAdmin) {
        print('🔍 [GestionVentas] Cargando TODAS las ventas (modo admin)');
        ventas = await _ventaService.obtenerTodasLasVentas();
        print('📊 [GestionVentas] Obtenidas ${ventas.length} ventas totales');
      } else {
        print('👤 [GestionVentas] Cargando ventas del usuario actual');
        ventas = await _ventaService.obtenerVentasUsuario();
        print('📊 [GestionVentas] Obtenidas ${ventas.length} ventas del usuario');
      }

      // Log de muestra de datos
      if (ventas.isNotEmpty) {
        print('📋 [GestionVentas] Muestra de primera venta:');
        print('   - ID: ${ventas.first['_id'] ?? ventas.first['id']}');
        print('   - Usuario ID: ${ventas.first['usuarioId']}');
        print('   - Total: ${ventas.first['total']}');
        print('   - Estado: ${ventas.first['estadoPago']}');
        print('   - Fecha: ${ventas.first['fecha'] ?? ventas.first['fechaVenta']}');
      }

      // Cargar nombres de usuarios para las ventas
      print('👥 [GestionVentas] Iniciando carga de nombres de usuarios');
      await _cargarNombresUsuarios(ventas);
      print('✅ [GestionVentas] Nombres de usuarios cargados');

      setState(() {
        _ventas = ventas;
        _ventasFiltradas = ventas;
      });

      print('🔄 [GestionVentas] Aplicando filtros iniciales');
      _aplicarFiltros();
      print('✅ [GestionVentas] Carga de ventas completada exitosamente');

    } catch (e) {
      print('❌ [GestionVentas] Error al cargar ventas: $e');
      print('📍 [GestionVentas] Stack trace: ${StackTrace.current}');
      _mostrarError('Error al cargar ventas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
      print('🏁 [GestionVentas] Finalizando proceso de carga');
    }
  }

  Future<void> _cargarNombresUsuarios(List<Map<String, dynamic>> ventas) async {
    print('👥 [GestionVentas] === INICIO CARGA NOMBRES USUARIOS ===');
    
    // Obtener lista única de usuarioIds
    final usuarioIds = ventas
        .map((venta) => venta['usuarioId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    print('🔍 [GestionVentas] Usuario IDs únicos encontrados: ${usuarioIds.length}');
    print('📋 [GestionVentas] IDs: ${usuarioIds.join(', ')}');
    
    // Estado del caché antes
    print('💾 [GestionVentas] Usuarios en caché antes: ${_usuariosCache.keys.length}');
    print('📝 [GestionVentas] Caché actual: $_usuariosCache');

    // Cargar nombres solo para usuarios que no están en caché
    int cargados = 0;
    int errores = 0;
    
    for (final usuarioId in usuarioIds) {
      if (!_usuariosCache.containsKey(usuarioId)) {
        print('🔄 [GestionVentas] Cargando nombre para usuario: $usuarioId');
        try {
          final nombreUsuario = await _ventaService.obtenerNombreUsuario(usuarioId!);
          _usuariosCache[usuarioId] = nombreUsuario ?? 'Usuario desconocido';
          print('✅ [GestionVentas] Nombre cargado para $usuarioId: ${_usuariosCache[usuarioId]}');
          cargados++;
        } catch (e) {
          print('❌ [GestionVentas] Error obteniendo nombre para usuario $usuarioId: $e');
          _usuariosCache[usuarioId!] = 'Usuario desconocido';
          errores++;
        }
      } else {
        print('💾 [GestionVentas] Usuario $usuarioId ya está en caché: ${_usuariosCache[usuarioId]}');
      }
    }
    
    print('📊 [GestionVentas] Resumen carga nombres:');
    print('   - Nombres cargados: $cargados');
    print('   - Errores: $errores');
    print('   - Total en caché: ${_usuariosCache.keys.length}');
    print('👥 [GestionVentas] === FIN CARGA NOMBRES USUARIOS ===');
  }

  // === MÉTODOS DE FILTRADO ===

  void _aplicarFiltros() {
    print('🔍 [GestionVentas] === APLICANDO FILTROS ===');
    print('📊 [GestionVentas] Ventas totales antes del filtro: ${_ventas.length}');
    
    List<Map<String, dynamic>> ventasFiltradas = List.from(_ventas);

    // Filtro por texto de búsqueda
    if (_searchController.text.isNotEmpty) {
      final busqueda = _searchController.text.toLowerCase();
      print('🔤 [GestionVentas] Aplicando filtro de búsqueda: "$busqueda"');
      
      final ventasAntes = ventasFiltradas.length;
      ventasFiltradas = ventasFiltradas.where((venta) {
        final usuarioId = venta['usuarioId']?.toString() ?? '';
        final nombreUsuario = _obtenerNombreUsuario(venta).toLowerCase();
        final productos = (venta['productos'] as List?) ?? [];
        final productosStr = productos
            .map((p) => (p['nombreProducto'] ?? '').toString().toLowerCase())
            .join(' ');

        final coincideUsuario = usuarioId.toLowerCase().contains(busqueda);
        final coincideNombre = nombreUsuario.contains(busqueda);
        final coincideProducto = productosStr.contains(busqueda);
        
        final coincide = coincideUsuario || coincideNombre || coincideProducto;
        
        if (coincide) {
          print('✅ [GestionVentas] Venta ${venta['_id'] ?? venta['id']} coincide con búsqueda');
        }
        
        return coincide;
      }).toList();
      
      print('📊 [GestionVentas] Filtro búsqueda: ${ventasAntes} → ${ventasFiltradas.length}');
    }

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      print('📊 [GestionVentas] Aplicando filtro de estado: $_filtroEstado');
      final ventasAntes = ventasFiltradas.length;
      
      ventasFiltradas = ventasFiltradas.where((venta) {
        final estadoVenta = venta['estadoPago']?.toString().toLowerCase();
        final coincide = estadoVenta == _filtroEstado;
        
        if (coincide) {
          print('✅ [GestionVentas] Venta ${venta['_id'] ?? venta['id']} coincide con estado $_filtroEstado');
        }
        
        return coincide;
      }).toList();
      
      print('📊 [GestionVentas] Filtro estado: ${ventasAntes} → ${ventasFiltradas.length}');
    }

    // Filtro por rango de fechas
    if (_rangoFechas != null) {
      print('📅 [GestionVentas] Aplicando filtro de fechas:');
      print('   - Desde: ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.start)}');
      print('   - Hasta: ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.end)}');
      
      final ventasAntes = ventasFiltradas.length;
      
      ventasFiltradas = ventasFiltradas.where((venta) {
        final fechaStr = venta['fechaVenta']?.toString() ?? venta['fecha']?.toString();
        final fechaVenta = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
        
        if (fechaVenta == null) {
          print('⚠️ [GestionVentas] Venta sin fecha válida: ${venta['_id'] ?? venta['id']}');
          return false;
        }

        final coincide = fechaVenta.isAfter(_rangoFechas!.start.subtract(const Duration(days: 1))) &&
            fechaVenta.isBefore(_rangoFechas!.end.add(const Duration(days: 1)));
            
        if (coincide) {
          print('✅ [GestionVentas] Venta ${venta['_id'] ?? venta['id']} dentro del rango de fechas');
        }
        
        return coincide;
      }).toList();
      
      print('📊 [GestionVentas] Filtro fechas: ${ventasAntes} → ${ventasFiltradas.length}');
    }

    print('📊 [GestionVentas] RESULTADO FINAL: ${ventasFiltradas.length} ventas después de todos los filtros');

    setState(() {
      _ventasFiltradas = ventasFiltradas;
    });
    
    print('🔍 [GestionVentas] === FIN APLICACIÓN FILTROS ===');
  }

  Future<void> _seleccionarRangoFechas() async {
    print('📅 [GestionVentas] Abriendo selector de rango de fechas');
    
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
    );

    if (picked != null) {
      print('📅 [GestionVentas] Rango de fechas seleccionado:');
      print('   - Desde: ${DateFormat('dd/MM/yyyy').format(picked.start)}');
      print('   - Hasta: ${DateFormat('dd/MM/yyyy').format(picked.end)}');
      
      setState(() {
        _rangoFechas = picked;
      });
      _aplicarFiltros();
    } else {
      print('📅 [GestionVentas] Selección de fechas cancelada');
    }
  }

  // === MÉTODOS DE GESTIÓN DE VENTAS ===

  Future<void> _actualizarEstadoVenta(String ventaId, String nuevoEstado) async {
    print('🔄 [GestionVentas] Actualizando estado de venta:');
    print('   - Venta ID: $ventaId');
    print('   - Nuevo estado: $nuevoEstado');
    
    try {
      await _ventaService.actualizarEstadoVenta(
        ventaId: ventaId,
        estadoPago: nuevoEstado,
      );

      print('✅ [GestionVentas] Estado actualizado exitosamente');
      _mostrarExito('Estado de venta actualizado exitosamente');
      
      print('🔄 [GestionVentas] Recargando ventas después de actualizar estado');
      _cargarVentas();
    } catch (e) {
      print('❌ [GestionVentas] Error al actualizar estado: $e');
      print('📍 [GestionVentas] Stack trace: ${StackTrace.current}');
      _mostrarError('Error al actualizar estado: $e');
    }
  }

  Future<void> _eliminarVenta(String ventaId) async {
    print('🗑️ [GestionVentas] Solicitando confirmación para eliminar venta: $ventaId');
    
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta venta?'),
        actions: [
          TextButton(
            onPressed: () {
              print('❌ [GestionVentas] Eliminación cancelada por el usuario');
              Navigator.pop(context, false);
            },
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              print('✅ [GestionVentas] Eliminación confirmada por el usuario');
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      print('🗑️ [GestionVentas] Procediendo a eliminar venta: $ventaId');
      try {
        await _ventaService.eliminarVenta(ventaId);
        print('✅ [GestionVentas] Venta eliminada exitosamente');
        _mostrarExito('Venta eliminada exitosamente');
        
        print('🔄 [GestionVentas] Recargando ventas después de eliminar');
        _cargarVentas();
      } catch (e) {
        print('❌ [GestionVentas] Error al eliminar venta: $e');
        print('📍 [GestionVentas] Stack trace: ${StackTrace.current}');
        _mostrarError('Error al eliminar venta: $e');
      }
    } else {
      print('🚫 [GestionVentas] Eliminación no confirmada');
    }
  }

  // === MÉTODOS DE UI ===

  String _obtenerNombreUsuario(Map<String, dynamic> venta) {
    final ventaId = venta['_id'] ?? venta['id'] ?? 'sin-id';
    print('👤 [GestionVentas] Obteniendo nombre usuario para venta: $ventaId');
    
    // PRIMERO: Verificar si el backend ya expandió el nombreUsuario
    if (venta['nombreUsuario'] != null && venta['nombreUsuario'].toString().trim().isNotEmpty) {
      final nombre = venta['nombreUsuario'].toString().trim();
      print('✅ [GestionVentas] Nombre obtenido del backend (expandido): $nombre');
      return nombre;
    }
    
    // SEGUNDO: Intentar obtener el nombre desde la venta directamente
    if (venta['usuario']?['nombre'] != null) {
      final nombre = venta['usuario']['nombre'];
      print('✅ [GestionVentas] Nombre obtenido de venta.usuario.nombre: $nombre');
      return nombre;
    }
    
    // TERCERO: Si no está disponible, buscar en el caché usando el usuarioId
    final usuarioId = venta['usuarioId']?.toString();
    if (usuarioId != null && _usuariosCache.containsKey(usuarioId)) {
      final nombre = _usuariosCache[usuarioId]!;
      print('✅ [GestionVentas] Nombre obtenido del caché para $usuarioId: $nombre');
      return nombre;
    }
    
    // ÚLTIMO RECURSO: Crear nombre temporal basado en ID
    if (usuarioId != null) {
      final nombreTemp = 'Usuario ${usuarioId.substring(usuarioId.length - 8)}';
      print('⚠️ [GestionVentas] Usando nombre temporal para $usuarioId: $nombreTemp');
      return nombreTemp;
    }
    
    print('⚠️ [GestionVentas] No se pudo obtener nombre, usando valor por defecto');
    return 'Usuario desconocido';
  }

  void _mostrarError(String mensaje) {
    print('❌ [GestionVentas] Mostrando error: $mensaje');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    print('✅ [GestionVentas] Mostrando éxito: $mensaje');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('🎨 [GestionVentas] Construyendo UI - ${_ventasFiltradas.length} ventas a mostrar');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Ventas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              print('🔄 [GestionVentas] Botón refresh presionado');
              _cargarVentas();
            },
          ),
        ],
      ),
      body: _buildListaVentas(),
    );
  }

  Widget _buildListaVentas() {
    print('📋 [GestionVentas] Construyendo lista de ventas');
    return Column(
      children: [
        // Barra de búsqueda y filtros
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[50],
          child: Column(
            children: [
              // Campo de búsqueda
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar por usuario o producto...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            print('🧹 [GestionVentas] Limpiando búsqueda');
                            _searchController.clear();
                            _aplicarFiltros();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  print('🔤 [GestionVentas] Texto búsqueda cambiado: "$value"');
                  _aplicarFiltros();
                },
              ),
              const SizedBox(height: 12),
              // Filtros
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filtroEstado,
                      decoration: const InputDecoration(
                        labelText: 'Estado',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'todos', child: Text('Todos')),
                        DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                        DropdownMenuItem(value: 'completado', child: Text('Completado')),
                        DropdownMenuItem(value: 'cancelado', child: Text('Cancelado')),
                        DropdownMenuItem(value: 'approved', child: Text('Aprobado')),
                      ],
                      onChanged: (value) {
                        print('📊 [GestionVentas] Filtro estado cambiado: $value');
                        setState(() {
                          _filtroEstado = value ?? 'todos';
                        });
                        _aplicarFiltros();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _seleccionarRangoFechas,
                    icon: const Icon(Icons.date_range),
                    label: Text(_rangoFechas == null ? 'Fechas' : 'Rango seleccionado'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rangoFechas != null ? Colors.blue : null,
                      foregroundColor: _rangoFechas != null ? Colors.white : null,
                    ),
                  ),
                ],
              ),
              if (_rangoFechas != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Desde: ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.start)} - '
                          'Hasta: ${DateFormat('dd/MM/yyyy').format(_rangoFechas!.end)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          print('🧹 [GestionVentas] Limpiando filtro de fechas');
                          setState(() {
                            _rangoFechas = null;
                          });
                          _aplicarFiltros();
                        },
                        child: const Text('Limpiar'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        // Lista de ventas
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _ventasFiltradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            _ventas.isEmpty 
                                ? 'No hay ventas disponibles'
                                : 'No se encontraron ventas con los filtros actuales',
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () {
                        print('↻ [GestionVentas] Pull-to-refresh activado');
                        return _cargarVentas();
                      },
                      child: ListView.builder(
                        itemCount: _ventasFiltradas.length,
                        itemBuilder: (context, index) {
                          final venta = _ventasFiltradas[index];
                          print('🃏 [GestionVentas] Construyendo card para venta ${index + 1}/${_ventasFiltradas.length}');
                          return _buildVentaCard(venta);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildVentaCard(Map<String, dynamic> venta) {
    final ventaId = venta['_id'] ?? venta['id'] ?? 'sin-id';
    print('🃏 [GestionVentas] === CONSTRUYENDO CARD VENTA ===');
    print('🔍 [GestionVentas] Venta ID: $ventaId');
    
    final fechaStr = venta['fechaVenta']?.toString() ?? venta['fecha']?.toString();
    final fechaVenta = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    final total = (venta['total'] ?? 0).toDouble();
    final estado = venta['estadoPago']?.toString() ?? 'pendiente';
    final productos = (venta['productos'] as List?) ?? [];
    
    print('📊 [GestionVentas] Datos de la venta:');
    print('   - Total: \$${total.toStringAsFixed(2)}');
    print('   - Estado: $estado');
    print('   - Productos: ${productos.length}');
    print('   - Fecha: ${fechaVenta != null ? DateFormat('dd/MM/yyyy HH:mm').format(fechaVenta) : 'Sin fecha'}');

    Color estadoColor;
    IconData estadoIcon;

    switch (estado.toLowerCase()) {
      case 'completado':
      case 'pagado':
      case 'approved':
        estadoColor = Colors.green;
        estadoIcon = Icons.check_circle;
        print('✅ [GestionVentas] Estado: Completado/Aprobado');
        break;
      case 'cancelado':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel;
        print('❌ [GestionVentas] Estado: Cancelado');
        break;
      default:
        estadoColor = Colors.orange;
        estadoIcon = Icons.schedule;
        print('⏳ [GestionVentas] Estado: Pendiente');
    }

    final nombreUsuario = _obtenerNombreUsuario(venta);
    print('👤 [GestionVentas] Nombre usuario final: $nombreUsuario');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.2),
          child: Icon(estadoIcon, color: estadoColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                nombreUsuario,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '\$${total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (fechaVenta != null)
              Text(DateFormat('dd/MM/yyyy HH:mm').format(fechaVenta)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: estadoColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                estado.toUpperCase(),
                style: TextStyle(
                  color: estadoColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productos:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...productos.map<Widget>((producto) {
                  final nombreProducto = producto['nombreProducto'] ?? 'Producto';
                  final talla = producto['talla'];
                  final color = producto['color'];
                  final cantidad = producto['cantidad'] ?? 0;
                  final precio = (producto['precioUnitario'] ?? 0).toDouble();
                  
                  print('🛍️ [GestionVentas] Producto: $nombreProducto (${cantidad}x \$${precio.toStringAsFixed(2)})');
                  
                  String colorStr = '';
                  if (color != null) {
                    if (color is Map && color['nombre'] != null) {
                      colorStr = '[${color['nombre']}]';
                    } else if (color is String) {
                      colorStr = '[$color]';
                    }
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$nombreProducto '
                            '${talla != null ? "($talla)" : ""} '
                            '$colorStr',
                          ),
                        ),
                        Text(
                          '${cantidad}x \$${precio.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }),
                if (_isAdmin && ventaId != 'sin-id') ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (estado.toLowerCase() == 'pendiente') ...[
                        ElevatedButton.icon(
                          onPressed: () {
                            print('✅ [GestionVentas] Botón completar presionado para venta: $ventaId');
                            _actualizarEstadoVenta(ventaId, 'completado');
                          },
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Completar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            print('❌ [GestionVentas] Botón cancelar presionado para venta: $ventaId');
                            _actualizarEstadoVenta(ventaId, 'cancelado');
                          },
                          icon: const Icon(Icons.cancel, size: 16),
                          label: const Text('Cancelar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                      TextButton.icon(
                        onPressed: () {
                          print('🗑️ [GestionVentas] Botón eliminar presionado para venta: $ventaId');
                          _eliminarVenta(ventaId);
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text('Eliminar',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}