import '../../services/FavoritoService.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/Carrito_Service.dart';
import '../../models/request_models.dart';
// Importar la pantalla de detalle del producto
import '../producto/producto_screen.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with TickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final FavoritoService _favoritoService = FavoritoService();
  final CarritoService _carritoService = CarritoService();
  
  List<Map<String, dynamic>> _favoritos = [];
  bool _isLoading = true;
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;
  bool _isRefreshing = false; // Nueva variable para controlar si es un refresh
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Nueva paleta de colores más suave
  static const Color primaryColor = Color(0xFF6C5CE7);      // Púrpura suave
  static const Color accentColor = Color(0xFFA29BFE);       // Púrpura claro
  static const Color backgroundColor = Color(0xFFFBFBFC);    // Blanco cálido
  static const Color cardColor = Colors.white;              // Blanco puro
  static const Color textColor = Color(0xFF2D3436);         // Gris oscuro
  static const Color subtextColor = Color(0xFF636E72);      // Gris medio
  static const Color successColor = Color(0xFF00B894);      // Verde menta
  static const Color warningColor = Color(0xFFE17055);      // Coral suave
  static const Color errorColor = Color(0xFFFF6B9D);        // Rosa suave
  static const Color favoriteColor = Color(0xFFE74C3C);     // Rojo para favoritos

  // Formateador de moneda colombiana
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _verificarEstadoUsuario();
  }

  String _formatCurrency(dynamic precio) {
    try {
      double value = double.parse(precio.toString());
      return _currencyFormatter.format(value);
    } catch (e) {
      return '\$0';
    }
  }

  // Método para navegar al detalle del producto
  void _navegarADetalleProducto(Map<String, dynamic> favorito) {
    try {
      final producto = favorito['producto'] ?? {};
      final productoId = producto['_id'] ?? producto['id'] ?? '';
      
      if (productoId.isEmpty) {
        _mostrarSnackbar(
          'Error: ID de producto no válido',
          isSuccess: false,
          duration: 2
        );
        return;
      }

      // Navegar a la pantalla de detalle del producto
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductoScreen(productId: productoId),

        ),
      );
      
    } catch (e) {
      _mostrarSnackbar(
        'Error al abrir el producto',
        isSuccess: false,
        duration: 2
      );
      print('❌ Error al navegar al detalle del producto: $e');
    }
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.elasticOut));
    
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _verificarEstadoUsuario() async {
    setState(() {
      _isCheckingAuth = true;
      _isLoading = false;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      
      final token = await _secureStorage.read(key: 'accessToken');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoggedIn = false;
          _isCheckingAuth = false;
        });
        
        await Future.delayed(const Duration(milliseconds: 600));
        
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      setState(() {
        _isLoggedIn = true;
        _isCheckingAuth = false;
      });
      
      _fadeController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      _slideController.forward();
      _staggerController.forward();
      
      await _cargarFavoritos();
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingAuth = false;
        _errorMessage = 'Error al verificar usuario';
      });
      
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _cargarFavoritos() async {
    if (!_isLoggedIn) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final favoritos = await _favoritoService.obtenerFavoritos();
      
      setState(() {
        _favoritos = favoritos;
        _isLoading = false;
      });
      
     
      
      // Reset refresh flag
      _isRefreshing = false;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
      
      _isRefreshing = false;
      
      if (_errorMessage!.contains('token') || _errorMessage!.contains('acceso')) {
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    }
  }

  Future<void> _eliminarFavorito(String productoId, int index) async {
    final confirm = await _mostrarDialogoConfirmacion(
      'Eliminar favorito',
      '¿Estás seguro de que deseas eliminar este producto de tus favoritos?'
    );
    
    if (!confirm) return;

    setState(() {
      _favoritos.removeAt(index);
    });

    try {
      final favorito = _favoritos.length > index ? _favoritos[index] : null;
      final idProducto = favorito != null 
        ? (favorito['producto']['_id'] ?? favorito['producto']['id'] ?? productoId)
        : productoId;
      
      await _favoritoService.eliminarFavorito(idProducto);
      
      _mostrarSnackbar('Producto eliminado de favoritos', isSuccess: true, duration: 2);
    } catch (e) {
      setState(() {
        _favoritos.insert(index, _favoritos.removeAt(index));
      });
      
      _mostrarSnackbar(
        e.toString().replaceFirst('Exception: ', ''), 
        isSuccess: false,
        duration: 3
      );
    }
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> favorito) async {
    try {
      // Obtener el token de autenticación
      final token = await _secureStorage.read(key: 'accessToken');
      if (token == null || token.isEmpty) {
        _mostrarSnackbar(
          'Debes iniciar sesión para agregar productos al carrito',
          isSuccess: false,
          duration: 3
        );
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      final producto = favorito['producto'];
      final productoId = producto['_id'] ?? producto['id'];
      final nombre = producto['nombre'] ?? 'Producto';
      
      // Verificar que el producto esté disponible
      final disponible = producto['disponible'] ?? true;
      if (!disponible) {
        _mostrarSnackbar(
          'Este producto no está disponible actualmente',
          isSuccess: false,
          duration: 3
        );
        return;
      }

      // Mostrar indicador de carga
      _mostrarSnackbar(
        'Agregando $nombre al carrito...',
        isSuccess: true,
        duration: 1
      );

      // Verificar si el producto tiene variaciones
      final variaciones = producto['variaciones'] as List<dynamic>?;
      bool agregado = false;

      if (variaciones != null && variaciones.isNotEmpty) {
        // Si hay variaciones, usar la primera disponible o crear request completo
        final primeraVariacion = variaciones.first;
        final variacionId = primeraVariacion['_id'] ?? primeraVariacion['id'];
        
        final request = AgregarAlCarritoRequest(
          productoId: productoId,
          cantidad: 1,
          variacionId: variacionId,
        );
        
        agregado = await _carritoService.agregarProductoCompleto(token, request);
      } else {
        // Si no hay variaciones, usar el método simple
        agregado = await _carritoService.agregarProducto(token, productoId, 1);
      }

      if (agregado) {
        // Usar HapticFeedback para mejor UX
        HapticFeedback.lightImpact();
        
        _mostrarSnackbar(
          '$nombre agregado al carrito exitosamente',
          isSuccess: true,
          duration: 2
        );
      } else {
        _mostrarSnackbar(
          'No se pudo agregar $nombre al carrito. Inténtalo de nuevo.',
          isSuccess: false,
          duration: 3
        );
      }
      
    } catch (e) {
      String errorMessage = 'Error al agregar al carrito';
      
      // Manejar errores específicos
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('token') || 
          e.toString().contains('401')) {
        errorMessage = 'Sesión expirada. Inicia sesión nuevamente.';
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      } else if (e.toString().contains('network') || 
                 e.toString().contains('connection')) {
        errorMessage = 'Error de conexión. Revisa tu internet.';
      } else if (e.toString().contains('timeout')) {
        errorMessage = 'Tiempo agotado. Inténtalo de nuevo.';
      }
      
      _mostrarSnackbar(
        errorMessage,
        isSuccess: false,
        duration: 3
      );
      
      print('❌ Error detallado en _agregarAlCarrito: $e');
    }
  }

  Future<bool> _mostrarDialogoConfirmacion(String titulo, String mensaje) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: EdgeInsets.zero,
          backgroundColor: cardColor,
          title: Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        errorColor.withOpacity(0.15),
                        errorColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: errorColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Text(
              mensaje,
              style: const TextStyle(
                fontSize: 16,
                color: subtextColor,
                height: 1.5,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(20),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: subtextColor,
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: errorColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 2,
              ),
              child: const Text(
                'Eliminar',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  void _mostrarSnackbar(String mensaje, {required bool isSuccess, int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? successColor : errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: Duration(seconds: duration),
        margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
        elevation: 6,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white.withOpacity(0.9),
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _isRefreshing = true; // Marcar como refresh
    await _cargarFavoritos();
  }

  // Widget para shimmer effect
  Widget _buildShimmerCard({bool isTablet = false}) {
    return Shimmer.fromColors(
      baseColor: backgroundColor,
      highlightColor: Colors.white,
      child: Card(
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: cardColor,
        child: Padding(
          padding: EdgeInsets.all(isTablet ? 18 : 14),
          child: isTablet ? _buildShimmerContentTablet() : _buildShimmerContentMobile(),
        ),
      ),
    );
  }

  Widget _buildShimmerContentMobile() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Imagen shimmer
        Container(
          width: screenWidth > 400 ? 100 : 85,
          height: screenWidth > 400 ? 100 : 85,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        SizedBox(width: screenWidth > 400 ? 16 : 12),
        
        // Contenido shimmer
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: double.infinity * 0.7,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        
        // Botones shimmer
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShimmerContentTablet() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
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

  Widget _buildShimmerList() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isTablet) ...[
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildShimmerCard(isTablet: true),
                childCount: 6, // Mostrar 6 cards shimmer
              ),
            ),
          ),
        ] else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildShimmerCard(isTablet: false),
              ),
              childCount: 8, // Mostrar 8 cards shimmer
            ),
          ),
        ],
        
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 32 : 24),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _isCheckingAuth ? null : AppBar(
        title: const Text(
          'Mis Favoritos',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/bienvenida', 
              (route) => false,
            );
          },
        ),
        actions: [
          if (_isLoggedIn && !_isLoading && _favoritos.isNotEmpty)
            Container(
              margin: EdgeInsets.only(
                right: isTablet ? 24 : 16, 
                top: 12, 
                bottom: 12
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 16 : 12, 
                vertical: 8
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    favoriteColor.withOpacity(0.2),
                    favoriteColor.withOpacity(0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: favoriteColor.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: favoriteColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_rounded, size: 18, color: favoriteColor),
                  const SizedBox(width: 6),
                  Text(
                    '${_favoritos.length}',
                    style: TextStyle(
                      fontSize: isTablet ? 16 : 15,
                      fontWeight: FontWeight.w700,
                      color: favoriteColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: _isCheckingAuth
          ? _buildAuthLoadingWidget()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: RefreshIndicator(
                  onRefresh: _onRefresh,
                  color: primaryColor,
                  strokeWidth: 3,
                  child: _isLoading
                      ? _buildShimmerList()
                      : _errorMessage != null
                          ? _buildErrorWidget()
                          : _favoritos.isEmpty
                              ? _buildEmptyState()
                              : _buildFavoritesList(),
                ),
              ),
            ),
    );
  }

  Widget _buildAuthLoadingWidget() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [cardColor, backgroundColor],
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(isTablet ? 48 : 40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            favoriteColor.withOpacity(0.1), // Cambio a rojo
                            favoriteColor.withOpacity(0.05), // Cambio a rojo
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: favoriteColor.withOpacity(0.2), // Cambio a rojo
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: isTablet ? 80 : 64,
                        color: favoriteColor, // Cambio a rojo
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isTablet ? 48 : 40),
              
              SizedBox(
                width: isTablet ? 48 : 40,
                height: isTablet ? 48 : 40,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  strokeWidth: 3.5,
                  backgroundColor: accentColor.withOpacity(0.2),
                ),
              ),
              SizedBox(height: isTablet ? 32 : 24),
              
              Text(
                'Verificando sesión...',
                style: TextStyle(
                  color: textColor,
                  fontSize: isTablet ? 18 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              
              Text(
                'Un momento por favor',
                style: TextStyle(
                  color: subtextColor,
                  fontSize: isTablet ? 15 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: primaryColor,
      strokeWidth: 3,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 120,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 32 : 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          errorColor.withOpacity(0.1),
                          errorColor.withOpacity(0.05),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: errorColor.withOpacity(0.2), width: 2),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: isTablet ? 80 : 64,
                      color: errorColor,
                    ),
                  ),
                  SizedBox(height: isTablet ? 32 : 24),
                  
                  Text(
                    'Algo salió mal',
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  Container(
                    padding: EdgeInsets.all(isTablet ? 20 : 16),
                    decoration: BoxDecoration(
                      color: errorColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: errorColor.withOpacity(0.1)),
                    ),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: isTablet ? 16 : 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 40 : 32),
                  
                  if (isTablet) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 160,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/bienvenida'),
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Inicio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subtextColor,
                              side: BorderSide(color: subtextColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 160,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_errorMessage!.contains('token') || _errorMessage!.contains('acceso')) {
                                Navigator.pushReplacementNamed(context, '/login');
                              } else {
                                _cargarFavoritos();
                              }
                            },
                            icon: Icon(_errorMessage!.contains('token') 
                              ? Icons.login_rounded 
                              : Icons.refresh_rounded),
                            label: Text(_errorMessage!.contains('token') 
                              ? 'Iniciar Sesión' 
                              : 'Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_errorMessage!.contains('token') || _errorMessage!.contains('acceso')) {
                                Navigator.pushReplacementNamed(context, '/login');
                              } else {
                                _cargarFavoritos();
                              }
                            },
                            icon: Icon(_errorMessage!.contains('token') 
                              ? Icons.login_rounded 
                              : Icons.refresh_rounded),
                            label: Text(_errorMessage!.contains('token') 
                              ? 'Iniciar Sesión' 
                              : 'Reintentar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/bienvenida'),
                            icon: const Icon(Icons.home_outlined),
                            label: const Text('Volver al Inicio'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: subtextColor,
                              side: BorderSide(color: subtextColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: primaryColor,
      strokeWidth: 3,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height - 120,
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.8, end: 1.05),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeInOut,
                    builder: (context, scale, child) {
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: EdgeInsets.all(isTablet ? 48 : 40),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                favoriteColor.withOpacity(0.15), // Cambio a rojo
                                favoriteColor.withOpacity(0.05), // Cambio a rojo
                              ],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: favoriteColor.withOpacity(0.15), // Cambio a rojo
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.favorite_border_rounded,
                            size: isTablet ? 100 : 80,
                            color: favoriteColor, // Cambio a rojo
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: isTablet ? 40 : 32),
                  
                  Text(
                    'Sin favoritos aún',
                    style: TextStyle(
                      fontSize: isTablet ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: isTablet ? 16 : 12),
                  
                  Text(
                    'Descubre productos increíbles y agrega\ntus favoritos para encontrarlos fácilmente.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      color: subtextColor,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: isTablet ? 48 : 40),
                  
                  SizedBox(
                    width: isTablet ? 320 : double.infinity,
                    height: isTablet ? 64 : 56,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/bienvenida'),
                      icon: const Icon(Icons.explore_outlined),
                      label: Text(
                        'Explorar Productos',
                        style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF8E9AAF), // Gris suave
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
                        ),
                        elevation: 3,
                      ),
                    ),
                  ),
                  SizedBox(height: isTablet ? 24 : 16),
                  
                  TextButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/bienvenida'),
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    label: const Text('Volver al Inicio'),
                    style: TextButton.styleFrom(
                      foregroundColor: subtextColor,
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 20 : 16, 
                        vertical: 12
                      ),
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

  Widget _buildFavoritesList() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Lista de favoritos adaptativa
        if (isTablet) ...[
          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final favorito = _favoritos[index];
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    curve: Curves.easeOutBack,
                    child: _buildFavoriteCardTablet(favorito, index),
                  );
                },
                childCount: _favoritos.length,
              ),
            ),
          ),
        ] else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final favorito = _favoritos[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  curve: Curves.easeOutBack,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _buildFavoriteCard(favorito, index),
                );
              },
              childCount: _favoritos.length,
            ),
          ),
        ],
        
        SliverToBoxAdapter(
          child: SizedBox(height: isTablet ? 32 : 24),
        ),
      ],
    );
  }

  /// Card de producto favorito para tablet con navegación al detalle
  Widget _buildFavoriteCardTablet(Map<String, dynamic> favorito, int index) {
    final producto = favorito['producto'] ?? {};
    final precio = producto['precio']?.toString() ?? '0';
    final descuento = producto['descuento'] ?? 0;
    final disponible = producto['disponible'] ?? true;
    final nombre = producto['nombre'] ?? 'Producto sin nombre';
    final imagen = producto['imagen'];
    final productoId = producto['_id'] ?? producto['id'] ?? '';

    return Card(
      elevation: 3,
      shadowColor: primaryColor.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          HapticFeedback.lightImpact();
          _navegarADetalleProducto(favorito);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Hero(
                    tag: 'product_${productoId}_$index',
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                        ),
                        child: imagen != null
                            ? Image.network(
                                imagen,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: subtextColor,
                                    size: 48,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: subtextColor,
                                  size: 48,
                                ),
                              ),
                      ),
                    ),
                  ),
                  // Botón eliminar más intuitivo
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          _eliminarFavorito(productoId, index);
                        },
                        icon: const Icon(Icons.close_rounded),
                        color: subtextColor,
                        iconSize: 20,
                        padding: const EdgeInsets.all(8),
                        tooltip: 'Eliminar de favoritos',
                      ),
                    ),
                  ),
                  // Badge de descuento
                  if (descuento > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [successColor, successColor.withOpacity(0.8)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: successColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          '-$descuento%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Información del producto
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    
                    // Precio formateado en negro
                    Text(
                      _formatCurrency(precio),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor, // Cambio de primaryColor a textColor (negro)
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    
                    // Botón de carrito centrado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botón agregar al carrito
                        Container(
                          decoration: BoxDecoration(
                            gradient: disponible 
                              ? LinearGradient(
                                  colors: [successColor, successColor.withOpacity(0.8)],
                                )
                              : LinearGradient(
                                  colors: [subtextColor.withOpacity(0.3), subtextColor.withOpacity(0.2)],
                                ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: disponible ? [
                              BoxShadow(
                                color: successColor.withOpacity(0.2),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ] : null,
                          ),
                          child: IconButton(
                            onPressed: disponible ? () {
                              HapticFeedback.lightImpact();
                              _agregarAlCarrito(favorito);
                            } : null,
                            icon: Icon(
                              disponible 
                                ? Icons.add_shopping_cart_outlined
                                : Icons.remove_shopping_cart_outlined,
                            ),
                            color: disponible ? Colors.white : subtextColor,
                            iconSize: 18,
                            padding: const EdgeInsets.all(12),
                            tooltip: disponible ? 'Agregar al carrito' : 'Producto agotado',
                          ),
                        ),
                      ],
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

  /// Card de producto favorito para móvil con navegación al detalle
  Widget _buildFavoriteCard(Map<String, dynamic> favorito, int index) {
    final producto = favorito['producto'] ?? {};
    final precio = producto['precio']?.toString() ?? '0';
    final descuento = producto['descuento'] ?? 0;
    final disponible = producto['disponible'] ?? true;
    final nombre = producto['nombre'] ?? 'Producto sin nombre';
    final imagen = producto['imagen'];
    final productoId = producto['_id'] ?? producto['id'] ?? '';
    final screenWidth = MediaQuery.of(context).size.width;

    return Card(
      elevation: 2,
      shadowColor: primaryColor.withOpacity(0.06),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          _navegarADetalleProducto(favorito);
        },
        child: Padding(
          padding: EdgeInsets.all(screenWidth > 400 ? 16 : 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Hero(
                tag: 'product_${productoId}_$index',
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: screenWidth > 400 ? 100 : 85,
                        height: screenWidth > 400 ? 100 : 85,
                        decoration: BoxDecoration(
                          color: backgroundColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: imagen != null
                            ? Image.network(
                                imagen,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / 
                                            loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.image_not_supported_outlined,
                                  color: subtextColor,
                                  size: 32,
                                ),
                              )
                            : Icon(
                                Icons.image_outlined,
                                color: subtextColor,
                                size: 32,
                              ),
                      ),
                    ),
                    // Badge de descuento
                    if (descuento > 0)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [successColor, successColor.withOpacity(0.8)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: successColor.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            '-$descuento%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: screenWidth > 400 ? 16 : 12),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: TextStyle(
                        fontSize: screenWidth > 400 ? 16 : 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth > 400 ? 12 : 10),
                    
                    // Precio formateado en negro
                    Text(
                      _formatCurrency(precio),
                      style: TextStyle(
                        fontSize: screenWidth > 400 ? 18 : 16,
                        fontWeight: FontWeight.w800,
                        color: textColor, // Cambio de primaryColor a textColor (negro)
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Acciones
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botón eliminar más claro
                  Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: subtextColor.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: IconButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _eliminarFavorito(productoId, index);
                      },
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: subtextColor,
                      tooltip: 'Eliminar de favoritos',
                      padding: const EdgeInsets.all(8),
                      iconSize: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Botón agregar al carrito
                  Container(
                    decoration: BoxDecoration(
                      gradient: disponible 
                        ? LinearGradient(
                            colors: [successColor, successColor.withOpacity(0.8)],
                          )
                        : LinearGradient(
                            colors: [subtextColor.withOpacity(0.3), subtextColor.withOpacity(0.2)],
                          ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: disponible ? [
                        BoxShadow(
                          color: successColor.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ] : null,
                    ),
                    child: IconButton(
                      onPressed: disponible ? () {
                        HapticFeedback.lightImpact();
                        _agregarAlCarrito(favorito);
                      } : null,
                      icon: Icon(
                        disponible 
                          ? Icons.add_shopping_cart_outlined
                          : Icons.remove_shopping_cart_outlined,
                      ),
                      color: disponible ? Colors.white : subtextColor,
                      tooltip: disponible ? 'Agregar al carrito' : 'Producto agotado',
                      padding: const EdgeInsets.all(8),
                      iconSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}