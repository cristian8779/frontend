// categoria_list.dart
import 'package:flutter/material.dart';
import '../../../services/categoria_service.dart';
import '../categoria_preview_screen.dart';
import '../create_category_screen.dart';
import '/models/categoria.dart';
import '../styles/categoria_list_styles.dart'; // Import de los estilos

class CategoriaList extends StatelessWidget {
  final List<Map<String, dynamic>> categorias;
  final VoidCallback onCategoriasActualizadas;
  final int maxItemsToShow;

  const CategoriaList({
    super.key,
    required this.categorias,
    required this.onCategoriasActualizadas,
    this.maxItemsToShow = CategoriaDimensions.defaultMaxItems,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = CategoriaDimensions.getResponsiveDimensions(context);
        
        if (categorias.isEmpty) {
          return _buildEmptyState(context, dimensions);
        }

        final bool hasMoreItems = categorias.length > maxItemsToShow;
        final int itemsToShow = hasMoreItems ? maxItemsToShow - 1 : categorias.length;

        return SizedBox(
          height: dimensions['containerHeight']!,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: itemsToShow + (hasMoreItems ? 2 : 1),
            itemBuilder: (context, index) {
              // Botón "Ver más"
              if (hasMoreItems && index == itemsToShow) {
                return _buildViewMoreButton(context, dimensions);
              }
              
              // Botón "Agregar"
              if (index == itemsToShow + (hasMoreItems ? 1 : 0)) {
                return _buildAddButton(context, dimensions);
              }

              // Categorías normales
              return _buildCategoryItem(context, index, dimensions);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, Map<String, double> dimensions) {
    return SizedBox(
      height: dimensions['containerHeight']!,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.only(right: dimensions['padding']!),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    CategoriaTheme.categoryIcon,
                    size: dimensions['iconSize']! + 4,
                    color: CategoriaTheme.hintTextColor,
                  ),
                  SizedBox(height: CategoriaDimensions.defaultSpacing),
                  Text(
                    CategoriaConstants.noCategoriesTitle,
                    style: CategoriaTextStyles.getTitleStyle(dimensions),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CategoriaConstants.noCategoriesSubtitle,
                    style: CategoriaTextStyles.getSubtitleStyle(dimensions),
                  ),
                ],
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildAddButtonContent(context, dimensions),
              SizedBox(height: CategoriaDimensions.defaultSpacing),
              Text(
                CategoriaConstants.addButtonLabel,
                style: CategoriaTextStyles.getLabelStyle(dimensions),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(BuildContext context, int index, Map<String, double> dimensions) {
    final categoriaMap = categorias[index];
    late Categoria categoria;
    
    try {
      categoria = Categoria.fromJson(categoriaMap);
    } catch (e) {
      return const SizedBox();
    }

    return Padding(
      padding: EdgeInsets.only(right: dimensions['padding']!),
      child: GestureDetector(
        onTap: () => _navigateToCategoryPreview(context, categoria),
        child: Column(
          children: [
            Container(
              width: dimensions['itemWidth']!,
              height: dimensions['itemHeight']!,
              decoration: CategoriaDecorations.getCategoryItemDecoration(),
              child: ClipRRect(
                borderRadius: CategoriaLayout.fullBorderRadius,
                child: _buildCategoryImage(categoria, dimensions),
              ),
            ),
            SizedBox(height: CategoriaDimensions.defaultSpacing),
            SizedBox(
              width: dimensions['itemWidth']!,
              child: Text(
                categoria.nombre,
                textAlign: TextAlign.center,
                style: CategoriaTextStyles.getCategoryNameStyle(dimensions),
                overflow: TextOverflow.ellipsis,
                maxLines: CategoriaConstants.maxLines,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryImage(Categoria categoria, Map<String, double> dimensions) {
    if (categoria.imagen != null && categoria.imagen!.isNotEmpty) {
      return Image.network(
        categoria.imagen!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Icon(
          CategoriaTheme.brokenImageIcon, 
          size: dimensions['iconSize']!
        ),
      );
    } else {
      return Image.asset(
        CategoriaConstants.defaultImagePath,
        fit: BoxFit.cover,
      );
    }
  }

  Widget _buildViewMoreButton(BuildContext context, Map<String, double> dimensions) {
    final totalCategorias = categorias.length;
    final categoriasRestantes = totalCategorias - (maxItemsToShow - 1);
    
    return Padding(
      padding: EdgeInsets.only(right: dimensions['padding']!),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _navigateToAllCategories(context),
            child: Container(
              width: dimensions['itemWidth']!,
              height: dimensions['itemHeight']!,
              decoration: CategoriaDecorations.getViewMoreButtonDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CategoriaTheme.viewMoreIcon,
                    color: CategoriaTheme.whiteColor,
                    size: dimensions['iconSize']! - 8,
                  ),
                  SizedBox(height: CategoriaDimensions.defaultSpacing),
                  Container(
                    padding: CategoriaLayout.counterPadding,
                    decoration: CategoriaDecorations.getCounterDecoration(),
                    child: Text(
                      "+$categoriasRestantes",
                      style: CategoriaTextStyles.getCounterStyle(dimensions),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: CategoriaDimensions.defaultSpacing),
          Text(
            CategoriaConstants.viewMoreButtonLabel,
            style: CategoriaTextStyles.getLabelStyle(dimensions),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(BuildContext context, Map<String, double> dimensions) {
    return Padding(
      padding: EdgeInsets.only(right: dimensions['padding']!),
      child: Column(
        children: [
          _buildAddButtonContent(context, dimensions),
          SizedBox(height: CategoriaDimensions.defaultSpacing),
          Text(
            CategoriaConstants.addButtonLabel,
            style: CategoriaTextStyles.getLabelStyle(dimensions),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButtonContent(BuildContext context, Map<String, double> dimensions) {
    return GestureDetector(
      onTap: () => _navigateToCreateCategory(context),
      child: Container(
        width: dimensions['itemWidth']!,
        height: dimensions['itemHeight']!,
        decoration: CategoriaDecorations.getAddButtonDecoration(),
        child: Icon(
          CategoriaTheme.addIcon, 
          color: CategoriaTheme.whiteColor, 
          size: dimensions['iconSize']!,
        ),
      ),
    );
  }

  // Métodos de navegación
  Future<void> _navigateToCategoryPreview(BuildContext context, Categoria categoria) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoriaPreviewScreen(categoria: categoria),
      ),
    );

    if (resultado == true) {
      onCategoriasActualizadas();
    }
  }

  Future<void> _navigateToCreateCategory(BuildContext context) async {
    final creado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateCategoryScreen(),
      ),
    );

    if (creado == true) {
      onCategoriasActualizadas();
    }
  }

  Future<void> _navigateToAllCategories(BuildContext context) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TodasLasCategoriasScreen(
          categorias: categorias,
          onCategoriasActualizadas: onCategoriasActualizadas,
        ),
      ),
    );

    if (resultado == true) {
      onCategoriasActualizadas();
    }
  }
}

// Pantalla para mostrar todas las categorías - también refactorizada
class TodasLasCategoriasScreen extends StatefulWidget {
  final List<Map<String, dynamic>> categorias;
  final VoidCallback onCategoriasActualizadas;

  const TodasLasCategoriasScreen({
    super.key,
    required this.categorias,
    required this.onCategoriasActualizadas,
  });

  @override
  State<TodasLasCategoriasScreen> createState() => _TodasLasCategoriasScreenState();
}

class _TodasLasCategoriasScreenState extends State<TodasLasCategoriasScreen> {
  List<Map<String, dynamic>> categoriasList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    categoriasList = List.from(widget.categorias);
  }

  Future<void> _recargarCategorias() async {
    setState(() => isLoading = true);

    try {
      final service = CategoriaService();
      final nuevasCategorias = await service.obtenerCategorias();
      
      setState(() {
        categoriasList = nuevasCategorias;
        isLoading = false;
      });
      
      widget.onCategoriasActualizadas();
    } catch (e) {
      setState(() => isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${CategoriaConstants.errorLoadingCategories}${e.toString()}'),
            backgroundColor: CategoriaTheme.addButtonColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CategoriaTheme.backgroundColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        '${CategoriaConstants.allCategoriesTitle} (${categoriasList.length})',
        style: CategoriaTextStyles.appBarTitleStyle,
      ),
      backgroundColor: CategoriaTheme.whiteColor,
      elevation: 0,
      iconTheme: const IconThemeData(color: CategoriaTheme.primaryTextColor),
      actions: [
        IconButton(
          icon: const Icon(CategoriaTheme.addIcon),
          onPressed: () async {
            final creado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateCategoryScreen()),
            );
            if (creado == true) await _recargarCategorias();
          },
        ),
        IconButton(
          icon: const Icon(CategoriaTheme.refreshIcon),
          onPressed: _recargarCategorias,
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (categoriasList.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _recargarCategorias,
      child: _buildGrid(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CategoriaTheme.categoryIcon,
            size: CategoriaConstants.emptyStateIconSize,
            color: CategoriaTheme.placeholderIcon,
          ),
          const SizedBox(height: 16),
          Text(
            CategoriaConstants.noCategoriesAvailable,
            style: CategoriaTextStyles.getEmptyStateMainStyle(),
          ),
          SizedBox(height: CategoriaDimensions.defaultSpacing),
          Text(
            CategoriaConstants.createNewCategory,
            style: CategoriaTextStyles.getEmptyStateSubStyle(),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: CategoriaLayout.gridPadding,
      gridDelegate: CategoriaLayout.getGridDelegate(context),
      itemCount: categoriasList.length,
      itemBuilder: (context, index) => _buildGridItem(index),
    );
  }

  Widget _buildGridItem(int index) {
    final categoriaMap = categoriasList[index];
    late Categoria categoria;
    
    try {
      categoria = Categoria.fromJson(categoriaMap);
    } catch (e) {
      return const SizedBox();
    }

    return GestureDetector(
      onTap: () async {
        final resultado = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoriaPreviewScreen(categoria: categoria),
          ),
        );
        if (resultado == true) await _recargarCategorias();
      },
      child: Container(
        decoration: CategoriaDecorations.getGridCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: CategoriaLayout.topBorderRadius,
                child: _buildGridImage(categoria),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: CategoriaLayout.cardPadding,
                child: Center(
                  child: Text(
                    categoria.nombre,
                    textAlign: TextAlign.center,
                    style: CategoriaTextStyles.gridCategoryNameStyle,
                    overflow: TextOverflow.ellipsis,
                    maxLines: CategoriaConstants.maxLines,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridImage(Categoria categoria) {
    if (categoria.imagen != null && categoria.imagen!.isNotEmpty) {
      return Image.network(
        categoria.imagen!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          decoration: CategoriaDecorations.getImagePlaceholderDecoration(),
          child: Icon(
            CategoriaTheme.brokenImageIcon,
            size: CategoriaConstants.gridImageIconSize,
            color: CategoriaTheme.placeholderIcon,
          ),
        ),
      );
    } else {
      return Container(
        decoration: CategoriaDecorations.getImagePlaceholderDecoration(),
        child: Image.asset(
          CategoriaConstants.defaultImagePath,
          fit: BoxFit.cover,
        ),
      );
    }
  }
}