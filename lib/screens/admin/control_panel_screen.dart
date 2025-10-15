import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/categoria_admin_provider.dart';
import 'widgets/categoria_list.dart';
import 'widgets/banner.dart';
import 'widgets/error_message.dart';
import 'widgets/top_icons.dart';
import 'widgets/categoria_skeleton.dart';
import 'widgets/connection_error_widget.dart';
import 'styles/control_panel/control_panel_styles.dart';

// 👇 Importar el routeObserver
import '../../main.dart';

class ControlPanelScreen extends StatefulWidget {
  final String rol;

  const ControlPanelScreen({super.key, this.rol = "admin"});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> with RouteAware {
  // GlobalKeys para los tooltips
  final GlobalKey _categoriasKey = GlobalKey();
  final GlobalKey _configKey = GlobalKey();
  final GlobalKey _productosKey = GlobalKey();
  final GlobalKey _ventasKey = GlobalKey();
  final GlobalKey _anunciosKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // inicializamos el provider
      context.read<CategoriasProvider>().inicializar();

      // Mostrar tutorial con tooltips
      _maybeShowTutorial();
    });
  }

  void _maybeShowTutorial() async {
    if (!_isAllowedRole(widget.rol)) return;

    // Verificar si ya se mostró el tutorial usando SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final tutorialMostrado = prefs.getBool('tutorial_control_panel_mostrado') ?? false;

    if (!tutorialMostrado) {
      // Delay para asegurar que todo esté renderizado
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ShowCaseWidget.of(context).startShowCase([
            _configKey,
            _categoriasKey,
            _productosKey,
            _ventasKey,
            _anunciosKey,
          ]);
          // Guardar que el tutorial ya fue mostrado
          prefs.setBool('tutorial_control_panel_mostrado', true);
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    super.didPopNext();
    print("🔄 Regresando a ControlPanel - Recargando categorías...");
    context.read<CategoriasProvider>().refrescarSilencioso();
  }

  bool _isAllowedRole(String rol) {
    return rol == 'admin' || rol == 'superAdmin';
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAllowedRole(widget.rol)) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final dimensions = ControlPanelStyles.getErrorScreenDimensions(context);
          
          return Scaffold(
            backgroundColor: ControlPanelStyles.errorScreenBackground,
            body: Center(
              child: Card(
                elevation: ControlPanelStyles.cardElevation,
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
                        ControlPanelStyles.restrictedAccessIcon,
                        size: dimensions['iconSize']!,
                       color: Colors.red,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Acceso Restringido",
                        style: ControlPanelStyles.getRestrictedAccessTitleStyle(
                          dimensions['titleFontSize']!
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No tienes permisos para ingresar a esta sección.\nSi crees que esto es un error, contacta al administrador.",
                        style: ControlPanelStyles.getRestrictedAccessBodyStyle(
                          dimensions['bodyFontSize']!
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/bienvenida-usuario'),
                          icon: const Icon(ControlPanelStyles.homeIcon, size: 24),
                          label: Text(
                            "Volver al Inicio",
                            style: ControlPanelStyles.getRestrictedAccessButtonStyle(
                              dimensions['buttonFontSize']!
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ControlPanelStyles.restrictedAccessButton,
                            padding: EdgeInsets.symmetric(vertical: dimensions['buttonPadding']!),
                            shape: ControlPanelStyles.getButtonShape(),
                            elevation: ControlPanelStyles.buttonElevation,
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
      backgroundColor: ControlPanelStyles.backgroundColor,
      body: SafeArea(
        child: Consumer<CategoriasProvider>(
          builder: (context, categoriasProvider, child) {
            return RefreshIndicator(
              onRefresh: () => categoriasProvider.refrescarSilencioso(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: _ContenidoFijo(
                  rol: widget.rol,
                  categoriasProvider: categoriasProvider,
                  categoriasKey: _categoriasKey,
                  configKey: _configKey,
                  productosKey: _productosKey,
                  ventasKey: _ventasKey,
                  anunciosKey: _anunciosKey,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContenidoFijo extends StatelessWidget {
  final String rol;
  final CategoriasProvider categoriasProvider;
  final GlobalKey categoriasKey;
  final GlobalKey configKey;
  final GlobalKey productosKey;
  final GlobalKey ventasKey;
  final GlobalKey anunciosKey;

  const _ContenidoFijo({
    required this.rol,
    required this.categoriasProvider,
    required this.categoriasKey,
    required this.configKey,
    required this.productosKey,
    required this.ventasKey,
    required this.anunciosKey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final media = MediaQuery.of(context);
        final dimensions = ControlPanelStyles.getContentDimensions(context);
        
        return Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: dimensions['maxWidth']!),
            child: Padding(
              padding: EdgeInsets.all(dimensions['padding']!),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TopIcons(
                    rol: rol, 
                    showNotificationIcon: false,
                    configKey: configKey,
                  ),
                  BannerWidget(media: media),
                  const SizedBox(height: ControlPanelStyles.defaultSpacing),
                  
                  // 🎨 Showcase estilo Mercado Libre para Categorías
                  Showcase(
                    key: categoriasKey,
                    title: 'Gestión de Categorías',
                    titleTextStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                      letterSpacing: -0.3,
                    ),
                    description: 'Organiza tus productos de manera eficiente. Crea, edita y ordena categorías para una mejor clasificación.',
                    descTextStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF666666),
                      height: 1.4,
                      letterSpacing: 0,
                    ),
                    targetBorderRadius: BorderRadius.circular(8),
                    tooltipBackgroundColor: Colors.white,
                    overlayColor: Colors.black,
                    overlayOpacity: 0.75,
                    tooltipBorderRadius: BorderRadius.circular(12),
                    tooltipPadding: const EdgeInsets.all(24),
                    targetPadding: const EdgeInsets.all(8),
                    child: Text(
                      "Categorías",
                      style: ControlPanelStyles.getSectionTitleStyle(
                        dimensions['titleFontSize']!
                      ),
                    ),
                  ),
                  const SizedBox(height: ControlPanelStyles.smallSpacing),
                  
                  // 🎯 MANEJO DE ESTADOS CON PROVIDER MEJORADO
                  if (categoriasProvider.isLoading && categoriasProvider.categorias.isEmpty)
                    const CategoriaSkeleton()
                  else if (categoriasProvider.hasError)
                    ImprovedErrorMessage(
                      message: ControlPanelStyles.mapErrorMessage(
                        categoriasProvider.errorMessage ?? 'Error desconocido'
                      ),
                      onRetry: () => categoriasProvider.reintentar(),
                    )
                  else
                    CategoriaList(
                      categorias: categoriasProvider.categoriasFiltradas,
                      onCategoriasActualizadas: () => categoriasProvider.refrescarSilencioso(),
                    ),
                  
                  const SizedBox(height: ControlPanelStyles.tinySpacing),

                  if (rol == 'admin' || rol == 'superAdmin') ...[
                    Text(
                      "Panel de Administración",
                      style: ControlPanelStyles.getSectionTitleStyle(
                        dimensions['adminTitleFontSize']!
                      ),
                    ),
                    const SizedBox(height: ControlPanelStyles.tinySpacing),
                    LayoutBuilder(
                      builder: (context, gridConstraints) {
                        final gridConfig = ControlPanelStyles.getGridConfig(
                          gridConstraints.maxWidth
                        );
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: gridConfig['crossAxisCount'],
                          crossAxisSpacing: ControlPanelStyles.gridSpacing,
                          mainAxisSpacing: ControlPanelStyles.gridSpacing,
                          childAspectRatio: gridConfig['childAspectRatio'],
                          children: [
                            _AdminCard(
                              showcaseKey: productosKey,
                              title: 'Gestión de Productos',
                              imagePath: 'assets/producto.png',
                              backgroundColor: ControlPanelStyles.productosCardBackground,
                              routeName: '/gestion-productos',
                              tooltipTitle: 'Gestión de Productos',
                              tooltipDescription: 'Administra tu catálogo completo. Agrega nuevos productos, edita información y mantén tu inventario actualizado.',
                              accentColor: const Color(0xFF3483FA),
                            ),
                            _AdminCard(
                              showcaseKey: ventasKey,
                              title: 'Gestión de Ventas',
                              imagePath: 'assets/venta.png',
                              backgroundColor: ControlPanelStyles.ventasCardBackground,
                              routeName: '/gestion-ventas',
                              tooltipTitle: 'Gestión de Ventas',
                              tooltipDescription: 'Visualiza y controla todas tus transacciones.',
                              accentColor: const Color(0xFF00A650),
                            ),
                            _AdminCard(
                              showcaseKey: anunciosKey,
                              title: 'Gestión de Anuncios',
                              imagePath: 'assets/anuncio.png',
                              backgroundColor: ControlPanelStyles.anunciosCardBackground,
                              routeName: '/anuncios-activos',
                              tooltipTitle: 'Gestión de Anuncios',
                              tooltipDescription: 'Crea promociones y anuncios destacados. Mantén informados a tus clientes sobre ofertas especiales.',
                              accentColor: const Color(0xFFFF6C00),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: ControlPanelStyles.defaultSpacing),
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
  final GlobalKey showcaseKey;
  final String imagePath;
  final String title;
  final Color backgroundColor;
  final String routeName;
  final String tooltipTitle;
  final String tooltipDescription;
  final Color accentColor;

  const _AdminCard({
    required this.showcaseKey,
    required this.imagePath,
    required this.title,
    required this.backgroundColor,
    required this.routeName,
    required this.tooltipTitle,
    required this.tooltipDescription,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = ControlPanelStyles.getAdminCardDimensions(context);
        
        return Showcase(
          key: showcaseKey,
          title: tooltipTitle,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
            letterSpacing: -0.3,
          ),
          description: tooltipDescription,
          descTextStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
            height: 1.4,
            letterSpacing: 0,
          ),
          targetBorderRadius: BorderRadius.circular(8),
          tooltipBackgroundColor: Colors.white,
          overlayColor: Colors.black,
          overlayOpacity: 0.75,
          tooltipBorderRadius: BorderRadius.circular(12),
          tooltipPadding: const EdgeInsets.all(24),
          targetPadding: const EdgeInsets.all(8),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, routeName),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: dimensions['horizontalPadding']!,
                vertical: dimensions['verticalPadding']!,
              ),
              decoration: ControlPanelStyles.getAdminCardDecoration(backgroundColor),
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
                      style: ControlPanelStyles.getAdminCardTitleStyle(
                        dimensions['fontSize']!
                      ),
                    ),
                  ),
                  Icon(
                    ControlPanelStyles.arrowForwardIcon,
                    color: ControlPanelStyles.arrowColor,
                    size: dimensions['iconSize']!,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}