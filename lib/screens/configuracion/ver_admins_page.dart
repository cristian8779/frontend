import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';

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
    
    final screenWidth = MediaQuery.of(context).size.width;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              esError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: screenWidth > 600 ? 24 : 20,
            ),
            SizedBox(width: screenWidth > 600 ? 16 : 12),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(fontSize: screenWidth > 600 ? 16 : 15),
              ),
            ),
          ],
        ),
        backgroundColor: esError ? Colors.red[600] : Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(screenWidth > 600 ? 24 : 16),
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

    // Mostrar loading mientras se elimina
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Card(
          margin: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 48 : 24),
          child: Padding(
            padding: EdgeInsets.all(MediaQuery.of(context).size.width > 600 ? 32 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                SizedBox(height: MediaQuery.of(context).size.width > 600 ? 24 : 16),
                Text(
                  'Eliminando administrador...',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
                  ),
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(isTablet, isDesktop),
          SliverToBoxAdapter(
            child: _buildStatsCard(isTablet, isDesktop),
          ),
          _buildContent(esSuperAdmin, isTablet, isDesktop),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(bool isTablet, bool isDesktop) {
    return SliverAppBar(
      expandedHeight: isDesktop ? 160 : (isTablet ? 140 : 120),
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.blue[600],
      iconTheme: const IconThemeData(color: Colors.white),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Administradores',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isDesktop ? 24 : (isTablet ? 22 : 20),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[600]!,
                Colors.blue[800]!,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.refresh, 
            color: Colors.white,
            size: isTablet ? 28 : 24,
          ),
          onPressed: cargando ? null : cargarAdmins,
          tooltip: 'Actualizar',
        ),
        if (isTablet) const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsCard(bool isTablet, bool isDesktop) {
    final margin = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final padding = isDesktop ? 32.0 : (isTablet ? 24.0 : 20.0);

    return Container(
      margin: EdgeInsets.all(margin),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isTablet ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 16 : 12),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
            ),
            child: Icon(
              Icons.admin_panel_settings,
              color: Colors.blue[600],
              size: isDesktop ? 32 : (isTablet ? 28 : 24),
            ),
          ),
          SizedBox(width: isTablet ? 20 : 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total de administradores',
                style: TextStyle(
                  fontSize: isDesktop ? 18 : (isTablet ? 16 : 14),
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: isTablet ? 8 : 4),
              Text(
                cargando ? '...' : '${admins.length}',
                style: TextStyle(
                  fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool esSuperAdmin, bool isTablet, bool isDesktop) {
    if (cargando) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (_, index) => _buildSkeletonCard(isTablet, isDesktop),
          childCount: 5,
        ),
      );
    }

    if (error != null) {
      return SliverFillRemaining(
        child: _buildErrorState(isTablet, isDesktop),
      );
    }

    if (admins.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(isTablet, isDesktop),
      );
    }

    // Para desktop, usar grid si hay muchos admins
    if (isDesktop && admins.length > 3) {
      return _buildGridContent(esSuperAdmin, isDesktop);
    }

    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        isDesktop ? 32 : (isTablet ? 24 : 16), 
        0, 
        isDesktop ? 32 : (isTablet ? 24 : 16), 
        isDesktop ? 32 : (isTablet ? 24 : 16)
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
                child: _buildAdminCard(admin, esSuperAdmin, index, isTablet, isDesktop),
              ),
            );
          },
          childCount: admins.length,
        ),
      ),
    );
  }

  Widget _buildGridContent(bool esSuperAdmin, bool isDesktop) {
    final crossAxisCount = isDesktop ? 2 : 1;
    
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          childAspectRatio: 3.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 12,
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
                child: _buildAdminCard(admin, esSuperAdmin, index, true, isDesktop),
              ),
            );
          },
          childCount: admins.length,
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(bool isTablet, bool isDesktop) {
    final margin = isDesktop ? 32.0 : (isTablet ? 24.0 : 16.0);
    final padding = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);
    final avatarRadius = isDesktop ? 35.0 : (isTablet ? 32.0 : 30.0);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin, vertical: 8),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[200]!,
        highlightColor: Colors.grey[50]!,
        child: Container(
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
          ),
          child: Row(
            children: [
              CircleAvatar(radius: avatarRadius, backgroundColor: Colors.white),
              SizedBox(width: isTablet ? 20 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: isDesktop ? 20 : (isTablet ? 18 : 16),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    SizedBox(height: isTablet ? 12 : 8),
                    Container(
                      height: isDesktop ? 18 : (isTablet ? 16 : 14),
                      width: isTablet ? 180 : 150,
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

  Widget _buildAdminCard(dynamic admin, bool esSuperAdmin, int index, bool isTablet, bool isDesktop) {
    final colores = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
    ];
    final color = colores[index % colores.length];
    final avatarSize = isDesktop ? 64.0 : (isTablet ? 60.0 : 56.0);
    final padding = isDesktop ? 24.0 : (isTablet ? 22.0 : 20.0);

    return Container(
      margin: EdgeInsets.only(bottom: isTablet ? 16 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: isTablet ? 15 : 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(padding),
        leading: Hero(
          tag: 'admin_${admin['_id']}',
          child: Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color[400]!,
                  color[600]!,
                ],
              ),
              borderRadius: BorderRadius.circular(isTablet ? 20 : 16),
            ),
            child: Center(
              child: Text(
                (admin['nombre'] ?? '?').substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isDesktop ? 28 : (isTablet ? 26 : 24),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          admin['nombre'] ?? 'Sin nombre',
          style: TextStyle(
            fontSize: isDesktop ? 20 : (isTablet ? 19 : 18),
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: isTablet ? 8 : 4),
            Row(
              children: [
                Icon(
                  Icons.email_outlined, 
                  size: isDesktop ? 20 : (isTablet ? 18 : 16), 
                  color: Colors.grey[600]
                ),
                SizedBox(width: isTablet ? 8 : 6),
                Expanded(
                  child: Text(
                    admin['email'] ?? 'Sin correo',
                    style: TextStyle(
                      fontSize: isDesktop ? 16 : (isTablet ? 15 : 14),
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (admin['rol'] != null) ...[
              SizedBox(height: isTablet ? 12 : 8),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isTablet ? 12 : 8, 
                  vertical: isTablet ? 6 : 4
                ),
                decoration: BoxDecoration(
                  color: color[100],
                  borderRadius: BorderRadius.circular(isTablet ? 10 : 8),
                ),
                child: Text(
                  admin['rol'].toString().toUpperCase(),
                  style: TextStyle(
                    fontSize: isDesktop ? 14 : (isTablet ? 13 : 12),
                    fontWeight: FontWeight.w600,
                    color: color[700],
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: esSuperAdmin
            ? Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                  onTap: () => eliminarAdmin(
                    admin['_id'],
                    admin['nombre'] ?? 'Admin',
                  ),
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 12 : 8),
                    child: Icon(
                      Icons.delete_outline,
                      color: Colors.red[400],
                      size: isDesktop ? 28 : (isTablet ? 26 : 24),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildConfirmDialog(String nombre) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isTablet ? 20 : 16)
      ),
      insetPadding: EdgeInsets.all(isTablet ? 32 : 16),
      title: Row(
        children: [
          Icon(
            Icons.warning, 
            color: Colors.orange[600],
            size: isTablet ? 28 : 24,
          ),
          SizedBox(width: isTablet ? 16 : 12),
          Expanded(
            child: Text(
              'Confirmar eliminación',
              style: TextStyle(fontSize: isTablet ? 20 : 18),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 500 : double.infinity,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '¿Estás seguro de que deseas eliminar a:',
              style: TextStyle(fontSize: isTablet ? 16 : 14),
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              nombre,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isTablet ? 18 : 16,
              ),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'Esta acción no se puede deshacer.',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: isTablet ? 15 : 14,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isTablet ? 16 : 14,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 24 : 16,
              vertical: isTablet ? 12 : 8,
            ),
          ),
          child: Text(
            'Eliminar',
            style: TextStyle(fontSize: isTablet ? 16 : 14),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(bool isTablet, bool isDesktop) {
    final padding = isDesktop ? 48.0 : (isTablet ? 32.0 : 24.0);
    final iconSize = isDesktop ? 80.0 : (isTablet ? 72.0 : 64.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 28 : 24)),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(isTablet ? 24 : 16),
              ),
              child: Icon(
                Icons.error_outline,
                size: iconSize,
                color: Colors.red[400],
              ),
            ),
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),
            Text(
              'Oops! Algo salió mal',
              style: TextStyle(
                fontSize: isDesktop ? 28 : (isTablet ? 24 : 20),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 12 : 8),
            Text(
              error!,
              style: TextStyle(
                fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 32 : (isTablet ? 28 : 24)),
            ElevatedButton.icon(
              onPressed: cargarAdmins,
              icon: Icon(
                Icons.refresh,
                size: isTablet ? 24 : 20,
              ),
              label: Text(
                'Intentar nuevamente',
                style: TextStyle(fontSize: isTablet ? 18 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                  vertical: isDesktop ? 16 : (isTablet ? 14 : 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isTablet, bool isDesktop) {
    final padding = isDesktop ? 48.0 : (isTablet ? 32.0 : 24.0);
    final iconSize = isDesktop ? 100.0 : (isTablet ? 90.0 : 80.0);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 40 : (isTablet ? 36 : 32)),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(isDesktop ? 32 : (isTablet ? 28 : 24)),
              ),
              child: Icon(
                Icons.admin_panel_settings_outlined,
                size: iconSize,
                color: Colors.blue[300],
              ),
            ),
            SizedBox(height: isDesktop ? 40 : (isTablet ? 36 : 32)),
            Text(
              'No hay administradores',
              style: TextStyle(
                fontSize: isDesktop ? 32 : (isTablet ? 28 : 24),
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isTablet ? 16 : 12),
            Text(
              'Cuando se registre un administrador,\nlo verás aquí.',
              style: TextStyle(
                fontSize: isDesktop ? 18 : (isTablet ? 17 : 16),
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isDesktop ? 40 : (isTablet ? 36 : 32)),
            ElevatedButton.icon(
              onPressed: cargarAdmins,
              icon: Icon(
                Icons.refresh,
                size: isTablet ? 24 : 20,
              ),
              label: Text(
                'Actualizar',
                style: TextStyle(fontSize: isTablet ? 18 : 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 32 : (isTablet ? 28 : 24),
                  vertical: isDesktop ? 16 : (isTablet ? 14 : 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isTablet ? 16 : 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}