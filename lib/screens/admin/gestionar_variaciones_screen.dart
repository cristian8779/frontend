import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../services/variacion_service.dart';
import '../../models/variacion.dart'; // Importar el modelo
import 'crear_variacion_screen.dart';
import 'ActualizarVariacionScreen.dart'; // Importar la nueva pantalla

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

  // Formateador de peso colombiano
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadVariaciones();
  }

  // Método para formatear precio en pesos colombianos
  String _formatPrice(double price) {
    return _currencyFormatter.format(price);
  }

  // Método para obtener breakpoints responsive
  ResponsiveBreakpoints _getBreakpoints(double width) {
    if (width >= 1200) {
      return ResponsiveBreakpoints.desktop;
    } else if (width >= 800) {
      return ResponsiveBreakpoints.tablet;
    } else if (width >= 600) {
      return ResponsiveBreakpoints.tabletSmall;
    } else {
      return ResponsiveBreakpoints.mobile;
    }
  }

  // Método para obtener dimensiones responsive
  ResponsiveDimensions _getDimensions(ResponsiveBreakpoints breakpoint) {
    switch (breakpoint) {
      case ResponsiveBreakpoints.desktop:
        return ResponsiveDimensions(
          horizontalMargin: 0.15,
          imageSize: 100,
          contentPadding: 32,
          titleFontSize: 20,
          priceFontSize: 18,
          iconSize: 28,
          actionButtonSize: 52,
          spacingLarge: 40,
          spacingMedium: 20,
          columns: 2,
        );
      case ResponsiveBreakpoints.tablet:
        return ResponsiveDimensions(
          horizontalMargin: 0.12,
          imageSize: 90,
          contentPadding: 28,
          titleFontSize: 19,
          priceFontSize: 17,
          iconSize: 26,
          actionButtonSize: 50,
          spacingLarge: 36,
          spacingMedium: 18,
          columns: 2,
        );
      case ResponsiveBreakpoints.tabletSmall:
        return ResponsiveDimensions(
          horizontalMargin: 0.08,
          imageSize: 80,
          contentPadding: 24,
          titleFontSize: 18,
          priceFontSize: 16,
          iconSize: 24,
          actionButtonSize: 48,
          spacingLarge: 32,
          spacingMedium: 16,
          columns: 1,
        );
      case ResponsiveBreakpoints.mobile:
        return ResponsiveDimensions(
          horizontalMargin: 0.05,
          imageSize: 60,
          contentPadding: 16,
          titleFontSize: 16,
          priceFontSize: 15,
          iconSize: 20,
          actionButtonSize: 40,
          spacingLarge: 24,
          spacingMedium: 12,
          columns: 1,
        );
    }
  }

  Future<void> _loadVariaciones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _variacionService.obtenerVariacionesPorProducto(widget.productId);
      
      // DEPURACIÓN: Imprimir los datos recibidos del servidor
      print('=== DATOS DE VARIACIONES RECIBIDOS ===');
      print('Cantidad de variaciones: ${data.length}');
      for (int i = 0; i < data.length; i++) {
        print('Variación $i:');
        print('  ID: ${data[i]['_id']}');
        print('  tallaLetra: "${data[i]['tallaLetra']}"');
        print('  tallaNumero: "${data[i]['tallaNumero']}"');
        print('  color: ${data[i]['color']}');
        print('  stock: ${data[i]['stock']}');
        print('  precio: ${data[i]['precio']}');
        print('  ---');
      }
      print('=======================================');

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

  // NUEVO: Método para navegar a la pantalla de actualizar variación
  void _navigateToActualizarVariacion(Map<String, dynamic> variacionData) {
    // Crear el objeto Variacion desde los datos
    final variacion = _convertirDataAVariacion(variacionData);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActualizarVariacionScreen(variacionToEdit: variacion),
      ),
    ).then((result) {
      // Si result es true, significa que se actualizó correctamente
      if (result == true) {
        _loadVariaciones(); // Recargar la lista
      }
    });
  }

  // MÉTODO CORREGIDO: Convertir Map a objeto Variacion
  Variacion _convertirDataAVariacion(Map<String, dynamic> data) {
    final Map<String, dynamic>? colorData = data['color'];
    final List<dynamic>? imagenesData = data['imagenes'];
    
    // Debug para verificar los datos
    print('🔄 CONVERSIÓN - tallaLetra: "${data['tallaLetra']}", tallaNumero: "${data['tallaNumero']}"');
    
    // Manejar tallas correctamente
    String? tallaLetra;
    String? tallaNumero;
    
    if (data['tallaLetra'] != null && data['tallaLetra'].toString().trim().isNotEmpty) {
      tallaLetra = data['tallaLetra'].toString().trim();
    }
    
    if (data['tallaNumero'] != null && data['tallaNumero'].toString().trim().isNotEmpty) {
      tallaNumero = data['tallaNumero'].toString().trim();
    }
    
    return Variacion(
      id: data['_id'] ?? '',
      productoId: widget.productId,
      colorHex: colorData?['hex'] ?? '',
      colorNombre: colorData?['nombre'] ?? '',
      tallaLetra: tallaLetra,
      tallaNumero: tallaNumero,
      stock: data['stock'] ?? 0,
      precio: (data['precio'] != null) 
          ? double.tryParse(data['precio'].toString()) ?? 0.0 
          : 0.0,
      imagenes: imagenesData?.isNotEmpty == true 
          ? [ImagenVariacion(url: imagenesData!.first['url'])]
          : [],
    );
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
          SizedBox(width: dimensions.spacingMedium * 0.3),
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

  Widget _buildShimmerItem(ResponsiveDimensions dimensions, double screenWidth) {
    final horizontalMargin = screenWidth * dimensions.horizontalMargin;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: EdgeInsets.all(dimensions.contentPadding),
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
                width: dimensions.imageSize,
                height: dimensions.imageSize,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
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

  Widget _buildVariacionItem(Map<String, dynamic> variacion, Animation<double> animation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpoints(constraints.maxWidth);
        final dimensions = _getDimensions(breakpoint);
        final horizontalMargin = constraints.maxWidth * dimensions.horizontalMargin;
        
        final Map<String, dynamic>? colorData = variacion['color'];
        final String color = colorData?['nombre'] ?? 'Sin color';
        
        // CORRECCIÓN: Manejar correctamente tallas vacías vs null
        String talla = 'Sin talla';
        
        // Primero verificar tallaLetra
        if (variacion['tallaLetra'] != null && 
            variacion['tallaLetra'].toString().trim().isNotEmpty) {
          talla = variacion['tallaLetra'].toString().trim();
        } 
        // Si no hay tallaLetra, verificar tallaNumero
        else if (variacion['tallaNumero'] != null && 
                 variacion['tallaNumero'].toString().trim().isNotEmpty) {
          talla = variacion['tallaNumero'].toString().trim();
        }
        
        // Debug: imprimir para verificar
        print('🏷️ TALLA DEBUG - tallaLetra: "${variacion['tallaLetra']}", tallaNumero: "${variacion['tallaNumero']}", resultado: "$talla"');
        
        final int stock = variacion['stock'] ?? 0;
        final double precio = (variacion['precio'] != null) 
            ? double.tryParse(variacion['precio'].toString()) ?? 0.0 
            : 0.0;
        final List<dynamic>? imagenes = variacion['imagenes'];
        
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
                padding: EdgeInsets.all(dimensions.contentPadding),
                child: Row(
                  children: [
                    // Imagen
                    Container(
                      width: dimensions.imageSize,
                      height: dimensions.imageSize,
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
                                  size: dimensions.iconSize,
                                ),
                              ),
                      ),
                    ),
                    
                    SizedBox(width: dimensions.spacingMedium),
                    
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
                              fontSize: dimensions.titleFontSize,
                              color: Color(0xFF2D3748),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          
                          SizedBox(height: dimensions.spacingMedium * 0.7),
                          
                          // Precio en pesos colombianos
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: dimensions.spacingMedium * 0.7,
                              vertical: dimensions.spacingMedium * 0.3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A86FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.attach_money,
                                  size: dimensions.iconSize * 0.8,
                                  color: const Color(0xFF3A86FF),
                                ),
                                Text(
                                  _formatPrice(precio),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: dimensions.priceFontSize,
                                    color: const Color(0xFF3A86FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: dimensions.spacingMedium * 0.7),
                          
                          // Stock
                          _buildStockChip(stock, dimensions),
                        ],
                      ),
                    ),
                    
                    // Acciones
                    Column(
                      children: [
                        Container(
                          width: dimensions.actionButtonSize,
                          height: dimensions.actionButtonSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3A86FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF3A86FF),
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
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade600,
                              size: dimensions.iconSize,
                            ),
                            tooltip: 'Eliminar variación',
                            onPressed: () {
                              final index = _variaciones.indexWhere(
                                (v) => v['_id'] == variacion['_id']
                              );
                              if (index != -1) _confirmDelete(index, dimensions);
                            },
                            splashRadius: dimensions.actionButtonSize * 0.5,
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

  Future<bool?> _showDeleteDialog(ResponsiveDimensions dimensions) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.all(dimensions.spacingMedium * 0.7),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_outlined,
                  color: Colors.red.shade600,
                  size: dimensions.iconSize,
                ),
              ),
              SizedBox(width: dimensions.spacingMedium * 0.8),
              Expanded(
                child: Text(
                  'Confirmar eliminación',
                  style: TextStyle(
                    fontSize: dimensions.titleFontSize, 
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
              fontSize: dimensions.titleFontSize - 2,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.spacingMedium,
                  vertical: dimensions.spacingMedium * 0.7,
                ),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(fontSize: dimensions.titleFontSize - 2),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.spacingMedium,
                  vertical: dimensions.spacingMedium * 0.7,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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

  void _confirmDelete(int index, ResponsiveDimensions dimensions) async {
    final confirmed = await _showDeleteDialog(dimensions);
    if (confirmed == true) {
      _deleteVariacion(index);
    }
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final breakpoint = _getBreakpoints(constraints.maxWidth);
        final dimensions = _getDimensions(breakpoint);
        
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
                  decoration: BoxDecoration(
                    color: const Color(0xFF3A86FF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.inventory_2_outlined,
                    size: dimensions.spacingLarge + 20,
                    color: Color(0xFF3A86FF),
                  ),
                ),
                
                SizedBox(height: dimensions.spacingLarge),
                
                Text(
                  'No hay variaciones',
                  style: TextStyle(
                    fontSize: dimensions.titleFontSize + 8,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                
                SizedBox(height: dimensions.spacingMedium * 0.7),
                
                Text(
                  'Agrega la primera variación de tu producto para empezar a vender',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: dimensions.titleFontSize,
                    color: Colors.grey.shade600,
                  ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3A86FF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: dimensions.spacingLarge,
                      vertical: dimensions.spacingMedium,
                    ),
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
        final breakpoint = _getBreakpoints(constraints.maxWidth);
        final dimensions = _getDimensions(breakpoint);
        final horizontalMargin = constraints.maxWidth * dimensions.horizontalMargin;
        
        return Container(
          margin: EdgeInsets.all(horizontalMargin),
          padding: EdgeInsets.all(dimensions.contentPadding),
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
                padding: EdgeInsets.all(dimensions.spacingMedium),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A86FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF3A86FF),
                  size: dimensions.iconSize + 4,
                ),
              ),
              
              SizedBox(width: dimensions.spacingMedium),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_variaciones.length} variaciones',
                      style: TextStyle(
                        fontSize: dimensions.titleFontSize,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    Text(
                      'Desliza hacia la izquierda para eliminar',
                      style: TextStyle(
                        fontSize: dimensions.titleFontSize - 2,
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
        final breakpoint = _getBreakpoints(constraints.maxWidth);
        final dimensions = _getDimensions(breakpoint);
        final bottomPadding = breakpoint == ResponsiveBreakpoints.mobile ? 100.0 : 120.0;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF7FAFC),
          appBar: AppBar(
            title: Text(
              'Gestionar Variaciones',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: dimensions.titleFontSize,
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
                  itemBuilder: (_, __) => _buildShimmerItem(dimensions, constraints.maxWidth),
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
  }
}

// Enums y clases para el sistema responsive
enum ResponsiveBreakpoints {
  mobile,
  tabletSmall,
  tablet,
  desktop,
}

class ResponsiveDimensions {
  final double horizontalMargin; // Como porcentaje de la pantalla
  final double imageSize;
  final double contentPadding;
  final double titleFontSize;
  final double priceFontSize;
  final double iconSize;
  final double actionButtonSize;
  final double spacingLarge;
  final double spacingMedium;
  final int columns; // Para futuras implementaciones de grid

  const ResponsiveDimensions({
    required this.horizontalMargin,
    required this.imageSize,
    required this.contentPadding,
    required this.titleFontSize,
    required this.priceFontSize,
    required this.iconSize,
    required this.actionButtonSize,
    required this.spacingLarge,
    required this.spacingMedium,
    required this.columns,
  });
}