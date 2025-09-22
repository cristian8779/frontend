import 'package:flutter/material.dart';
import '../../services/superAdminservice.dart';

class TransferenciaSuperAdminScreen extends StatefulWidget {
  const TransferenciaSuperAdminScreen({super.key});

  @override
  State<TransferenciaSuperAdminScreen> createState() =>
      _TransferenciaSuperAdminScreenState();
}

class _TransferenciaSuperAdminScreenState
    extends State<TransferenciaSuperAdminScreen> {
  final SuperAdminService _service = SuperAdminService();
  bool _cargando = true;
  bool _pendiente = false;
  bool _procesandoTransferencia = false;
  bool _procesandoConfirmacion = false;
  Map<String, dynamic>? _transferenciaPendiente;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _codigoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cargarTransferenciaPendiente();
  }

  Future<void> _cargarTransferenciaPendiente() async {
    setState(() => _cargando = true);
    try {
      final data = await _service.verificarTransferenciaPendiente();
      setState(() {
        _pendiente = data["pendiente"] ?? false;
        _transferenciaPendiente = data;
      });
    } catch (e) {
      _mostrarMensaje("Error al cargar información", e.toString(), Colors.red);
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _iniciarTransferencia() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _mostrarMensaje("Campo requerido", "Por favor ingresa un correo electrónico", Colors.orange);
      return;
    }

    if (!_isValidEmail(email)) {
      _mostrarMensaje("Correo inválido", "Por favor ingresa un correo electrónico válido", Colors.orange);
      return;
    }

    // Mostrar diálogo de confirmación
    final confirmar = await _mostrarDialogoConfirmacion(
      "¿Confirmar transferencia?",
      "Se transferirán todos los permisos de SuperAdmin a:\n\n$email\n\nEsta acción es irreversible una vez confirmada.",
    );

    if (!confirmar) return;

    setState(() => _procesandoTransferencia = true);
    try {
      final result = await _service.transferirSuperAdmin(email);
      _mostrarMensaje(
        "Transferencia iniciada",
        "${result['mensaje']}\nExpira: ${result['expiracion']}",
        Colors.green,
        duration: 5,
      );
      _emailController.clear();
      _cargarTransferenciaPendiente();
    } catch (e) {
      _mostrarMensaje("Error al transferir", e.toString(), Colors.red);
    } finally {
      setState(() => _procesandoTransferencia = false);
    }
  }

  Future<void> _confirmarTransferencia() async {
    final codigo = _codigoController.text.trim();
    if (codigo.isEmpty) {
      _mostrarMensaje("Campo requerido", "Por favor ingresa el código de confirmación", Colors.orange);
      return;
    }

    setState(() => _procesandoConfirmacion = true);
    try {
      final result = await _service.confirmarTransferencia(codigo);
      _mostrarMensaje("Transferencia confirmada", result["mensaje"], Colors.green);
      _codigoController.clear();
      _cargarTransferenciaPendiente();
    } catch (e) {
      _mostrarMensaje("Error al confirmar", e.toString(), Colors.red);
    } finally {
      setState(() => _procesandoConfirmacion = false);
    }
  }

  Future<void> _rechazarTransferencia() async {
    final confirmar = await _mostrarDialogoConfirmacion(
      "¿Rechazar transferencia?",
      "Se cancelará la transferencia pendiente. El código de confirmación dejará de ser válido.",
    );

    if (!confirmar) return;

    try {
      final result = await _service.rechazarTransferencia();
      _mostrarMensaje("Transferencia rechazada", result["mensaje"], Colors.orange);
      _cargarTransferenciaPendiente();
    } catch (e) {
      _mostrarMensaje("Error al rechazar", e.toString(), Colors.red);
    }
  }

  void _mostrarMensaje(String titulo, String mensaje, Color color, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(mensaje),
          ],
        ),
        backgroundColor: color,
        duration: Duration(seconds: duration),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion(String titulo, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 8),
                Expanded(child: Text(titulo)),
              ],
            ),
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text("Confirmar", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Transferencia de SuperAdmin"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: _cargando
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Cargando información..."),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header informativo
                  _buildHeaderInfo(),
                  const SizedBox(height: 24),
                  
                  // Contenido principal
                  _pendiente ? _buildTransferenciaPendiente() : _buildIniciarTransferencia(),
                  
                  const SizedBox(height: 24),
                  
                  // Información adicional
                  _buildInfoAdicional(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
              const SizedBox(width: 8),
              Text(
                "Gestión de SuperAdmin",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Desde aquí puedes transferir todos los permisos de SuperAdmin a otro usuario. "
            "Esta funcionalidad te permite cambiar el administrador principal del sistema de forma segura.",
            style: TextStyle(color: Colors.blue[700], height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferenciaPendiente() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.orange[50]!, Colors.yellow[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pending_actions, color: Colors.orange[700], size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Transferencia Pendiente",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow("Destinatario", _transferenciaPendiente?['email'] ?? 'Desconocido'),
                  const SizedBox(height: 8),
                  _buildInfoRow("Solicitante", _transferenciaPendiente?['solicitante'] ?? 'Desconocido'),
                  const SizedBox(height: 8),
                  _buildInfoRow("Expira", _transferenciaPendiente?['expiracion'] ?? 'Desconocida'),
                  const SizedBox(height: 8),
                  _buildEstadoRow(),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            _buildEstadoInfo(),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.mail_outline, color: Colors.amber[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Se ha enviado un código de confirmación al correo del nuevo SuperAdmin. "
                      "Solicita el código para completar la transferencia.",
                      style: TextStyle(color: Colors.amber[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            TextField(
              controller: _codigoController,
              decoration: InputDecoration(
                labelText: "Código de confirmación",
                hintText: "Ej: ABC123",
                prefixIcon: const Icon(Icons.vpn_key),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _procesandoConfirmacion ? null : _confirmarTransferencia,
                    icon: _procesandoConfirmacion
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check_circle),
                    label: Text(_procesandoConfirmacion ? "Confirmando..." : "Confirmar Transferencia"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _rechazarTransferencia,
                    icon: const Icon(Icons.cancel),
                    label: const Text("Rechazar"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIniciarTransferencia() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Colors.blue[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Iniciar Transferencia",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "⚠️ IMPORTANTE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Esta acción transferirá TODOS los permisos de SuperAdmin al usuario especificado. "
                          "Una vez confirmada, perderás acceso total al sistema.",
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Correo del nuevo SuperAdmin",
                hintText: "ejemplo@correo.com",
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                helperText: "Este usuario recibirá el código de confirmación",
              ),
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _procesandoTransferencia ? null : _iniciarTransferencia,
                icon: _procesandoTransferencia
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
                label: Text(_procesandoTransferencia ? "Procesando..." : "Iniciar Transferencia"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoAdicional() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help_outline, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  "Información Adicional",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "• Los códigos de confirmación expiran después de un tiempo determinado\n"
              "• Solo puede haber una transferencia pendiente a la vez\n"
              "• El proceso es reversible hasta que se confirme\n"
              "• Asegúrate de que el correo sea correcto antes de enviar",
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEstadoInfo() {
    final estado = _transferenciaPendiente?['estado'] ?? 'desconocido';
    final fechaExpiracion = _transferenciaPendiente?['expiracion'];
    bool isExpired = false;
    
    // Verificar si está expirado
    if (fechaExpiracion != null) {
      final expiration = DateTime.parse(fechaExpiracion);
      isExpired = DateTime.now().isAfter(expiration);
    }
    
    String mensaje;
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    
    if (isExpired || estado.toLowerCase() == 'expirado') {
      mensaje = "Esta transferencia ha expirado. El código ya no es válido y la transferencia se canceló automáticamente.";
      bgColor = Colors.red[50]!;
      borderColor = Colors.red[200]!;
      textColor = Colors.red[800]!;
      icon = Icons.timer_off;
    } else {
      switch (estado.toLowerCase()) {
        case 'pendiente':
          mensaje = "Se ha enviado un código de confirmación al correo del nuevo SuperAdmin. "
                   "Solicita el código para completar la transferencia.";
          bgColor = Colors.amber[50]!;
          borderColor = Colors.amber[200]!;
          textColor = Colors.amber[800]!;
          icon = Icons.mail_outline;
          break;
        case 'confirmado':
          mensaje = "La transferencia ha sido confirmada exitosamente. Los permisos ya han sido transferidos.";
          bgColor = Colors.green[50]!;
          borderColor = Colors.green[200]!;
          textColor = Colors.green[800]!;
          icon = Icons.check_circle_outline;
          break;
        case 'cancelado':
          mensaje = "La transferencia fue cancelada por el usuario. No se realizó ningún cambio de permisos.";
          bgColor = Colors.grey[50]!;
          borderColor = Colors.grey[200]!;
          textColor = Colors.grey[800]!;
          icon = Icons.info_outline;
          break;
        case 'rechazado':
          mensaje = "La transferencia fue rechazada. El código de confirmación ya no es válido.";
          bgColor = Colors.red[50]!;
          borderColor = Colors.red[200]!;
          textColor = Colors.red[800]!;
          icon = Icons.block;
          break;
        default:
          mensaje = "Estado desconocido. Por favor, contacta al administrador del sistema.";
          bgColor = Colors.grey[50]!;
          borderColor = Colors.grey[200]!;
          textColor = Colors.grey[800]!;
          icon = Icons.help_outline;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensaje,
              style: TextStyle(color: textColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoRow() {
    final estado = _transferenciaPendiente?['estado'] ?? 'desconocido';
    String estadoTexto;
    Color estadoColor;
    IconData estadoIcon;
    
    switch (estado.toLowerCase()) {
      case 'pendiente':
        estadoTexto = 'Pendiente';
        estadoColor = Colors.orange[600]!;
        estadoIcon = Icons.pending;
        break;
      case 'confirmado':
        estadoTexto = 'Confirmado';
        estadoColor = Colors.green[600]!;
        estadoIcon = Icons.check_circle;
        break;
      case 'expirado':
        estadoTexto = 'Expirado';
        estadoColor = Colors.red[600]!;
        estadoIcon = Icons.timer_off;
        break;
      case 'cancelado':
        estadoTexto = 'Cancelado';
        estadoColor = Colors.grey[600]!;
        estadoIcon = Icons.cancel;
        break;
      case 'rechazado':
        estadoTexto = 'Rechazado';
        estadoColor = Colors.red[600]!;
        estadoIcon = Icons.block;
        break;
      default:
        estadoTexto = 'Desconocido';
        estadoColor = Colors.grey[600]!;
        estadoIcon = Icons.help_outline;
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          width: 80,
          child: Text(
            "Estado:",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: estadoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: estadoColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      estadoIcon,
                      size: 14,
                      color: estadoColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      estadoTexto,
                      style: TextStyle(
                        color: estadoColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codigoController.dispose();
    super.dispose();
  }
}