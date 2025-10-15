// 📅 ANUNCIOS PROGRAMADOS SCREEN
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Importaciones de servicios
import '../../services/anuncio_service.dart';

// Importación de estilos
import 'styles/anuncio/styles_index.dart';

class AnunciosProgramadosScreen extends StatefulWidget {
  const AnunciosProgramadosScreen({super.key});

  @override
  State<AnunciosProgramadosScreen> createState() => _AnunciosProgramadosScreenState();
}

class _AnunciosProgramadosScreenState extends State<AnunciosProgramadosScreen> {
  final AnuncioService _anuncioService = AnuncioService();
  
  List<Map<String, dynamic>> _anunciosProgramados = [];
  bool _isLoading = true;
  bool _hasError = false;
  String? _mensajeError;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _cargarAnunciosProgramados();
  }

  Future<void> _cargarAnunciosProgramados() async {
    if (!mounted) return;
    
    setState(() {
      if (!_isRefreshing) {
        _isLoading = true;
      }
      _hasError = false;
      _mensajeError = null;
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Llamar al servicio para obtener anuncios programados
      final anuncios = await _anuncioService.obtenerAnunciosProgramados();

      if (!mounted) return;
      
      setState(() {
        _anunciosProgramados = anuncios;
        _isLoading = false;
        _hasError = false;
        _isRefreshing = false;
      });
      
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _hasError = true;
        _isLoading = false;
        _isRefreshing = false;
        _mensajeError = StyleUtilities.determineErrorMessage(e);
      });
    }
  }

  Future<void> _onRefresh() async {
    if (_isLoading || _isRefreshing) return;
    
    StyleUtilities.mediumHaptic();
    
    setState(() {
      _isRefreshing = true;
    });
    
    await _cargarAnunciosProgramados();
  }

  Future<void> _eliminarAnuncio(String id) async {
    StyleUtilities.mediumHaptic();

    final confirmar = await _mostrarDialogoConfirmacion();
    if (confirmar != true) return;

    try {
      final eliminado = await _anuncioService.eliminarAnuncio(id);
      if (!mounted) return;

      if (eliminado) {
        StyleUtilities.showStyledSnackBar(
          context,
          "Anuncio programado eliminado exitosamente", 
          isSuccess: true
        );
        setState(() {
          _anunciosProgramados.removeWhere((a) => a['_id'] == id);
        });
      } else {
        StyleUtilities.showStyledSnackBar(
          context,
          _anuncioService.message ?? 'Error al eliminar el anuncio',
          isSuccess: false
        );
      }
    } catch (e) {
      if (mounted) {
        StyleUtilities.showStyledSnackBar(
          context,
          StyleUtilities.determineErrorMessage(e), 
          isSuccess: false
        );
      }
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
          "¿Estás seguro de que deseas eliminar este anuncio programado?",
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
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      appBar: AppBar(
        title: const Text(
          "Anuncios Programados",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: WidgetStyles.primaryGradient,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppStyles.primaryColor,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading || _isRefreshing) {
      return _buildLoadingState();
    }
    
    if (_hasError) {
      return _buildErrorState();
    }
    
    if (_anunciosProgramados.isEmpty) {
      return _buildEmptyState();
    }
    
    return _buildAnunciosList();
  }

  Widget _buildLoadingState() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = AppStyles.calculateBannerHeight(screenWidth);
    
    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      itemCount: 3,
      itemBuilder: (context, index) => _buildShimmerCard(bannerHeight),
    );
  }

  Widget _buildShimmerCard(double bannerHeight) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
          ),
          child: Container(
            height: bannerHeight + 200, // altura de imagen + contenido
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorConfig = AppStyles.getErrorConfig(_mensajeError);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              errorConfig['icon'],
              color: errorConfig['color'],
              size: 64,
            ),
            const SizedBox(height: AppStyles.spacingLarge),
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
            const SizedBox(height: AppStyles.spacingXLarge),
            ElevatedButton.icon(
              onPressed: _cargarAnunciosProgramados,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: WidgetStyles.primaryElevatedButtonStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppStyles.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
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
                Icons.schedule_rounded,
                color: AppStyles.primaryColor,
                size: 50,
              ),
            ),
            const SizedBox(height: AppStyles.spacingXLarge),
            Text(
              "No hay anuncios programados",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppStyles.spacingMedium),
            Text(
              "Los anuncios programados para el futuro aparecerán aquí",
              style: WidgetStyles.bodyTextStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnunciosList() {
    return ListView.builder(
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      itemCount: _anunciosProgramados.length,
      itemBuilder: (context, index) {
        return _buildAnuncioCard(_anunciosProgramados[index]);
      },
    );
  }

  Widget _buildAnuncioCard(Map<String, dynamic> anuncio) {
    final DateTime fechaInicio = DateTime.tryParse(anuncio['fechaInicio'] ?? '') ?? DateTime.now();
    final DateTime fechaFin = DateTime.tryParse(anuncio['fechaFin'] ?? '') ?? DateTime.now();
    final Duration diasParaInicio = fechaInicio.difference(DateTime.now());
    final Duration duracion = fechaFin.difference(fechaInicio);
    final imageUrl = anuncio['imagen'] ?? '';
    
    // Calcular altura de imagen usando la misma lógica que anuncios_screen y BannerCarousel
    final double screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = AppStyles.calculateBannerHeight(screenWidth);

    return Container(
      margin: const EdgeInsets.only(bottom: AppStyles.spacingMedium),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusLarge),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del anuncio - CON MISMO TAMAÑO QUE ANUNCIOS_SCREEN Y BANNER_CAROUSEL
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppStyles.radiusLarge),
              ),
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: imageUrl,
                    height: bannerHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    fadeInDuration: const Duration(milliseconds: 300),
                    fadeOutDuration: const Duration(milliseconds: 100),
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade200,
                      highlightColor: Colors.grey.shade50,
                      period: const Duration(milliseconds: 1500),
                      child: Container(
                        height: bannerHeight,
                        color: Colors.white,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: bannerHeight,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                    ),
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
                            Colors.black.withOpacity(0.1),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Badge de programado
                  Positioned(
                    top: AppStyles.spacingMedium,
                    left: AppStyles.spacingMedium,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppStyles.spacingMedium,
                        vertical: AppStyles.spacingSmall,
                      ),
                      decoration: WidgetStyles.statusBadgeDecoration(AppStyles.warningColor),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: AppStyles.spacingXSmall),
                          Text(
                            'Programado',
                            style: WidgetStyles.badgeLabelStyle,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botón eliminar
                  Positioned(
                    top: AppStyles.spacingMedium,
                    right: AppStyles.spacingMedium,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _eliminarAnuncio(anuncio['_id']),
                        borderRadius: BorderRadius.circular(AppStyles.radiusMax),
                        child: Container(
                          padding: const EdgeInsets.all(AppStyles.spacingSmall),
                          decoration: WidgetStyles.circularButtonDecoration(
                            AppStyles.errorColor,
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Información del anuncio
            Padding(
              padding: const EdgeInsets.all(AppStyles.spacingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Descripción
                  if (anuncio['descripcion'] != null && anuncio['descripcion'].isNotEmpty)
                    Text(
                      anuncio['descripcion'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppStyles.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  
                  const SizedBox(height: AppStyles.spacingMedium),
                  
                  // Contador de días para inicio
                  Container(
                    padding: const EdgeInsets.all(AppStyles.spacingMedium),
                    decoration: BoxDecoration(
                      color: AppStyles.warningColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
                      border: Border.all(
                        color: AppStyles.warningColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          color: AppStyles.warningColor,
                          size: 20,
                        ),
                        const SizedBox(width: AppStyles.spacingSmall),
                        Expanded(
                          child: Text(
                            'Iniciará en ${diasParaInicio.inDays} días',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppStyles.warningColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: AppStyles.spacingMedium),
                  
                  // Grid de información
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoChip(
                          'Inicio',
                          StyleUtilities.formatDate(fechaInicio),
                          Icons.play_arrow_rounded,
                          AppStyles.successColor,
                        ),
                      ),
                      const SizedBox(width: AppStyles.spacingSmall),
                      Expanded(
                        child: _buildInfoChip(
                          'Fin',
                          StyleUtilities.formatDate(fechaFin),
                          Icons.stop_rounded,
                          AppStyles.errorColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppStyles.spacingSmall),
                  
                  _buildInfoChip(
                    'Duración',
                    '${duracion.inDays} días',
                    Icons.schedule_rounded,
                    AppStyles.infoColor,
                  ),
                ],
              ),
            ),
          ],
        ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
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
          Expanded(
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
}