import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_provider.dart';
import '../screens/usuario/todas_categorias_screen.dart';

class CategoriasWidget extends StatefulWidget {
  final VoidCallback onVerMas;
  final Function(String) onCategoriaSeleccionada;

  const CategoriasWidget({
    Key? key,
    required this.onVerMas,
    required this.onCategoriaSeleccionada,
  }) : super(key: key);

  @override
  State<CategoriasWidget> createState() => _CategoriasWidgetState();
}

class _CategoriasWidgetState extends State<CategoriasWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final categoriaProvider = Provider.of<CategoriaProvider>(context);
    final categorias = categoriaProvider.categorias;
    final isLoading = categoriaProvider.isLoading;

    final size = MediaQuery.of(context).size;
    final double avatarSize = size.width * 0.14;
    final double fontSize = size.width * 0.03;
    final double iconSize = size.width * 0.085;

    // 🚀 Mostrar shimmer solo si está cargando y no hay categorías aún
    if (isLoading && categorias.isEmpty) {
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
        // 🔥 USAR EL CALLBACK DEL PADRE - No navegar directamente
        // Esto permite que BienvenidaUsuarioScreen maneje la navegación
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
        // 🔥 USAR EL CALLBACK DEL PADRE
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