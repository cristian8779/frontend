import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../providers/categoria_provider.dart';
import '../screens/usuario/todas_categorias_screen.dart';

class CategoriasWidget extends StatefulWidget {
  final VoidCallback onVerMas;
  final Function(String) onCategoriaSeleccionada;
  final bool showNoConnectionScreen; // 🔹 NUEVO: Parámetro para controlar visibilidad

  const CategoriasWidget({
    Key? key,
    required this.onVerMas,
    required this.onCategoriaSeleccionada,
    this.showNoConnectionScreen = false, // 🔹 NUEVO: Por defecto false
  }) : super(key: key);

  @override
  State<CategoriasWidget> createState() => _CategoriasWidgetState();
}

class _CategoriasWidgetState extends State<CategoriasWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

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

  bool _shouldShowContent() {
    // 🔹 CAMBIO PRINCIPAL: No mostrar nada si estamos en pantalla sin conexión
    return !widget.showNoConnectionScreen;
  }

  bool _shouldShowErrors() {
    return _isConnected && !widget.showNoConnectionScreen;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // 🔹 OCULTAR COMPLETAMENTE si estamos en modo sin conexión
    if (!_shouldShowContent()) {
      return const SizedBox.shrink();
    }

    final categoriaProvider = Provider.of<CategoriaProvider>(context);
    final categorias = categoriaProvider.categorias;
    final isLoading = categoriaProvider.isLoading;
    final hasError = categoriaProvider.error != null;

    final size = MediaQuery.of(context).size;
    final double avatarSize = size.width * 0.14;
    final double fontSize = size.width * 0.03;
    final double iconSize = size.width * 0.085;

    // 🔹 No mostrar error si no hay conexión O si no debería mostrar errores
    if (hasError && categorias.isEmpty && !_shouldShowErrors()) {
      return const SizedBox.shrink();
    }

    // 🔹 Si hay error Y conexión, mostrar mensaje de error
    if (hasError && categorias.isEmpty && _shouldShowErrors()) {
      return Container(
        height: avatarSize * 1.8,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: iconSize, color: Colors.red.shade400),
            const SizedBox(height: 8),
            Text(
              "Error al cargar categorías",
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                Provider.of<CategoriaProvider>(context, listen: false)
                    .cargarCategorias(forceRefresh: true);
              },
              icon: Icon(Icons.refresh, size: fontSize + 2, color: Colors.red),
              label: Text(
                "Reintentar",
                style: TextStyle(fontSize: fontSize, color: Colors.red),
              ),
            ),
          ],
        ),
      );
    }

    // 🔹 Mostrar shimmer solo si está cargando, hay conexión y no hay categorías aún
    if (isLoading && categorias.isEmpty && _isConnected) {
      return SizedBox(
        height: avatarSize * 1.8,
        child: ListView.separated(
          physics: const BouncingScrollPhysics(),
          scrollDirection: Axis.horizontal,
          itemCount: 6,
          separatorBuilder: (_, __) => SizedBox(width: size.width * 0.03),
          itemBuilder: (context, index) => Column(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(height: size.height * 0.008),
              Container(
                width: avatarSize * 0.8,
                height: 10,
                color: Colors.grey.shade300,
              ),
            ],
          ),
        ),
      );
    }

    // 🔹 Si no hay categorías, no mostrar nada
    if (categorias.isEmpty) {
      return const SizedBox.shrink();
    }

    final categoriasLimitadas = categorias.take(10).toList();

    return SizedBox(
      height: avatarSize * 1.7,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        itemCount: categoriasLimitadas.length + 1,
        itemBuilder: (context, index) {
          if (index == categoriasLimitadas.length) {
            return _buildVerMas(context, avatarSize, fontSize, iconSize);
          }
          return _buildCategoriaItem(
            context,
            categoriasLimitadas[index],
            avatarSize,
            fontSize,
            iconSize,
          );
        },
      ),
    );
  }

  Widget _buildCategoriaItem(
    BuildContext context,
    Map<String, dynamic> categoria,
    double avatarSize,
    double fontSize,
    double iconSize,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () {
        widget.onCategoriaSeleccionada(categoria['_id']);
      },
      child: Container(
        width: avatarSize + 20,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: categoria['imagen'] ?? '',
                width: avatarSize,
                height: avatarSize,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey.shade200,
                  width: avatarSize,
                  height: avatarSize,
                ),
                errorWidget: (context, url, error) =>
                    Icon(Icons.category, size: iconSize, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              categoria['nombre'] ?? 'Sin nombre',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerMas(
    BuildContext context,
    double avatarSize,
    double fontSize,
    double iconSize,
  ) {
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () {
        widget.onVerMas();
      },
      child: Container(
        width: avatarSize + 20,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            CircleAvatar(
              radius: avatarSize / 2,
              backgroundColor: Colors.grey.shade100,
              child: Icon(Icons.more_horiz, size: iconSize, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              "Ver más",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}