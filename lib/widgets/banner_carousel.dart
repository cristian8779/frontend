import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/anuncio_service.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({Key? key}) : super(key: key);

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final AnuncioService _anuncioService = AnuncioService();

  List<Map<String, String>> _anuncios = [];
  bool _isLoading = true;
  bool _hasError = false;
  int _currentIndex = 0;

  // Relación similar a Mercado Libre (~3.33:1)
  static const double aspectRatioML = 10 / 3;
  static const double maxBannerHeight = 240;
  static const double minBannerHeight = 120;
  static const EdgeInsets containerMargin =
      EdgeInsets.symmetric(horizontal: 16, vertical: 12);

  @override
  void initState() {
    super.initState();
    _loadAnuncios();
  }

  double _calculateBannerHeight(double screenWidth, double screenHeight) {
    double height = (screenWidth - 32) / aspectRatioML; // margen horizontal
    // 🔹 límite dinámico respecto al alto de pantalla
    return height.clamp(minBannerHeight, screenHeight * 0.3);
  }

  double _getViewportFraction(double screenWidth) {
    if (screenWidth >= 1400) return 0.6; // 🔹 desktop grande: se ven 2 banners
    if (screenWidth >= 1024) return 0.75;
    if (screenWidth >= 768) return 0.85;
    if (screenWidth >= 600) return 0.9;
    return 0.92;
  }

  Future<void> _loadAnuncios() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final anuncios = await _anuncioService.obtenerAnunciosActivos();
      setState(() {
        _anuncios = anuncios;
      });

      if (mounted) {
        _prefetchImages();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _prefetchImages() async {
    for (int i = 0; i < _anuncios.length && i < 3; i++) {
      final url = _anuncios[i]['imagen'];
      if (url != null && url.isNotEmpty && mounted) {
        try {
          await precacheImage(
            CachedNetworkImageProvider(url),
            context,
          );
        } catch (_) {}
      }
    }
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

  Widget _buildModernDotsIndicator() {
    if (_anuncios.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      child: Row(
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
      ),
    );
  }

  Widget _buildBannerItem(
      Map<String, String> anuncio, double width, double height) {
    final deeplink = anuncio['deeplink'];
    final imageUrl = anuncio['imagen'] ?? '';

    return GestureDetector(
      onTap: () {
        if (deeplink != null && deeplink.isNotEmpty) {
          Navigator.pushNamed(context, deeplink);
        }
      },
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
                    onTap: () {
                      if (deeplink != null && deeplink.isNotEmpty) {
                        Navigator.pushNamed(context, deeplink);
                      }
                    },
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
            Icon(Icons.wifi_off_rounded, color: Colors.grey.shade400, size: 32),
            const SizedBox(height: 8),
            Text(
              'Error de conexión',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadAnuncios,
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenWidth = constraints.maxWidth;
        final double screenHeight = MediaQuery.of(context).size.height;

        final double bannerHeight =
            _calculateBannerHeight(screenWidth, screenHeight);
        final double viewportFraction = _getViewportFraction(screenWidth);

        if (_isLoading) {
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

        if (_hasError) {
          return _buildErrorState(bannerHeight);
        }

        if (_anuncios.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: containerMargin,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
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
                    autoPlay: _anuncios.length > 1,
                    autoPlayInterval: const Duration(seconds: 6),
                    autoPlayAnimationDuration:
                        const Duration(milliseconds: 1000),
                    autoPlayCurve: Curves.easeOutCubic,
                    enlargeCenterPage: false,
                    viewportFraction: viewportFraction,
                    enableInfiniteScroll: _anuncios.length > 1,
                    pauseAutoPlayOnTouch: true,
                    pauseAutoPlayOnManualNavigate: true,
                    onPageChanged: (index, reason) {
                      if (mounted) {
                        setState(() {
                          _currentIndex = index;
                        });
                      }
                    },
                  ),
                ),
              ),
              _buildModernDotsIndicator(),
            ],
          ),
        );
      },
    );
  }
}
