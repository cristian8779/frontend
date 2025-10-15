import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:crud/screens/admin/widgets/producto_card.dart';
import 'package:crud/providers/producto_admin_provider.dart';
import '../../services/categoria_service.dart';
import 'crear_producto_screen.dart';
import 'gestionar_variaciones_screen.dart';
import 'dart:io';

// Importar estilos
import 'styles/gestion_producto/app_colors.dart';
import 'styles/gestion_producto/app_dimensions.dart';
import 'styles/gestion_producto/widget_styles.dart';
import 'styles/gestion_producto/animation_config.dart';

enum ConnectionState { online, offline, serverError, loading }

class BuscadorProductos extends StatefulWidget {
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final VoidCallback onClear;

  const BuscadorProductos({
    Key? key,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onClear,
  }) : super(key: key);

  @override
  State<BuscadorProductos> createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<BuscadorProductos>
    with SingleTickerProviderStateMixin {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _controller = TextEditingController(text: widget.busqueda);
    _animationController = AnimationController(
      duration: AnimationConfig.scaleAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: AnimationConfig.scaleAnimationBegin,
      end: AnimationConfig.scaleAnimationEnd,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    final horizontalPadding = AppDimensions.getHorizontalPadding(screenWidth);
    
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 4,
            ),
            decoration: WidgetStyles.searchBarDecoration(
              isFocused: _focusNode.hasFocus,
            ),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: widget.onBusquedaChanged,
              style: WidgetStyles.searchTextStyle(screenWidth),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.search,
                  color: _focusNode.hasFocus ? AppColors.primary : Colors.grey[600],
                  size: AppDimensions.getSearchIconSize(screenWidth),
                ),
                hintText: 'Buscar productos...',
                hintStyle: WidgetStyles.searchHintStyle(screenWidth),
                border: InputBorder.none,
                suffixIcon: widget.busqueda.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _controller.clear();
                          widget.onClear();
                        },
                        child: Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close,
                            size: isSmallScreen ? 14 : 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}

class GestionProductosScreen extends StatefulWidget {
  const GestionProductosScreen({super.key});

  @override
  _GestionProductosScreenState createState() => _GestionProductosScreenState();
}

