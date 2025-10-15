import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart'; // 👈 agregado para controlar la orientación
import 'package:flutter_localizations/flutter_localizations.dart'; // 👈 agregado para español
import 'package:showcaseview/showcaseview.dart'; // 👈 NUEVO: Para los tooltips del tutorial

// Providers
import 'providers/auth_provider.dart';
import 'providers/categoria_provider.dart'; // 👈 NUEVO provider agregado
import 'providers/bottom_nav_provider.dart';
import 'providers/producto_provider.dart';
import 'providers/anuncio_provider.dart';
import 'providers/producto_admin_provider.dart';
import 'providers/categoria_admin_provider.dart';
import 'providers/anuncio_admin_provider.dart';
import 'providers/variacion_admin_provider.dart';
import 'providers/FavoritoProvider.dart';
import 'providers/variacion_admin_provider.dart';
import 'providers/carrito_provider.dart';


// Widgets de búsqueda
import 'widgets/buscador.dart';
import 'widgets/pantalla_busqueda.dart';

// Splash
import 'splash/splash_wrapper.dart';

// Otras pantallas que tengas
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/new_password_screen.dart';
import 'screens/auth/verificar_codigo_screen.dart';
import 'screens/admin/bienvenida_admin_screen.dart';
import 'screens/admin/control_panel_screen.dart';
import 'screens/admin/create_category_screen.dart';
import 'screens/admin/gestion_productos_screen.dart';
import 'screens/admin/gestion_ventas_screen.dart';
import 'screens/admin/crear_producto_screen.dart';
import 'screens/admin/gestionar_variaciones_screen.dart';
import 'screens/admin/crear_variacion_screen.dart';
import 'screens/admin/editar_producto_screen.dart';
import 'screens/admin/gestion_anuncios_screen.dart';
import 'screens/admin/anuncios_screen.dart';
import 'screens/admin/pantalla_rol.dart';
import 'screens/admin/invitaciones.dart';

import 'screens/usuario/bienvenida_usuario_screen.dart';
import 'screens/usuario/favorito.dart';
import 'screens/usuario/historial/historial_screen.dart';

import 'screens/configuracion/ver_admins_page.dart';
import 'screens/producto/producto_screen.dart';
import 'screens/categoria/categoria_screen.dart';
import 'screens/cart/cart_page.dart';
import 'screens/profile/profile_page.dart';
import 'screens/bold_payment_page.dart';
import 'screens/more/more_page.dart';

// 👇 AGREGAR: RouteObserver global
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 👇 Aquí bloqueamos la orientación a vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // Solo vertical normal
    // DeviceOrientation.portraitDown, // si quieres también vertical invertido, descomenta
  ]);

  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('es_ES', null);

  runApp(const AppProviders());
}

class AppProviders extends StatelessWidget {
  const AppProviders({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CategoriaProvider()), // 👈 agregado
        ChangeNotifierProvider(create: (_) => BottomNavProvider()),
        ChangeNotifierProvider(create: (_) => ProductosProvider()),
        ChangeNotifierProvider(create: (_) => AnuncioProvider()),
        ChangeNotifierProvider(create: (_) => ProductoProvider()),
        ChangeNotifierProvider(create: (_) => CategoriasProvider()),
        ChangeNotifierProvider(create: (_) => AnunciosProvider()),
        ChangeNotifierProvider(create: (_) => VariacionProvider()),
        ChangeNotifierProvider(create: (_) => FavoritoProvider()),
        ChangeNotifierProvider(create: (_) => VariacionProvider()),
       ChangeNotifierProvider(create: (_) => CarritoProvider()),

      ],
      child: ShowCaseWidget( // 👈 NUEVO: Envuelve MyApp con ShowCaseWidget
        builder: (context) => const MyApp(),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Soportee Admin',
          theme: ThemeData(
            primarySwatch: Colors.red,
            scaffoldBackgroundColor: Colors.white,
          ),
          navigatorObservers: [routeObserver],
          home: const SplashScreenWrapper(),

          // 👇 agregado para soporte de español
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('es', 'ES'), // Español
            Locale('en', 'US'), // Inglés opcional
          ],
          locale: const Locale('es', 'ES'),

