import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_admin_provider.dart';
import 'widgets/categoria_list.dart';
import 'widgets/banner.dart';
import 'widgets/error_message.dart';
import 'widgets/top_icons.dart';
import 'widgets/categoria_skeleton.dart';
import 'widgets/connection_error_widget.dart';
import 'styles/control_panel_styles.dart';

// 👇 AGREGAR: Importar el routeObserver
import '../../main.dart';

class ControlPanelScreen extends StatefulWidget {
  final String rol;

  const ControlPanelScreen({super.key, this.rol = "admin"});

  @override
  State<ControlPanelScreen> createState() => _ControlPanelScreenState();
}

class _ControlPanelScreenState extends State<ControlPanelScreen> with RouteAware {

  @override
  void initState() {
    super.initState();
    // Inicializar el provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CategoriasProvider>().inicializar();
    });
  }

  // 👇 AGREGAR: Suscribirse al RouteObserver
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);
  }

  // 👇 AGREGAR: Desuscribirse del RouteObserver
  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Se ejecuta cuando regresamos a esta pantalla desde otra pantalla
    super.didPopNext();
    print("🔄 Regresando a ControlPanel - Recargando categorías...");
    // Usar refresh silencioso para no mostrar skeleton
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

  const _ContenidoFijo({
    required this.rol,
    required this.categoriasProvider,
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
                  TopIcons(rol: rol, showNotificationIcon: false),
                  BannerWidget(media: media),
                  const SizedBox(height: ControlPanelStyles.defaultSpacing),
                  Text(
                    "Categorías",
                    style: ControlPanelStyles.getSectionTitleStyle(
                      dimensions['titleFontSize']!
                    ),
                  ),
                  const SizedBox(height: ControlPanelStyles.smallSpacing),
                  
                  // 🎯 MANEJO DE ESTADOS CON PROVIDER MEJORADO
                  if (categoriasProvider.isLoading && categoriasProvider.categorias.isEmpty)
                    // Solo mostrar skeleton si es carga inicial (no hay datos)
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
                              title: 'Gestión de Productos',
                              imagePath: 'assets/producto.png',
                              backgroundColor: ControlPanelStyles.productosCardBackground,
                              routeName: '/gestion-productos',
                            ),
                            _AdminCard(
                              title: 'Gestión de Ventas',
                              imagePath: 'assets/venta.png',
                              backgroundColor: ControlPanelStyles.ventasCardBackground,
                              routeName: '/gestion-ventas',
                            ),
                            _AdminCard(
                              title: 'Gestión de Anuncios',
                              imagePath: 'assets/anuncio.png',
                              backgroundColor: ControlPanelStyles.anunciosCardBackground,
                              routeName: '/anuncios-activos',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = ControlPanelStyles.getAdminCardDimensions(context);
        
        return GestureDetector(
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
        );
      },
    );
  }
}