// screens/historial_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/HistorialService.dart';
import '../../../services/FavoritoService.dart';
import 'package:shimmer/shimmer.dart';

class HistorialScreen extends StatefulWidget {
  const HistorialScreen({super.key});

  @override
  State<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends State<HistorialScreen> {
  final HistorialService _historialService = HistorialService();
  final FavoritoService _favoritoService = FavoritoService();
  final NumberFormat _formatoPesos = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
  );
  
  Map<String, dynamic> _historial = {};
  Set<String> _productosFavoritos = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarHistorial();
    _cargarFavoritos();
  }

  Future<void> _cargarHistorial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _historialService.obtenerHistorial();
      setState(() {
        _historial = data;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _cargarFavoritos() async {
    try {
      final favoritos = await _favoritoService.obtenerFavoritos();
      setState(() {
        _productosFavoritos = favoritos
            .map((fav) => fav['producto']['_id'] as String)
            .toSet();
      });
    } catch (e) {
      print('Error al cargar favoritos: $e');
      // No mostramos error en UI para favoritos, solo lo logueamos
    }
  }

  Future<void> _toggleFavorito(String productoId, String nombreProducto) async {
    try {
      if (_productosFavoritos.contains(productoId)) {
        // Eliminar de favoritos
        await _favoritoService.eliminarFavorito(productoId);
        setState(() {
          _productosFavoritos.remove(productoId);
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.heart_broken, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Flexible(child: Text('Eliminado de favoritos')),
                ],
              ),
              backgroundColor: Colors.grey.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        // Agregar a favoritos
        await _favoritoService.agregarFavorito(productoId);
        setState(() {
          _productosFavoritos.add(productoId);
        });
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.favorite, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Flexible(child: Text('Agregado a favoritos')),
                ],
              ),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _eliminarItem(String id) async {
    try {
      await _historialService.eliminarDelHistorial(id);
      _cargarHistorial();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(child: Text('Producto eliminado del historial')),
              ],
            ),
            backgroundColor: const Color(0xFF00A650),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  Future<void> _borrarTodo() async {
    try {
      await _historialService.borrarHistorialCompleto();
      _cargarHistorial();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Flexible(child: Text('Historial borrado completamente')),
              ],
            ),
            backgroundColor: const Color(0xFF00A650),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    }
  }

  void _mostrarDialogoBorrarTodo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, 
                 color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 8),
            const Flexible(
              child: Text(
                "Borrar historial",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: const Text(
          "¿Seguro que quieres borrar todo el historial? Esta acción no se puede deshacer.",
          style: TextStyle(fontSize: 15, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w500)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _borrarTodo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Borrar todo", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      appBar: AppBar(
        title: const Text(
          "Historial",
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          if (!_loading && _historial.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.black87),
              onPressed: _mostrarDialogoBorrarTodo,
            ),
        ],
      ),
      body: _loading
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _historial.isEmpty
                  ? _buildEmptyState()
                  : _buildHistorialContent(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3483FA)),
          ),
          SizedBox(height: 16),
          Text(
            "Cargando historial...",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              "Error al cargar",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _cargarHistorial,
              child: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text(
              "No hay productos en el historial",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              "Los productos que veas aparecerán aquí",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorialContent() {
    return RefreshIndicator(
      onRefresh: _cargarHistorial,
      color: const Color(0xFF3483FA),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 600;
          final crossAxisCount = isTablet ? 2 : 1;
          
          if (isTablet) {
            return _buildGridView(crossAxisCount);
          } else {
            return _buildListView();
          }
        },
      ),
    );
  }

  Widget _buildGridView(int crossAxisCount) {
    final allItems = <Map<String, dynamic>>[];
    
    _historial.forEach((fecha, items) {
      for (var item in items) {
        // Filtrar items con producto null
        if (item['producto'] != null) {
          allItems.add({
            ...item,
            'fecha': fecha,
          });
        }
      }
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: allItems.length,
      itemBuilder: (context, index) {
        return _buildProductCard(allItems[index]);
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(0),
      itemCount: _historial.length,
      itemBuilder: (context, index) {
        final entry = _historial.entries.elementAt(index);
        final items = (entry.value as List<dynamic>)
            .where((item) => item['producto'] != null) // Filtrar productos null
            .toList();
        
        // Solo mostrar la sección si tiene items válidos
        if (items.isNotEmpty) {
          return _buildDateSection(entry.key, items);
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget _buildDateSection(String fecha, List<dynamic> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de fecha
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: const Color(0xFFE5E5E5),
          child: Text(
            fecha,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        // Lista de productos
        Container(
          color: Colors.white,
          child: Column(
            children: items.map((item) => _buildProductItem(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(dynamic item) {
    final producto = item['producto'];
    // Verificaciones de null safety
    if (producto == null) return const SizedBox.shrink();
    
    final nombre = producto['nombre'] ?? "Producto sin nombre";
    final precio = producto['precio'];
    final imagen = producto['imagen'];
    final fecha = item['fecha'];
    final productoId = producto['_id'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fecha y favorito
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fecha,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (productoId != null)
                  GestureDetector(
                    onTap: () => _toggleFavorito(productoId, nombre),
                    child: Icon(
                      _productosFavoritos.contains(productoId)
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: _productosFavoritos.contains(productoId)
                          ? Colors.red
                          : Colors.grey[400],
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Imagen del producto
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: imagen != null
                      ? Image.network(
                          imagen,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.image_not_supported,
                              color: Colors.grey[400],
                              size: 40,
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey.shade300,
                              highlightColor: Colors.grey.shade100,
                              child: Container(color: Colors.white),
                            );
                          },
                        )
                      : Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 40,
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Nombre del producto
            Text(
              nombre,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Precio
            if (precio != null) ...[
              Text(
                _formatoPesos.format(precio),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
            ],
            // Botón eliminar
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _eliminarItem(item['_id']),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF3483FA),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(dynamic item) {
    final producto = item['producto'];
    // Verificaciones de null safety
    if (producto == null) return const SizedBox.shrink();
    
    final nombre = producto['nombre'] ?? "Producto sin nombre";
    final precio = producto['precio'];
    final imagen = producto['imagen'];
    final productoId = producto['_id'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E5E5), width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto - más grande
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imagen != null
                  ? Image.network(
                      imagen,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          color: Colors.grey[400],
                          size: 40,
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey.shade300,
                          highlightColor: Colors.grey.shade100,
                          child: Container(color: Colors.white),
                        );
                      },
                    )
                  : Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[400],
                      size: 40,
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Información del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icono de favorito
                Row(
                  children: [
                    const Spacer(),
                    if (productoId != null)
                      GestureDetector(
                        onTap: () => _toggleFavorito(productoId, nombre),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            _productosFavoritos.contains(productoId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _productosFavoritos.contains(productoId)
                                ? Colors.red
                                : Colors.grey[400],
                            size: 24,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Nombre del producto
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                // Precio
                if (precio != null) ...[
                  Text(
                    _formatoPesos.format(precio),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Botón eliminar
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => _eliminarItem(item['_id']),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3483FA),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      "Eliminar",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}