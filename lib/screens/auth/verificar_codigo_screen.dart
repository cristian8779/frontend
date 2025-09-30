import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../services/password_service.dart';
import '../../theme/verificar_codigo/app_colors.dart';
import '../../theme/verificar_codigo/verificar_codigo_styles.dart';
import '../../theme/verificar_codigo/notification_widget.dart';

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
  int _attemptsRemaining = VerificarCodigoStyles.maxAttempts;
  
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
      duration: VerificarCodigoStyles.fadeAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: VerificarCodigoStyles.slideAnimationDuration,
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: VerificarCodigoStyles.buttonAnimationDuration,
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: VerificarCodigoStyles.shakeAnimationDuration,
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: VerificarCodigoStyles.pulseAnimationDuration,
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
    Future.delayed(VerificarCodigoStyles.fadeAnimationDelay, () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(VerificarCodigoStyles.slideAnimationDelay, () {
      if (mounted) _slideController.forward();
    });

    // Pulso continuo para el campo PIN
    _pulseController.repeat(reverse: true);
  }

  void _startInitialCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = VerificarCodigoStyles.resendCountdownSeconds;
    });

    final timer = Stream.periodic(const Duration(seconds: 1), (i) => VerificarCodigoStyles.resendCountdownSeconds - i - 1)
        .take(VerificarCodigoStyles.resendCountdownSeconds)
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

    Future.delayed(const Duration(seconds: VerificarCodigoStyles.resendCountdownSeconds), () {
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

    if (codigo.isEmpty || codigo.length != VerificarCodigoStyles.pinLength) {
      setState(() {
        _errorMessage = "Ingresa el código completo de ${VerificarCodigoStyles.pinLength} dígitos";
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
            _attemptsRemaining = VerificarCodigoStyles.maxAttempts;
          });
        } else {
          setState(() {
            _errorMessage = "Código incorrecto. $_attemptsRemaining intentos restantes";
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
      builder: (_) => NotificationWidget(
        message: message,
        subtitle: subtitle,
        type: type,
        icon: icon,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(milliseconds: VerificarCodigoStyles.notificationDurationMs), () {
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
    
    final colorScheme = AppColorScheme.of(context, isDark);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        appBar: _buildAppBar(colorScheme),
        body: SafeArea(
          child: AnimatedContainer(
            duration: VerificarCodigoStyles.containerAnimationDuration,
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? VerificarCodigoStyles.spacingL : 0),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: VerificarCodigoStyles.spacingXL),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: VerificarCodigoStyles.spacingL),
                      _buildHeroIllustration(size, colorScheme),
                      const SizedBox(height: VerificarCodigoStyles.spacingXXXL),
                      _buildMainCard(colorScheme),
                      const SizedBox(height: VerificarCodigoStyles.spacingXXL),
                      _buildBackButton(colorScheme),
                      const SizedBox(height: VerificarCodigoStyles.spacingXXXL),
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

  PreferredSizeWidget _buildAppBar(AppColorScheme colorScheme) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onBackground,
          size: VerificarCodigoStyles.appBarIconSize,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        tooltip: 'Volver',
      ),
      title: Text(
        "Verificación",
        style: VerificarCodigoStyles.appBarTitleStyle(colorScheme),
      ),
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: colorScheme.isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: colorScheme.isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Widget _buildHeroIllustration(Size size, AppColorScheme colorScheme) {
    return Hero(
      tag: 'verification_illustration',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: size.width * VerificarCodigoStyles.heroIllustrationSize,
        height: size.width * VerificarCodigoStyles.heroIllustrationSize,
        decoration: VerificarCodigoStyles.heroIllustrationDecoration(colorScheme),
        child: Center(
          child: Icon(
            Icons.verified_user_rounded,
            size: size.width * VerificarCodigoStyles.heroIconSize,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(AppColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = _shakeAnimation.value * 8;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(VerificarCodigoStyles.mainCardPadding),
            decoration: VerificarCodigoStyles.mainCardDecoration(colorScheme),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildTitle(colorScheme),
                const SizedBox(height: VerificarCodigoStyles.spacingS),
                _buildSubtitle(colorScheme),
                const SizedBox(height: VerificarCodigoStyles.spacingXXXL - 4),
                _buildPinField(colorScheme),
                if (_errorMessage != null) ...[
                  const SizedBox(height: VerificarCodigoStyles.spacingM),
                  _buildErrorMessage(colorScheme),
                ],
                const SizedBox(height: VerificarCodigoStyles.spacingXXXL - 4),
                _buildSubmitButton(colorScheme),
                const SizedBox(height: VerificarCodigoStyles.spacingXL),
                _buildResendSection(colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(AppColorScheme colorScheme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: "Ingresa el ",
            style: VerificarCodigoStyles.titleTextStyle(colorScheme),
          ),
          TextSpan(
            text: "código",
            style: VerificarCodigoStyles.titleAccentTextStyle(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(AppColorScheme colorScheme) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          TextSpan(
            text: "Enviamos un código de ${VerificarCodigoStyles.pinLength} dígitos a\n",
            style: VerificarCodigoStyles.subtitleTextStyle(colorScheme),
          ),
          TextSpan(
            text: widget.email,
            style: VerificarCodigoStyles.emailTextStyle(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField(AppColorScheme colorScheme) {
    // Calcular tamaños responsivos para evitar overflow
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 112; // 24*2 padding + 32*2 card padding
    final fieldWidth = (availableWidth - VerificarCodigoStyles.fieldsSpacing) / VerificarCodigoStyles.pinLength;
    final fieldHeight = fieldWidth * VerificarCodigoStyles.fieldAspectRatio;
    
    // Asegurar tamaños mínimos y máximos
    final finalFieldWidth = fieldWidth.clamp(VerificarCodigoStyles.minFieldWidth, VerificarCodigoStyles.maxFieldWidth);
    final finalFieldHeight = fieldHeight.clamp(VerificarCodigoStyles.minFieldHeight, VerificarCodigoStyles.maxFieldHeight);
    
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
              length: VerificarCodigoStyles.pinLength,
              controller: _codigoController,
              animationType: AnimationType.scale,
              autoFocus: true,
              keyboardType: TextInputType.number,
              enableActiveFill: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textStyle: VerificarCodigoStyles.pinFieldTextStyle(colorScheme, finalFieldWidth),
              pinTheme: VerificarCodigoStyles.pinTheme(colorScheme, finalFieldWidth, finalFieldHeight),
              onChanged: (value) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
                
                // Auto-verificar cuando se complete el código
                if (value.length == VerificarCodigoStyles.pinLength) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (_codigoController.text.length == VerificarCodigoStyles.pinLength) {
                      _verificarCodigo();
                    }
                  });
                }
              },
              onCompleted: (value) {
                HapticFeedback.lightImpact();
              },
              validator: (value) {
                if (value == null || value.length != VerificarCodigoStyles.pinLength) {
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

  Widget _buildErrorMessage(AppColorScheme colorScheme) {
    return AnimatedContainer(
      duration: VerificarCodigoStyles.containerAnimationDuration,
      padding: const EdgeInsets.all(VerificarCodigoStyles.spacingM),
      decoration: VerificarCodigoStyles.errorMessageDecoration(colorScheme),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: VerificarCodigoStyles.errorIconSize,
            color: colorScheme.error,
          ),
          const SizedBox(width: VerificarCodigoStyles.spacingS),
          Expanded(
            child: Text(
              _errorMessage!,
              style: VerificarCodigoStyles.errorMessageTextStyle(colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppColorScheme colorScheme) {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: VerificarCodigoStyles.buttonHeight,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _verificarCodigo,
          style: VerificarCodigoStyles.elevatedButtonStyle(colorScheme, _isLoading),
          child: AnimatedSwitcher(
            duration: VerificarCodigoStyles.switcherAnimationDuration,
            child: _isLoading
                ? Row(
                    key: const ValueKey('loading'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: VerificarCodigoStyles.loadingIndicatorSize,
                        height: VerificarCodigoStyles.loadingIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(width: VerificarCodigoStyles.spacingS),
                      Text(
                        "Verificando...",
                        style: VerificarCodigoStyles.loadingTextStyle(),
                      ),
                    ],
                  )
                : Row(
                    key: const ValueKey('verify'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        size: VerificarCodigoStyles.buttonIconSize,
                        color: Colors.white,
                      ),
                      const SizedBox(width: VerificarCodigoStyles.spacingXS + 2),
                      Text(
                        "Verificar código",
                        style: VerificarCodigoStyles.buttonTextStyle(),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendSection(AppColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          "¿No recibiste el código?",
          style: VerificarCodigoStyles.resendQuestionStyle(colorScheme),
        ),
        const SizedBox(height: VerificarCodigoStyles.spacingS),
        if (_canResend)
          GestureDetector(
            onTap: _resendCode,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: VerificarCodigoStyles.spacingL, 
                vertical: VerificarCodigoStyles.spacingS
              ),
              decoration: VerificarCodigoStyles.resendButtonDecoration(colorScheme),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.refresh_rounded,
                    size: VerificarCodigoStyles.resendIconSize,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: VerificarCodigoStyles.spacingXS),
                  Text(
                    "Reenviar código",
                    style: VerificarCodigoStyles.resendButtonTextStyle(colorScheme),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: VerificarCodigoStyles.spacingL, 
              vertical: VerificarCodigoStyles.spacingS
            ),
            decoration: VerificarCodigoStyles.countdownContainerDecoration(colorScheme),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: VerificarCodigoStyles.countdownIconSize,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: VerificarCodigoStyles.spacingXS),
                Text(
                  "Reenviar en ${_resendCountdown}s",
                  style: VerificarCodigoStyles.countdownTextStyle(colorScheme),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildBackButton(AppColorScheme colorScheme) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.arrow_back_rounded,
        color: colorScheme.onSurfaceVariant,
        size: VerificarCodigoStyles.backIconSize,
      ),
      label: Text(
        "Volver atrás",
        style: VerificarCodigoStyles.backButtonTextStyle(colorScheme),
      ),
      style: VerificarCodigoStyles.textButtonStyle(),
    );
  }
}