// 🎯 IMPORTACIONES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../services/anuncio_service.dart';
import 'gestion_anuncios_screen.dart';

// 🎨 ESTILOS PROFESIONALES MEJORADOS
class AppStyles {
  // Colores mejorados con paleta más sofisticada
  static const Color primaryColor = Color(0xFF1A237E);
  static const Color primaryLight = Color(0xFF3F51B5);
  static const Color accentColor = Color(0xFFFF6B35);
  static const Color accentLight = Color(0xFFFF8A65);
  static const Color successColor = Color(0xFF00C853);
  static const Color successLight = Color(0xFF69F0AE);
  static const Color errorColor = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFF5252);
  static const Color warningColor = Color(0xFFFFA726);
  static const Color infoColor = Color(0xFF29B6F6);
  
  // Colores de superficie y fondo
  static const Color backgroundColor = Color(0xFFF8FAFF);
  static const Color surfaceColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color dividerColor = Color(0xFFE0E7FF);
  
  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF999999);
  static const Color textOnPrimary = Colors.white;
  
  // Dimensiones estandarizadas
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusMax = 32.0;
  
  static const double spacingXSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingXLarge = 32.0;
  
  static const double elevationSmall = 2.0;
  static const double elevationMedium = 4.0;
  static const double elevationLarge = 8.0;
  static const double elevationXLarge = 16.0;
  
  // Duraciones de animación optimizadas
  static const Duration fastAnimation = Duration(milliseconds: 150);
  static const Duration normalAnimation = Duration(milliseconds: 300);
  static const Duration slowAnimation = Duration(milliseconds: 500);
  static const Duration toastDuration = Duration(seconds: 4);

  // Shadows mejoradas
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 4,
      offset: const Offset(0, 1),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}

