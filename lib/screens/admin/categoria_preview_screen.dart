import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '/models/producto.dart';
import '/models/categoria.dart';
import 'categoria_detalle_screen.dart';
import 'crear_producto_screen.dart';
import 'package:crud/screens/admin/widgets/producto_card.dart';
import '../../providers/categoria_admin_provider.dart';
import '../../providers/producto_admin_provider.dart';
import 'styles/categoria_preview/categoria_preview_styles.dart';

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
  bool _isRefreshing = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final ScrollController _scrollController = ScrollController();

  late Categoria _categoriaActual;

  @override
  void initState() {
    super.initState();
    _categoriaActual = widget.categoria;
    
    _animationController = AnimationController(
      vsync: this,
      duration: CategoriaPreviewStyles.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: CategoriaPreviewStyles.animationCurve,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarProductos();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _inicializarProductos() async {
    if (!mounted) return;

    final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
    
    try {
      if (productoProvider.state == ProductoState.initial) {
        debugPrint('🔄 Inicializando provider desde categoria preview');
        await productoProvider.inicializar();
      } else {
        debugPrint('🔄 Refrescando productos desde categoria preview');
        await productoProvider.refrescar();
      }
      
      debugPrint('🔍 Filtrando por categoría: ${_categoriaActual.id}');
      productoProvider.filtrarPorCategoria(_categoriaActual.id);
      
    } catch (e) {
      debugPrint('❌ Error al inicializar productos: $e');
      productoProvider.filtrarPorCategoria(_categoriaActual.id);
    }
  }

  Future<void> _actualizarInformacionCategoria() async {
    try {
      final categoriasProvider = Provider.of<CategoriasProvider>(context, listen: false);
      final categoriaActualizada = await categoriasProvider.obtenerCategoriaPorId(_categoriaActual.id);

      if (categoriaActualizada != null && mounted) {
        setState(() {
          _categoriaActual = categoriaActualizada;
        });
      }
    } catch (e) {
      debugPrint('Error al actualizar información de categoría: $e');
    }
  }

  Future<void> _navegarAEditarCategoria() async {
    try {
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriaDetalleScreen(categoria: _categoriaActual),
        ),
      );

      if (resultado == true && mounted) {
        await _actualizarInformacionCategoria();
        await _refrescarProductos();
      }
    } catch (e) {
      debugPrint('Error al navegar a editar categoría: $e');
    }
  }

  Future<void> _refrescarProductos() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
    
    try {
      await productoProvider.refrescar();
      productoProvider.filtrarPorCategoria(_categoriaActual.id);

      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: CategoriaPreviewStyles.scrollAnimationDuration,
          curve: CategoriaPreviewStyles.scrollCurve,
        );
      }
    } catch (e) {
      debugPrint('Error al refrescar productos: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: CategoriaPreviewStyles.gridPadding,
      itemCount: CategoriaPreviewStyles.shimmerItemCount,
      gridDelegate: CategoriaPreviewStyles.shimmerGridDelegate,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: CategoriaPreviewStyles.shimmerBaseColor(),
          highlightColor: CategoriaPreviewStyles.shimmerHighlightColor(),
          child: Container(
            decoration: CategoriaPreviewStyles.containerDecoration(),
            padding: CategoriaPreviewStyles.containerPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: CategoriaPreviewStyles.spacing120,
                  decoration: CategoriaPreviewStyles.shimmerItemDecoration(),
                ),
                const SizedBox(height: CategoriaPreviewStyles.spacing12),
                Container(
                  width: double.infinity,
                  height: CategoriaPreviewStyles.spacing16,
                  decoration: CategoriaPreviewStyles.shimmerBarDecoration(),
                ),
                const SizedBox(height: CategoriaPreviewStyles.spacing8),
                Container(
                  width: CategoriaPreviewStyles.spacing80,
                  height: CategoriaPreviewStyles.spacing16,
                  decoration: CategoriaPreviewStyles.shimmerBarDecoration(),
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: CategoriaPreviewStyles.backgroundColor,
        title: Text(
          _categoriaActual.nombre,
          style: CategoriaPreviewStyles.appBarTitleStyle(),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.edit,
              color: CategoriaPreviewStyles.iconColor,
            ),
            tooltip: 'Editar categoría',
            onPressed: _navegarAEditarCategoria,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          HapticFeedback.selectionClick();
          
          final productoCreado = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (context) => CrearProductoScreen(categoryId: _categoriaActual.id),
            ),
          );

          if (productoCreado == true && mounted) {
            debugPrint('✅ Producto creado, refrescando vista de categoría');
            await _refrescarProductos();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("Agregar"),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refrescarProductos,
                    child: _buildContent(theme, constraints),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, BoxConstraints constraints) {
    return Consumer<ProductoProvider>(
      builder: (context, productoProvider, child) {
        if (productoProvider.isLoading && productoProvider.productos.isEmpty) {
          return _buildShimmerGrid();
        }

        if (productoProvider.hasError) {
          return _errorDisplay(theme, productoProvider.errorMessage);
        }

        final productosDeCategoria = productoProvider.productos.where((producto) {
          final categoriaId = producto['categoria']?.toString();
          final categoriaIdAlt = producto['categoriaId']?.toString();
          
          return categoriaId == _categoriaActual.id || categoriaIdAlt == _categoriaActual.id;
        }).toList();

        debugPrint('📊 Productos en categoría ${_categoriaActual.nombre}: ${productosDeCategoria.length}');
        debugPrint('📊 Total productos en provider: ${productoProvider.productos.length}');

        if (productosDeCategoria.isEmpty && !productoProvider.isLoading) {
          return _emptyDisplay(theme);
        }

        return GridView.builder(
          controller: _scrollController,
          padding: CategoriaPreviewStyles.gridBottomPadding,
          itemCount: productosDeCategoria.length,
          gridDelegate: CategoriaPreviewStyles.gridDelegate(constraints),
          itemBuilder: (context, index) {
            final productoData = productosDeCategoria[index];
            
            final productoId = productoData['_id']?.toString() ?? 
                              productoData['id']?.toString() ?? '';

            return ProductoCard(
              id: productoId,
              producto: productoData,
              onProductoEliminado: () {
                _refrescarProductos();
              },
              onProductoActualizado: () {
                _refrescarProductos();
              },
            );
          },
        );
      },
    );
  }

  Widget _errorDisplay(ThemeData theme, String? errorMessage) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CategoriaPreviewStyles.errorIcon(theme),
          const SizedBox(height: CategoriaPreviewStyles.spacing16),
          Text(
            errorMessage ?? 'Ocurrió un error al cargar los productos.\nReintenta más tarde.',
            textAlign: TextAlign.center,
            style: CategoriaPreviewStyles.errorTextStyle(theme),
          ),
          const SizedBox(height: CategoriaPreviewStyles.spacing16),
          ElevatedButton.icon(
            onPressed: _refrescarProductos,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
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
          CategoriaPreviewStyles.emptyIcon(),
          const SizedBox(height: CategoriaPreviewStyles.spacing16),
          Text(
            'No hay productos registrados en esta categoría.',
            style: CategoriaPreviewStyles.emptyTextStyle(theme),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}