          routes: {
            '/login': (_) => const LoginScreen(),
            '/forgot': (_) => const ForgotPasswordScreen(),
            '/bienvenida-usuario': (_) => const BienvenidaUsuarioScreen(),
            '/ver-admins': (_) => const VerAdminsPage(),
            '/gestion-productos': (_) => const GestionProductosScreen(),
            '/gestion-ventas': (_) => const GestionVentasScreen(),
            '/gestion-anuncios': (_) => const GestionAnunciosScreen(),
            '/crear-categoria': (_) => const CreateCategoryScreen(),
            '/crear-producto': (_) => const CrearProductoScreen(),
            '/anuncios-activos': (_) => const AnunciosScreen(),
            '/pantalla-rol': (_) => const PantallaRol(),
            '/invitaciones': (_) =>
                const InvitacionRolScreen(rolActual: 'superAdmin'),

            '/bienvenida': (_) => const BienvenidaUsuarioScreen(),
            '/favorites': (_) => FavoritesPage(),
            '/cart': (_) => const CartPage(),
            '/profile': (_) => const ProfilePage(),
            '/more': (_) => const MorePage(),
            '/historial': (_) => const HistorialScreen(),
          },
          onGenerateRoute: (settings) {
            final args = settings.arguments;
            final uri = Uri.tryParse(settings.name ?? '');

            if (uri != null && uri.pathSegments.isNotEmpty) {
              switch (uri.pathSegments[0]) {
                case 'producto':
                  if (uri.pathSegments.length > 1) {
                    return MaterialPageRoute(
                      builder: (_) =>
                          ProductoScreen(productId: uri.pathSegments[1]),
                    );
                  }
                  break;
                case 'categoria':
                  if (uri.pathSegments.length > 1) {
                    return MaterialPageRoute(
                      builder: (_) =>
                          CategoriaScreen(categoriaId: uri.pathSegments[1]),
                    );
                  }
                  break;
              }
            }

            switch (settings.name) {
              case '/verificar-codigo':
                if (args is Map<String, dynamic> && args['email'] != null) {
                  return MaterialPageRoute(
                    builder: (_) => VerificarCodigoScreen(email: args['email']),
                  );
                }
                break;

              case '/new-password':
                if (args is Map<String, dynamic> &&
                    args['email'] != null &&
                    args['token'] != null) {
                  return MaterialPageRoute(
                    builder: (_) => NewPasswordScreen(
                      email: args['email'],
                      token: args['token'],
                    ),
                  );
                }
                break;

              case '/bienvenida-admin':
                if (args is Map<String, dynamic> && args['rol'] != null) {
                  return MaterialPageRoute(
                    builder: (_) => BienvenidaAdminScreen(rol: args['rol']),
                  );
                }
                break;

              case '/control-panel':
                if (args is Map<String, dynamic> && args['rol'] != null) {
                  return MaterialPageRoute(
                    builder: (_) => ControlPanelScreen(rol: args['rol']),
                  );
                }
                break;

              case '/gestionar-variaciones':
                if (args is String) {
                  return MaterialPageRoute(
                    builder: (_) => GestionarVariacionesScreen(productId: args),
                  );
                }
                break;

              case '/crear-variacion':
                if (args is String) {
                  return MaterialPageRoute(
                    builder: (_) => CrearVariacionScreen(productId: args),
                  );
                }
                break;

              case '/editar-producto':
                if (args is String) {
                  return MaterialPageRoute(
                    builder: (_) => EditarProductoScreen(productId: args),
                  );
                }
                break;

              case '/bold-payment':
                if (args is Map<String, dynamic> &&
                    args['totalPrice'] != null &&
                    args['totalItems'] != null) {
                  final double totalPrice = (args['variationPrice'] != null)
                      ? args['variationPrice'].toDouble()
                      : args['totalPrice'].toDouble();

                  return MaterialPageRoute(
                    builder: (_) => BoldPaymentPage(
                      totalPrice: totalPrice,
                      totalItems: args['totalItems'],
                    ),
                  );
                }
                break;
            }

            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(
                  child: Text(
                    '❌ Ruta no encontrada o parámetros inválidos',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}