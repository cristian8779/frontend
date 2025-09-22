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
import '../../providers/producto_admin_provider.dart'; // Importar ProductoProvider

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

  // Variable para mantener la categoría actualizada
  late Categoria _categoriaActual;

  @override
  void initState() {
    super.initState();
    _categoriaActual = widget.categoria;
    _inicializarProductos();
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

  // NUEVO: Usar ProductoProvider para cargar productos por categoría
  Future<void> _inicializarProductos() async {
    if (!mounted) return;

    final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
    
    // Asegurar que el provider esté inicializado
    if (productoProvider.state == ProductoState.initial) {
      await productoProvider.inicializar();
    }
    
    // Filtrar por esta categoría específica
    productoProvider.filtrarPorCategoria(_categoriaActual.id);
  }

  // Método para actualizar la información de la categoría
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

  // Navegar a editar categoría y esperar resultado
  Future<void> _navegarAEditarCategoria() async {
    try {
      final resultado = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => CategoriaDetalleScreen(categoria: _categoriaActual),
        ),
      );

      // Si se retorna true, significa que la categoría fue actualizada
      if (resultado == true && mounted) {
        await _actualizarInformacionCategoria();
        await _refrescarProductos();
      }
    } catch (e) {
      debugPrint('Error al navegar a editar categoría: $e');
    }
  }

  // NUEVO: Usar ProductoProvider para refrescar
  Future<void> _refrescarProductos() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    final productoProvider = Provider.of<ProductoProvider>(context, listen: false);
    
    // Refrescar productos y aplicar filtro de categoría
    await productoProvider.refrescar();
    productoProvider.filtrarPorCategoria(_categoriaActual.id);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });
    }
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F5F5),
        title: Text(
          _categoriaActual.nombre,
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
        // Mostrar shimmer mientras carga
        if (productoProvider.isLoading && productoProvider.productos.isEmpty) {
          return _buildShimmerGrid();
        }

        // Mostrar error si hay error
        if (productoProvider.hasError) {
          return _errorDisplay(theme, productoProvider.errorMessage);
        }

        // Filtrar productos de esta categoría
        final productosDeCategoria = productoProvider.productosFiltrados.where((producto) {
          final categoriaId = producto['categoria']?.toString();
          return categoriaId == _categoriaActual.id;
        }).toList();

        // Mostrar mensaje vacío si no hay productos
        if (productosDeCategoria.isEmpty && !productoProvider.isLoading) {
          return _emptyDisplay(theme);
        }

        // Mostrar grid de productos
        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: productosDeCategoria.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: (constraints.maxWidth / 200).floor().clamp(2, 4),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemBuilder: (context, index) {
            final productoData = productosDeCategoria[index];
            
            // Obtener el ID correcto del producto
            final productoId = productoData['_id']?.toString() ?? 
                              productoData['id']?.toString() ?? '';

            return ProductoCard(
              id: productoId,
              // Callback para refrescar al eliminar
              onProductoEliminado: () {
                _refrescarProductos();
              },
              // Callback para refrescar al actualizar
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
          Icon(Icons.error_outline,
              size: 80, color: theme.colorScheme.error.withOpacity(0.6)),
          const SizedBox(height: 16),
          Text(
            errorMessage ?? 'Ocurrió un error al cargar los productos.\nReintenta más tarde.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 16),
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