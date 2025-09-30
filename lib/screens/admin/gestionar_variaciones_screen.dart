import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/variacion.dart';
import '../../providers/variacion_admin_provider.dart';
import 'crear_variacion_screen.dart';
import 'ActualizarVariacionScreen.dart';
import 'styles/gestionar_variacion/gestionar_variaciones_styles.dart';
import 'styles/gestionar_variacion/responsive_dimensions.dart';

class GestionarVariacionesScreen extends StatefulWidget {
  final String productId;
  const GestionarVariacionesScreen({Key? key, required this.productId}) : super(key: key);

  @override
  _GestionarVariacionesScreenState createState() => _GestionarVariacionesScreenState();
}

class _GestionarVariacionesScreenState extends State<GestionarVariacionesScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '', // Removido el símbolo para añadirlo manualmente
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVariaciones();
    });
  }

  String _formatPrice(double price) {
    // Formateamos sin símbolo, el ícono attach_money ya muestra el $
    return _currencyFormatter.format(price);
  }

  Future<void> _loadVariaciones() async {
    final provider = Provider.of<VariacionProvider>(context, listen: false);
    await provider.cargarVariaciones(widget.productId);
    
    if (provider.hasError) {
      _showSnackBar('Error al cargar variaciones: ${provider.error}', isError: true);
    }
  }

  Future<void> _deleteVariacion(String variacionId) async {
    final provider = Provider.of<VariacionProvider>(context, listen: false);
    
    final exito = await provider.eliminarVariacion(
      productoId: widget.productId,
      variacionId: variacionId,
    );
    
    if (exito) {
      _showSnackBar('Variación eliminada correctamente');
    } else {
      _showSnackBar('Error al eliminar variación: ${provider.error}', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      GestionarVariacionesStyles.buildSnackBar(message, isError),
    );
  }

  void _navigateToCrearVariacion() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CrearVariacionScreen(productId: widget.productId),
      ),
    ).then((_) {
      _loadVariaciones();
    });
  }

  void _navigateToActualizarVariacion(Variacion variacion) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActualizarVariacionScreen(variacionToEdit: variacion),
      ),
    ).then((result) {
      if (result == true) {
        _loadVariaciones();
      }
    });
  }

  Color _getStockColor(int stock) {
    if (stock <= 5) return GestionarVariacionesStyles.stockLowColor;
    if (stock <= 20) return GestionarVariacionesStyles.stockMediumColor;
    return GestionarVariacionesStyles.stockHighColor;
  }

  String _getStockLabel(int stock) {
    if (stock <= 5) return 'Bajo';
    if (stock <= 20) return 'Medio';
    return 'Alto';
  }

  Widget _buildStockChip(int stock, ResponsiveDimensions dimensions) {
    final color = _getStockColor(stock);
    final label = _getStockLabel(stock);
    final fontSize = dimensions.titleFontSize - 4;
    final dotSize = dimensions.iconSize * 0.3;
    final padding = EdgeInsets.symmetric(
      horizontal: dimensions.spacingMedium * 0.8,
      vertical: dimensions.spacingMedium * 0.4,
    );
    
    return Container(
      padding: padding,
      decoration: GestionarVariacionesStyles.stockChipDecoration(color),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: dimensions.spacingMedium * 0.3),
          Text(
            '$stock ($label)',
            style: GestionarVariacionesStyles.stockLabelStyle(fontSize, color),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem(ResponsiveDimensions dimensions, double screenWidth) {
    final horizontalMargin = screenWidth * dimensions.horizontalMargin;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: GestionarVariacionesStyles.shimmerBaseColor,
        highlightColor: GestionarVariacionesStyles.shimmerHighlightColor,
        child: Container(
          padding: EdgeInsets.all(dimensions.contentPadding),
          decoration: GestionarVariacionesStyles.cardDecoration,
          child: Row(
            children: [
              Container(
                width: dimensions.imageSize,
                height: dimensions.imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: GestionarVariacionesStyles.imageBorderRadius,
                ),
              ),
              SizedBox(width: dimensions.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: dimensions.titleFontSize,
                      width: screenWidth * 0.3,
                      color: Colors.grey,
                      margin: EdgeInsets.only(bottom: dimensions.spacingMedium * 0.5),
                    ),
                    Container(
                      height: dimensions.priceFontSize,
                      width: screenWidth * 0.2,
                      color: Colors.grey,
                      margin: EdgeInsets.only(bottom: dimensions.spacingMedium * 0.5),
                    ),
                    Container(
                      height: dimensions.titleFontSize - 2,
                      width: screenWidth * 0.25,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: dimensions.actionButtonSize,
                    height: dimensions.actionButtonSize,
                    color: Colors.grey,
                    margin: EdgeInsets.only(bottom: dimensions.spacingMedium * 0.5),
                  ),
                  Container(
                    width: dimensions.actionButtonSize,
                    height: dimensions.actionButtonSize,
                    color: Colors.grey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVariacionItem(Variacion variacion, ResponsiveDimensions dimensions, double horizontalMargin) {
    final color = (variacion.colorNombre?.isNotEmpty ?? false) ? variacion.colorNombre! : 'Sin color';
    
    String talla = 'Sin talla';
    if (variacion.tallaLetra != null && variacion.tallaLetra!.trim().isNotEmpty) {
      talla = variacion.tallaLetra!.trim();
    } else if (variacion.tallaNumero != null && variacion.tallaNumero!.trim().isNotEmpty) {
      talla = variacion.tallaNumero!.trim();
    }
    
    final stock = variacion.stock;
    final precio = variacion.precio;
    final imagenes = variacion.imagenes;
    
    return Dismissible(
      key: Key(variacion.id ?? UniqueKey().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
        decoration: GestionarVariacionesStyles.deleteBackgroundDecoration,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: dimensions.spacingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.delete_outline, 
              color: Colors.white, 
              size: dimensions.iconSize + 4,
            ),
            const SizedBox(height: 4),
            Text(
              'Eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: dimensions.titleFontSize - 4,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (direction) => _showDeleteDialog(dimensions),
      onDismissed: (direction) {
        if (variacion.id != null) {
          _deleteVariacion(variacion.id!);
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
        decoration: GestionarVariacionesStyles.cardDecoration,
        child: Padding(
          padding: EdgeInsets.all(dimensions.contentPadding),
          child: Row(
            children: [
              Container(
                width: dimensions.imageSize,
                height: dimensions.imageSize,
                decoration: GestionarVariacionesStyles.imageContainerDecoration,
                child: ClipRRect(
                  borderRadius: GestionarVariacionesStyles.imageBorderRadius,
                  child: (imagenes.isNotEmpty && imagenes[0].url != null)
                      ? Image.network(
                          imagenes[0].url!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade100,
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: Colors.grey.shade400,
                              size: dimensions.iconSize,
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey.shade100,
                              child: Center(
                                child: SizedBox(
                                  width: dimensions.iconSize,
                                  height: dimensions.iconSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      GestionarVariacionesStyles.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey.shade100,
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey.shade400,
                            size: dimensions.iconSize,
                          ),
                        ),
                ),
              ),
              
              SizedBox(width: dimensions.spacingMedium),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$color - $talla',
                      style: GestionarVariacionesStyles.titleStyle(dimensions.titleFontSize),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    SizedBox(height: dimensions.spacingMedium * 0.7),
                    
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: dimensions.spacingMedium * 0.7,
                        vertical: dimensions.spacingMedium * 0.3,
                      ),
                      decoration: GestionarVariacionesStyles.priceContainerDecoration,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: dimensions.iconSize * 0.8,
                            color: GestionarVariacionesStyles.primaryColor,
                          ),
                          Text(
                            _formatPrice(precio),
                            style: GestionarVariacionesStyles.priceStyle(dimensions.priceFontSize),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: dimensions.spacingMedium * 0.7),
                    
                    _buildStockChip(stock, dimensions),
                  ],
                ),
              ),
              
              Column(
                children: [
                  Container(
                    width: dimensions.actionButtonSize,
                    height: dimensions.actionButtonSize,
                    decoration: GestionarVariacionesStyles.iconContainerDecoration(
                      GestionarVariacionesStyles.primaryColor,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.edit_outlined,
                        color: GestionarVariacionesStyles.primaryColor,
                        size: dimensions.iconSize,
                      ),
                      tooltip: 'Editar variación',
                      onPressed: () => _navigateToActualizarVariacion(variacion),
                      splashRadius: dimensions.actionButtonSize * 0.5,
                    ),
                  ),
                  
                  SizedBox(height: dimensions.spacingMedium * 0.7),
                  
                  Container(
                    width: dimensions.actionButtonSize,
                    height: dimensions.actionButtonSize,
                    decoration: GestionarVariacionesStyles.iconContainerDecoration(
                      GestionarVariacionesStyles.errorColor,
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: GestionarVariacionesStyles.errorColor,
                        size: dimensions.iconSize,
                      ),
                      tooltip: 'Eliminar variación',
                      onPressed: () => _confirmDelete(variacion.id!, dimensions),
                      splashRadius: dimensions.actionButtonSize * 0.5,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _showDeleteDialog(ResponsiveDimensions dimensions) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: GestionarVariacionesStyles.cardBorderRadius,
          ),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(dimensions.spacingMedium * 0.7),
                decoration: GestionarVariacionesStyles.iconContainerDecoration(
                  GestionarVariacionesStyles.errorColor,
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: GestionarVariacionesStyles.errorColor,
                  size: dimensions.iconSize,
                ),
              ),
              SizedBox(width: dimensions.spacingMedium * 0.8),
              Expanded(
                child: Text(
                  'Confirmar eliminación',
                  style: GestionarVariacionesStyles.titleStyle(dimensions.titleFontSize),
                ),
              ),
            ],
          ),
          content: Text(
            '¿Está seguro que desea eliminar esta variación? Esta acción no se puede deshacer.',
            style: GestionarVariacionesStyles.dialogContentStyle(dimensions.titleFontSize - 2),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: GestionarVariacionesStyles.cancelButtonStyle(
                dimensions.spacingMedium,
                dimensions.spacingMedium * 0.7,
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: dimensions.titleFontSize - 2),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: GestionarVariacionesStyles.deleteButtonStyle(
                dimensions.spacingMedium,
                dimensions.spacingMedium * 0.7,
              ),
              child: Text(
                'Eliminar',
                style: TextStyle(fontSize: dimensions.titleFontSize - 2),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(String variacionId, ResponsiveDimensions dimensions) async {
    final confirmed = await _showDeleteDialog(dimensions);
    if (confirmed == true) {
      _deleteVariacion(variacionId);
    }
  }

  Widget _buildEmptyState(ResponsiveBreakpoints breakpoint, ResponsiveDimensions dimensions) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(dimensions.contentPadding),
        constraints: BoxConstraints(
          maxWidth: breakpoint == ResponsiveBreakpoints.mobile ? double.infinity : 600,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(dimensions.spacingLarge),
              decoration: GestionarVariacionesStyles.emptyStateIconDecoration,
              child: Icon(
                Icons.inventory_2_outlined,
                size: dimensions.spacingLarge + 20,
                color: GestionarVariacionesStyles.primaryColor,
              ),
            ),
            
            SizedBox(height: dimensions.spacingLarge),
            
            Text(
              'No hay variaciones',
              style: TextStyle(
                fontSize: dimensions.titleFontSize + 8,
                fontWeight: FontWeight.w600,
                color: GestionarVariacionesStyles.textPrimaryColor,
              ),
            ),
            
            SizedBox(height: dimensions.spacingMedium * 0.7),
            
            Text(
              'Agrega la primera variación de tu producto para empezar a vender',
              textAlign: TextAlign.center,
              style: GestionarVariacionesStyles.subtitleStyle(dimensions.titleFontSize),
            ),
            
            SizedBox(height: dimensions.spacingLarge + 8),
            
            ElevatedButton.icon(
              onPressed: _navigateToCrearVariacion,
              icon: Icon(Icons.add, size: dimensions.iconSize),
              label: Text(
                'Nueva variación',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: dimensions.titleFontSize,
                ),
              ),
              style: GestionarVariacionesStyles.primaryButtonStyle(
                dimensions.spacingLarge,
                dimensions.spacingMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int variacionesCount, ResponsiveDimensions dimensions, double horizontalMargin) {
    if (variacionesCount == 0) return const SizedBox.shrink();
    
    return Container(
      margin: EdgeInsets.all(horizontalMargin),
      padding: EdgeInsets.all(dimensions.contentPadding),
      decoration: GestionarVariacionesStyles.cardDecoration,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dimensions.spacingMedium),
            decoration: GestionarVariacionesStyles.circleIconDecoration(
              GestionarVariacionesStyles.primaryColor,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              color: GestionarVariacionesStyles.primaryColor,
              size: dimensions.iconSize + 4,
            ),
          ),
          
          SizedBox(width: dimensions.spacingMedium),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$variacionesCount variaciones',
                  style: GestionarVariacionesStyles.titleStyle(dimensions.titleFontSize),
                ),
                Text(
                  'Desliza hacia la izquierda para eliminar',
                  style: GestionarVariacionesStyles.subtitleStyle(dimensions.titleFontSize - 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VariacionProvider>(
      builder: (context, provider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final breakpoint = ResponsiveDimensions.getBreakpoint(constraints.maxWidth);
            final dimensions = ResponsiveDimensions.fromBreakpoint(breakpoint);
            final horizontalMargin = constraints.maxWidth * dimensions.horizontalMargin;
            final bottomPadding = breakpoint == ResponsiveBreakpoints.mobile ? 100.0 : 120.0;
            
            return Scaffold(
              backgroundColor: GestionarVariacionesStyles.backgroundColor,
              appBar: AppBar(
                title: Text(
                  'Gestionar Variaciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: dimensions.titleFontSize,
                  ),
                ),
                backgroundColor: GestionarVariacionesStyles.whiteColor,
                foregroundColor: GestionarVariacionesStyles.textPrimaryColor,
                centerTitle: true,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.dark,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                    height: 1,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              body: provider.isLoading
                  ? ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      itemCount: 6,
                      itemBuilder: (_, __) => _buildShimmerItem(dimensions, constraints.maxWidth),
                    )
                  : provider.variaciones.isEmpty
                      ? _buildEmptyState(breakpoint, dimensions)
                      : Column(
                          children: [
                            _buildHeader(provider.variaciones.length, dimensions, horizontalMargin),
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadVariaciones,
                                color: GestionarVariacionesStyles.primaryColor,
                                backgroundColor: GestionarVariacionesStyles.whiteColor,
                                child: ListView.builder(
                                  padding: EdgeInsets.only(bottom: bottomPadding),
                                  itemCount: provider.variaciones.length,
                                  itemBuilder: (context, index) {
                                    return _buildVariacionItem(
                                      provider.variaciones[index], 
                                      dimensions, 
                                      horizontalMargin
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
              floatingActionButton: provider.variaciones.isNotEmpty ? FloatingActionButton.extended(
                onPressed: _navigateToCrearVariacion,
                tooltip: 'Agregar variación',
                backgroundColor: GestionarVariacionesStyles.primaryColor,
                foregroundColor: GestionarVariacionesStyles.whiteColor,
                elevation: 4,
                icon: Icon(Icons.add, size: dimensions.iconSize),
                label: Text(
                  'Nueva variación',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: dimensions.titleFontSize - 2,
                  ),
                ),
              ) : null,
            );
          },
        );
      },
    );
  }
}