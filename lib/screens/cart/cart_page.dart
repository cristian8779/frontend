import '../../services/carrito_service.dart';
import '../../providers/auth_provider.dart';
import '../../theme/cart/cart_page_styles.dart';
import '../bold_payment_page.dart';
import '../producto/producto_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CartPage extends StatefulWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CarritoService _carritoService = CarritoService();
  List<dynamic> items = [];
  bool isLoading = true;
  bool isRefreshing = false;
  double totalPrice = 0.0;
  int totalItems = 0;

  // Formatear números con formato colombiano
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\$#,##0',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAutenticacionYCargar();
    });
  }

  Future<void> _verificarAutenticacionYCargar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    await _cargarCarrito(authProvider);
  }

  Future<void> _cargarCarrito(AuthProvider authProvider, {bool isRefresh = false}) async {
    setState(() {
      if (isRefresh) {
        isRefreshing = true;
      } else {
        isLoading = true;
      }
    });

    try {
      final token = authProvider.token;
      if (token == null || token.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }

      print('🛒 Cargando carrito con token...');
      final carritoData = await _carritoService.obtenerCarrito(token);
      
      print('📦 Datos recibidos del carrito: $carritoData');
      
      if (carritoData != null) {
        final itemsData = carritoData['items'] ?? [];
        print('📋 Items en el carrito: ${itemsData.length}');
        
        setState(() {
          items = itemsData;
          _recalcularTotales();
          isLoading = false;
          isRefreshing = false;
        });

        if (isRefresh) {
          ScaffoldMessenger.of(context).showSnackBar(
            CartPageStyles.buildSuccessSnackBar('Carrito actualizado'),
          );
        }
      } else {
        print('⚠️ CarritoData es null');
        setState(() {
          items = [];
          totalPrice = 0.0;
          totalItems = 0;
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      print('❌ Error al cargar carrito: $e');
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }
      setState(() {
        items = [];
        totalPrice = 0.0;
        totalItems = 0;
        isLoading = false;
        isRefreshing = false;
      });
      
      if (isRefresh) {
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildErrorSnackBar('Error al actualizar carrito'),
        );
      }
    }
  }

  void _recalcularTotales() {
    double total = 0.0;
    int itemCount = 0;

    for (var item in items) {
      final cantidad = item['cantidad'] ?? item['quantity'] ?? 1;
      final precioUnitario =
          (item['precioUnitario'] ?? item['unitPrice'] ?? 0.0).toDouble();

      total += precioUnitario * cantidad;
      itemCount += cantidad as int;
    }

    totalPrice = total;
    totalItems = itemCount;
  }

  String _getItemUniqueId(dynamic item) {
    final productoId = item['productoId'] ?? item['id'] ?? '';
    final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
    
    if (variacionId.isNotEmpty) {
      return '${productoId}_${variacionId}';
    }
    return productoId;
  }

  Future<void> _actualizarCantidadLocal(
      String productoId, int nuevaCantidad, {String? variacionId}) async {
    if (productoId.isEmpty) {
      print('❌ Error: productoId está vacío');
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('Error: ID de producto inválido'),
      );
      return;
    }

    if (nuevaCantidad <= 0) {
      await _eliminarProducto(productoId, variacionId: variacionId);
      return;
    }

    setState(() {
      for (int i = 0; i < items.length; i++) {
        final itemId = items[i]['productoId'] ?? items[i]['id'] ?? '';
        final itemVariacionId = items[i]['variacionId'] ?? items[i]['variation_id'] ?? '';
        
        bool esElMismoItem = itemId == productoId;
        if (variacionId != null && variacionId.isNotEmpty) {
          esElMismoItem = esElMismoItem && (itemVariacionId == variacionId);
        } else {
          esElMismoItem = esElMismoItem && (itemVariacionId.isEmpty);
        }
        
        if (esElMismoItem) {
          items[i]['cantidad'] = nuevaCantidad;
          items[i]['quantity'] = nuevaCantidad;

          final precioUnitario = (items[i]['precioUnitario'] ??
                  items[i]['unitPrice'] ??
                  0.0)
              .toDouble();
          items[i]['precio'] = precioUnitario * nuevaCantidad;
          items[i]['price'] = precioUnitario * nuevaCantidad;
          
          break;
        }
      }
      _recalcularTotales();
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      final success = await _carritoService.actualizarCantidadConVariacion(
        token, 
        productoId, 
        nuevaCantidad,
        variacionId: variacionId,
      );

      if (!success) {
        await _cargarCarrito(authProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildErrorSnackBar('Error al actualizar cantidad'),
        );
      }
    } catch (e) {
      await _cargarCarrito(authProvider);
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('Error al actualizar: ${e.toString()}'),
      );
    }
  }

  Future<void> _eliminarProducto(String productoId, {String? variacionId}) async {
    if (productoId.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    final bool? confirmacion = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return CartPageStyles.buildDeleteConfirmationDialog(
          context: context,
          onConfirm: () => Navigator.of(context).pop(true),
        );
      },
    );

    if (confirmacion != true) return;

    try {
      final success = await _carritoService.eliminarProductoConVariacion(
        token, 
        productoId,
        variacionId: variacionId,
      );
      
      if (success) {
        await _cargarCarrito(authProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildSuccessSnackBar('Producto eliminado del carrito'),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildErrorSnackBar('Error al eliminar producto'),
        );
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('Error al eliminar: ${e.toString()}'),
      );
    }
  }

  void _navegarADetalleProducto(String productoId) {
    if (productoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('Error: ID de producto inválido'),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductoScreen(productId: productoId),
      ),
    );
  }

  void _navegarAPago(AuthProvider authProvider) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildWarningSnackBar('Tu carrito está vacío'),
      );
      return;
    }

    final userId = authProvider.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('No se encontró el usuario'),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoldPaymentPage(
          totalPrice: totalPrice,
          totalItems: totalItems,
        ),
      ),
    );
  }

  Widget _buildShimmerItem(Map<String, dynamic> responsive) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive['horizontalPadding'],
        vertical: 4,
      ),
      decoration: CartPageStyles.cartItemDecoration,
      child: Padding(
        padding: EdgeInsets.all(responsive['cardPadding']),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer para imagen
            Shimmer.fromColors(
              baseColor: CartPageStyles.shimmerBaseColor,
              highlightColor: CartPageStyles.shimmerHighlightColor,
              child: CartPageStyles.buildShimmerContainer(
                width: responsive['itemImageSize'],
                height: responsive['itemImageSize'],
                borderRadius: 8,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Shimmer para información
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Shimmer.fromColors(
                    baseColor: CartPageStyles.shimmerBaseColor,
                    highlightColor: CartPageStyles.shimmerHighlightColor,
                    child: CartPageStyles.buildShimmerContainer(
                      width: double.infinity,
                      height: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Shimmer.fromColors(
                    baseColor: CartPageStyles.shimmerBaseColor,
                    highlightColor: CartPageStyles.shimmerHighlightColor,
                    child: CartPageStyles.buildShimmerContainer(
                      width: 100,
                      height: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Shimmer.fromColors(
                    baseColor: CartPageStyles.shimmerBaseColor,
                    highlightColor: CartPageStyles.shimmerHighlightColor,
                    child: CartPageStyles.buildShimmerContainer(
                      width: 120,
                      height: 32,
                      borderRadius: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = CartPageStyles.getResponsiveDimensions(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.cargando) {
          return Scaffold(
            body: Center(child: CartPageStyles.loadingIndicator),
          );
        }

        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return Scaffold(
            body: Center(child: CartPageStyles.loadingIndicator),
          );
        }

        return Scaffold(
          backgroundColor: CartPageStyles.backgroundColor,
          appBar: CartPageStyles.buildAppBar(
            context: context,
            onBack: () => Navigator.pop(context),
            totalItems: totalItems,
          ),
          body: _buildCartView(authProvider, responsive),
        );
      },
    );
  }

  Widget _buildCartView(AuthProvider authProvider, Map<String, dynamic> responsive) {
    if (isLoading) {
      return Column(
        children: [
          // Shimmer items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: 3,
              itemBuilder: (context, index) => _buildShimmerItem(responsive),
            ),
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _cargarCarrito(authProvider, isRefresh: true),
        color: CartPageStyles.primaryBlue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CartPageStyles.buildEmptyCartIcon(),
                  const SizedBox(height: 24),
                  Text(
                    'Tu carrito está vacío',
                    style: CartPageStyles.emptyCartTitleStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Descubre miles de productos',
                    style: CartPageStyles.emptyCartSubtitleStyle,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: CartPageStyles.discoverButtonStyle,
                    child: const Text(
                      'Descubrir productos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        // Lista de productos con RefreshIndicator
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _cargarCarrito(authProvider, isRefresh: true),
            color: CartPageStyles.primaryBlue,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildCarritoItem(item, index, responsive);
              },
            ),
          ),
        ),

        // Panel de resumen y pago
        Container(
          decoration: CartPageStyles.paymentPanelDecoration,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Resumen del total
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: CartPageStyles.summaryContainerDecoration,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total ($totalItems producto${totalItems != 1 ? 's' : ''})',
                              style: CartPageStyles.totalLabelStyle,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _currencyFormat.format(totalPrice),
                              style: CartPageStyles.totalPriceStyle,
                            ),
                          ],
                        ),
                        CartPageStyles.buildShippingIcon(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botón de continuar compra
                  SizedBox(
                    width: double.infinity,
                    height: responsive['buttonHeight'],
                    child: ElevatedButton(
                      onPressed: () => _navegarAPago(authProvider),
                      style: CartPageStyles.primaryButtonStyle,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Continuar compra',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          CartPageStyles.buildArrowIcon(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarritoItem(dynamic item, int index, Map<String, dynamic> responsive) {
    final nombre = item['nombre'] ?? item['name'] ?? 'Producto';
    final precio = (item['precio'] ?? item['price'] ?? 0.0).toDouble();
    final cantidad = item['cantidad'] ?? item['quantity'] ?? 1;
    final precioUnitario = (item['precioUnitario'] ?? item['unitPrice'] ?? 0.0).toDouble();
    final productoId = item['productoId'] ?? item['id'] ?? '';
    final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
    final imagenUrl = item['imagen'] ?? item['image'] ?? '';
    
    // Información de variación
    final variacionNombre = item['variacionNombre'] ?? item['variation_name'] ?? '';
    final variacionValor = item['variacionValor'] ?? item['variation_value'] ?? '';
    final talla = item['talla'] ?? item['size'] ?? '';
    final color = item['color'] ?? '';
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: responsive['horizontalPadding']),
      decoration: CartPageStyles.cartItemDecoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navegarADetalleProducto(productoId),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(responsive['cardPadding']),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del producto
                Container(
                  width: responsive['itemImageSize'],
                  height: responsive['itemImageSize'],
                  decoration: CartPageStyles.buildImageDecoration(),
                  child: imagenUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imagenUrl,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return Shimmer.fromColors(
                                baseColor: CartPageStyles.shimmerBaseColor,
                                highlightColor: CartPageStyles.shimmerHighlightColor,
                                child: Container(color: Colors.white),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return CartPageStyles.buildImageErrorIcon();
                            },
                          ),
                        )
                      : CartPageStyles.buildImagePlaceholderIcon(),
                ),
                
                const SizedBox(width: 12),
                
                // Información del producto
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nombre,
                        style: CartPageStyles.productNameStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      // Mostrar variaciones si existen
                      if (talla.isNotEmpty || color.isNotEmpty || variacionNombre.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (talla.isNotEmpty)
                              CartPageStyles.buildVariationChip('Talla: $talla', Colors.purple),
                            if (color.isNotEmpty)
                              CartPageStyles.buildVariationChip('Color: $color', Colors.blue),
                            if (variacionNombre.isNotEmpty && variacionValor.isNotEmpty)
                              CartPageStyles.buildVariationChip('$variacionNombre: $variacionValor', Colors.teal),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      // Precio
                      Text(
                        _currencyFormat.format(precioUnitario),
                        style: CartPageStyles.priceStyle,
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Controles de cantidad y eliminar
                      Row(
                        children: [
                          Text(
                            'Cantidad:',
                            style: CartPageStyles.quantityLabelStyle,
                          ),
                          const Spacer(),
                          _buildQuantityControls(productoId, cantidad, variacionId),
                          const SizedBox(width: 8),
                          // Botón eliminar
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _eliminarProducto(
                                productoId, 
                                variacionId: variacionId.isNotEmpty ? variacionId : null
                              ),
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                child: CartPageStyles.buildDeleteIcon(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(String productoId, int cantidad, String variacionId) {
    return Container(
      decoration: CartPageStyles.quantityControlsDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botón disminuir
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: cantidad > 1 ? () {
                _actualizarCantidadLocal(
                  productoId, 
                  cantidad - 1, 
                  variacionId: variacionId.isNotEmpty ? variacionId : null
                );
              } : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                child: CartPageStyles.buildQuantityIcon(
                  Icons.remove, 
                  enabled: cantidad > 1,
                ),
              ),
            ),
          ),
          
          // Cantidad actual
          Container(
            constraints: const BoxConstraints(minWidth: 32),
            child: Text(
              cantidad.toString(),
              textAlign: TextAlign.center,
              style: CartPageStyles.quantityValueStyle,
            ),
          ),
          
          // Botón aumentar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                _actualizarCantidadLocal(
                  productoId, 
                  cantidad + 1,
                  variacionId: variacionId.isNotEmpty ? variacionId : null
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                child: CartPageStyles.buildQuantityIcon(
                  Icons.add, 
                  enabled: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}