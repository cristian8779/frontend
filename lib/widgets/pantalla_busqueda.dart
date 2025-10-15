import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/producto_service.dart';
import '../../providers/categoria_provider.dart';
import '../../theme/pantalla_busqueda/colors.dart';
import '../../theme/pantalla_busqueda/dimensions.dart';
import '../../theme/pantalla_busqueda/decorations.dart';
import '../../theme/pantalla_busqueda/text_styles.dart';
import 'buscador.dart';
import '../screens/producto/producto_screen.dart';
import '../screens/usuario/ProductosPorCategoriaScreen.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({Key? key}) : super(key: key);

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> with TickerProviderStateMixin {
  final ProductoService _productoService = ProductoService();
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _resultadosProductos = [];
  List<Map<String, dynamic>> _resultadosCategorias = [];
  bool _cargando = false;
  String _busqueda = "";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _unfocusSearchField();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _unfocusSearchField() {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  void _handleBackPress() {
    _unfocusSearchField();
    Navigator.of(context).pop();
  }

  Future<void> _buscarProductos([String? query]) async {
    if (query != null) {
      setState(() {
        _busqueda = query;
      });
    }

    setState(() {
      _cargando = true;
      _resultadosProductos = [];
      _resultadosCategorias = [];
    });

    try {
      if (_busqueda.isNotEmpty) {
        final productos = await _productoService.buscarProductos(query: _busqueda);
        
        final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
        final categoriasFiltradas = categoriaProvider.categorias.where((categoria) {
          final nombre = categoria['nombre']?.toString().toLowerCase() ?? '';
          return nombre.contains(_busqueda.toLowerCase());
        }).toList();

        setState(() {
          _resultadosProductos = productos;
          _resultadosCategorias = categoriasFiltradas;
        });

        if (_resultadosProductos.isNotEmpty || _resultadosCategorias.isNotEmpty) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString());
      }
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.grey.shade100,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Error al buscar: $message",
                style: BusquedaTextStyles.snackBarText,
              ),
            ),
          ],
        ),
        backgroundColor: BusquedaColors.errorRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.all(BusquedaDimensions.isTablet(context) ? 24 : 16),
      ),
    );
  }

  void _limpiarBusqueda() {
    setState(() {
      _resultadosProductos = [];
      _resultadosCategorias = [];
      _busqueda = "";
      _controller.clear();
    });
    _animationController.reset();
    _unfocusSearchField();
  }

  String _formatearPrecio(dynamic precio) {
    if (precio == null) return "--";

    final numero = int.tryParse(precio.toString());
    if (numero == null) return "--";

    final formatter = NumberFormat("#,##0", "es_ES");
    return "\$${formatter.format(numero)}";
  }

  void _navegarACategoria(Map<String, dynamic> categoria) {
    _unfocusSearchField();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductosPorCategoriaScreen(
          categoriaId: categoria['_id'],
          categoriaNombre: categoria['nombre'] ?? 'Categoría',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneResultados = _resultadosProductos.isNotEmpty || _resultadosCategorias.isNotEmpty;
    final isTablet = BusquedaDimensions.isTablet(context);
    final padding = BusquedaDimensions.getResponsivePadding(context);

    return WillPopScope(
      onWillPop: () async {
        _unfocusSearchField();
        return true;
      },
      child: Scaffold(
        backgroundColor: BusquedaColors.background,
        appBar: _buildAppBar(),
        body: GestureDetector(
          onTap: _unfocusSearchField,
          child: Column(
            children: [
              if (tieneResultados || _busqueda.isNotEmpty)
                _buildHeaderStats(context),

              Expanded(
                child: _cargando
                    ? _buildLoadingState(context)
                    : tieneResultados
                        ? _buildResultsList(context)
                        : _buildEmptyState(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: true,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BusquedaDecorations.backButtonDecoration(),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.grey.shade600,
            size: 20,
          ),
          onPressed: _handleBackPress,
        ),
      ),
      title: BuscadorProductos(
        busqueda: _busqueda,
        controller: _controller,
        onBusquedaChanged: (value) => _buscarProductos(value),
        onClear: _limpiarBusqueda,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          decoration: BoxDecoration(
            gradient: BusquedaDecorations.appBarDividerGradient(),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStats(BuildContext context) {
    final padding = BusquedaDimensions.getResponsivePadding(context);
    final isTablet = BusquedaDimensions.isTablet(context);
    final totalResultados = _resultadosProductos.length + _resultadosCategorias.length;

    return Container(
      margin: EdgeInsets.fromLTRB(
        padding.horizontal,
        BusquedaDimensions.headerTopPadding(context),
        padding.horizontal,
        BusquedaDimensions.headerBottomPadding(context),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BusquedaDecorations.headerStatsDecoration(context),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BusquedaDecorations.sectionIconContainerDecoration(isTablet: isTablet),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.grey.shade600,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados para "$_busqueda"',
                  style: BusquedaTextStyles.headerTitle(context),
                ),
                Text(
                  '$totalResultados resultados encontrados',
                  style: BusquedaTextStyles.headerSubtitle(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isTablet = BusquedaDimensions.isTablet(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BusquedaDecorations.loadingContainerDecoration(isTablet: isTablet),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              strokeWidth: isTablet ? 4 : 3,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            "Buscando...",
            style: BusquedaTextStyles.loadingTitle(context),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            "Un momento por favor",
            style: BusquedaTextStyles.loadingSubtitle(context),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final padding = BusquedaDimensions.getResponsivePadding(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          padding.horizontal,
          8,
          padding.horizontal,
          24,
        ),
        children: [
          if (_resultadosCategorias.isNotEmpty) ...[
            _buildSectionHeader(context, 'Categorías', Icons.category_rounded),
            const SizedBox(height: 12),
            ..._resultadosCategorias.map((categoria) => 
              _buildCategoryCard(context, categoria)).toList(),
          ],
          
          if (_resultadosProductos.isNotEmpty) ...[
            if (_resultadosCategorias.isNotEmpty) const SizedBox(height: 24),
            _buildSectionHeader(context, 'Productos', Icons.shopping_bag_rounded),
            const SizedBox(height: 12),
            ..._resultadosProductos.map((producto) => 
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildProductCard(context, producto),
              )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isTablet = BusquedaDimensions.isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BusquedaDecorations.sectionHeaderDecoration(),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: isTablet ? 22 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Text(
            title,
            style: BusquedaTextStyles.sectionHeader(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> categoria) {
    final isTablet = BusquedaDimensions.isTablet(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BusquedaDecorations.cardDecoration(
        isTablet: isTablet,
        borderColor: BusquedaColors.primaryBlue.withOpacity(0.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navegarACategoria(categoria),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 60 : 50,
                  height: isTablet ? 60 : 50,
                  decoration: BusquedaDecorations.categoryIconDecoration(),
                  child: Icon(
                    Icons.category_rounded,
                    color: BusquedaColors.primaryBlue,
                    size: isTablet ? 30 : 26,
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria['nombre'] ?? "Sin nombre",
                        style: BusquedaTextStyles.categoryName(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 4 : 3,
                        ),
                        decoration: BusquedaDecorations.viewProductsBadgeDecoration(),
                        child: Text(
                          'Ver productos',
                          style: BusquedaTextStyles.categoryBadge(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: BusquedaColors.primaryBlue,
                  size: isTablet ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> producto) {
    final isTablet = BusquedaDimensions.isTablet(context);
    final imageSize = BusquedaDimensions.getProductImageSize(context);
    
    return Container(
      decoration: BusquedaDecorations.cardDecoration(isTablet: isTablet),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navegarAProducto(producto),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                _buildProductImage(context, producto, imageSize, isTablet),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto['nombre'] ?? "Sin nombre",
                        style: BusquedaTextStyles.productName(context),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 8 : 6),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 12 : 10,
                              vertical: isTablet ? 6 : 5,
                            ),
                            decoration: BusquedaDecorations.priceContainerDecoration(context),
                            child: Text(
                              _formatearPrecio(producto['precio']),
                              style: BusquedaTextStyles.productPrice(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BusquedaDecorations.arrowButtonDecoration(),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: BusquedaColors.primaryBlue,
                    size: isTablet ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductImage(
    BuildContext context, 
    Map<String, dynamic> producto, 
    double imageSize, 
    bool isTablet
  ) {
    return Container(
      width: imageSize,
      height: imageSize,
      padding: const EdgeInsets.all(6),
      decoration: BusquedaDecorations.productImageContainerDecoration(),
      child: producto['imagen'] != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                producto['imagen'],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  decoration: BusquedaDecorations.imagePlaceholderDecoration(),
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Colors.grey.shade400,
                    size: isTablet ? 36 : 32,
                  ),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    decoration: BusquedaDecorations.imagePlaceholderDecoration(),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            )
          : Container(
              decoration: BusquedaDecorations.imagePlaceholderDecoration(),
              child: Icon(
                Icons.shopping_bag_rounded,
                color: Colors.grey.shade400,
                size: isTablet ? 36 : 32,
              ),
            ),
    );
  }

  void _navegarAProducto(Map<String, dynamic> producto) {
    _unfocusSearchField();
    
    final productId = producto['_id'];
    if (productId != null && productId.toString().isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProductoScreen(productId: producto['_id']),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Error: Producto sin ID válido",
                  style: BusquedaTextStyles.snackBarText,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: EdgeInsets.all(BusquedaDimensions.isTablet(context) ? 24 : 16),
        ),
      );
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final padding = BusquedaDimensions.getResponsivePadding(context);
    final isTablet = BusquedaDimensions.isTablet(context);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 40 : 32),
              decoration: BusquedaDecorations.emptyStateDecoration(isTablet: isTablet),
              child: Icon(
                _busqueda.isEmpty
                    ? Icons.search_rounded
                    : Icons.search_off_rounded,
                size: isTablet ? 80 : 64,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              _busqueda.isEmpty
                  ? "¡Empieza a buscar!"
                  : "No encontramos nada",
              style: BusquedaTextStyles.emptyStateTitle(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : 300),
              child: Text(
                _busqueda.isEmpty
                    ? "Escribe el nombre del producto o categoría que buscas"
                    : "Intenta con otros términos de búsqueda",
                style: BusquedaTextStyles.emptyStateSubtitle(context),
                textAlign: TextAlign.center,
              ),
            ),
            if (_busqueda.isNotEmpty) ...[
              SizedBox(height: isTablet ? 32 : 24),
              Container(
                decoration: BusquedaDecorations.newSearchButtonDecoration(context),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    onTap: _limpiarBusqueda,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 20,
                        vertical: isTablet ? 16 : 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.autorenew_rounded,
                            size: isTablet ? 24 : 22,
                            color: const Color(0xFF6B7280),
                          ),
                          SizedBox(width: isTablet ? 10 : 8),
                          Text(
                            "Nueva búsqueda",
                            style: BusquedaTextStyles.buttonText(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}