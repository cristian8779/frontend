import 'package:flutter/material.dart';
import '../../services/anuncio_service.dart';
import 'styles/selector_visual/selector_visual_colors.dart';
import 'styles/selector_visual/selector_visual_text_styles.dart';
import 'styles/selector_visual/selector_visual_decorations.dart';
import 'styles/selector_visual/selector_visual_constants.dart';


class SelectorVisualScreen extends StatefulWidget {
  final bool esProducto;

  const SelectorVisualScreen({super.key, required this.esProducto});

  @override
  State<SelectorVisualScreen> createState() => _SelectorVisualScreenState();
}

class _SelectorVisualScreenState extends State<SelectorVisualScreen>
    with SingleTickerProviderStateMixin {
  final AnuncioService _service = AnuncioService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _filteredItems = [];
  bool _loading = true;
  String _busqueda = '';
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _cargarDatos();
  }

  void _initAnimations() {
    _animationController = AnimationController(
      duration: Duration(milliseconds: SelectorVisualConstants.animationDuration),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _loading = true);

    try {
      final data = widget.esProducto
          ? await _service.obtenerProductos()
          : await _service.obtenerCategorias();

      setState(() {
        _items = data;
        _filteredItems = data;
        _loading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      setState(() => _loading = false);
      _mostrarError(e);
    }
  }

  void _mostrarError(dynamic error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: SelectorVisualColors.errorIcon),
            const SizedBox(width: SelectorVisualConstants.spacingMedium),
            Expanded(child: Text('Error al cargar los datos: $error')),
          ],
        ),
        backgroundColor: SelectorVisualColors.errorBackground,
        behavior: SnackBarBehavior.floating,
        shape: SelectorVisualDecorations.snackBarShape,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: SelectorVisualColors.errorActionText,
          onPressed: _cargarDatos,
        ),
      ),
    );
  }

  void _filtrar(String query) {
    setState(() {
      _busqueda = query;
      _filteredItems = _items
          .where((item) =>
              (item['nombre'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(query.toLowerCase()))
          .toList();
    });
  }

  void _limpiarBusqueda() {
    _searchController.clear();
    setState(() => _busqueda = '');
    _filtrar('');
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.esProducto ? 'producto' : 'categoría';

    return Scaffold(
      backgroundColor: SelectorVisualColors.backgroundColor,
      appBar: _buildAppBar(tipo),
      body: _loading
          ? _buildLoadingState(tipo)
          : _items.isEmpty
              ? _buildEmptyState()
              : _buildContentState(tipo),
    );
  }

  PreferredSizeWidget _buildAppBar(String tipo) {
    return AppBar(
      title: Text(
        'Seleccionar $tipo',
        style: SelectorVisualTextStyles.appBarTitle,
      ),
      backgroundColor: SelectorVisualColors.appBarBackground,
      foregroundColor: SelectorVisualColors.appBarForeground,
      elevation: 0,
      actions: [
        Container(
          margin: const EdgeInsets.only(right: SelectorVisualConstants.spacingMedium),
          decoration: SelectorVisualDecorations.closeButtonDecoration,
          child: IconButton(
            icon: const Icon(
              Icons.close_rounded,
              size: SelectorVisualConstants.closeIconSize,
            ),
            tooltip: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(String tipo) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SelectorVisualConstants.loadingContainerPadding),
            decoration: SelectorVisualDecorations.loadingContainer,
            child: Column(
              children: [
                SizedBox(
                  width: SelectorVisualConstants.loadingIndicatorSize,
                  height: SelectorVisualConstants.loadingIndicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: SelectorVisualConstants.loadingIndicatorStroke,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      SelectorVisualColors.loadingIndicator,
                    ),
                  ),
                ),
                const SizedBox(height: SelectorVisualConstants.spacingLarge),
                Text(
                  'Cargando ${tipo}s...',
                  style: SelectorVisualTextStyles.loadingText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SelectorVisualConstants.emptyContainerPadding),
            decoration: SelectorVisualDecorations.emptyContainer,
            child: Icon(
              widget.esProducto
                  ? Icons.inventory_2_outlined
                  : Icons.category_outlined,
              size: SelectorVisualConstants.emptyIconSize,
              color: SelectorVisualColors.emptyIconColor,
            ),
          ),
          const SizedBox(height: SelectorVisualConstants.spacingXLarge),
          const Text(
            'No hay elementos disponibles',
            style: SelectorVisualTextStyles.emptyTitle,
          ),
          const SizedBox(height: SelectorVisualConstants.spacingMedium),
          Text(
            'Intenta nuevamente más tarde',
            style: SelectorVisualTextStyles.emptySubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildContentState(String tipo) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          _buildSearchBar(tipo),
          if (_filteredItems.isNotEmpty) _buildResultCounter(tipo),
          Expanded(
            child: _filteredItems.isEmpty
                ? _buildNoResultsState()
                : _buildGridView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(String tipo) {
    return Container(
      margin: const EdgeInsets.all(SelectorVisualConstants.screenPadding),
      decoration: SelectorVisualDecorations.searchContainer,
      child: TextField(
        controller: _searchController,
        onChanged: _filtrar,
        style: SelectorVisualTextStyles.searchInput,
        decoration: SelectorVisualDecorations.searchInputDecoration(
          tipo,
          _busqueda.isNotEmpty,
        ).copyWith(
          suffixIcon: _busqueda.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.clear_rounded,
                    color: SelectorVisualColors.searchClearIcon,
                  ),
                  onPressed: _limpiarBusqueda,
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildResultCounter(String tipo) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SelectorVisualConstants.screenPadding,
      ),
      padding: const EdgeInsets.only(bottom: SelectorVisualConstants.spacingMedium),
      child: Row(
        children: [
          Text(
            '${_filteredItems.length} ${tipo}${_filteredItems.length != 1 ? 's' : ''} encontrado${_filteredItems.length != 1 ? 's' : ''}',
            style: SelectorVisualTextStyles.counterText,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(SelectorVisualConstants.noResultsContainerPadding),
            decoration: SelectorVisualDecorations.noResultsContainer,
            child: const Icon(
              Icons.search_off,
              size: SelectorVisualConstants.noResultsIconSize,
              color: SelectorVisualColors.noResultsIcon,
            ),
          ),
          const SizedBox(height: SelectorVisualConstants.spacingLarge),
          const Text(
            'No se encontraron resultados',
            style: SelectorVisualTextStyles.noResultsTitle,
          ),
          const SizedBox(height: SelectorVisualConstants.spacingMedium),
          Text(
            'Intenta con otros términos de búsqueda',
            style: SelectorVisualTextStyles.noResultsSubtitle,
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(
        SelectorVisualConstants.screenPadding,
        0,
        SelectorVisualConstants.screenPadding,
        SelectorVisualConstants.screenPadding,
      ),
      itemCount: _filteredItems.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > SelectorVisualConstants.gridBreakpoint
            ? SelectorVisualConstants.gridCrossAxisCountTablet
            : SelectorVisualConstants.gridCrossAxisCountMobile,
        childAspectRatio: SelectorVisualConstants.gridChildAspectRatio,
        crossAxisSpacing: SelectorVisualConstants.gridCrossAxisSpacing,
        mainAxisSpacing: SelectorVisualConstants.gridMainAxisSpacing,
      ),
      itemBuilder: (context, index) => _buildGridItem(index),
    );
  }

  Widget _buildGridItem(int index) {
    final item = _filteredItems[index];
    final nombre = item['nombre'] ?? 'Sin nombre';
    final imagen = item['imagen'] ?? '';

    return AnimatedContainer(
      duration: Duration(
        milliseconds: SelectorVisualConstants.cardAnimationBase +
            (index * SelectorVisualConstants.cardAnimationIncrement),
      ),
      curve: Curves.easeOutBack,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(SelectorVisualConstants.cardBorderRadius),
          onTap: () => Navigator.pop(context, item),
          child: Container(
            decoration: SelectorVisualDecorations.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: SelectorVisualConstants.cardImageFlex,
                  child: _buildCardImage(imagen),
                ),
                Expanded(
                  flex: SelectorVisualConstants.cardContentFlex,
                  child: _buildCardTitle(nombre),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardImage(String imagen) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(SelectorVisualConstants.cardBorderRadius),
      ),
      child: imagen.isNotEmpty
          ? Image.network(
              imagen,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: SelectorVisualColors.cardImagePlaceholder,
                  child: Center(
                    child: SizedBox(
                      width: SelectorVisualConstants.cardLoadingIndicatorSize,
                      height: SelectorVisualConstants.cardLoadingIndicatorSize,
                      child: CircularProgressIndicator(
                        strokeWidth: SelectorVisualConstants.cardLoadingIndicatorStroke,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          SelectorVisualColors.cardImageLoadingIndicator,
                        ),
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => _buildImageError(),
            )
          : _buildImagePlaceholder(),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: SelectorVisualColors.cardImagePlaceholder,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_rounded,
            size: SelectorVisualConstants.cardIconSize,
            color: SelectorVisualColors.cardIconColor,
          ),
          const SizedBox(height: SelectorVisualConstants.spacingSmall),
          Text(
            'Error al cargar',
            style: SelectorVisualTextStyles.cardImageError,
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: SelectorVisualColors.cardImagePlaceholder,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.esProducto
                ? Icons.inventory_2_outlined
                : Icons.category_outlined,
            size: SelectorVisualConstants.cardIconSize,
            color: SelectorVisualColors.cardIconColor,
          ),
          const SizedBox(height: SelectorVisualConstants.spacingSmall),
          Text(
            'Sin imagen',
            style: SelectorVisualTextStyles.cardNoImage,
          ),
        ],
      ),
    );
  }

  Widget _buildCardTitle(String nombre) {
    return Padding(
      padding: const EdgeInsets.all(SelectorVisualConstants.cardPadding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            nombre,
            textAlign: TextAlign.center,
            maxLines: SelectorVisualConstants.cardTitleMaxLines,
            overflow: TextOverflow.ellipsis,
            style: SelectorVisualTextStyles.cardTitle,
          ),
        ],
      ),
    );
  }
}