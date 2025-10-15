// 📱 ANUNCIOS SCREEN REFACTORIZADO
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../services/anuncio_service.dart';
import 'gestion_anuncios_screen.dart';
import 'anuncio_programados.dart';
import 'styles/anuncio/styles_index.dart';

class AnunciosScreen extends StatefulWidget {
  const AnunciosScreen({super.key});

  @override
  State<AnunciosScreen> createState() => _AnunciosScreenState();
}

class _AnunciosScreenState extends State<AnunciosScreen> with TickerProviderStateMixin {
  final AnuncioService _anuncioService = AnuncioService();
  
  List<Map<String, dynamic>> _anuncios = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _mensajeError;
  int _currentIndex = 0;
  bool _isDeleting = false;
  bool _isRefreshing = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarAnuncios();
  }

  void _initAnimations() {
    _fadeController = StyleUtilities.createStandardController(vsync: this);
    _slideController = StyleUtilities.createStandardController(vsync: this);
    
    _fadeAnimation = StyleUtilities.createFadeAnimation(_fadeController);
    _slideAnimation = StyleUtilities.createSlideAnimation(_slideController);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _cargarAnuncios() async {
    if (!mounted) return;
    
    setState(() {
      if (!_isRefreshing) {
        _isLoading = true;
      }
      _hasError = false;
      _mensajeError = null;
    });

    _fadeController.reset();
    _slideController.reset();

    try {
      await Future.delayed(const Duration(milliseconds: 600));
      final anuncios = await _anuncioService.obtenerAnunciosActivosConId();

      if (!mounted) return;
      
      setState(() {
        _anuncios = anuncios;
        _isLoading = false;
        _hasError = false;
        _isRefreshing = false;
        if (_anuncios.isEmpty) {
          _currentIndex = 0;
        }
      });
      
      _fadeController.forward();
      _slideController.forward();
      
      if (mounted && _anuncios.isNotEmpty) {
        _prefetchImages();
      }
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
        _mensajeError = StyleUtilities.determineErrorMessage(e);
      });
      _fadeController.forward();
    }
  }

  Future<void> _onRefresh() async {
    if (_isLoading || _isRefreshing) return;
    
    StyleUtilities.mediumHaptic();
    
    setState(() {
      _isRefreshing = true;
    });
    
    await _cargarAnuncios();
  }

  Future<void> _prefetchImages() async {
    final imagesToPrefetch = _anuncios.take(3).toList();
    for (int i = 0; i < imagesToPrefetch.length; i++) {
      final url = imagesToPrefetch[i]['imagen'];
      if (StyleUtilities.isValidImageUrl(url) && mounted) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          );
        } catch (_) {}
      }
    }
  }

  Future<void> _eliminarAnuncio(String id) async {
    if (_isDeleting) return;
    
    StyleUtilities.mediumHaptic();

    final confirmar = await _mostrarDialogoConfirmacion();
    if (confirmar != true) return;

    // ✅ Verificar mounted después del diálogo
    if (!mounted) return;

    setState(() => _isDeleting = true);

    try {
      final eliminado = await _anuncioService.eliminarAnuncio(id);
      
      // ✅ Verificar mounted después de la operación asíncrona
      if (!mounted) return;

      if (eliminado) {
        // ✅ Actualizar estado primero
        setState(() {
          _anuncios.removeWhere((a) => a['_id'] == id);
          
          if (_anuncios.isEmpty) {
            _currentIndex = 0;
          } else if (_currentIndex >= _anuncios.length) {
            _currentIndex = _anuncios.length - 1;
          }
          _isDeleting = false;
        });
        
        // ✅ Verificar mounted antes de mostrar SnackBar
        if (!mounted) return;
        
        StyleUtilities.showStyledSnackBar(
          context,
          "Anuncio eliminado exitosamente", 
          isSuccess: true
        );
      } else {
        // ✅ Verificar mounted antes de mostrar SnackBar
        if (!mounted) return;
        
        setState(() => _isDeleting = false);
        
        StyleUtilities.showStyledSnackBar(
          context,
          _anuncioService.message ?? 'Error al eliminar el anuncio',
          isSuccess: false
        );
      }
    } catch (e) {
      // ✅ Verificar mounted antes de usar context
      if (!mounted) return;
      
      setState(() => _isDeleting = false);
      
      StyleUtilities.showStyledSnackBar(
        context,
        StyleUtilities.determineErrorMessage(e), 
        isSuccess: false
      );
    }
  }

  Future<bool?> _mostrarDialogoConfirmacion() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: WidgetStyles.dialogShape,
        elevation: AppStyles.elevationXLarge,
        backgroundColor: AppStyles.surfaceColor,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingSmall),
              decoration: WidgetStyles.iconContainerDecoration(AppStyles.errorColor),
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
        content: Text(
          "¿Estás seguro de que deseas eliminar este anuncio? Esta acción no se puede deshacer.",
          style: WidgetStyles.bodyTextStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: WidgetStyles.secondaryTextButtonStyle,
            child: const Text(
              "Cancelar",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: WidgetStyles.errorElevatedButtonStyle,
            child: const Text(
              "Eliminar",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = AppStyles.calculateBannerHeight(screenWidth);
    final double viewportFraction = AppStyles.getViewportFraction(screenWidth);

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
              child: _isLoading || _isRefreshing
                  ? _buildShimmerContent(screenWidth, bannerHeight, viewportFraction)
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Column(
                          children: [
                            if (!_hasError && _anuncios.isNotEmpty)
                              _buildHeaderInfo(),

                            AnimatedSwitcher(
                              duration: AppStyles.normalAnimation,
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              child: _buildBodyContent(screenWidth, bannerHeight, viewportFraction),
                            ),

                            if (!_hasError && _anuncios.isNotEmpty)
                              _buildAnuncioDetailCard(_anuncios[_currentIndex]),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: (_isLoading || _isRefreshing || _anuncios.isEmpty)
          ? null
          : _buildFloatingActionButton(),
    );
  }

  Widget _buildShimmerContent(double screenWidth, double bannerHeight, double viewportFraction) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(
            AppStyles.spacingMedium,
            AppStyles.spacingLarge,
            AppStyles.spacingMedium,
            AppStyles.spacingSmall,
          ),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
              ),
              child: Container(
                height: 80,
                padding: const EdgeInsets.all(AppStyles.spacingMedium),
              ),
            ),
          ),
        ),
        
        _buildLoadingState(screenWidth, bannerHeight, viewportFraction),
        
        Container(
          margin: const EdgeInsets.all(AppStyles.spacingMedium),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade200,
            highlightColor: Colors.grey.shade50,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
              ),
              child: Container(
                height: 250,
                padding: const EdgeInsets.all(AppStyles.spacingLarge),
              ),
            ),
          ),
        ),
      ],
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
      actions: [
        IconButton(
          icon: const Icon(Icons.schedule_rounded),
          tooltip: 'Ver anuncios programados',
          onPressed: () {
            StyleUtilities.lightHaptic();
            Navigator.push(
              context,
              StyleUtilities.slideRightTransition(
                const AnunciosProgramadosScreen(),
              ),
            ).then((_) => _cargarAnuncios());
          },
        ),
        const SizedBox(width: 8),
      ],
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
            gradient: WidgetStyles.primaryGradient,
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
                decoration: WidgetStyles.iconContainerDecoration(AppStyles.primaryColor),
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
                      style: WidgetStyles.subtitleStyle,
                    ),
                    Text(
                      'Desliza hacia abajo para actualizar',
                      style: WidgetStyles.captionStyle,
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
        gradient: WidgetStyles.accentGradient,
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
        style: WidgetStyles.badgeLabelStyle,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: WidgetStyles.fabDecoration,
      child: FloatingActionButton.extended(
        onPressed: () {
          StyleUtilities.lightHaptic();
          Navigator.push(
            context,
            StyleUtilities.slideRightTransition(const GestionAnunciosScreen()),
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
    if (_hasError) return _buildErrorState(bannerHeight);
    if (_anuncios.isEmpty) return _buildEmptyState();
    return _buildCarruselAnuncios(screenWidth, bannerHeight, viewportFraction);
  }

  Widget _buildCarruselAnuncios(double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: AppStyles.containerMargin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
                    StyleUtilities.selectionHaptic();
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
      decoration: WidgetStyles.carouselItemDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
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

            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: WidgetStyles.imageOverlayGradient,
                ),
              ),
            ),

            Positioned(
              top: AppStyles.spacingMedium,
              left: AppStyles.spacingMedium,
              child: _buildEnhancedStatusBadge(anuncio),
            ),

            Positioned(
              top: AppStyles.spacingMedium,
              right: AppStyles.spacingMedium,
              child: _buildDeleteButton(anuncio['_id']),
            ),

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
    
    final statusConfig = AppStyles.getStatusBadgeConfig(fechaInicio, fechaFin);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppStyles.spacingMedium,
        vertical: AppStyles.spacingSmall,
      ),
      decoration: WidgetStyles.statusBadgeDecoration(statusConfig['color']),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusConfig['icon'],
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: AppStyles.spacingXSmall),
          Text(
            statusConfig['status'],
            style: WidgetStyles.badgeLabelStyle,
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
            decoration: WidgetStyles.circularButtonDecoration(
              AppStyles.errorColor,
              isDisabled: _isDeleting,
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingSmall),
                    decoration: WidgetStyles.iconContainerDecoration(AppStyles.infoColor),
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
                      style: WidgetStyles.sectionTitleStyle,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppStyles.spacingLarge),
              
              Row(
                children: [
                  Expanded(
                    child: _buildDateInfoCard(
                      'Fecha de Inicio',
                      StyleUtilities.formatDate(fechaInicio),
                      Icons.play_arrow_rounded,
                      AppStyles.successColor,
                    ),
                  ),
                  const SizedBox(width: AppStyles.spacingMedium),
                  Expanded(
                    child: _buildDateInfoCard(
                      'Fecha de Fin',
                      StyleUtilities.formatDate(fechaFin),
                      Icons.stop_rounded,
                      AppStyles.errorColor,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: AppStyles.spacingMedium),
              
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
      decoration: WidgetStyles.successCardDecoration,
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
                  style: WidgetStyles.captionStyle.copyWith(fontWeight: FontWeight.w600),
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
      decoration: WidgetStyles.infoChipDecoration(color),
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
    if (_anuncios.isEmpty || _anuncios.length <= 1) {
      return const SizedBox.shrink();
    }

    final safeCurrentIndex = _currentIndex.clamp(0, _anuncios.length - 1);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _anuncios.asMap().entries.map((entry) {
        final isActive = entry.key == safeCurrentIndex;
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
      decoration: WidgetStyles.carouselItemDecoration,
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
                Positioned.fill(
                  child: Container(
                    color: Colors.grey.shade300,
                  ),
                ),
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
      decoration: WidgetStyles.errorImagePlaceholderDecoration,
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildLoadingState(double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: AppStyles.containerMargin,
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
    final errorConfig = AppStyles.getErrorConfig(_mensajeError);
    
    return Container(
      constraints: BoxConstraints(
        minHeight: height * 0.8,
        maxHeight: height,
      ),
      margin: AppStyles.containerMargin,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppStyles.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                errorConfig['icon'],
                color: errorConfig['color'],
                size: 48,
              ),
              const SizedBox(height: AppStyles.spacingMedium),
              Text(
                errorConfig['title'],
                style: WidgetStyles.subtitleStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacingSmall),
              Text(
                errorConfig['subtitle'],
                style: WidgetStyles.bodyTextStyle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppStyles.spacingLarge),
              ElevatedButton.icon(
                onPressed: _cargarAnuncios,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reintentar'),
                style: WidgetStyles.errorElevatedButtonStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        child: Padding(
          padding: StyleUtilities.getResponsivePadding(context),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder(
                duration: AppStyles.slowAnimation,
                tween: Tween<double>(begin: 0.8, end: 1.0),
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 80,
                      height: 80,
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
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: AppStyles.spacingLarge),
              
              Text(
                "¡Todo listo para empezar!",
                style: TextStyle(
                  fontSize: StyleUtilities.getResponsiveFontSize(
                    context, 
                    mobile: 20,
                    tablet: 24,
                    desktop: 28
                  ),
                  fontWeight: FontWeight.bold,
                  color: AppStyles.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppStyles.spacingMedium),
              
              Text(
                "Crea tu primer anuncio para promocionar tu negocio y aumentar tus ventas.",
                style: WidgetStyles.bodyTextStyle.copyWith(
                  fontSize: StyleUtilities.getResponsiveFontSize(
                    context,
                    mobile: 14,
                    tablet: 16,
                  )
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppStyles.spacingXLarge),
              
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
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    "Crear Primer Anuncio",
                    style: TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    StyleUtilities.lightHaptic();
                    Navigator.push(
                      context,
                      StyleUtilities.slideUpTransition(const GestionAnunciosScreen()),
                    ).then((_) => _cargarAnuncios());
                  },
                  style: WidgetStyles.primaryElevatedButtonStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}