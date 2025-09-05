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
  
  // Variable para mantener la categoría actualizada
  late Categoria _categoriaActual;

  @override
  void initState() {
    super.initState();
    _categoriaActual = widget.categoria; // Inicializar con la categoría original
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
        await categoriaService.obtenerProductosPorCategoria(_categoriaActual.id);
    return productosJson.map((json) => Producto.fromJson(json)).toList();
  }

  // Método para actualizar la información de la categoría
  Future<void> _actualizarInformacionCategoria() async {
    try {
      final categoriaService = CategoriaService();
      final categoriaJson = await categoriaService.obtenerCategoriaPorId(_categoriaActual.id);
      
      debugPrint('Datos obtenidos del servidor: $categoriaJson'); // Para debuggear
      
      if (categoriaJson != null && mounted) {
        final categoriaActualizada = Categoria.fromJson(categoriaJson);
        
        debugPrint('Categoría actualizada - Nombre: ${categoriaActualizada.nombre}, Imagen: ${categoriaActualizada.imagen}'); // Para debuggear
        
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
        debugPrint('La categoría fue actualizada, refrescando datos...'); // Para debuggear
        
        // Actualizar la información de la categoría
        await _actualizarInformacionCategoria();
        
        // También refrescar la lista de productos por si cambió algo
        setState(() {
          _productosFuture = _cargarProductosDeCategoria();
        });
        
        // Mostrar feedback visual
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Categoría "${_categoriaActual.nombre}" actualizada exitosamente'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error al navegar a editar categoría: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Error al actualizar la categoría'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
            _categoriaActual.nombre, // Usar la categoría actualizada
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
                _navegarAEditarCategoria();
              },
            ),
          ],
        ),
          floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            HapticFeedback.selectionClick();
            // Evitar navegaciones múltiples
            if (ModalRoute.of(context)?.isCurrent == true) {
              final productoCreado = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      CrearProductoScreen(categoryId: _categoriaActual.id),
                ),
              );
              
              // Si se creó un producto, refrescar la lista
              if (productoCreado == true && mounted) {
                setState(() {
                  _productosFuture = _cargarProductosDeCategoria();
                });
              }
            }
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
                        tag: 'categoria-${_categoriaActual.id}',
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
                              child: (_categoriaActual.imagen != null &&
                                      _categoriaActual.imagen!.isNotEmpty)
                                  ? CachedNetworkImage(
                                      imageUrl: _categoriaActual.imagen!,
                                      fit: BoxFit.contain,
                                      key: ValueKey(_categoriaActual.imagen), // Forzar reconstrucción si cambia la imagen
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
                        _categoriaActual.nombre, // Usar la categoría actualizada
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                        textAlign: TextAlign.center,
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
                                  // ✅ AGREGADO: Callback para actualizar la lista
                                  onUpdated: () {
                                    setState(() {
                                      _productosFuture = _cargarProductosDeCategoria();
                                    });
                                  },
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