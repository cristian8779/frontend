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

  // Función para formatear el precio con $ al inicio
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
        // Grid de productos responsive
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
        // Indicador de carga para paginación
        if (isLoadingMore)
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(CategoriaDimensions.getLoadingIndicatorPadding(screenWidth)),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),
        // Mensaje de fin de productos
        if (!tieneMasProductos && productos.isNotEmpty)
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
                      'Has visto todos los productos',
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

  // Función para formatear el precio con $ al inicio
  String _formatPrice(double price) {
    return '\$${NumberFormat('#,##0', 'es_CO').format(price)}';
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = CategoriaDimensions.isTablet(screenWidth);
    final isDesktop = CategoriaDimensions.isDesktop(screenWidth);
    
    // Obtener padding de la card
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
                  flex: 7,
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
                // Información del producto - AQUÍ ESTÁ LA CORRECCIÓN
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
                          style: CategoriaTextStyles.getProductTitle(screenWidth),
                        ),
                        const Spacer(), // CAMBIO: Spacer en lugar de SizedBox fijo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                _formatPrice(precio),
                                style: CategoriaTextStyles.getProductPrice(screenWidth),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Indicador de stock
                            if (stock <= 5 && stock > 0)
                              Container(
                                padding: CategoriaWidgetStyles.getStockWarningPadding(isTablet),
                                decoration: CategoriaWidgetStyles.getStockWarningDecoration(),
                                child: Text(
                                  'Últimos $stock',
                                  style: CategoriaTextStyles.getStockWarning(screenWidth),
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