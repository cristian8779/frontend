import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

// Importaciones de servicios y widgets
import '../../services/producto_usuario_service.dart';
import '../../services/FavoritoService.dart'; // Importar el servicio de favoritos
// Importa tus widgets personalizados cuando los tengas listos:
// import 'widgets/color_selector.dart';
// import 'widgets/selector_talla.dart';
import '/utils/colores.dart'; // Para manejar colores

class ProductoScreen extends StatefulWidget {
  final String productId;
  const ProductoScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<ProductoScreen> createState() => _ProductoScreenState();
}

class _ProductoScreenState extends State<ProductoScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> producto;
  late Future<List<Map<String, dynamic>>> variaciones;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Servicios
  final FavoritoService _favoritoService = FavoritoService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Estados de selección
  List<String> coloresSeleccionados = [];
  List<String> tallasSeleccionadas = [];
  bool isFavorite = false;
  bool _isLoadingFavorite = true; // Para mostrar loading en el corazón
  bool _isLoggedIn = false; // Para verificar si está logueado
  int selectedImageIndex = 0;
  String currentTab = 'descripcion'; // 'descripcion' o 'especificaciones'

  @override
  void initState() {
    super.initState();
    producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId);
    variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    
    // Verificar estado de autenticación y favoritos
    _verificarEstadoFavorito();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 🔐 Verificar si el usuario está logueado y si el producto está en favoritos
  Future<void> _verificarEstadoFavorito() async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      // Verificar si hay token de acceso
      final token = await _secureStorage.read(key: 'accessToken');
      
      if (token == null || token.isEmpty) {
        setState(() {
          _isLoggedIn = false;
          _isLoadingFavorite = false;
          isFavorite = false;
        });
        return;
      }

      setState(() {
        _isLoggedIn = true;
      });

      // Obtener favoritos del usuario para verificar si este producto está incluido
      try {
        final favoritos = await _favoritoService.obtenerFavoritos();
        final esFavorito = favoritos.any((fav) => 
          (fav['productoId'] ?? fav['id']) == widget.productId
        );
        
        setState(() {
          isFavorite = esFavorito;
          _isLoadingFavorite = false;
        });
      } catch (e) {
        // Si hay error al obtener favoritos, asumir que no es favorito
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoggedIn = false;
        _isLoadingFavorite = false;
        isFavorite = false;
      });
    }
  }

  /// ❤️ Manejar toggle de favoritos
  Future<void> _toggleFavorito() async {
    // Si no está logueado, redirigir al login
    if (!_isLoggedIn) {
      _mostrarDialogoLogin();
      return;
    }

    // Mostrar loading en el botón
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      if (isFavorite) {
        // Eliminar de favoritos
        await _favoritoService.eliminarFavorito(widget.productId);
        setState(() {
          isFavorite = false;
          _isLoadingFavorite = false;
        });
        _mostrarSnackbar('💔 Eliminado de favoritos', isSuccess: true);
      } else {
        // Agregar a favoritos
        await _favoritoService.agregarFavorito(widget.productId);
        setState(() {
          isFavorite = true;
          _isLoadingFavorite = false;
        });
        _mostrarSnackbar('❤️ Agregado a favoritos', isSuccess: true);
      }
    } catch (e) {
      setState(() {
        _isLoadingFavorite = false;
      });
      
      String errorMessage = e.toString().replaceFirst('Exception: ', '');
      
      // Si el error es de autenticación, redirigir al login
      if (errorMessage.contains('token') || errorMessage.contains('acceso')) {
        _mostrarDialogoLogin();
      } else {
        _mostrarSnackbar('Error: $errorMessage', isSuccess: false);
      }
    }
  }

  /// 🚪 Mostrar diálogo para iniciar sesión
  void _mostrarDialogoLogin() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: EdgeInsets.zero,
          title: Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.2),
                        Colors.blue.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.login_rounded,
                    color: Colors.blue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Iniciar Sesión',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1a1a1a),
                    ),
                  ),
                ),
              ],
            ),
          ),
          content: Container(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: const Text(
              'Para agregar productos a favoritos necesitas iniciar sesión en tu cuenta.',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF757575),
                height: 1.5,
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 2,
              ),
              child: const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 📱 Mostrar SnackBar mejorado
  void _mostrarSnackbar(String mensaje, {required bool isSuccess}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                mensaje,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        elevation: 8,
      ),
    );
  }

  // Extraer colores únicos de las variaciones
  List<Map<String, String>> _extraerColoresDisponibles(List<Map<String, dynamic>> variations) {
    final Set<Map<String, String>> coloresSet = {};
    
    for (var variacion in variations) {
      if (variacion['color'] != null && variacion['color'] is Map) {
        final color = variacion['color'] as Map<String, dynamic>;
        if (color['nombre'] != null && color['hex'] != null) {
          coloresSet.add({
            'nombre': color['nombre'].toString(),
            'hex': color['hex'].toString(),
          });
        }
      }
    }
    
    return coloresSet.toList();
  }

  // Calcular precio basado en selecciones
  double _calcularPrecioSeleccion(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    if (variations.isEmpty || (coloresSeleccionados.isEmpty && tallasSeleccionadas.isEmpty)) {
      return double.tryParse(productData['precio'].toString()) ?? 0.0;
    }

    // Buscar variación que coincida con la selección
    for (var variacion in variations) {
      bool colorCoincide = coloresSeleccionados.isEmpty || 
          (variacion['color'] != null && 
           coloresSeleccionados.contains(variacion['color']['hex']));
      
      bool tallaCoincide = tallasSeleccionadas.isEmpty ||
          tallasSeleccionadas.contains(variacion['tallaNumero']?.toString()) ||
          tallasSeleccionadas.contains(variacion['tallaLetra']?.toString());

      if (colorCoincide && tallaCoincide) {
        return double.tryParse(variacion['precio'].toString()) ?? 
               double.tryParse(productData['precio'].toString()) ?? 0.0;
      }
    }

    return double.tryParse(productData['precio'].toString()) ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: FutureBuilder(
        future: Future.wait([producto, variaciones]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          Map<String, dynamic> productData = snapshot.data![0];
          List<Map<String, dynamic>> variations = snapshot.data![1];
          
          final coloresDisponibles = _extraerColoresDisponibles(variations);
          final precioActual = _calcularPrecioSeleccion(productData, variations);

          return FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              slivers: [
                _buildSliverAppBar(productData),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProductHeader(productData, precioActual),
                        const SizedBox(height: 24),
                        
                        // Solo mostrar selectores si hay variaciones
                        if (variations.isNotEmpty) ...[
                          _buildVariationSelectors(coloresDisponibles, variations),
                          const SizedBox(height: 24),
                        ],
                        
                        _buildTabBar(),
                        const SizedBox(height: 16),
                        _buildTabContent(productData, variations),
                        const SizedBox(height: 100), // Espacio para el botón flotante
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildPurchaseButton(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(strokeWidth: 3),
          SizedBox(height: 16),
          Text('Cargando producto...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text('Error al cargar el producto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {
              producto = ProductoUsuarioService().obtenerProductoPorId(widget.productId);
              variaciones = ProductoUsuarioService().obtenerVariacionesPorProducto(widget.productId);
            }),
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(Map<String, dynamic> productData) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: _isLoadingFavorite
              ? Container(
                  width: 48,
                  height: 48,
                  padding: const EdgeInsets.all(12),
                  child: const CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                  ),
                )
              : IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleFavorito, // Usar el método correcto
                ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Hero(
          tag: 'product-image-${widget.productId}',
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(productData['imagen']),
                fit: BoxFit.cover,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductHeader(Map<String, dynamic> productData, double precioActual) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          productData['nombre'],
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              '\$${precioActual.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(width: 8),
            if (precioActual != double.tryParse(productData['precio'].toString())) ...[
              Text(
                '\$${productData['precio']}',
                style: TextStyle(
                  fontSize: 18,
                  decoration: TextDecoration.lineThrough,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildVariationSelectors(List<Map<String, String>> coloresDisponibles, List<Map<String, dynamic>> variations) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selector de colores (solo si hay colores disponibles)
        if (coloresDisponibles.isNotEmpty) ...[
          const Text(
            'Colores disponibles:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildColorSelector(coloresDisponibles),
          const SizedBox(height: 24),
        ],
        
        // Selector de tallas (solo si hay tallas disponibles)
        if (_tieneVariacionesDeTalla(variations)) ...[
          const Text(
            'Tallas disponibles:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          _buildSizeSelector(variations),
        ],
      ],
    );
  }

  bool _tieneVariacionesDeTalla(List<Map<String, dynamic>> variations) {
    return variations.any((v) => v['tallaNumero'] != null || v['tallaLetra'] != null);
  }

  Widget _buildColorSelector(List<Map<String, String>> coloresDisponibles) {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: coloresDisponibles.length,
        itemBuilder: (context, index) {
          final colorData = coloresDisponibles[index];
          final hex = colorData['hex']!;
          final nombre = colorData['nombre']!;
          final color = Colores.hexToColor(hex);
          final seleccionado = coloresSeleccionados.contains(hex);

          return GestureDetector(
            onTap: () {
              setState(() {
                if (seleccionado) {
                  coloresSeleccionados.clear();
                } else {
                  coloresSeleccionados.clear();
                  coloresSeleccionados.add(hex);
                }
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      border: Border.all(
                        color: seleccionado ? Colors.black : Colors.grey.shade300,
                        width: seleccionado ? 3 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: seleccionado 
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nombre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
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

  Widget _buildSizeSelector(List<Map<String, dynamic>> variations) {
    final tallas = <String>{};
    for (var v in variations) {
      if (v['tallaNumero'] != null) tallas.add(v['tallaNumero'].toString());
      if (v['tallaLetra'] != null) tallas.add(v['tallaLetra'].toString());
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tallas.map((talla) {
        final seleccionado = tallasSeleccionadas.contains(talla);
        
        return GestureDetector(
          onTap: () {
            setState(() {
              if (seleccionado) {
                tallasSeleccionadas.clear();
              } else {
                tallasSeleccionadas.clear();
                tallasSeleccionadas.add(talla);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: seleccionado ? Colors.black : Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              talla,
              style: TextStyle(
                color: seleccionado ? Colors.white : Colors.black,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentTab = 'descripcion'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: currentTab == 'descripcion' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Descripción',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: currentTab == 'descripcion' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => currentTab = 'especificaciones'),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: currentTab == 'especificaciones' ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Detalles',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: currentTab == 'especificaciones' ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: currentTab == 'descripcion'
          ? _buildDescription(productData)
          : _buildSpecifications(productData, variations),
    );
  }

  Widget _buildDescription(Map<String, dynamic> productData) {
    return Container(
      key: const ValueKey('descripcion'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        productData['descripcion'] ?? 'Sin descripción disponible.',
        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
      ),
    );
  }

  Widget _buildSpecifications(Map<String, dynamic> productData, List<Map<String, dynamic>> variations) {
    return Container(
      key: const ValueKey('especificaciones'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSpecItem('Producto', productData['nombre']),
          _buildSpecItem('Precio base', '\$${productData['precio']}'),
          if (variations.isNotEmpty) _buildSpecItem('Variaciones', '${variations.length} disponibles'),
          _buildSpecItem('ID', widget.productId),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ElevatedButton.icon(
        icon: const Icon(Icons.shopping_cart_outlined, size: 20),
        label: const Text('Comprar ahora', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        onPressed: () {
          // Validar selecciones antes de proceder
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🛒 Producto agregado al carrito'),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
            ),
          );
          print('🛒 Iniciando compra - Colores: $coloresSeleccionados, Tallas: $tallasSeleccionadas');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}