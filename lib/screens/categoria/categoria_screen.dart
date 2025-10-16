import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/producto_service.dart';
import '../../services/categoria_service.dart';
import '../producto/producto_screen.dart';
import '../../theme/categoria/categoria_colors.dart';
import '../../theme/categoria/categoria_dimensions.dart';
import '../../theme/categoria/categoria_text_styles.dart';
import '../../theme/categoria/categoria_widgets_styles.dart';

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
  String categoriaNombre = '';
  bool isLoading = true;
  bool isLoadingMore = false;
  String? error;
  
  // 🔹 Variables para paginación
  int _page = 0;
  final int _limit = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // 🔹 Detectar scroll para cargar más productos
  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent * 0.8) {
      _cargarMasProductos();
    }
  }

  Future<void> _cargarDatos() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        _page = 0;
        _hasMore = true;
        productos.clear();
      });

      // Cargar nombre de categoría
      final categorias = await _categoriaService.obtenerCategorias();
      final categoria = categorias.firstWhere(
        (cat) => cat['_id']?.toString() == widget.categoriaId,
        orElse: () => {'nombre': 'Categoría'},
      );

      // 🔹 Cargar productos CON FILTRO de categoría usando paginación
      final response = await _productoService.obtenerProductosPaginados(
        FiltrosBusqueda(
          page: _page,
          limit: _limit,
          categoria: widget.categoriaId,  // ✅ Filtrar por categoría desde la API
        ),
      );

      final productosObtenidos = List<Map<String, dynamic>>.from(
        response['productos'] ?? []
      );
      final total = response['total'] ?? 0;

      print('✅ Productos obtenidos para categoría ${widget.categoriaId}: ${productosObtenidos.length}');
      print('📊 Total en esta categoría: $total');

      setState(() {
        categoriaNombre = categoria['nombre'] ?? 'Categoría';
        productos = productosObtenidos;
        _hasMore = productos.length < total;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      print('❌ Error al cargar datos: $e');
      setState(() {
        error = e.toString();
        categoriaNombre = 'Categoría';
        isLoading = false;
      });
    }
  }

  // 🔹 Cargar más productos (scroll infinito)
  Future<void> _cargarMasProductos() async {
    if (isLoadingMore || !_hasMore) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      _page++;
      
      final response = await _productoService.obtenerProductosPaginados(
        FiltrosBusqueda(
          page: _page,
          limit: _limit,
          categoria: widget.categoriaId,
        ),
      );

      final nuevosProductos = List<Map<String, dynamic>>.from(
        response['productos'] ?? []
      );
      final total = response['total'] ?? 0;

      print('➡️ Página $_page: ${nuevosProductos.length} productos más');

      setState(() {
        productos.addAll(nuevosProductos);
        _hasMore = productos.length < total;
        isLoadingMore = false;
      });
    } catch (e) {
      print('❌ Error cargando más productos: $e');
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _refrescarLista() async {
    await _cargarDatos();
  }

  String _formatPrice(double price) {
    return '\$${NumberFormat('#,##0', 'es_CO').format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    return Scaffold(
      backgroundColor: CategoriaColors.background,
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            categoriaNombre,
            style: CategoriaTextStyles.getAppBarTitle(screenWidth),
          ),
        ),
        backgroundColor: CategoriaColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: CategoriaColors.primaryText),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarLista,
        child: isLoading
            ? _buildShimmerGrid(screenWidth)
            : error != null
                ? _buildErrorState(screenWidth)
                : productos.isEmpty
                    ? _buildEmptyState(screenWidth)
                    : _buildProductGrid(screenWidth),
      ),
    );
  }

  Widget _buildProductGrid(double screenWidth) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Grid de productos
        SliverPadding(
          padding: CategoriaDimensions.getResponsivePadding(screenWidth),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: CategoriaDimensions.getCrossAxisCount(screenWidth),
              mainAxisSpacing: CategoriaDimensions.getResponsiveSpacing(screenWidth),
              crossAxisSpacing: CategoriaDimensions.getResponsiveSpacing(screenWidth),
              childAspectRatio: CategoriaDimensions.getChildAspectRatio(screenWidth),
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
        
        // 🔹 Indicador de carga de más productos
        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blue[300],
                ),
              ),
            ),
          ),
        
        // Mensaje de fin
        if (productos.isNotEmpty && !_hasMore)
          SliverToBoxAdapter(
            child: Container(
              margin: EdgeInsets.all(CategoriaDimensions.getEndMessagePadding(screenWidth)),
              padding: EdgeInsets.all(CategoriaDimensions.getEndMessageInternalPadding(screenWidth)),
              decoration: CategoriaWidgetStyles.getEndMessageDecoration(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle, 
                    color: CategoriaColors.iconGrey, 
                    size: CategoriaWidgetStyles.getEndMessageIconSize(),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Total: ${productos.length} productos',
                      style: CategoriaTextStyles.getEndMessage(screenWidth),
                    ),
                  ),
                ],
              ),
            ),
          ),
        
        // Espaciado inferior
        SliverToBoxAdapter(
          child: SizedBox(height: CategoriaDimensions.getBottomSpacing(screenWidth)),
        ),
      ],
    );
  }

  Widget _buildShimmerGrid(double screenWidth) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: CategoriaDimensions.getResponsivePadding(screenWidth),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: CategoriaDimensions.getCrossAxisCount(screenWidth),
              mainAxisSpacing: CategoriaDimensions.getResponsiveSpacing(screenWidth),
              crossAxisSpacing: CategoriaDimensions.getResponsiveSpacing(screenWidth),
              childAspectRatio: CategoriaDimensions.getChildAspectRatio(screenWidth),
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Shimmer.fromColors(
                  baseColor: CategoriaColors.shimmerBase,
                  highlightColor: CategoriaColors.shimmerHighlight,
                  child: Container(
                    decoration: BoxDecoration(
                      color: CategoriaColors.cardBackground,
                      borderRadius: BorderRadius.circular(CategoriaDimensions.cardRadius),
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

  Widget _buildErrorState(double screenWidth) {
    final isTablet = CategoriaDimensions.isTablet(screenWidth);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(CategoriaDimensions.getErrorStatePadding(screenWidth)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: CategoriaWidgetStyles.getErrorIconDecoration(isTablet),
              child: Icon(
                Icons.error_outline,
                size: CategoriaWidgetStyles.getErrorIconSize(isTablet),
                color: CategoriaColors.errorColor,
              ),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateIconSpacing(isTablet)),
            Text(
              'Error al cargar productos',
              style: CategoriaTextStyles.getErrorTitle(isTablet),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateDescriptionSpacing(isTablet)),
            Text(
              error ?? 'Ocurrió un error desconocido',
              textAlign: TextAlign.center,
              style: CategoriaTextStyles.getErrorDescription(isTablet),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateButtonSpacing(isTablet)),
            ElevatedButton.icon(
              onPressed: _refrescarLista,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: CategoriaWidgetStyles.getPrimaryButtonStyle(isTablet),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(double screenWidth) {
    final isTablet = CategoriaDimensions.isTablet(screenWidth);
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(CategoriaDimensions.getErrorStatePadding(screenWidth)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 24 : 20),
              decoration: CategoriaWidgetStyles.getEmptyStateIconDecoration(isTablet),
              child: Icon(
                Icons.inventory_2_outlined,
                size: CategoriaWidgetStyles.getEmptyStateIconSize(isTablet),
                color: CategoriaColors.emptyStateIcon,
              ),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateIconSpacing(isTablet)),
            Text(
              'No hay productos disponibles',
              style: CategoriaTextStyles.getEmptyStateTitle(isTablet),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateDescriptionSpacing(isTablet)),
            Text(
              'Esta categoría aún no tiene productos agregados',
              textAlign: TextAlign.center,
              style: CategoriaTextStyles.getEmptyStateDescription(isTablet),
            ),
            SizedBox(height: CategoriaWidgetStyles.getStateButtonSpacing(isTablet)),
            TextButton.icon(
              onPressed: _refrescarLista,
              icon: const Icon(Icons.refresh),
              label: const Text('Actualizar'),
              style: CategoriaWidgetStyles.getSecondaryButtonStyle(isTablet),
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

  String _formatPrice(double price) {
    return '\$${NumberFormat('#,##0', 'es_CO').format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = CategoriaDimensions.isTablet(screenWidth);
    final cardPadding = CategoriaDimensions.getCardPadding(screenWidth);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(CategoriaDimensions.cardRadius),
      child: Container(
        decoration: CategoriaWidgetStyles.getProductCardDecoration(),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(cardPadding),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(CategoriaDimensions.cardRadius),
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
                          decoration: CategoriaWidgetStyles.getImagePlaceholderDecoration(),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported_outlined,
                                size: CategoriaWidgetStyles.getImagePlaceholderIconSize(screenWidth),
                                color: CategoriaColors.iconPlaceholder,
                              ),
                              SizedBox(height: CategoriaWidgetStyles.getImagePlaceholderTextSpacing(isTablet)),
                              Text(
                                'Sin imagen',
                                style: CategoriaTextStyles.getPlaceholderText(isTablet),
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
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.all(cardPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del producto
                        Expanded(
                          flex: 2,
                          child: Text(
                            nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: CategoriaTextStyles.getProductTitle(screenWidth),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Precio y stock
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _formatPrice(precio),
                                style: CategoriaTextStyles.getProductPrice(screenWidth),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (stock <= 5 && stock > 0) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: CategoriaWidgetStyles.getStockWarningPadding(isTablet),
                                decoration: CategoriaWidgetStyles.getStockWarningDecoration(),
                                child: Text(
                                  'Últimos $stock',
                                  style: CategoriaTextStyles.getStockWarning(screenWidth),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
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
                  decoration: CategoriaWidgetStyles.getOutOfStockOverlay(),
                  child: Center(
                    child: Text(
                      'AGOTADO',
                      style: CategoriaTextStyles.getOutOfStockBadge(screenWidth),
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