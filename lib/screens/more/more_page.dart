// screens/more/more_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/PerfilService.dart';
import '../usuario/todas_categorias_screen.dart';
import '../../widgets/pantalla_busqueda.dart';
import '../auth/PrivacyPolicy_lectura.dart';
import '../../theme/more/more_styles.dart';
import '../../theme/more/more_widgets.dart';
import '../../providers/FavoritoProvider.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  final PerfilService _perfilService = PerfilService();
  Map<String, dynamic>? _perfilData;
  bool _isLoadingPerfil = false;
  bool _hasConnectionError = false;

  @override
  void initState() {
    super.initState();
    _cargarPerfilUsuario();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authProvider = Provider.of<AuthProvider>(context);
    if (!authProvider.isAuthenticated && _perfilData != null) {
      setState(() {
        _perfilData = null;
        _isLoadingPerfil = false;
        _hasConnectionError = false;
      });
    } else if (authProvider.isAuthenticated && _perfilData == null && !_hasConnectionError) {
      _cargarPerfilUsuario();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Método para detectar si el error es de conexión
  bool _isConnectionError(dynamic error) {
    String errorString = error.toString().toLowerCase();
    
    return errorString.contains('socketexception') ||
           errorString.contains('network') ||
           errorString.contains('connection') ||
           errorString.contains('timeout') ||
           errorString.contains('host lookup failed') ||
           errorString.contains('no internet') ||
           errorString.contains('unreachable') ||
           errorString.contains('handshake') ||
           errorString.contains('failed host lookup') ||
           error.runtimeType.toString().contains('SocketException');
  }

  Future<void> _cargarPerfilUsuario() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (!authProvider.isAuthenticated) return;

    setState(() {
      _isLoadingPerfil = true;
      _hasConnectionError = false;
    });

    try {
      final perfil = await _perfilService.obtenerPerfil();
      
      if (mounted) {
        setState(() {
          _perfilData = perfil;
          _isLoadingPerfil = false;
          _hasConnectionError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPerfil = false;
          // Usar detección específica de errores de conexión
          _hasConnectionError = _isConnectionError(e);
        });
        
        // Debug: imprimir el error para ver qué tipo es
        print('Error en _cargarPerfilUsuario: $e');
        print('Tipo de error: ${e.runtimeType}');
      }
    }
  }

  void _mostrarOpcionesPerfil() {
    if (_hasConnectionError) {
      _mostrarOpcionesConexion();
      return;
    }

    MoreWidgets.showOptionsBottomSheet(
      context: context,
      title: 'Opciones de perfil',
      options: [
        BottomSheetOption(
          icon: Icons.edit_outlined,
          title: 'Editar perfil',
          onTap: () {
            Navigator.pop(context);
            _navegarEditarPerfil();
          },
        ),
      ],
    );
  }

  void _mostrarOpcionesConexion() {
    MoreWidgets.showOptionsBottomSheet(
      context: context,
      title: 'Sin conexión',
      options: [
        BottomSheetOption(
          icon: Icons.refresh_outlined,
          title: 'Reintentar conexión',
          onTap: () {
            Navigator.pop(context);
            _cargarPerfilUsuario();
          },
        ),
        BottomSheetOption(
          icon: Icons.wifi_outlined,
          title: 'Verificar conexión',
          onTap: () {
            Navigator.pop(context);
            _mostrarConsejosConexion();
          },
        ),
      ],
    );
  }

  void _mostrarConsejosConexion() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.orange),
            SizedBox(width: 8),
            Text('Sin conexión'),
          ],
        ),
        content: const Text(
          'Verifica tu conexión a internet:\n\n'
          '• Revisa tu WiFi o datos móviles\n'
          '• Intenta abrir otra aplicación\n'
          '• Reinicia tu conexión si es necesario',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _cargarPerfilUsuario();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _navegarEditarPerfil() {
    if (_hasConnectionError) {
      _mostrarMensajeConexionSutil();
      return;
    }

    Navigator.pushNamed(
      context, 
      '/profile',
      arguments: _perfilData,
    ).then((_) {
      _cargarPerfilUsuario();
    });
  }

  void _mostrarMensajeConexionSutil() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Text('Sin conexión. Verifica tu internet.'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: _cargarPerfilUsuario,
        ),
      ),
    );
  }

  void _navegarTerminosCondiciones() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );
  }

  void _mostrarOpcionesImagen() {
    if (_hasConnectionError) {
      _mostrarMensajeConexionSutil();
      return;
    }

    List<BottomSheetOption> options = [
      BottomSheetOption(
        icon: Icons.camera_alt_outlined,
        title: 'Tomar foto',
        onTap: () {
          Navigator.pop(context);
          _tomarFoto();
        },
      ),
      BottomSheetOption(
        icon: Icons.photo_library_outlined,
        title: 'Seleccionar de galería',
        onTap: () {
          Navigator.pop(context);
          _seleccionarDeGaleria();
        },
      ),
    ];

    if (_perfilData?['imagenPerfil'] != null) {
      options.add(
        BottomSheetOption(
          icon: Icons.delete_outline,
          title: 'Eliminar foto actual',
          isDestructive: true,
          onTap: () {
            Navigator.pop(context);
            _eliminarImagenPerfil();
          },
        ),
      );
    }

    MoreWidgets.showOptionsBottomSheet(
      context: context,
      title: 'Foto de perfil',
      options: options,
    );
  }

  void _tomarFoto() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de cámara pendiente de implementar')),
    );
  }

  void _seleccionarDeGaleria() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Función de galería pendiente de implementar')),
    );
  }

  Future<void> _eliminarImagenPerfil() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar foto'),
        content: const Text('¿Estás seguro de que quieres eliminar tu foto de perfil?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      MoreWidgets.showLoadingDialog(context, 'Eliminando imagen...');
      
      final success = await _perfilService.eliminarImagenPerfil();
      
      if (mounted) {
        Navigator.pop(context);
        
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Imagen eliminada correctamente'),
              backgroundColor: MoreStyles.successColor,
            ),
          );
          _cargarPerfilUsuario();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_perfilService.message ?? 'Error al eliminar imagen'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<MenuItem> _getNavigationItems() {
    return [
      MenuItem(
        icon: Icons.home_outlined,
        title: "Inicio",
        subtitle: "Volver a la página principal",
        onTap: () => Navigator.pushNamed(context, '/bienvenida'),
      ),
      MenuItem(
        icon: Icons.search_outlined,
        title: "Buscar",
        subtitle: "Encuentra lo que necesitas",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PantallaBusqueda(),
            ),
          );
        },
      ),
      MenuItem(
        icon: Icons.category_outlined,
        title: "Categorías",
        subtitle: "Explora todas las categorías",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TodasCategoriasScreen(),
            ),
          );
        },
      ),
    ];
  }

  List<MenuItem> _getAccountItems() {
    return [
      MenuItem(
        icon: Icons.person_outline,
        title: "Editar perfil",
        subtitle: _hasConnectionError ? "Sin conexión" : "Actualizar información personal",
        onTap: _hasConnectionError ? null : _navegarEditarPerfil,
        disabled: _hasConnectionError,
      ),
      MenuItem(
        icon: Icons.history_outlined,
        title: "Historial",
        subtitle: _hasConnectionError ? "Sin conexión" : "Revisa tu actividad reciente",
        onTap: _hasConnectionError ? null : () => Navigator.pushNamed(context, '/historial'),
        disabled: _hasConnectionError,
      ),
      MenuItem(
        icon: Icons.favorite_outline,
        title: "Favoritos",
        subtitle: _hasConnectionError ? "Sin conexión" : "Tus elementos guardados",
        onTap: _hasConnectionError ? null : () => Navigator.pushNamed(context, '/favorites'),
        disabled: _hasConnectionError,
      ),
    ];
  }

  List<MenuItem> _getLoginItems() {
    return [
      MenuItem(
        icon: Icons.login_outlined,
        title: "Iniciar sesión",
        subtitle: "Accede a todas las funciones",
        onTap: () => Navigator.pushNamed(context, '/login'),
        highlighted: true,
      ),
    ];
  }

