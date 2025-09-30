import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../providers/categoria_provider.dart';
import '../usuario/productosPorCategoriaScreen.dart';
import '../../theme/todas_categorias/todas_categorias_theme.dart';

class TodasCategoriasScreen extends StatefulWidget {
  final Function(String)? onCategoriaSeleccionada;

  const TodasCategoriasScreen({Key? key, this.onCategoriaSeleccionada})
      : super(key: key);

  @override
  State<TodasCategoriasScreen> createState() => _TodasCategoriasScreenState();
}

class _TodasCategoriasScreenState extends State<TodasCategoriasScreen>
    with AutomaticKeepAliveClientMixin {
  
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    debugPrint("🔥 [TodasCategoriasScreen] initState llamado");
    
    _monitorConnectivity();

    final categoriaProvider =
        Provider.of<CategoriaProvider>(context, listen: false);

    if (categoriaProvider.categorias.isEmpty) {
      debugPrint("📥 [TodasCategoriasScreen] No había categorías, cargando...");
      categoriaProvider.cargarCategorias();
    } else {
      debugPrint("✅ [TodasCategoriasScreen] Categorías ya en memoria, no recargo.");
    }
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint("🔄 [TodasCategoriasScreen] didChangeDependencies llamado");
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    debugPrint("🎨 [TodasCategoriasScreen] build ejecutado");

    return Scaffold(
      backgroundColor: TodasCategoriasTheme.backgroundColor,
      appBar: TodasCategoriasTheme.buildAppBar(),
      body: Consumer<CategoriaProvider>(
        builder: (context, provider, _) {
          debugPrint(
              "👀 [TodasCategoriasScreen] Consumer rebuild -> isLoading=${provider.isLoading}, error=${provider.error}, categorias=${provider.categorias.length}");

          if (provider.isLoading && provider.categorias.isEmpty) {
            return TodasCategoriasTheme.buildLoadingIndicator();
          }

          if (provider.error != null && provider.categorias.isEmpty) {
            if (!_shouldShowErrors()) {
              return TodasCategoriasTheme.buildNoConnectionState();
            }
            return TodasCategoriasTheme.buildErrorState(
              provider.error,
              () {
                debugPrint("🔁 [TodasCategoriasScreen] Botón Reintentar presionado");
                provider.cargarCategorias(forceRefresh: true);
              },
            );
          }

          return TodasCategoriasTheme.buildRefreshIndicator(
            onRefresh: () async {
              debugPrint("🔄 [TodasCategoriasScreen] Pull-to-refresh disparado");
              await provider.cargarCategorias(forceRefresh: true);
            },
            child: _buildCategoriesGrid(provider.categorias),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesGrid(List<Map<String, dynamic>> categorias) {
    debugPrint("📦 [TodasCategoriasScreen] Pintando grid con ${categorias.length} categorías");

    if (categorias.isEmpty) {
      return TodasCategoriasTheme.buildEmptyCategoriesState();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = TodasCategoriasTheme.getCrossAxisCount(width);
        final childAspectRatio = TodasCategoriasTheme.getChildAspectRatio(width);

        return GridView.builder(
          key: const PageStorageKey('categoriasGrid'),
          padding: TodasCategoriasTheme.getGridPadding(),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: TodasCategoriasTheme.getGridDelegate(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: categorias.length,
          itemBuilder: (context, index) => _buildCategoriaCard(categorias[index]),
        );
      },
    );
  }

  Widget _buildCategoriaCard(Map<String, dynamic> categoria) {
    final nombre = categoria['nombre'] ?? "Sin nombre";
    final imagenUrl = categoria['imagen'];

    return TodasCategoriasTheme.buildCategoriaCard(
      nombre: nombre,
      imagenUrl: imagenUrl,
      onTap: () {
        debugPrint("👉 [TodasCategoriasScreen] Categoría seleccionada: $nombre");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductosPorCategoriaScreen(
              categoriaId: categoria['_id'],
              categoriaNombre: nombre,
            ),
            maintainState: true,
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}