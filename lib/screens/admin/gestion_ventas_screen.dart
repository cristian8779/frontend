import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/venta_service.dart';
import 'styles/gestion_ventas/app_colors.dart';
import 'styles/gestion_ventas/app_styles.dart';
import 'styles/gestion_ventas/responsive_utils.dart';
import 'styles/gestion_ventas/venta_estado_helper.dart';
import 'styles/gestion_ventas/venta_widgets.dart';
import 'detalle_venta_screen.dart';

class GestionVentasScreen extends StatefulWidget {
  const GestionVentasScreen({super.key});

  @override
  State<GestionVentasScreen> createState() => _GestionVentasScreenState();
}

class _GestionVentasScreenState extends State<GestionVentasScreen> {
  final VentaService _ventaService = VentaService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _scrollController.dispose();
    _ventaService.dispose();
    super.dispose();
  }

  // === MÉTODOS DE CARGA DE DATOS ===

  Future<void> _cargarVentas() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

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
      setState(() => _isLoading = false);
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

    if (_filtroEstado != 'todos') {
      ventasFiltradas = ventasFiltradas.where((venta) {
        final estadoVenta = venta['estadoPago']?.toString().toLowerCase();
        return estadoVenta == _filtroEstado;
      }).toList();
    }

    if (_rangoFechas != null) {
      ventasFiltradas = ventasFiltradas.where((venta) {
        final fechaStr = venta['fechaVenta']?.toString() ?? venta['fecha']?.toString();
        final fechaVenta = fechaStr != null ? DateTime.tryParse(fechaStr) : null;

        if (fechaVenta == null) return false;

        return fechaVenta.isAfter(_rangoFechas!.start.subtract(const Duration(days: 1))) &&
               fechaVenta.isBefore(_rangoFechas!.end.add(const Duration(days: 1)));
      }).toList();
    }

    setState(() => _ventasFiltradas = ventasFiltradas);
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
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _rangoFechas = picked);
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

      if (mounted) {
        _mostrarExito('Estado actualizado correctamente');
        _cargarVentas();
      }
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al actualizar estado: $e');
      }
    }
  }

 
