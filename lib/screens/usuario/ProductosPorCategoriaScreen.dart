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
  List<Map<String, dynamic>> productos = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos() async {
    try {
      final allProducts = await _productoService.obtenerProductos();
      final filtered = allProducts
          .where((p) => p['categoria']?.toString() == widget.categoriaId)
          .toList();

      setState(() {
        productos = filtered;
        isLoading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _refrescarLista() async {
    setState(() {
      isLoading = true;
      error = null;
    });
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
            "",
            style: ProductoPorCategoriaTheme.emptyStateSubtitleTextStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(Size size) {
    return GridView.builder(
      padding: ProductoPorCategoriaTheme.gridPaddingInsets,
      gridDelegate: ProductoPorCategoriaTheme.gridDelegate(size),
      itemCount: productos.length,
      itemBuilder: (context, index) {
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