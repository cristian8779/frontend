import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// Importaciones de servicios y widgets
import '../../services/producto_usuario_service.dart';
import '../../services/FavoritoService.dart';
import '../../services/Carrito_Service.dart';
import '../../services/HistorialService.dart';
import '../../services/ResenaService.dart';
import '../../providers/FavoritoProvider.dart';
import '../../providers/carrito_provider.dart';
import '../../models/request_models.dart';
import '/utils/colores.dart';
import '../../widgets/resena.dart';
import '../../theme/producto/index.dart';

class ProductoScreen extends StatefulWidget {
  final String productId;
  const ProductoScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> producto;
  late Future<List<Map<String, dynamic>>> variaciones;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Servicios
  final HistorialService _historialService = HistorialService();
  final ResenaService _resenaService = ResenaService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Controllers para scroll
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _descripcionKey = GlobalKey();
  final GlobalKey _especificacionesKey = GlobalKey();
  final GlobalKey _resenasKey = GlobalKey();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  // Estados de selección
  List<String> coloresSeleccionados = [];
  List<String> tallasSeleccionadas = [];
  bool _isLoggedIn = false;
  bool _historialAgregado = false;
  int selectedImageIndex = 0;
  String? imagenActual;
  String? _cachedImage;
  
  // Estado para reseñas
  List<Map<String, dynamic>> _resenas = [];
  bool _cargandoResenas = false;

  // Helper para responsividad
  bool get _isTablet => MediaQuery.of(context).size.width >= 768;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;
  double get _screenWidth => MediaQuery.of(context).size.width;
  
  double get _horizontalPadding => _isDesktop 
      ? ProductoPadding.desktopHorizontal 
      : _isTablet 
          ? ProductoPadding.tabletHorizontal 
          : ProductoPadding.mobileHorizontal;

  String _formatearPrecio(double precio) {
    final formatter = NumberFormat('#,##0', 'es_CO');
    return '\$' + formatter.format(precio);
  }

