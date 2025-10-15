import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:another_flushbar/flushbar.dart';

import '../../widgets/banner_carousel.dart';
import '../../widgets/buscador.dart';
import '../../widgets/pantalla_busqueda.dart';
import '../../widgets/CategoriasWidget.dart';
import '../../widgets/ProductosHorizontalesWidget.dart';
import '../../widgets/ListaProductosWidget.dart';
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
  bool _isConnected = true;
  bool _hasLoadedData = false;
  bool _showNoConnectionScreen = false;
  bool _hasCheckedInitialConnection = false;
  bool _isDoingRefresh = false;
  bool _hasShownInvitationDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasCheckedInitialConnection) {
        _checkInitialConnection();
      }
    });
  }

  @override
  void dispose() {
    _unfocusSearchField();
    _buscadorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialConnection() async {
    if (_hasCheckedInitialConnection) return;
    _hasCheckedInitialConnection = true;

    print("🔍 Verificando conexión inicial...");
    
    final connectivityResult = await Connectivity().checkConnectivity();
    final isConnected = connectivityResult != ConnectivityResult.none;
    
    print("📶 Conexión inicial: $isConnected");
    
    setState(() {
      _isConnected = isConnected;
    });

    if (!isConnected) {
      final hasCache = await _checkCacheData();
      
      if (!hasCache) {
        print("🚫 Sin conexión y sin caché - Mostrando pantalla sin conexión");
        setState(() {
          _showNoConnectionScreen = true;
        });
        _monitorConnectivity();
        return;
      } else {
        print("📱 Sin conexión pero con caché - Mostrando datos disponibles");
        setState(() {
          _showNoConnectionScreen = false;
        });
      }
    } else {
      print("✅ Con conexión - Cargando datos normalmente");
      setState(() {
        _showNoConnectionScreen = false;
      });
      
      if (!_hasShownInvitationDialog && mounted) {
        _hasShownInvitationDialog = true;
        mostrarInvitacionDialog(context);
      }
      
      await _verificarEstadoAuth();
      await _cargarDatosIniciales();
    }
    
    _monitorConnectivity();
  }

  Future<bool> _checkCacheData() async {
    try {
      final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
      final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
      final anuncioProvider = Provider.of<AnuncioProvider>(context, listen: false);
      
      final hasCategorias = categoriaProvider.categorias.isNotEmpty;
      final hasProductos = productosProvider.productos.isNotEmpty;
      final hasAnuncios = anuncioProvider.anuncios.isNotEmpty;
      
      print("📦 Estado del caché - Categorías: $hasCategorias, Productos: $hasProductos, Anuncios: $hasAnuncios");
      
      return hasCategorias || hasProductos || hasAnuncios;
    } catch (e) {
      print("❌ Error verificando caché: $e");
      return false;
    }
  }

  Future<bool> _checkRealInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print("❌ Sin conectividad según connectivity_plus");
        return false;
      }
      
      print("🔍 Verificando conexión real con petición de prueba...");
      
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 5);
        
        final request = await client.getUrl(Uri.parse('https://www.google.com'));
        final response = await request.close();
        client.close();
        
        if (response.statusCode == 200) {
          print("✅ Petición de prueba exitosa - Internet funcional");
          return true;
        } else {
          print("❌ Petición de prueba falló - Status: ${response.statusCode}");
          return false;
        }
      } catch (e) {
        print("❌ Petición de prueba falló: $e");
        
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('failed host lookup') ||
            errorStr.contains('network unreachable') ||
            errorStr.contains('connection failed') ||
            errorStr.contains('timeout') ||
            errorStr.contains('no route to host')) {
          return false;
        }
        
        return true;
      }
    } catch (e) {
      print("❌ Error verificando conexión real: $e");
      return false;
    }
  }

  void _unfocusSearchField() {
    if (FocusScope.of(context).hasFocus) {
      FocusScope.of(context).unfocus();
    }
    if (_buscadorController.text.isNotEmpty) {
      _buscadorController.selection = TextSelection.collapsed(
        offset: _buscadorController.text.length
      );
    }
  }

  Future<void> _verificarEstadoAuth() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (!authProvider.cargando) {
        await authProvider.actualizarEstado();
      }
    } catch (e) {
      print("❌ Error verificando auth: $e");
    }
  }

  Future<void> _cargarDatosIniciales() async {
    try {
      final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
      final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
      final anuncioProvider = Provider.of<AnuncioProvider>(context, listen: false);

      final bool hayCategorias = categoriaProvider.categorias.isNotEmpty;
      final bool hayProductos = productosProvider.productos.isNotEmpty;
      final bool hayAnuncios = anuncioProvider.anuncios.isNotEmpty;

      final List<Future> loadingTasks = [];

      if (!hayCategorias && !categoriaProvider.isLoading) {
        loadingTasks.add(categoriaProvider.cargarCategorias(forceRefresh: false));
      }

      if (!hayProductos && !productosProvider.isLoading) {
        loadingTasks.add(productosProvider.cargarProductos(forceRefresh: false));
      }

      if (anuncioProvider.state != AnuncioState.loaded || 
          (!hayAnuncios && anuncioProvider.state != AnuncioState.loading)) {
        loadingTasks.add(anuncioProvider.loadAnuncios());
      }

      if (loadingTasks.isNotEmpty) {
        await Future.wait(loadingTasks);
      }

      _hasLoadedData = true;
      print("✅ Datos iniciales cargados");
    } catch (e) {
      print("❌ Error cargando datos iniciales: $e");
    }
  }

  void _monitorConnectivity() {
    bool? _ultimoEstado;

    Connectivity().onConnectivityChanged.listen((status) async {
      final conectado = status != ConnectivityResult.none;
      print("📡 Cambio de conectividad: $_ultimoEstado -> $conectado");

      if (_showNoConnectionScreen && conectado && (_ultimoEstado == false || _ultimoEstado == null)) {
        print("🔄 Saliendo de pantalla sin conexión...");
        setState(() {
          _showNoConnectionScreen = false;
          _isDoingRefresh = true;
        });
        
        if (!_hasShownInvitationDialog && mounted) {
          _hasShownInvitationDialog = true;
          mostrarInvitacionDialog(context);
        }
        
        await _verificarEstadoAuth();
        await _cargarDatosIniciales();
        _mostrarFlushbarConexion(true);
        
        setState(() {
          _isDoingRefresh = false;
        });
      }
      else if (_ultimoEstado != null && _ultimoEstado != conectado && !_showNoConnectionScreen) {
        _mostrarFlushbarConexion(conectado);

        if (conectado && _hasLoadedData) {
          print("🔄 Recargando datos tras recuperar conexión...");
          
          setState(() {
            _isDoingRefresh = true;
          });
          
          try {
            final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
            final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
            final anuncioProvider = Provider.of<AnuncioProvider>(context, listen: false);

            await Future.wait([
              categoriaProvider.cargarCategorias(forceRefresh: true, mostrarLoading: false),
              productosProvider.cargarProductos(forceRefresh: true, mostrarLoading: false),
              anuncioProvider.loadAnuncios(mostrarLoading: false)
            ]);
          } catch (e) {
            print("❌ Error recargando datos: $e");
          } finally {
            setState(() {
              _isDoingRefresh = false;
            });
          }
        }
      }

      _ultimoEstado = conectado;
      if (mounted) {
        setState(() => _isConnected = conectado);
      }
    });
  }

  void _mostrarFlushbarConexion(bool conectado) {
    if (!mounted) return;
    
    Flushbar(
      message: conectado ? "✅ Conexión restablecida" : "⚠️ Sin conexión a internet",
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
    
    print("🔄 Pull-to-refresh iniciado");
    
    setState(() {
      _isDoingRefresh = true;
    });
    
    if (_showNoConnectionScreen) {
      print("📱 Verificando conexión desde pantalla sin conexión...");
      final hasRealConnection = await _checkRealInternetConnection();
      
      if (hasRealConnection) {
        print("✅ Conexión real detectada, cargando datos...");
        setState(() {
          _isConnected = true;
          _showNoConnectionScreen = false;
        });
        
        await _verificarEstadoAuth();
        await _cargarDatosIniciales();
        
        setState(() {
          _isDoingRefresh = false;
        });
        return;
      } else {
        print("❌ Aún sin conexión real");
        _mostrarFlushbarConexion(false);
        
        setState(() {
          _isDoingRefresh = false;
        });
        return;
      }
    }
    
    print("🔄 Verificando conexión real antes del refresh...");
    final hasRealConnection = await _checkRealInternetConnection();
    
    if (!hasRealConnection) {
      print("❌ Sin conexión real durante refresh");
      setState(() {
        _isConnected = false;
        _isDoingRefresh = false;
      });
      _mostrarFlushbarConexion(false);
      return;
    }
    
    setState(() => _isRefreshing = true);

    try {
      print("🔄 Ejecutando refresh normal...");
      await _verificarEstadoAuth();

      final categoriaProvider = Provider.of<CategoriaProvider>(context, listen: false);
      final productosProvider = Provider.of<ProductosProvider>(context, listen: false);
      final anuncioProvider = Provider.of<AnuncioProvider>(context, listen: false);

      await Future.wait([
        categoriaProvider.cargarCategorias(forceRefresh: true, mostrarLoading: false),
        productosProvider.cargarProductos(forceRefresh: true, mostrarLoading: false),
        anuncioProvider.loadAnuncios(mostrarLoading: false)
      ]);
      
      print("✅ Refresh completado");
    } catch (e) {
      print("❌ Error en refresh: $e");
      
      if (_isErrorDeConexion(e.toString())) {
        setState(() {
          _isConnected = false;
        });
        _mostrarFlushbarConexion(false);
      } else {
        _mostrarFlushbarError("❌ Error al actualizar");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isDoingRefresh = false;
        });
      }
    }
  }

  void _mostrarFlushbarError(String mensaje) {
    if (!mounted) return;
    
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

  void _navegarAPantallaBusqueda() async {
    _unfocusSearchField();
    
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PantallaBusqueda(),
      ),
    );
    
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _unfocusSearchField();
      });
    }
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
    if (!mounted) return;
    
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

  Widget _buildNoConnectionScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Row(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Icon(Icons.search, color: Colors.grey, size: 20),
                    ),
                    Expanded(
                      child: Text(
                        "Buscar productos...",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                color: primaryColor,
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off_rounded,
                            size: 100,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 32),
                          
                          Text(
                            "Sin conexión a internet",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              "Revisa tu conexión y desliza hacia abajo para intentar nuevamente",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        onTap: _onBottomNavTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showNoConnectionScreen) {
      return _buildNoConnectionScreen();
    }

    final anuncioProvider = Provider.of<AnuncioProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: BuscadorProductos(
                busqueda: busqueda,
                onBusquedaChanged: onBusquedaChanged,
                controller: _buscadorController,
                onTap: _navegarAPantallaBusqueda,
              ),
            ),

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
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildHomeContent() {
    if (_showNoConnectionScreen) {
      return const SizedBox.shrink();
    }

    return Container(
      color: const Color(0xFFFAFAFB),
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          
          Consumer<ProductosProvider>(
            builder: (context, productosProvider, child) {
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
               
              if (productosProvider.isLoading && _isConnected && !_showNoConnectionScreen) {
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
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }
               
              if (productosProvider.error != null &&
                  productosProvider.productos.isEmpty &&
                  _isConnected && 
                  !_showNoConnectionScreen &&
                  !_isErrorDeConexion(productosProvider.error.toString())) {
                return Center(
                  child: Column(
                    children: [
                      Text(
                        "❌ Error al cargar productos",
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => productosProvider.cargarProductos(forceRefresh: true),
                        icon: const Icon(Icons.refresh, color: Colors.red),
                        label: const Text("Reintentar", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              }
               
              return const SizedBox.shrink();
            },
          ),
           
          const SizedBox(height: 16),
          
          const ListaProductosWidget(),
        ],
      ),
    );
  }

  bool _isErrorDeConexion(String error) {
    final errorLower = error.toLowerCase();
    return errorLower.contains('conexión') ||
           errorLower.contains('connection') ||
           errorLower.contains('internet') ||
           errorLower.contains('network') ||
           errorLower.contains('timeout') ||
           errorLower.contains('unreachable') ||
           errorLower.contains('failed host lookup');
  }

  Widget _buildBannerSection(AnuncioProvider anuncioProvider) {
    if (_showNoConnectionScreen) {
      return const SizedBox.shrink();
    }

    if (anuncioProvider.anuncios.isNotEmpty) {
      return const BannerCarousel();
    }

    return const SizedBox.shrink();
  }
}