import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../providers/anuncio_provider.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({Key? key}) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  static const double aspectRatioML = 10 / 3;
  static const double maxBannerHeight = 240;
  static const double minBannerHeight = 120;
  static const EdgeInsets containerMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _monitorConnectivity();
  }

  void _monitorConnectivity() {
    Connectivity().onConnectivityChanged.listen((status) {
      final conectado = status != ConnectivityResult.none;
      if (mounted) {
        setState(() => _isConnected = conectado);
      }
    });
  }

  bool _shouldShowErrors() {
    return _isConnected;
  }

  double _calculateBannerHeight(double screenWidth, double screenHeight) {
    double height = (screenWidth - 32) / aspectRatioML;
    return height.clamp(minBannerHeight, screenHeight * 0.3);
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth >= 1400) return 0.6;
    if (screenWidth >= 1024) return 0.75;
    if (screenWidth >= 768) return 0.85;
    if (screenWidth >= 600) return 0.9;
    return 0.92;
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
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade50,
        period: const Duration(milliseconds: 1500),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDotsIndicator(BuildContext context, AnuncioProvider provider) {
    if (provider.anuncios.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: provider.anuncios.asMap().entries.map((entry) {
          final isActive = entry.key == provider.currentIndex;
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
      ),
    );
  }

  Widget _buildBannerItem(
      BuildContext context,
      Map<String, String> anuncio,
      double width,
      double height,
      ) {
    final deeplink = anuncio['deeplink'];
    final imageUrl = anuncio['imagen'] ?? '';

    return GestureDetector(
      onTap: () => context.read<AnuncioProvider>().navigateToDeeplink(context, deeplink),
      child: Container(
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
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: width,
                height: height,
                placeholder: (context, url) => _buildShimmer(width, height),
                errorWidget: (context, url, error) => Container(
                  width: width,
                  height: height,
                  color: Colors.grey.shade200,
                  child: Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                ),
                fadeInDuration: const Duration(milliseconds: 300),
                fadeOutDuration: const Duration(milliseconds: 100),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => context.read<AnuncioProvider>().navigateToDeeplink(context, deeplink),
                    splashColor: Colors.white.withOpacity(0.2),
                    highlightColor: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, double height) {
    if (!_shouldShowErrors()) {
      return const SizedBox.shrink();
    }

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
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error al cargar anuncios',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => context.read<AnuncioProvider>().loadAnuncios(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).primaryColor,
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: containerMargin,
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
    );
  }

  Widget _buildCarousel(BuildContext context, AnuncioProvider provider,
      double screenWidth, double bannerHeight, double viewportFraction) {
    return Container(
      margin: containerMargin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: screenWidth,
            height: bannerHeight,
            child: CarouselSlider.builder(
              itemCount: provider.anuncios.length,
              itemBuilder: (context, index, realIndex) {
                return _buildBannerItem(
                  context,
                  provider.anuncios[index],
                  screenWidth * viewportFraction - 12,
                  bannerHeight,
                );
              },
              options: CarouselOptions(
                height: bannerHeight,
                autoPlay: provider.anuncios.length > 1,
                autoPlayInterval: const Duration(seconds: 6),
                autoPlayAnimationDuration: const Duration(milliseconds: 1000),
                autoPlayCurve: Curves.easeOutCubic,
                enlargeCenterPage: false,
                viewportFraction: viewportFraction,
                enableInfiniteScroll: provider.anuncios.length > 1,
                pauseAutoPlayOnTouch: true,
                pauseAutoPlayOnManualNavigate: true,
                onPageChanged: (index, reason) {
                  provider.setCurrentIndex(index);
                },
              ),
            ),
          ),
          _buildModernDotsIndicator(context, provider),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = MediaQuery.of(context).size.height;
        final double bannerHeight = _calculateBannerHeight(screenWidth, screenHeight);
        final double viewportFraction = _getViewportFraction(screenWidth);

        return Consumer<AnuncioProvider>(
          builder: (context, provider, child) {
            // Mostrar shimmer solo al iniciar la app y antes de que el provider tenga datos
            if (provider.anuncios.isEmpty && provider.state == AnuncioState.loading) {
              return _buildLoadingState(screenWidth, bannerHeight, viewportFraction);
            }

            // Si hay anuncios, mostrar carousel
            if (provider.anuncios.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.prefetchImages(context);
              });
              return _buildCarousel(context, provider, screenWidth, bannerHeight, viewportFraction);
            }

            // Si hay error Y conexión, mostrar estado de error
            if (provider.state == AnuncioState.error && _shouldShowErrors()) {
              return _buildErrorState(context, bannerHeight);
            }

            // Para cualquier otro caso (sin anuncios, sin conexión, empty), ocultar completamente
            return const SizedBox.shrink();
          },
        );
      },
    );
  }
}