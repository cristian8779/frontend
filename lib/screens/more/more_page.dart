// screens/more/more_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../usuario/todas_categorias_screen.dart';
import '../../widgets/pantalla_busqueda.dart';


class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bool isLoggedIn = authProvider.isAuthenticated;
    
    // Obtener información de la pantalla
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          "Mi cuenta",
          style: TextStyle(
            color: Colors.black87,
            fontSize: isTablet ? 24 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xf4f1d6), 
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? screenWidth * 0.15 : (isTablet ? 24 : 0),
          ),
          child: Column(
            children: [
              // Header con información del usuario
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: EdgeInsets.all(isTablet ? 28 : 20),
                child: Row(
                  children: [
                    Container(
                      width: isTablet ? 80 : 64,
                      height: isTablet ? 80 : 64,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3483FA), // Azul MercadoLibre
                            const Color(0xFF2968C8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF3483FA).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (authProvider.nombre?.isNotEmpty ?? false)
                              ? authProvider.nombre![0].toUpperCase()
                              : "?",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 36 : 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: isTablet ? 24 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLoggedIn ? "¡Hola!" : "¡Hola!",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: isTablet ? 18 : 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          SizedBox(height: isTablet ? 6 : 4),
                          Text(
                            (authProvider.nombre?.isNotEmpty ?? false)
                                ? authProvider.nombre!
                                : "Invitado",
                            style: TextStyle(
                              fontSize: isTablet ? 26 : 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (!isLoggedIn) ...[
                            SizedBox(height: isTablet ? 12 : 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/login');
                              },
                              child: Text(
                                "Ingresá a tu cuenta",
                                style: TextStyle(
                                  color: const Color(0xFF3483FA),
                                  fontSize: isTablet ? 18 : 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: isTablet ? 20 : 12),

              // Layout responsivo para las secciones
              if (isDesktop) ...[
                // Layout de escritorio: 2 columnas
                _buildDesktopLayout(context, isLoggedIn, screenWidth),
              ] else ...[
                // Layout móvil/tablet: columna única
                _buildMobileLayout(context, isLoggedIn, isTablet),
              ],

              SizedBox(height: isTablet ? 100 : 80), // Espacio extra para mejor scroll
            ],
          ),
        ),
      ),
    );
  }

  // Layout para escritorio (2 columnas)
  Widget _buildDesktopLayout(BuildContext context, bool isLoggedIn, double screenWidth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Columna izquierda
        Expanded(
          child: Column(
            children: [
              _buildSectionCard(
                title: "Navegación",
                items: [
                  _MenuItem(
                    icon: Icons.home_outlined,
                    title: "Inicio",
                    subtitle: "Volver a la página principal",
                    onTap: () => Navigator.pushNamed(context, '/bienvenida'),
                  ),
                  _MenuItem(
                    icon: Icons.search_outlined,
                    title: "Buscar",
                    subtitle: "Encuentra lo que necesitas",
                    onTap: () => Navigator.pushNamed(context, '/search'),
                  ),
                  _MenuItem(
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
                ],
                isTablet: true,
              ),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Columna derecha
        Expanded(
          child: Column(
            children: [
              if (!isLoggedIn) ...[
                _buildSectionCard(
                  title: "Cuenta",
                  items: [
                    _MenuItem(
                      icon: Icons.login_outlined,
                      title: "Iniciar sesión",
                      subtitle: "Accede a todas las funciones",
                      onTap: () => Navigator.pushNamed(context, '/login'),
                      highlighted: true,
                    ),
                  ],
                  isTablet: true,
                ),
              ] else ...[
                _buildSectionCard(
                  title: "Mi cuenta",
                  items: [
                    _MenuItem(
                      icon: Icons.history_outlined,
                      title: "Historial",
                      subtitle: "Revisa tu actividad reciente",
                      onTap: () => Navigator.pushNamed(context, '/historial'),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_outline,
                      title: "Favoritos",
                      subtitle: "Tus elementos guardados",
                      onTap: () => Navigator.pushNamed(context, '/favorites'),
                    ),
                  ],
                  isTablet: true,
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: "Sesión",
                  items: [
                    _MenuItem(
                      icon: Icons.logout_outlined,
                      title: "Cerrar sesión",
                      subtitle: "Salir de tu cuenta",
                      onTap: () async {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        await authProvider.cerrarSesion();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Sesión cerrada"),
                              backgroundColor: const Color(0xFF00A650),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        }
                      },
                      isDestructive: true,
                    ),
                  ],
                  isTablet: true,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // Layout para móvil/tablet (columna única)
  Widget _buildMobileLayout(BuildContext context, bool isLoggedIn, bool isTablet) {
    return Column(
      children: [
        // Sección principal de navegación
        _buildSectionCard(
          title: "Navegación",
          items: [
            _MenuItem(
              icon: Icons.home_outlined,
              title: "Inicio",
              subtitle: "Volver a la página principal",
              onTap: () => Navigator.pushNamed(context, '/bienvenida'),
            ),
           _MenuItem(
             icon: Icons.search_outlined,
            title: "Buscar",
             subtitle: "Encuentra lo que necesitas",
              onTap: () {
             Navigator.push(
             context,
            MaterialPageRoute(
           builder: (context) => const PantallaBusqueda(), // 👈 aquí va tu pantalla
          ),
         );
        },
      ),

            _MenuItem(
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
          ],
          isTablet: isTablet,
        ),

        SizedBox(height: isTablet ? 20 : 12),

        // Sección según estado de login
        if (!isLoggedIn) ...[
          _buildSectionCard(
            title: "Cuenta",
            items: [
              _MenuItem(
                icon: Icons.login_outlined,
                title: "Iniciar sesión",
                subtitle: "Accede a todas las funciones",
                onTap: () => Navigator.pushNamed(context, '/login'),
                highlighted: true,
              ),
            ],
            isTablet: isTablet,
          ),
        ] else ...[
          _buildSectionCard(
            title: "Mi cuenta",
            items: [
              _MenuItem(
                icon: Icons.history_outlined,
                title: "Historial",
                subtitle: "Revisa tu actividad reciente",
                onTap: () => Navigator.pushNamed(context, '/historial'),
              ),
              _MenuItem(
                icon: Icons.favorite_outline,
                title: "Favoritos",
                subtitle: "Tus elementos guardados",
                onTap: () => Navigator.pushNamed(context, '/favorites'),
              ),
            ],
            isTablet: isTablet,
          ),
          
          SizedBox(height: isTablet ? 20 : 12),
          
          _buildSectionCard(
            title: "Sesión",
            items: [
              _MenuItem(
                icon: Icons.logout_outlined,
                title: "Cerrar sesión",
                subtitle: "Salir de tu cuenta",
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.cerrarSesion();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text("Sesión cerrada"),
                        backgroundColor: const Color(0xFF00A650), // Verde MercadoLibre
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    );
                  }
                },
                isDestructive: true,
              ),
            ],
            isTablet: isTablet,
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required List<_MenuItem> items,
    bool isTablet = false,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 0 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: isTablet ? 12 : 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              isTablet ? 24 : 16,
              isTablet ? 24 : 16,
              isTablet ? 24 : 16,
              isTablet ? 12 : 8,
            ),
            child: Text(
              title,
              style: TextStyle(
                fontSize: isTablet ? 20 : 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          ...items.map((item) => _buildMenuItem(item, isTablet)).toList(),
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItem item, [bool isTablet = false]) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        child: Container(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Row(
            children: [
              Container(
                width: isTablet ? 56 : 40,
                height: isTablet ? 56 : 40,
                decoration: BoxDecoration(
                  color: item.highlighted 
                      ? const Color(0xFF3483FA).withOpacity(0.1)
                      : item.isDestructive
                          ? Colors.red.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isTablet ? 28 : 20),
                ),
                child: Icon(
                  item.icon,
                  size: isTablet ? 28 : 20,
                  color: item.highlighted 
                      ? const Color(0xFF3483FA)
                      : item.isDestructive
                          ? Colors.red.shade600
                          : Colors.grey[600],
                ),
              ),
              SizedBox(width: isTablet ? 24 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: isTablet ? 20 : 16,
                        fontWeight: FontWeight.w500,
                        color: item.isDestructive 
                            ? Colors.red.shade600 
                            : Colors.black87,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      SizedBox(height: isTablet ? 4 : 2),
                      Text(
                        item.subtitle!,
                        style: TextStyle(
                          fontSize: isTablet ? 16 : 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: isTablet ? 28 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool highlighted;
  final bool isDestructive;

  _MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.highlighted = false,
    this.isDestructive = false,
  });
}