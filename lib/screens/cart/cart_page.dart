import '../../providers/carrito_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/cart/cart_page_styles.dart';
import '../../services/producto_usuario_service.dart';
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
  // Formatear números con formato colombiano
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\$#,##0',
  );

  // Estado local para actualizaciones optimistas
  final Map<String, int> _actualizacionesOptimistas = {};
  final Map<String, bool> _itemsActualizando = {};
  
  // Cache de stock
  final Map<String, int> _stockCache = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _verificarAutenticacionYCargar();
    });
  }

  Future<void> _verificarAutenticacionYCargar() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final carritoProvider = Provider.of<CarritoProvider>(context, listen: false);

    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    await _cargarCarrito(authProvider, carritoProvider);
  }

  Future<void> _cargarCarrito(
    AuthProvider authProvider,
    CarritoProvider carritoProvider, {
    bool isRefresh = false,
  }) async {
    final token = authProvider.token;
    if (token == null || token.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    try {
      await carritoProvider.obtenerCarrito(token);
      
      // PRE-CARGAR EL STOCK DE TODOS LOS ITEMS
      await _precargarStockItems(carritoProvider);
      
      // Limpiar actualizaciones optimistas después de cargar
      _actualizacionesOptimistas.clear();
      _itemsActualizando.clear();
      
      if (isRefresh && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildSuccessSnackBar('Carrito actualizado'),
        );
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }
      
      if (isRefresh && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          CartPageStyles.buildErrorSnackBar('Error al actualizar carrito'),
        );
      }
    }
  }

  // Método para pre-cargar el stock de todos los items
  Future<void> _precargarStockItems(CarritoProvider carritoProvider) async {
    print('🔄 Pre-cargando stock de todos los items del carrito...');
    print('📊 Cantidad de items en el carrito: ${carritoProvider.items.length}');
    
    if (carritoProvider.items.isEmpty) {
      print('⚠️ No hay items en el carrito para pre-cargar stock');
      return;
    }
    
    for (var item in carritoProvider.items) {
      final productoId = item['productoId'] ?? item['id'] ?? '';
      final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
      
      print('🔍 Procesando item: ProductoId=$productoId, VariacionId=$variacionId');
      
      if (productoId.isNotEmpty) {
        try {
          await _obtenerStockRealProducto(
            productoId, 
            variacionId.isNotEmpty ? variacionId : null
          );
        } catch (e) {
          print('❌ Error al pre-cargar stock del producto $productoId: $e');
        }
      } else {
        print('⚠️ Item sin productoId válido');
      }
    }
    
    print('✅ Stock pre-cargado para ${carritoProvider.items.length} items');
    print('📦 Cache de stock actual: $_stockCache');
    
    // Forzar rebuild para mostrar las advertencias de stock
    if (mounted) {
      setState(() {});
    }
  }

  // Método para obtener el stock real del producto
  Future<int> _obtenerStockRealProducto(String productoId, String? variacionId) async {
    try {
      // Crear una key única para el cache
      final cacheKey = variacionId != null && variacionId.isNotEmpty 
          ? '${productoId}_$variacionId'
          : productoId;
      
      // Si ya está en cache, devolverlo
      if (_stockCache.containsKey(cacheKey)) {
        print('📦 Stock obtenido del cache para $cacheKey: ${_stockCache[cacheKey]}');
        return _stockCache[cacheKey]!;
      }
      
      print('🔍 Consultando stock del producto: $productoId (variación: $variacionId)');
      
      // Obtener el producto completo
      final producto = await ProductoUsuarioService().obtenerProductoPorId(productoId);
      print('✅ Producto obtenido. Keys disponibles: ${producto.keys.toList()}');
      
      int stock = 0;
      
      // Si hay variación, buscar el stock de esa variación específica
      if (variacionId != null && variacionId.isNotEmpty) {
        print('🔍 Buscando stock de variación: $variacionId');
        
        final variaciones = await ProductoUsuarioService().obtenerVariacionesPorProducto(productoId);
        print('📋 Total de variaciones encontradas: ${variaciones.length}');
        
        for (var variacion in variaciones) {
          final varId = variacion['_id'] ?? variacion['id'];
          if (varId == variacionId) {
            stock = variacion['stock'] ?? 0;
            print('✅ Stock de variación $variacionId encontrado: $stock');
            break;
          }
        }
        
        if (stock == 0) {
          print('⚠️ No se encontró stock para la variación $variacionId');
        }
      } else {
        // Si no hay variación, usar el stock del producto base
        stock = producto['stock'] ?? 0;
        print('✅ Stock del producto base: $stock');
      }
      
      // Guardar en cache
      _stockCache[cacheKey] = stock;
      print('💾 Stock guardado en cache: $cacheKey = $stock');
      
      return stock;
    } catch (e) {
      print('❌ Error al obtener stock del producto $productoId: $e');
      print('📚 Stack trace: ${StackTrace.current}');
      return 999; // En caso de error, asumir stock alto
    }
  }

  String _getItemKey(String productoId, String? variacionId) {
    return variacionId != null && variacionId.isNotEmpty
        ? '${productoId}_$variacionId'
        : productoId;
  }

  Future<void> _actualizarCantidadOptimista(
    String productoId,
    int nuevaCantidad, {
    String? variacionId,
  }) async {
    if (productoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar('Error: ID de producto inválido'),
      );
      return;
    }

    if (nuevaCantidad <= 0) {
      await _eliminarProducto(productoId, variacionId: variacionId);
      return;
    }

    // OBTENER EL STOCK REAL DEL PRODUCTO/VARIACIÓN
    final stockDisponible = await _obtenerStockRealProducto(productoId, variacionId);
    
    print('📦 CartPage - Validando stock:');
    print('   ProductoId: $productoId');
    print('   VariacionId: $variacionId');
    print('   Nueva cantidad: $nuevaCantidad');
    print('   Stock disponible: $stockDisponible');
    
    if (nuevaCantidad > stockDisponible) {
      print('⛔ BLOQUEADO - Intento de superar el stock');
      
      // SnackBar responsive con más información
      final screenWidth = MediaQuery.of(context).size.width;
      final isDesktop = screenWidth >= 1024;
      final isTablet = screenWidth >= 768 && screenWidth < 1024;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: Colors.white,
                size: isDesktop ? 24 : 20,
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock máximo alcanzado',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 16 : 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Solo hay $stockDisponible unidad${stockDisponible != 1 ? 'es' : ''} disponible${stockDisponible != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: isDesktop ? 14 : 13,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFFF9500),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          margin: EdgeInsets.all(isDesktop ? 24 : isTablet ? 20 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isDesktop ? 12 : 8),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 24 : 16,
            vertical: isDesktop ? 16 : 12,
          ),
        ),
      );
      return;
    }
    
    print('✅ Validación de stock pasada, procediendo con la actualización');

    final itemKey = _getItemKey(productoId, variacionId);
    
    // Actualización optimista: actualizar UI inmediatamente
    setState(() {
      _actualizacionesOptimistas[itemKey] = nuevaCantidad;
      _itemsActualizando[itemKey] = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final carritoProvider = Provider.of<CarritoProvider>(context, listen: false);
    final token = authProvider.token;
    if (token == null) return;

    try {
      // Hacer la petición al servidor sin esperar a recargar todo el carrito
      final success = await carritoProvider.actualizarCantidadConVariacion(
        token,
        productoId,
        nuevaCantidad,
        variacionId: variacionId,
      );

      if (mounted) {
        setState(() {
          _itemsActualizando[itemKey] = false;
        });

        if (!success && carritoProvider.error != null) {
          // Si falla, revertir y mostrar error
          setState(() {
            _actualizacionesOptimistas.remove(itemKey);
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            CartPageStyles.buildErrorSnackBar(carritoProvider.error!),
          );
        } else {
          // Limpiar la actualización optimista después de un momento
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _actualizacionesOptimistas.remove(itemKey);
              });
            }
          });
        }
      }

      // Manejar errores de autenticación
      if (carritoProvider.error?.contains('Sesión expirada') ?? false) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _actualizacionesOptimistas.remove(itemKey);
          _itemsActualizando[itemKey] = false;
        });
      }
    }
  }

  Future<void> _eliminarProducto(String productoId, {String? variacionId}) async {
    if (productoId.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final carritoProvider = Provider.of<CarritoProvider>(context, listen: false);
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

    final success = await carritoProvider.eliminarProductoConVariacion(
      token,
      productoId,
      variacionId: variacionId,
    );

    if (success) {
      // Limpiar cache de stock al eliminar
      final cacheKey = variacionId != null && variacionId.isNotEmpty 
          ? '${productoId}_$variacionId'
          : productoId;
      _stockCache.remove(cacheKey);
      
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildSuccessSnackBar('Producto eliminado del carrito'),
      );
    } else if (carritoProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        CartPageStyles.buildErrorSnackBar(carritoProvider.error!),
      );
    }

    if (carritoProvider.error?.contains('Sesión expirada') ?? false) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
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

  void _navegarAPago(CarritoProvider carritoProvider, AuthProvider authProvider) {
    if (carritoProvider.isEmpty) {
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

    // Calcular el total real considerando las actualizaciones optimistas
    double totalReal = _calcularTotalOptimista(carritoProvider);
    int cantidadReal = _calcularCantidadOptimista(carritoProvider);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BoldPaymentPage(
          totalPrice: totalReal,
          totalItems: cantidadReal,
        ),
      ),
    );
  }

  double _calcularTotalOptimista(CarritoProvider carritoProvider) {
    double total = 0.0;
    
    for (var item in carritoProvider.items) {
      final productoId = item['productoId'] ?? item['id'] ?? '';
      final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
      final itemKey = _getItemKey(productoId, variacionId);
      
      final precioUnitario = (item['precioUnitario'] ?? item['unitPrice'] ?? 0.0).toDouble();
      final cantidad = _actualizacionesOptimistas[itemKey] ?? 
                      (item['cantidad'] ?? item['quantity'] ?? 1);
      
      total += precioUnitario * cantidad;
    }
    
    return total;
  }

  int _calcularCantidadOptimista(CarritoProvider carritoProvider) {
    int total = 0;
    
    for (var item in carritoProvider.items) {
      final productoId = item['productoId'] ?? item['id'] ?? '';
      final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
      final itemKey = _getItemKey(productoId, variacionId);
      
      final cantidad = _actualizacionesOptimistas[itemKey] ?? 
                      (item['cantidad'] ?? item['quantity'] ?? 1);
      
      total += cantidad as int;
    }
    
    return total;
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

    return Consumer2<AuthProvider, CarritoProvider>(
      builder: (context, authProvider, carritoProvider, child) {
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
            totalItems: _calcularCantidadOptimista(carritoProvider),
          ),
          body: _buildCartView(authProvider, carritoProvider, responsive),
        );
      },
    );
  }

  Widget _buildCartView(
    AuthProvider authProvider,
    CarritoProvider carritoProvider,
    Map<String, dynamic> responsive,
  ) {
    if (carritoProvider.isLoading) {
      return Column(
        children: [
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

    if (carritoProvider.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _cargarCarrito(authProvider, carritoProvider, isRefresh: true),
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

    // Calcular totales con actualizaciones optimistas
    final totalOptimista = _calcularTotalOptimista(carritoProvider);
    final cantidadOptimista = _calcularCantidadOptimista(carritoProvider);

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _cargarCarrito(authProvider, carritoProvider, isRefresh: true),
            color: CartPageStyles.primaryBlue,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: carritoProvider.items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = carritoProvider.items[index];
                return _buildCarritoItem(item, index, responsive, carritoProvider);
              },
            ),
          ),
        ),

        Container(
          decoration: CartPageStyles.paymentPanelDecoration,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
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
                              'Total ($cantidadOptimista producto${cantidadOptimista != 1 ? 's' : ''})',
                              style: CartPageStyles.totalLabelStyle,
                            ),
                            const SizedBox(height: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, animation) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0, 0.3),
                                      end: Offset.zero,
                                    ).animate(animation),
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                _currencyFormat.format(totalOptimista),
                                key: ValueKey<double>(totalOptimista),
                                style: CartPageStyles.totalPriceStyle,
                              ),
                            ),
                          ],
                        ),
                        CartPageStyles.buildShippingIcon(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: responsive['buttonHeight'],
                    child: ElevatedButton(
                      onPressed: carritoProvider.isDeleting
                          ? null
                          : () => _navegarAPago(carritoProvider, authProvider),
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

  Widget _buildCarritoItem(
    dynamic item,
    int index,
    Map<String, dynamic> responsive,
    CarritoProvider carritoProvider,
  ) {
    final nombre = item['nombre'] ?? item['name'] ?? 'Producto';
    final productoId = item['productoId'] ?? item['id'] ?? '';
    final variacionId = item['variacionId'] ?? item['variation_id'] ?? '';
    final itemKey = _getItemKey(productoId, variacionId);
    
    // Usar cantidad optimista si existe, sino la del servidor
    final cantidadOriginal = item['cantidad'] ?? item['quantity'] ?? 1;
    final cantidad = _actualizacionesOptimistas[itemKey] ?? cantidadOriginal;
    
    final precioUnitario = (item['precioUnitario'] ?? item['unitPrice'] ?? 0.0).toDouble();
    final precioTotal = precioUnitario * cantidad;
    
    final imagenUrl = item['imagen'] ?? item['image'] ?? '';
    final variacionNombre = item['variacionNombre'] ?? item['variation_name'] ?? '';
    final variacionValor = item['variacionValor'] ?? item['variation_value'] ?? '';
    final talla = item['talla'] ?? item['size'] ?? '';
    final color = item['color'] ?? '';
    
    final isActualizando = _itemsActualizando[itemKey] ?? false;
    
    // Obtener stock disponible del cache (si existe)
    final cacheKey = variacionId.isNotEmpty ? '${productoId}_$variacionId' : productoId;
    final stockDisponible = _stockCache[cacheKey] ?? 999;
    
    // Mostrar advertencia si está cerca del límite
    final cercaDelLimite = cantidad >= (stockDisponible * 0.8) && stockDisponible < 999;
    
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
                Container(
                  width: responsive['itemImageSize'],
                  height: responsive['itemImageSize'],
                  decoration: CartPageStyles.buildImageDecoration(),
                 child: imagenUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            imagenUrl,
                            fit: BoxFit.contain,
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
                      
                      // Precio con animación suave
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (child, animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: Text(
                          _currencyFormat.format(precioUnitario),
                          key: ValueKey<String>('precio_$productoId'),
                          style: CartPageStyles.priceStyle,
                        ),
                      ),
                      
                      // Indicador de stock si está cerca del límite
                      if (cercaDelLimite) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 14,
                              color: Colors.orange.shade700,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Solo quedan $stockDisponible unidades',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 8),
                      
                      Row(
                        children: [
                          Text(
                            'Cantidad:',
                            style: CartPageStyles.quantityLabelStyle,
                          ),
                          if (isActualizando) ...[
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  CartPageStyles.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          _buildQuantityControls(
                            productoId,
                            cantidad,
                            variacionId,
                            isActualizando,
                            stockDisponible,
                          ),
                          const SizedBox(width: 8),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: carritoProvider.isDeleting
                                  ? null
                                  : () => _eliminarProducto(
                                        productoId,
                                        variacionId: variacionId.isNotEmpty ? variacionId : null,
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

  Widget _buildQuantityControls(
    String productoId,
    int cantidad,
    String variacionId,
    bool isActualizando,
    int stockDisponible,
  ) {
    // Verificar si se puede aumentar la cantidad
    final puedeAumentar = cantidad < stockDisponible;
    
    return Container(
      decoration: CartPageStyles.quantityControlsDecoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (cantidad > 1 && !isActualizando)
                  ? () => _actualizarCantidadOptimista(
                        productoId,
                        cantidad - 1,
                        variacionId: variacionId.isNotEmpty ? variacionId : null,
                      )
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                child: CartPageStyles.buildQuantityIcon(
                  Icons.remove,
                  enabled: cantidad > 1 && !isActualizando,
                ),
              ),
            ),
          ),
          
          // Cantidad con animación
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(
                scale: animation,
                child: child,
              );
            },
            child: Container(
              key: ValueKey<int>(cantidad),
              constraints: const BoxConstraints(minWidth: 32),
              child: Text(
                cantidad.toString(),
                textAlign: TextAlign.center,
                style: CartPageStyles.quantityValueStyle,
              ),
            ),
          ),
          
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: (puedeAumentar && !isActualizando)
                  ? () => _actualizarCantidadOptimista(
                        productoId,
                        cantidad + 1,
                        variacionId: variacionId.isNotEmpty ? variacionId : null,
                      )
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 32,
                height: 32,
                child: CartPageStyles.buildQuantityIcon(
                  Icons.add,
                  enabled: puedeAumentar && !isActualizando,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}