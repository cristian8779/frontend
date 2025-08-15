import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '/models/producto.dart';
import '/models/categoria.dart';
import 'categoria_detalle_screen.dart';
import 'crear_producto_screen.dart';
import 'package:crud/screens/admin/widgets/producto_card.dart';
import '../../services/categoria_service.dart';

class CategoriaPreviewScreen extends StatefulWidget {
  final Categoria categoria;

  const CategoriaPreviewScreen({
    super.key,
    required this.categoria,
  });

  @override
  State<CategoriaPreviewScreen> createState() => _CategoriaPreviewScreenState();
}

class _CategoriaPreviewScreenState extends State<CategoriaPreviewScreen>
    with SingleTickerProviderStateMixin {
  late Future<List<Producto>> _productosFuture;
  bool _isRefreshing = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _productosFuture = _cargarProductosDeCategoria();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<Producto>> _cargarProductosDeCategoria() async {
    final categoriaService = CategoriaService();
    final productosJson =
        await categoriaService.obtenerProductosPorCategoria(widget.categoria.id);
    return productosJson.map((json) => Producto.fromJson(json)).toList();
  }

 Future<void> _refrescarProductos() async {
  if (_isRefreshing) return;
  setState(() {
    _isRefreshing = true;
    _productosFuture = _cargarProductosDeCategoria();
  });
  await _productosFuture;

  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  setState(() {
    _isRefreshing = false;
  });
}


  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoria = widget.categoria;
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('¿Salir de la categoría?'),
            content: const Text('¿Estás seguro de que deseas volver?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Salir'),
              ),
            ],
          ),
        );
        return shouldPop ?? false;
      },
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFF5F5F5),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF5F5F5), Color(0xFFEDEDED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Volver',
            onLongPress: () => HapticFeedback.lightImpact(),
          ),
          title: Text(
            categoria.nombre,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              tooltip: 'Editar categoría',
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CategoriaDetalleScreen(categoria: categoria),
                  ),
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CrearProductoScreen(categoryId: categoria.id),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text("Agregar"),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = constraints.maxWidth * 0.35;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Hero(
                        tag: 'categoria-${categoria.id}',
                        child: ScaleTransition(
                          scale: _fadeAnimation,
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              height: imageSize.clamp(120, 160),
                              width: imageSize.clamp(120, 160),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: (categoria.imagen != null &&
                                      categoria.imagen!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: categoria.imagen!,
                                      fit: BoxFit.contain,
                                      placeholder: (context, url) =>
                                          Shimmer.fromColors(
                                        baseColor: Colors.grey.shade200,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade300,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.broken_image,
                                              size: 60,
                                              color: Colors.grey.shade400),
                                    )
                                  : Icon(Icons.image_not_supported,
                                      size: 60, color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        categoria.nombre,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Productos Registrados',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _refrescarProductos,
                        child: FutureBuilder<List<Producto>>(
                          future: _productosFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildShimmerGrid();
                            }

                            if (snapshot.hasError) {
                              return _errorDisplay(theme);
                            }

                            final productos = snapshot.data ?? [];
                            if (productos.isEmpty) {
                              return _emptyDisplay(theme);
                            }

                            return GridView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.only(bottom: 80),
                              itemCount: productos.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    (constraints.maxWidth / 200).floor().clamp(2, 4),
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 0.75,
                              ),
                              itemBuilder: (context, index) {
                                final producto = productos[index];
                                return ProductoCard(
                                  id: producto.id,
                                  nombre: producto.nombre,
                                  imagenUrl: producto.imagenUrl.isNotEmpty
                                      ? producto.imagenUrl
                                      : 'https://via.placeholder.com/150',
                                  precio: producto.precio,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _errorDisplay(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline,
              size: 80, color: theme.colorScheme.error.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            'Ocurrió un error al cargar los productos.\nReintenta más tarde.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _refrescarProductos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyDisplay(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined,
              size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No hay productos registrados en esta categoría.',
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
