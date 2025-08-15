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

  Widget _buildStockChip(int stock) {
    final color = _getStockColor(stock);
    final label = _getStockLabel(stock);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$stock ($label)',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerItem() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 16,
                      width: 120,
                      color: Colors.grey,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    Container(
                      height: 14,
                      width: 80,
                      color: Colors.grey,
                      margin: const EdgeInsets.only(bottom: 8),
                    ),
                    Container(
                      height: 12,
                      width: 100,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    color: Colors.grey,
                    margin: const EdgeInsets.only(bottom: 8),
                  ),
                  Container(
                    width: 32,
                    height: 32,
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
    final Map<String, dynamic>? colorData = variacion['color'];
    final String color = colorData?['nombre'] ?? 'Sin color';
    final String talla = variacion['tallaNumero']?.toString() ?? variacion['tallaLetra'] ?? 'Sin talla';
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
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.delete_outline, color: Colors.white, size: 28),
              const SizedBox(height: 4),
              const Text(
                'Eliminar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
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
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
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
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Imagen
                Container(
                  width: 60,
                  height: 60,
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
                                size: 24,
                              ),
                            ),
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
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
                              size: 24,
                            ),
                          ),
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Información principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        '$color - $talla',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Precio
                      Row(
                        children: [
                          Icon(
                            Icons.attach_money,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          Text(
                            precio.toStringAsFixed(2),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF3A86FF),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Stock
                      _buildStockChip(stock),
                    ],
                  ),
                ),
                
                // Acciones
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A86FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: Color(0xFF3A86FF),
                          size: 20,
                        ),
                        tooltip: 'Editar variación',
                        onPressed: _navigateToCrearVariacion,
                        splashRadius: 20,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Colors.red.shade600,
                          size: 20,
                        ),
                        tooltip: 'Eliminar variación',
                        onPressed: () {
                          final index = _variaciones.indexWhere(
                            (v) => v['_id'] == variacion['_id']
                          );
                          if (index != -1) _confirmDelete(index);
                        },
                        splashRadius: 20,
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
  }

  Future<bool?> _showDeleteDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.warning_outlined,
                color: Colors.red.shade600,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Confirmar eliminación',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: const Text(
          '¿Está seguro que desea eliminar esta variación? Esta acción no se puede deshacer.',
          style: TextStyle(color: Color(0xFF718096)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int index) async {
    final confirmed = await _showDeleteDialog();
    if (confirmed == true) {
      _deleteVariacion(index);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3A86FF).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Color(0xFF3A86FF),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              'No hay variaciones',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'Agrega la primera variación de tu producto para empezar a vender',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            
            const SizedBox(height: 32),
            
            ElevatedButton.icon(
              onPressed: _navigateToCrearVariacion,
              icon: const Icon(Icons.add, size: 20),
              label: const Text(
                'Crear primera variación',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3A86FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
  }

  Widget _buildHeader() {
    if (_variaciones.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(16),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3A86FF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF3A86FF),
              size: 24,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_variaciones.length} variaciones',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  'Desliza hacia la izquierda para eliminar',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestionar Variaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
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
                          padding: const EdgeInsets.only(bottom: 100),
                          initialItemCount: _variaciones.length,
                          itemBuilder: (context, index, animation) {
                            return _buildVariacionItem(_variaciones[index], animation);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCrearVariacion,
        tooltip: 'Agregar variación',
        backgroundColor: const Color(0xFF3A86FF),
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Nueva variación',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}