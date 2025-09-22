import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:crud/providers/producto_admin_provider.dart';

class ProductoCard extends StatefulWidget {
  final String id;
  
  // NUEVO: Parámetro para pasar el producto directamente (opcional)
  final Map<String, dynamic>? producto;
  
  // Parámetros DEPRECATED - mantenidos por compatibilidad
  @deprecated
  final String? nombre;
  @deprecated
  final String? imagenUrl;
  @deprecated
  final double? precio;
  
  final VoidCallback? onTap;
  final VoidCallback? onProductoEliminado;
  final VoidCallback? onProductoActualizado;

  const ProductoCard({
    super.key,
    required this.id,
    this.producto, // NUEVO: producto opcional
    @deprecated this.nombre,
    @deprecated this.imagenUrl,
    @deprecated this.precio,
    this.onTap,
    this.onProductoEliminado,
    this.onProductoActualizado,
  });

  @override
  State<ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<ProductoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  // Formatter para pesos colombianos
  final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Debug info
    debugPrint('ProductoCard iniciado - ID: ${widget.id}, tiene producto: ${widget.producto != null}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return _currencyFormatter.format(price);
  }

  // MEJORADO: Método para encontrar el producto con múltiples fuentes
  Map<String, dynamic>? _findProductoInProvider(ProductoProvider provider) {
    // 1. Si se pasó el producto directamente, usarlo (más eficiente)
    if (widget.producto != null) {
      debugPrint('Usando producto pasado directamente: ${widget.producto!['nombre']}');
      return widget.producto;
    }

    // 2. Buscar en productos del provider
    Map<String, dynamic>? producto;
    
    try {
      // Buscar por _id en productos principales
      producto = provider.productos.firstWhere(
        (p) => p['_id']?.toString() == widget.id || p['id']?.toString() == widget.id,
      );
      debugPrint('Producto encontrado en provider.productos: ${producto['nombre']}');
      return producto;
    } catch (e) {
      // No encontrado en productos principales
    }

    try {
      // Buscar por _id en productos filtrados
      producto = provider.productosFiltrados.firstWhere(
        (p) => p['_id']?.toString() == widget.id || p['id']?.toString() == widget.id,
      );
      debugPrint('Producto encontrado en provider.productosFiltrados: ${producto['nombre']}');
      return producto;
    } catch (e) {
      // No encontrado en productos filtrados
    }

    debugPrint('❌ Producto NO encontrado en provider - ID: ${widget.id}');
    debugPrint('   - Productos en provider: ${provider.productos.length}');
    debugPrint('   - Productos filtrados: ${provider.productosFiltrados.length}');
    debugPrint('   - IDs en provider: ${provider.productos.map((p) => p['_id']).take(5).toList()}');
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        // Obtener datos del producto
        final producto = _findProductoInProvider(provider);
        
        // MEJORADO: Obtener datos de forma más robusta
        final nombre = producto?['nombre']?.toString() ?? 
                      widget.nombre ?? 
                      'Sin nombre';
        
        // CORREGIDO: Manejar tanto 'imagen' como 'imagenUrl'
        final imagenUrl = producto?['imagen']?.toString() ?? 
                         producto?['imagenUrl']?.toString() ?? 
                         widget.imagenUrl ?? 
                         '';
        
        final precio = (producto?['precio'] as num?)?.toDouble() ?? 
                      widget.precio ?? 
                      0.0;
        
        final disponible = producto?['disponible'] as bool? ?? true;
        final estado = producto?['estado']?.toString() ?? 'activo';
        final stock = (producto?['stock'] as num?)?.toInt() ?? 0;

        // MEJORADO: Mostrar más información de debug
        if (producto == null && widget.nombre == null) {
          return Container(
            height: 320,
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red[200]!, width: 1),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[400], size: 48),
                    const SizedBox(height: 8),
                    Text(
                      'Producto no encontrado',
                      style: TextStyle(
                        color: Colors.red[700], 
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${widget.id}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Productos en provider: ${provider.productos.length}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 10),
                    ),
                    if (provider.productos.isNotEmpty)
                      Text(
                        'Primer ID: ${provider.productos.first['_id']}',
                        style: TextStyle(color: Colors.grey[500], fontSize: 10),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        return AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: GestureDetector(
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                  _animationController.forward();
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                  widget.onTap?.call();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                },
                child: Container(
                  height: 320,
                  margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: !disponible || estado != 'activo' 
                        ? Border.all(color: Colors.grey[300]!, width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Imagen del producto
                      Expanded(
                        flex: 7,
                        child: Stack(
                          children: [
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              child: Hero(
                                tag: 'producto_${widget.id}',
                                child: Stack(
                                  children: [
                                    Image.network(
                                      imagenUrl.isNotEmpty
                                          ? imagenUrl
                                          : 'https://via.placeholder.com/400x280/f5f5f5/cccccc?text=Sin+Imagen',
                                      fit: BoxFit.contain,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              Colors.blue[600]!,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) =>
                                          Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported_outlined,
                                              size: 40,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Sin imagen',
                                              style: TextStyle(
                                                color: Colors.grey[500],
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Overlay si no está disponible
                                    if (!disponible || estado != 'activo')
                                      Container(
                                        width: double.infinity,
                                        height: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12, 
                                              vertical: 6
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red[100],
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              !disponible ? 'No disponible' : 'Inactivo',
                                              style: TextStyle(
                                                color: Colors.red[700],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),

                            // Botón de opciones
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => _mostrarOpciones(context, nombre, imagenUrl, precio),
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Icon(
                                        Icons.more_vert,
                                        color: Colors.grey[600],
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // MEJORADO: Indicador de stock bajo
                            if (stock <= 5 && stock > 0)
                              Positioned(
                                bottom: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[600],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Stock: $stock',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),

                            // Indicador de estado actualizado
                            if (provider.state == ProductoState.updating && 
                                provider.productoSeleccionado?['_id'] == widget.id)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[600],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Información del producto
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatPrice(precio),
                              style: TextStyle(
                                color: !disponible || estado != 'activo' 
                                    ? Colors.grey[500] 
                                    : Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                decoration: !disponible || estado != 'activo'
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              nombre,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: !disponible || estado != 'activo'
                                    ? Colors.grey[500]
                                    : Colors.grey[700],
                                fontSize: 11,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ... resto de los métodos permanecen igual ...
  void _mostrarOpciones(BuildContext context, String nombre, String imagenUrl, double precio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header con preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imagenUrl.isNotEmpty
                              ? imagenUrl
                              : 'https://via.placeholder.com/100',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.image, color: Colors.grey[400]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatPrice(precio),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 24),

              // Opciones
              _buildOptionTile(
                icon: Icons.tune,
                iconColor: Colors.blue[600]!,
                title: 'Gestionar variaciones',
                subtitle: 'Configurar tallas, colores, etc.',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(
                    context,
                    '/gestionar-variaciones',
                    arguments: widget.id,
                  );
                },
              ),
              _buildOptionTile(
                icon: Icons.edit_outlined,
                iconColor: Colors.orange[600]!,
                title: 'Editar producto',
                subtitle: 'Modificar información y detalles',
                onTap: () => _editarProducto(context),
              ),
              _buildOptionTile(
                icon: Icons.delete_outline,
                iconColor: Colors.red[600]!,
                title: 'Eliminar producto',
                subtitle: 'Esta acción no se puede deshacer',
                onTap: () => _confirmarEliminacion(context, nombre),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      ),
      onTap: onTap,
    );
  }

  void _editarProducto(BuildContext context) async {
    Navigator.pop(context);
    
    final result = await Navigator.pushNamed(
      context,
      '/editar-producto',
      arguments: widget.id,
    );

    if (result == true && mounted) {
      widget.onProductoActualizado?.call();
    }
  }

  void _confirmarEliminacion(BuildContext context, String nombre) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('¿Eliminar "$nombre"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => _eliminarProducto(context),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _eliminarProducto(BuildContext context) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    
    navigator.pop();

    final provider = Provider.of<ProductoProvider>(context, listen: false);
    final success = await provider.eliminarProducto(widget.id);

    if (!mounted) return;

    if (success) {
      widget.onProductoEliminado?.call();
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Producto eliminado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Error desconocido'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}