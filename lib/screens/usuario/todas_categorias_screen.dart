import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/categoria_provider.dart';
import '../usuario/productosPorCategoriaScreen.dart';
import '../../theme/todas_categorias/todas_categorias_theme.dart';

enum ViewMode { grid, list }

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
  ViewMode _viewMode = ViewMode.grid;
  static const String _viewModeKey = 'categorias_view_mode';

  @override
  void initState() {
    super.initState();
    debugPrint("🔥 [TodasCategoriasScreen] initState llamado");
    
    _loadViewModePreference();
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

  Future<void> _loadViewModePreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMode = prefs.getString(_viewModeKey);
      if (savedMode != null && mounted) {
        setState(() {
          _viewMode = savedMode == 'list' ? ViewMode.list : ViewMode.grid;
        });
        debugPrint("💾 [TodasCategoriasScreen] Preferencia cargada: $_viewMode");
      }
    } catch (e) {
      debugPrint("❌ [TodasCategoriasScreen] Error cargando preferencia: $e");
    }
  }

  Future<void> _saveViewModePreference(ViewMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_viewModeKey, mode == ViewMode.list ? 'list' : 'grid');
      debugPrint("💾 [TodasCategoriasScreen] Preferencia guardada: $mode");
    } catch (e) {
      debugPrint("❌ [TodasCategoriasScreen] Error guardando preferencia: $e");
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

  PreferredSizeWidget _buildAppBarWithToggle() {
    final originalAppBar = TodasCategoriasTheme.buildAppBar();
    
    // Si el AppBar original ya tiene actions, las preservamos
    final existingActions = originalAppBar is AppBar ? originalAppBar.actions ?? [] : [];
    
    return AppBar(
      title: originalAppBar is AppBar ? originalAppBar.title : const Text('Categorías'),
      backgroundColor: originalAppBar is AppBar ? originalAppBar.backgroundColor : null,
      elevation: originalAppBar is AppBar ? originalAppBar.elevation : null,
      leading: originalAppBar is AppBar ? originalAppBar.leading : null,
      actions: [
        ...existingActions,
        // Toggle sutil y moderno
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildViewToggleButton(
                  icon: Icons.grid_view_rounded,
                  isActive: _viewMode == ViewMode.grid,
                  onTap: () {
                    setState(() => _viewMode = ViewMode.grid);
                    _saveViewModePreference(ViewMode.grid);
                  },
                ),
                _buildViewToggleButton(
                  icon: Icons.view_list_rounded,
                  isActive: _viewMode == ViewMode.list,
                  onTap: () {
                    setState(() => _viewMode = ViewMode.list);
                    _saveViewModePreference(ViewMode.list);
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
      appBar: _buildAppBarWithToggle(),
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
            child: _viewMode == ViewMode.grid 
                ? _buildCategoriesGrid(provider.categorias)
                : _buildCategoriesList(provider.categorias),
          );
        },
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Icon(
            icon,
            size: 22,
            color: isActive 
                ? Theme.of(context).primaryColor
                : Colors.grey.shade600,
          ),
        ),
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

  Widget _buildCategoriesList(List<Map<String, dynamic>> categorias) {
    debugPrint("📋 [TodasCategoriasScreen] Pintando lista con ${categorias.length} categorías");

    if (categorias.isEmpty) {
      return TodasCategoriasTheme.buildEmptyCategoriesState();
    }

    return ListView.builder(
      key: const PageStorageKey('categoriasList'),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: categorias.length,
      itemBuilder: (context, index) => _buildCategoriaListTile(categorias[index]),
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

  Widget _buildCategoriaListTile(Map<String, dynamic> categoria) {
    final nombre = categoria['nombre'] ?? "Sin nombre";
    final imagenUrl = categoria['imagen'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen cuadrada
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagenUrl != null
                    ? CachedNetworkImage(
                        imageUrl: imagenUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 70,
                          height: 70,
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: Icon(
                          Icons.category,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              // Texto
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Flecha
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}