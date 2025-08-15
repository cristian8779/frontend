import 'package:flutter/material.dart';

import '../../services/categoria_service.dart';
import 'widgets/categoria_list.dart';
import 'widgets/banner.dart';
import 'widgets/error_message.dart';
import 'widgets/top_icons.dart';
import 'widgets/categoria_skeleton.dart';

class ControlPanelScreen extends StatefulWidget {
  final String rol;

  const ControlPanelScreen({super.key, this.rol = "admin"});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> {
  late final CategoriaService _categoriaService;
  List<Map<String, dynamic>> _categorias = [];
  String _errorMessage = "";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _categoriaService = CategoriaService();
    _cargarCategorias();
  }

  bool _isAllowedRole(String rol) {
    return rol == 'admin' || rol == 'superAdmin';
  }

  Future<void> _cargarCategorias() async {
    setState(() {
      _isLoading = true;
      _errorMessage = "";
    });

    try {
      final categorias = await _categoriaService.obtenerCategorias();
      setState(() {
        _categorias = categorias;
      });
    } catch (error) {
      setState(() {
        _errorMessage = _mapErrorMessage(error.toString());
        _categorias = [];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapErrorMessage(String error) {
    if (error.contains('SocketException')) {
      return "❌ Error de conexión: No hay Internet.";
    } else if (error.contains('Token expirado')) {
      return "❌ Token expirado: Por favor, inicia sesión nuevamente.";
    }
    return "❌ Error inesperado.";
  }

  // Función para obtener dimensiones responsivas del error screen
  Map<String, double> _getErrorScreenDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'iconSize': 120.0,
        'titleFontSize': 32.0,
        'bodyFontSize': 20.0,
        'buttonFontSize': 20.0,
        'horizontalMargin': 120.0,
        'verticalPadding': 48.0,
        'horizontalPadding': 40.0,
        'buttonPadding': 20.0,
      };
    } else if (isTablet) {
      return {
        'iconSize': 108.0,
        'titleFontSize': 28.0,
        'bodyFontSize': 19.0,
        'buttonFontSize': 19.0,
        'horizontalMargin': 80.0,
        'verticalPadding': 42.0,
        'horizontalPadding': 32.0,
        'buttonPadding': 18.0,
      };
    } else {
      return {
        'iconSize': 96.0,
        'titleFontSize': 26.0,
        'bodyFontSize': 18.0,
        'buttonFontSize': 18.0,
        'horizontalMargin': 32.0,
        'verticalPadding': 36.0,
        'horizontalPadding': 24.0,
        'buttonPadding': 14.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowedRole(widget.rol)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final dimensions = _getErrorScreenDimensions(context);
          
          return Scaffold(
            backgroundColor: Colors.grey[100],
            body: Center(
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: EdgeInsets.symmetric(horizontal: dimensions['horizontalMargin']!),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: dimensions['verticalPadding']!,
                    horizontal: dimensions['horizontalPadding']!,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: dimensions['iconSize']!,
                        color: Colors.deepOrange.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Acceso Restringido",
                        style: TextStyle(
                          fontSize: dimensions['titleFontSize']!,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No tienes permisos para ingresar a esta sección.\nSi crees que esto es un error, contacta al administrador.",
                        style: TextStyle(
                          fontSize: dimensions['bodyFontSize']!,
                          color: Colors.grey.shade800,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/bienvenida-usuario'),
                          icon: const Icon(Icons.home_outlined, size: 24),
                          label: Text(
                            "Volver al Inicio",
                            style: TextStyle(
                              fontSize: dimensions['buttonFontSize']!,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.shade400,
                            padding: EdgeInsets.symmetric(vertical: dimensions['buttonPadding']!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargarCategorias,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: _ContenidoFijo(
              rol: widget.rol,
              categorias: _categorias,
              isLoading: _isLoading,
              errorMessage: _errorMessage,
              onCategoriasActualizadas: _cargarCategorias, // callback
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoFijo extends StatelessWidget {
  final String rol;
  final List<Map<String, dynamic>> categorias;
  final bool isLoading;
  final String errorMessage;
  final VoidCallback onCategoriasActualizadas;

  const _ContenidoFijo({
    required this.rol,
    required this.categorias,
    required this.isLoading,
    required this.errorMessage,
    required this.onCategoriasActualizadas,
  });

  // Función para obtener dimensiones responsivas del contenido principal
  Map<String, double> _getContentDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'padding': 32.0,
        'titleFontSize': 28.0,
        'adminTitleFontSize': 29.0,
        'emptyIconSize': 56.0,
        'emptyFontSize': 18.0,
        'maxWidth': 1200.0,
      };
    } else if (isTablet) {
      return {
        'padding': 24.0,
        'titleFontSize': 26.0,
        'adminTitleFontSize': 27.0,
        'emptyIconSize': 52.0,
        'emptyFontSize': 17.0,
        'maxWidth': 800.0,
      };
    } else {
      return {
        'padding': 20.0,
        'titleFontSize': 24.0,
        'adminTitleFontSize': 25.0,
        'emptyIconSize': 48.0,
        'emptyFontSize': 16.0,
        'maxWidth': double.infinity,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final dimensions = _getContentDimensions(context);
        
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: dimensions['maxWidth']!),
            child: Padding(
              padding: EdgeInsets.all(dimensions['padding']!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopIcons(rol: rol, showNotificationIcon: false),
                  BannerWidget(media: media),
                  const SizedBox(height: 12),
                  Text(
                    "Categorías",
                    style: TextStyle(
                      fontSize: dimensions['titleFontSize']!,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isLoading)
                    const CategoriaSkeleton()
                  else if (errorMessage.isNotEmpty)
                    ErrorMessage(message: errorMessage)
                  else if (categorias.isEmpty)
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.category_outlined,
                            size: dimensions['emptyIconSize']!,
                            color: Colors.blueGrey,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'No se encontraron categorías.\n¡Puedes crear nuevas desde el Panel de Administración!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dimensions['emptyFontSize']!,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    CategoriaList(
                      categorias: categorias,
                      onCategoriasActualizadas: onCategoriasActualizadas,
                    ),
                  const SizedBox(height: 2),

                  if (rol == 'admin' || rol == 'superAdmin') ...[
                    Text(
                      "Panel de Administración",
                      style: TextStyle(
                        fontSize: dimensions['adminTitleFontSize']!,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        int crossAxisCount;
                        double childAspectRatio;
                        
                        if (gridConstraints.maxWidth >= 1200) {
                          crossAxisCount = 3;
                          childAspectRatio = 3.2;
                        } else if (gridConstraints.maxWidth >= 768) {
                          crossAxisCount = 2;
                          childAspectRatio = 3.0;
                        } else if (gridConstraints.maxWidth >= 600) {
                          crossAxisCount = 2;
                          childAspectRatio = 2.8;
                        } else {
                          crossAxisCount = 1;
                          childAspectRatio = 3.5;
                        }
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: childAspectRatio,
                          children: [
                            _AdminCard(
                              title: 'Gestión de Productos',
                              imagePath: 'assets/producto.png',
                              backgroundColor: Colors.blue.shade50,
                              routeName: '/gestion-productos',
                            ),
                            _AdminCard(
                              title: 'Gestión de Ventas',
                              imagePath: 'assets/venta.png',
                              backgroundColor: Colors.green.shade50,
                              routeName: '/gestion-ventas',
                            ),
                            _AdminCard(
                              title: 'Gestión de Anuncios',
                              imagePath: 'assets/anuncio.png',
                              backgroundColor: Colors.orange.shade50,
                              routeName: '/anuncios-activos',
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AdminCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final Color backgroundColor;
  final String routeName;

  const _AdminCard({
    required this.imagePath,
    required this.title,
    required this.backgroundColor,
    required this.routeName,
  });

  // Función para obtener dimensiones responsivas de las tarjetas admin
  Map<String, double> _getCardDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'horizontalPadding': 24.0,
        'verticalPadding': 24.0,
        'imageSize': 70.0,
        'spacing': 24.0,
        'fontSize': 22.0,
        'iconSize': 20.0,
      };
    } else if (isTablet) {
      return {
        'horizontalPadding': 22.0,
        'verticalPadding': 22.0,
        'imageSize': 65.0,
        'spacing': 22.0,
        'fontSize': 21.0,
        'iconSize': 18.0,
      };
    } else {
      return {
        'horizontalPadding': 20.0,
        'verticalPadding': 20.0,
        'imageSize': 60.0,
        'spacing': 20.0,
        'fontSize': 20.0,
        'iconSize': 16.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _getCardDimensions(context);
        
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, routeName),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: dimensions['horizontalPadding']!,
              vertical: dimensions['verticalPadding']!,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Image.asset(
                  imagePath,
                  width: dimensions['imageSize']!,
                  height: dimensions['imageSize']!,
                  fit: BoxFit.contain,
                ),
                SizedBox(width: dimensions['spacing']!),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: dimensions['fontSize']!,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey,
                  size: dimensions['iconSize']!,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}