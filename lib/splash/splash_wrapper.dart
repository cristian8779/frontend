import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SplashScreenWrapper extends StatefulWidget {
  const SplashScreenWrapper({super.key});

  @override
  State<SplashScreenWrapper> createState() => _SplashScreenWrapperState();
}

class _SplashScreenWrapperState extends State<SplashScreenWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();

    // Inicialización de la animación
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // ❌ Ya no se limpia el almacenamiento al iniciar

    // Espera 3 segundos antes de iniciar la verificación
    _delayTimer = Timer(const Duration(seconds: 3), () {
      _controller.stop();
      _initApp();
    });
  }

  // 🔄 Función para limpiar almacenamiento seguro (por si la necesitás en el futuro)
  Future<void> _limpiarAlmacenamiento() async {
    final storage = FlutterSecureStorage();
    await storage.deleteAll(); // Elimina todos los datos persistentes
    debugPrint("🚮 Almacenamiento limpiado");
  }

  Future<void> _initApp() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Cargar la sesión (verifica el token y el rol, si existen)
      await authProvider.cargarSesion();
      debugPrint("ROL detectado: ${authProvider.rol}");
      debugPrint("Está autenticado? ${authProvider.isAuthenticated}");

      if (!mounted) return;

      // Verificar autenticación antes de redirigir
      if (!authProvider.isAuthenticated) {
        // Si no está autenticado, redirigir a la pantalla de bienvenida del usuario
        Navigator.pushReplacementNamed(context, '/bienvenida-usuario');
        return;
      }

      final rol = authProvider.rol;

      // Si está autenticado y el rol es válido
      if (rol != null) {
        // Si el rol es admin o superAdmin, redirigir a la pantalla de bienvenida admin
        if (rol == 'admin' || rol == 'superAdmin') {
          Navigator.pushReplacementNamed(
                  context,
              '/bienvenida-admin',
             arguments: {'rol': rol},
               );        } else {
          // Si el rol es usuario, redirigir a la pantalla de bienvenida usuario
          Navigator.pushReplacementNamed(context, '/bienvenida-usuario');
        }
      } else {
        // Si el rol es null, redirigir al login
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      debugPrint('Error en SplashScreenWrapper: $e');
      // Si algo sale mal, redirigir al login
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _delayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7F0), // Fondo en color blanco pastel
      body: Center(
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Image.asset('assets/bola.png', width: 170, height: 170),
        ),
      ),
    );
  }
}