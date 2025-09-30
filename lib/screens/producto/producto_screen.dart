import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';

// Importaciones de servicios y widgets
import '../../services/producto_usuario_service.dart';
import '../../services/FavoritoService.dart';
import '../../services/Carrito_Service.dart';
import '../../services/HistorialService.dart';  // 📝 NUEVA IMPORTACIÓN
import '../../models/request_models.dart';
import '/utils/colores.dart';
import '../../widgets/resena.dart';  // 📝 IMPORTAR WIDGET DE RESEÑAS

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
  final FavoritoService _favoritoService = FavoritoService();
  final CarritoService _carritoService = CarritoService();
  final HistorialService _historialService = HistorialService();  // 📝 NUEVO SERVICIO
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Estados de selección
  List<String> coloresSeleccionados = [];
  List<String> tallasSeleccionadas = [];
  bool isFavorite = false;
  bool _isLoadingFavorite = true;
  bool _isLoggedIn = false;
  bool _isLoadingCarrito = false;
  bool _historialAgregado = false;  // 📝 NUEVO ESTADO para evitar duplicados
  int selectedImageIndex = 0;
  String currentTab = 'descripcion';
  String? imagenActual;

  // Helper para responsividad
  bool get _isTablet => MediaQuery.of(context).size.width >= 768;
  bool get _isDesktop => MediaQuery.of(context).size.width >= 1024;
  double get _screenWidth => MediaQuery.of(context).size.width;
  double get _horizontalPadding => _isDesktop ? 32.0 : _isTablet ? 24.0 : 16.0;

  // Formatear precio en pesos colombianos
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    _verificarEstadoFavorito();
    _agregarAlHistorial();  // 📝 NUEVA LLAMADA
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // 📝 NUEVO MÉTODO para mostrar imagen en pantalla completa con zoom
  void _mostrarImagenCompleta(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ImagenZoomScreen(imageUrl: imageUrl),
      ),
    );
  }

  // 📝 NUEVO MÉTODO para agregar al historial
  Future<void> _agregarAlHistorial() async {
    // Solo agregar si no se ha agregado ya y si hay token
    if (_historialAgregado) return;
    
    try {
      final token = await _secureStorage.read(key: 'accessToken');
      
      // Solo agregar al historial si el usuario está logueado
      if (token == null || token.isEmpty) {
        print('DEBUG - Usuario no logueado, no se agrega al historial');
        return;
      }

      print('DEBUG - Agregando producto ${widget.productId} al historial');
      
      await _historialService.agregarAlHistorial(widget.productId);
      
      setState(() {
        _historialAgregado = true;
      });
      
      print('DEBUG - Producto agregado al historial exitosamente');
      
    } catch (e) {
      // No mostrar error al usuario, solo logear
      print('DEBUG - Error al agregar al historial (no crítico): $e');
      
      // Si el error es por producto ya existente, marcar como agregado
      if (e.toString().contains('ya existe') || e.toString().contains('already exists')) {
        setState(() {
          _historialAgregado = true;
        });
      }
    }
  }

  String _obtenerImagenActual(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    if (coloresSeleccionados.isEmpty) {
      return productData['imagen'] ?? '';
    }

    final colorSeleccionado = coloresSeleccionados.first;
    
    for (var variacion in variations) {
      if (variacion['color'] != null && 
          variacion['color']['hex'] == colorSeleccionado &&
          variacion['imagenes'] != null &&
          (variacion['imagenes'] as List).isNotEmpty) {
        final imagenes = variacion['imagenes'] as List;
        return imagenes[0]['url'] ?? imagenes[0]['urlImagen'] ?? productData['imagen'] ?? '';
      }
    }

    return productData['imagen'] ?? '';
  }

  // Método para obtener el stock actual basado en la selección
  int _obtenerStockActual(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    // Si no hay variaciones o no hay selección, retornar stock base del producto
    if (variations.isEmpty || (coloresSeleccionados.isEmpty && tallasSeleccionadas.isEmpty)) {
      return productData['stock'] ?? 0;
    }

    // Buscar la variación que coincida con la selección
    for (var variacion in variations) {
      bool colorCoincide = coloresSeleccionados.isEmpty || 
          (variacion['color'] != null && 
           coloresSeleccionados.contains(variacion['color']['hex']));
      
      bool tallaCoincide = tallasSeleccionadas.isEmpty ||
          tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
          tallasSeleccionadas.contains(variacion['tallaLetra']?.toString());

      if (colorCoincide && tallaCoincide) {
        return variacion['stock'] ?? 0;
      }
    }

    // Si hay selección pero no se encuentra variación específica, 
    // calcular el stock mínimo de las variaciones que coincidan parcialmente
    int stockMinimo = productData['stock'] ?? 0;
    bool encontroCoincidencia = false;

    for (var variacion in variations) {
      bool tieneCoincidencia = false;

      if (coloresSeleccionados.isNotEmpty && variacion['color'] != null) {
        if (coloresSeleccionados.contains(variacion['color']['hex'])) {
          tieneCoincidencia = true;
        }
      }

      if (tallasSeleccionadas.isNotEmpty) {
        if (tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
            tallasSeleccionadas.contains(variacion['tallaLetra']?.toString())) {
          tieneCoincidencia = true;
        }
      }

      if (tieneCoincidencia) {
        encontroCoincidencia = true;
        int stockVariacion = variacion['stock'] ?? 0;
        if (!encontroCoincidencia || stockVariacion < stockMinimo) {
          stockMinimo = stockVariacion;
        }
      }
    }

    return encontroCoincidencia ? stockMinimo : (productData['stock'] ?? 0);
  }

  // Widget para mostrar el estado del stock
  Widget _buildStockInfo(int stock) {
    Color stockColor;
    IconData stockIcon;
    String stockText;

    if (stock <= 0) {
      stockColor = const Color(0xFFE74C3C);
      stockIcon = Icons.cancel_outlined;
      stockText = 'Sin stock';
    } else if (stock <= 5) {
      stockColor = const Color(0xFFFF9500);
      stockIcon = Icons.warning_outlined;
      stockText = 'Últimas $stock unidades';
    } else if (stock <= 10) {
      stockColor = const Color(0xFFFF9500);
      stockIcon = Icons.inventory_outlined;
      stockText = 'Pocas unidades ($stock disponibles)';
    } else {
      stockColor = const Color(0xFF00A650);
      stockIcon = Icons.check_circle_outlined;
      stockText = 'Stock disponible ($stock unidades)';
    }

    return Row(
      children: [
        Icon(stockIcon, color: stockColor, size: 16),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            stockText,
            style: TextStyle(
              color: stockColor,
              fontSize: _isDesktop ? 14 : 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _verificarEstadoFavorito() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoggedIn = false;
          _isLoadingFavorite = false;
          isFavorite = false;
        });
        return;
      }

      setState(() {
        _isLoggedIn = true;
      });

      try {
        final favoritos = await _favoritoService.obtenerFavoritos();
        print('DEBUG - Verificando favoritos. Total: ${favoritos.length}');
        print('DEBUG - Buscando producto ID: ${widget.productId}');
        
        final esFavorito = favoritos.any((fav) {
          // Verificar múltiples posibles campos de ID
          final favoritoId = fav['productoId'] ?? fav['producto']?['_id'] ?? fav['producto']?['id'] ?? fav['id'];
          final match = favoritoId == widget.productId;
          print('DEBUG - Comparando: $favoritoId == ${widget.productId} = $match');
          return match;
        });
        
        print('DEBUG - Resultado final: esFavorito = $esFavorito');
        
        setState(() {
          isFavorite = esFavorito;
          _isLoadingFavorite = false;
        });
      } catch (e) {
        print('ERROR al verificar favoritos: $e');
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      print('ERROR en _verificarEstadoFavorito: $e');
      setState(() {
        _isLoggedIn = false;
        _isLoadingFavorite = false;
        isFavorite = false;
      });
    }
  }

  Future<void> _toggleFavorito() async {
    if (!_isLoggedIn) {
      _mostrarDialogoLogin();
      return;
    }

    // Prevenir múltiples clicks mientras está procesando
    if (_isLoadingFavorite) {
      return;
    }

    setState(() {
      _isLoadingFavorite = true;
    });

    // Guardar estado actual antes del toggle
    final estadoAnterior = isFavorite;
    
    try {
      print('DEBUG - Estado actual antes del toggle: isFavorite = $isFavorite');
      
      if (isFavorite) {
        // Eliminar de favoritos
        print('DEBUG - Intentando ELIMINAR de favoritos');
        await _favoritoService.eliminarFavorito(widget.productId);
        
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
        
        print('DEBUG - ELIMINADO exitosamente');
        _mostrarSnackbar('Eliminado de favoritos', isSuccess: true);
        
      } else {
        // Agregar a favoritos
        print('DEBUG - Intentando AGREGAR a favoritos');
        await _favoritoService.agregarFavorito(widget.productId);
        
        setState(() {
          isFavorite = true;
          _isLoadingFavorite = false;
        });
        
        print('DEBUG - AGREGADO exitosamente');
        _mostrarSnackbar('Agregado a favoritos', isSuccess: true);
      }
      
      print('DEBUG - Estado después del toggle: isFavorite = $isFavorite');
      
    } catch (e) {
      print('ERROR en toggle: $e');
      
      // Restaurar estado anterior en caso de error
      setState(() {
        isFavorite = estadoAnterior;
        _isLoadingFavorite = false;
      });
      
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Manejo específico de errores
      if (errorMessage.toLowerCase().contains('ya existe') || 
          errorMessage.toLowerCase().contains('already exists') ||
          errorMessage.toLowerCase().contains('duplicate')) {
        
        // Si el error dice que ya existe, significa que SÍ está en favoritos
        setState(() {
          isFavorite = true;
        });
        _mostrarSnackbar('Este producto ya está en favoritos', isSuccess: true);
        
      } else if (errorMessage.toLowerCase().contains('no encontrado') ||
                 errorMessage.toLowerCase().contains('not found')) {
        
        // Si no se encuentra, significa que NO está en favoritos
        setState(() {
          isFavorite = false;
        });
        _mostrarSnackbar('Producto eliminado de favoritos', isSuccess: true);
        
      } else if (errorMessage.contains('token') || 
                 errorMessage.contains('acceso') ||
                 errorMessage.contains('unauthorized')) {
        
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Iniciar sesión',
              style: TextStyle(
                fontSize: _isDesktop ? 22 : 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
          ),
          content: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Text(
              'Para agregar productos a favoritos necesitas iniciar sesión en tu cuenta.',
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 15,
                color: const Color(0xFF666666),
                height: 1.4,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              ),
              child: const Text(
                'Ahora no',
                style: TextStyle(
                  color: Color(0xFF3483FA),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3483FA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
              ),
              child: const Text(
                'Iniciar sesión',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _mostrarSnackbar(String mensaje, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: TextStyle(
            fontSize: _isDesktop ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: isSuccess ? const Color(0xFF00A650) : const Color(0xFFE74C3C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        duration: const Duration(seconds: 3),
        margin: EdgeInsets.all(_horizontalPadding),
      ),
    );
  }

  void _mostrarSnackbarConBotonCarrito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(
                  fontSize: _isDesktop ? 15 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00A650),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        duration: const Duration(seconds: 5),
        margin: EdgeInsets.all(_horizontalPadding),
        action: SnackBarAction(
          label: 'Ir al carrito',
          textColor: Colors.white,
          backgroundColor: Colors.white.withOpacity(0.2),
          onPressed: () {
            Navigator.pushNamed(context, '/cart');
          },
        ),
      ),
    );
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
          (variacion['color'] != null && 
           coloresSeleccionados.contains(variacion['color']['hex']));
      
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
          (variacion['color'] != null && 
           coloresSeleccionados.contains(variacion['color']['hex']));
      
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

    // Verificar stock antes de agregar al carrito
    final stockActual = _obtenerStockActual(productData, variations);
    if (stockActual <= 0) {
      _mostrarSnackbar('Producto sin stock disponible', isSuccess: false);
      return;
    }

    setState(() {
      _isLoadingCarrito = true;
    });

    try {
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        _mostrarDialogoLogin();
        return;
      }

      final variacionSeleccionada = _obtenerVariacionSeleccionada(variations);

      bool exito = false;

      if (variacionSeleccionada != null) {
        final request = AgregarAlCarritoRequest(
          productoId: widget.productId,
          cantidad: 1,
          variacionId: variacionSeleccionada['_id'] ?? variacionSeleccionada['id'],
        );
        
        exito = await _carritoService.agregarProductoCompleto(token, request);
      } else {
        exito = await _carritoService.agregarProducto(token, widget.productId, 1);
      }

      setState(() {
        _isLoadingCarrito = false;
      });

      if (exito) {
        String mensaje = variacionSeleccionada != null 
            ? 'Variación agregada al carrito'
            : 'Producto agregado al carrito';
        _mostrarSnackbarConBotonCarrito(mensaje);
        
        setState(() {
          coloresSeleccionados.clear();
          tallasSeleccionadas.clear();
        });
      } else {
        _mostrarSnackbar('Error al agregar al carrito', isSuccess: false);
      }

    } catch (e) {
      setState(() {
        _isLoadingCarrito = false;
      });

      String errorMessage = e.toString().replaceFirst('Exception: ', '');

      if (errorMessage.contains('token') ||
          errorMessage.contains('acceso') ||
          errorMessage.contains('Unauthorized')) {
        _mostrarDialogoLogin();
      } else if (errorMessage.contains('Producto no encontrado')) {
        _mostrarSnackbar('Producto no disponible. Verifica tu selección.', isSuccess: false);
      } else if (errorMessage.contains('Variación no encontrada')) {
        _mostrarSnackbar('Esta variación no está disponible.', isSuccess: false);
      } else {
        _mostrarSnackbar('Error: $errorMessage', isSuccess: false);
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

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    // Sección de imagen - 50%
                    Expanded(
                      flex: 1,
                      child: _buildImageSection(productData, variations),
                    ),
                    const SizedBox(width: 32),
                    // Sección de información - 50%
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                children: [
                                  _buildProductInfo(productData, precioActual, coloresDisponibles, variations),
                                  const SizedBox(height: 32),
                                  _buildTabSection(productData, variations),
                                  const SizedBox(height: 80),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
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
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildImageSection(productData, variations),
                        _buildProductInfo(productData, precioActual, coloresDisponibles, variations),
                        _buildTabSection(productData, variations),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF5F5F5),
      elevation: 1,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Color(0xFF666666)),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        _isLoadingFavorite
            ? Container(
                width: 48,
                height: 48,
                padding: const EdgeInsets.all(12),
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF666666)),
                ),
              )
            : IconButton(
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    key: ValueKey(isFavorite),
                    color: isFavorite ? const Color(0xFFE74C3C) : const Color(0xFF666666),
                  ),
                ),
                onPressed: _toggleFavorito,
              ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3483FA)),
            strokeWidth: _isDesktop ? 4 : 3,
          ),
          SizedBox(height: _isDesktop ? 20 : 16),
          Text(
            'Cargando producto...',
            style: TextStyle(
              fontSize: _isDesktop ? 18 : 16,
              color: const Color(0xFF666666),
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
            Icon(
              Icons.error_outline, 
              size: _isDesktop ? 80 : 64, 
              color: Colors.grey.shade400
            ),
            SizedBox(height: _isDesktop ? 20 : 16),
            Text(
              'Ups! Algo salió mal',
              style: TextStyle(
                fontSize: _isDesktop ? 24 : 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: _isDesktop ? 12 : 8),
            Text(
              'No pudimos cargar este producto. Revisá tu conexión e intentá de nuevo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: _isDesktop ? 18 : 16,
              ),
            ),
            SizedBox(height: _isDesktop ? 24 : 20),
            ElevatedButton(
              onPressed: () => setState(() {
                producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId);
                variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId);
              }),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3483FA),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                elevation: 0,
                padding: EdgeInsets.symmetric(
                  horizontal: _isDesktop ? 32 : 24,
                  vertical: _isDesktop ? 16 : 12,
                ),
              ),
              child: Text(
                'Reintentar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: _isDesktop ? 16 : 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    final imagenMostrar = _obtenerImagenActual(productData, variations);
    final imageHeight = _isDesktop ? 500.0 : _isTablet ? 450.0 : 400.0;
    
    return Container(
      height: imageHeight,
      width: double.infinity,
      color: Colors.white,
      child: Stack(
        children: [
          Center(
            child: GestureDetector(
              onTap: () => _mostrarImagenCompleta(imagenMostrar),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Image.network(
                  imagenMostrar,
                  key: ValueKey(imagenMostrar),
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      height: imageHeight,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3483FA)),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: imageHeight,
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: _isDesktop ? 64 : 48,
                              color: const Color(0xFFCCCCCC),
                            ),
                            SizedBox(height: _isDesktop ? 12 : 8),
                            Text(
                              'Imagen no disponible',
                              style: TextStyle(
                                color: const Color(0xFF999999),
                                fontSize: _isDesktop ? 16 : 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Indicador de tap para zoom
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: _isDesktop ? 20 : 16,
              ),
            ),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '1/1',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _isDesktop ? 13 : 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfo(Map<String, dynamic> productData, double precioActual, 
                          List<Map<String, String>> coloresDisponibles, 
                          List<Map<String, dynamic>> variations) {
    final precioBase = double.tryParse(productData['precio'].toString()) ?? 0.0;
    final stockActual = _obtenerStockActual(productData, variations);
    
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Precio
          Row(
            children: [
              Text(
                _formatearPrecio(precioActual),
                style: TextStyle(
                  fontSize: _isDesktop ? 36 : _isTablet ? 34 : 32,
                  fontWeight: FontWeight.w300,
                  color: const Color(0xFF333333),
                ),
              ),
              if (precioActual != precioBase) ...[
                const SizedBox(width: 8),
                Text(
                  _formatearPrecio(precioBase),
                  style: TextStyle(
                    fontSize: _isDesktop ? 20 : 18,
                    decoration: TextDecoration.lineThrough,
                    color: const Color(0xFF999999),
                  ),
                ),
              ],
            ],
          ),
          
          SizedBox(height: _isDesktop ? 16 : 12),
          
          // Nombre del producto
          Text(
            productData['nombre'],
            style: TextStyle(
              fontSize: _isDesktop ? 24 : _isTablet ? 22 : 20,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF333333),
              height: 1.2,
            ),
          ),
          
          SizedBox(height: _isDesktop ? 20 : 16),
          
          // Selectores de variaciones
          if (variations.isNotEmpty) ...[
            _buildVariationSelectors(coloresDisponibles, variations),
          ],
          
          SizedBox(height: _isDesktop ? 20 : 16),
          
          // Información de stock dinámico
          _buildStockInfo(stockActual),
          
          SizedBox(height: _isDesktop ? 24 : 20),
          
          // Botón de agregar al carrito
          _buildPurchaseButtons(productData, variations, stockActual),
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
            'Color: ${coloresSeleccionados.isEmpty ? "Elegir" : coloresDisponibles.firstWhere((c) => coloresSeleccionados.contains(c['hex']))['nombre']}',
            style: TextStyle(
              fontSize: _isDesktop ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: _isDesktop ? 12 : 8),
          _buildColorSelector(coloresDisponibles),
          SizedBox(height: _isDesktop ? 20 : 16),
        ],
        
        if (_tieneVariacionesDeTalla(variations)) ...[
          Text(
            'Talle: ${tallasSeleccionadas.isEmpty ? "Elegir" : tallasSeleccionadas.first}',
            style: TextStyle(
              fontSize: _isDesktop ? 16 : 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: _isDesktop ? 12 : 8),
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
    final colorSize = _isDesktop ? 44.0 : _isTablet ? 42.0 : 40.0;
    
    return Wrap(
      spacing: _isDesktop ? 12 : 8,
      runSpacing: _isDesktop ? 12 : 8,
      children: coloresDisponibles.map((colorData) {
        final hex = colorData['hex']!;
        final nombre = colorData['nombre']!;
        final color = Colores.hexToColor(hex);
        final seleccionado = coloresSeleccionados.contains(hex);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (seleccionado) {
                coloresSeleccionados.clear();
              } else {
                coloresSeleccionados.clear();
                coloresSeleccionados.add(hex);
              }
            });
          },
          child: Container(
            width: colorSize,
            height: colorSize,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(
                color: seleccionado ? const Color(0xFF3483FA) : const Color(0xFFDDDDDD),
                width: seleccionado ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: seleccionado 
                ? Icon(
                    Icons.check,
                    color: _getContrastColor(color),
                    size: _isDesktop ? 20 : 16,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  Widget _buildSizeSelector(List<Map<String, dynamic>> variations) {
    final tallas = <String>{};
    
    // Filtrar y obtener solo las tallas válidas
    for (var v in variations) {
      // Solo agregar tallas que no sean null ni vacías
      if (v['tallaNumero'] != null && v['tallaNumero'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaNumero'].toString().trim());
      }
      if (v['tallaLetra'] != null && v['tallaLetra'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaLetra'].toString().trim());
      }
    }

    // Si no hay tallas válidas, no mostrar nada
    if (tallas.isEmpty) {
      return const SizedBox.shrink();
    }

    // Convertir a lista y ordenar
    final tallasList = tallas.toList();
    tallasList.sort((a, b) {
      // Intentar ordenar numéricamente si son números
      final numA = int.tryParse(a);
      final numB = int.tryParse(b);
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      // Si no son números, ordenar alfabéticamente
      return a.compareTo(b);
    });

    return Wrap(
      spacing: _isDesktop ? 12 : 8,
      runSpacing: _isDesktop ? 12 : 8,
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
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 20 : 16, 
              vertical: _isDesktop ? 12 : 8,
            ),
            decoration: BoxDecoration(
              color: seleccionado ? const Color(0xFF3483FA) : Colors.white,
              border: Border.all(
                color: seleccionado ? const Color(0xFF3483FA) : const Color(0xFFDDDDDD),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              talla,
              style: TextStyle(
                color: seleccionado ? Colors.white : const Color(0xFF333333),
                fontWeight: FontWeight.w500,
                fontSize: _isDesktop ? 16 : 14,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPurchaseButtons(Map<String, dynamic> productData, List<Map<String, dynamic>> variations, int stockActual) {
    final buttonHeight = _isDesktop ? 56.0 : _isTablet ? 52.0 : 48.0;
    
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: ElevatedButton(
        onPressed: (_isLoadingCarrito || stockActual <= 0) ? null : () => _agregarAlCarrito(productData, variations),
        style: ElevatedButton.styleFrom(
          backgroundColor: stockActual <= 0 ? Colors.grey : const Color(0xFF3483FA),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: _isLoadingCarrito
            ? SizedBox(
                height: _isDesktop ? 24 : 20,
                width: _isDesktop ? 24 : 20,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                stockActual <= 0 ? 'Sin stock' : 'Agregar al carrito',
                style: TextStyle(
                  fontSize: _isDesktop ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Widget _buildTabSection(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Divisor
          Container(
            height: _isDesktop ? 12 : 8,
            color: const Color(0xFFF5F5F5),
          ),
          
          // Tabs
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildTabBar(),
                _buildTabContent(productData, variations),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentTab = 'descripcion'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: _isDesktop ? 20 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: currentTab == 'descripcion' 
                          ? const Color(0xFF3483FA) 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Descripción',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: currentTab == 'descripcion' 
                        ? const Color(0xFF3483FA) 
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentTab = 'especificaciones'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: _isDesktop ? 20 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: currentTab == 'especificaciones' 
                          ? const Color(0xFF3483FA) 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Características',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: currentTab == 'especificaciones' 
                        ? const Color(0xFF3483FA) 
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentTab = 'resenas'),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: _isDesktop ? 20 : 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: currentTab == 'resenas' 
                          ? const Color(0xFF3483FA) 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  'Reseñas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _isDesktop ? 16 : 14,
                    fontWeight: FontWeight.w600,
                    color: currentTab == 'resenas' 
                        ? const Color(0xFF3483FA) 
                        : const Color(0xFF666666),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: currentTab == 'descripcion'
          ? _buildDescription(productData)
          : currentTab == 'especificaciones'
              ? _buildSpecifications(productData, variations)
              : _buildResenas(productData),
    );
  }

  Widget _buildDescription(Map<String, dynamic> productData) {
    return Container(
      key: const ValueKey('descripcion'),
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Descripción',
            style: TextStyle(
              fontSize: _isDesktop ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: _isDesktop ? 16 : 12),
          Text(
            productData['descripcion'] ?? 'Sin descripción disponible.',
            style: TextStyle(
              fontSize: _isDesktop ? 16 : 14,
              height: 1.5,
              color: const Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResenas(Map<String, dynamic> productData) {
    return Container(
      key: const ValueKey('resenas'),
      width: double.infinity,
      height: 400, // Altura fija para el contenedor de reseñas
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(_horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reseñas del producto',
                  style: TextStyle(
                    fontSize: _isDesktop ? 20 : 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ResenaWidget(
                          productoId: widget.productId,
                          nombreProducto: productData['nombre'] ?? 'Producto',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: Color(0xFF3483FA),
                  ),
                  label: const Text(
                    'Ver todas',
                    style: TextStyle(
                      color: Color(0xFF3483FA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: _horizontalPadding),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rate_review_outlined,
                      size: _isDesktop ? 48 : 40,
                      color: const Color(0xFF3483FA),
                    ),
                    SizedBox(height: _isDesktop ? 16 : 12),
                    Text(
                      'Ver reseñas completas',
                      style: TextStyle(
                        fontSize: _isDesktop ? 16 : 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    SizedBox(height: _isDesktop ? 8 : 6),
                    Text(
                      'Toca "Ver todas" para leer y escribir reseñas',
                      style: TextStyle(
                        fontSize: _isDesktop ? 14 : 12,
                        color: const Color(0xFF666666),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecifications(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return Container(
      key: const ValueKey('especificaciones'),
      width: double.infinity,
      padding: EdgeInsets.all(_horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Características principales',
            style: TextStyle(
              fontSize: _isDesktop ? 20 : 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF333333),
            ),
          ),
          SizedBox(height: _isDesktop ? 16 : 12),
          _buildSpecItem('Producto', productData['nombre']),
          _buildSpecItem('Stock total', (productData['stock'] ?? 0).toString()),
          if (variations.isNotEmpty && _extraerColoresDisponibles(variations).isNotEmpty)
            _buildSpecItem('Colores disponibles', 
              _extraerColoresDisponibles(variations).map((c) => c['nombre']).join(', ')),
          if (variations.isNotEmpty && _tieneVariacionesDeTalla(variations)) ...[
            _buildSpecItem('Tallas disponibles', _obtenerTallasDisponibles(variations)),
          ],
          if (variations.isNotEmpty) ...[
            SizedBox(height: _isDesktop ? 12 : 8),
            Text(
              'Stock por variación:',
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
              ),
            ),
            SizedBox(height: _isDesktop ? 12 : 8),
            ...variations.map((variacion) => _buildVariationStockItem(variacion)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVariationStockItem(Map<String, dynamic> variacion) {
    String descripcion = '';
    
    if (variacion['color'] != null) {
      descripcion += variacion['color']['nombre'] ?? 'Color sin nombre';
    }
    
    if (variacion['tallaNumero'] != null) {
      descripcion += descripcion.isNotEmpty ? ' - Talla ${variacion['tallaNumero']}' : 'Talla ${variacion['tallaNumero']}';
    } else if (variacion['tallaLetra'] != null) {
      descripcion += descripcion.isNotEmpty ? ' - Talla ${variacion['tallaLetra']}' : 'Talla ${variacion['tallaLetra']}';
    }
    
    final stock = variacion['stock'] ?? 0;
    
    return Padding(
      padding: EdgeInsets.only(bottom: _isDesktop ? 12 : 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              descripcion.isEmpty ? 'Variación sin especificar' : descripcion,
              style: TextStyle(
                fontSize: _isDesktop ? 15 : 13,
                color: const Color(0xFF666666),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isDesktop ? 12 : 8, 
              vertical: _isDesktop ? 4 : 2,
            ),
            decoration: BoxDecoration(
              color: stock <= 0 ? Colors.red.shade50 : 
                     stock <= 5 ? Colors.orange.shade50 : Colors.green.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: stock <= 0 ? Colors.red.shade200 : 
                       stock <= 5 ? Colors.orange.shade200 : Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Text(
              '$stock unidades',
              style: TextStyle(
                fontSize: _isDesktop ? 14 : 12,
                fontWeight: FontWeight.w500,
                color: stock <= 0 ? Colors.red.shade700 : 
                       stock <= 5 ? Colors.orange.shade700 : Colors.green.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _obtenerTallasDisponibles(List<Map<String, dynamic>> variations) {
    final tallas = <String>{};
    for (var v in variations) {
      // Usar la misma lógica de filtrado que en _buildSizeSelector
      if (v['tallaNumero'] != null && v['tallaNumero'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaNumero'].toString().trim());
      }
      if (v['tallaLetra'] != null && v['tallaLetra'].toString().trim().isNotEmpty) {
        tallas.add(v['tallaLetra'].toString().trim());
      }
    }
    
    if (tallas.isEmpty) {
      return 'No disponibles';
    }
    
    final tallasList = tallas.toList();
    tallasList.sort((a, b) {
      final numA = int.tryParse(a);
      final numB = int.tryParse(b);
      if (numA != null && numB != null) {
        return numA.compareTo(numB);
      }
      return a.compareTo(b);
    });
    
    return tallasList.join(', ');
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: _isDesktop ? 16 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _isDesktop ? 140 : 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 14,
                color: const Color(0xFF999999),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: _isDesktop ? 16 : 14,
                color: const Color(0xFF333333),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 📝 NUEVA CLASE PARA LA PANTALLA DE ZOOM DE IMAGEN
class ImagenZoomScreen extends StatefulWidget {
  final String imageUrl;
  
  const ImagenZoomScreen({
    required this.imageUrl, 
    Key? key
  }) : super(key: key);

  @override
  State<ImagenZoomScreen> createState() => _ImagenZoomScreenState();
}

class _ImagenZoomScreenState extends State<ImagenZoomScreen> 
    with SingleTickerProviderStateMixin {
  
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  
  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onAnimationComplete() {
    _transformationController.value = _animation!.value;
    if (!_animationController.isAnimating) {
      _animation?.removeListener(_onAnimationComplete);
      _animation = null;
      _animationController.reset();
    }
  }

  void _resetZoom() {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.ease
      ),
    );
    _animation!.addListener(_onAnimationComplete);
    _animationController.forward();
  }

  void _onDoubleTap() {
    Matrix4 endMatrix;
    Offset position = Offset.zero;
    
    if (_transformationController.value != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      endMatrix = Matrix4.identity()
        ..translate(-100.0, -100.0)
        ..scale(2.5);
    }
    
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: endMatrix,
    ).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: Curves.ease
      ),
    );
    _animation!.addListener(_onAnimationComplete);
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _resetZoom,
            tooltip: 'Restablecer zoom',
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: GestureDetector(
            onDoubleTap: _onDoubleTap,
            child: Center(
              child: Hero(
                tag: 'product-image-${widget.imageUrl}',
                child: Image.network(
                  widget.imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image_not_supported_outlined,
                              size: 64,
                              color: Colors.white54,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Imagen no disponible',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Pellizca para zoom • Doble tap para acercar/alejar',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}