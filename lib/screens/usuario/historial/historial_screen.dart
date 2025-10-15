// screens/historial_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/HistorialService.dart';
import '../../../providers/FavoritoProvider.dart';
import 'package:shimmer/shimmer.dart';
import '../../producto/producto_screen.dart';
// Importaciones de tema
import '../../../theme/historial/historial_theme.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final HistorialService _historialService = HistorialService();
  final NumberFormat _formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  
  Map<String, dynamic> _historial = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritoProvider>().cargarFavoritos();
    });
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _historialService.obtenerHistorial();
      setState(() {
        _historial = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorito(String productoId, String nombreProducto) async {
    try {
      final favoritoProvider = context.read<FavoritoProvider>();
      
      if (favoritoProvider.esFavorito(productoId)) {
        await favoritoProvider.eliminarFavorito(productoId);
      } else {
        await favoritoProvider.agregarFavorito(productoId);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          HistorialWidgets.buildErrorSnackBar('Error: $e'),
        );
      }
    }
  }

  Future<void> _eliminarItem(String id) async {
    try {
      await _historialService.eliminarDelHistorial(id);
      
      // Actualizar el historial localmente sin recargar todo
      setState(() {
        _historial.forEach((fecha, items) {
          (items as List).removeWhere((item) => item['_id'] == id);
        });
        // Eliminar fechas vacías
        _historial.removeWhere((fecha, items) => (items as List).isEmpty);
      });
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          HistorialWidgets.buildSuccessSnackBar('Producto eliminado del historial'),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          HistorialWidgets.buildErrorSnackBar('Error: $e'),
        );
      }
    }
  }

  Future<void> _borrarTodo() async {
    try {
      await _historialService.borrarHistorialCompleto();
      _cargarHistorial();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          HistorialWidgets.buildSuccessSnackBar('Historial borrado completamente', seconds: 3),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          HistorialWidgets.buildErrorSnackBar('Error: $e'),
        );
      }
    }
  }

  void _mostrarDialogoBorrarTodo() {
    showDialog(
      context: context,
      builder: (context) => HistorialWidgets.buildDeleteDialog(context, _borrarTodo),
    );
  }

  void _navegarADetalleProducto(String productoId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductoScreen(productId: productoId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HistorialColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Historial",
          style: HistorialTextStyles.appBarTitle,
        ),
        backgroundColor: HistorialColors.appBarColor,
        elevation: HistorialDimensions.elevationLow,
        iconTheme: const IconThemeData(color: HistorialColors.textPrimary),
        actions: [
          if (!_loading && _historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: HistorialColors.textPrimary),
              tooltip: 'Borrar todo el historial',
              onPressed: _mostrarDialogoBorrarTodo,
            ),
        ],
      ),
      body: _loading
          ? HistorialWidgets.loading
          : _error != null
              ? HistorialWidgets.buildError(_error!, _cargarHistorial)
              : _historial.isEmpty
                  ? HistorialWidgets.emptyState
                  : _buildHistorialContent(),
    );
  }

  Widget _buildHistorialContent() {
    return RefreshIndicator(
      onRefresh: () async {
        await _cargarHistorial();
        await context.read<FavoritoProvider>().cargarFavoritos();
      },
      color: HistorialColors.primaryBlue,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > HistorialDimensions.tabletBreakpoint;
          final crossAxisCount = isTablet ? HistorialDimensions.tabletColumns : HistorialDimensions.mobileColumns;
          
          if (isTablet) {
            return _buildGridView(crossAxisCount);
          } else {
            return _buildListView();
          }
        },
      ),
    );
  }

  Widget _buildGridView(int crossAxisCount) {
    final allItems = <Map<String, dynamic>>[];
    
    _historial.forEach((fecha, items) {
      for (var item in items) {
        if (item['producto'] != null) {
          allItems.add({
            ...item,
            'fecha': fecha,
          });
        }
      }
    });

    return GridView.builder(
      padding: const EdgeInsets.all(HistorialDimensions.paddingMedium),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75, // Ajustado para mejor visualización
        crossAxisSpacing: HistorialDimensions.gridSpacing,
        mainAxisSpacing: HistorialDimensions.gridSpacing,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        return _buildProductCard(allItems[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final entry = _historial.entries.elementAt(index);
        final items = (entry.value as List<dynamic>)
            .where((item) => item['producto'] != null)
            .toList();
        
        if (items.isNotEmpty) {
          return _buildDateSection(entry.key, items);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildDateSection(String fecha, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HistorialWidgets.buildDateHeader(fecha),
        Container(
          color: HistorialColors.cardBackground,
          child: Column(
            children: items.map((item) => _buildProductItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic item) {
    final producto = item['producto'];
    if (producto == null) return const SizedBox.shrink();
    
    final nombre = producto['nombre'] ?? "Producto sin nombre";
    final precio = producto['precio'];
    final imagen = producto['imagen'];
    final fecha = item['fecha'];
    final productoId = producto['_id'];
    final itemId = item['_id'];

    return GestureDetector(
      onTap: () {
        if (productoId != null) {
          _navegarADetalleProducto(productoId);
        }
      },
      child: Card(
        elevation: HistorialDimensions.elevationMedium,
        shape: HistorialDecorations.cardShape,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del producto con aspect ratio
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  _buildProductImage(imagen, true),
                  // Botón de favorito sobre la imagen
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: productoId != null 
                        ? _buildFavoriteIcon(productoId, nombre)
                        : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            ),
            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fecha,
                      style: HistorialTextStyles.dateCard.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        nombre,
                        style: HistorialTextStyles.productNameCard,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (precio != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _formatoPesos.format(precio),
                        style: HistorialTextStyles.productPriceCard,
                      ),
                    ],
                    const SizedBox(height: 8),
                    _buildDeleteButton(() => _eliminarItem(itemId), true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    final producto = item['producto'];
    if (producto == null) return const SizedBox.shrink();
    
    final nombre = producto['nombre'] ?? "Producto sin nombre";
    final precio = producto['precio'];
    final imagen = producto['imagen'];
    final productoId = producto['_id'];
    final itemId = item['_id'];

    return InkWell(
      onTap: () {
        if (productoId != null) {
          _navegarADetalleProducto(productoId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: HistorialDecorations.productBorder,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenedor de imagen mejorado
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildProductImage(imagen, false),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          nombre,
                          style: HistorialTextStyles.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (productoId != null) _buildFavoriteIcon(productoId, nombre),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (precio != null) ...[
                    Text(
                      _formatoPesos.format(precio),
                      style: HistorialTextStyles.productPrice,
                    ),
                    const SizedBox(height: 12),
                  ],
                  _buildDeleteButton(() => _eliminarItem(itemId), false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteIcon(String productoId, String nombre) {
    return Consumer<FavoritoProvider>(
      builder: (context, favoritoProvider, child) {
        final esFavorito = favoritoProvider.esFavorito(productoId);
        return GestureDetector(
          onTap: () => _toggleFavorito(productoId, nombre),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              esFavorito ? Icons.favorite : Icons.favorite_border,
              color: esFavorito
                  ? HistorialColors.favoriteActive
                  : HistorialColors.favoriteInactive,
              size: 24,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String? imagen, bool isCard) {
    if (imagen == null) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.grey.shade200,
        child: Icon(
          Icons.image_not_supported,
          color: HistorialColors.iconPrimary,
          size: isCard ? 48 : 40,
        ),
      );
    }

    return Image.network(
      imagen,
      fit: BoxFit.contain, // Cambiado de cover a contain para mostrar la imagen completa
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade200,
          child: Icon(
            Icons.broken_image,
            color: HistorialColors.iconPrimary,
            size: isCard ? 48 : 40,
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            color: Colors.white,
            width: double.infinity,
            height: double.infinity,
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(VoidCallback onPressed, bool isSmall) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline,
              size: isSmall ? 14 : 16,
              color: HistorialColors.primaryBlue,
            ),
            const SizedBox(width: 4),
            Text(
              "Eliminar",
              style: isSmall 
                ? HistorialTextStyles.buttonSmall 
                : HistorialTextStyles.buttonPrimary,
            ),
          ],
        ),
      ),
    );
  }
}