import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../providers/producto_provider.dart';
import '../screens/producto/producto_screen.dart';
import '../services/FavoritoService.dart';
import '../services/carrito_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ListaProductosWidget extends StatefulWidget {
  const ListaProductosWidget({super.key});

  @override
  State<ListaProductosWidget> createState() => _ListaProductosWidgetState();
}

class _ListaProductosWidgetState extends State<ListaProductosWidget>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  // Servicios
  final FavoritoService _favoritoService = FavoritoService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Estados para favoritos
  Set<String> _favoritos = {};
  bool _loadingFavoritos = false;

  // Controladores de animación
  late AnimationController _animationController;
  List<AnimationController> _itemControllers = [];

  @override
  void initState() {
    super.initState();

    // Inicializar controlador de animación principal
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Cargar productos al iniciar
    Future.microtask(() {
      final provider = Provider.of<ProductosProvider>(context, listen: false);
      provider.cargarProductos();
      _cargarFavoritos();
    });

    // Detectar cuando llegamos al final del scroll
    _scrollController.addListener(() {
      final provider = Provider.of<ProductosProvider>(context, listen: false);

      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !provider.isLoading &&
          provider.hasMore) {
        provider.cargarMasProductos();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    for (var controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Cargar favoritos del usuario
  Future<void> _cargarFavoritos() async {
    try {
      setState(() => _loadingFavoritos = true);
      
      final token = await _secureStorage.read(key: 'accessToken');
      if (token != null) {
        final favoritos = await _favoritoService.obtenerFavoritos();
        final favoritosIds = favoritos
            .map((f) => f['producto']?['_id'] ?? f['productoId'])
            .where((id) => id != null)
            .cast<String>()
            .toSet();
        
        if (mounted) {
          setState(() {
            _favoritos = favoritosIds;
            _loadingFavoritos = false;
          });
        }
      }
    } catch (e) {
      print('Error cargando favoritos: $e');
      if (mounted) {
        setState(() => _loadingFavoritos = false);
      }
    }
  }

  // Toggle favorito
  Future<void> _toggleFavorito(String productoId) async {
    try {
      final esFavorito = _favoritos.contains(productoId);
      
      if (esFavorito) {
        await _favoritoService.eliminarFavorito(productoId);
        if (mounted) {
          setState(() => _favoritos.remove(productoId));
          _mostrarSnackbar('Eliminado de favoritos', Icons.heart_broken);
        }
      } else {
        await _favoritoService.agregarFavorito(productoId);
        if (mounted) {
          setState(() => _favoritos.add(productoId));
          _mostrarSnackbar('Agregado a favoritos', Icons.favorite, Colors.red);
        }
      }
    } catch (e) {
      _mostrarSnackbar('Error: ${e.toString()}', Icons.error, Colors.red);
    }
  }

  // Mostrar snackbar con mensaje
  void _mostrarSnackbar(String mensaje, IconData icon, [Color? color]) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color ?? Colors.grey[800],
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _formatPrice(dynamic precio) {
    if (precio == null) return "Sin precio";
    try {
      final num parsed =
          precio is num ? precio : num.tryParse(precio.toString()) ?? 0;
      final formatter = NumberFormat('#,##0', 'es_CO');
      return '\$${formatter.format(parsed)}';
    } catch (_) {
      return "Sin precio";
    }
  }

  Widget _buildShimmerItem() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen shimmer
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),
            ),
            
            // Contenido shimmer
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Precio shimmer
                    Container(
                      height: 20,
                      width: double.infinity * 0.6,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Nombre shimmer - línea 1
                    Container(
                      height: 12,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Nombre shimmer - línea 2
                    Container(
                      height: 12,
                      width: double.infinity * 0.7,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Stock shimmer
                    Container(
                      height: 20,
                      width: double.infinity * 0.4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Crear controladores de animación para nuevos items
  void _crearControladorParaItem(int index) {
    if (_itemControllers.length <= index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 300 + (index * 50)),
        vsync: this,
      );
      _itemControllers.add(controller);
      controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<ProductosProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.productos.isEmpty) {
          // Mostrar shimmer effect durante la carga inicial
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF8F9FA),
                  const Color(0xFFF1F3F4),
                ],
              ),
            ),
            child: GridView.builder(
              controller: _scrollController,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(12),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: size.width * 0.5,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: 6,
              itemBuilder: (context, index) => _buildShimmerItem(),
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: Colors.red[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Oops! Algo salió mal",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (provider.productos.isEmpty) {
          return Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shopping_bag_outlined,
                      size: 48,
                      color: Colors.blue[400],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No hay productos",
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No hay productos disponibles en este momento",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFF8F9FA),
                const Color(0xFFF1F3F4),
              ],
            ),
          ),
          child: GridView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: size.width * 0.5,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.65,
            ),
            itemCount: provider.productos.length + (provider.hasMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= provider.productos.length) {
                return Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3483FA),
                      strokeWidth: 3,
                    ),
                  ),
                );
              }

              final producto = provider.productos[index];
              final nombre = producto['nombre'] ?? 'Producto sin nombre';
              final imagen = producto['imagen'] ?? producto['imagenUrl'] ?? '';
              final precio = producto['precio'];
              final stock = producto['stock'] ?? producto['cantidad'] ?? producto['disponible'];
              final productoId = producto['_id'];

              // Crear controlador de animación para este item
              _crearControladorParaItem(index);

              return AnimatedBuilder(
                animation: _itemControllers.length > index 
                    ? _itemControllers[index] 
                    : _animationController,
                builder: (context, child) {
                  final controller = _itemControllers.length > index 
                      ? _itemControllers[index] 
                      : _animationController;
                      
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: controller,
                      curve: Curves.easeOutBack,
                    )),
                    child: FadeTransition(
                      opacity: controller,
                      child: _ProductoCard(
                        producto: producto,
                        nombre: nombre,
                        imagenUrl: imagen.isNotEmpty
                            ? imagen
                            : 'https://via.placeholder.com/400x280/f5f5f5/cccccc?text=Sin+Imagen',
                        precio: precio,
                        stock: stock,
                        formatPrice: _formatPrice,
                        onTap: () => _navigateToProductDetail(context, producto),
                        // Funcionalidad de favoritos
                        esFavorito: productoId != null && _favoritos.contains(productoId),
                        onToggleFavorito: productoId != null 
                            ? () => _toggleFavorito(productoId)
                            : null,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Función para navegar al detalle del producto
  void _navigateToProductDetail(BuildContext context, Map<String, dynamic> producto) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductoScreen(productId: producto['_id']),
      ),
    );
  }
}