  @override
  void initState() {
    super.initState();
    producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId);
    variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId);
    
    _animationController = AnimationController(
      duration: ProductoAnimations.fadeIn,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    _verificarEstadoInicial();
    _agregarAlHistorial();
    _cargarResenas();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarResenas() async {
    setState(() => _cargandoResenas = true);
    
    try {
      final resenas = await _resenaService.obtenerResenasPorProducto(widget.productId);
      setState(() {
        _resenas = resenas;
      });
    } catch (e) {
      print('Error al cargar reseñas: $e');
    } finally {
      setState(() => _cargandoResenas = false);
    }
  }

  Future<void> _verificarEstadoInicial() async {
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      
      if (token == null || token.isEmpty) {
        setState(() => _isLoggedIn = false);
        return;
      }

      setState(() => _isLoggedIn = true);

      if (mounted) {
        final favoritoProvider = Provider.of<FavoritoProvider>(context, listen: false);
        if (favoritoProvider.favoritos.isEmpty) {
          await favoritoProvider.cargarFavoritos();
        }
      }
    } catch (e) {
      print('ERROR en _verificarEstadoInicial: $e');
      setState(() => _isLoggedIn = false);
    }
  }

  void _mostrarImagenCompleta(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagenZoomScreen(imageUrl: imageUrl),
      ),
    );
  }

  Future<void> _agregarAlHistorial() async {
    if (_historialAgregado) return;
    
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) return;
      
      await _historialService.agregarAlHistorial(widget.productId);
      setState(() => _historialAgregado = true);
      
    } catch (e) {
      if (e.toString().contains('ya existe') || e.toString().contains('already exists')) {
        setState(() => _historialAgregado = true);
      }
    }
  }

  String _obtenerImagenActual(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    if (coloresSeleccionados.isEmpty) {
      final imagenBase = productData['imagen'] ?? '';
      _cachedImage = imagenBase;
      return imagenBase;
    }

    final colorSeleccionado = coloresSeleccionados.first;
    
    for (var variacion in variations) {
      if (variacion['color'] != null && 
          variacion['color']['hex'] == colorSeleccionado &&
          variacion['imagenes'] != null &&
          (variacion['imagenes'] as List).isNotEmpty) {
        final imagenes = variacion['imagenes'] as List;
        final nuevaImagen = imagenes[0]['url'] ?? imagenes[0]['urlImagen'] ?? productData['imagen'] ?? '';
        _cachedImage = nuevaImagen;
        return nuevaImagen;
      }
    }

    final imagenBase = productData['imagen'] ?? '';
    _cachedImage = imagenBase;
    return imagenBase;
  }

  int _obtenerStockActual(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    if (variations.isEmpty || (coloresSeleccionados.isEmpty && tallasSeleccionadas.isEmpty)) {
      return productData['stock'] ?? 0;
    }

    for (var variacion in variations) {
      bool colorCoincide = coloresSeleccionados.isEmpty || 
          (variacion['color'] != null && coloresSeleccionados.contains(variacion['color']['hex']));
      
      bool tallaCoincide = tallasSeleccionadas.isEmpty ||
          tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
          tallasSeleccionadas.contains(variacion['tallaLetra']?.toString());

      if (colorCoincide && tallaCoincide) {
        return variacion['stock'] ?? 0;
      }
    }

    return productData['stock'] ?? 0;
  }

  Widget _buildStockInfo(int stock) {
    Color stockColor;
    IconData stockIcon;
    String stockText;

    if (stock <= 0) {
      stockColor = ProductoColores.error;
      stockIcon = Icons.cancel_outlined;
      stockText = 'Sin stock';
    } else if (stock <= 5) {
      stockColor = ProductoColores.warning;
      stockIcon = Icons.warning_outlined;
      stockText = 'Últimas $stock unidades';
    } else if (stock <= 10) {
      stockColor = ProductoColores.warning;
      stockIcon = Icons.inventory_outlined;
      stockText = 'Pocas unidades ($stock disponibles)';
    } else {
      stockColor = ProductoColores.success;
      stockIcon = Icons.check_circle_outlined;
      stockText = 'Stock disponible ($stock unidades)';
    }

    return Row(
      children: [
        Icon(stockIcon, color: stockColor, size: 16),
        const SizedBox(width: ProductoSpacing.xs),
        Flexible(
          child: Text(
            stockText,
            style: TextStyle(
              color: stockColor,
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodySm,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleFavorito() async {
    if (!_isLoggedIn) {
      _mostrarDialogoLogin();
      return;
    }

    final favoritoProvider = Provider.of<FavoritoProvider>(context, listen: false);
    final esFavorito = favoritoProvider.esFavorito(widget.productId);

    try {
      if (esFavorito) {
        await favoritoProvider.eliminarFavorito(widget.productId);
        _mostrarSnackbar('Eliminado de favoritos', isSuccess: true);
      } else {
        await favoritoProvider.agregarFavorito(widget.productId);
        _mostrarSnackbar('Agregado a favoritos', isSuccess: true);
      }
    } catch (e) {
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      if (errorMessage.contains('token') || errorMessage.contains('acceso') || errorMessage.contains('unauthorized')) {
        _mostrarDialogoLogin();
      } else {
        _mostrarSnackbar('Error: $errorMessage', isSuccess: false);
      }
    }
  }

  void _mostrarDialogoLogin() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ProductoBorderRadius.sm)),
          contentPadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(ProductoSpacing.lg),
            child: Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: _isDesktop ? ProductoFontSizes.desktopHeadingMd : ProductoFontSizes.mobileHeadingMd,
                fontWeight: FontWeight.w600,
                color: ProductoColores.textDark,
              ),
            ),
          ),
          content: Container(
            padding: const EdgeInsets.fromLTRB(ProductoSpacing.lg, 0, ProductoSpacing.lg, ProductoSpacing.lg),
            child: Text(
              'Para agregar productos a favoritos necesitas iniciar sesión en tu cuenta.',
              style: TextStyle(
                fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
                color: ProductoColores.textMedium,
                height: 1.4,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(ProductoSpacing.lg),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ahora no', style: TextStyle(color: ProductoColores.primary)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ProductoColores.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Iniciar sesión'),
            ),
          ],
        );
      },
    );
  }

  void _mostrarSnackbar(String mensaje, {required bool isSuccess}) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: isSuccess ? ProductoColores.success : ProductoColores.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            margin: const EdgeInsets.all(ProductoSpacing.lg),
          ),
        );
      } catch (e) {
        print('Error mostrando SnackBar: $e');
      }
    });
  }

  void _mostrarSnackbarConBotonCarrito(String mensaje) {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: ProductoSpacing.md),
                Expanded(child: Text(mensaje)),
              ],
            ),
            backgroundColor: ProductoColores.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            margin: const EdgeInsets.all(ProductoSpacing.lg),
            action: SnackBarAction(
              label: 'Ir al carrito',
              textColor: Colors.white,
              onPressed: () {
                if (mounted) Navigator.pushNamed(context, '/cart');
              },
            ),
          ),
        );
      } catch (e) {
        print('Error mostrando SnackBar: $e');
      }
    });
  }

  List<Map<String, String>> _extraerColoresDisponibles(List<Map<String, dynamic>> variations) {
    final Set<Map<String, String>> coloresSet = {};
    for (var variacion in variations) {
      if (variacion['color'] != null && variacion['color'] is Map) {
        final color = variacion['color'] as Map<String, dynamic>;
        if (color['nombre'] != null && color['hex'] != null) {
          coloresSet.add({
            'nombre': color['nombre'].toString(),
            'hex': color['hex'].toString(),
          });
        }
      }
    }
    return coloresSet.toList();
  }

  double _calcularPrecioSeleccion(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    if (variations.isEmpty || (coloresSeleccionados.isEmpty && tallasSeleccionadas.isEmpty)) {
      return double.tryParse(productData['precio'].toString()) ?? 0.0;
    }

    for (var variacion in variations) {
      bool colorCoincide = coloresSeleccionados.isEmpty || 
          (variacion['color'] != null && coloresSeleccionados.contains(variacion['color']['hex']));
      bool tallaCoincide = tallasSeleccionadas.isEmpty ||
          tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
          tallasSeleccionadas.contains(variacion['tallaLetra']?.toString());

      if (colorCoincide && tallaCoincide) {
        return double.tryParse(variacion['precio'].toString()) ?? 
               double.tryParse(productData['precio'].toString()) ?? 0.0;
      }
    }
    return double.tryParse(productData['precio'].toString()) ?? 0.0;
  }

  Map<String, dynamic>? _obtenerVariacionSeleccionada(List<Map<String, dynamic>> variations) {
    if (variations.isEmpty || (coloresSeleccionados.isEmpty && tallasSeleccionadas.isEmpty)) {
      return null;
    }

    for (var variacion in variations) {
      bool colorCoincide = coloresSeleccionados.isEmpty || 
          (variacion['color'] != null && coloresSeleccionados.contains(variacion['color']['hex']));
      bool tallaCoincide = tallasSeleccionadas.isEmpty ||
          tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
          tallasSeleccionadas.contains(variacion['tallaLetra']?.toString());

      if (colorCoincide && tallaCoincide) {
        return variacion;
      }
    }
    return null;
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) async {
    if (!_isLoggedIn) {
      _mostrarDialogoLogin();
      return;
    }

    final stockActual = _obtenerStockActual(productData, variations);
    if (stockActual <= 0) {
      _mostrarSnackbar('Producto sin stock disponible', isSuccess: false);
      return;
    }

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        _mostrarDialogoLogin();
        return;
      }

      final carritoProvider = Provider.of<CarritoProvider>(context, listen: false);
      if (carritoProvider.items.isEmpty) {
        await carritoProvider.obtenerCarrito(token);
      }
      
      final variacionSeleccionada = _obtenerVariacionSeleccionada(variations);
      final String? variacionId = variacionSeleccionada != null 
          ? (variacionSeleccionada['_id'] ?? variacionSeleccionada['id']) 
          : null;
      
      final yaExiste = carritoProvider.tieneProducto(widget.productId, variacionId: variacionId);
      final cantidadActual = carritoProvider.obtenerCantidadProducto(widget.productId, variacionId: variacionId);

      bool exito = false;

      if (yaExiste) {
        final nuevaCantidad = cantidadActual + 1;
        if (nuevaCantidad > stockActual) {
          _mostrarSnackbar('No hay suficiente stock disponible', isSuccess: false);
          return;
        }
        
        exito = await carritoProvider.actualizarCantidadConVariacion(
          token, widget.productId, nuevaCantidad,
          variacionId: variacionId,
        );
        
        if (exito && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          _mostrarSnackbarConBotonCarrito('Cantidad actualizada a $nuevaCantidad unidades');
        }
      } else {
        if (variacionSeleccionada != null) {
          final request = AgregarAlCarritoRequest(
            productoId: widget.productId,
            cantidad: 1,
            variacionId: variacionId,
          );
          exito = await carritoProvider.agregarProductoCompleto(token, request);
        } else {
          exito = await carritoProvider.agregarProducto(token, widget.productId, 1);
        }

        if (exito && mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          _mostrarSnackbarConBotonCarrito('Producto agregado al carrito');
          if (mounted) {
            setState(() {
              coloresSeleccionados.clear();
              tallasSeleccionadas.clear();
            });
          }
        }
      }

      if (!exito && mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        _mostrarSnackbar(carritoProvider.error ?? 'Error al procesar la operación', isSuccess: false);
      }

    } catch (e) {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        _mostrarSnackbar('Error: ${e.toString()}', isSuccess: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktop) {
      return _buildDesktopLayout();
    } else {
      return _buildMobileLayout();
    }
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ProductoColores.backgroundGray,
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: ProductoColores.textMedium),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Consumer<FavoritoProvider>(
          builder: (context, favoritoProvider, child) {
            final esFavorito = favoritoProvider.esFavorito(widget.productId);
            final isLoading = favoritoProvider.isLoading;

            if (isLoading) {
              return const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            return IconButton(
              icon: Icon(
                esFavorito ? Icons.favorite : Icons.favorite_border,
                color: esFavorito ? ProductoColores.error : ProductoColores.textMedium,
              ),
              onPressed: _toggleFavorito,
            );
          },
        ),
      ],
    );
  }

  Widget _buildPurchaseButtons(Map<String, dynamic> productData, List<Map<String, dynamic>> variations, int stockActual) {
    final buttonHeight = _isDesktop 
        ? ProductoHeights.buttonDesktop 
        : _isTablet 
            ? ProductoHeights.buttonTablet 
            : ProductoHeights.buttonMobile;
    
    return Consumer<CarritoProvider>(
      builder: (context, carritoProvider, child) {
        final isLoading = carritoProvider.isAdding || carritoProvider.isUpdating;
        
        return SizedBox(
          width: double.infinity,
          height: buttonHeight,
          child: ElevatedButton(
            onPressed: (isLoading || stockActual <= 0) ? null : () => _agregarAlCarrito(productData, variations),
            style: ElevatedButton.styleFrom(
              backgroundColor: stockActual <= 0 ? Colors.grey : ProductoColores.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ProductoBorderRadius.sm)
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    stockActual <= 0 ? 'Sin stock' : 'Agregar al carrito',
                    style: TextStyle(
                      fontSize: _isDesktop ? ProductoFontSizes.desktopBodyLg : ProductoFontSizes.mobileBodyLg,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopLayout() {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: ProductoColores.background,
        appBar: _buildAppBar(),
        body: FutureBuilder(
          future: Future.wait([producto, variaciones]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            Map<String, dynamic> productData = snapshot.data![0];
            List<Map<String, dynamic>> variations = snapshot.data![1];
            
            final coloresDisponibles = _extraerColoresDisponibles(variations);
            final precioActual = _calcularPrecioSeleccion(productData, variations);

            return FadeTransition(
              opacity: _fadeAnimation,
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildImageSection(productData, variations),
                      ),
                      const SizedBox(width: ProductoSpacing.xxxl),
                      Expanded(
                        flex: 1,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: Column(
                            children: [
                              _buildProductInfo(productData, precioActual, coloresDisponibles, variations),
                              const SizedBox(height: ProductoSpacing.xxxl),
                              _buildAllSections(productData, variations),
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        backgroundColor: ProductoColores.background,
        appBar: _buildAppBar(),
        body: FutureBuilder(
          future: Future.wait([producto, variaciones]),
          builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingState();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            Map<String, dynamic> productData = snapshot.data![0];
            List<Map<String, dynamic>> variations = snapshot.data![1];
            
            final coloresDisponibles = _extraerColoresDisponibles(variations);
            final precioActual = _calcularPrecioSeleccion(productData, variations);

            return FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(productData, variations),
                    _buildProductInfo(productData, precioActual, coloresDisponibles, variations),
                    const SizedBox(height: ProductoSpacing.lg),
                    _buildAllSections(productData, variations),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(ProductoColores.primary),
          ),
          const SizedBox(height: ProductoSpacing.lg),
          Text(
            'Cargando producto...',
            style: TextStyle(
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodyLg : ProductoFontSizes.mobileBodyLg
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(_horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: _isDesktop ? 80 : 64, color: Colors.grey.shade400),
            const SizedBox(height: ProductoSpacing.lg),
            const Text('Ups! Algo salió mal', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: ProductoSpacing.md),
            const Text('No pudimos cargar este producto.', textAlign: TextAlign.center),
            const SizedBox(height: ProductoSpacing.xl),
            ElevatedButton(
              onPressed: () => setState(() {
                producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId);
                variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId);
              }),
              style: ElevatedButton.styleFrom(backgroundColor: ProductoColores.primary),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    final imagenMostrar = _obtenerImagenActual(productData, variations);
    final imageHeight = _isDesktop 
        ? ProductoHeights.imageDesktop 
        : _isTablet 
            ? ProductoHeights.imageTablet 
            : ProductoHeights.imageMobile;
    
    final imagenAMostrar = _cachedImage ?? imagenMostrar;
    
    return Container(
      height: imageHeight,
      width: double.infinity,
      color: ProductoColores.background,
      child: GestureDetector(
        onTap: () => _mostrarImagenCompleta(imagenAMostrar),
        child: Image.network(
          imagenAMostrar,
          key: ValueKey(imagenAMostrar),
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                valueColor: const AlwaysStoppedAnimation<Color>(ProductoColores.primary),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(Icons.image_not_supported_outlined, size: 64, color: Colors.grey.shade400),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> productData, double precioActual, 
                          List<Map<String, String>> coloresDisponibles, 
                          List<Map<String, dynamic>> variations) {
    final stockActual = _obtenerStockActual(productData, variations);
    
    return Container(
      color: ProductoColores.background,
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEstrellasSuperior(productData),
          const SizedBox(height: ProductoSpacing.md),
          Text(_formatearPrecio(precioActual), style: ProductoTextStyles.headingXLDesktop),
          const SizedBox(height: ProductoSpacing.lg),
          Text(
            productData['nombre'],
            style: _isDesktop ? ProductoTextStyles.headingLgDesktop : ProductoTextStyles.headingLgMobile,
          ),
          const SizedBox(height: ProductoSpacing.xl),
          if (variations.isNotEmpty) ...[
            _buildVariationSelectors(coloresDisponibles, variations),
            const SizedBox(height: ProductoSpacing.xl),
          ],
          _buildStockInfo(stockActual),
          const SizedBox(height: ProductoSpacing.xxl),
          _buildPurchaseButtons(productData, variations, stockActual),
        ],
      ),
    );
  }

  Widget _buildEstrellasSuperior(Map<String, dynamic> productData) {
    if (_resenas.isEmpty) return const SizedBox.shrink();
    
    final promedio = _calcularPromedioCalificacion();
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: ProductoSpacing.md, horizontal: ProductoSpacing.md),
      decoration: BoxDecoration(
        color: ProductoColores.ratingBackground,
        borderRadius: BorderRadius.circular(ProductoBorderRadius.sm),
        border: Border.all(color: ProductoColores.ratingBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < promedio.round() ? Icons.star : Icons.star_border,
                color: ProductoColores.starColor,
                size: _isDesktop ? 18 : 16,
              );
            }),
          ),
          const SizedBox(width: ProductoSpacing.md),
          Text(
            promedio.toStringAsFixed(1),
            style: TextStyle(
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
              fontWeight: FontWeight.w600,
              color: ProductoColores.textDark,
            ),
          ),
          const SizedBox(width: ProductoSpacing.xs),
          Text(
            '(${_resenas.length})',
            style: TextStyle(
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodySm : ProductoFontSizes.mobileLabelSm,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVariationSelectors(List<Map<String, String>> coloresDisponibles, List<Map<String, dynamic>> variations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coloresDisponibles.isNotEmpty) ...[
          Text(
            'Color:',
            style: TextStyle(
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: ProductoSpacing.md),
          _buildColorSelector(coloresDisponibles),
          const SizedBox(height: ProductoSpacing.xl),
        ],
        if (_tieneVariacionesDeTalla(variations)) ...[
          Text(
            'Talle:',
            style: TextStyle(
              fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: ProductoSpacing.md),
          _buildSizeSelector(variations),
        ],
      ],
    );
  }

  bool _tieneVariacionesDeTalla(List<Map<String, dynamic>> variations) {
    return variations.any((v) => 
      (v['tallaNumero'] != null && v['tallaNumero'].toString().trim().isNotEmpty) ||
      (v['tallaLetra'] != null && v['tallaLetra'].toString().trim().isNotEmpty)
    );
  }

  Widget _buildColorSelector(List<Map<String, String>> coloresDisponibles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (coloresSeleccionados.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: ProductoSpacing.md),
            child: Text(
              coloresDisponibles.firstWhere(
                (c) => c['hex'] == coloresSeleccionados.first,
                orElse: () => {'nombre': ''}
              )['nombre']!,
              style: TextStyle(
                fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
                fontWeight: FontWeight.w400,
                color: ProductoColores.textDark,
              ),
            ),
          ),
        Wrap(
          spacing: ProductoSpacing.sm,
          runSpacing: ProductoSpacing.sm,
          children: coloresDisponibles.map((colorData) {
            final hex = colorData['hex']!;
            final nombre = colorData['nombre']!;
            final color = Colores.hexToColor(hex);
            final seleccionado = coloresSeleccionados.contains(hex);

            return Tooltip(
              message: nombre,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (seleccionado) {
                      coloresSeleccionados.clear();
                      _cachedImage = null;
                    } else {
                      coloresSeleccionados.clear();
                      coloresSeleccionados.add(hex);
                    }
                  });
                },
                child: Container(
                  width: ProductoHeights.colorSelectorSize,
                  height: ProductoHeights.colorSelectorSize,
                  decoration: BoxDecoration(
                    color: ProductoColores.background,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: seleccionado ? ProductoColores.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                      boxShadow: [ProductoShadows.small],
                    ),
                    child: seleccionado
                        ? Icon(Icons.check, color: _getContrastColor(color), size: 20)
                        : null,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildSizeSelector(List<Map<String, dynamic>> variations) {
    final tallas = <String>{};
    
    for (var v in variations) {
      if (v['tallaNumero'] != null && v['tallaNumero'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaNumero'].toString().trim());
      }
      if (v['tallaLetra'] != null && v['tallaLetra'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaLetra'].toString().trim());
      }
    }

    if (tallas.isEmpty) return const SizedBox.shrink();

    final tallasList = tallas.toList()..sort();

    return Wrap(
      spacing: ProductoSpacing.sm,
      children: tallasList.map((talla) {
        final seleccionado = tallasSeleccionadas.contains(talla);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (seleccionado) {
                tallasSeleccionadas.clear();
              } else {
                tallasSeleccionadas.clear();
                tallasSeleccionadas.add(talla);
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: ProductoSpacing.lg, vertical: ProductoSpacing.md),
            decoration: BoxDecoration(
              color: seleccionado ? ProductoColores.primary : ProductoColores.background,
              border: Border.all(
                color: seleccionado ? ProductoColores.primary : ProductoColores.borderDark,
              ),
              borderRadius: BorderRadius.circular(ProductoBorderRadius.sm),
            ),
            child: Text(
              talla,
              style: TextStyle(
                color: seleccionado ? Colors.white : ProductoColores.textDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAllSections(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return Column(
      children: [
        Container(height: ProductoSpacing.lg, color: ProductoColores.backgroundGray),
        
        Container(
          key: _descripcionKey,
          width: double.infinity,
          padding: EdgeInsets.all(_horizontalPadding),
          color: ProductoColores.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Descripción', style: _isDesktop ? ProductoTextStyles.headingMdDesktop : ProductoTextStyles.headingMdMobile),
              const SizedBox(height: ProductoSpacing.lg),
              Text(
                productData['descripcion'] ?? 'Sin descripción disponible.',
                style: _isDesktop ? ProductoTextStyles.bodyLgDesktop : ProductoTextStyles.bodyLgMobile,
              ),
            ],
          ),
        ),
        
        Container(height: ProductoSpacing.lg, color: ProductoColores.backgroundGray),
        
        Container(
          key: _especificacionesKey,
          width: double.infinity,
          padding: EdgeInsets.all(_horizontalPadding),
          color: ProductoColores.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Características principales', style: _isDesktop ? ProductoTextStyles.headingMdDesktop : ProductoTextStyles.headingMdMobile),
              const SizedBox(height: ProductoSpacing.lg),
              _buildSpecItem('Producto', productData['nombre']),
              _buildSpecItem('Stock total', (productData['stock'] ?? 0).toString()),
              if (variations.isNotEmpty && _extraerColoresDisponibles(variations).isNotEmpty)
                _buildSpecItem('Colores disponibles', _extraerColoresDisponibles(variations).map((c) => c['nombre']).join(', ')),
            ],
          ),
        ),
        
        Container(height: ProductoSpacing.lg, color: ProductoColores.backgroundGray),
        
        Container(
          key: _resenasKey,
          width: double.infinity,
          color: ProductoColores.background,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.all(_horizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Opiniones del producto', style: _isDesktop ? ProductoTextStyles.headingMdDesktop : ProductoTextStyles.headingMdMobile),
                        TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ResenaWidget(
                                productoId: widget.productId,
                                nombreProducto: productData['nombre'] ?? 'Producto',
                              ),
                            )).then((_) => _cargarResenas());
                          },
                          child: const Text('Ver todas', style: TextStyle(color: ProductoColores.primary, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: ProductoSpacing.lg),
                    _buildResumenCalificacion(),
                  ],
                ),
              ),
              
              const SizedBox(height: ProductoSpacing.lg),
              
              if (_cargandoResenas)
                Padding(
                  padding: EdgeInsets.all(_horizontalPadding),
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(ProductoColores.primary))),
                )
              else if (_resenas.isEmpty)
                _buildEmptyResenas()
              else
                Column(
                  children: [
                    ..._resenas.take(2).map((resena) => _buildResenaCompacta(resena)).toList(),
                    if (_resenas.length > 2)
                      Padding(
                        padding: EdgeInsets.all(_horizontalPadding),
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                              builder: (context) => ResenaWidget(
                                productoId: widget.productId,
                                nombreProducto: productData['nombre'] ?? 'Producto',
                              ),
                            )).then((_) => _cargarResenas());
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ProductoColores.primary,
                            side: const BorderSide(color: ProductoColores.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ProductoBorderRadius.sm)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                          child: Text('Ver las ${_resenas.length} opiniones'),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ProductoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 140, child: Text('$label:', style: const TextStyle(color: ProductoColores.textLight))),
          Expanded(child: Text(value, style: const TextStyle(color: ProductoColores.textDark))),
        ],
      ),
    );
  }

  Widget _buildResumenCalificacion() {
    if (_resenas.isEmpty) return const SizedBox.shrink();
    final promedio = _calcularPromedioCalificacion();
    
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(promedio.toStringAsFixed(1), style: TextStyle(fontSize: _isDesktop ? 48 : 40, fontWeight: FontWeight.w300, height: 1)),
            const SizedBox(height: ProductoSpacing.xs),
            Row(
              children: List.generate(5, (index) {
                return Icon(index < promedio.round() ? Icons.star : Icons.star_border, color: ProductoColores.starColor, size: 16);
              }),
            ),
            const SizedBox(height: ProductoSpacing.xs),
            Text('${_resenas.length} opinión${_resenas.length != 1 ? 'es' : ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        const SizedBox(width: ProductoSpacing.xxl),
        Expanded(child: _buildDistribucionEstrellas()),
      ],
    );
  }

  Widget _buildDistribucionEstrellas() {
    final distribucion = _calcularDistribucionEstrellas();
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = distribucion[stars] ?? 0;
        final percentage = _resenas.isEmpty ? 0.0 : (count / _resenas.length);
        
        return Padding(
          padding: const EdgeInsets.only(bottom: ProductoSpacing.xs),
          child: Row(
            children: [
              Text('$stars', style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
              const SizedBox(width: ProductoSpacing.xs),
              Icon(Icons.star, size: 12, color: Colors.grey.shade400),
              const SizedBox(width: ProductoSpacing.md),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(ProductoColores.starColor),
                    minHeight: 5,
                  ),
                ),
              ),
              const SizedBox(width: ProductoSpacing.md),
              SizedBox(width: 24, child: Text('$count', style: TextStyle(fontSize: 11, color: Colors.grey.shade600), textAlign: TextAlign.right)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildResenaCompacta(Map<String, dynamic> resena) {
    final calificacion = resena['calificacion'] ?? 0;
    final comentario = resena['comentario'] ?? '';
    final fecha = resena['fecha'] ?? resena['fechaCreacion'] ?? resena['createdAt'] ?? '';
    
    final usuarioData = resena['usuario'];
    String usuario = 'Usuario anónimo';
    String imagenPerfil = '';
    
    if (usuarioData is Map) {
      usuario = usuarioData['nombre'] ?? 'Usuario anónimo';
      imagenPerfil = usuarioData['imagenPerfil'] ?? '';
    } else if (usuarioData is String) {
      usuario = resena['usuarioNombre'] ?? 'Usuario anónimo';
    }
    
    return Container(
      margin: EdgeInsets.only(left: _horizontalPadding, right: _horizontalPadding, bottom: ProductoSpacing.lg),
      padding: EdgeInsets.all(_isDesktop ? ProductoSpacing.lg : ProductoSpacing.md),
      decoration: BoxDecoration(
        color: ProductoColores.background,
        border: Border.all(color: ProductoColores.borderColor),
        borderRadius: BorderRadius.circular(ProductoBorderRadius.md),
        boxShadow: [ProductoShadows.small],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              imagenPerfil.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(ProductoBorderRadius.lg),
                      child: Image.network(
                        imagenPerfil,
                        width: _isDesktop ? 40 : 36,
                        height: _isDesktop ? 40 : 36,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return CircleAvatar(
                            radius: _isDesktop ? 20 : 18,
                            backgroundColor: ProductoColores.primaryLight,
                            child: Text(usuario.isNotEmpty ? usuario[0].toUpperCase() : 'U', style: TextStyle(color: ProductoColores.primary, fontWeight: FontWeight.bold, fontSize: _isDesktop ? 16 : 14)),
                          );
                        },
                      ),
                    )
                  : CircleAvatar(
                      radius: _isDesktop ? 20 : 18,
                      backgroundColor: ProductoColores.primaryLight,
                      child: Text(
                        usuario.isNotEmpty ? usuario[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: ProductoColores.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: _isDesktop ? 16 : 14,
                        ),
                      ),
                    ),
              const SizedBox(width: ProductoSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
                        color: ProductoColores.textDark,
                      ),
                    ),
                    const SizedBox(height: ProductoSpacing.xs),
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 12, color: Colors.green.shade600),
                        const SizedBox(width: ProductoSpacing.xs),
                        Text(
                          'Compra verificada',
                          style: TextStyle(
                            fontSize: _isDesktop ? ProductoFontSizes.desktopLabelSm : ProductoFontSizes.mobileLabelSm,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (fecha.isNotEmpty)
                Text(
                  _formatearFecha(fecha),
                  style: TextStyle(
                    fontSize: _isDesktop ? ProductoFontSizes.desktopLabelSm : ProductoFontSizes.mobileLabelSm,
                    color: Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const SizedBox(height: ProductoSpacing.md),
          
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < calificacion ? Icons.star : Icons.star_border,
                    color: ProductoColores.starColor,
                    size: _isDesktop ? 16 : 14,
                  );
                }),
              ),
              const SizedBox(width: ProductoSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: ProductoSpacing.md, vertical: ProductoSpacing.xs),
                decoration: BoxDecoration(
                  color: calificacion >= 4
                      ? Colors.green.shade50
                      : calificacion >= 3
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(ProductoBorderRadius.sm),
                  border: Border.all(
                    color: calificacion >= 4
                        ? Colors.green.shade200
                        : calificacion >= 3
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                    width: 1,
                  ),
                ),
                child: Text(
                  calificacion >= 4
                      ? 'Excelente'
                      : calificacion >= 3
                          ? 'Bueno'
                          : 'Regular',
                  style: TextStyle(
                    fontSize: _isDesktop ? ProductoFontSizes.desktopLabelSm : ProductoFontSizes.mobileLabelSm,
                    fontWeight: FontWeight.w600,
                    color: calificacion >= 4
                        ? Colors.green.shade700
                        : calificacion >= 3
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: ProductoSpacing.md),
            Text(
              comentario,
              style: TextStyle(
                fontSize: _isDesktop ? ProductoFontSizes.desktopBodyMd : ProductoFontSizes.mobileBodyMd,
                height: 1.6,
                color: ProductoColores.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyResenas() {
    return Padding(
      padding: EdgeInsets.all(_horizontalPadding),
      child: Container(
        padding: const EdgeInsets.all(ProductoSpacing.xxxl),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(ProductoBorderRadius.md),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: ProductoSpacing.md),
            Text(
              'Todavía no hay opiniones',
              style: TextStyle(
                fontSize: ProductoFontSizes.desktopBodyMd,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: ProductoSpacing.md),
            Text(
              _isLoggedIn
                  ? 'Sé el primero en opinar sobre este producto'
                  : 'Iniciá sesión para escribir tu opinión',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: ProductoFontSizes.desktopBodySm,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calcularPromedioCalificacion() {
    if (_resenas.isEmpty) return 0.0;
    final suma = _resenas.fold<double>(0.0, (sum, resena) => sum + (resena['calificacion']?.toDouble() ?? 0.0));
    return suma / _resenas.length;
  }

  Map<int, int> _calcularDistribucionEstrellas() {
    final distribucion = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var resena in _resenas) {
      final cal = resena['calificacion'] ?? 0;
      if (cal >= 1 && cal <= 5) {
        distribucion[cal] = (distribucion[cal] ?? 0) + 1;
      }
    }
    return distribucion;
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) return 'Hoy';
      if (difference.inDays == 1) return 'Ayer';
      if (difference.inDays < 30) return 'Hace ${difference.inDays} días';
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}


class ImagenZoomScreen extends StatefulWidget {
  final String imageUrl;
  
  const ImagenZoomScreen({required this.imageUrl, Key? key}) : super(key: key);

  @override
  State<ImagenZoomScreen> createState() => _ImagenZoomScreenState();
}

class _ImagenZoomScreenState extends State<ImagenZoomScreen> with TickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: ProductoAnimations.zoomTransition,
    )..addListener(() {
        _transformationController.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    final position = _doubleTapDetails!.localPosition;
    final double scale = _transformationController.value.getMaxScaleOnAxis();

    Matrix4 matrix;
    
    if (scale > 1.0) {
      matrix = Matrix4.identity();
    } else {
      final double newScale = 3.0;
      final double x = -position.dx * (newScale - 1);
      final double y = -position.dy * (newScale - 1);
      matrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(newScale);
    }

    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: matrix,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward(from: 0);
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Cerrar',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.zoom_out_map, color: Colors.white, size: 24),
            onPressed: _resetZoom,
            tooltip: 'Restablecer zoom',
          ),
        ],
      ),
      body: GestureDetector(
        onDoubleTapDown: _handleDoubleTapDown,
        onDoubleTap: _handleDoubleTap,
        child: Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              clipBehavior: Clip.none,
              boundaryMargin: const EdgeInsets.all(double.infinity),
              child: Center(
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                          const SizedBox(height: ProductoSpacing.lg),
                          Text(
                            loadingProgress.expectedTotalBytes != null
                                ? '${(loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! * 100).toStringAsFixed(0)}%'
                                : 'Cargando...',
                            style: const TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image_not_supported_outlined, size: 80, color: Colors.white.withOpacity(0.5)),
                          const SizedBox(height: ProductoSpacing.lg),
                          const Text('No se pudo cargar la imagen', style: TextStyle(color: Colors.white70, fontSize: 16)),
                          const SizedBox(height: ProductoSpacing.xxl),
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back),
                            label: const Text('Volver'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ProductoColores.primary,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: ProductoSpacing.xl, vertical: ProductoSpacing.md),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(ProductoBorderRadius.lg),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: Colors.white.withOpacity(0.9), size: 18),
                      const SizedBox(width: ProductoSpacing.md),
                      Text(
                        'Toca dos veces para hacer zoom',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}