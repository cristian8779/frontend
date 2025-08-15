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

  @override
  Widget build(BuildContext context) {
    if (!_isAllowedRole(widget.rol)) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        body: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(horizontal: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline,
                    size: 96,
                    color: Colors.deepOrange.shade400,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Acceso Restringido",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "No tienes permisos para ingresar a esta sección.\nSi crees que esto es un error, contacta al administrador.",
                    style: TextStyle(
                      fontSize: 18,
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
                      label: const Text(
                        "Volver al Inicio",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 14),
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TopIcons(rol: rol, showNotificationIcon: false),
          BannerWidget(media: media),
          const SizedBox(height: 12),
          const Text(
            "Categorías",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                children: const [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.blueGrey,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No se encontraron categorías.\n¡Puedes crear nuevas desde el Panel de Administración!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.black54),
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
            const Text(
              "Panel de Administración",
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            LayoutBuilder(
              builder: (context, constraints) {
                int crossAxisCount = constraints.maxWidth < 600 ? 1 : 2;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3,
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
            Image.asset(imagePath, width: 60, height: 60, fit: BoxFit.contain),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
