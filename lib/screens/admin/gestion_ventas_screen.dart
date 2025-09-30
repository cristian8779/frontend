import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/venta_service.dart';

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
  Map<String, String> _usuariosCache = {};

  bool _isLoading = false;
  bool _isAdmin = true;
  String _filtroEstado = 'todos';
  DateTimeRange? _rangoFechas;

  @override
  void initState() {
    super.initState();
    _cargarVentas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _ventaService.dispose();
    super.dispose();
  }

  // === MÉTODOS DE CARGA DE DATOS ===

  Future<void> _cargarVentas() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<Map<String, dynamic>> ventas;

      if (_isAdmin) {
        ventas = await _ventaService.obtenerTodasLasVentas();
      } else {
        ventas = await _ventaService.obtenerVentasUsuario();
      }

      await _cargarNombresUsuarios(ventas);

      setState(() {
        _ventas = ventas;
        _ventasFiltradas = ventas;
      });

      _aplicarFiltros();

    } catch (e) {
      _mostrarError('Error al cargar ventas: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _cargarNombresUsuarios(List<Map<String, dynamic>> ventas) async {
    final usuarioIds = ventas
        .map((venta) => venta['usuarioId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();
    
    for (final usuarioId in usuarioIds) {
      if (!_usuariosCache.containsKey(usuarioId)) {
        try {
          final nombreUsuario = await _ventaService.obtenerNombreUsuario(usuarioId!);
          _usuariosCache[usuarioId] = nombreUsuario ?? 'Usuario desconocido';
        } catch (e) {
          _usuariosCache[usuarioId!] = 'Usuario desconocido';
        }
      }
    }
  }

  // === MÉTODOS DE FILTRADO ===

  void _aplicarFiltros() {
    List<Map<String, dynamic>> ventasFiltradas = List.from(_ventas);

    // Filtro por texto de búsqueda
    if (_searchController.text.isNotEmpty) {
      final busqueda = _searchController.text.toLowerCase();
      ventasFiltradas = ventasFiltradas.where((venta) {
        final usuarioId = venta['usuarioId']?.toString() ?? '';
        final nombreUsuario = _obtenerNombreUsuario(venta).toLowerCase();
        final productos = (venta['productos'] as List?) ?? [];
        final productosStr = productos
            .map((p) => (p['nombreProducto'] ?? '').toString().toLowerCase())
            .join(' ');

        return usuarioId.toLowerCase().contains(busqueda) ||
               nombreUsuario.contains(busqueda) ||
               productosStr.contains(busqueda);
      }).toList();
    }

    // Filtro por estado
    if (_filtroEstado != 'todos') {
      ventasFiltradas = ventasFiltradas.where((venta) {
        final estadoVenta = venta['estadoPago']?.toString().toLowerCase();
        return estadoVenta == _filtroEstado;
      }).toList();
    }

    // Filtro por rango de fechas
    if (_rangoFechas != null) {
      ventasFiltradas = ventasFiltradas.where((venta) {
        final fechaStr = venta['fechaVenta']?.toString() ?? venta['fecha']?.toString();
        final fechaVenta = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
        
        if (fechaVenta == null) return false;

        return fechaVenta.isAfter(_rangoFechas!.start.subtract(const Duration(days: 1))) &&
               fechaVenta.isBefore(_rangoFechas!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() {
      _ventasFiltradas = ventasFiltradas;
    });
  }

  Future<void> _seleccionarRangoFechas() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _rangoFechas,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFF3483FA),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _rangoFechas = picked;
      });
      _aplicarFiltros();
    }
  }

  // === MÉTODOS DE GESTIÓN DE VENTAS ===

  Future<void> _actualizarEstadoVenta(String ventaId, String nuevoEstado) async {
    try {
      await _ventaService.actualizarEstadoVenta(
        ventaId: ventaId,
        estadoPago: nuevoEstado,
      );

      _mostrarExito('Estado actualizado correctamente');
      _cargarVentas();
    } catch (e) {
      _mostrarError('Error al actualizar estado: $e');
    }
  }

  Future<void> _eliminarVenta(String ventaId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta venta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _ventaService.eliminarVenta(ventaId);
        _mostrarExito('Venta eliminada correctamente');
        _cargarVentas();
      } catch (e) {
        _mostrarError('Error al eliminar venta: $e');
      }
    }
  }

  // === MÉTODOS DE UI ===

  String _obtenerNombreUsuario(Map<String, dynamic> venta) {
    if (venta['nombreUsuario'] != null && venta['nombreUsuario'].toString().trim().isNotEmpty) {
      return venta['nombreUsuario'].toString().trim();
    }
    
    if (venta['usuario']?['nombre'] != null) {
      return venta['usuario']['nombre'];
    }
    
    final usuarioId = venta['usuarioId']?.toString();
    if (usuarioId != null && _usuariosCache.containsKey(usuarioId)) {
      return _usuariosCache[usuarioId]!;
    }
    
    if (usuarioId != null) {
      return 'Usuario ${usuarioId.substring(usuarioId.length - 8)}';
    }
    
    return 'Usuario desconocido';
  }

  String _obtenerDireccionCompleta(Map<String, dynamic> venta) {
    if (venta['direccionUsuario'] is Map) {
      final dir = venta['direccionUsuario'] as Map;
      final municipio = dir['municipio'] ?? '';
      final departamento = dir['departamento'] ?? '';
      if (municipio.isNotEmpty && departamento.isNotEmpty) {
        return '$municipio, $departamento';
      }
    }
    
    if (venta['usuario']?['direccion'] is Map) {
      final dir = venta['usuario']['direccion'] as Map;
      final municipio = dir['municipio'] ?? '';
      final departamento = dir['departamento'] ?? '';
      if (municipio.isNotEmpty && departamento.isNotEmpty) {
        return '$municipio, $departamento';
      }
    }
    
    final direccionStr = venta['direccionUsuario']?.toString() ?? '';
    if (direccionStr.isNotEmpty && direccionStr != '{}') {
      return direccionStr;
    }
    
    return 'Dirección no disponible';
  }

  String _obtenerCodigoPostal(Map<String, dynamic> venta) {
    if (venta['direccionUsuario'] is Map) {
      final dir = venta['direccionUsuario'] as Map;
      final codigoPostal = dir['codigoPostal']?.toString() ?? '';
      if (codigoPostal.isNotEmpty) {
        return codigoPostal;
      }
    }
    
    if (venta['usuario']?['direccion'] is Map) {
      final dir = venta['usuario']['direccion'] as Map;
      final codigoPostal = dir['codigoPostal']?.toString() ?? '';
      if (codigoPostal.isNotEmpty) {
        return codigoPostal;
      }
    }
    
    return '';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3483FA),
        foregroundColor: Colors.white,
        title: const Text(
          'Gestión de Ventas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _cargarVentas,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3483FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildEstadisticasHeader(),
          ),
          const SizedBox(height: 16),
          // Barra de búsqueda y filtros
          _buildBarraBusqueda(),
          const SizedBox(height: 8),
          // Lista de ventas
          Expanded(child: _buildListaVentas()),
        ],
      ),
    );
  }

  Widget _buildEstadisticasHeader() {
    final resumen = _ventaService.obtenerResumenVentas(_ventasFiltradas);
    
    return Row(
      children: [
        Expanded(
          child: _buildEstadistica(
            'Total Ventas',
            '${resumen['totalVentas']}',
            Icons.receipt_long_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEstadistica(
            'Monto Total',
            '\$${NumberFormat('#,##0', 'es_CO').format(resumen['montoTotal'])}',
            Icons.attach_money_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildEstadistica(
            'Aprobadas',
            '${resumen['ventasAprobadas'] ?? resumen['ventasCompletadas'] ?? 0}',
            Icons.check_circle_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadistica(String titulo, String valor, IconData icono) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icono, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarraBusqueda() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Campo de búsqueda
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por usuario, producto...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[500]),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: Colors.grey[500]),
                        onPressed: () {
                          _searchController.clear();
                          _aplicarFiltros();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              onChanged: (value) => _aplicarFiltros(),
            ),
          ),
          const SizedBox(height: 12),
          // Filtros
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonFormField<String>(
                    value: _filtroEstado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'todos', child: Text('Todos los estados')),
                      DropdownMenuItem(value: 'pending', child: Text('Pendiente')),
                      DropdownMenuItem(value: 'approved', child: Text('Aprobado')),
                      DropdownMenuItem(value: 'failed', child: Text('Fallido')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filtroEstado = value ?? 'todos';
                      });
                      _aplicarFiltros();
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: _rangoFechas != null 
                      ? const Color(0xFF3483FA) 
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextButton.icon(
                  onPressed: _seleccionarRangoFechas,
                  icon: Icon(
                    Icons.date_range_rounded,
                    color: _rangoFechas != null ? Colors.white : const Color(0xFF3483FA),
                  ),
                  label: Text(
                    _rangoFechas == null ? 'Fechas' : 'Rango',
                    style: TextStyle(
                      color: _rangoFechas != null ? Colors.white : const Color(0xFF3483FA),
                    ),
                  ),
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
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _rangoFechas = null;
                      });
                      _aplicarFiltros();
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Color(0xFF3483FA)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildListaVentas() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3483FA)),
        ),
      );
    }

    if (_ventasFiltradas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _ventas.isEmpty 
                  ? 'No hay ventas disponibles'
                  : 'No se encontraron ventas',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_ventas.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Intenta ajustar los filtros',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarVentas,
      color: const Color(0xFF3483FA),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _ventasFiltradas.length,
        itemBuilder: (context, index) {
          return _buildVentaCard(_ventasFiltradas[index]);
        },
      ),
    );
  }

  Widget _buildVentaCard(Map<String, dynamic> venta) {
    final ventaId = venta['_id'] ?? venta['id'] ?? 'sin-id';
    final fechaStr = venta['fechaVenta']?.toString() ?? venta['fecha']?.toString();
    final fechaVenta = fechaStr != null ? DateTime.tryParse(fechaStr) : null;
    final total = (venta['total'] ?? 0).toDouble();
    final estado = venta['estadoPago']?.toString() ?? 'pending';
    final productos = (venta['productos'] as List?) ?? [];
    final nombreUsuario = _obtenerNombreUsuario(venta);
    final direccion = _obtenerDireccionCompleta(venta);
    final codigoPostal = _obtenerCodigoPostal(venta);
    final telefono = venta['telefonoUsuario']?.toString() ?? 
                     venta['usuario']?['telefono']?.toString() ?? '';

    // Configuración de estado
    Color estadoColor;
    IconData estadoIcon;
    String estadoTexto;

    switch (estado.toLowerCase()) {
      case 'approved':
        estadoColor = const Color(0xFF00A650);
        estadoIcon = Icons.check_circle_rounded;
        estadoTexto = 'APROBADO';
        break;
      case 'failed':
        estadoColor = Colors.red;
        estadoIcon = Icons.cancel_rounded;
        estadoTexto = 'FALLIDO';
        break;
      case 'pending':
      default:
        estadoColor = const Color(0xFFFF8C00);
        estadoIcon = Icons.schedule_rounded;
        estadoTexto = 'PENDIENTE';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          childrenPadding: const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(estadoIcon, color: estadoColor, size: 26),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Nombre del usuario
              Row(
                children: [
                  Icon(
                    Icons.person_rounded,
                    size: 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nombreUsuario,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Información de contacto
              if (telefono.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.phone_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      telefono,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              // Dirección
              if (direccion != 'Dirección no disponible') ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        direccion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              // Código postal
              if (codigoPostal.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.markunread_mailbox_rounded,
                      size: 16,
                      color: Colors.grey[500],
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'C.P. $codigoPostal',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
              // Fecha
              Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    size: 16,
                    color: Colors.grey[500],
                  ),
                  const SizedBox(width: 10),
                  Text(
                    fechaVenta != null
                        ? DateFormat('dd/MM/yyyy - HH:mm').format(fechaVenta)
                        : 'Fecha no disponible',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${NumberFormat('#,##0', 'es_CO').format(total)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00A650),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: estadoColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  estadoTexto,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Resumen de productos con botón
            _buildResumenProductos(productos, venta),
            // Acciones de administrador
            if (_isAdmin && ventaId != 'sin-id') ...[
              const SizedBox(height: 16),
              _buildAccionesAdmin(ventaId, estado),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResumenProductos(List<dynamic> productos, Map<String, dynamic> venta) {
    final totalProductos = productos.length;
   final totalItems = productos.fold<int>(
  0,
  (sum, producto) => sum + ((producto['cantidad'] ?? 0) as num).toInt(),
);

    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                size: 24,
                color: Colors.grey[700],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$totalProductos producto${totalProductos != 1 ? 's' : ''} diferentes',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalItems artículo${totalItems != 1 ? 's' : ''} en total',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetalleProductosScreen(
                        productos: productos,
                        nombreUsuario: _obtenerNombreUsuario(venta),
                        total: (venta['total'] ?? 0).toDouble(),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.visibility_rounded, size: 18),
                label: const Text('Ver productos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3483FA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesAdmin(String ventaId, String estado) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (estado.toLowerCase() == 'pending') ...[
            // Botón Aprobar
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF00A650),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00A650).withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _actualizarEstadoVenta(ventaId, 'approved'),
                icon: const Icon(Icons.check_rounded),
                color: Colors.white,
                iconSize: 24,
                tooltip: 'Aprobar venta',
              ),
            ),
            // Botón Rechazar
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: () => _actualizarEstadoVenta(ventaId, 'failed'),
                icon: const Icon(Icons.close_rounded),
                color: Colors.white,
                iconSize: 24,
                tooltip: 'Rechazar venta',
              ),
            ),
          ],
          // Botón Eliminar
          Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => _eliminarVenta(ventaId),
              icon: const Icon(Icons.delete_rounded),
              color: Colors.white,
              iconSize: 24,
              tooltip: 'Eliminar venta',
            ),
          ),
        ],
      ),
    );
  }
}

