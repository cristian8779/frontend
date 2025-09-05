import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/buscador.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import 'package:crud/utils/invitacion_dialog.dart';
import '../../providers/auth_provider.dart';
import '../../services/producto_service.dart';
import '../../widgets/pantalla_filtros.dart';

// 👇 Importa correctamente el HomeScreen y el CategoriasWidget
import '../../widgets/CategoriasWidget.dart';
import '../home/home_screen.dart';   // 👈 agrega esta línea


class BienvenidaUsuarioScreen extends StatefulWidget {
  const BienvenidaUsuarioScreen({super.key});

  @override
  State<BienvenidaUsuarioScreen> createState() => _BienvenidaUsuarioScreenState();
}

class _BienvenidaUsuarioScreenState extends State<BienvenidaUsuarioScreen> {
  final Color primaryColor = const Color(0xFFBE0C0C);
  String busqueda = '';
  int currentBottomIndex = 0;
  final TextEditingController _buscadorController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mostrarInvitacionDialog(context);
      _verificarEstadoAuth();
    });
  }

  @override
  void dispose() {
    _buscadorController.dispose();
    super.dispose();
  }

  // Verificar estado de autenticación
  Future<void> _verificarEstadoAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.cargando) {
      await authProvider.actualizarEstado();
    }
  }

  void onBusquedaChanged(String value) {
    setState(() {
      busqueda = value;
    });
  }

  // Abrir panel de filtros en BottomSheet
  void onTapBuscador() async {
    Map<String, dynamic> filtrosDisponibles = {};
    try {
      final service = ProductoService();
      filtrosDisponibles = await service.obtenerFiltrosDisponibles();
    } catch (e) {
      debugPrint('❌ Error al obtener filtros: $e');
    }

    if (filtrosDisponibles.isNotEmpty) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => FractionallySizedBox(
          heightFactor: 0.8,
          child: FiltrosPanel(filtros: filtrosDisponibles),
        ),
      );
    }
  }

  void _onBottomNavTap(int index) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      currentBottomIndex = index;
    });

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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Inicia sesión para acceder a $seccion'),
        backgroundColor: primaryColor,
        action: SnackBarAction(
          label: 'Iniciar sesión',
          textColor: Colors.white,
          onPressed: () => Navigator.pushNamed(context, '/login'),
        ),
      ),
    );

    setState(() {
      currentBottomIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: BuscadorProductos(
                busqueda: busqueda,
                onBusquedaChanged: onBusquedaChanged,
                onTap: onTapBuscador,
                controller: _buscadorController,
              ),
            ),
            // Banner
            const BannerCarousel(),
            // 👇 Aquí metemos el HomeScreen en lugar del Center vacío
            Expanded(
              child: HomeScreen(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: currentBottomIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }
}
