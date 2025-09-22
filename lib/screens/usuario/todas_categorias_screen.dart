import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_provider.dart';
import '../usuario/productosPorCategoriaScreen.dart';

class TodasCategoriasScreen extends StatefulWidget {
  final Function(String)? onCategoriaSeleccionada;

  const TodasCategoriasScreen({Key? key, this.onCategoriaSeleccionada})
      : super(key: key);

  @override
  State<TodasCategoriasScreen> createState() => _TodasCategoriasScreenState();
}

class _TodasCategoriasScreenState extends State<TodasCategoriasScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  void initState() {
    super.initState();
    debugPrint("🔥 [TodasCategoriasScreen] initState llamado");

    final categoriaProvider =
        Provider.of<CategoriaProvider>(context, listen: false);

    if (categoriaProvider.categorias.isEmpty) {
      debugPrint("📥 [TodasCategoriasScreen] No había categorías, cargando...");
      categoriaProvider.cargarCategorias();
    } else {
      debugPrint("✅ [TodasCategoriasScreen] Categorías ya en memoria, no recargo.");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("🔄 [TodasCategoriasScreen] didChangeDependencies llamado");
  }

  // ❌ Eliminado el dispose, para que no se destruya el estado
  // @override
  // void dispose() {
  //   debugPrint("🗑️ [TodasCategoriasScreen] dispose llamado");
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    super.build(context); // 👈 obligatorio con AutomaticKeepAliveClientMixin
    debugPrint("🎨 [TodasCategoriasScreen] build ejecutado");

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: Consumer<CategoriaProvider>(
        builder: (context, provider, _) {
          debugPrint(
              "👀 [TodasCategoriasScreen] Consumer rebuild -> isLoading=${provider.isLoading}, error=${provider.error}, categorias=${provider.categorias.length}");

          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF3498DB)),
            );
          }

          if (provider.error != null) {
            return _buildErrorState(provider);
          }

          return RefreshIndicator(
            onRefresh: () async {
              debugPrint("🔄 [TodasCategoriasScreen] Pull-to-refresh disparado");
              await provider.cargarCategorias(forceRefresh: true);
            },
            color: const Color(0xFF3498DB),
            child: _buildCategoriesGrid(provider.categorias),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F8F8),
      foregroundColor: Colors.black,
      title: const Text(
        "Categorías",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      elevation: 0,
      // 🎨 Borde redondeado en la parte inferior del AppBar
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildErrorState(CategoriaProvider provider) {
    debugPrint("❌ [TodasCategoriasScreen] Mostrando error: ${provider.error}");
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🎨 Contenedor con borde redondeado para el ícono de error
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE74C3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: const Color(0xFFE74C3C).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64, 
              color: Color(0xFFE74C3C)
            ),
          ),
          const SizedBox(height: 24),
          // 🎨 Contenedor con borde redondeado para el mensaje de error
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  "¡Ops! Algo salió mal",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.error ?? '',
                  style: const TextStyle(fontSize: 14, color: Color(0xFFE74C3C)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // 🎨 Botón con bordes más redondeados
          ElevatedButton.icon(
            onPressed: () {
              debugPrint("🔁 [TodasCategoriasScreen] Botón Reintentar presionado");
              provider.cargarCategorias(forceRefresh: true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3498DB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25), // 🎨 Más redondeado
              ),
              elevation: 4,
              shadowColor: const Color(0xFF3498DB).withOpacity(0.3),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              "Reintentar",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Map<String, dynamic>> categorias) {
    debugPrint("📦 [TodasCategoriasScreen] Pintando grid con ${categorias.length} categorías");

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = _getCrossAxisCount(width);
        final childAspectRatio = _getChildAspectRatio(width);
        final padding = _getPadding(width);

        return GridView.builder(
          key: const PageStorageKey('categoriasGrid'), // 👈 mantiene estado scroll
          padding: padding,
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 12, // 🎨 Más espacio entre elementos
            mainAxisSpacing: 12,
          ),
          itemCount: categorias.length,
          itemBuilder: (context, index) =>
              _buildCategoriaCard(categorias[index]),
        );
      },
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria) {
    final nombre = categoria['nombre'] ?? "Sin nombre";
    final imagenUrl = categoria['imagen'];

    return InkWell(
      onTap: () {
        debugPrint("👉 [TodasCategoriasScreen] Categoría seleccionada: $nombre");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductosPorCategoriaScreen(
              categoriaId: categoria['_id'],
              categoriaNombre: nombre,
            ),
            maintainState: true, // 👈 mantiene la pantalla en memoria
          ),
        );
      },
      borderRadius: BorderRadius.circular(20), // 🎨 Borde más redondeado
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // 🎨 Borde más redondeado
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08), // 🎨 Sombra más sutil
              blurRadius: 8,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
          // 🎨 Borde sutil opcional
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(16), // 🎨 Padding más uniforme
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12), // 🎨 Imagen con bordes redondeados
                  child: (imagenUrl != null && imagenUrl.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: imagenUrl,
                          fit: BoxFit.contain,
                          placeholder: (context, url) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2)
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.category_rounded,
                              size: 48,
                              color: Colors.grey
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.category_rounded,
                            size: 48,
                            color: Colors.grey
                          ),
                        ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  // 🎨 Fondo sutil para el texto
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600, // 🎨 Texto un poco más bold
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  double _getChildAspectRatio(double width) => 0.9;
  EdgeInsets _getPadding(double width) => const EdgeInsets.all(12); // 🎨 Padding aumentado

  @override
  bool get wantKeepAlive => true;
}