Future<bool> _eliminarVenta(String ventaId) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusXLarge),
      title: const Text('Confirmar eliminación'),
      content: const Text('¿Estás seguro de que quieres eliminar esta venta?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Eliminar', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );

  if (confirmar == true) {
    try {
      await _ventaService.eliminarVenta(ventaId);
      
      if (mounted) {
        _mostrarExito('Venta eliminada correctamente');
        await _cargarVentas();
      }
      return true;
    } catch (e) {
      if (mounted) {
        _mostrarError('Error al eliminar venta: $e');
      }
      return false;
    }
  }
  return false;
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

    return 'No disponible';
  }

  String _obtenerCodigoPostal(Map<String, dynamic> venta) {
    if (venta['direccionUsuario'] is Map) {
      final dir = venta['direccionUsuario'] as Map;
      final codigoPostal = dir['codigoPostal']?.toString() ?? '';
      if (codigoPostal.isNotEmpty) return codigoPostal;
    }

    if (venta['usuario']?['direccion'] is Map) {
      final dir = venta['usuario']['direccion'] as Map;
      final codigoPostal = dir['codigoPostal']?.toString() ?? '';
      if (codigoPostal.isNotEmpty) return codigoPostal;
    }

    return '';
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
        margin: AppStyles.paddingMedium,
      ),
    );
  }

  void _mostrarExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppStyles.radiusMedium),
        margin: AppStyles.paddingMedium,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarVentas,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Botón de volver
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: AppColors.primary,
                        iconSize: 28,
                      ),
                    ],
                  ),
                ),
              ),
              // Header siempre visible
              SliverToBoxAdapter(
                child: VentaWidgets.buildHeader(onRefresh: _cargarVentas),
              ),
              // Estadísticas siempre visibles
              SliverToBoxAdapter(
                child: VentaWidgets.buildEstadisticasCard(
                  _ventaService.obtenerResumenVentas(_ventasFiltradas),
                ),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: 20),
              ),
              // Búsqueda y filtros siempre visibles
              SliverToBoxAdapter(
                child: _buildSearchAndFilters(),
              ),
              SliverToBoxAdapter(
                child: const SizedBox(height: 16),
              ),
              // Lista de ventas
              _buildSliverListaVentas(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: AppStyles.paddingHorizontal,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VentaWidgets.buildSearchField(
            controller: _searchController,
            onChanged: _aplicarFiltros,
            onClear: () {
              _searchController.clear();
              _aplicarFiltros();
            },
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                VentaWidgets.buildFilterChip(
                  label: _filtroEstado == 'todos'
                      ? 'Todos'
                      : VentaEstadoHelper.getEstadoLabel(_filtroEstado),
                  icon: Icons.filter_list_rounded,
                  isActive: _filtroEstado != 'todos',
                  onTap: _showEstadoFilter,
                ),
                const SizedBox(width: 8),
                VentaWidgets.buildFilterChip(
                  label: _rangoFechas == null ? 'Fechas' : 'Rango activo',
                  icon: Icons.calendar_today_rounded,
                  isActive: _rangoFechas != null,
                  onTap: _seleccionarRangoFechas,
                ),
                if (_rangoFechas != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      setState(() => _rangoFechas = null);
                      _aplicarFiltros();
                    },
                    child: Container(
                      padding: AppStyles.paddingSmall,
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.close_rounded, size: 18, color: Colors.red[400]),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEstadoFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: AppStyles.paddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _buildEstadoOption('todos', 'Todos los estados', Icons.list_rounded),
            _buildEstadoOption('pending', 'Pendiente', Icons.schedule_rounded),
            _buildEstadoOption('approved', 'Aprobado', Icons.check_circle_rounded),
            _buildEstadoOption('failed', 'Fallido', Icons.cancel_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoOption(String value, String label, IconData icon) {
    final isSelected = _filtroEstado == value;
    return InkWell(
      onTap: () {
        setState(() => _filtroEstado = value);
        _aplicarFiltros();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: AppStyles.paddingMedium,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.grey[50],
          borderRadius: AppStyles.radiusMedium,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverListaVentas() {
    if (_isLoading) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildShimmerItem(),
          childCount: 6,
        ),
      );
    }

    if (_ventasFiltradas.isEmpty) {
      return SliverToBoxAdapter(
        child: VentaWidgets.buildEmptyState(hasVentas: _ventas.isNotEmpty),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildVentaCard(_ventasFiltradas[index]),
          childCount: _ventasFiltradas.length,
        ),
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AppStyles.radiusXLarge,
        ),
        child: Padding(
          padding: AppStyles.paddingMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 60,
                    child: Container(
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 120,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 100,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
        venta['usuario']?['telefono']?.toString() ??
        '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppStyles.radiusXLarge,
        boxShadow: AppStyles.cardShadow,
      ),
      child: InkWell(
        borderRadius: AppStyles.radiusXLarge,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetalleVentaScreen(
                venta: venta,
                nombreUsuario: nombreUsuario,
                onUpdate: _cargarVentas,
                isAdmin: _isAdmin,
                onActualizarEstado: _actualizarEstadoVenta,
                onEliminar: _eliminarVenta,
              ),
            ),
          );
        },
        child: Padding(
          padding: AppStyles.paddingMedium,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(nombreUsuario, style: AppStyles.heading3),
                  ),
                  VentaWidgets.buildEstadoBadge(estado),
                ],
              ),
              const SizedBox(height: 12),
              if (telefono.isNotEmpty)
                VentaWidgets.buildInfoRow(
                  Icons.phone_rounded,
                  telefono,
                  Colors.grey[700]!,
                ),
              if (direccion != 'No disponible')
                VentaWidgets.buildInfoRow(
                  Icons.location_on_rounded,
                  direccion,
                  Colors.grey[700]!,
                ),
              if (codigoPostal.isNotEmpty)
                VentaWidgets.buildInfoRow(
                  Icons.local_post_office_rounded,
                  'C.P. $codigoPostal',
                  Colors.grey[700]!,
                ),
              VentaWidgets.buildInfoRow(
                Icons.access_time_rounded,
                fechaVenta != null
                    ? DateFormat('dd MMM yyyy, HH:mm', 'es').format(fechaVenta)
                    : 'Sin fecha',
                Colors.grey[500]!,
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: AppStyles.radiusSmall,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '${productos.length} producto${productos.length != 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "\$${NumberFormat('#,##0', 'es_CO').format(total)}",
                    style: AppStyles.priceText,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}