List<MenuItem> _getLogoutItems() {
  return [
    MenuItem(
      icon: Icons.logout_outlined,
      title: "Cerrar sesión",
      subtitle: "Salir de tu cuenta",
      isDestructive: true,
      onTap: () async {
        setState(() {
          _perfilData = null;
          _isLoadingPerfil = false;
          _hasConnectionError = false;
        });
        
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // ✅ AGREGAR ESTA LÍNEA - Limpiar favoritos antes del logout
        final favoritoProvider = Provider.of<FavoritoProvider>(context, listen: false);
        favoritoProvider.limpiarFavoritos();
        
        await authProvider.cerrarSesion();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Sesión cerrada"),
              backgroundColor: MoreStyles.successColor,
            ),
          );
        }
      },
    ),
  ];
}

  List<MenuItem> _getInformationItems() {
    return [
      MenuItem(
        icon: Icons.description_outlined,
        title: "Términos y condiciones",
        subtitle: "Política de privacidad y términos de uso",
        onTap: _navegarTerminosCondiciones,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.isAuthenticated;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = MoreStyles.isTablet(screenWidth);
    final isDesktop = MoreStyles.isDesktop(screenWidth);

    final nombre = isLoggedIn && _perfilData != null
        ? (_perfilData!['nombre']?.toString() ?? 'Usuario')
        : (_hasConnectionError && isLoggedIn ? 'Usuario' : 'Invitado');

    // Determinar la URL de imagen con manejo de estado de conexión
    String? imagenUrl;
    if (isLoggedIn) {
      if (_hasConnectionError) {
        imagenUrl = 'connection_error'; // Valor especial para indicar error de conexión
      } else if (_perfilData != null) {
        imagenUrl = _perfilData!['imagenPerfil']?.toString();
      }
    }

    return Scaffold(
      backgroundColor: MoreStyles.backgroundColor,
      appBar: AppBar(
        title: Text(
          "Mi cuenta",
          style: MoreStyles.appBarTitleStyle(isTablet),
        ),
        backgroundColor: MoreStyles.headerColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: MoreStyles.primaryTextColor),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarPerfilUsuario,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: MoreStyles.getHorizontalPadding(screenWidth),
            ),
            child: Column(
              children: [
                // Header del usuario con nuevo parámetro hasConnectionError
                MoreWidgets.buildUserHeader(
                  context: context,
                  nombre: nombre,
                  imagenUrl: imagenUrl,
                  isLoggedIn: isLoggedIn,
                  isLoadingPerfil: _isLoadingPerfil,
                  hasConnectionError: _hasConnectionError,
                  onProfileTap: _mostrarOpcionesPerfil,
                  onLoginTap: () => Navigator.pushNamed(context, '/login'),
                ),
                
                MoreStyles.verticalSpacing(isTablet, MoreStyles.getSectionSpacing(isTablet)),

                // Layout según el dispositivo
                if (isDesktop) ...[
                  _buildDesktopLayout(isLoggedIn, isTablet),
                ] else ...[
                  _buildMobileLayout(isLoggedIn, isTablet),
                ],

                MoreStyles.verticalSpacing(isTablet, MoreStyles.getBottomSpacing(isTablet)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isLoggedIn, bool isTablet) {
    return MoreWidgets.buildDesktopLayout(
      context: context,
      leftColumnChildren: [
        MoreWidgets.buildSectionCard(
          context: context,
          title: "Navegación",
          items: _getNavigationItems(),
        ),
        MoreStyles.verticalSpacing(isTablet, 20),
        MoreWidgets.buildSectionCard(
          context: context,
          title: "Información",
          items: _getInformationItems(),
        ),
      ],
      rightColumnChildren: [
        if (!isLoggedIn) ...[
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Cuenta",
            items: _getLoginItems(),
          ),
        ] else ...[
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Mi cuenta",
            items: _getAccountItems(),
          ),
          MoreStyles.verticalSpacing(isTablet, 20),
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Sesión",
            items: _getLogoutItems(),
          ),
        ],
      ],
    );
  }

  Widget _buildMobileLayout(bool isLoggedIn, bool isTablet) {
    return Column(
      children: [
        // Navegación
        MoreWidgets.buildSectionCard(
          context: context,
          title: "Navegación",
          items: _getNavigationItems(),
        ),

        MoreStyles.verticalSpacing(isTablet, MoreStyles.getSectionSpacing(isTablet)),

        // Sección según estado de login
        if (!isLoggedIn) ...[
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Cuenta",
            items: _getLoginItems(),
          ),
        ] else ...[
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Mi cuenta",
            items: _getAccountItems(),
          ),
          
          MoreStyles.verticalSpacing(isTablet, MoreStyles.getSectionSpacing(isTablet)),
          
          MoreWidgets.buildSectionCard(
            context: context,
            title: "Sesión",
            items: _getLogoutItems(),
          ),
        ],

        MoreStyles.verticalSpacing(isTablet, MoreStyles.getSectionSpacing(isTablet)),

        // Información
        MoreWidgets.buildSectionCard(
          context: context,
          title: "Información",
          items: _getInformationItems(),
        ),
      ],
    );
  }
}