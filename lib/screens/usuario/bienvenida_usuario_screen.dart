import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_flushbar/flushbar.dart'; // 👈 Import nuevo

import '../../widgets/banner_carousel.dart';
import '../../widgets/buscador.dart';
import '../../widgets/pantalla_busqueda.dart';
import '../../widgets/CategoriasWidget.dart';
import '../../widgets/ProductosHorizontalesWidget.dart';  // 🔹 Import agregado
import '../../widgets/ListaProductosWidget.dart';         // 🔹 Import agregado
import '../../providers/auth_provider.dart';
import '../../providers/producto_provider.dart';
import '../../providers/categoria_provider.dart';
import '../../providers/anuncio_provider.dart';

import '../../utils/invitacion_dialog.dart';
import '../home/home_screen.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../usuario/productosPorCategoriaScreen.dart';
import '../usuario/todas_categorias_screen.dart';



class BienvenidaUsuarioScreen extends StatefulWidget {
  const BienvenidaUsuarioScreen({super.key});

  @override
  State<BienvenidaUsuarioScreen> createState() =>
      _BienvenidaUsuarioScreenState();
}

class _BienvenidaUsuarioScreenState extends State<BienvenidaUsuarioScreen> {
  final Color primaryColor = const Color(0xFFBE0C0C);
  String busqueda = '';
  final TextEditingController _buscadorController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isRefreshing = false;
  bool _isConnected = true; // 🔹 estado conexión

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mostrarInvitacionDialog(context);
      _verificarEstadoAuth();
      _monitorConnectivity();
      _cargarDatosIniciales();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🔹 Verificar estado de autenticación
  Future<void> _verificarEstadoAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.cargando) {
      await authProvider.actualizarEstado();
    }
  }

  // 🔹 Cargar datos iniciales
  Future<void> _cargarDatosIniciales() async {
    final categoriaProvider =
        Provider.of<CategoriaProvider>(context, listen: false);
    final productosProvider =
        Provider.of<ProductosProvider>(context, listen: false);
    final anuncioProvider =
        Provider.of<AnuncioProvider>(context, listen: false);

    await categoriaProvider.cargarCategorias(forceRefresh: true);
    await productosProvider.cargarProductos(forceRefresh: true);
    await anuncioProvider.loadAnuncios();
  }

  // 🔹 Monitor de conexión
  void _monitorConnectivity() {
    bool? _ultimoEstado; // 🔹 Estado anterior, inicialmente null

    Connectivity().onConnectivityChanged.listen((status) async {
      final conectado = status != ConnectivityResult.none;

      // 🔹 Solo si cambió el estado
      if (_ultimoEstado != null && _ultimoEstado != conectado) {
        _mostrarFlushbarConexion(conectado);

        if (conectado) {
          // 🔹 Recargar datos solo cuando vuelve la conexión
          final categoriaProvider =
              Provider.of<CategoriaProvider>(context, listen: false);
          final productosProvider =
              Provider.of<ProductosProvider>(context, listen: false);
          final anuncioProvider =
              Provider.of<AnuncioProvider>(context, listen: false);

          // 🔹 Refrescar sin mostrar loading
          await Future.wait([
            categoriaProvider.cargarCategorias(
                forceRefresh: true, mostrarLoading: false),
            productosProvider.cargarProductos(
                forceRefresh: true, mostrarLoading: false),
            anuncioProvider.loadAnuncios(mostrarLoading: false),
          ]);
        }
      }

      _ultimoEstado = conectado; // 🔹 Actualiza el estado
      if (mounted) setState(() => _isConnected = conectado);
    });
  }

  void _mostrarFlushbarConexion(bool conectado) {
    Flushbar(
      message:
          conectado ? "✅ Conexión restablecida" : "⚠️ Sin conexión a internet",
      icon: Icon(
        conectado ? Icons.wifi : Icons.wifi_off,
        color: Colors.white,
      ),
      duration: const Duration(seconds: 3),
      backgroundColor: conectado ? Colors.green : Colors.red,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);

    try {
      await _verificarEstadoAuth();

      final categoriaProvider =
          Provider.of<CategoriaProvider>(context, listen: false);
      final productosProvider =
          Provider.of<ProductosProvider>(context, listen: false);
      final anuncioProvider =
          Provider.of<AnuncioProvider>(context, listen: false);

      // 🔹 Refrescar anuncios + categorías + productos
      await Future.wait([
        categoriaProvider.cargarCategorias(
            forceRefresh: true, mostrarLoading: false),
        productosProvider.cargarProductos(
            forceRefresh: true, mostrarLoading: false), // ✅ corregido
        anuncioProvider.loadAnuncios(mostrarLoading: false),
      ]);
    } catch (e) {
      _mostrarFlushbarError("❌ Error al actualizar: $e");
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  void _mostrarFlushbarError(String mensaje) {
    Flushbar(
      message: mensaje,
      icon: const Icon(Icons.error, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: primaryColor,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

  void onBusquedaChanged(String value) {
    setState(() {
      busqueda = value;
    });
  }

  void _onBottomNavTap(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    switch (index) {
      case 0:
        break;
      case 1:
        if (authProvider.isAuthenticated) {
          Navigator.pushNamed(context, '/favorites');
        } else {
          _mostrarMensajeLogin('Favoritos');
        }
        break;
      case 2:
        Navigator.pushNamed(context, '/cart');
        break;
      case 3:
        if (authProvider.isAuthenticated) {
          Navigator.pushNamed(context, '/profile');
        } else {
          _mostrarMensajeLogin('Perfil');
        }
        break;
      case 4:
        Navigator.pushNamed(context, '/more');
        break;
    }
  }

  void _mostrarMensajeLogin(String seccion) {
    Flushbar(
      message: "🔐 Inicia sesión para acceder a $seccion",
      icon: const Icon(Icons.lock, color: Colors.white),
      duration: const Duration(seconds: 3),
      backgroundColor: primaryColor,
      margin: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      flushbarPosition: FlushbarPosition.TOP,
    ).show(context);
  }

@override
Widget build(BuildContext context) {
  final anuncioProvider = Provider.of<AnuncioProvider>(context);

  return Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: Column(
        children: [
          // 🔹 BUSCADOR FIJO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: BuscadorProductos(
              busqueda: busqueda,
              onBusquedaChanged: onBusquedaChanged,
              controller: _buscadorController,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PantallaBusqueda(),
                  ),
                );
              },
            ),
          ),

          // 🔹 CONTENIDO SCROLLEABLE
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: primaryColor,
              backgroundColor: Colors.white,
              strokeWidth: 2.5,
              displacement: 40.0,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildBannerSection(anuncioProvider),
                    CategoriasWidget(
                      onVerMas: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TodasCategoriasScreen(),
                          ),
                        );
                      },
                      onCategoriaSeleccionada: (categoriaId) {
                        final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
                        final categoria = categoriaProvider.categorias.firstWhere(
                          (cat) => cat['_id'] == categoriaId,
                          orElse: () => {'nombre': 'Categoría'},
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProductosPorCategoriaScreen(
                              categoriaId: categoriaId,
                              categoriaNombre: categoria['nombre'] ?? 'Categoría',
                            ),
                          ),
                        );
                      },
                    ),
                    _buildHomeContent(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    bottomNavigationBar: CustomBottomNavigationBar(
     
      onTap: (index) {
        _onBottomNavTap(index); // mantiene tu lógica de navegación
      },
    ),
  );
}



  /// 🔹 Contenido del HomeScreen sin Scaffold para evitar conflictos
  Widget _buildHomeContent() {
    return Container(
      color: const Color(0xFFFAFAFB),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          // 🔹 Sección "Te puede interesar" - Mostrar según estado del provider
          Consumer<ProductosProvider>(
            builder: (context, productosProvider, child) {
              // 🔹 Si hay productos, mostrarlos siempre
              if (productosProvider.productos.isNotEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Te puede interesar",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const ProductosHorizontalesWidget(),
                  ],
                );
              }
               
              // 🔹 Si está cargando y no hay productos, mostrar shimmer
              if (productosProvider.isLoading) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "Te puede interesar",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (context, index) => Container(
                          width: 150,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          color: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ],
                );
              }
               
              // 🔹 Si hay error y no hay productos
              if (productosProvider.error != null &&
                  productosProvider.productos.isEmpty) {
                return Center(
                  child: Text(
                    "❌ Error al cargar productos",
                    style: TextStyle(color: Colors.red.shade600),
                  ),
                );
              }
               
              // 🔹 Default: no mostrar nada
              return const SizedBox.shrink();
            },
          ),
           
          const SizedBox(height: 16),
           
          // 🔹 Lista de productos con scroll infinito (sin título)
          const ListaProductosWidget(),
        ],
      ),
    );
  }
  Widget _buildBannerSection(AnuncioProvider anuncioProvider) {
    switch (anuncioProvider.state) {
      case AnuncioState.loading:
        return Container(
          height: 180,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        );

      case AnuncioState.error:
        return Column(
          children: [
            Container(
              height: 180,
              alignment: Alignment.center,
              color: Colors.grey.shade200,
              child: const Text(
                "❌ Error al cargar anuncios",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            TextButton.icon(
              onPressed: () => anuncioProvider.loadAnuncios(),
              icon: const Icon(Icons.refresh, color: Colors.red),
              label: const Text("Reintentar"),
            ),
          ],
        );

      case AnuncioState.empty:
        return const SizedBox.shrink(); // 🔹 No muestra nada

      case AnuncioState.loaded:
        return const BannerCarousel();
    }
  }
}