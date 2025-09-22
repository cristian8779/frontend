import '../../services/carrito_service.dart';
import '../../providers/auth_provider.dart';
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
            const SnackBar(
              content: Text('Carrito actualizado'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
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
          const SnackBar(
            content: Text('Error al actualizar carrito'),
            backgroundColor: Colors.red,
          ),
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
        const SnackBar(content: Text('Error: ID de producto inválido')),
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
        
        // Comparar tanto producto como variación
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
          const SnackBar(content: Text('Error al actualizar cantidad')),
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
        SnackBar(content: Text('Error al actualizar cantidad: ${e.toString()}')),
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
        return AlertDialog(
          title: const Text('Eliminar producto'),
          content: const Text('¿Estás seguro de que deseas eliminar este producto del carrito?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Eliminar'),
            ),
          ],
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
          const SnackBar(content: Text('Producto eliminado del carrito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al eliminar producto')),
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
        SnackBar(content: Text('Error al eliminar producto: ${e.toString()}')),
      );
    }
  }

  void _navegarADetalleProducto(String productoId) {
    if (productoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: ID de producto inválido'),
          backgroundColor: Colors.red,
        ),
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
        const SnackBar(
          content: Text('Tu carrito está vacío'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userId = authProvider.userId;
    if (userId == null || userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el usuario'),
          backgroundColor: Colors.red,
        ),
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

  // Función para obtener dimensiones responsive
  Map<String, dynamic> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // Breakpoints más específicos
    bool isSmall = screenWidth < 480;
    bool isMedium = screenWidth >= 480 && screenWidth < 768;
    bool isTablet = screenWidth >= 768 && screenWidth < 1024;
    bool isDesktop = screenWidth >= 1024;
    bool isLargeDesktop = screenWidth >= 1440;
    
    return {
      'isSmall': isSmall,
      'isMedium': isMedium,
      'isTablet': isTablet,
      'isDesktop': isDesktop,
      'isLargeDesktop': isLargeDesktop,
      'screenWidth': screenWidth,
      'screenHeight': screenHeight,
      'horizontalPadding': isLargeDesktop ? 40.0 : 
                          isDesktop ? 32.0 : 
                          isTablet ? 24.0 : 
                          isMedium ? 20.0 : 16.0,
      'verticalPadding': isDesktop ? 24.0 : 
                        isTablet ? 20.0 : 16.0,
      'headerFontSize': isLargeDesktop ? 28.0 : 
                       isDesktop ? 26.0 :
                       isTablet ? 24.0 : 
                       isMedium ? 22.0 : 20.0,
      'cardPadding': isDesktop ? 24.0 : 
                    isTablet ? 20.0 : 
                    isMedium ? 16.0 : 12.0,
      'itemImageSize': isDesktop ? 100.0 : 
                      isTablet ? 80.0 : 
                      isMedium ? 70.0 : 60.0,
      'buttonHeight': isDesktop ? 64.0 : 
                     isTablet ? 60.0 : 56.0,
    };
  }

  Widget _buildShimmerItem(Map<String, dynamic> responsive) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: responsive['horizontalPadding'],
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(responsive['cardPadding']),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shimmer para imagen
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: responsive['itemImageSize'],
                    height: responsive['itemImageSize'],
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                
                SizedBox(width: responsive['isDesktop'] ? 20.0 : 16.0),
                
                // Shimmer para información
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: responsive['isDesktop'] ? 20.0 : 18.0,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: responsive['isDesktop'] ? 16.0 : 14.0,
                          width: 150,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: responsive['isDesktop'] ? 18.0 : 16.0,
                          width: 100,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Shimmer para botón eliminar
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: responsive['isDesktop'] ? 20.0 : 16.0),
            
            // Shimmer para controles
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      height: 16,
                      width: 80,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: responsive['isDesktop'] ? 152.0 : 122.0,
                      height: responsive['isDesktop'] ? 44.0 : 36.0,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
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
    final responsive = _getResponsiveDimensions(context);

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.cargando) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!authProvider.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: SafeArea(
            child: Column(
              children: [
                // Header mejorado
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive['horizontalPadding'],
                    vertical: responsive['verticalPadding'],
                  ),
                  child: Row(
                    children: [
                      // Botón de regreso
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black87,
                            size: responsive['isDesktop'] ? 24.0 : 20.0,
                          ),
                        ),
                      ),
                      
                      // Título centrado
                      Expanded(
                        child: Text(
                          'Carrito de Compra',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive['headerFontSize'],
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      
                      // Icono de carrito con contador
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4A5568).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Stack(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              color: const Color(0xFF4A5568),
                              size: responsive['isDesktop'] ? 24.0 : 20.0,
                            ),
                            if (totalItems > 0)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    totalItems > 99 ? '99+' : totalItems.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenido principal - pantalla completa
                Expanded(
                  child: _buildCartView(authProvider, responsive),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartView(AuthProvider authProvider, Map<String, dynamic> responsive) {
    if (isLoading) {
      return Column(
        children: [
          // Shimmer para header
          Container(
            margin: EdgeInsets.all(responsive['horizontalPadding']),
            padding: EdgeInsets.symmetric(
              horizontal: responsive['cardPadding'],
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          
          // Shimmer items
          Expanded(
            child: ListView.builder(
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
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(responsive['horizontalPadding']),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        size: responsive['isDesktop'] ? 80.0 : 60.0,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    SizedBox(height: responsive['isDesktop'] ? 32.0 : 24.0),
                    Text(
                      'Tu carrito está vacío',
                      style: TextStyle(
                        fontSize: responsive['isDesktop'] ? 24.0 : 20.0,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: responsive['isDesktop'] ? 16.0 : 12.0),
                    Text(
                      'Desliza hacia abajo para actualizar\no agrega productos para comenzar',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
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
            color: const Color(0xFF4A5568),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // Header con contador de items
                if (items.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: EdgeInsets.all(responsive['horizontalPadding']),
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive['cardPadding'],
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A5568).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: const Color(0xFF4A5568),
                            size: responsive['isDesktop'] ? 20.0 : 18.0,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '$totalItems producto${totalItems != 1 ? 's' : ''} en tu carrito',
                            style: TextStyle(
                              fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                          const Spacer(),
                          if (isRefreshing)
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                
                // Lista de productos
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive['horizontalPadding'],
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = items[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: responsive['isDesktop'] ? 16.0 : 12.0,
                          ),
                          child: _buildCarritoItem(item, index, responsive),
                        );
                      },
                      childCount: items.length,
                    ),
                  ),
                ),
                
                // Espaciado inferior
                SliverToBoxAdapter(
                  child: SizedBox(height: responsive['verticalPadding']),
                ),
              ],
            ),
          ),
        ),

        // Panel de total y pago
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.all(responsive['horizontalPadding']),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Resumen del pedido
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive['cardPadding']),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Productos ($totalItems):',
                              style: TextStyle(
                                fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(totalPrice),
                              style: TextStyle(
                                fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Divider(color: Colors.grey.shade300, thickness: 1),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: responsive['isDesktop'] ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _currencyFormat.format(totalPrice),
                              style: TextStyle(
                                fontSize: responsive['isDesktop'] ? 24.0 : 22.0,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4A5568),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: responsive['verticalPadding']),
                  
                  // Botón de pago
                  SizedBox(
                    width: double.infinity,
                    height: responsive['buttonHeight'],
                    child: ElevatedButton(
                      onPressed: () => _navegarAPago(authProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4A5568),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: const Color(0xFF4A5568).withOpacity(0.3),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.security_outlined,
                            size: responsive['isDesktop'] ? 24.0 : 20.0,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Proceder al Pago Seguro',
                            style: TextStyle(
                              fontSize: responsive['isDesktop'] ? 18.0 : 16.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            size: responsive['isDesktop'] ? 20.0 : 18.0,
                          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navegarADetalleProducto(productoId),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(responsive['cardPadding']),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen del producto mejorada
                    Container(
                      width: responsive['itemImageSize'],
                      height: responsive['itemImageSize'],
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.grey.shade100,
                      ),
                      child: imagenUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imagenUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  if (progress == null) return child;
                                  return Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      color: Colors.white,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.image_not_supported_outlined,
                                    size: responsive['itemImageSize'] * 0.4,
                                    color: Colors.grey.shade400,
                                  );
                                },
                              ),
                            )
                          : Icon(
                              Icons.shopping_bag_outlined,
                              size: responsive['itemImageSize'] * 0.4,
                              color: Colors.grey.shade400,
                            ),
                    ),
                    
                    SizedBox(width: responsive['isDesktop'] ? 20.0 : 16.0),
                    
                    // Información del producto
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            style: TextStyle(
                              fontSize: responsive['isDesktop'] ? 18.0 : 16.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          // Mostrar información de variaciones si existe
                          if (variacionNombre.isNotEmpty || talla.isNotEmpty || color.isNotEmpty) ...[
                            SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (talla.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.purple.shade200),
                                    ),
                                    child: Text(
                                      'Talla: $talla',
                                      style: TextStyle(
                                        fontSize: responsive['isDesktop'] ? 11.0 : 10.0,
                                        color: Colors.purple.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (color.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.orange.shade200),
                                    ),
                                    child: Text(
                                      'Color: $color',
                                      style: TextStyle(
                                        fontSize: responsive['isDesktop'] ? 11.0 : 10.0,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                if (variacionNombre.isNotEmpty && variacionValor.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.indigo.shade200),
                                    ),
                                    child: Text(
                                      '$variacionNombre: $variacionValor',
                                      style: TextStyle(
                                        fontSize: responsive['isDesktop'] ? 11.0 : 10.0,
                                        color: Colors.indigo.shade700,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          
                          SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Precio unitario: ${_currencyFormat.format(precioUnitario)}',
                              style: TextStyle(
                                fontSize: responsive['isDesktop'] ? 12.0 : 11.0,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Subtotal: ${_currencyFormat.format(precio)}',
                            style: TextStyle(
                              fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF4A5568),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Botón eliminar mejorado
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        onPressed: () => _eliminarProducto(
                          productoId, 
                          variacionId: variacionId.isNotEmpty ? variacionId : null
                        ),
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: responsive['isDesktop'] ? 24.0 : 20.0,
                        ),
                        tooltip: 'Eliminar producto',
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: responsive['isDesktop'] ? 20.0 : 16.0),
                
                // Controles de cantidad mejorados
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cantidad:',
                        style: TextStyle(
                          fontSize: responsive['isDesktop'] ? 16.0 : 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
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
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  bottomLeft: Radius.circular(12),
                                ),
                                child: Container(
                                  width: responsive['isDesktop'] ? 44.0 : 36.0,
                                  height: responsive['isDesktop'] ? 44.0 : 36.0,
                                  decoration: BoxDecoration(
                                    color: cantidad > 1 
                                        ? const Color(0xFF4A5568) 
                                        : Colors.grey.shade200,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      bottomLeft: Radius.circular(12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    color: cantidad > 1 ? Colors.white : Colors.grey.shade400,
                                    size: responsive['isDesktop'] ? 20.0 : 16.0,
                                  ),
                                ),
                              ),
                            ),
                            
                            // Cantidad actual
                            Container(
                              width: responsive['isDesktop'] ? 60.0 : 50.0,
                              height: responsive['isDesktop'] ? 44.0 : 36.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.symmetric(
                                  vertical: BorderSide(
                                    color: Colors.grey.shade200,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  cantidad.toString(),
                                  style: TextStyle(
                                    fontSize: responsive['isDesktop'] ? 18.0 : 16.0,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
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
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(12),
                                  bottomRight: Radius.circular(12),
                                ),
                                child: Container(
                                  width: responsive['isDesktop'] ? 44.0 : 36.0,
                                  height: responsive['isDesktop'] ? 44.0 : 36.0,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF4A5568),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(12),
                                      bottomRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add,
                                    color: Colors.white,
                                    size: responsive['isDesktop'] ? 20.0 : 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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
}