// ==============================
// PANTALLA DETALLE PRODUCTOS
// ==============================

class DetalleProductosScreen extends StatelessWidget {
  final List<dynamic> productos;
  final String nombreUsuario;
  final double total;

  const DetalleProductosScreen({
    super.key,
    required this.productos,
    required this.nombreUsuario,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF3483FA),
        foregroundColor: Colors.white,
        title: Text(
          'Productos - $nombreUsuario',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header con resumen
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF3483FA),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: _buildHeaderResumen(),
          ),
          const SizedBox(height: 16),
          // Lista de productos
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                return _buildProductoCard(productos[index], context);
              },
            ),
          ),
          // Footer con total
          _buildFooterTotal(),
        ],
      ),
    );
  }

  Widget _buildHeaderResumen() {
    final totalItems = productos.fold<int>(
  0,
  (sum, producto) => sum + ((producto['cantidad'] ?? 0) as num).toInt(),
);

    
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  '${productos.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Productos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 28),
                const SizedBox(height: 8),
                Text(
                  '$totalItems',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Artículos',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> producto, BuildContext context) {
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    final talla = producto['talla'];
    final color = producto['color'];
    final cantidad = producto['cantidad'] ?? 0;
    final precio = (producto['precioUnitario'] ?? producto['precio'] ?? 0).toDouble();
    final subtotal = precio * cantidad;
    
    String colorNombre = '';
    if (color != null) {
      if (color is Map && color['nombre'] != null) {
        colorNombre = color['nombre'];
      } else if (color is String) {
        colorNombre = color;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Imagen del producto
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: producto['imagen'] != null
                ? ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: Image.network(
                      producto['imagen'],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Colors.grey[400],
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.inventory_2_rounded,
                        color: Colors.grey[400],
                        size: 50,
                      ),
                    ),
                  ),
          ),
          // Información del producto
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nombre del producto
                Text(
                  nombreProducto,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                // Características del producto
                Row(
                  children: [
                    if (talla != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.straighten_rounded, 
                                 size: 16, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              'Talla: $talla',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (colorNombre.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_rounded, 
                                 size: 16, color: Colors.purple[700]),
                            const SizedBox(width: 4),
                            Text(
                              colorNombre,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.purple[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Cantidad y precios
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart_outlined, 
                               size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Cantidad:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$cantidad',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.green[700],
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.attach_money_rounded, 
                               size: 20, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Precio unitario:',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${NumberFormat("#,##0", "es_CO").format(precio)}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF3483FA),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.calculate_rounded, 
                               size: 20, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Subtotal:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${NumberFormat("#,##0", "es_CO").format(subtotal)}',

                            style: const TextStyle(
                              fontSize: 20,
                              color: Color(0xFF00A650),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterTotal() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.receipt_long_rounded, 
               size: 28, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Text(
            'TOTAL GENERAL:',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            '${NumberFormat("#,##0", "es_CO").format(total)}',
            style: const TextStyle(
              fontSize: 24,
              color: Color(0xFF00A650),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}