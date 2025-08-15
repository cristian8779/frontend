import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/banner_carousel.dart';
import '../../widgets/buscador.dart';
import 'package:crud/utils/invitacion_dialog.dart'; // ✅ Ruta correcta
import '../../providers/auth_provider.dart'; // ✅ Import del AuthProvider

class BienvenidaUsuarioScreen extends StatefulWidget {
  const BienvenidaUsuarioScreen({super.key});

  @override
  State<BienvenidaUsuarioScreen> createState() => _BienvenidaUsuarioScreenState();
}

class _BienvenidaUsuarioScreenState extends State<BienvenidaUsuarioScreen> {
  final Color primaryColor = const Color(0xFFBE0C0C);
  String busqueda = '';

  @override
  void initState() {
    super.initState();
    // 🔹 Llamar a la verificación de invitación después de que la pantalla se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      mostrarInvitacionDialog(context);
    });
  }

  void onBusquedaChanged(String value) {
    setState(() {
      busqueda = value;
    });
  }

  void onTapBuscador() {
    print('Buscador tocado');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔹 Buscador
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: BuscadorProductos(
                busqueda: busqueda,
                onBusquedaChanged: onBusquedaChanged,
                onTap: onTapBuscador,
              ),
            ),
            // 🔹 Banner de imágenes
            const BannerCarousel(),

            // 🔹 Botón cerrar sesión
            Padding(
              padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
              child: ElevatedButton.icon(
                onPressed: () async {
                  await authProvider.cerrarSesion();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text(
                  "Cerrar sesión",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),

            // 🔹 Contenido central
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.shopping_bag_rounded, size: 100, color: primaryColor),
                      const SizedBox(height: 20),
                      const Text(
                        'Explora nuestros productos',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 Barra inferior
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: const Border(top: BorderSide(color: Colors.black12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.home_outlined, color: Colors.black54),
                  Icon(Icons.person_outline, color: Colors.black54),
                  Icon(Icons.shopping_cart_outlined, color: Colors.black54),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
