import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shimmer/shimmer.dart';
import 'package:crud/screens/admin/widgets/producto_card.dart';
import '../../services/producto_service.dart';
import '../../services/categoria_service.dart';
import 'crear_producto_screen.dart';
import 'gestionar_variaciones_screen.dart';
import 'dart:io';

enum ConnectionState { online, offline, serverError, loading }

class BuscadorProductos extends StatefulWidget {
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final VoidCallback onClear;

  const BuscadorProductos({
    Key? key,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  State<BuscadorProductos> createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<BuscadorProductos>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.busqueda);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(_focusNode.hasFocus ? 0.15 : 0.08),
                  blurRadius: _focusNode.hasFocus ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: _focusNode.hasFocus 
                  ? Colors.blue.withOpacity(0.5) 
                  : Colors.transparent,
                width: 2,
              ),
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onBusquedaChanged,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: _focusNode.hasFocus ? Colors.blue : Colors.grey[600],
                  size: 24,
                ),
                hintText: 'Buscar productos...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: InputBorder.none,
                suffixIcon: widget.busqueda.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          widget.onClear();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GestionProductosScreen extends StatefulWidget {
  const GestionProductosScreen({super.key});

  @override
  _GestionProductosScreenState createState() => _GestionProductosScreenState();
}

class _GestionProductosScreenState extends State<GestionProductosScreen>
    with TickerProviderStateMixin {
  final ProductoService productoService = ProductoService();
  final CategoriaService categoriaService = CategoriaService();
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late AnimationController _staggeredAnimationController;

  List<dynamic> productos = [];
  List<dynamic> productosFiltrados = [];
  List<Map<String, dynamic>> categorias = [];
  String? categoriaSeleccionada;
  String busqueda = '';
  bool isLoading = true;
  String _sortBy = 'nombre';
  bool _sortAscending = true;
  ConnectionState _connectionState = ConnectionState.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _staggeredAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _staggeredAnimationController.forward();
    _cargarDatos();
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _listAnimationController.dispose();
    _staggeredAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _cargarDatos() async {
    setState(() {
      isLoading = true;
      _connectionState = ConnectionState.loading;
      _errorMessage = null;
    });

    try {
      // Verificar conexión a internet
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        setState(() {
          _connectionState = ConnectionState.offline;
          isLoading = false;
        });
        return;
      }

      // Simular un delay mínimo para mejor experiencia visual
      await Future.delayed(const Duration(milliseconds: 800));
      
      categorias = await categoriaService.obtenerCategorias();
      final data = await productoService.obtenerProductos();
      
      if (data is List) {
        productos = data;
        productosFiltrados = List.from(productos);
        _aplicarOrdenamiento();
        setState(() {
          _connectionState = ConnectionState.online;
        });
      } else {
        throw Exception('Formato de datos inválido');
      }
    } on SocketException catch (_) {
      setState(() {
        _connectionState = ConnectionState.offline;
        _errorMessage = 'Sin conexión a internet';
      });
    } on HttpException catch (e) {
      setState(() {
        _connectionState = ConnectionState.serverError;
        _errorMessage = 'Error del servidor: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _connectionState = ConnectionState.serverError;
        _errorMessage = _getErrorMessage(e.toString());
      });
      
      if (mounted) {
        _mostrarSnackBar(
          _errorMessage ?? 'Error desconocido',
          Colors.red,
          Icons.error_outline,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
        if (_connectionState == ConnectionState.online) {
          _fadeAnimationController.forward();
          _listAnimationController.forward();
        }
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('timeout')) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    } else if (error.toLowerCase().contains('host lookup failed')) {
      return 'No se puede conectar al servidor. Verifica tu conexión.';
    } else if (error.toLowerCase().contains('server')) {
      return 'El servidor no está disponible en este momento.';
    } else if (error.toLowerCase().contains('404')) {
      return 'Recurso no encontrado en el servidor.';
    } else if (error.toLowerCase().contains('500')) {
      return 'Error interno del servidor. Intenta más tarde.';
    } else {
      return 'Ocurrió un error inesperado. Intenta nuevamente.';
    }
  }

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: color == Colors.red ? SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarDatos,
        ) : null,
      ),
    );
  }

  void _filtrar() {
    setState(() {
      productosFiltrados = productos.where((prod) {
        final coincideBusqueda = busqueda.isEmpty || 
            prod['nombre']?.toString().toLowerCase().contains(busqueda.toLowerCase()) == true ||
            prod['descripcion']?.toString().toLowerCase().contains(busqueda.toLowerCase()) == true;
        
        final coincideCategoria = categoriaSeleccionada == null || 
            prod['categoria'] == categoriaSeleccionada;
        
        return coincideBusqueda && coincideCategoria;
      }).toList();
      
      _aplicarOrdenamiento();
    });
  }

  void _aplicarOrdenamiento() {
    productosFiltrados.sort((a, b) {
      int comparison;
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
          comparison = (a['nombre']?.toString() ?? '').toLowerCase()
              .compareTo((b['nombre']?.toString() ?? '').toLowerCase());
      }
      return _sortAscending ? comparison : -comparison;
    });
  }

  void _limpiarFiltros() {
    setState(() {
      categoriaSeleccionada = null;
      busqueda = '';
      _filtrar();
    });
  }

  Widget _buildShimmerElement({required Widget child, required int delay}) {
    return AnimatedBuilder(
      animation: _staggeredAnimationController,
      builder: (context, _) {
        final animationProgress = _staggeredAnimationController.value;
        final normalizedDelay = delay * 0.1;
        final adjustedProgress = ((animationProgress - normalizedDelay) / (1.0 - normalizedDelay))
            .clamp(0.0, 1.0);
        
        if (adjustedProgress <= 0) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: child,
          );
        }
        
        final opacity = Curves.easeOut.transform(adjustedProgress);
        final scale = 0.95 + (0.05 * Curves.easeOutBack.transform(adjustedProgress));
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildShimmerSearchBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerStatsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 180,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerProductGrid() {
    return SizedBox(
      height: 600,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        padding: const EdgeInsets.symmetric(vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          return _buildShimmerElement(
            delay: 6 + index,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionErrorState() {
    IconData icon;
    Color color;
    String title;
    String message;
    String actionText = 'Reintentar';

    switch (_connectionState) {
      case ConnectionState.offline:
        icon = Icons.wifi_off_rounded;
        color = Colors.orange;
        title = 'Sin conexión a internet';
        message = 'Verifica tu conexión WiFi o datos móviles y vuelve a intentar.';
        break;
      case ConnectionState.serverError:
        icon = Icons.cloud_off_rounded;
        color = Colors.red;
        title = 'Error del servidor';
        message = _errorMessage ?? 'El servidor no está disponible. Intenta más tarde.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      height: 500,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 64,
              color: color,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
              if (_connectionState == ConnectionState.offline) ...[
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    _mostrarSnackBar(
                      'Ve a Configuración > WiFi o Datos móviles',
                      Colors.blue,
                      Icons.info_outline,
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Ayuda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosYOrdenamiento() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_alt_outlined, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Filtros y ordenamiento',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: categoriaSeleccionada,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Categoría',
                    prefixIcon: const Icon(Icons.category_outlined, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todas las categorías'),
                    ),
                    ...categorias.map((categoria) => DropdownMenuItem<String>(
                      value: categoria['_id'],
                      child: Text(
                        categoria['nombre'] ?? 'Sin nombre',
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      categoriaSeleccionada = value;
                      _filtrar();
                    });
                  },
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  value: _sortBy,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Ordenar por',
                    prefixIcon: const Icon(Icons.sort, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                    DropdownMenuItem(value: 'precio', child: Text('Precio')),
                    DropdownMenuItem(value: 'fecha', child: Text('Fecha')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _sortBy = value!;
                      _aplicarOrdenamiento();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      _aplicarOrdenamiento();
                    });
                  },
                  icon: Icon(
                    _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                    color: Colors.blue,
                    size: 20,
                  ),
                  tooltip: _sortAscending ? 'Ascendente' : 'Descendente',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEstadisticasHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CrearProductoScreen(),
                  ),
                );
                if (result == true) {
                  _cargarDatos();
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_box_outlined,
                        color: Colors.blue,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Agregar Producto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.green[700],
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${productosFiltrados.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const Text(
                    'Productos',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.category_outlined,
                      color: Colors.orange[700],
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${categorias.length}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Text(
                    'Categorías',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  busqueda.isNotEmpty ? Icons.search_off : Icons.inventory_2_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                busqueda.isNotEmpty || categoriaSeleccionada != null
                  ? 'No encontramos productos'
                  : 'No hay productos registrados',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                busqueda.isNotEmpty || categoriaSeleccionada != null
                  ? 'Intenta con otros filtros o términos de búsqueda.'
                  : 'Comienza agregando tu primer producto.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              if (busqueda.isEmpty && categoriaSeleccionada == null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearProductoScreen(),
                      ),
                    );
                    if (result == true) {
                      _cargarDatos();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final itemCount = productosFiltrados.length;
    final rows = (itemCount / 2).ceil();
    final height = rows * 280.0 + (rows - 1) * 16.0 + 16.0;
    
    return SizedBox(
      height: height,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(vertical: 8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemBuilder: (context, index) {
          final producto = productosFiltrados[index];
          return AnimatedBuilder(
            animation: _listAnimationController,
            builder: (context, child) {
              final animationProgress = _listAnimationController.value;
              final itemDelay = (index * 0.1).clamp(0.0, 0.8);
              final animationValue = ((animationProgress - itemDelay) / (1.0 - itemDelay))
                  .clamp(0.0, 1.0);
              
              final curvedValue = Curves.easeOutBack.transform(animationValue);
              final opacity = curvedValue.clamp(0.0, 1.0);
              final scale = (0.5 + (curvedValue * 0.5)).clamp(0.0, 1.0);
              
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: ProductoCard(
                    id: producto['_id'] ?? '',
                    nombre: producto['nombre']?.toString() ?? 'Sin nombre',
                    imagenUrl: producto['imagen'] == null ||
                            (producto['imagen'] as String).isEmpty
                        ? 'https://via.placeholder.com/150'
                        : producto['imagen'].toString(),
                    precio: (producto['precio'] as num?)?.toDouble() ?? 0.0,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_connectionState == ConnectionState.online) return const SizedBox.shrink();
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_connectionState) {
      case ConnectionState.offline:
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_off;
        statusText = 'Sin conexión';
        break;
      case ConnectionState.serverError:
        statusColor = Colors.red;
        statusIcon = Icons.cloud_off;
        statusText = 'Error del servidor';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor.withOpacity(0.8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _cargarDatos,
            child: Text(
              'Reintentar',
              style: TextStyle(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Gestión de Productos',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.blue[50]!,
                        Colors.white,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de estado de conexión
                    _buildConnectionStatus(),
                    
                    // Manejo de errores de conexión
                    if (_connectionState == ConnectionState.offline ||
                        _connectionState == ConnectionState.serverError)
                      _buildConnectionErrorState()
                    else ...[
                      // Buscador con shimmer
                      if (isLoading)
                        _buildShimmerElement(
                          delay: 0,
                          child: _buildShimmerSearchBar(),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: BuscadorProductos(
                            busqueda: busqueda,
                            onBusquedaChanged: (value) {
                              setState(() {
                                busqueda = value;
                                _filtrar();
                              });
                            },
                            onClear: () {
                              setState(() {
                                busqueda = '';
                                _filtrar();
                              });
                            },
                          ),
                        ),
                      const SizedBox(height: 24),
                      
                      // Estadísticas con shimmer
                      if (isLoading)
                        _buildShimmerElement(
                          delay: 1,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(child: _buildShimmerStatsCard()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildShimmerStatsCard()),
                                const SizedBox(width: 16),
                                Expanded(child: _buildShimmerStatsCard()),
                              ],
                            ),
                          ),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildEstadisticasHeader(),
                        ),
                      const SizedBox(height: 24),
                      
                      // Filtros con shimmer
                      if (isLoading)
                        _buildShimmerElement(
                          delay: 2,
                          child: _buildShimmerFilters(),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildFiltrosYOrdenamiento(),
                        ),
                      const SizedBox(height: 24),
                      
                      // Header de productos con shimmer
                      if (isLoading)
                        _buildShimmerElement(
                          delay: 3,
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                width: 200,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                width: 80,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Row(
                            children: [
                              const Icon(Icons.inventory, color: Colors.blue, size: 24),
                              const SizedBox(width: 8),
                              const Text(
                                'Productos Registrados',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (productosFiltrados.isNotEmpty) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${productosFiltrados.length} resultado${productosFiltrados.length != 1 ? 's' : ''}',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      
                      // Grid de productos o estados de carga/vacío
                      if (isLoading)
                        _buildShimmerProductGrid()
                      else if (productosFiltrados.isEmpty)
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildEmptyState(),
                        )
                      else
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: _buildProductGrid(),
                        ),
                      
                      const SizedBox(height: 32),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}