class _GestionProductosScreenState extends State<GestionProductosScreen>
    with TickerProviderStateMixin {
  final CategoriaService categoriaService = CategoriaService();

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _listAnimationController;
  late AnimationController _staggeredAnimationController;
  
  late ScrollController _mainScrollController;

  List<Map<String, dynamic>> categorias = [];
  ConnectionState _connectionState = ConnectionState.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fadeAnimationController = AnimationController(
      duration: AnimationConfig.fadeAnimationDuration,
      vsync: this,
    );
    _listAnimationController = AnimationController(
      duration: AnimationConfig.listAnimationDuration,
      vsync: this,
    );
    _staggeredAnimationController = AnimationController(
      duration: AnimationConfig.staggeredAnimationDuration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: AnimationConfig.fadeAnimationBegin,
      end: AnimationConfig.fadeAnimationEnd,
    ).animate(
      CurvedAnimation(
        parent: _fadeAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _mainScrollController = ScrollController();
    _mainScrollController.addListener(_onScroll);

    _staggeredAnimationController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDatos();
    });
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _listAnimationController.dispose();
    _staggeredAnimationController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_mainScrollController.position.pixels >= 
        _mainScrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ProductoProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore && mounted) {
        provider.cargarMasProductos();
      }
    }
  }

  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> _cargarDatos() async {
    if (!mounted) return;
    
    setState(() {
      _connectionState = ConnectionState.loading;
      _errorMessage = null;
    });

    try {
      final hasInternet = await _checkInternetConnection();
      if (!hasInternet) {
        if (mounted) {
          setState(() {
            _connectionState = ConnectionState.offline;
          });
        }
        return;
      }

      categorias = await categoriaService.obtenerCategorias();
      
      final provider = Provider.of<ProductoProvider>(context, listen: false);
      
      final esPrimeraCarga = provider.state == ProductoState.initial;
      
      if (esPrimeraCarga) {
        debugPrint('🔄 Primera carga: Limpiando filtros');
        provider.mostrarTodosLosProductos();
        await provider.inicializar();
      } else {
        debugPrint('🔄 Recarga: Manteniendo filtros actuales');
        await provider.refrescar();
      }
      
      if (mounted) {
        setState(() {
          _connectionState = ConnectionState.online;
        });

        await Future.delayed(AnimationConfig.delayAfterLoading);
        if (mounted) {
          _fadeAnimationController.forward();
          _listAnimationController.forward();
        }
      }

    } on SocketException catch (_) {
      if (mounted) {
        setState(() {
          _connectionState = ConnectionState.offline;
          _errorMessage = 'Sin conexión a internet';
        });
      }
    } on HttpException catch (e) {
      if (mounted) {
        setState(() {
          _connectionState = ConnectionState.serverError;
          _errorMessage = 'Error del servidor: ${e.message}';
        });
      }
    } catch (e) {
      final errorMessage = _getErrorMessage(e.toString());
      if (mounted) {
        setState(() {
          _connectionState = ConnectionState.serverError;
          _errorMessage = errorMessage;
        });
        
        _mostrarSnackBar(
          errorMessage,
          AppColors.error,
          Icons.error_outline,
        );
      }
    }
  }

  String _getErrorMessage(String error) {
    if (error.toLowerCase().contains('timeout')) {
      return 'Tiempo de espera agotado. Verifica tu conexión.';
    } else if (error.toLowerCase().contains('host lookup failed')) {
      return 'No se puede conectar al servidor. Verifica tu conexión.';
    } else if (error.toLowerCase().contains('server')) {
      return 'El servidor no está disponible en este momento.';
    } else if (error.toLowerCase().contains('404')) {
      return 'Recurso no encontrado en el servidor.';
    } else if (error.toLowerCase().contains('500')) {
      return 'Error interno del servidor. Intenta más tarde.';
    } else {
      return 'Ocurrió un error inesperado. Intenta nuevamente.';
    }
  }

  void _mostrarSnackBar(String mensaje, Color color, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: AnimationConfig.snackBarDuration,
        action: color == AppColors.error ? SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarDatos,
        ) : null,
      ),
    );
  }

  Widget _buildShimmerElement({required Widget child, required int delay}) {
    return AnimatedBuilder(
      animation: _staggeredAnimationController,
      builder: (context, _) {
        final animationProgress = _staggeredAnimationController.value;
        final normalizedDelay = AnimationConfig.getNormalizedDelay(delay);
        final adjustedProgress = AnimationConfig.getAdjustedProgress(
          animationProgress,
          normalizedDelay,
        );
        
        if (adjustedProgress <= 0) {
          return Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: child,
          );
        }
        
        final opacity = Curves.easeOut.transform(adjustedProgress);
        final scale = AnimationConfig.shimmerScaleBegin + 
                     (AnimationConfig.shimmerScaleEnd * Curves.easeOutBack.transform(adjustedProgress));
        
        return Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildShimmerSearchBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = AppDimensions.getHorizontalPadding(screenWidth);
    
    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 4,
      ),
      decoration: WidgetStyles.cardDecoration(),
    );
  }

  Widget _buildShimmerStatsCard() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = AppDimensions.getCardPadding(screenWidth);
    final iconSize = AppDimensions.getStatsIconSize(screenWidth);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: WidgetStyles.cardDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(AppDimensions.iconContainerRadius),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 60,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerFilters() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = AppDimensions.getCardPadding(screenWidth);
    
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: WidgetStyles.filterContainerDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: screenWidth * 0.4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = AppDimensions.getCrossAxisCount(screenWidth);
    final itemCount = crossAxisCount * 3;
    
    return SizedBox(
      height: 600,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        padding: const EdgeInsets.symmetric(vertical: 8),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppDimensions.getGridSpacing(screenWidth),
          mainAxisSpacing: AppDimensions.getGridSpacing(screenWidth),
          childAspectRatio: AppDimensions.getChildAspectRatio(screenWidth),
        ),
        itemBuilder: (context, index) {
          return _buildShimmerElement(
            delay: 6 + index,
            child: Container(
              decoration: WidgetStyles.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 80,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionErrorState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    
    IconData icon;
    Color color;
    String title;
    String message;
    String actionText = 'Reintentar';

    switch (_connectionState) {
      case ConnectionState.offline:
        icon = Icons.wifi_off_rounded;
        color = AppColors.warning;
        title = 'Sin conexión a internet';
        message = 'Verifica tu conexión WiFi o datos móviles y vuelve a intentar.';
        break;
      case ConnectionState.serverError:
        icon = Icons.cloud_off_rounded;
        color = AppColors.error;
        title = 'Error del servidor';
        message = _errorMessage ?? 'El servidor no está disponible. Intenta más tarde.';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      height: AppDimensions.getErrorStateHeight(screenWidth),
      padding: EdgeInsets.all(AppDimensions.getEmptyStatePadding(screenWidth)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(AppDimensions.getIconPadding(screenWidth)),
            decoration: WidgetStyles.errorContainerDecoration(color),
            child: Icon(
              icon,
              size: AppDimensions.getErrorIconSize(screenWidth),
              color: color,
            ),
          ),
          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
          Text(
            title,
            style: WidgetStyles.errorTitleStyle(screenWidth),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppDimensions.getVerticalSpacing(screenWidth)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: WidgetStyles.errorMessageStyle(screenWidth),
          ),
          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth) + 4),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _cargarDatos,
                icon: const Icon(Icons.refresh),
                label: Text(actionText),
                style: WidgetStyles.secondaryButtonStyle(screenWidth, color),
              ),
              if (_connectionState == ConnectionState.offline)
                OutlinedButton.icon(
                  onPressed: () {
                    _mostrarSnackBar(
                      'Ve a Configuración > WiFi o Datos móviles',
                      AppColors.primary,
                      Icons.info_outline,
                    );
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Ayuda'),
                  style: WidgetStyles.outlinedButtonStyle(screenWidth, color),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrosYOrdenamiento() {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardPadding = AppDimensions.getCardPadding(screenWidth);
    final fontSize = AppDimensions.getLabelFontSize(screenWidth);
    
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: WidgetStyles.filterContainerDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
           Row(
  children: [
    Icon(
      Icons.filter_alt_outlined,
      color: AppColors.primary,
      size: AppDimensions.getFilterIconSize(screenWidth),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Text(
        'Filtros y ordenamiento',
        style: WidgetStyles.filterTitleStyle(screenWidth),
      ),
    ),
    if (provider.tieneFiltrosActivos) ...[
      TextButton(
        onPressed: provider.limpiarFiltros,
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth < 360 ? 8 : 12,
            vertical: 4,
          ),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Limpiar',
          style: TextStyle(
            fontSize: AppDimensions.getButtonTextFontSize(screenWidth),
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  ],
),
              SizedBox(height: AppDimensions.getVerticalSpacing(screenWidth)),
              
              DropdownButtonFormField<String>(
                value: provider.categoriaSeleccionada,
                isExpanded: true,
                decoration: WidgetStyles.dropdownDecoration(
                  labelText: 'Categoría',
                  prefixIcon: Icons.category_outlined,
                  screenWidth: screenWidth,
                ),
                style: WidgetStyles.dropdownItemStyle(screenWidth),
                dropdownColor: Colors.white,
                items: [
                  DropdownMenuItem<String>(
                    value: null,
                    child: Text(
                      'Todas las categorías',
                      style: WidgetStyles.dropdownItemStyle(screenWidth),
                    ),
                  ),
                  ...categorias.map((categoria) => DropdownMenuItem<String>(
                    value: categoria['_id'],
                    child: Text(
                      categoria['nombre'] ?? 'Sin nombre',
                      overflow: TextOverflow.ellipsis,
                      style: WidgetStyles.dropdownItemStyle(screenWidth),
                    ),
                  )),
                ],
                onChanged: (value) {
                  provider.filtrarPorCategoria(value);
                },
              ),
              
              SizedBox(height: AppDimensions.getVerticalSpacing(screenWidth)),
              
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: provider.sortBy,
                      isExpanded: true,
                      decoration: WidgetStyles.dropdownDecoration(
                        labelText: 'Ordenar por',
                        prefixIcon: Icons.sort,
                        screenWidth: screenWidth,
                      ),
                      style: WidgetStyles.dropdownItemStyle(screenWidth),
                      dropdownColor: Colors.white,
                      items: [
                        DropdownMenuItem(
                          value: 'nombre',
                          child: Text(
                            'Nombre', 
                            style: WidgetStyles.dropdownItemStyle(screenWidth),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'precio',
                          child: Text(
                            'Precio', 
                            style: WidgetStyles.dropdownItemStyle(screenWidth),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'fecha',
                          child: Text(
                            'Fecha', 
                            style: WidgetStyles.dropdownItemStyle(screenWidth),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        provider.cambiarOrdenamiento(value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: WidgetStyles.iconContainerDecoration(AppColors.primary),
                    child: IconButton(
                      onPressed: () {
                        provider.cambiarOrdenamiento(
                          provider.sortBy, 
                          ascending: !provider.sortAscending,
                        );
                      },
                      icon: Icon(
                        provider.sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                        color: AppColors.primary,
                        size: AppDimensions.getFilterIconSize(screenWidth),
                      ),
                      tooltip: provider.sortAscending ? 'Ascendente' : 'Descendente',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstadisticasHeader() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    final cardPadding = AppDimensions.getCardPadding(screenWidth);
    final containerPadding = AppDimensions.getContainerPadding(screenWidth);
    final iconSize = AppDimensions.getStatsIconSize(screenWidth);
    
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        return Container(
          padding: EdgeInsets.all(containerPadding),
          decoration: WidgetStyles.statsContainerDecoration(),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CrearProductoScreen(),
                      ),
                    );
                    if (result == true) {
                      provider.refrescar();
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.all(cardPadding),
                    decoration: WidgetStyles.cardDecoration(shadowColor: AppColors.primary),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 8.0 : 12.0),
                          decoration: WidgetStyles.iconContainerDecoration(AppColors.primary),
                          child: Icon(
                            Icons.add_box_outlined,
                            color: AppColors.primary,
                            size: iconSize,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        Text(
                          'Agregar Producto',
                          style: WidgetStyles.statsTitleStyle(screenWidth),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getVerticalSpacing(screenWidth)),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: WidgetStyles.cardDecoration(shadowColor: AppColors.secondary),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
                        decoration: WidgetStyles.iconContainerDecoration(AppColors.secondary),
                        child: Icon(
                          Icons.inventory_2_outlined,
                          color: Colors.green[700],
                          size: iconSize,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        '${provider.totalFiltrados}',
                        style: WidgetStyles.statsNumberStyle(screenWidth, AppColors.secondary),
                      ),
                      Text(
                        'Productos',
                        style: WidgetStyles.statsLabelStyle(screenWidth),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: AppDimensions.getVerticalSpacing(screenWidth)),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: WidgetStyles.cardDecoration(shadowColor: AppColors.accent),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallScreen ? 6.0 : 8.0),
                        decoration: WidgetStyles.iconContainerDecoration(AppColors.accent),
                        child: Icon(
                          Icons.category_outlined,
                          color: Colors.orange[700],
                          size: iconSize,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        '${categorias.length}',
                        style: WidgetStyles.statsNumberStyle(screenWidth, AppColors.accent),
                      ),
                      Text(
                        'Categorías',
                        style: WidgetStyles.statsLabelStyle(screenWidth),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

 Widget _buildEmptyState() {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final containerHeight = AppDimensions.getEmptyStateHeight(screenWidth, screenHeight);
  final padding = AppDimensions.getEmptyStatePadding(screenWidth);
  final iconSize = AppDimensions.getEmptyStateIconSize(screenWidth);
  final isVerySmall = screenWidth < 360 || screenHeight < 650;
  
  return Consumer<ProductoProvider>(
    builder: (context, provider, child) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: containerHeight,
          minHeight: 200,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(AppDimensions.getIconPadding(screenWidth)),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    provider.tieneFiltrosActivos ? Icons.search_off : Icons.inventory_2_outlined,
                    size: iconSize,
                    color: Colors.grey[400],
                  ),
                ),
                SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
                Text(
                  provider.tieneFiltrosActivos
                    ? 'No encontramos productos'
                    : 'No hay productos registrados',
                  style: WidgetStyles.emptyStateTitleStyle(screenWidth),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: AppDimensions.getVerticalSpacing(screenWidth)),
                Text(
                  provider.tieneFiltrosActivos
                    ? 'Intenta con otros filtros o términos de búsqueda.'
                    : 'Comienza agregando tu primer producto.',
                  textAlign: TextAlign.center,
                  style: WidgetStyles.emptyStateSubtitleStyle(screenWidth),
                ),
                if (!provider.tieneFiltrosActivos) ...[
                  SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CrearProductoScreen(),
                        ),
                      );
                      if (result == true) {
                        provider.refrescar();
                      }
                    },
                    icon: Icon(Icons.add, size: isVerySmall ? 18 : 20),
                    label: Text(
                      'Agregar producto',
                      style: TextStyle(fontSize: isVerySmall ? 13 : 15),
                    ),
                    style: WidgetStyles.primaryButtonStyle(screenWidth),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

  Widget _buildProductGrid() {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = AppDimensions.getCrossAxisCount(screenWidth);
    final spacing = AppDimensions.getGridSpacing(screenWidth);
    final childAspectRatio = AppDimensions.getChildAspectRatio(screenWidth);
    
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        final productos = provider.productosFiltrados;
        
        if (productos.isEmpty) return const SizedBox.shrink();
        
        return Column(
          children: [
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
                childAspectRatio: childAspectRatio,
              ),
              itemCount: productos.length,
              itemBuilder: (context, index) {
                final producto = productos[index];
                final productoId = producto['_id'] ?? producto['id'] ?? '';
                
                return AnimatedBuilder(
                  key: ValueKey('producto_${productoId}_${provider.state}'),
                  animation: _listAnimationController,
                  builder: (context, child) {
                    final animationProgress = _listAnimationController.value;
                    final itemDelay = AnimationConfig.getItemDelay(index);
                    final animationValue = AnimationConfig.getAnimationValue(
                      animationProgress,
                      itemDelay,
                    );
                    
                    final curvedValue = Curves.easeOutBack.transform(animationValue);
                    final opacity = curvedValue.clamp(0.0, 1.0);
                    final scale = (AnimationConfig.productCardScaleBegin + 
                                  (curvedValue * AnimationConfig.productCardScaleEnd))
                                  .clamp(0.0, 1.0);
                    
                    return Transform.scale(
                      scale: scale,
                      child: Opacity(
                        opacity: opacity,
                        child: ProductoCard(
                          key: ValueKey('card_$productoId'),
                          id: productoId,
                          producto: producto,
                          onProductoEliminado: () {
                            debugPrint('✅ Producto eliminado confirmado');
                          },
                          onProductoActualizado: () {
                            debugPrint('📝 Producto actualizado confirmado');
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            
            if (provider.isLoadingMore)
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Cargando más productos...',
                      style: WidgetStyles.loadingMoreStyle(),
                    ),
                  ],
                ),
              ),
              
            if (!provider.hasMore && productos.isNotEmpty && productos.length > 10)
              Container(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Has visto todos los productos (${productos.length})',
                  style: WidgetStyles.endOfListStyle(),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatus() {
    if (_connectionState == ConnectionState.online) return const SizedBox.shrink();
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_connectionState) {
      case ConnectionState.offline:
        statusColor = AppColors.warning;
        statusIcon = Icons.wifi_off;
        statusText = 'Sin conexión';
        break;
      case ConnectionState.serverError:
        statusColor = AppColors.error;
        statusIcon = Icons.cloud_off;
        statusText = 'Error del servidor';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: AppDimensions.getVerticalSpacing(screenWidth)),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 10 : 12,
      ),
      decoration: WidgetStyles.statusBarDecoration(statusColor),
      child: Row(
        children: [
          Icon(
            statusIcon,
            color: statusColor,
            size: AppDimensions.getFilterIconSize(screenWidth),
          ),
          SizedBox(width: isSmallScreen ? 10 : 12),
          Expanded(
            child: Text(
              statusText,
              style: WidgetStyles.statusTextStyle(screenWidth, statusColor),
            ),
          ),
          TextButton(
            onPressed: _cargarDatos,
            child: Text(
              'Reintentar',
              style: TextStyle(
                color: statusColor,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = AppDimensions.isSmallScreen(screenWidth);
    final padding = AppDimensions.getScreenPadding(screenWidth);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer<ProductoProvider>(
        builder: (context, provider, child) {
          final mostrarShimmer = _connectionState == ConnectionState.loading && 
                                 provider.state == ProductoState.initial;
          
          return RefreshIndicator(
            onRefresh: () async {
              await _cargarDatos();
            },
            child: CustomScrollView(
              controller: _mainScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: AppDimensions.getAppBarHeight(screenWidth),
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(
                      'Gestión de Productos',
                      style: WidgetStyles.appBarTitleStyle(screenWidth),
                    ),
                    centerTitle: true,
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.appBarGradient,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildConnectionStatus(),
                        
                        if (_connectionState == ConnectionState.offline ||
                            _connectionState == ConnectionState.serverError)
                          _buildConnectionErrorState()
                        else ...[
                          // Buscador
                          if (mostrarShimmer)
                            _buildShimmerElement(
                              delay: 0,
                              child: _buildShimmerSearchBar(),
                            )
                          else
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: BuscadorProductos(
                                busqueda: provider.busqueda,
                                onBusquedaChanged: (value) {
                                  provider.buscarProductos(value);
                                },
                                onClear: () {
                                  provider.buscarProductos('');
                                },
                              ),
                            ),
                          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
                          
                          // Estadísticas
                          if (mostrarShimmer)
                            _buildShimmerElement(
                              delay: 1,
                              child: Container(
                                padding: EdgeInsets.all(AppDimensions.getContainerPadding(screenWidth)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(AppDimensions.containerRadius),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: _buildShimmerStatsCard()),
                                    SizedBox(width: AppDimensions.getVerticalSpacing(screenWidth)),
                                    Expanded(child: _buildShimmerStatsCard()),
                                    SizedBox(width: AppDimensions.getVerticalSpacing(screenWidth)),
                                    Expanded(child: _buildShimmerStatsCard()),
                                  ],
                                ),
                              ),
                            )
                          else
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildEstadisticasHeader(),
                            ),
                          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
                          
                          // Filtros
                          if (mostrarShimmer)
                            _buildShimmerElement(
                              delay: 2,
                              child: _buildShimmerFilters(),
                            )
                          else
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildFiltrosYOrdenamiento(),
                            ),
                          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth)),
                          
                          // Título de productos
                          if (mostrarShimmer)
                            _buildShimmerElement(
                              delay: 3,
                              child: Row(
                                children: [
                                  Container(
                                    width: isSmallScreen ? 20 : 24,
                                    height: isSmallScreen ? 20 : 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Container(
                                    width: screenWidth * 0.5,
                                    height: isSmallScreen ? 20 : 24,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade400,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.inventory,
                                    color: AppColors.primary,
                                    size: isSmallScreen ? 20 : 24,
                                  ),
                                  SizedBox(width: isSmallScreen ? 6 : 8),
                                  Expanded(
                                    child: Text(
                                      'Productos Registrados',
                                      style: WidgetStyles.headerTitleStyle(screenWidth),
                                    ),
                                  ),
                                  if (provider.productosFiltrados.isNotEmpty) ...[
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: isSmallScreen ? 10 : 12,
                                        vertical: isSmallScreen ? 4 : 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${provider.productosFiltrados.length} resultado${provider.productosFiltrados.length != 1 ? 's' : ''}',
                                        style: WidgetStyles.resultsBadgeStyle(screenWidth),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          SizedBox(height: AppDimensions.getVerticalSpacing(screenWidth)),
                          
                          // Grid de productos
                          if (mostrarShimmer)
                            _buildShimmerProductGrid()
                          else if (provider.productosFiltrados.isEmpty)
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildEmptyState(),
                            )
                          else
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: _buildProductGrid(),
                            ),
                          
                          SizedBox(height: AppDimensions.getSectionSpacing(screenWidth) + 8),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}