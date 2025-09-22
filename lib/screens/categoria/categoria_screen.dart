import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/producto_service.dart';
import '../../services/categoria_service.dart';
import '../producto/producto_screen.dart';

class CategoriaScreen extends StatefulWidget {
  final String categoriaId;

  const CategoriaScreen({
    Key? key,
    required this.categoriaId,
  }) : super(key: key);

  @override
  State<CategoriaScreen> createState() => _CategoriaScreenState();
}

class _CategoriaScreenState extends State<CategoriaScreen> {
  final ProductoService _productoService = ProductoService();
  final CategoriaService _categoriaService = CategoriaService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> productos = [];
  List<Map<String, dynamic>> todosLosProductos = [];
  String categoriaNombre = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  
  // Paginación
  static const int productsPorPagina = 10;
  int paginaActual = 0;
  bool tieneMasProductos = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _cargarMasProductos();
    }
  }

  Future<void> _cargarDatos() async {
    try {
      // Cargar categorías y productos en paralelo
      final futures = await Future.wait([
        _categoriaService.obtenerCategorias(),
        _productoService.obtenerProductos(),
      ]);

      final categorias = futures[0] as List<Map<String, dynamic>>;
      final allProducts = futures[1] as List<Map<String, dynamic>>;

      // Buscar el nombre de la categoría
      final categoria = categorias.firstWhere(
        (cat) => cat['_id']?.toString() == widget.categoriaId,
        orElse: () => {'nombre': 'Categoría ${widget.categoriaId}'},
      );

      // Filtrar productos por categoría
      final filtered = allProducts
          .where((p) => p['categoria']?.toString() == widget.categoriaId)
          .toList();

      setState(() {
        categoriaNombre = categoria['nombre'] ?? 'Categoría ${widget.categoriaId}';
        todosLosProductos = filtered;
        productos = _obtenerProductosPagina(0);
        paginaActual = 0;
        tieneMasProductos = todosLosProductos.length > productsPorPagina;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        categoriaNombre = 'Categoría ${widget.categoriaId}';
        isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _obtenerProductosPagina(int pagina) {
    final inicio = pagina * productsPorPagina;
    final fin = (inicio + productsPorPagina).clamp(0, todosLosProductos.length);
    
    if (inicio >= todosLosProductos.length) return [];
    
    return todosLosProductos.sublist(inicio, fin);
  }

  Future<void> _cargarMasProductos() async {
    if (!tieneMasProductos || isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final siguientePagina = paginaActual + 1;
    final nuevosProductos = _obtenerProductosPagina(siguientePagina);

    setState(() {
      if (nuevosProductos.isNotEmpty) {
        productos.addAll(nuevosProductos);
        paginaActual = siguientePagina;
        tieneMasProductos = (siguientePagina + 1) * productsPorPagina < todosLosProductos.length;
      } else {
        tieneMasProductos = false;
      }
      isLoadingMore = false;
    });
  }

  Future<void> _refrescarLista() async {
    setState(() {
      isLoading = true;
      error = null;
    });
    await _cargarDatos();
  }

  // Formatter mejorado para mostrar el signo peso primero
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0', // Patrón personalizado para mostrar $ primero
  );

  String _formatPrice(double price) {
    return '\$${NumberFormat('#,##0', 'es_CO').format(price)}';
  }

  // Función para obtener el número de columnas basado en el ancho de pantalla
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 4; // Desktop grande
    if (screenWidth >= 800) return 3;  // Tablet horizontal
    if (screenWidth >= 600) return 2;  // Tablet vertical
    return 2; // Móvil
  }

  // Función para obtener el aspect ratio basado en el tamaño de pantalla
  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth >= 1200) return 0.75; // Desktop
    if (screenWidth >= 800) return 0.70;  // Tablet horizontal
    if (screenWidth >= 600) return 0.68;  // Tablet vertical
    return 0.65; // Móvil
  }

  // Función para obtener padding responsive
  EdgeInsets _getResponsivePadding(double screenWidth) {
    if (screenWidth >= 1200) return const EdgeInsets.all(24);
    if (screenWidth >= 800) return const EdgeInsets.all(20);
    if (screenWidth >= 600) return const EdgeInsets.all(18);
    return const EdgeInsets.all(16);
  }

  // Función para obtener spacing responsive
  double _getResponsiveSpacing(double screenWidth) {
    if (screenWidth >= 1200) return 20;
    if (screenWidth >= 800) return 18;
    if (screenWidth >= 600) return 16;
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            categoriaNombre,
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: size.width < 600 ? 18 : 20,
            ),
          ),
        ),
        backgroundColor: const Color(0xFFF8F8F8),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarLista,
        child: isLoading
            ? _buildShimmerGrid()
            : error != null
                ? _buildErrorState()
                : productos.isEmpty
                    ? _buildEmptyState()
                    : _buildProductGrid(),
      ),
    );
  }

  Widget _buildProductGrid() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Grid de productos responsive
        SliverPadding(
          padding: _getResponsivePadding(screenWidth),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(screenWidth),
              mainAxisSpacing: _getResponsiveSpacing(screenWidth),
              crossAxisSpacing: _getResponsiveSpacing(screenWidth),
              childAspectRatio: _getChildAspectRatio(screenWidth),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final producto = productos[index];
                return _ProductoCard(
                  id: producto['_id'] ?? '',
                  nombre: producto['nombre'] ?? 'Sin nombre',
                  imagenUrl: producto['imagen'] ??
                      'https://via.placeholder.com/400x280/f5f5f5/cccccc?text=Sin+Imagen',
                  precio: producto['precio'] is double
                      ? producto['precio']
                      : double.tryParse(producto['precio']?.toString() ?? '0') ?? 0,
                  stock: producto['stock'] ?? 0,
                  disponible: producto['disponible'] ?? true,
                  screenWidth: screenWidth,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductoScreen(
                          productId: producto['_id'],
                        ),
                      ),
                    );
                  },
                );
              },
              childCount: productos.length,
            ),
          ),
        ),
        // Indicador de carga para paginación
        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        // Mensaje de fin de productos
        if (!tieneMasProductos && productos.isNotEmpty)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(screenWidth < 600 ? 16 : 20),
              padding: EdgeInsets.all(screenWidth < 600 ? 12 : 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, 
                       color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Has visto todos los productos',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: screenWidth < 600 ? 14 : 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        // Espaciado inferior
        SliverToBoxAdapter(
          child: SizedBox(height: screenWidth < 600 ? 24 : 32),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid() {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;
    
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: _getResponsivePadding(screenWidth),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(screenWidth),
              mainAxisSpacing: _getResponsiveSpacing(screenWidth),
              crossAxisSpacing: _getResponsiveSpacing(screenWidth),
              childAspectRatio: _getChildAspectRatio(screenWidth),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Shimmer.fromColors(
                  baseColor: Colors.grey[300]!,
                  highlightColor: Colors.grey[100]!,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              childCount: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: isTablet ? 56 : 48,
                color: Colors.redAccent,
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'Error al cargar productos',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              error ?? 'Ocurrió un error desconocido',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isTablet ? 28 : 24),
            ElevatedButton.icon(
              onPressed: _refrescarLista,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 28 : 24,
                  vertical: isTablet ? 16 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isTablet ? 32 : 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: isTablet ? 72 : 64,
                color: Colors.blue[400],
              ),
            ),
            SizedBox(height: isTablet ? 20 : 16),
            Text(
              'No hay productos disponibles',
              style: TextStyle(
                fontSize: isTablet ? 20 : 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              'Esta categoría aún no tiene productos agregados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isTablet ? 16 : 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: isTablet ? 28 : 24),
            TextButton.icon(
              onPressed: _refrescarLista,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 24 : 20,
                  vertical: isTablet ? 12 : 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String imagenUrl;
  final double precio;
  final int stock;
  final bool disponible;
  final double screenWidth;
  final VoidCallback onTap;

  const _ProductoCard({
    Key? key,
    required this.id,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
    required this.stock,
    required this.disponible,
    required this.screenWidth,
    required this.onTap,
  }) : super(key: key);

  // Función para formatear el precio con $ al inicio
  String _formatPrice(double price) {
    return '\$${NumberFormat('#,##0', 'es_CO').format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = screenWidth >= 600;
    final isDesktop = screenWidth >= 1200;
    
    // Tamaños responsive
    final cardPadding = isDesktop ? 16.0 : isTablet ? 14.0 : 12.0;
    final titleFontSize = isDesktop ? 15.0 : isTablet ? 14.0 : 13.0;
    final priceFontSize = isDesktop ? 18.0 : isTablet ? 17.0 : 16.0;
    final stockFontSize = isDesktop ? 11.0 : isTablet ? 10.0 : 9.0;
    final badgeFontSize = isDesktop ? 14.0 : isTablet ? 13.0 : 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Expanded(
                  flex: 7,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: Image.network(
                        imagenUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue[300],
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: isDesktop ? 48 : isTablet ? 44 : 40,
                                color: Colors.grey[400],
                              ),
                              SizedBox(height: isTablet ? 10 : 8),
                              Text(
                                'Sin imagen',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: isTablet ? 14 : 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Información del producto
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w500,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isTablet ? 6 : 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _formatPrice(precio),
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: priceFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Indicador de stock
                            if (stock <= 5 && stock > 0)
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isTablet ? 8 : 6, 
                                  vertical: isTablet ? 3 : 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Últimos $stock',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: stockFontSize,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Badge de sin stock
            if (stock == 0 || !disponible)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      'AGOTADO',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}