// 📱 ANUNCIOS SCREEN CON DISEÑO PROFESIONAL MEJORADO
class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> 
    with TickerProviderStateMixin {
  final AnuncioService _anuncioService = AnuncioService();
  
  List<Map<String, dynamic>> _anuncios = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _mensajeError;
  int _currentIndex = 0;
  bool _isDeleting = false;
  bool _isRefreshing = false;

  // Controllers de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Configuraciones del carrusel optimizadas - MISMO TAMAÑO QUE BannerCarousel
  static const double aspectRatioML = 10 / 3; // Relación similar a Mercado Libre (~3.33:1)
  static const double maxBannerHeight = 240;
  static const double minBannerHeight = 120;
  static const EdgeInsets containerMargin = EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarAnuncios();
  }

  void _initAnimations() {
    _fadeController = AnimationController(
      duration: AppStyles.normalAnimation,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: AppStyles.normalAnimation,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  double _calculateBannerHeight(double screenWidth) {
    double height = (screenWidth - 32) / aspectRatioML; // margen horizontal
    return height.clamp(minBannerHeight, maxBannerHeight);
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth >= 1024) return 0.85;
    if (screenWidth >= 768) return 0.88;
    if (screenWidth >= 600) return 0.9;
    return 0.92;
  }

  Future<void> _cargarAnuncios() async {
    if (!mounted) return;
    
    if (!_isRefreshing) {
      setState(() {
        _isLoading = true;
        _hasError = false;
        _mensajeError = null;
      });
    }

    // Reset animaciones
    _fadeController.reset();
    _slideController.reset();

    try {
      // UX delay para mostrar loading shimmer (solo si no es refresh)
      if (!_isRefreshing) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      final anuncios = await _anuncioService.obtenerAnunciosActivosConId();

      if (!mounted) return;
      
      setState(() {
        _anuncios = anuncios;
        _isLoading = false;
        _hasError = false;
        _isRefreshing = false;
      });
      
      // Iniciar animaciones
      _fadeController.forward();
      _slideController.forward();
      
      // Precargar las primeras 3 imágenes
      if (mounted && _anuncios.isNotEmpty) {
        _prefetchImages();
      }
      
      // Mostrar mensaje de éxito solo en refresh manual
      if (_isRefreshing) {
        _mostrarToast("Anuncios actualizados", success: true);
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
        _mensajeError = _determinarMensajeError(e);
      });
      _fadeController.forward(); // Mostrar error con animación
    }
  }

  Future<void> _onRefresh() async {
    if (_isLoading || _isRefreshing) return;
    
    HapticFeedback.mediumImpact();
    
    setState(() {
      _isRefreshing = true;
    });
    
    await _cargarAnuncios();
  }

  String _determinarMensajeError(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || 
        errorStr.contains('network') || 
        errorStr.contains('connection')) {
      return "Sin conexión a internet";
    } else if (errorStr.contains('timeout') || 
               errorStr.contains('time out')) {
      return "Tiempo de espera agotado";
    } else if (errorStr.contains('server') || 
               errorStr.contains('502') || 
               errorStr.contains('503') || 
               errorStr.contains('500')) {
      return "Servidor no disponible";
    } else if (errorStr.contains('404')) {
      return "Recurso no encontrado";
    } else {
      return "Error de conexión";
    }
  }

  Future<void> _prefetchImages() async {
    final imagesToPrefetch = _anuncios.take(3).toList();
    for (int i = 0; i < imagesToPrefetch.length; i++) {
      final url = imagesToPrefetch[i]['imagen'];
      if (url != null && url.isNotEmpty && mounted) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          );
        } catch (_) {
          // Silently handle prefetch errors
        }
      }
    }
  }

  Future<void> _eliminarAnuncio(String id) async {
    if (_isDeleting) return;
    
    HapticFeedback.mediumImpact();

    final confirmar = await _mostrarDialogoConfirmacion();
    if (confirmar != true) return;

    setState(() => _isDeleting = true);

    try {
      final eliminado = await _anuncioService.eliminarAnuncio(id);
      if (!mounted) return;

      if (eliminado) {
        _mostrarToast("Anuncio eliminado exitosamente", success: true);
        setState(() {
          _anuncios.removeWhere((a) => a['_id'] == id);
          if (_currentIndex >= _anuncios.length && _anuncios.isNotEmpty) {
            _currentIndex = _anuncios.length - 1;
          }
        });
      } else {
        _mostrarToast(
          _anuncioService.message ?? 'Error al eliminar el anuncio',
          success: false
        );
      }
    } catch (e) {
      if (mounted) {
        _mostrarToast(_determinarMensajeError(e), success: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        elevation: AppStyles.elevationXLarge,
        backgroundColor: AppStyles.surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingSmall),
              decoration: BoxDecoration(
                color: AppStyles.errorColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: AppStyles.errorColor,
                size: 24,
              ),
            ),
            const SizedBox(width: AppStyles.spacingMedium),
            const Expanded(
              child: Text(
                "Confirmar eliminación",
                style: TextStyle(
                  color: AppStyles.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          "¿Estás seguro de que deseas eliminar este anuncio? Esta acción no se puede deshacer.",
          style: TextStyle(
            color: AppStyles.textSecondary,
            fontSize: 16,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.textSecondary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingLarge,
                vertical: AppStyles.spacingMedium,
              ),
            ),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppStyles.errorColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: AppStyles.spacingLarge,
                vertical: AppStyles.spacingMedium,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
            ),
            child: const Text(
              "Eliminar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarToast(String mensaje, {required bool success}) {
    if (!mounted) return;
    
    final color = success ? AppStyles.successColor : AppStyles.errorColor;
    final icon = success ? Icons.check_circle_rounded : Icons.error_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingSmall),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingXSmall),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: Text(
                  mensaje,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        duration: AppStyles.toastDuration,
        elevation: AppStyles.elevationLarge,
        margin: const EdgeInsets.all(AppStyles.spacingMedium),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = _calculateBannerHeight(screenWidth);
    final double viewportFraction = _getViewportFraction(screenWidth);

    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppStyles.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        displacement: 60,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    children: [
                      // Header con información del carrusel
                      if (!_isLoading && _anuncios.isNotEmpty)
                        _buildHeaderInfo(),

                      // Contenido principal
                      AnimatedSwitcher(
                        duration: AppStyles.normalAnimation,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: _buildBodyContent(screenWidth, bannerHeight, viewportFraction),
                      ),

                      // Información detallada del anuncio actual
                      if (!_isLoading && !_hasError && _anuncios.isNotEmpty)
                        _buildAnuncioDetailCard(_anuncios[_currentIndex]),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: AppStyles.primaryColor,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          "Gestión de Anuncios",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppStyles.primaryColor,
                AppStyles.primaryLight,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -30,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppStyles.spacingMedium,
        AppStyles.spacingLarge,
        AppStyles.spacingMedium,
        AppStyles.spacingSmall,
      ),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
          side: BorderSide(
            color: AppStyles.dividerColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingMedium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingSmall),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                ),
                child: Icon(
                  Icons.campaign_rounded,
                  color: AppStyles.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anuncios Activos',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.textPrimary,
                      ),
                    ),
                    Text(
                      'Desliza hacia abajo para actualizar',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppStyles.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCounterBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounterBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppStyles.accentColor, AppStyles.accentLight],
        ),
        borderRadius: BorderRadius.circular(AppStyles.radiusMax),
        boxShadow: [
          BoxShadow(
            color: AppStyles.accentColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '${_currentIndex + 1} de ${_anuncios.length}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppStyles.radiusMax),
        boxShadow: AppStyles.elevatedShadow,
      ),
      child: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const GestionAnunciosScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return SlideTransition(
                  position: animation.drive(
                    Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                        .chain(CurveTween(curve: Curves.easeOutCubic)),
                  ),
                  child: child,
                );
              },
              transitionDuration: AppStyles.normalAnimation,
            ),
          ).then((_) => _cargarAnuncios());
        },
        backgroundColor: AppStyles.accentColor,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        icon: const Icon(Icons.add_rounded, size: 24),
        label: const Text(
          "Nuevo Anuncio",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildBodyContent(double screenWidth, double bannerHeight, double viewportFraction) {
    if (_isLoading) return _buildLoadingState(screenWidth, bannerHeight, viewportFraction);
    if (_hasError) return _buildErrorState(bannerHeight);
    if (_anuncios.isEmpty) return _buildEmptyState();
    return _buildCarruselAnuncios(screenWidth, bannerHeight, viewportFraction);
  }

  Widget _buildCarruselAnuncios(double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: containerMargin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Carrusel principal con animación mejorada
          AnimatedContainer(
            duration: AppStyles.normalAnimation,
            width: screenWidth,
            height: bannerHeight,
            child: CarouselSlider.builder(
              itemCount: _anuncios.length,
              itemBuilder: (context, index, realIndex) {
                return _buildBannerItem(
                  _anuncios[index],
                  screenWidth * viewportFraction - 12,
                  bannerHeight,
                );
              },
              options: CarouselOptions(
                height: bannerHeight,
                autoPlay: false,
                enlargeCenterPage: false,
                viewportFraction: viewportFraction,
                enableInfiniteScroll: _anuncios.length > 1,
                scrollPhysics: const BouncingScrollPhysics(),
                onPageChanged: (index, reason) {
                  if (mounted) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentIndex = index;
                    });
                  }
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          _buildModernDotsIndicator(),
        ],
      ),
    );
  }

  Widget _buildBannerItem(
    Map<String, dynamic> anuncio,
    double width,
    double height,
  ) {
    final imageUrl = anuncio['imagen'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Imagen principal
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              width: width,
              height: height,
              placeholder: (context, url) => _buildShimmer(width, height),
              errorWidget: (context, url, error) => _buildErrorImagePlaceholder(width, height),
              fadeInDuration: const Duration(milliseconds: 300),
              fadeOutDuration: const Duration(milliseconds: 100),
            ),

            // Overlay degradado
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                    ],
                    stops: const [0.6, 1.0],
                  ),
                ),
              ),
            ),

            // Status badge
            Positioned(
              top: AppStyles.spacingMedium,
              left: AppStyles.spacingMedium,
              child: _buildEnhancedStatusBadge(anuncio),
            ),

            // Botón de eliminación
            Positioned(
              top: AppStyles.spacingMedium,
              right: AppStyles.spacingMedium,
              child: _buildDeleteButton(anuncio['_id']),
            ),

            // Información del anuncio
            Positioned(
              bottom: AppStyles.spacingMedium,
              left: AppStyles.spacingMedium,
              right: AppStyles.spacingMedium,
              child: _buildBannerContent(anuncio),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedStatusBadge(Map<String, dynamic> anuncio) {
    final DateTime now = DateTime.now();
    final DateTime fechaInicio = DateTime.tryParse(anuncio['fechaInicio'] ?? '') ?? now;
    final DateTime fechaFin = DateTime.tryParse(anuncio['fechaFin'] ?? '') ?? now;
    
    final bool isActive = now.isAfter(fechaInicio) && now.isBefore(fechaFin);
    final bool isExpired = now.isAfter(fechaFin);
    final bool isPending = now.isBefore(fechaInicio);

    String status;
    Color statusColor;
    IconData statusIcon;

    if (isExpired) {
      status = 'Expirado';
      statusColor = AppStyles.errorColor;
      statusIcon = Icons.schedule_rounded;
    } else if (isPending) {
      status = 'Programado';
      statusColor = AppStyles.warningColor;
      statusIcon = Icons.schedule_rounded;
    } else {
      status = 'Activo';
      statusColor = AppStyles.successColor;
      statusIcon = Icons.check_circle_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusMax),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: AppStyles.spacingXSmall),
          Text(
            status,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteButton(String anuncioId) {
    return AnimatedContainer(
      duration: AppStyles.fastAnimation,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isDeleting ? null : () => _eliminarAnuncio(anuncioId),
          borderRadius: BorderRadius.circular(AppStyles.radiusMax),
          child: Container(
            padding: const EdgeInsets.all(AppStyles.spacingSmall),
            decoration: BoxDecoration(
              color: _isDeleting 
                  ? AppStyles.textSecondary.withOpacity(0.8)
                  : AppStyles.errorColor,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (_isDeleting 
                      ? AppStyles.textSecondary 
                      : AppStyles.errorColor).withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _isDeleting
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(
                    Icons.delete_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBannerContent(Map<String, dynamic> anuncio) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingSmall,
            vertical: AppStyles.spacingXSmall,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Text(
            'Anuncio',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        if (anuncio['descripcion'] != null && anuncio['descripcion'].isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppStyles.spacingSmall),
            child: Text(
              anuncio['descripcion'],
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildAnuncioDetailCard(Map<String, dynamic> anuncio) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy', 'es');
    final DateTime fechaInicio = DateTime.tryParse(anuncio['fechaInicio'] ?? '') ?? DateTime.now();
    final DateTime fechaFin = DateTime.tryParse(anuncio['fechaFin'] ?? '') ?? DateTime.now();
    final Duration duracion = fechaFin.difference(fechaInicio);
    final DateTime now = DateTime.now();
    final Duration tiempoRestante = fechaFin.difference(now);

    return Container(
      margin: const EdgeInsets.all(AppStyles.spacingMedium),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          side: BorderSide(
            color: AppStyles.dividerColor,
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de la tarjeta
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingSmall),
                    decoration: BoxDecoration(
                      color: AppStyles.infoColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusSmall),
                    ),
                    child: Icon(
                      Icons.info_outline_rounded,
                      color: AppStyles.infoColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingMedium),
                  Expanded(
                    child: Text(
                      'Detalles del Anuncio',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppStyles.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppStyles.spacingLarge),
              
              // Información de fechas en grid
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfoCard(
                      'Fecha de Inicio',
                      dateFormat.format(fechaInicio),
                      Icons.play_arrow_rounded,
                      AppStyles.successColor,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingMedium),
                  Expanded(
                    child: _buildDateInfoCard(
                      'Fecha de Fin',
                      dateFormat.format(fechaFin),
                      Icons.stop_rounded,
                      AppStyles.errorColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppStyles.spacingMedium),
              
              // Información adicional
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      'Duración',
                      '${duracion.inDays} días',
                      Icons.schedule_rounded,
                      AppStyles.infoColor,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingMedium),
                  Expanded(
                    child: _buildInfoChip(
                      'Tiempo Restante',
                      tiempoRestante.isNegative 
                          ? 'Expirado' 
                          : '${tiempoRestante.inDays} días',
                      Icons.timer_outlined,
                      tiempoRestante.isNegative 
                          ? AppStyles.errorColor 
                          : AppStyles.warningColor,
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

  Widget _buildDateInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: AppStyles.spacingXSmall),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppStyles.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppStyles.spacingXSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppStyles.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
      decoration: BoxDecoration(
        color: AppStyles.backgroundColor,
        borderRadius: BorderRadius.circular(AppStyles.radiusMax),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: AppStyles.spacingXSmall),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppStyles.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppStyles.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDotsIndicator() {
    if (_anuncios.length <= 1) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _anuncios.asMap().entries.map((entry) {
        final isActive = entry.key == _currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: isActive ? 24 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: isActive
                ? Theme.of(context).primaryColor
                : Colors.grey.withOpacity(0.4),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildShimmer(double width, double height) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          period: const Duration(milliseconds: 1500),
          child: Container(
            height: height,
            width: width,
            color: Colors.white,
            child: Stack(
              children: [
                // Fondo base
                Positioned.fill(
                  child: Container(
                    color: Colors.grey.shade300,
                  ),
                ),
                // Simular badges superiores
                Positioned(
                  top: AppStyles.spacingMedium,
                  left: AppStyles.spacingMedium,
                  child: Container(
                    width: 60,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                    ),
                  ),
                ),
                Positioned(
                  top: AppStyles.spacingMedium,
                  right: AppStyles.spacingMedium,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // Simular contenido inferior
                Positioned(
                  bottom: AppStyles.spacingMedium,
                  left: AppStyles.spacingMedium,
                  right: AppStyles.spacingMedium,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: AppStyles.spacingSmall),
                      Container(
                        width: width * 0.6,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(7),
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

  Widget _buildErrorImagePlaceholder(double width, double height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildLoadingState(double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: containerMargin,
      child: Column(
        children: [
          SizedBox(
            height: bannerHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) => _buildShimmer(
                screenWidth * viewportFraction - 12,
                bannerHeight,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Shimmer para los dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              3,
              (index) => Shimmer.fromColors(
                baseColor: Colors.grey.shade200,
                highlightColor: Colors.grey.shade50,
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(double height) {
    return Container(
      height: height,
      margin: containerMargin,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _mensajeError?.contains('internet') == true || _mensajeError?.contains('conexión') == true
                  ? Icons.wifi_off_rounded 
                  : _mensajeError?.contains('servidor') == true || _mensajeError?.contains('Servidor') == true
                      ? Icons.dns_rounded
                      : Icons.error_outline_rounded,
              color: AppStyles.errorColor,
              size: 48,
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            Text(
              _mensajeError ?? 'Error desconocido',
              style: TextStyle(
                color: AppStyles.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingSmall),
            Text(
              _mensajeError?.contains('internet') == true
                  ? 'Verifica tu conexión e intenta nuevamente'
                  : _mensajeError?.contains('servidor') == true || _mensajeError?.contains('Servidor') == true
                      ? 'El servicio no está disponible en este momento'
                      : 'No se pudieron cargar los anuncios',
              style: TextStyle(
                color: AppStyles.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingLarge),
            ElevatedButton.icon(
              onPressed: _cargarAnuncios,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.errorColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppStyles.spacingLarge,
                  vertical: AppStyles.spacingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingXLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ilustración animada
            TweenAnimationBuilder(
              duration: AppStyles.slowAnimation,
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppStyles.primaryColor.withOpacity(0.1),
                          AppStyles.accentColor.withOpacity(0.1),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.campaign_outlined,
                      color: AppStyles.primaryColor,
                      size: 60,
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: AppStyles.spacingXLarge),
            
            Text(
              "¡Todo listo para empezar!",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppStyles.spacingMedium),
            
            Text(
              "Crea tu primer anuncio para promocionar tu negocio y aumentar tus ventas.",
              style: TextStyle(
                fontSize: 16,
                color: AppStyles.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppStyles.spacingXLarge),
            
            // Botón call-to-action mejorado
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radiusMax),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.accentColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_rounded, size: 24),
                label: const Text("Crear Primer Anuncio"),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const GestionAnunciosScreen(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        return SlideTransition(
                          position: animation.drive(
                            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                                .chain(CurveTween(curve: Curves.easeOutCubic)),
                          ),
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      transitionDuration: AppStyles.normalAnimation,
                    ),
                  ).then((_) => _cargarAnuncios());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingXLarge,
                    vertical: AppStyles.spacingLarge,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMax),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: AppStyles.spacingMedium),
            
            // Texto de ayuda adicional
            TextButton.icon(
              onPressed: () {
                // Aquí podrías navegar a una página de ayuda o tutorial
                _mostrarToast("¡Pronto tendremos una guía completa!", success: true);
              },
              icon: Icon(
                Icons.help_outline_rounded,
                size: 16,
                color: AppStyles.textTertiary,
              ),
              label: Text(
                "¿Necesitas ayuda?",
                style: TextStyle(
                  color: AppStyles.textTertiary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}