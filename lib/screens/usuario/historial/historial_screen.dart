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
      _cargarHistorial();
      
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
              icon: const Icon(Icons.settings, color: HistorialColors.textPrimary),
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
        childAspectRatio: HistorialDimensions.gridAspectRatio,
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

    return GestureDetector(
      onTap: () {
        if (productoId != null) {
          _navegarADetalleProducto(productoId);
        }
      },
      child: Card(
        elevation: HistorialDimensions.elevationMedium,
        shape: HistorialDecorations.cardShape,
        child: Container(
          padding: const EdgeInsets.all(HistorialDimensions.paddingMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(fecha, style: HistorialTextStyles.dateCard),
                  if (productoId != null) _buildFavoriteIcon(productoId, nombre),
                ],
              ),
              const SizedBox(height: HistorialDimensions.paddingMedium),
              Expanded(child: _buildProductImage(imagen, true)),
              const SizedBox(height: HistorialDimensions.paddingMedium),
              Text(
                nombre,
                style: HistorialTextStyles.productNameCard,
                maxLines: HistorialDimensions.maxLinesCard,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: HistorialDimensions.paddingSmall),
              if (precio != null) ...[
                Text(
                  _formatoPesos.format(precio),
                  style: HistorialTextStyles.productPriceCard,
                ),
                const SizedBox(height: HistorialDimensions.paddingMedium),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: _buildDeleteButton(() => _eliminarItem(item['_id']), true),
              ),
            ],
          ),
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

    return GestureDetector(
      onTap: () {
        if (productoId != null) {
          _navegarADetalleProducto(productoId);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(HistorialDimensions.paddingLarge),
        decoration: HistorialDecorations.productBorder,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: HistorialDimensions.imageSize,
              height: HistorialDimensions.imageSize,
              decoration: HistorialDecorations.imageContainer,
              child: _buildProductImage(imagen, false),
            ),
            const SizedBox(width: HistorialDimensions.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      if (productoId != null) _buildFavoriteIcon(productoId, nombre),
                    ],
                  ),
                  const SizedBox(height: HistorialDimensions.paddingSmall),
                  Text(
                    nombre,
                    style: HistorialTextStyles.productName,
                    maxLines: HistorialDimensions.maxLinesProduct,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: HistorialDimensions.paddingMedium),
                  if (precio != null) ...[
                    Text(
                      _formatoPesos.format(precio),
                      style: HistorialTextStyles.productPrice,
                    ),
                    const SizedBox(height: HistorialDimensions.paddingMedium),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _buildDeleteButton(() => _eliminarItem(item['_id']), false),
                  ),
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
        return GestureDetector(
          onTap: () => _toggleFavorito(productoId, nombre),
          child: Container(
            padding: const EdgeInsets.all(HistorialDimensions.paddingSmall),
            child: Icon(
              favoritoProvider.esFavorito(productoId)
                  ? Icons.favorite
                  : Icons.favorite_border,
              color: favoritoProvider.esFavorito(productoId)
                  ? HistorialColors.favoriteActive
                  : HistorialColors.favoriteInactive,
              size: HistorialDimensions.iconSizeLarge,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProductImage(String? imagen, bool isCard) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        isCard ? HistorialDimensions.borderRadiusSmall : HistorialDimensions.borderRadiusMedium,
      ),
      child: imagen != null
          ? Image.network(
              imagen,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.image_not_supported,
                  color: HistorialColors.iconPrimary,
                  size: HistorialDimensions.iconSizeXLarge,
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
            )
          : Icon(
              Icons.image_not_supported,
              color: HistorialColors.iconPrimary,
              size: HistorialDimensions.iconSizeXLarge,
            ),
    );
  }

  Widget _buildDeleteButton(VoidCallback onPressed, bool isSmall) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: HistorialColors.primaryBlue,
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        "Eliminar",
        style: isSmall ? HistorialTextStyles.buttonSmall : HistorialTextStyles.buttonPrimary,
      ),
    );
  }
}