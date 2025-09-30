import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/producto_service.dart';
import '../../providers/categoria_provider.dart';
import 'buscador.dart';
import '../screens/producto/producto_screen.dart';
import '../screens/usuario/ProductosPorCategoriaScreen.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({Key? key}) : super(key: key);

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> with TickerProviderStateMixin {
  final ProductoService _productoService = ProductoService();
  final TextEditingController _controller = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<Map<String, dynamic>> _resultadosProductos = [];
  List<Map<String, dynamic>> _resultadosCategorias = [];
  bool _cargando = false;
  String _busqueda = "";

  // Paleta de colores pastel
  static const Color _backgroundColor = Color(0xFFFAFAFA);
  static const Color _cardColor = Color(0xFFFFFFFF);
  static const Color _primaryPastel = Color(0xFFE8F4FD);
  static const Color _accentPastel = Color(0xFFF0F8E8);
  static const Color _rosePastel = Color(0xFFFDF2F8);
  static const Color _lavenderPastel = Color(0xFFF3F0FF);
  static const Color _peachPastel = Color(0xFFFFF7ED);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    // ✅ SOLUCIÓN: Desenfoca cualquier campo de texto antes de cerrar la pantalla
    _unfocusSearchField();
    _controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ✅ NUEVA FUNCIÓN: Desenfocar el campo de búsqueda
  void _unfocusSearchField() {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
    }
  }

  // ✅ FUNCIÓN MEJORADA: Manejar el botón de regreso
  void _handleBackPress() {
    _unfocusSearchField(); // Desenfoca antes de cerrar
    Navigator.of(context).pop();
  }

  // Función para determinar si estamos en tablet
  bool _isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= 768;
  }

  // Función para determinar el número de columnas en grid
  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 3; // Desktop
    if (width >= 768) return 2;  // Tablet
    return 1; // Mobile
  }

  // Función para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return const EdgeInsets.symmetric(horizontal: 24);
    if (width >= 768) return const EdgeInsets.symmetric(horizontal: 20);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  // Función para obtener tamaño de fuente responsivo
  double _getResponsiveFontSize(BuildContext context, double baseFontSize) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return baseFontSize + 2;
    if (width >= 768) return baseFontSize + 1;
    return baseFontSize;
  }

  Future<void> _buscarProductos([String? query]) async {
    if (query != null) {
      setState(() {
        _busqueda = query;
      });
    }

    setState(() {
      _cargando = true;
      _resultadosProductos = [];
      _resultadosCategorias = [];
    });

    try {
      if (_busqueda.isNotEmpty) {
        // Buscar productos
        final productos = await _productoService.buscarProductos(query: _busqueda);
        
        // Buscar categorías que coincidan con la búsqueda
        final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
        final categoriasFiltradas = categoriaProvider.categorias.where((categoria) {
          final nombre = categoria['nombre']?.toString().toLowerCase() ?? '';
          return nombre.contains(_busqueda.toLowerCase());
        }).toList();

        setState(() {
          _resultadosProductos = productos;
          _resultadosCategorias = categoriasFiltradas;
        });

        if (_resultadosProductos.isNotEmpty || _resultadosCategorias.isNotEmpty) {
          _animationController.forward();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.error_outline_rounded,
                    color: Colors.grey.shade100,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Error al buscar: $e",
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: EdgeInsets.all(_isTablet(context) ? 24 : 16),
          ),
        );
      }
    } finally {
      setState(() {
        _cargando = false;
      });
    }
  }

  void _limpiarBusqueda() {
    setState(() {
      _resultadosProductos = [];
      _resultadosCategorias = [];
      _busqueda = "";
      _controller.clear();
    });
    _animationController.reset();
    // ✅ Opcional: también desenfocar al limpiar la búsqueda
    _unfocusSearchField();
  }

  String _formatearPrecio(dynamic precio) {
    if (precio == null) return "--";

    final numero = int.tryParse(precio.toString());
    if (numero == null) return "--";

    final formatter = NumberFormat("#,##0", "es_ES");
    return "\$${formatter.format(numero)}";
  }

  void _navegarACategoria(Map<String, dynamic> categoria) {
    // ✅ Desenfoca antes de navegar
    _unfocusSearchField();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductosPorCategoriaScreen(
          categoriaId: categoria['_id'],
          categoriaNombre: categoria['nombre'] ?? 'Categoría',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tieneResultados = _resultadosProductos.isNotEmpty || _resultadosCategorias.isNotEmpty;
    final isTablet = _isTablet(context);
    final padding = _getResponsivePadding(context);

    // ✅ SOLUCIÓN: Usar WillPopScope para manejar el botón de regreso del sistema
    return WillPopScope(
      onWillPop: () async {
        _unfocusSearchField();
        return true; // Permite que se cierre la pantalla
      },
      child: Scaffold(
        backgroundColor: _backgroundColor,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: true,
          leading: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.grey.shade600,
                size: 20,
              ),
              // ✅ SOLUCIÓN: Usar la nueva función para manejar el regreso
              onPressed: _handleBackPress,
            ),
          ),
          title: BuscadorProductos(
            busqueda: _busqueda,
            controller: _controller,
            onBusquedaChanged: (value) => _buscarProductos(value),
            onClear: _limpiarBusqueda,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.grey.shade200,
                    Colors.transparent,
                    Colors.grey.shade200,
                  ],
                ),
              ),
            ),
          ),
        ),
        // ✅ SOLUCIÓN: Agregar GestureDetector para desenfocar al tocar fuera del campo
        body: GestureDetector(
          onTap: _unfocusSearchField,
          child: Column(
            children: [
              // Mostrar header solo si hay resultados o búsqueda
              if (tieneResultados || _busqueda.isNotEmpty)
                _buildHeaderStats(context),

              Expanded(
                child: _cargando
                    ? _buildLoadingState(context)
                    : tieneResultados
                        ? _buildResultsList(context)
                        : _buildEmptyState(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- Widgets Responsivos (sin cambios) -------------------

  Widget _buildHeaderStats(BuildContext context) {
    final padding = _getResponsivePadding(context);
    final isTablet = _isTablet(context);
    final totalResultados = _resultadosProductos.length + _resultadosCategorias.length;

    return Container(
      margin: EdgeInsets.fromLTRB(
        padding.horizontal,
        isTablet ? 16 : 12,
        padding.horizontal,
        isTablet ? 12 : 8,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 16 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryPastel, _accentPastel],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isTablet ? 12 : 8,
            offset: Offset(0, isTablet ? 3 : 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 10 : 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(isTablet ? 12 : 10),
            ),
            child: Icon(
              Icons.analytics_outlined,
              color: Colors.grey.shade600,
              size: isTablet ? 24 : 20,
            ),
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resultados para "$_busqueda"',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
                Text(
                  '$totalResultados resultados encontrados',
                  style: TextStyle(
                    fontSize: _getResponsiveFontSize(context, 12),
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final isTablet = _isTablet(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 32 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryPastel, _lavenderPastel],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isTablet ? 24 : 20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: isTablet ? 16 : 12,
                  offset: Offset(0, isTablet ? 6 : 4),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
              strokeWidth: isTablet ? 4 : 3,
            ),
          ),
          SizedBox(height: isTablet ? 32 : 24),
          Text(
            "Buscando...",
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade700,
            ),
          ),
          SizedBox(height: isTablet ? 12 : 8),
          Text(
            "Un momento por favor",
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 14),
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList(BuildContext context) {
    final padding = _getResponsivePadding(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          padding.horizontal,
          8,
          padding.horizontal,
          24,
        ),
        children: [
          // Mostrar categorías si hay coincidencias
          if (_resultadosCategorias.isNotEmpty) ...[
            _buildSectionHeader(context, 'Categorías', Icons.category_rounded),
            const SizedBox(height: 12),
            ..._resultadosCategorias.map((categoria) => 
              _buildCategoryCard(context, categoria)).toList(),
          ],
          
          // Mostrar productos si hay coincidencias
          if (_resultadosProductos.isNotEmpty) ...[
            if (_resultadosCategorias.isNotEmpty) const SizedBox(height: 24),
            _buildSectionHeader(context, 'Productos', Icons.shopping_bag_rounded),
            const SizedBox(height: 12),
            ..._resultadosProductos.map((producto) => 
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: _buildProductCard(context, producto),
              )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final isTablet = _isTablet(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 16 : 12,
        vertical: isTablet ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: _lavenderPastel,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.grey.shade600,
            size: isTablet ? 22 : 20,
          ),
          SizedBox(width: isTablet ? 12 : 10),
          Text(
            title,
            style: TextStyle(
              fontSize: _getResponsiveFontSize(context, 16),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> categoria) {
    final isTablet = _isTablet(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3498DB).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _navegarACategoria(categoria),
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: isTablet ? 60 : 50,
                  height: isTablet ? 60 : 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryPastel, _accentPastel],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.category_rounded,
                    color: const Color(0xFF3498DB),
                    size: isTablet ? 30 : 26,
                  ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        categoria['nombre'] ?? "Sin nombre",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: _getResponsiveFontSize(context, 16),
                          color: const Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 4 : 3,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryPastel,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Ver productos',
                          style: TextStyle(
                            color: const Color(0xFF3498DB),
                            fontWeight: FontWeight.w500,
                            fontSize: _getResponsiveFontSize(context, 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: const Color(0xFF3498DB),
                  size: isTablet ? 20 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, Map<String, dynamic> producto) {
    final isTablet = _isTablet(context);
    final imageSize = isTablet ? 80.0 : 60.0;
    
    return Container(
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // ✅ Desenfoca antes de navegar al producto
            _unfocusSearchField();
            
            final productId = producto['_id'];
            if (productId != null && productId.toString().isNotEmpty) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductoScreen(productId: producto['_id']),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Error: Producto sin ID válido",
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: EdgeInsets.all(_isTablet(context) ? 24 : 16),
                ),
              );
            }
          },
          child: Padding(
            padding: EdgeInsets.all(isTablet ? 20 : 16),
            child: Row(
              children: [
                Container(
                  width: imageSize,
                  height: imageSize,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: producto['imagen'] != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            producto['imagen'],
                            width: imageSize,
                            height: imageSize,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.image_not_supported_rounded,
                                color: Colors.grey.shade500,
                                size: isTablet ? 32 : 28,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.shopping_bag_rounded,
                            color: Colors.grey.shade500,
                            size: isTablet ? 32 : 28,
                          ),
                        ),
                ),
                SizedBox(width: isTablet ? 20 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        producto['nombre'] ?? "Sin nombre",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: _getResponsiveFontSize(context, 16),
                          color: const Color(0xFF2C3E50),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isTablet ? 6 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTablet ? 10 : 8,
                          vertical: isTablet ? 5 : 4,
                        ),
                        decoration: BoxDecoration(
                          color: _accentPastel,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatearPrecio(producto['precio']),
                          style: TextStyle(
                            color: const Color(0xFF27AE60),
                            fontWeight: FontWeight.w700,
                            fontSize: _getResponsiveFontSize(context, 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.grey.shade400,
                  size: isTablet ? 28 : 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final padding = _getResponsivePadding(context);
    final isTablet = _isTablet(context);

    return Center(
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 40 : 32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primaryPastel, _lavenderPastel],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(isTablet ? 32 : 24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: isTablet ? 16 : 12,
                    offset: Offset(0, isTablet ? 6 : 4),
                  ),
                ],
              ),
              child: Icon(
                _busqueda.isEmpty
                    ? Icons.search_rounded
                    : Icons.search_off_rounded,
                size: isTablet ? 80 : 64,
                color: Colors.grey.shade400,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            Text(
              _busqueda.isEmpty
                  ? "¡Empieza a buscar!"
                  : "No encontramos nada",
              style: TextStyle(
                fontSize: _getResponsiveFontSize(context, 20),
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 500 : 300),
              child: Text(
                _busqueda.isEmpty
                    ? "Escribe el nombre del producto o categoría que buscas"
                    : "Intenta con otros términos de búsqueda",
                style: TextStyle(
                  fontSize: _getResponsiveFontSize(context, 14),
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (_busqueda.isNotEmpty) ...[
              SizedBox(height: isTablet ? 32 : 24),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryPastel, _accentPastel],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                    onTap: _limpiarBusqueda,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isTablet ? 24 : 20,
                        vertical: isTablet ? 16 : 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.autorenew_rounded,
                            size: isTablet ? 24 : 22,
                            color: const Color(0xFF6B7280),
                          ),
                          SizedBox(width: isTablet ? 10 : 8),
                          Text(
                            "Nueva búsqueda",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                              fontSize: _getResponsiveFontSize(context, 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}