class _ProductoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final String nombre;
  final String imagenUrl;
  final dynamic precio;
  final dynamic stock;
  final String Function(dynamic) formatPrice;
  final VoidCallback onTap;
  final bool esFavorito;
  final VoidCallback? onToggleFavorito;

  const _ProductoCard({
    Key? key,
    required this.producto,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
    required this.stock,
    required this.formatPrice,
    required this.onTap,
    required this.esFavorito,
    required this.onToggleFavorito,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 1,
                offset: const Offset(0, 1),
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto con favorito
              Expanded(
                flex: 6,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.white,
                          child: Image.network(
                            imagenUrl,
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  color: const Color(0xFF3483FA),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 32,
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Sin imagen',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        // Botón de favorito (corazón)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: onToggleFavorito,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child: Icon(
                                      esFavorito ? Icons.favorite : Icons.favorite_border,
                                      key: ValueKey(esFavorito),
                                      color: esFavorito ? Colors.red : Colors.grey[600],
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Información del producto
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Precio principal
                      Text(
                        formatPrice(precio),
                        style: const TextStyle(
                          color: Color(0xFF1a1a1a),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Nombre del producto
                      Expanded(
                        child: Text(
                          nombre,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            height: 1.3,
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      
                      const SizedBox(height: 6),
                      
                      // Indicador de stock
                      _buildStockIndicator(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator() {
    // Determinar el estado del stock
    bool hasStock = false;
    String stockText = '';
    Color backgroundColor = Colors.red.withOpacity(0.15);
    Color textColor = Colors.red[700]!;

    if (stock == null) {
      // Si no hay información de stock, mostrar como disponible
      hasStock = true;
      stockText = 'Disponible';
      backgroundColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green[700]!;
    } else if (stock is bool) {
      // Si el stock es un booleano
      hasStock = stock;
      stockText = hasStock ? 'Disponible' : 'Sin stock';
    } else if (stock is num) {
      // Si el stock es un número
      final stockNum = stock as num;
      hasStock = stockNum > 0;
      if (stockNum > 5) {
        stockText = 'Disponible';
      } else if (stockNum > 0) {
        stockText = 'Últimas ${stockNum.toInt()}';
        backgroundColor = Colors.orange.withOpacity(0.15);
        textColor = Colors.orange[700]!;
      } else {
        stockText = 'Sin stock';
      }
    } else if (stock is String) {
      // Si el stock es string, intentar parsearlo
      final stockLower = stock.toString().toLowerCase();
      if (stockLower.contains('disponible') || stockLower.contains('si') || stockLower == 'true') {
        hasStock = true;
        stockText = 'Disponible';
      } else if (stockLower.contains('agotado') || stockLower.contains('no') || stockLower == 'false') {
        hasStock = false;
        stockText = 'Sin stock';
      } else {
        // Intentar parsear como número
        final parsedStock = num.tryParse(stock.toString());
        if (parsedStock != null) {
          hasStock = parsedStock > 0;
          if (parsedStock > 5) {
            stockText = 'Disponible';
          } else if (parsedStock > 0) {
            stockText = 'Últimas ${parsedStock.toInt()}';
            backgroundColor = Colors.orange.withOpacity(0.15);
            textColor = Colors.orange[700]!;
          } else {
            stockText = 'Sin stock';
          }
        } else {
          // Por defecto, mostrar el texto tal como viene
          hasStock = true;
          stockText = stock.toString();
        }
      }
    }

    // Establecer colores según disponibilidad
    if (hasStock && stockText == 'Disponible') {
      backgroundColor = Colors.green.withOpacity(0.15);
      textColor = Colors.green[700]!;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            stockText,
            style: TextStyle(
              color: textColor,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}