import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/variacion_service.dart';
import 'crear_variacion_screen.dart';

class GestionarVariacionesScreen extends StatefulWidget {
  final String productId;
  const GestionarVariacionesScreen({Key? key, required this.productId}) : super(key: key);

  @override
  _GestionarVariacionesScreenState createState() => _GestionarVariacionesScreenState();
}

class _GestionarVariacionesScreenState extends State<GestionarVariacionesScreen> {
  final VariacionService _variacionService = VariacionService();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  List<Map<String, dynamic>> _variaciones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVariaciones();
  }

  Future<void> _loadVariaciones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _variacionService.obtenerVariacionesPorProducto(widget.productId);

      if (!mounted) return;

      // Animar eliminación previa
      if (_variaciones.isNotEmpty) {
        for (int i = _variaciones.length - 1; i >= 0; i--) {
          final removedItem = _variaciones.removeAt(i);
          _listKey.currentState?.removeItem(
            i,
            (context, animation) => _buildVariacionItem(removedItem, animation),
            duration: const Duration(milliseconds: 300),
          );
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

      // Insertar nuevos
      for (int i = 0; i < data.length; i++) {
        _variaciones.insert(i, Map<String, dynamic>.from(data[i]));
        _listKey.currentState?.insertItem(i, duration: const Duration(milliseconds: 300));
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } catch (e) {
      _showSnackBar('Error al cargar variaciones', isError: true);
      debugPrint('Error cargando variaciones: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVariacion(int index) async {
    if (index < 0 || index >= _variaciones.length) return;
    final variacionId = _variaciones[index]['_id'] as String;
    
    try {
      await _variacionService.eliminarVariacion(
        productoId: widget.productId,
        variacionId: variacionId,
      );
      final removedItem = _variaciones.removeAt(index);
      _listKey.currentState?.removeItem(
        index,
        (context, animation) => _buildVariacionItem(removedItem, animation),
        duration: const Duration(milliseconds: 300),
      );
      _showSnackBar('Variación eliminada correctamente');
    } catch (e) {
      _showSnackBar('Error al eliminar variación', isError: true);
      debugPrint('Error eliminando variación: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isError ? 4 : 3),
      ),
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

  Color _getStockColor(int stock) {
    if (stock <= 5) return Colors.red.shade600;
    if (stock <= 20) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  String _getStockLabel(int stock) {
    if (stock <= 5) return 'Bajo';
    if (stock <= 20) return 'Medio';
    return 'Alto';
  }

  Widget _buildStockChip(int stock, [bool isTablet = false]) {
    final color = _getStockColor(stock);
    final label = _getStockLabel(stock);
    final fontSize = isTablet ? 14.0 : 12.0;
    final dotSize = isTablet ? 8.0 : 6.0;
    final padding = isTablet ? 
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6) :
        const EdgeInsets.symmetric(horizontal: 8, vertical: 4);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
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
          SizedBox(width: isTablet ? 6 : 4),
          Text(
            '$stock ($label)',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final horizontalMargin = isTablet ? constraints.maxWidth * 0.1 : 20.0;
        final imageSize = isTablet ? 80.0 : 60.0;
        final contentPadding = isTablet ? 24.0 : 16.0;
        
        return Container(
          margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
          child: Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              padding: EdgeInsets.all(contentPadding),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: imageSize,
                    height: imageSize,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(width: isTablet ? 24 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: isTablet ? 20 : 16,
                          width: isTablet ? 160 : 120,
                          color: Colors.grey,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Container(
                          height: isTablet ? 18 : 14,
                          width: isTablet ? 100 : 80,
                          color: Colors.grey,
                          margin: const EdgeInsets.only(bottom: 8),
                        ),
                        Container(
                          height: isTablet ? 16 : 12,
                          width: isTablet ? 120 : 100,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Container(
                        width: isTablet ? 40 : 32,
                        height: isTablet ? 40 : 32,
                        color: Colors.grey,
                        margin: const EdgeInsets.only(bottom: 8),
                      ),
                      Container(
                        width: isTablet ? 40 : 32,
                        height: isTablet ? 40 : 32,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVariacionItem(Map<String, dynamic> variacion, Animation<double> animation) {
    final Map<String, dynamic>? colorData = variacion['color'];
    final String color = colorData?['nombre'] ?? 'Sin color';
    final String talla = variacion['tallaNumero']?.toString() ?? variacion['tallaLetra'] ?? 'Sin talla';
    final int stock = variacion['stock'] ?? 0;
    final double precio = (variacion['precio'] != null) 
        ? double.tryParse(variacion['precio'].toString()) ?? 0.0 
        : 0.0;
    final List<dynamic>? imagenes = variacion['imagenes'];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final horizontalMargin = isTablet ? constraints.maxWidth * 0.1 : 20.0;
        final imageSize = isTablet ? 80.0 : 60.0;
        final contentPadding = isTablet ? 24.0 : 16.0;
        final titleFontSize = isTablet ? 18.0 : 16.0;
        final priceFontSize = isTablet ? 17.0 : 15.0;
        final iconSize = isTablet ? 24.0 : 20.0;
        final actionButtonSize = isTablet ? 48.0 : 40.0;
        
        return SizeTransition(
          sizeFactor: animation,
          axis: Axis.vertical,
          child: Dismissible(
            key: Key(variacion['_id'] ?? UniqueKey().toString()),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 32 : 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline, color: Colors.white, size: isTablet ? 32 : 28),
                  const SizedBox(height: 4),
                  Text(
                    'Eliminar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 14 : 12,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (direction) => _showDeleteDialog(),
            onDismissed: (direction) {
              final index = _variaciones.indexWhere((v) => v['_id'] == variacion['_id']);
              if (index != -1) _deleteVariacion(index);
            },
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(contentPadding),
                child: Row(
                  children: [
                    // Imagen
                    Container(
                      width: imageSize,
                      height: imageSize,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: (imagenes != null && imagenes.isNotEmpty)
                            ? Image.network(
                                imagenes[0]['url'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey.shade400,
                                    size: isTablet ? 28 : 24,
                                  ),
                                ),
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: Colors.grey.shade100,
                                    child: Center(
                                      child: SizedBox(
                                        width: isTablet ? 24 : 20,
                                        height: isTablet ? 24 : 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF3A86FF),
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
                                  size: isTablet ? 28 : 24,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(width: isTablet ? 24 : 16),
                    
                    // Información principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            '$color - $talla',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: titleFontSize,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          
                          SizedBox(height: isTablet ? 12 : 8),
                          
                          // Precio
                          Row(
                            children: [
                              Icon(
                                Icons.attach_money,
                                size: isTablet ? 18 : 16,
                                color: Colors.grey.shade600,
                              ),
                              Text(
                                precio.toStringAsFixed(2),
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: priceFontSize,
                                  color: const Color(0xFF3A86FF),
                                ),
                              ),
                            ],
                          ),
                          
                          SizedBox(height: isTablet ? 12 : 8),
                          
                          // Stock
                          _buildStockChip(stock, isTablet),
                        ],
                      ),
                    ),
                    
                    // Acciones
                    Column(
                      children: [
                        Container(
                          width: actionButtonSize,
                          height: actionButtonSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A86FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF3A86FF),
                              size: iconSize,
                            ),
                            tooltip: 'Editar variación',
                            onPressed: _navigateToCrearVariacion,
                            splashRadius: isTablet ? 24 : 20,
                          ),
                        ),
                        
                        SizedBox(height: isTablet ? 12 : 8),
                        
                        Container(
                          width: actionButtonSize,
                          height: actionButtonSize,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: iconSize,
                            ),
                            tooltip: 'Eliminar variación',
                            onPressed: () {
                              final index = _variaciones.indexWhere(
                                (v) => v['_id'] == variacion['_id']
                              );
                              if (index != -1) _confirmDelete(index);
                            },
                            splashRadius: isTablet ? 24 : 20,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isTablet = constraints.maxWidth > 600;
            final titleFontSize = isTablet ? 20.0 : 18.0;
            final contentFontSize = isTablet ? 16.0 : 14.0;
            final iconSize = isTablet ? 28.0 : 24.0;
            final buttonPadding = isTablet ? 
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16) :
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
            final spacingMedium = isTablet ? 16.0 : 12.0;
            
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_outlined,
                      color: Colors.red.shade600,
                      size: iconSize,
                    ),
                  ),
                  SizedBox(width: spacingMedium),
                  Expanded(
                    child: Text(
                      'Confirmar eliminación',
                      style: TextStyle(
                        fontSize: titleFontSize, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                '¿Está seguro que desea eliminar esta variación? Esta acción no se puede deshacer.',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: contentFontSize,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: buttonPadding,
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(fontSize: contentFontSize),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    foregroundColor: Colors.white,
                    padding: buttonPadding,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    'Eliminar',
                    style: TextStyle(fontSize: contentFontSize),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(int index) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      _deleteVariacion(index);
    }
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final iconSize = isTablet ? 80.0 : 64.0;
        final titleFontSize = isTablet ? 28.0 : 24.0;
        final subtitleFontSize = isTablet ? 18.0 : 16.0;
        final buttonPadding = isTablet ? 
            const EdgeInsets.symmetric(horizontal: 32, vertical: 20) :
            const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        final containerPadding = isTablet ? 48.0 : 32.0;
        final spacingLarge = isTablet ? 32.0 : 24.0;
        final spacingMedium = isTablet ? 12.0 : 8.0;
        final spacingXLarge = isTablet ? 48.0 : 32.0;
        
        return Center(
          child: Container(
            padding: EdgeInsets.all(containerPadding),
            constraints: BoxConstraints(
              maxWidth: isTablet ? 600 : double.infinity,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(spacingLarge),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A86FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: iconSize,
                    color: Color(0xFF3A86FF),
                  ),
                ),
                
                SizedBox(height: spacingLarge),
                
                Text(
                  'No hay variaciones',
                  style: TextStyle(
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                
                SizedBox(height: spacingMedium),
                
                Text(
                  'Agrega la primera variación de tu producto para empezar a vender',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: subtitleFontSize,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                SizedBox(height: spacingXLarge),
                
                ElevatedButton.icon(
                  onPressed: _navigateToCrearVariacion,
                  icon: Icon(Icons.add, size: isTablet ? 24 : 20),
                  label: Text(
                    'Nueva variación',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: isTablet ? 18 : 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A86FF),
                    foregroundColor: Colors.white,
                    padding: buttonPadding,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    if (_variaciones.isEmpty) return const SizedBox.shrink();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final horizontalMargin = isTablet ? constraints.maxWidth * 0.1 : 20.0;
        final contentPadding = isTablet ? 24.0 : 16.0;
        final iconSize = isTablet ? 28.0 : 24.0;
        final titleFontSize = isTablet ? 20.0 : 18.0;
        final subtitleFontSize = isTablet ? 16.0 : 14.0;
        final spacingMedium = isTablet ? 20.0 : 16.0;
        
        return Container(
          margin: EdgeInsets.all(horizontalMargin),
          padding: EdgeInsets.all(contentPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isTablet ? 16 : 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A86FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF3A86FF),
                  size: iconSize,
                ),
              ),
              
              SizedBox(width: spacingMedium),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_variaciones.length} variaciones',
                      style: TextStyle(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Desliza hacia la izquierda para eliminar',
                      style: TextStyle(
                        fontSize: subtitleFontSize,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final bottomPadding = isTablet ? 120.0 : 100.0;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFC),
          appBar: AppBar(
            title: Text(
              'Gestionar Variaciones',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 20 : 18,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF2D3748),
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
          body: _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  itemCount: 6,
                  itemBuilder: (_, __) => _buildShimmerItem(),
                )
              : _variaciones.isEmpty
                  ? _buildEmptyState()
                  : Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: RefreshIndicator(
                            onRefresh: _loadVariaciones,
                            color: const Color(0xFF3A86FF),
                            backgroundColor: Colors.white,
                            child: AnimatedList(
                              key: _listKey,
                              padding: EdgeInsets.only(bottom: bottomPadding),
                              initialItemCount: _variaciones.length,
                              itemBuilder: (context, index, animation) {
                                return _buildVariacionItem(_variaciones[index], animation);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
          // Solo mostrar el FloatingActionButton cuando hay variaciones
          floatingActionButton: _variaciones.isNotEmpty ? FloatingActionButton.extended(
            onPressed: _navigateToCrearVariacion,
            tooltip: 'Agregar variación',
            backgroundColor: const Color(0xFF3A86FF),
            foregroundColor: Colors.white,
            elevation: 4,
            icon: Icon(Icons.add, size: isTablet ? 24 : 20),
            label: Text(
              'Nueva variación',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 16 : 14,
              ),
            ),
          ) : null,
        );
      },
    );
  }
}