import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/password_service.dart';

class VerificarCodigoScreen extends StatefulWidget {
  final String email;
  const VerificarCodigoScreen({super.key, required this.email});

  @override
  State<VerificarCodigoScreen> createState() => _VerificarCodigoScreenState();
}

class _VerificarCodigoScreenState extends State<VerificarCodigoScreen>
    with TickerProviderStateMixin {
  final PasswordService _passwordService = PasswordService();
  final TextEditingController _codigoController = TextEditingController();
  
  bool _isLoading = false;
  bool _canResend = true;
  int _resendCountdown = 0;
  String? _errorMessage;
  int _attemptsRemaining = 3;
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  
  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialCountdown();
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

    // Iniciar animaciones con delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });

    // Pulso continuo para el campo PIN
    _pulseController.repeat(reverse: true);
  }

  void _startInitialCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60;
    });

    final timer = Stream.periodic(const Duration(seconds: 1), (i) => 60 - i - 1)
        .take(60)
        .listen((count) {
      if (mounted) {
        setState(() {
          _resendCountdown = count;
          if (count == 0) {
            _canResend = true;
          }
        });
      }
    });

    Future.delayed(const Duration(seconds: 60), () {
      timer.cancel();
    });
  }

  void _shakeFields() {
    HapticFeedback.heavyImpact();
    _shakeController.reset();
    _shakeController.forward();
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    HapticFeedback.lightImpact();
    
    try {
      // Aquí llamarías al servicio para reenviar el código
      _showNotification(
        message: "Código reenviado",
        subtitle: "Revisa tu bandeja de entrada y spam",
        type: NotificationType.success,
        icon: Icons.mark_email_read_outlined,
      );
      
      _startInitialCountdown();
      
    } catch (e) {
      _showNotification(
        message: "Error al reenviar",
        subtitle: "Intenta nuevamente en un momento",
        type: NotificationType.error,
        icon: Icons.error_outline,
      );
    }
  }

  Future<void> _verificarCodigo() async {
    final codigo = _codigoController.text.trim();

    if (codigo.isEmpty || codigo.length != 6) {
      setState(() {
        _errorMessage = "Ingresa el código completo de 6 dígitos";
      });
      _shakeFields();
      return;
    }

    HapticFeedback.lightImpact();
    _buttonController.forward().then((_) => _buttonController.reverse());
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _passwordService.verificarCodigo(widget.email, codigo);
      final msg = _passwordService.message;

      if (success) {
        _showNotification(
          message: "✨ Código verificado",
          subtitle: "Redirigiendo para crear nueva contraseña",
          type: NotificationType.success,
          icon: Icons.verified_rounded,
        );
        
        HapticFeedback.mediumImpact();
        
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          Navigator.pushNamed(
            context,
            '/new-password',
            arguments: {
              'token': codigo,
              'email': widget.email,
            },
          );
        }
      } else {
        _attemptsRemaining--;
        
        if (_attemptsRemaining <= 0) {
          _showNotification(
            message: "Demasiados intentos fallidos",
            subtitle: "Por favor, solicita un nuevo código",
            type: NotificationType.error,
            icon: Icons.block_rounded,
          );
          
          // Limpiar código y deshabilitar temporalmente
          _codigoController.clear();
          setState(() {
            _attemptsRemaining = 3;
          });
        } else {
          setState(() {
            _errorMessage = "Código incorrecto. ${_attemptsRemaining} intentos restantes";
          });
          
          _showNotification(
            message: msg ?? "Código incorrecto",
            subtitle: "Te quedan $_attemptsRemaining intentos",
            type: NotificationType.warning,
            icon: Icons.warning_amber_rounded,
          );
        }
        
        HapticFeedback.heavyImpact();
        _shakeFields();
        
        // Limpiar código para nuevo intento
        _codigoController.clear();
      }
    } catch (e) {
      _showNotification(
        message: "Error de conexión",
        subtitle: "Verifica tu internet e intenta nuevamente",
        type: NotificationType.error,
        icon: Icons.cloud_off_rounded,
      );
      _shakeFields();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    _fadeController.dispose();
    _slideController.dispose();
    _buttonController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
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
        "Verificación",
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
      tag: 'verification_illustration',
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
            Icons.verified_user_rounded,
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
                _buildSubtitle(colorScheme),
                const SizedBox(height: 36),
                _buildPinField(colorScheme),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(colorScheme),
                ],
                const SizedBox(height: 36),
                _buildSubmitButton(colorScheme),
                const SizedBox(height: 24),
                _buildResendSection(colorScheme),
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
            text: "Ingresa el ",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: "código",
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

  Widget _buildSubtitle(_AppColorScheme colorScheme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: "Enviamos un código de 6 dígitos a\n",
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          TextSpan(
            text: widget.email,
            style: TextStyle(
              fontSize: 16,
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField(_AppColorScheme colorScheme) {
    // Calcular tamaños responsivos para evitar overflow
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 112; // 24*2 padding + 32*2 card padding
    final fieldWidth = (availableWidth - 50) / 6; // 50 para espacios entre campos
    final fieldHeight = fieldWidth * 1.2;
    
    // Asegurar tamaños mínimos y máximos
    final finalFieldWidth = fieldWidth.clamp(40.0, 60.0);
    final finalFieldHeight = fieldHeight.clamp(50.0, 70.0);
    
    return AnimatedBuilder(
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
              textStyle: TextStyle(
                fontSize: finalFieldWidth > 45 ? 20 : 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
              pinTheme: PinTheme(
                shape: PinCodeFieldShape.box,
                borderRadius: BorderRadius.circular(16),
                fieldHeight: finalFieldHeight,
                fieldWidth: finalFieldWidth,
                borderWidth: 2,
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.outline.withOpacity(0.3),
                selectedColor: colorScheme.primary,
                selectedFillColor: colorScheme.primary.withOpacity(0.08),
                inactiveFillColor: colorScheme.surfaceVariant,
                activeFillColor: colorScheme.primary.withOpacity(0.12),
                disabledColor: colorScheme.outline.withOpacity(0.2),
                errorBorderColor: colorScheme.error,
              ),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
                
                // Auto-verificar cuando se complete el código
                if (value.length == 6) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_codigoController.text.length == 6) {
                      _verificarCodigo();
                    }
                  });
                }
              },
              onCompleted: (value) {
                HapticFeedback.lightImpact();
              },
              validator: (value) {
                if (value == null || value.length != 6) {
                  return "Código incompleto";
                }
                return null;
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorMessage(_AppColorScheme colorScheme) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.error.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 20,
            color: colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(_AppColorScheme colorScheme) {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: 58,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verificarCodigo,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isLoading 
                ? colorScheme.primary.withOpacity(0.7)
                : colorScheme.primary,
            foregroundColor: Colors.white,
            elevation: _isLoading ? 0 : 12,
            shadowColor: colorScheme.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: _isLoading
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
                        "Verificando...",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('verify'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "Verificar código",
                        style: TextStyle(
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

  Widget _buildResendSection(_AppColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          "¿No recibiste el código?",
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        if (_canResend)
          GestureDetector(
            onTap: _resendCode,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Reenviar código",
                    style: TextStyle(
                      fontSize: 15,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  "Reenviar en ${_resendCountdown}s",
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
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

// Reutilizamos el sistema de colores de la pantalla anterior
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