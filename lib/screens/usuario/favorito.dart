import '../../services/FavoritoService.dart';
import '../../providers/FavoritoProvider.dart';
import '../../theme/favorito/favorito_colors.dart';
import '../../theme/favorito/favorito_text_styles.dart';
import '../../theme/favorito/favorito_decorations.dart';
import '../../theme/favorito/favorito_dimensions.dart';
import '../../theme/favorito/favorito_widgets.dart';
import '../../theme/favorito/favorito_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_flushbar/flushbar.dart';
import 'dart:io';
import '../../services/Carrito_Service.dart';
import '../../models/request_models.dart';
import '../producto/producto_screen.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> with TickerProviderStateMixin {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final CarritoService _carritoService = CarritoService();
  
  bool _isLoggedIn = false;
  bool _isCheckingAuth = true;
  String? _errorMessage;
  
  // Variables de conexión
  bool _isConnected = true;
  bool _showNoConnectionScreen = false;
  bool _hasCheckedInitialConnection = false;
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _staggerController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Formateador de moneda colombiana
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0',
  );

  @override
  void initState() {
    super.initState();
    _initAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedInitialConnection) {
        _checkInitialConnection();
      }
    });
  }

  // Verificación inicial de conexión
  Future<void> _checkInitialConnection() async {
    if (_hasCheckedInitialConnection) return;
    _hasCheckedInitialConnection = true;

    print("🔍 Verificando conexión inicial en Favoritos...");
    
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    
    print("📶 Conexión inicial en Favoritos: $isConnected");
    
    setState(() {
      _isConnected = isConnected;
    });

    if (!isConnected) {
      // Sin conexión: verificar si hay favoritos en caché
      final hasCache = await _checkCacheData();
      
      if (!hasCache) {
        print("🚫 Sin conexión y sin favoritos en caché - Mostrando pantalla sin conexión");
        setState(() {
          _showNoConnectionScreen = true;
          _isCheckingAuth = false;
        });
        _monitorConnectivity();
        return;
      } else {
        print("📱 Sin conexión pero con favoritos en caché - Mostrando datos disponibles");
        setState(() {
          _showNoConnectionScreen = false;
        });
      }
    } else {
      // Con conexión: proceder normalmente
      print("✅ Con conexión en Favoritos - Procediendo normalmente");
      setState(() {
        _showNoConnectionScreen = false;
      });
      
      await _verificarEstadoUsuario();
    }
    
    _monitorConnectivity();
  }

  // Verificar si hay datos de favoritos en caché
  Future<bool> _checkCacheData() async {
    try {
      final favoritoProvider = Provider.of<FavoritoProvider>(context, listen: false);
      final hasFavoritos = favoritoProvider.favoritos.isNotEmpty;
      
      print("📦 Estado del caché de favoritos: $hasFavoritos");
      
      return hasFavoritos;
    } catch (e) {
      print("❌ Error verificando caché de favoritos: $e");
      return false;
    }
  }

  // Verificar conexión real a internet
  Future<bool> _checkRealInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("❌ Sin conectividad según connectivity_plus en Favoritos");
        return false;
      }
      
      print("🔍 Verificando conexión real con petición de prueba en Favoritos...");
      
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        
        final request = await client.getUrl(Uri.parse('https://www.google.com'));
        final response = await request.close();
        client.close();
        
        if (response.statusCode == 200) {
          print("✅ Petición de prueba exitosa en Favoritos - Internet funcional");
          return true;
        } else {
          print("❌ Petición de prueba falló en Favoritos - Status: ${response.statusCode}");
          return false;
        }
      } catch (e) {
        print("❌ Petición de prueba falló en Favoritos: $e");
        
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('failed host lookup') ||
            errorStr.contains('network unreachable') ||
            errorStr.contains('connection failed') ||
            errorStr.contains('timeout') ||
            errorStr.contains('no route to host')) {
          return false;
        }
        
        return true;
      }
    } catch (e) {
      print("❌ Error verificando conexión real en Favoritos: $e");
      return false;
    }
  }

  // Monitorear cambios de conectividad
  void _monitorConnectivity() {
    bool? _ultimoEstado;

    Connectivity().onConnectivityChanged.listen((status) async {
      final conectado = status != ConnectivityResult.none;
      print("📡 Cambio de conectividad en Favoritos: $_ultimoEstado -> $conectado");

      // Transición de sin conexión a con conexión desde pantalla sin conexión
      if (_showNoConnectionScreen && conectado && (_ultimoEstado == false || _ultimoEstado == null)) {
        print("🔄 Saliendo de pantalla sin conexión en Favoritos...");
        setState(() {
          _showNoConnectionScreen = false;
        });
        
        await _verificarEstadoUsuario();
        _mostrarFlushbarConexion(true);
      }
      // Cambios de conexión normales
      else if (_ultimoEstado != null && _ultimoEstado != conectado && !_showNoConnectionScreen) {
        _mostrarFlushbarConexion(conectado);

        // Recargar favoritos si se recupera la conexión
        if (conectado && _isLoggedIn) {
          print("🔄 Recargando favoritos tras recuperar conexión...");
          try {
            await Provider.of<FavoritoProvider>(context, listen: false).cargarFavoritos();
          } catch (e) {
            print("❌ Error recargando favoritos: $e");
          }
        }
      }

      _ultimoEstado = conectado;
      if (mounted) {
        setState(() => _isConnected = conectado);
      }
    });
  }

  void _mostrarFlushbarConexion(bool conectado) {
    if (!mounted) return;
    
    Flushbar(
      message: conectado ? "✅ Conexión restablecida" : "⚠️ Sin conexión a internet",
      icon: Icon(
        conectado ? Icons.wifi : Icons.wifi_off,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: conectado ? Colors.green : Colors.red,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  String _formatCurrency(dynamic precio) {
    try {
      double value = double.parse(precio.toString());
      return _currencyFormatter.format(value);
    } catch (e) {
      return '\$0';
    }
  }

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
      duration: FavoritoDimensions.mediumAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: FavoritoDimensions.longAnimationDuration,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: FavoritoDimensions.pulseAnimationDuration,
      vsync: this,
    );
    _staggerController = AnimationController(
      duration: FavoritoDimensions.staggerAnimationDuration,
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
    });

    try {
      await Future.delayed(FavoritoDimensions.longDelay);
      
      final token = await _secureStorage.read(key: 'accessToken');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoggedIn = false;
          _isCheckingAuth = false;
        });
        
        await Future.delayed(FavoritoDimensions.mediumDelay);
        
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
      await Future.delayed(FavoritoDimensions.shortDelay);
      _slideController.forward();
      _staggerController.forward();
      
      if (mounted) {
        await Provider.of<FavoritoProvider>(context, listen: false).cargarFavoritos();
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isCheckingAuth = false;
        _errorMessage = 'Error al verificar usuario';
      });
      
      await Future.delayed(FavoritoDimensions.longDelay);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  Future<void> _eliminarFavorito(String productoId, int index) async {
    final confirm = await _mostrarDialogoConfirmacion(
      'Eliminar favorito',
      '¿Estás seguro de que deseas eliminar este producto de tus favoritos?'
    );
    
    if (!confirm) return;

    try {
      await Provider.of<FavoritoProvider>(context, listen: false)
          .eliminarFavorito(productoId);
      
      _mostrarSnackbar('Producto eliminado de favoritos', isSuccess: true, duration: 2);
    } catch (e) {
      _mostrarSnackbar(
        e.toString().replaceFirst('Exception: ', ''), 
        isSuccess: false,
        duration: 3
      );
    }
  }

  Future<void> _agregarAlCarrito(Map<String, dynamic> favorito) async {
    try {
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
      
      final disponible = producto['disponible'] ?? true;
      if (!disponible) {
        _mostrarSnackbar(
          'Este producto no está disponible actualmente',
          isSuccess: false,
          duration: 3
        );
        return;
      }

      _mostrarSnackbar(
        'Agregando $nombre al carrito...',
        isSuccess: true,
        duration: 1
      );

      final variaciones = producto['variaciones'] as List<dynamic>?;
      bool agregado = false;

      if (variaciones != null && variaciones.isNotEmpty) {
        final primeraVariacion = variaciones.first;
        final variacionId = primeraVariacion['_id'] ?? primeraVariacion['id'];
        
        final request = AgregarAlCarritoRequest(
          productoId: productoId,
          cantidad: 1,
          variacionId: variacionId,
        );
        
        agregado = await _carritoService.agregarProductoCompleto(token, request);
      } else {
        agregado = await _carritoService.agregarProducto(token, productoId, 1);
      }

      if (agregado) {
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
      
      if (e.toString().contains('Unauthorized') || 
          e.toString().contains('token') || 
          e.toString().contains('401')) {
        errorMessage = 'Sesión expirada. Inicia sesión nuevamente.';
        await Future.delayed(FavoritoDimensions.longDelay);
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
          shape: FavoritoDecorations.dialogShape,
          contentPadding: EdgeInsets.zero,
          backgroundColor: FavoritoColors.cardColor,
          title: Container(
            padding: FavoritoDimensions.dialogTitlePadding,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: FavoritoDecorations.dialogIconDecoration,
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: FavoritoColors.errorColor,
                    size: 28,
                  ),
                ),
                FavoritoDimensions.mediumHorizontalSpace,
                Expanded(
                  child: Text(
                    titulo,
                    style: FavoritoTextStyles.dialogTitle,
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: FavoritoDimensions.dialogContentPadding,
            child: Text(
              mensaje,
              style: FavoritoTextStyles.dialogContent,
            ),
          ),
          actionsPadding: FavoritoDimensions.dialogActionsPadding,
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: FavoritoDecorations.smallButtonShape,
                foregroundColor: FavoritoColors.subtextColor,
              ),
              child: const Text(
                'Cancelar',
                style: FavoritoTextStyles.buttonLabel,
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: FavoritoColors.errorColor,
                foregroundColor: Colors.white,
                shape: FavoritoDecorations.smallButtonShape,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: FavoritoDimensions.buttonElevation,
              ),
              child: const Text(
                'Eliminar',
                style: FavoritoTextStyles.elevatedButtonLabel,
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
              decoration: FavoritoDecorations.snackbarIconDecoration,
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: FavoritoDimensions.snackbarIconSize,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: FavoritoTextStyles.snackbarText,
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? FavoritoColors.successColor : FavoritoColors.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: FavoritoDecorations.snackbarShape,
        duration: Duration(seconds: duration),
        margin: FavoritoDimensions.snackbarMargin(context),
        elevation: FavoritoDimensions.snackbarElevation,
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
    
    // Si estamos en pantalla sin conexión
    if (_showNoConnectionScreen) {
      print("📱 Verificando conexión desde pantalla sin conexión en Favoritos...");
      final hasRealConnection = await _checkRealInternetConnection();
      
      if (hasRealConnection) {
        print("✅ Conexión real detectada en Favoritos, cargando datos...");
        setState(() {
          _isConnected = true;
          _showNoConnectionScreen = false;
        });
        
        await _verificarEstadoUsuario();
        return;
      } else {
        print("❌ Aún sin conexión real en Favoritos");
        _mostrarFlushbarConexion(false);
        return;
      }
    }
    
    // Refresh normal: verificar conexión real antes de proceder
    print("🔄 Verificando conexión real antes del refresh en Favoritos...");
    final hasRealConnection = await _checkRealInternetConnection();
    
    if (!hasRealConnection) {
      print("❌ Sin conexión real durante refresh en Favoritos");
      setState(() {
        _isConnected = false;
      });
      _mostrarFlushbarConexion(false);
      return;
    }
    
    try {
      await Provider.of<FavoritoProvider>(context, listen: false).cargarFavoritos();
    } catch (e) {
      if (_isErrorDeConexion(e.toString())) {
        setState(() {
          _isConnected = false;
        });
        _mostrarFlushbarConexion(false);
      } else {
        _mostrarSnackbar(
          'Error al actualizar favoritos',
          isSuccess: false,
          duration: 2
        );
      }
    }
  }

  // Detectar si un error es de conexión
  bool _isErrorDeConexion(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('conexión') ||
           errorLower.contains('connection') ||
           errorLower.contains('internet') ||
           errorLower.contains('network') ||
           errorLower.contains('timeout') ||
           errorLower.contains('unreachable') ||
           errorLower.contains('failed host lookup');
  }

  // Pantalla sin conexión
  Widget _buildNoConnectionScreen() {
    final isTablet = FavoritoDimensions.isTablet(context);
    
    return Scaffold(
      backgroundColor: FavoritoColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Mis Favoritos',
          style: FavoritoTextStyles.appBarTitle,
        ),
        backgroundColor: FavoritoColors.cardColor,
        foregroundColor: FavoritoColors.textColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: FavoritoDimensions.appBarIconSize),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/bienvenida', 
              (route) => false,
            );
          },
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: FavoritoColors.primaryColor,
        strokeWidth: 3,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.7,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icono principal
                  Icon(
                    Icons.wifi_off_rounded,
                    size: isTablet ? 120 : 100,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: isTablet ? 40 : 32),
                  
                  // Mensaje principal
                  Text(
                    "Sin conexión a internet",
                    style: TextStyle(
                      fontSize: isTablet ? 28 : 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: isTablet ? 20 : 16),
                  
                  // Mensaje secundario
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: isTablet ? 60 : 40),
                    child: Text(
                      "Revisa tu conexión y desliza hacia abajo para intentar nuevamente",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isTablet ? 18 : 16,
                        color: Colors.grey.shade600,
                        height: 1.4,
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

  Widget _buildShimmerCard({bool isTablet = false}) {
    return Shimmer.fromColors(
      baseColor: FavoritoColors.backgroundColor,
      highlightColor: Colors.white,
      child: Card(
        elevation: isTablet ? FavoritoDimensions.cardElevationTablet : FavoritoDimensions.cardElevation,
        shadowColor: FavoritoColors.primaryColor.withOpacity(0.06),
        shape: isTablet ? FavoritoDecorations.cardShapeTablet : FavoritoDecorations.cardShape,
        color: FavoritoColors.cardColor,
        child: Padding(
          padding: FavoritoDimensions.cardPadding(isTablet),
          child: isTablet ? _buildShimmerContentTablet() : _buildShimmerContentMobile(),
        ),
      ),
    );
  }

  Widget _buildShimmerContentMobile() {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageSize = FavoritoDimensions.imageSize(screenWidth);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: imageSize,
          height: imageSize,
          decoration: FavoritoDecorations.imageContainerDecoration,
        ),
        FavoritoDimensions.adaptiveHorizontalSpace(screenWidth),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: FavoritoColors.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FavoritoDimensions.smallVerticalSpace,
              Container(
                height: 16,
                width: double.infinity * 0.7,
                decoration: BoxDecoration(
                  color: FavoritoColors.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: FavoritoColors.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ),
        
        Column(
          children: [
            Container(
              width: FavoritoDimensions.smallButtonSize,
              height: FavoritoDimensions.smallButtonSize,
              decoration: BoxDecoration(
                color: FavoritoColors.backgroundColor,
                borderRadius: BorderRadius.circular(FavoritoDimensions.smallBorderRadius),
              ),
            ),
            FavoritoDimensions.smallVerticalSpace,
            Container(
              width: FavoritoDimensions.smallButtonSize,
              height: FavoritoDimensions.smallButtonSize,
              decoration: BoxDecoration(
                color: FavoritoColors.backgroundColor,
                borderRadius: BorderRadius.circular(FavoritoDimensions.smallBorderRadius),
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
            decoration: FavoritoDecorations.imageContainerDecoration,
          ),
        ),
        FavoritoDimensions.mediumVerticalSpace,
        
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: FavoritoColors.backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              FavoritoDimensions.smallVerticalSpace,
              Container(
                height: 24,
                width: 100,
                decoration: BoxDecoration(
                  color: FavoritoColors.backgroundColor,
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
                        color: FavoritoColors.backgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: FavoritoDimensions.smallButtonSize,
                    height: FavoritoDimensions.smallButtonSize,
                    decoration: BoxDecoration(
                      color: FavoritoColors.backgroundColor,
                      borderRadius: BorderRadius.circular(FavoritoDimensions.smallBorderRadius),
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
    final isTablet = FavoritoDimensions.isTablet(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isTablet) ...[
          SliverPadding(
            padding: FavoritoDimensions.listPadding,
            sliver: SliverGrid(
              gridDelegate: FavoritoDimensions.tabletGridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildShimmerCard(isTablet: true),
                childCount: 6,
              ),
            ),
          ),
        ] else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Container(
                margin: FavoritoDimensions.cardMargin,
                child: _buildShimmerCard(isTablet: false),
              ),
              childCount: 8,
            ),
          ),
        ],
        
        SliverToBoxAdapter(
          child: FavoritoDimensions.adaptiveVerticalSpace(isTablet),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = FavoritoDimensions.isTablet(context);

    // Mostrar pantalla sin conexión si corresponde
    if (_showNoConnectionScreen) {
      return _buildNoConnectionScreen();
    }

    return Scaffold(
      backgroundColor: FavoritoColors.backgroundColor,
      appBar: _isCheckingAuth ? null : AppBar(
        title: Text(
          'Mis Favoritos',
          style: FavoritoTextStyles.appBarTitle,
        ),
        backgroundColor: FavoritoColors.cardColor,
        foregroundColor: FavoritoColors.textColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, size: FavoritoDimensions.appBarIconSize),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/bienvenida', 
              (route) => false,
            );
          },
        ),
        actions: [
          Consumer<FavoritoProvider>(
            builder: (context, provider, child) {
              if (_isLoggedIn && !provider.isLoading && provider.favoritos.isNotEmpty) {
                return FavoritoWidgets.favoriteCounter(
                  count: provider.favoritos.length,
                  isTablet: isTablet,
                );
              }
              return const SizedBox();
            },
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
                  color: FavoritoColors.primaryColor,
                  strokeWidth: 3,
                  child: Consumer<FavoritoProvider>(
                    builder: (context, provider, child) {
                      if (provider.isLoading && _isConnected && !_showNoConnectionScreen) {
                        return _buildShimmerList();
                      } else if (_errorMessage != null && !_showNoConnectionScreen) {
                        return _buildErrorWidget();
                      } else if (provider.favoritos.isEmpty && _isConnected && !_showNoConnectionScreen) {
                        return _buildEmptyState();
                      } else if (!_showNoConnectionScreen && provider.favoritos.isNotEmpty) {
                        return _buildFavoritesList(provider.favoritos);
                      } else {
                        // Estado por defecto cuando no hay conexión pero sí hay datos en caché
                        if (provider.favoritos.isNotEmpty && !_isConnected) {
                          return _buildFavoritesList(provider.favoritos);
                        }
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildAuthLoadingWidget() {
    final isTablet = FavoritoDimensions.isTablet(context);

    return Container(
      decoration: BoxDecoration(
        gradient: FavoritoColors.authLoadingGradient,
      ),
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FavoritoWidgets.pulseIcon(
                animation: _pulseAnimation,
                icon: Icons.favorite_rounded,
                isTablet: isTablet,
              ),
              SizedBox(height: isTablet ? 48 : 40),
              
              FavoritoWidgets.circularProgress(isLarge: isTablet),
              SizedBox(height: isTablet ? 32 : 24),
              
              Text(
                'Verificando sesión...',
                style: FavoritoTextStyles.loadingTitle(isTablet),
              ),
              SizedBox(height: isTablet ? 8 : 6),
              
              Text(
                'Un momento por favor',
                style: FavoritoTextStyles.loadingSubtitle(isTablet),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final isTablet = FavoritoDimensions.isTablet(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: FavoritoColors.primaryColor,
      strokeWidth: 3,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: FavoritoDimensions.screenHeightWithoutAppBar(context),
          child: FavoritoWidgets.errorState(
            title: 'Algo salió mal',
            message: _errorMessage!,
            primaryButtonText: _errorMessage!.contains('token') ? 'Iniciar Sesión' : 'Reintentar',
            onPrimaryPressed: () {
              if (_errorMessage!.contains('token') || _errorMessage!.contains('acceso')) {
                Navigator.pushReplacementNamed(context, '/login');
              } else {
                _onRefresh();
              }
            },
            secondaryButtonText: 'Inicio',
            onSecondaryPressed: () => Navigator.pushNamed(context, '/bienvenida'),
            isTablet: isTablet,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isTablet = FavoritoDimensions.isTablet(context);

    return RefreshIndicator(
      onRefresh: _onRefresh,
      color: FavoritoColors.primaryColor,
      strokeWidth: 3,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: FavoritoDimensions.screenHeightWithoutAppBar(context),
          child: FavoritoWidgets.emptyState(
            icon: Icons.favorite_border_rounded,
            title: 'Sin favoritos aún',
            description: 'Descubre productos increíbles y agrega\ntus favoritos para encontrarlos fácilmente.',
            buttonText: 'Explorar Productos',
            onButtonPressed: () => Navigator.pushNamed(context, '/bienvenida'),
            secondaryButtonText: 'Volver al Inicio',
            onSecondaryButtonPressed: () => Navigator.pushNamed(context, '/bienvenida'),
            isTablet: isTablet,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<Map<String, dynamic>> favoritos) {
    final isTablet = FavoritoDimensions.isTablet(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (isTablet) ...[
          SliverPadding(
            padding: FavoritoDimensions.listPadding,
            sliver: SliverGrid(
              gridDelegate: FavoritoDimensions.tabletGridDelegate,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final favorito = favoritos[index];
                  return AnimatedContainer(
                    duration: FavoritoTheme.getStaggeredAnimationDurationTablet(index),
                    curve: Curves.easeOutBack,
                    child: _buildFavoriteCardTablet(favorito, index),
                  );
                },
                childCount: favoritos.length,
              ),
            ),
          ),
        ] else ...[
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final favorito = favoritos[index];
                return AnimatedContainer(
                  duration: FavoritoTheme.getStaggeredAnimationDuration(index),
                  curve: Curves.easeOutBack,
                  margin: FavoritoDimensions.cardMargin,
                  child: _buildFavoriteCard(favorito, index),
                );
              },
              childCount: favoritos.length,
            ),
          ),
        ],
        
        SliverToBoxAdapter(
          child: FavoritoDimensions.adaptiveVerticalSpace(isTablet),
        ),
      ],
    );
  }

  Widget _buildFavoriteCardTablet(Map<String, dynamic> favorito, int index) {
    final producto = favorito['producto'] ?? {};
    final precio = producto['precio']?.toString() ?? '0';
    final descuento = producto['descuento'] ?? 0;
    final disponible = producto['disponible'] ?? true;
    final nombre = producto['nombre'] ?? 'Producto sin nombre';
    final imagen = producto['imagen'];
    final productoId = producto['_id'] ?? producto['id'] ?? '';

    return Card(
      elevation: FavoritoDimensions.cardElevationTablet,
      shadowColor: FavoritoColors.primaryColor.withOpacity(0.08),
      shape: FavoritoDecorations.cardShapeTablet,
      color: FavoritoColors.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(FavoritoDimensions.cardBorderRadiusTablet),
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
                        topLeft: Radius.circular(FavoritoDimensions.cardBorderRadiusTablet),
                        topRight: Radius.circular(FavoritoDimensions.cardBorderRadiusTablet),
                      ),
                      child: FavoritoWidgets.imageContainer(
                        imageUrl: imagen,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Botón eliminar
                  Positioned(
                    top: 12,
                    right: 12,
                    child: FavoritoWidgets.closeButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _eliminarFavorito(productoId, index);
                      },
                    ),
                  ),
                  // Badge de descuento
                  if (descuento > 0)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: FavoritoWidgets.discountBadge(
                        discount: descuento,
                        isSmall: false,
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
                      style: FavoritoTextStyles.productNameTablet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    FavoritoDimensions.smallVerticalSpace,
                    
                    Text(
                      _formatCurrency(precio),
                      style: FavoritoTextStyles.productPriceTablet,
                    ),
                    const Spacer(),
                    
                    // Botón de carrito centrado
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FavoritoWidgets.cartButton(
                          onPressed: disponible ? () {
                            HapticFeedback.lightImpact();
                            _agregarAlCarrito(favorito);
                          } : null,
                          disponible: disponible,
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
      elevation: FavoritoDimensions.cardElevation,
      shadowColor: FavoritoColors.primaryColor.withOpacity(0.06),
      shape: FavoritoDecorations.cardShape,
      color: FavoritoColors.cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(FavoritoDimensions.cardBorderRadius),
        onTap: () {
          HapticFeedback.lightImpact();
          _navegarADetalleProducto(favorito);
        },
        child: Padding(
          padding: FavoritoDimensions.cardPaddingTablet(FavoritoDimensions.isLargeScreen(context)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagen del producto
              Hero(
                tag: 'product_${productoId}_$index',
                child: Stack(
                  children: [
                    FavoritoWidgets.imageContainer(
                      imageUrl: imagen,
                      width: FavoritoDimensions.imageSize(screenWidth),
                      height: FavoritoDimensions.imageSize(screenWidth),
                    ),
                    // Badge de descuento
                    if (descuento > 0)
                      Positioned(
                        top: -2,
                        left: -2,
                        child: FavoritoWidgets.discountBadge(
                          discount: descuento,
                          isSmall: true,
                        ),
                      ),
                  ],
                ),
              ),
              FavoritoDimensions.adaptiveHorizontalSpace(screenWidth),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: FavoritoTextStyles.productNameMobile(screenWidth),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenWidth > 400 ? 12 : 10),
                    
                    Text(
                      _formatCurrency(precio),
                      style: FavoritoTextStyles.productPriceMobile(screenWidth),
                    ),
                  ],
                ),
              ),
              
              // Acciones
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FavoritoWidgets.deleteButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      _eliminarFavorito(productoId, index);
                    },
                  ),
                  FavoritoDimensions.smallVerticalSpace,
                  
                  FavoritoWidgets.cartButton(
                    onPressed: disponible ? () {
                      HapticFeedback.lightImpact();
                      _agregarAlCarrito(favorito);
                    } : null,
                    disponible: disponible,
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