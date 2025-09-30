import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../admin/styles/ver_admin/ver_admins_colors.dart';
import '../admin/styles/ver_admin/ver_admins_dimensions.dart';
import '../admin/styles/ver_admin/ver_admins_styles.dart';

class VerAdminsPage extends StatefulWidget {
  const VerAdminsPage({super.key});

  @override
  State<VerAdminsPage> createState() => _VerAdminsPageState();
}

class _VerAdminsPageState extends State<VerAdminsPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> admins = [];
  bool cargando = true;
  String? error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    cargarAdmins();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  Future<void> cargarAdmins() async {
    setState(() {
      cargando = true;
      error = null;
    });

    bool isConnected = await _checkConnectivity();
    if (!isConnected) {
      setState(() {
        error = 'Sin conexión a internet';
        cargando = false;
      });
      return;
    }

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);

      if (auth.token == null) {
        await auth.cargarSesion();
      }

      final accessToken = auth.token;

      if (accessToken == null) {
        setState(() {
          error = 'Sesión expirada. Inicia sesión nuevamente';
          cargando = false;
        });
        return;
      }

      final service = AdminService(token: accessToken);
      final result = await service.listarAdmins();

      if (result['ok']) {
        setState(() {
          admins = result['data'];
          cargando = false;
        });
        _animationController.forward();
      } else {
        setState(() {
          error = result['mensaje'] ?? 'Error inesperado';
          cargando = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Error de conexión';
        cargando = false;
      });
    }
  }

  void _mostrarSnack(String mensaje, {bool esError = false}) {
    if (!mounted) return;
    
    final dimensions = VerAdminsDimensions(MediaQuery.of(context).size.width);
    final styles = VerAdminsStyles(dimensions);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: dimensions.snackBarIconSize,
            ),
            SizedBox(width: dimensions.snackBarIconSpacing),
            Expanded(
              child: Text(
                mensaje,
                style: styles.snackBarTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: esError ? VerAdminsColors.errorRed : VerAdminsColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: styles.snackBarShape,
        margin: EdgeInsets.all(dimensions.snackBarMargin),
        duration: Duration(seconds: esError ? 4 : 3),
      ),
    );
  }

  Future<void> eliminarAdmin(String id, String nombre) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildConfirmDialog(nombre),
    );

    if (result != true) return;

    final dimensions = VerAdminsDimensions(MediaQuery.of(context).size.width);
    final styles = VerAdminsStyles(dimensions);

    // Mostrar loading mientras se elimina
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(dimensions.loadingDialogMargin),
          child: Padding(
            padding: EdgeInsets.all(dimensions.loadingDialogPadding),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: dimensions.loadingDialogSpacing),
                Text(
                  'Eliminando administrador...',
                  style: styles.loadingTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final accessToken = auth.token;

    if (accessToken == null) {
      Navigator.pop(context); // Cerrar loading
      _mostrarSnack('Token no disponible', esError: true);
      return;
    }

    final service = AdminService(token: accessToken);
    final success = await service.eliminarAdmin(id);

    Navigator.pop(context); // Cerrar loading

    if (success) {
      _mostrarSnack('Administrador eliminado exitosamente');
      await cargarAdmins();
    } else {
      _mostrarSnack('No se pudo eliminar el administrador', esError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final esSuperAdmin = auth.rol == 'superAdmin';
    final dimensions = VerAdminsDimensions(MediaQuery.of(context).size.width);

    return Scaffold(
      backgroundColor: VerAdminsColors.backgroundGrey,
      body: RefreshIndicator(
        onRefresh: cargarAdmins,
        color: VerAdminsColors.primaryBlue,
        backgroundColor: Colors.white,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _buildSliverAppBar(dimensions),
            SliverToBoxAdapter(
              child: _buildStatsCard(dimensions),
            ),
            _buildContent(esSuperAdmin, dimensions),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(VerAdminsDimensions dimensions) {
    final styles = VerAdminsStyles(dimensions);
    
    return SliverAppBar(
      expandedHeight: dimensions.appBarHeight,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: VerAdminsColors.primaryBlue,
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Administradores',
          style: styles.appBarTitleStyle,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: styles.appBarGradient,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard(VerAdminsDimensions dimensions) {
    final styles = VerAdminsStyles(dimensions);

    return Container(
      margin: EdgeInsets.all(dimensions.statsMargin),
      padding: EdgeInsets.all(dimensions.statsPadding),
      decoration: styles.statsCardDecoration,
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(dimensions.statsIconPadding),
            decoration: styles.statsIconDecoration,
            child: Icon(
              Icons.admin_panel_settings,
              color: VerAdminsColors.primaryBlue,
              size: dimensions.statsIconSize,
            ),
          ),
          SizedBox(width: dimensions.statsSpacing),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de administradores',
                style: styles.statsTitleStyle,
              ),
              SizedBox(height: dimensions.cardSubtitleSpacing),
              Text(
                cargando ? '...' : '${admins.length}',
                style: styles.statsCountStyle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool esSuperAdmin, VerAdminsDimensions dimensions) {
    if (cargando) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, index) => _buildSkeletonCard(dimensions),
          childCount: 5,
        ),
      );
    }

    if (error != null) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildErrorState(dimensions),
      );
    }

    if (admins.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmptyState(dimensions),
      );
    }

    // Para desktop, usar grid si hay muchos admins
    if (dimensions.isDesktop && admins.length > 3) {
      return _buildGridContent(esSuperAdmin, dimensions);
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        dimensions.contentHorizontalPadding, 
        0, 
        dimensions.contentHorizontalPadding, 
        dimensions.contentBottomPadding
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final admin = admins[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                )),
                child: _buildAdminCard(admin, esSuperAdmin, index, dimensions),
              ),
            );
          },
          childCount: admins.length,
        ),
      ),
    );
  }

  Widget _buildGridContent(bool esSuperAdmin, VerAdminsDimensions dimensions) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: dimensions.gridCrossAxisCount,
          childAspectRatio: dimensions.gridChildAspectRatio,
          crossAxisSpacing: dimensions.gridCrossAxisSpacing,
          mainAxisSpacing: dimensions.gridMainAxisSpacing,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final admin = admins[index];
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                )),
                child: _buildAdminCard(admin, esSuperAdmin, index, dimensions),
              ),
            );
          },
          childCount: admins.length,
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(VerAdminsDimensions dimensions) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: dimensions.skeletonMargin, 
        vertical: 8
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          padding: EdgeInsets.all(dimensions.skeletonPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(dimensions.cardRadius),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: dimensions.skeletonAvatarRadius, 
                backgroundColor: Colors.white
              ),
              SizedBox(width: dimensions.statsSpacing),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: dimensions.skeletonTitleHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: dimensions.skeletonSpacing),
                    Container(
                      height: dimensions.skeletonSubtitleHeight,
                      width: dimensions.skeletonSubtitleWidth,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdminCard(
    dynamic admin, 
    bool esSuperAdmin, 
    int index, 
    VerAdminsDimensions dimensions
  ) {
    final styles = VerAdminsStyles(dimensions);
    final color = VerAdminsColors.getAvatarColor(index);

    return Container(
      margin: EdgeInsets.only(bottom: dimensions.cardMarginBottom),
      decoration: styles.cardDecoration,
      child: ListTile(
        contentPadding: EdgeInsets.all(dimensions.cardPadding),
        leading: Hero(
          tag: 'admin_${admin['_id']}',
          child: Container(
            width: dimensions.avatarSize,
            height: dimensions.avatarSize,
            decoration: styles.avatarDecoration(color),
            child: Center(
              child: Text(
                (admin['nombre'] ?? '?').substring(0, 1).toUpperCase(),
                style: styles.avatarTextStyle,
              ),
            ),
          ),
        ),
        title: Text(
          admin['nombre'] ?? 'Sin nombre',
          style: styles.cardTitleStyle,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: dimensions.cardSubtitleSpacing),
            Row(
              children: [
                Icon(
                  Icons.email_outlined, 
                  size: dimensions.cardIconSize, 
                  color: VerAdminsColors.textSecondary
                ),
                SizedBox(width: dimensions.cardIconSpacing),
                Expanded(
                  child: Text(
                    admin['email'] ?? 'Sin correo',
                    style: styles.cardSubtitleStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (admin['rol'] != null) ...[
              SizedBox(height: dimensions.cardRolSpacing),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: dimensions.cardRolPaddingH, 
                  vertical: dimensions.cardRolPaddingV
                ),
                decoration: styles.rolBadgeDecoration(color),
                child: Text(
                  admin['rol'].toString().toUpperCase(),
                  style: styles.cardRolStyle(color[700]!),
                ),
              ),
            ],
          ],
        ),
        trailing: esSuperAdmin
            ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(dimensions.deleteIconRadius),
                child: InkWell(
                  borderRadius: BorderRadius.circular(dimensions.deleteIconRadius),
                  onTap: () => eliminarAdmin(
                    admin['_id'],
                    admin['nombre'] ?? 'Admin',
                  ),
                  child: Container(
                    padding: EdgeInsets.all(dimensions.deleteIconPadding),
                    child: Icon(
                      Icons.delete_outline,
                      color: VerAdminsColors.redButton,
                      size: dimensions.deleteIconSize,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildConfirmDialog(String nombre) {
    final dimensions = VerAdminsDimensions(MediaQuery.of(context).size.width);
    final styles = VerAdminsStyles(dimensions);
    
    return AlertDialog(
      shape: styles.dialogShape,
      insetPadding: EdgeInsets.all(dimensions.dialogPadding),
      title: Row(
        children: [
          Icon(
            Icons.warning, 
            color: VerAdminsColors.warningOrange,
            size: dimensions.dialogIconSize,
          ),
          SizedBox(width: dimensions.dialogIconSpacing),
          Expanded(
            child: Text(
              'Confirmar eliminación',
              style: styles.dialogTitleStyle,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dimensions.dialogMaxWidth,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar a:',
              style: styles.dialogContentStyle,
            ),
            SizedBox(height: dimensions.dialogSpacingSmall),
            Text(
              nombre,
              style: styles.dialogNameStyle,
            ),
            SizedBox(height: dimensions.dialogSpacingMedium),
            Text(
              'Esta acción no se puede deshacer.',
              style: styles.dialogWarningStyle,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: styles.dialogCancelStyle,
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: styles.dialogDeleteButtonStyle,
          child: Text(
            'Eliminar',
            style: styles.dialogDeleteStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(VerAdminsDimensions dimensions) {
    final styles = VerAdminsStyles(dimensions);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(dimensions.statePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(dimensions.errorIconPadding),
              decoration: styles.errorIconDecoration,
              child: Icon(
                Icons.error_outline,
                size: dimensions.errorIconSize,
                color: VerAdminsColors.redButton,
              ),
            ),
            SizedBox(height: dimensions.stateSpacingMedium),
            Text(
              'Oops! Algo salió mal',
              style: styles.errorTitleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: dimensions.stateSpacingSmall),
            Text(
              error!,
              style: styles.errorMessageStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: dimensions.stateSpacingMedium),
            Text(
              'Desliza hacia abajo para reintentar',
              style: styles.emptyHintStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(VerAdminsDimensions dimensions) {
    final styles = VerAdminsStyles(dimensions);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(dimensions.statePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(dimensions.stateIconPadding),
              decoration: styles.emptyIconDecoration,
              child: Icon(
                Icons.admin_panel_settings_outlined,
                size: dimensions.stateIconSize,
                color: Colors.blue[300],
              ),
            ),
            SizedBox(height: dimensions.stateSpacingLarge),
            Text(
              'No hay administradores',
              style: styles.emptyTitleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: dimensions.stateSpacingSmall),
            Text(
              'Cuando se registre un administrador,\nlo verás aquí.',
              style: styles.emptySubtitleStyle,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: dimensions.stateSpacingMedium),
            Text(
              'Desliza hacia abajo para actualizar',
              style: styles.emptyHintStyle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}