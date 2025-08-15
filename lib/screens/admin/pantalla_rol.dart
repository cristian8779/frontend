import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/rol_service.dart'; // Ajusta la ruta según tu estructura
import 'bienvenida_admin_screen.dart';

class PantallaRol extends StatefulWidget {
  const PantallaRol({Key? key}) : super(key: key);

  @override
  State<PantallaRol> createState() => _PantallaRolState();
}

class _PantallaRolState extends State<PantallaRol> with TickerProviderStateMixin {
  final RolService _rolService = RolService();
  final TextEditingController _codigoController = TextEditingController();

  String? _emailInvitacion;
  String? _nuevoRol;
  DateTime? _fechaExpiracion;
  Duration _tiempoRestante = Duration.zero;
  Timer? _timer;

  bool _loading = false;
  bool _cargandoInvitacion = true;
  bool _codigoExpirado = false;

  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _timerController;
  
  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _timerPulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _cargarInvitacionPendiente();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _timerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _timerPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.easeInOut,
    ));

    // Pulso continuo para el campo PIN
    _pulseController.repeat(reverse: true);
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  void _shakeFields() {
    HapticFeedback.heavyImpact();
    _shakeController.reset();
    _shakeController.forward();
  }

  void _mostrarMensaje(String mensaje, {bool error = false}) {
    _showNotification(
      message: mensaje,
      type: error ? NotificationType.error : NotificationType.success,
      icon: error ? Icons.error_outline : Icons.check_circle_outline,
    );
  }

  void _iniciarContador() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_fechaExpiracion == null) return;
      final diferencia = _fechaExpiracion!.difference(DateTime.now());

      if (diferencia.isNegative) {
        _timer?.cancel();
        setState(() {
          _tiempoRestante = Duration.zero;
          _codigoExpirado = true;
        });
        _mostrarMensaje("⏰ El código ha expirado", error: true);
      } else {
        setState(() {
          _tiempoRestante = diferencia;
        });
        
        // Animación de pulso cuando queden menos de 60 segundos
        if (_tiempoRestante.inSeconds <= 60) {
          _timerController.repeat(reverse: true);
        }
      }
    });
  }

  Future<void> _cargarInvitacionPendiente() async {
    setState(() => _cargandoInvitacion = true);
    try {
      final invitacion = await _rolService.verificarInvitacionPendiente();

      if (invitacion != null) {
        setState(() {
          _emailInvitacion = invitacion['email'];
          _nuevoRol = invitacion['nuevoRol'];
          if (invitacion['expiracion'] != null) {
            _fechaExpiracion = DateTime.parse(invitacion['expiracion']);
            _tiempoRestante = _fechaExpiracion!.difference(DateTime.now());
            _codigoExpirado = _tiempoRestante.isNegative;
            if (!_codigoExpirado) {
              _iniciarContador();
            }
          }
        });
        _startAnimations();
      } else {
        _mostrarMensaje("No tienes invitaciones pendientes");
        Navigator.of(context).pop();
      }
    } catch (e) {
      _mostrarMensaje("Error al verificar invitación: $e", error: true);
      Navigator.of(context).pop();
    }
    setState(() => _cargandoInvitacion = false);
  }

  Future<void> _confirmarInvitacion() async {
    final codigo = _codigoController.text.trim();
    
    if (codigo.isEmpty || codigo.length != 6) {
      _mostrarMensaje("Debes ingresar el código completo de 6 dígitos", error: true);
      _shakeFields();
      return;
    }

    if (_nuevoRol == null) {
      _mostrarMensaje("Error: no se recibió el rol de la invitación", error: true);
      return;
    }

    HapticFeedback.lightImpact();
    _buttonController.forward().then((_) => _buttonController.reverse());

    setState(() => _loading = true);
    try {
      await _rolService.confirmarCodigoRol(codigo);
      
      _showNotification(
        message: "✨ Invitación aceptada",
        subtitle: "Bienvenido a tu nuevo rol",
        type: NotificationType.success,
        icon: Icons.verified_rounded,
      );

      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => BienvenidaAdminScreen(rol: _nuevoRol!),
          ),
        );
      }
    } catch (e) {
      _mostrarMensaje("Error al confirmar: $e", error: true);
      _shakeFields();
    }
    setState(() => _loading = false);
  }

  void _showNotification({
    required String message,
    String? subtitle,
    required NotificationType type,
    required IconData icon,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (_) => _NotificationWidget(
        message: message,
        subtitle: subtitle,
        type: type,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _timerController.dispose();
    _codigoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    final colorScheme = _AppColorScheme.of(context, isDark);

    if (_cargandoInvitacion) {
      return Scaffold(
        backgroundColor: colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                "Verificando invitación...",
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: _buildAppBar(colorScheme),
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 20 : 0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      _buildHeroIllustration(size, colorScheme),
                      const SizedBox(height: 40),
                      _buildMainCard(colorScheme),
                      const SizedBox(height: 32),
                      _buildBackButton(colorScheme),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(_AppColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onBackground,
          size: 22,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        tooltip: 'Volver',
      ),
      title: Text(
        "Invitación de Rol",
        style: TextStyle(
          color: colorScheme.onBackground,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: colorScheme.isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: colorScheme.isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Widget _buildHeroIllustration(Size size, _AppColorScheme colorScheme) {
    return Hero(
      tag: 'role_invitation_illustration',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: size.width * 0.5,
        height: size.width * 0.5,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.15),
              colorScheme.primary.withOpacity(0.05),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.admin_panel_settings_rounded,
            size: size.width * 0.2,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(_AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = _shakeAnimation.value * 8;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(colorScheme.isDark ? 0.3 : 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
                if (!colorScheme.isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 50,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitle(colorScheme),
                const SizedBox(height: 12),
                _buildRoleInfo(colorScheme),
                const SizedBox(height: 24),
                _buildTimerSection(colorScheme),
                const SizedBox(height: 36),
                _buildPinField(colorScheme),
                const SizedBox(height: 36),
                _buildSubmitButton(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(_AppColorScheme colorScheme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: "Confirma tu ",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: "invitación",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleInfo(_AppColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                "Nuevo Rol:",
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _nuevoRol ?? 'No disponible',
            style: TextStyle(
              fontSize: 18,
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerSection(_AppColorScheme colorScheme) {
    if (_fechaExpiracion == null) return const SizedBox.shrink();
    
    String contadorTexto = _tiempoRestante.inSeconds > 0
        ? "${_tiempoRestante.inMinutes.remainder(60).toString().padLeft(2, '0')}:${_tiempoRestante.inSeconds.remainder(60).toString().padLeft(2, '0')}"
        : "00:00";

    final isUrgent = _tiempoRestante.inSeconds <= 60;

    return AnimatedBuilder(
      animation: _timerPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isUrgent ? _timerPulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isUrgent 
                  ? colorScheme.error.withOpacity(0.1)
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isUrgent 
                    ? colorScheme.error.withOpacity(0.3)
                    : colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  color: isUrgent ? colorScheme.error : colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Tiempo restante:",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  contadorTexto,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isUrgent ? colorScheme.error : colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPinField(_AppColorScheme colorScheme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 112;
    final fieldWidth = (availableWidth - 50) / 6;
    final fieldHeight = fieldWidth * 1.2;
    
    final finalFieldWidth = fieldWidth.clamp(40.0, 60.0);
    final finalFieldHeight = fieldHeight.clamp(50.0, 70.0);
    
    return Column(
      children: [
        Text(
          "Ingresa el código de confirmación",
          style: TextStyle(
            fontSize: 16,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _codigoController.text.isEmpty ? _pulseAnimation.value : 1.0,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: availableWidth,
                ),
                child: PinCodeTextField(
                  appContext: context,
                  length: 6,
                  controller: _codigoController,
                  animationType: AnimationType.scale,
                  autoFocus: true,
                  keyboardType: TextInputType.number,
                  enableActiveFill: true,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  enabled: !_codigoExpirado && !_loading,
                  textStyle: TextStyle(
                    fontSize: finalFieldWidth > 45 ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color: _codigoExpirado 
                        ? colorScheme.onSurfaceVariant.withOpacity(0.5)
                        : colorScheme.onSurface,
                  ),
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(16),
                    fieldHeight: finalFieldHeight,
                    fieldWidth: finalFieldWidth,
                    borderWidth: 2,
                    activeColor: colorScheme.primary,
                    inactiveColor: _codigoExpirado 
                        ? colorScheme.outline.withOpacity(0.2)
                        : colorScheme.outline.withOpacity(0.3),
                    selectedColor: colorScheme.primary,
                    selectedFillColor: colorScheme.primary.withOpacity(0.08),
                    inactiveFillColor: _codigoExpirado 
                        ? colorScheme.surfaceVariant.withOpacity(0.5)
                        : colorScheme.surfaceVariant,
                    activeFillColor: colorScheme.primary.withOpacity(0.12),
                    disabledColor: colorScheme.outline.withOpacity(0.2),
                    errorBorderColor: colorScheme.error,
                  ),
                  onChanged: (value) {
                    // Auto-verificar cuando se complete el código
                    if (value.length == 6 && !_codigoExpirado) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_codigoController.text.length == 6) {
                          _confirmarInvitacion();
                        }
                      });
                    }
                  },
                  onCompleted: (value) {
                    HapticFeedback.lightImpact();
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(_AppColorScheme colorScheme) {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: (_codigoExpirado || _loading) ? null : _confirmarInvitacion,
          style: ElevatedButton.styleFrom(
            backgroundColor: _codigoExpirado 
                ? colorScheme.onSurfaceVariant.withOpacity(0.3)
                : _loading 
                    ? colorScheme.primary.withOpacity(0.7)
                    : colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: (_codigoExpirado || _loading) ? 0 : 12,
            shadowColor: colorScheme.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _loading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Confirmando...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: ValueKey(_codigoExpirado ? 'expired' : 'accept'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _codigoExpirado ? Icons.timer_off_rounded : Icons.verified_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _codigoExpirado ? "Código expirado" : "Aceptar invitación",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton(_AppColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.arrow_back_rounded,
        color: colorScheme.onSurfaceVariant,
        size: 18,
      ),
      label: Text(
        "Volver atrás",
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: 15,
          letterSpacing: 0.1,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// Sistema de colores reutilizado
class _AppColorScheme {
  final Color primary;
  final Color onPrimary;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color surfaceVariant;
  final Color background;
  final Color onBackground;
  final Color error;
  final Color outline;
  final bool isDark;

  const _AppColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.surfaceVariant,
    required this.background,
    required this.onBackground,
    required this.error,
    required this.outline,
    required this.isDark,
  });

  static _AppColorScheme of(BuildContext context, bool isDark) {
    if (isDark) {
      return const _AppColorScheme(
        primary: Color(0xFFFF6B6B),
        onPrimary: Colors.white,
        surface: Color(0xFF1E1E1E),
        onSurface: Colors.white,
        onSurfaceVariant: Color(0xFFB0B0B0),
        surfaceVariant: Color(0xFF2A2A2A),
        background: Color(0xFF121212),
        onBackground: Colors.white,
        error: Color(0xFFFF5252),
        outline: Color(0xFF404040),
        isDark: true,
      );
    } else {
      return const _AppColorScheme(
        primary: Color(0xFFBE0C0C),
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A1A),
        onSurfaceVariant: Color(0xFF6B6B6B),
        surfaceVariant: Color(0xFFF5F5F5),
        background: Color(0xFFF8FAFC),
        onBackground: Color(0xFF1A1A1A),
        error: Color(0xFFD32F2F),
        outline: Color(0xFFE0E0E0),
        isDark: false,
      );
    }
  }
}

enum NotificationType { success, error, warning, info }

class _NotificationWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final NotificationType type;
  final IconData icon;
  final VoidCallback onDismiss;

  const _NotificationWidget({
    required this.message,
    this.subtitle,
    required this.type,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  Color get backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF10B981);
      case NotificationType.error:
        return const Color(0xFFEF4444);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.info:
        return const Color(0xFF3B82F6);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 20,
      right: 20,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                onPanUpdate: (details) {
                  // Permitir deslizar para cerrar
                  if (details.delta.dy < -2) {
                    widget.onDismiss();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Barra de progreso para mostrar tiempo restante
                      const SizedBox(height: 12),
                      Container(
                        height: 3,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.0, // Se animará automáticamente
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}