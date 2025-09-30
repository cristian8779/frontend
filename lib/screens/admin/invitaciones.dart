import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/rol_service.dart';
import 'styles/invitaciones/invitaciones_colors.dart';
import 'styles/invitaciones/invitaciones_text_styles.dart';
import 'styles/invitaciones/invitaciones_decorations.dart';
import 'styles/invitaciones/invitaciones_dimensions.dart';
import 'styles/invitaciones/invitaciones_button_styles.dart';

class InvitacionRolScreen extends StatefulWidget {
  final String rolActual;

  const InvitacionRolScreen({Key? key, required this.rolActual}) : super(key: key);

  @override
  State<InvitacionRolScreen> createState() => _InvitacionRolScreenState();
}

class _InvitacionRolScreenState extends State<InvitacionRolScreen>
    with TickerProviderStateMixin {
  final RolService _rolService = RolService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmacionController = TextEditingController();
  String? _rolSeleccionado;
  bool _loading = false;
  bool _cargandoLista = false;
  bool _eliminandoTodas = false;
  List<Map<String, dynamic>> _invitaciones = [];
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: InvitacionesDimensions.fadeAnimationDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.rolActual == "superAdmin") {
      _cargarInvitaciones();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _confirmacionController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool error = false, bool importante = false}) {
    final color = importante 
        ? InvitacionesColors.warningSnackbar 
        : (error ? InvitacionesColors.errorSnackbar : InvitacionesColors.successSnackbar);
    final backgroundColor = importante 
        ? InvitacionesColors.warningSnackbarBg 
        : (error ? InvitacionesColors.errorSnackbarBg : InvitacionesColors.successSnackbarBg);
    final icono = importante 
        ? Icons.warning_amber_rounded 
        : (error ? Icons.error_outline : Icons.check_circle_outline);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      importante ? "Atención" : (error ? "Error" : "Éxito"),
                      style: InvitacionesTextStyles.snackbarTitle(color, false),
                    ),
                    Text(
                      mensaje,
                      style: InvitacionesTextStyles.snackbarMessage(color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        duration: InvitacionesDimensions.getSnackbarDuration(error: error, importante: importante),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: InvitacionesDimensions.dialogElevation,
      ),
    );
  }

  bool _validarEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email);
  }

  Future<void> _enviarInvitacion() async {
    final correo = _emailController.text.trim();
    if (correo.isEmpty) {
      _mostrarMensaje("Debes ingresar un correo electrónico", error: true);
      return;
    }
    
    if (!_validarEmail(correo)) {
      _mostrarMensaje("El formato del correo electrónico no es válido", error: true);
      return;
    }
    
    final rolAsignar = "admin";

    setState(() => _loading = true);
    try {
      final resultado = await _rolService.invitarCambioRol(correo, rolAsignar);
      if (resultado['success'] == true) {
        _mostrarMensaje(resultado['mensaje'] ?? 'Invitación enviada exitosamente');
        _emailController.clear();
        await _cargarInvitaciones();
      } else {
        _mostrarMensaje(resultado['mensaje'] ?? 'Error al enviar la invitación', error: true);
      }
    } catch (e) {
      debugPrint("❌ Error al enviar invitación: $e");
      _mostrarMensaje("Error: ${e.toString().replaceFirst('Exception: ', '')}", error: true);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _cargarInvitaciones() async {
    setState(() => _cargandoLista = true);
    
    try {
      final data = await _rolService.listarInvitaciones();
      if (mounted && data['success'] == true) {
        setState(() {
          _invitaciones = List<Map<String, dynamic>>.from(data['invitaciones'] ?? []);
        });
        debugPrint("📋 Invitaciones cargadas: ${_invitaciones.length}");
        
        _verificarEstadosImportantes();
      } else {
        if (mounted) {
          _mostrarMensaje(data['mensaje'] ?? 'Error al cargar invitaciones', error: true);
        }
      }
    } catch (e) {
      debugPrint("❌ Error cargando invitaciones: $e");
      if (mounted) {
        _mostrarMensaje("Error: ${e.toString().replaceFirst('Exception: ', '')}", error: true);
      }
    } finally {
      if (mounted) setState(() => _cargandoLista = false);
    }
  }

  void _verificarEstadosImportantes() {
    final expiradas = _invitaciones.where((inv) => _estaExpirada(inv['expiracion'])).length;
    final confirmadas = _invitaciones.where((inv) => inv['estado'] == 'confirmado').length;
    
    if (expiradas > 0) {
      _mostrarMensaje("$expiradas invitación${expiradas > 1 ? 'es han' : ' ha'} expirado", importante: true);
    }
    if (confirmadas > 0) {
      _mostrarMensaje("$confirmadas invitación${confirmadas > 1 ? 'es fueron' : ' fue'} confirmada${confirmadas > 1 ? 's' : ''} recientemente");
    }
  }

  bool _estaExpirada(dynamic expiracionStr) {
    if (expiracionStr == null) return false;
    try {
      final expiracion = DateTime.parse(expiracionStr.toString());
      return expiracion.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  Future<void> _eliminarTodasLasInvitaciones() async {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: InvitacionesButtonStyles.roundedBorder,
        title: Row(
          children: [
            Container(
              padding: InvitacionesDimensions.getDialogPadding(isSmall),
              decoration: InvitacionesDecorations.iconContainer(Colors.red.shade100, radius: 12),
              child: Icon(
                Icons.delete_forever, 
                color: Colors.red.shade700, 
                size: InvitacionesDimensions.getLargeIconSize(isSmall),
              ),
            ),
            SizedBox(width: InvitacionesDimensions.getItemSpacing(isSmall)),
            Expanded(
              child: Text("Eliminar Todas", style: InvitacionesTextStyles.dialogTitle(isSmall)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: InvitacionesDimensions.getContentPadding(isSmall),
                decoration: InvitacionesDecorations.warningContainer(isSmall),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded, 
                      color: Colors.red.shade700, 
                      size: InvitacionesDimensions.getIconSize(isSmall),
                    ),
                    SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                    Expanded(
                      child: Text(
                        "Esta acción eliminará TODAS las invitaciones permanentemente",
                        style: InvitacionesTextStyles.warningText(isSmall),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
              Text(
                "Para confirmar, escribe exactamente:",
                style: InvitacionesTextStyles.confirmationText(isSmall),
              ),
              SizedBox(height: InvitacionesDimensions.getSmallSpacing(isSmall)),
              Container(
                width: double.infinity,
                padding: InvitacionesDimensions.getSmallPadding(isSmall),
                decoration: InvitacionesDecorations.confirmationBox(isSmall),
                child: Text(
                  "ELIMINAR TODO",
                  style: InvitacionesTextStyles.monospace(isSmall),
                ),
              ),
              SizedBox(height: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
              TextField(
                controller: _confirmacionController,
                decoration: InvitacionesDecorations.dialogTextFieldDecoration(isSmall),
                textCapitalization: TextCapitalization.characters,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _confirmacionController.clear();
              Navigator.pop(context, false);
            },
            style: InvitacionesButtonStyles.textButton(isSmall),
            child: Text("Cancelar", style: InvitacionesTextStyles.buttonSmall(isSmall)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: InvitacionesButtonStyles.dangerButton(isSmall),
            child: Text("Confirmar Eliminación", style: InvitacionesTextStyles.buttonSmall(isSmall)),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      _confirmacionController.clear();
      return;
    }

    final confirmacion = _confirmacionController.text.trim();
    if (confirmacion != "ELIMINAR TODO") {
      _mostrarMensaje("La confirmación no es correcta. Debe escribir exactamente: ELIMINAR TODO", error: true);
      return;
    }

    setState(() => _eliminandoTodas = true);
    try {
      final resultado = await _rolService.eliminarTodasLasInvitaciones(confirmacion);
      if (resultado['success'] == true) {
        _mostrarMensaje(resultado['mensaje'] ?? 'Todas las invitaciones han sido eliminadas');
        await _cargarInvitaciones();
      } else {
        _mostrarMensaje(resultado['mensaje'] ?? 'Error al eliminar las invitaciones', error: true);
      }
    } catch (e) {
      debugPrint("❌ Error al eliminar todas las invitaciones: $e");
      _mostrarMensaje("Error: ${e.toString().replaceFirst('Exception: ', '')}", error: true);
    } finally {
      setState(() => _eliminandoTodas = false);
      _confirmacionController.clear();
    }
  }

  void _mostrarInformacionPantalla(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: InvitacionesButtonStyles.roundedBorder,
        title: Row(
          children: [
            Container(
              padding: InvitacionesDimensions.getLargeIconContainerSize(isSmall) == 10 
                  ? const EdgeInsets.all(10) 
                  : const EdgeInsets.all(12),
              decoration: InvitacionesDecorations.gradientContainer(
                [InvitacionesColors.accent, InvitacionesColors.accentLight],
              ),
              child: Icon(
                Icons.info_rounded,
                color: Colors.white,
                size: InvitacionesDimensions.getLargeIconSize(isSmall),
              ),
            ),
            SizedBox(width: InvitacionesDimensions.getItemSpacing(isSmall)),
            Expanded(
              child: Text("Gestión de Roles", style: InvitacionesTextStyles.dialogTitle(isSmall)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoSection(
                icon: Icons.send_outlined,
                title: "Enviar Invitaciones",
                description: "Invita usuarios por correo electrónico para que se conviertan en administradores de la plataforma.",
                color: InvitacionesColors.success,
                isSmall: isSmall,
              ),
              SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
              _buildInfoSection(
                icon: Icons.admin_panel_settings_rounded,
                title: "Rol de Administrador",
                description: "Los administradores pueden gestionar productos, ventas y anuncios. No tienen permisos para gestionar otros roles.",
                color: Colors.blue,
                isSmall: isSmall,
              ),
              SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
              _buildInfoSection(
                icon: Icons.schedule_outlined,
                title: "Tiempo de Expiración",
                description: "Las invitaciones tienen un tiempo límite. Si expiran, se eliminarán automáticamente después de 15 minutos.",
                color: Colors.orange,
                isSmall: isSmall,
              ),
              SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
              _buildInfoSection(
                icon: Icons.history_outlined,
                title: "Historial",
                description: "Visualiza todas las invitaciones enviadas con su estado actual: pendiente, confirmada, expirada o cancelada.",
                color: InvitacionesColors.accent,
                isSmall: isSmall,
              ),
              SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
              Container(
                padding: InvitacionesDimensions.getContentPadding(isSmall),
                decoration: InvitacionesDecorations.infoContainer(isSmall),
                child: Row(
                  children: [
                    Icon(
                      Icons.swipe_down_rounded,
                      color: InvitacionesColors.accent,
                      size: InvitacionesDimensions.getIconSize(isSmall),
                    ),
                    SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                    Expanded(
                      child: Text(
                        "Desliza hacia abajo para actualizar la lista de invitaciones",
                        style: InvitacionesTextStyles.bodySmall(isSmall).copyWith(
                          color: InvitacionesColors.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: InvitacionesButtonStyles.dialogTextButton(isSmall),
            child: Text(
              "Entendido",
              style: InvitacionesTextStyles.button(isSmall).copyWith(
                color: InvitacionesColors.accent,
                fontSize: isSmall ? 14 : 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required bool isSmall,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: InvitacionesDimensions.getSmallPadding(isSmall),
          decoration: InvitacionesDecorations.iconContainer(color, radius: 10),
          child: Icon(icon, color: color, size: InvitacionesDimensions.getSmallIconSize(isSmall)),
        ),
        SizedBox(width: InvitacionesDimensions.getItemSpacing(isSmall)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: InvitacionesTextStyles.infoTitle(isSmall)),
              SizedBox(height: InvitacionesDimensions.getSmallSpacing(isSmall)),
              Text(description, style: InvitacionesTextStyles.infoDescription(isSmall)),
            ],
          ),
        ),
      ],
    );
  }

  String _getDescripcionRol() {
    return "Administrador con permisos para gestionar productos, ventas y anuncios de la plataforma.";
  }

  Map<String, dynamic> _getEstadoInfo(String estado, dynamic expiracion) {
    final ahora = DateTime.now();
    bool expirada = false;
    
    if (expiracion != null) {
      try {
        final fechaExpiracion = DateTime.parse(expiracion.toString());
        expirada = fechaExpiracion.isBefore(ahora);
      } catch (e) {
        // Ignore parsing error
      }
    }

    if (expirada && estado == 'pendiente') {
      return {
        'texto': 'Expirada',
        'color': InvitacionesColors.expiradoColor,
        'backgroundColor': InvitacionesColors.expiradoBackground,
        'icon': Icons.access_time_filled_rounded,
        'prioridad': 3,
      };
    }

    switch (estado.toLowerCase()) {
      case 'pendiente':
        return {
          'texto': 'Pendiente',
          'color': InvitacionesColors.pendienteColor,
          'backgroundColor': InvitacionesColors.pendienteBackground,
          'icon': Icons.pending_actions_rounded,
          'prioridad': 2,
        };
      case 'confirmado':
        return {
          'texto': 'Confirmada',
          'color': InvitacionesColors.confirmadoColor,
          'backgroundColor': InvitacionesColors.confirmadoBackground,
          'icon': Icons.check_circle_rounded,
          'prioridad': 1,
        };
      case 'cancelado':
        return {
          'texto': 'Cancelada',
          'color': InvitacionesColors.canceladoColor,
          'backgroundColor': InvitacionesColors.canceladoBackground,
          'icon': Icons.cancel_rounded,
          'prioridad': 4,
        };
      default:
        return {
          'texto': estado,
          'color': InvitacionesColors.expiradoColor,
          'backgroundColor': InvitacionesColors.expiradoBackground,
          'icon': Icons.help_outline_rounded,
          'prioridad': 5,
        };
    }
  }

  String _formatearTiempoExpiracion(String? expiracionStr) {
    if (expiracionStr == null) return "Sin límite";
    
    try {
      final expiracion = DateTime.parse(expiracionStr);
      final ahora = DateTime.now();
      final diferencia = expiracion.difference(ahora);
      
      if (diferencia.isNegative) {
        final tiempoExpirado = ahora.difference(expiracion);
        if (tiempoExpirado.inDays > 0) {
          return "Expiró hace ${tiempoExpirado.inDays} día${tiempoExpirado.inDays > 1 ? 's' : ''}";
        } else if (tiempoExpirado.inHours > 0) {
          return "Expiró hace ${tiempoExpirado.inHours}h";
        } else {
          return "Expiró hace ${tiempoExpirado.inMinutes}min";
        }
      } else {
        if (diferencia.inMinutes < 60) {
          return "${diferencia.inMinutes} minutos restantes";
        } else if (diferencia.inHours < 24) {
          return "${diferencia.inHours}h ${diferencia.inMinutes % 60}min restantes";
        } else if (diferencia.inDays < 7) {
          return "${diferencia.inDays} día${diferencia.inDays > 1 ? 's' : ''} restante${diferencia.inDays > 1 ? 's' : ''}";
        } else {
          return "${expiracion.day}/${expiracion.month}/${expiracion.year}";
        }
      }
    } catch (e) {
      return "Fecha inválida";
    }
  }

  Widget _buildShimmerItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: InvitacionesDimensions.getShimmerMargin,
        decoration: InvitacionesDecorations.shimmerContainer,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: InvitacionesDimensions.shimmerAvatarSize,
                height: InvitacionesDimensions.shimmerAvatarSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: InvitacionesDimensions.shimmerTitleWidth,
                      height: InvitacionesDimensions.shimmerTitleHeight,
                      decoration: InvitacionesDecorations.shimmerElement,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: InvitacionesDimensions.shimmerSubtitleWidth,
                      height: InvitacionesDimensions.shimmerSubtitleHeight,
                      decoration: InvitacionesDecorations.shimmerElement,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: InvitacionesDimensions.shimmerSmallWidth,
                      height: InvitacionesDimensions.shimmerSmallHeight,
                      decoration: InvitacionesDecorations.shimmerElement,
                    ),
                  ],
                ),
              ),
              Container(
                width: InvitacionesDimensions.shimmerIconSize,
                height: InvitacionesDimensions.shimmerIconSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenInvitaciones() {
    final pendientes = _invitaciones.where((inv) => inv['estado'] == 'pendiente' && !_estaExpirada(inv['expiracion'])).length;
    final confirmadas = _invitaciones.where((inv) => inv['estado'] == 'confirmado').length;
    final expiradas = _invitaciones.where((inv) => _estaExpirada(inv['expiracion'])).length;
    final total = _invitaciones.length;
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return Container(
      margin: InvitacionesDimensions.getSummaryMargin,
      padding: InvitacionesDimensions.getContentPadding(isSmall),
      decoration: InvitacionesDecorations.summaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Resumen de invitaciones', style: InvitacionesTextStyles.label(isSmall)),
          SizedBox(height: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
          isSmall
              ? Column(
                  children: [
                    Row(
                      children: [
                        _buildStatItem('Total', total.toString(), Colors.blue, isSmall),
                        const SizedBox(width: 12),
                        _buildStatItem('Pendientes', pendientes.toString(), Colors.orange, isSmall),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatItem('Confirmadas', confirmadas.toString(), Colors.green, isSmall),
                        const SizedBox(width: 12),
                        _buildStatItem('Expiradas', expiradas.toString(), Colors.red, isSmall),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    _buildStatItem('Total', total.toString(), Colors.blue, isSmall),
                    const SizedBox(width: 16),
                    _buildStatItem('Pendientes', pendientes.toString(), Colors.orange, isSmall),
                    const SizedBox(width: 16),
                    _buildStatItem('Confirmadas', confirmadas.toString(), Colors.green, isSmall),
                    const SizedBox(width: 16),
                    _buildStatItem('Expiradas', expiradas.toString(), Colors.red, isSmall),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, bool isSmall) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: InvitacionesTextStyles.statLabel(isSmall)),
          SizedBox(height: InvitacionesDimensions.getTinySpacing(isSmall)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? 6 : 8,
              vertical: isSmall ? 3 : 4,
            ),
            decoration: InvitacionesDecorations.statBadge(color),
            child: Text(value, style: InvitacionesTextStyles.statValue(isSmall, color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;
    final padding = InvitacionesDimensions.getPadding(size);

    if (widget.rolActual != "superAdmin") {
      return _buildRestrictedAccessScreen(isSmall, padding);
    }

    final invitacionesOrdenadas = List<Map<String, dynamic>>.from(_invitaciones);
    invitacionesOrdenadas.sort((a, b) {
      final estadoA = _getEstadoInfo(a['estado'] ?? '', a['expiracion']);
      final estadoB = _getEstadoInfo(b['estado'] ?? '', b['expiracion']);
      return estadoA['prioridad'].compareTo(estadoB['prioridad']);
    });

    return Scaffold(
      backgroundColor: InvitacionesColors.backgroundPrimary,
      appBar: _buildAppBar(isSmall),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _cargarInvitaciones,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!_cargandoLista && _invitaciones.isNotEmpty)
                  _buildResumenInvitaciones(),
                _buildNewInvitationCard(isSmall),
                SizedBox(height: InvitacionesDimensions.getTitleSpacing(isSmall)),
                _buildInvitationsHeader(isSmall),
                SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
                _buildInvitationsList(invitacionesOrdenadas, isSmall),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isSmall) {
    return AppBar(
      title: Text('Gestión de Roles', style: InvitacionesTextStyles.title(isSmall)),
      centerTitle: true,
      backgroundColor: Colors.white,
      foregroundColor: InvitacionesColors.primaryText,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: InvitacionesColors.border),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline_rounded, size: InvitacionesDimensions.getIconSize(isSmall)),
          onPressed: () => _mostrarInformacionPantalla(context),
          tooltip: "Información",
          color: InvitacionesColors.accent,
        ),
        SizedBox(width: isSmall ? 4 : 8),
      ],
    );
  }

  Widget _buildNewInvitationCard(bool isSmall) {
    return Container(
      width: double.infinity,
      decoration: InvitacionesDecorations.cardDecoration,
      child: Padding(
        padding: InvitacionesDimensions.getCardPadding(isSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(InvitacionesDimensions.getIconContainerSize(isSmall)),
                  decoration: InvitacionesDecorations.iconContainer(InvitacionesColors.success),
                  child: Icon(
                    Icons.person_add_outlined,
                    color: InvitacionesColors.success,
                    size: InvitacionesDimensions.getSmallIconSize(isSmall),
                  ),
                ),
                SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                Text('Nueva Invitación', style: InvitacionesTextStyles.sectionTitle(isSmall)),
              ],
            ),
            SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
            Text("Correo electrónico *", style: InvitacionesTextStyles.label(isSmall)),
            SizedBox(height: InvitacionesDimensions.getSmallSpacing(isSmall)),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_loading,
              decoration: InvitacionesDecorations.textFieldDecoration(
                isSmall,
                hint: "usuario@empresa.com",
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    left: isSmall ? 12 : 16,
                    right: isSmall ? 10 : 12,
                  ),
                  child: Icon(
                    Icons.email_outlined,
                    color: InvitacionesColors.tertiaryText,
                    size: InvitacionesDimensions.getSmallIconSize(isSmall),
                  ),
                ),
                suffixIcon: _emailController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: InvitacionesDimensions.getSmallIconSize(isSmall)),
                        onPressed: () => _emailController.clear(),
                        color: InvitacionesColors.tertiaryText,
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
            SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
            Container(
              width: double.infinity,
              padding: InvitacionesDimensions.getContentPadding(isSmall),
              decoration: InvitacionesDecorations.infoContainer(isSmall),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings_rounded,
                        size: InvitacionesDimensions.getIconSize(isSmall),
                        color: Colors.blue,
                      ),
                      SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                      Text("Rol: Administrador", style: InvitacionesTextStyles.cardTitle(isSmall)),
                    ],
                  ),
                  SizedBox(height: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(InvitacionesDimensions.getIconContainerSize(isSmall) - 1),
                        decoration: InvitacionesDecorations.iconContainer(InvitacionesColors.accent, radius: 6),
                        child: Icon(
                          Icons.info_outline,
                          color: InvitacionesColors.accent,
                          size: InvitacionesDimensions.getTinyIconSize(isSmall),
                        ),
                      ),
                      SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                      Expanded(
                        child: Text(_getDescripcionRol(), style: InvitacionesTextStyles.description(isSmall)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
            SizedBox(
              width: double.infinity,
              height: InvitacionesDimensions.getButtonHeight(isSmall),
              child: ElevatedButton(
                onPressed: _loading ? null : _enviarInvitacion,
                style: InvitacionesButtonStyles.primaryButton(isSmall),
                child: _loading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: InvitacionesDimensions.getProgressIndicatorSize(isSmall),
                            height: InvitacionesDimensions.getProgressIndicatorSize(isSmall),
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: InvitacionesDimensions.getItemSpacing(isSmall)),
                          Text('Enviando invitación...', style: InvitacionesTextStyles.button(isSmall)),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send_outlined, size: InvitacionesDimensions.getSmallIconSize(isSmall)),
                          SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
                          Text('Enviar Invitación', style: InvitacionesTextStyles.button(isSmall)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationsHeader(bool isSmall) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(InvitacionesDimensions.getIconContainerSize(isSmall)),
          decoration: InvitacionesDecorations.iconContainer(InvitacionesColors.accent),
          child: Icon(
            Icons.history_outlined,
            color: InvitacionesColors.accent,
            size: InvitacionesDimensions.getSmallIconSize(isSmall),
          ),
        ),
        SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
        Flexible(
          child: Text(
            'Historial de Invitaciones',
            style: InvitacionesTextStyles.sectionTitle(isSmall),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [InvitacionesColors.accent.withOpacity(0.3), Colors.transparent],
              ),
            ),
          ),
        ),
        if (_invitaciones.isNotEmpty && !_cargandoLista) ...[
          IconButton(
            onPressed: _eliminandoTodas ? null : _eliminarTodasLasInvitaciones,
            icon: _eliminandoTodas
                ? SizedBox(
                    width: InvitacionesDimensions.getSmallIconSize(isSmall),
                    height: InvitacionesDimensions.getSmallIconSize(isSmall),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.red.shade600,
                    ),
                  )
                : Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red.shade600,
                    size: InvitacionesDimensions.getIconSize(isSmall),
                  ),
            tooltip: "Eliminar todas las invitaciones",
            style: InvitacionesButtonStyles.iconButton(isSmall),
          ),
        ],
      ],
    );
  }

  Widget _buildInvitationsList(List<Map<String, dynamic>> invitacionesOrdenadas, bool isSmall) {
    if (_cargandoLista) {
      return Column(children: List.generate(3, (index) => _buildShimmerItem()));
    }

    if (_invitaciones.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(isSmall ? 32 : 40),
        decoration: InvitacionesDecorations.emptyStateContainer(isSmall),
        child: Column(
          children: [
            Container(
              width: InvitacionesDimensions.getEmptyStateIconSize(isSmall),
              height: InvitacionesDimensions.getEmptyStateIconSize(isSmall),
              decoration: InvitacionesDecorations.emptyStateIcon(isSmall),
              child: Icon(
                Icons.inbox_outlined,
                size: InvitacionesDimensions.getEmptyStateIconInnerSize(isSmall),
                color: InvitacionesColors.accent,
              ),
            ),
            SizedBox(height: InvitacionesDimensions.getSectionSpacing(isSmall)),
            Text("No hay invitaciones", style: InvitacionesTextStyles.emptyStateTitle(isSmall)),
            SizedBox(height: InvitacionesDimensions.getExtraSmallSpacing(isSmall)),
            Text(
              "Las invitaciones que envíes aparecerán aquí con información detallada sobre su estado",
              style: InvitacionesTextStyles.emptyStateMessage(isSmall),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: invitacionesOrdenadas.map((inv) => _buildInvitationCard(inv, isSmall)).toList(),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> inv, bool isSmall) {
    final correo = inv["email"] ?? "Sin correo";
    final rol = inv["nuevoRol"] ?? "Desconocido";
    final estado = inv["estado"] ?? "pendiente";
    final expiracion = inv["expiracion"];
    final estadoInfo = _getEstadoInfo(estado, expiracion);

    return Container(
      margin: InvitacionesDimensions.getItemMargin(isSmall),
      decoration: InvitacionesDecorations.cardWithShadowDecoration,
      child: Padding(
        padding: InvitacionesDimensions.getCardPadding(isSmall),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: InvitacionesDimensions.getAvatarSize(isSmall),
                  height: InvitacionesDimensions.getAvatarSize(isSmall),
                  decoration: InvitacionesDecorations.estadoIconContainer(
                    estadoInfo['backgroundColor'],
                    estadoInfo['color'],
                    InvitacionesDimensions.getAvatarSize(isSmall) / 2,
                  ),
                  child: Icon(
                    estadoInfo['icon'],
                    color: estadoInfo['color'],
                    size: InvitacionesDimensions.getIconSize(isSmall),
                  ),
                ),
                SizedBox(width: InvitacionesDimensions.getItemSpacing(isSmall)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(correo, style: InvitacionesTextStyles.cardTitle(isSmall), overflow: TextOverflow.ellipsis),
                      SizedBox(height: InvitacionesDimensions.getTinySpacing(isSmall)),
                      Row(
                        children: [
                          Icon(
                            rol == "superAdmin" ? Icons.security : Icons.admin_panel_settings,
                            size: InvitacionesDimensions.getTinyIconSize(isSmall),
                            color: InvitacionesColors.secondaryText,
                          ),
                          SizedBox(width: InvitacionesDimensions.getSmallSpacing(isSmall) - 1),
                          Flexible(
                            child: Text(
                              rol == 'superAdmin' ? 'Super Administrador' : 'Administrador',
                              style: InvitacionesTextStyles.subtitle(isSmall),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: isSmall ? 8 : 0),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmall ? 8 : 12,
                    vertical: isSmall ? 4 : 6,
                  ),
                  decoration: InvitacionesDecorations.estadoBadge(
                    estadoInfo['backgroundColor'],
                    estadoInfo['color'],
                  ),
                  child: Text(
                    estadoInfo['texto'],
                    style: InvitacionesTextStyles.estadoText(isSmall).copyWith(color: estadoInfo['color']),
                  ),
                ),
              ],
            ),
            SizedBox(height: InvitacionesDimensions.getItemSpacing(isSmall)),
            Container(
              padding: InvitacionesDimensions.getSmallPadding(isSmall),
              decoration: InvitacionesDecorations.timeInfoContainer(isSmall),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule_outlined,
                    size: InvitacionesDimensions.getTinyIconSize(isSmall),
                    color: _estaExpirada(expiracion)
                        ? Colors.red.shade600
                        : InvitacionesColors.secondaryText,
                  ),
                  SizedBox(width: InvitacionesDimensions.getSmallSpacing(isSmall)),
                  Expanded(
                    child: Text(
                      _formatearTiempoExpiracion(expiracion?.toString()),
                      style: InvitacionesTextStyles.timeText(isSmall, isExpired: _estaExpirada(expiracion)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictedAccessScreen(bool isSmall, double padding) {
    return Scaffold(
      backgroundColor: InvitacionesColors.backgroundPrimary,
      appBar: AppBar(
        title: Text("Acceso Restringido", style: InvitacionesTextStyles.title(isSmall)),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: InvitacionesDimensions.getRestrictedIconSize(isSmall),
                height: InvitacionesDimensions.getRestrictedIconSize(isSmall),
                decoration: InvitacionesDecorations.restrictedAccessIconDecoration(isSmall),
                child: Icon(
                  Icons.shield_outlined,
                  size: InvitacionesDimensions.getRestrictedIconInnerSize(isSmall),
                  color: Colors.white,
                ),
              ),
              SizedBox(height: InvitacionesDimensions.getTitleSpacing(isSmall)),
              Text(
                "Acceso Restringido",
                style: InvitacionesTextStyles.emptyStateTitle(isSmall).copyWith(fontSize: isSmall ? 20 : 24),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: InvitacionesDimensions.getItemSpacing(isSmall)),
              Container(
                padding: InvitacionesDimensions.getCardPadding(isSmall),
                decoration: InvitacionesDecorations.whiteCardWithShadow(isSmall),
                child: Text(
                  "Solo los Super Administradores pueden acceder a la gestión de invitaciones de roles. Este módulo requiere permisos especiales para proteger la seguridad del sistema.",
                  style: InvitacionesTextStyles.body(isSmall),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: InvitacionesDimensions.getTitleSpacing(isSmall)),
              ElevatedButton.icon(
                icon: Icon(Icons.arrow_back_rounded, size: InvitacionesDimensions.getIconSize(isSmall)),
                label: Text("Volver", style: InvitacionesTextStyles.button(isSmall)),
                style: InvitacionesButtonStyles.backButton(isSmall),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}