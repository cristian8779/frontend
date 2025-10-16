import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/producto_service.dart';
import '../producto/producto_screen.dart';
import '../../theme/producto_por_categoria/producto_por_categoria_theme.dart';
import '../../theme/producto_por_categoria/producto_card_widget.dart';

class ProductosPorCategoriaScreen extends StatefulWidget {
  final String categoriaId;
  final String categoriaNombre;

  const ProductosPorCategoriaScreen({
    Key? key,
    required this.categoriaId,
    required this.categoriaNombre,
  }) : super(key: key);

  @override
  State<ProductosPorCategoriaScreen> createState() =>
      _ProductosPorCategoriaScreenState();
}

class _ProductosPorCategoriaScreenState
    extends State<ProductosPorCategoriaScreen> {
  final ProductoService _productoService = ProductoService();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> productos = [];
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
    _cargarProductos();
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

  Future<void> _cargarProductos() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        _page = 0;
        _hasMore = true;
        productos.clear();
      });

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
        productos = productosObtenidos;
        _hasMore = productos.length < total;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      print('❌ Error al cargar productos: $e');
      setState(() {
        error = e.toString();
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
    await _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ProductoPorCategoriaTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.categoriaNombre,
          style: ProductoPorCategoriaTheme.titleTextStyle,
        ),
        backgroundColor: ProductoPorCategoriaTheme.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: ProductoPorCategoriaTheme.primaryTextColor,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescarLista,
        child: isLoading
            ? _buildShimmerGrid()
            : error != null
                ? _buildErrorState()
                : productos.isEmpty
                    ? _buildEmptyState()
                    : _buildProductsGrid(size),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: ProductoPorCategoriaTheme.gridPaddingInsets,
      gridDelegate: ProductoPorCategoriaTheme.shimmerGridDelegate,
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ProductoPorCategoriaTheme.shimmerBaseColor,
          highlightColor: ProductoPorCategoriaTheme.shimmerHighlightColor,
          child: Container(
            decoration: ProductoPorCategoriaTheme.shimmerDecoration,
          ),
        );
      },
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProductoPorCategoriaTheme.errorIcon,
          ProductoPorCategoriaTheme.errorSpacing,
          Text(
            "Error: $error",
            style: ProductoPorCategoriaTheme.errorTextStyle,
          ),
          ProductoPorCategoriaTheme.errorSpacing,
          ElevatedButton(
            onPressed: _refrescarLista,
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ProductoPorCategoriaTheme.emptyStateIcon,
          ProductoPorCategoriaTheme.emptyStateSpacing,
          const Text(
            "No hay productos disponibles",
            style: ProductoPorCategoriaTheme.emptyStateTextStyle,
          ),
          ProductoPorCategoriaTheme.emptyStateSubtitleSpacing,
          const Text(
            "Esta categoría aún no tiene productos agregados",
            style: ProductoPorCategoriaTheme.emptyStateSubtitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(Size size) {
    return GridView.builder(
      controller: _scrollController,
      padding: ProductoPorCategoriaTheme.gridPaddingInsets,
      gridDelegate: ProductoPorCategoriaTheme.gridDelegate(size),
      itemCount: productos.length + (isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        // 🔹 Mostrar indicador de carga al final
        if (index == productos.length) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.blue[300],
              ),
            ),
          );
        }

        final producto = productos[index];
        return InkWell(
          borderRadius: ProductoPorCategoriaTheme.cardBorderRadiusGeometry,
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
          child: ProductoCardWidget(
            id: producto['_id'] ?? '',
            nombre: producto['nombre'] ?? 'Sin nombre',
            imagenUrl: producto['imagen'] ??
                'https://via.placeholder.com/400x280/f5f5f5/cccccc?text=Sin+Imagen',
            precio: producto['precio'] is double
                ? producto['precio']
                : double.tryParse(producto['precio']?.toString() ?? '0') ?? 0,
          ),
        );
      },
    );
  }
}