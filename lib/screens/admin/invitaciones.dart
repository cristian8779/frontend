import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/rol_service.dart';

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
  late AnimationController _refreshController;
  late AnimationController _fadeController;
  late Animation<double> _refreshAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.elasticOut,
    ));
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
    _refreshController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _mostrarMensaje(String mensaje, {bool error = false, bool importante = false}) {
    final color = importante ? Colors.amber.shade700 : (error ? Colors.red.shade700 : Colors.green.shade700);
    final backgroundColor = importante ? Colors.amber.shade50 : (error ? Colors.red.shade50 : Colors.green.shade50);
    final icono = importante ? Icons.warning_amber_rounded : (error ? Icons.error_outline : Icons.check_circle_outline);
    
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
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      mensaje,
                      style: TextStyle(
                        color: color,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: importante ? 8 : (error ? 6 : 4)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 8,
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
    
    if (_rolSeleccionado == null) {
      _mostrarMensaje("Debes seleccionar un rol para la invitación", error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final resultado = await _rolService.invitarCambioRol(correo, _rolSeleccionado!);
      if (resultado['success'] == true) {
        _mostrarMensaje(resultado['mensaje'] ?? 'Invitación enviada exitosamente');
        _emailController.clear();
        setState(() => _rolSeleccionado = null);
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
    _refreshController.forward().then((_) => _refreshController.reset());
    
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
    final confirmar = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.delete_forever, color: Colors.red.shade700, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                "Eliminar Todas",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Esta acción eliminará TODAS las invitaciones permanentemente",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Para confirmar, escribe exactamente:",
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text(
                "ELIMINAR TODO",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmacionController,
              decoration: InputDecoration(
                labelText: "Confirmación",
                hintText: "Escribe: ELIMINAR TODO",
                prefixIcon: Icon(Icons.edit_outlined, color: Colors.grey.shade600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.blue.shade400, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _confirmacionController.clear();
              Navigator.pop(context, false);
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text("Cancelar", style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text("Confirmar Eliminación", style: TextStyle(fontWeight: FontWeight.bold)),
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

  String _getDescripcionRol(String? rol) {
    switch (rol) {
      case "admin":
        return "Administrador con permisos para gestionar productos, ventas y anuncios de la plataforma.";
      case "superAdmin":
        return "Super Administrador con control total del sistema, incluyendo gestión completa de roles y usuarios.";
      default:
        return "";
    }
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
        'color': Colors.grey.shade700,
        'backgroundColor': Colors.grey.shade100,
        'icon': Icons.access_time_filled_rounded,
        'prioridad': 3,
      };
    }

    switch (estado.toLowerCase()) {
      case 'pendiente':
        return {
          'texto': 'Pendiente',
          'color': Colors.orange.shade700,
          'backgroundColor': Colors.orange.shade100,
          'icon': Icons.pending_actions_rounded,
          'prioridad': 2,
        };
      case 'confirmado':
        return {
          'texto': 'Confirmada',
          'color': Colors.green.shade700,
          'backgroundColor': Colors.green.shade100,
          'icon': Icons.check_circle_rounded,
          'prioridad': 1,
        };
      case 'cancelado':
        return {
          'texto': 'Cancelada',
          'color': Colors.red.shade700,
          'backgroundColor': Colors.red.shade100,
          'icon': Icons.cancel_rounded,
          'prioridad': 4,
        };
      default:
        return {
          'texto': estado,
          'color': Colors.grey.shade700,
          'backgroundColor': Colors.grey.shade100,
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
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
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
                      width: double.infinity,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 180,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 120,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
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

  // Widget estilo resumen de producto para las invitaciones
  Widget _buildResumenInvitaciones() {
    final pendientes = _invitaciones.where((inv) => inv['estado'] == 'pendiente' && !_estaExpirada(inv['expiracion'])).length;
    final confirmadas = _invitaciones.where((inv) => inv['estado'] == 'confirmado').length;
    final expiradas = _invitaciones.where((inv) => _estaExpirada(inv['expiracion'])).length;
    final total = _invitaciones.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de invitaciones',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                'Total',
                total.toString(),
                Colors.blue,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Pendientes',
                pendientes.toString(),
                Colors.orange,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Confirmadas',
                confirmadas.toString(),
                Colors.green,
              ),
              const SizedBox(width: 16),
              _buildStatItem(
                'Expiradas',
                expiradas.toString(),
                Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.rolActual != "superAdmin") {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text("Acceso Restringido", style: TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade400, Colors.red.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(70),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade200,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(Icons.shield_outlined, size: 70, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text(
                  "Acceso Restringido",
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade200,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "Solo los Super Administradores pueden acceder a la gestión de invitaciones de roles. Este módulo requiere permisos especiales para proteger la seguridad del sistema.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text("Volver", style: TextStyle(fontWeight: FontWeight.w600)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Ordenar invitaciones por prioridad
    final invitacionesOrdenadas = List<Map<String, dynamic>>.from(_invitaciones);
    invitacionesOrdenadas.sort((a, b) {
      final estadoA = _getEstadoInfo(a['estado'] ?? '', a['expiracion']);
      final estadoB = _getEstadoInfo(b['estado'] ?? '', b['expiracion']);
      return estadoA['prioridad'].compareTo(estadoB['prioridad']);
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestión de Roles',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _refreshAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _refreshAnimation.value * 2.0 * 3.14159,
                child: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 24),
                  onPressed: _cargandoLista ? null : _cargarInvitaciones,
                  tooltip: "Actualizar lista",
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _cargarInvitaciones,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resumen estilo producto
                if (!_cargandoLista && _invitaciones.isNotEmpty)
                  _buildResumenInvitaciones(),

                // Sección de nueva invitación
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.person_add_outlined,
                                color: const Color(0xFF10B981),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Nueva Invitación',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1F2937),
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Campo de email
                        Text(
                          "Correo electrónico *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_loading,
                          decoration: InputDecoration(
                            hintText: "usuario@empresa.com",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.email_outlined, color: Color(0xFF9CA3AF), size: 20),
                            ),
                            suffixIcon: _emailController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () => _emailController.clear(),
                                    color: const Color(0xFF9CA3AF),
                                  )
                                : null,
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                          ),
                          onChanged: (value) => setState(() {}),
                        ),
                        const SizedBox(height: 20),
                        
                        // Campo de rol
                        Text(
                          "Rol a asignar *",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: _rolSeleccionado,
                          items: const [
                            DropdownMenuItem(
                              value: "admin",
                              child: Row(
                                children: [
                                  Icon(Icons.admin_panel_settings_rounded, size: 20, color: Colors.blue),
                                  SizedBox(width: 12),
                                  Text("Administrador", style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: "superAdmin",
                              child: Row(
                                children: [
                                  Icon(Icons.security_rounded, size: 20, color: Colors.purple),
                                  SizedBox(width: 12),
                                  Text("Super Administrador", style: TextStyle(fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                          onChanged: _loading ? null : (value) => setState(() => _rolSeleccionado = value),
                          decoration: InputDecoration(
                            hintText: "Seleccionar rol",
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 16, right: 12),
                              child: Icon(Icons.badge_outlined, color: Color(0xFF9CA3AF), size: 20),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
                            ),
                          ),
                        ),
                        
                        // Descripción del rol
                        if (_rolSeleccionado != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6366F1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: const Color(0xFF6366F1),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _getDescripcionRol(_rolSeleccionado),
                                    style: TextStyle(
                                      color: const Color(0xFF6366F1),
                                      fontSize: 13,
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Botón enviar
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _enviarInvitacion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: const Color(0xFF9CA3AF),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _loading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Text(
                                        'Enviando invitación...',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.send_outlined, size: 22),
                                      const SizedBox(width: 12),
                                      const Text(
                                        'Enviar Invitación',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),

                // Header de invitaciones
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.history_outlined,
                        color: const Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Historial de Invitaciones',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF6366F1).withOpacity(0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_invitaciones.isNotEmpty && !_cargandoLista) ...[
                      IconButton(
                        onPressed: _eliminandoTodas ? null : _eliminarTodasLasInvitaciones,
                        icon: _eliminandoTodas
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red.shade600,
                                ),
                              )
                            : Icon(
                                Icons.delete_forever_outlined,
                                color: Colors.red.shade600,
                              ),
                        tooltip: "Eliminar todas las invitaciones",
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Lista de invitaciones
                if (_cargandoLista)
                  Column(
                    children: List.generate(3, (index) => _buildShimmerItem()),
                  )
                else if (_invitaciones.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.inbox_outlined,
                            size: 40,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          "No hay invitaciones",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Las invitaciones que envíes aparecerán aquí con información detallada sobre su estado",
                          style: TextStyle(
                            color: const Color(0xFF6B7280),
                            fontSize: 15,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: invitacionesOrdenadas.map((inv) {
                      final correo = inv["email"] ?? "Sin correo";
                      final rol = inv["nuevoRol"] ?? "Desconocido";
                      final estado = inv["estado"] ?? "pendiente";
                      final expiracion = inv["expiracion"];
                      final estadoInfo = _getEstadoInfo(estado, expiracion);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Header con email y estado
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: estadoInfo['backgroundColor'],
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: estadoInfo['color'].withOpacity(0.3),
                                      ),
                                    ),
                                    child: Icon(
                                      estadoInfo['icon'],
                                      color: estadoInfo['color'],
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          correo,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Icon(
                                              rol == "superAdmin" ? Icons.security : Icons.admin_panel_settings,
                                              size: 16,
                                              color: const Color(0xFF6B7280),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              rol == 'superAdmin' ? 'Super Administrador' : 'Administrador',
                                              style: const TextStyle(
                                                color: Color(0xFF6B7280),
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: estadoInfo['backgroundColor'],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: estadoInfo['color'].withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      estadoInfo['texto'],
                                      style: TextStyle(
                                        color: estadoInfo['color'],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Info adicional
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFE5E7EB)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_outlined,
                                      size: 16,
                                      color: _estaExpirada(expiracion) 
                                          ? Colors.red.shade600 
                                          : const Color(0xFF6B7280),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _formatearTiempoExpiracion(expiracion?.toString()),
                                        style: TextStyle(
                                          color: _estaExpirada(expiracion) 
                                              ? Colors.red.shade600 
                                              : const Color(0xFF6B7280),
                                          fontSize: 13,
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
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}