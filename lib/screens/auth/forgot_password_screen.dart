import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/password_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final PasswordService passwordService = PasswordService();
  final TextEditingController emailController = TextEditingController();
  final FocusNode emailFocusNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _isEmailValid = false;
  String? _emailError;
  bool _canResend = true;
  int _resendCountdown = 0;
  
  // Controladores de animación
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _buttonController;
  late AnimationController _shakeController;
  late AnimationController _progressController;
  
  // Animaciones
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _buttonScale;
  late Animation<double> _shakeAnimation;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _setupEmailListener();
  }

  void _setupAnimations() {
    // Controladores básicos
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animaciones
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));

    _buttonScale = Tween<double>(
      begin: 1.0,
      end: 0.96,
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

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // Ejecutar animaciones de entrada con delay escalonado
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
  }

  void _setupEmailListener() {
    emailController.addListener(() {
      final email = emailController.text.trim();
      final isValid = _validateEmail(email);
      if (isValid != _isEmailValid) {
        setState(() {
          _isEmailValid = isValid;
          // Solo mostrar error si hay texto y no es válido
          _emailError = email.isNotEmpty && !isValid ? 'Formato de correo inválido' : null;
        });
      }
    });
  }

  bool _validateEmail(String email) {
    if (email.isEmpty) return false;
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  void _shakeField() {
    HapticFeedback.heavyImpact();
    _shakeController.reset();
    _shakeController.forward();
  }

  void _startResendCountdown() {
    setState(() {
      _canResend = false;
      _resendCountdown = 60; // 60 segundos
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

    // Limpiar timer si el widget se desmonta
    Future.delayed(const Duration(seconds: 60), () {
      timer.cancel();
    });
  }

  Future<void> _sendResetEmail() async {
    final email = emailController.text.trim();

    // Validaciones con mejor UX
    if (email.isEmpty) {
      _showFieldError("Este campo es obligatorio");
      _shakeField();
      emailFocusNode.requestFocus();
      return;
    }

    if (!_isEmailValid) {
      _showFieldError("Por favor, ingresa un correo válido");
      _shakeField();
      emailFocusNode.requestFocus();
      return;
    }

    // Feedback háptico y visual
    HapticFeedback.lightImpact();
    _buttonController.forward().then((_) => _buttonController.reverse());
    
    setState(() => _isLoading = true);
    _progressController.forward();

    try {
      final success = await passwordService.sendPasswordResetEmail(email);
      final backendMsg = passwordService.message;

      if (success) {
        // Éxito - mostrar notificación y iniciar countdown
        _showNotification(
          message: backendMsg ?? "✨ Código enviado exitosamente",
          subtitle: "Revisa tu bandeja de entrada y spam",
          type: NotificationType.success,
          icon: Icons.mark_email_read_outlined,
        );
        
        HapticFeedback.mediumImpact();
        _startResendCountdown();
        
        // Delay más corto para mejor UX
        await Future.delayed(const Duration(milliseconds: 1800));
        if (mounted) {
          Navigator.pushNamed(context, '/verificar-codigo', arguments: {
            'email': email,
          });
        }
      } else {
        _showNotification(
          message: "Cuenta no encontrada",
          subtitle: backendMsg ?? "Verifica el correo e intenta nuevamente",
          type: NotificationType.error,
          icon: Icons.person_search_rounded,
        );
        HapticFeedback.heavyImpact();
        _shakeField();
      }
    } catch (e) {
      _showNotification(
        message: "Error de conexión",
        subtitle: "Verifica tu internet e intenta nuevamente",
        type: NotificationType.error,
        icon: Icons.cloud_off_rounded,
      );
      HapticFeedback.heavyImpact();
      _shakeField();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _progressController.reverse();
      }
    }
  }

  void _showFieldError(String message) {
    setState(() {
      _emailError = message;
    });
    
    // Auto-limpiar error después de 4 segundos
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _emailError == message) {
        setState(() {
          _emailError = _isEmailValid ? null : (emailController.text.isNotEmpty ? 'Formato de correo inválido' : null);
        });
      }
    });
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
    _progressController.dispose();
    emailController.dispose();
    emailFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    // Sistema de colores mejorado
    final colorScheme = _AppColorScheme.of(context, isDark);
    
    // Sistema responsive
    final responsive = _ResponsiveHelper(size);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.background,
        resizeToAvoidBottomInset: true,
        appBar: _buildAppBar(colorScheme, responsive),
        body: SafeArea(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.only(bottom: bottomInset > 0 ? 20 : 0),
            child: responsive.isTablet || responsive.isDesktop
                ? _buildDesktopLayout(colorScheme, responsive)
                : _buildMobileLayout(colorScheme, responsive),
          ),
        ),
      ),
    );
  }

  // Layout para móviles
  Widget _buildMobileLayout(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: responsive.padding),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: responsive.verticalSpacing),
              _buildHeroIllustration(colorScheme, responsive),
              SizedBox(height: responsive.verticalSpacing * 1.5),
              _buildMainCard(colorScheme, responsive),
              SizedBox(height: responsive.verticalSpacing),
              _buildBackButton(colorScheme, responsive),
              SizedBox(height: responsive.verticalSpacing * 1.5),
            ],
          ),
        ),
      ),
    );
  }

  // Layout para tablets y desktop
  Widget _buildDesktopLayout(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: responsive.maxCardWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: responsive.padding),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Card(
                elevation: responsive.isDesktop ? 24 : 16,
                shadowColor: colorScheme.primary.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(responsive.borderRadius * 1.5),
                ),
                color: colorScheme.surface,
                child: Padding(
                  padding: EdgeInsets.all(responsive.cardPadding),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: responsive.verticalSpacing),
                      _buildHeroIllustration(colorScheme, responsive),
                      SizedBox(height: responsive.verticalSpacing * 1.5),
                      _buildMainCard(colorScheme, responsive, isInsideCard: true),
                      SizedBox(height: responsive.verticalSpacing),
                      _buildBackButton(colorScheme, responsive),
                      SizedBox(height: responsive.verticalSpacing),
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

  PreferredSizeWidget _buildAppBar(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: colorScheme.onBackground,
          size: responsive.iconSize,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.pop(context);
        },
        tooltip: 'Volver',
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: colorScheme.isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: colorScheme.isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  Widget _buildHeroIllustration(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return Hero(
      tag: 'password_illustration',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: responsive.heroSize,
        height: responsive.heroSize,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.primary.withOpacity(0.05),
            ],
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.1),
              blurRadius: responsive.shadowBlur,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.shield_outlined,
            size: responsive.heroIconSize,
            color: colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildMainCard(_AppColorScheme colorScheme, _ResponsiveHelper responsive, {bool isInsideCard = false}) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = _shakeAnimation.value * 10;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.cardPadding),
            decoration: isInsideCard ? null : BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(responsive.borderRadius),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(colorScheme.isDark ? 0.3 : 0.08),
                  blurRadius: responsive.shadowBlur,
                  offset: const Offset(0, 10),
                  spreadRadius: 0,
                ),
                if (!colorScheme.isDark)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: responsive.shadowBlur * 2,
                    offset: const Offset(0, 20),
                  ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTitle(colorScheme, responsive),
                  SizedBox(height: responsive.verticalSpacing * 0.5),
                  _buildSubtitle(colorScheme, responsive),
                  SizedBox(height: responsive.verticalSpacing * 1.5),
                  _buildEmailField(colorScheme, responsive),
                  SizedBox(height: responsive.verticalSpacing * 1.5),
                  _buildSubmitButton(colorScheme, responsive),
                  if (!_canResend && _resendCountdown > 0) ...[
                    SizedBox(height: responsive.verticalSpacing),
                    _buildResendInfo(colorScheme, responsive),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Recuperar ",
            style: TextStyle(
              fontSize: responsive.titleSize,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              height: 1.2,
              letterSpacing: -0.5,
            ),
          ),
          TextSpan(
            text: "contraseña",
            style: TextStyle(
              fontSize: responsive.titleSize,
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

  Widget _buildSubtitle(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return Text(
      "Te enviaremos un código de verificación seguro para restablecer tu contraseña.",
      style: TextStyle(
        fontSize: responsive.bodySize,
        color: colorScheme.onSurfaceVariant,
        height: 1.5,
        letterSpacing: 0.1,
      ),
    );
  }

  Widget _buildEmailField(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.email_outlined,
              size: responsive.smallIconSize,
              color: colorScheme.primary,
            ),
            SizedBox(width: responsive.horizontalSpacing * 0.5),
            Text(
              "Correo electrónico",
              style: TextStyle(
                fontSize: responsive.labelSize,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.verticalSpacing * 0.5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(responsive.inputRadius),
            border: Border.all(
              color: _emailError != null
                  ? colorScheme.error.withOpacity(0.6)
                  : emailFocusNode.hasFocus
                      ? colorScheme.primary.withOpacity(0.6)
                      : _isEmailValid
                          ? Colors.green.withOpacity(0.6)
                          : Colors.transparent,
              width: 2,
            ),
          ),
          child: TextFormField(
            controller: emailController,
            focusNode: emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
            style: TextStyle(
              fontSize: responsive.inputTextSize,
              color: colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
            decoration: InputDecoration(
              hintText: 'ejemplo@correo.com',
              hintStyle: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: responsive.inputTextSize,
              ),
              filled: true,
              fillColor: colorScheme.isDark 
                  ? colorScheme.onSurface.withOpacity(0.05)
                  : colorScheme.surfaceVariant,
              contentPadding: EdgeInsets.symmetric(
                horizontal: responsive.inputPadding,
                vertical: responsive.inputPadding * 0.9,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.inputRadius),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.inputRadius),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(responsive.inputRadius),
                borderSide: BorderSide.none,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(
                  left: responsive.inputPadding,
                  right: responsive.inputPadding * 0.6,
                ),
                child: Icon(
                  Icons.alternate_email_rounded,
                  color: emailFocusNode.hasFocus 
                      ? colorScheme.primary 
                      : colorScheme.onSurfaceVariant.withOpacity(0.6),
                  size: responsive.iconSize,
                ),
              ),
              suffixIcon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: emailController.text.isNotEmpty
                    ? Container(
                        key: ValueKey(_isEmailValid),
                        margin: EdgeInsets.only(right: responsive.inputPadding * 0.6),
                        padding: EdgeInsets.all(responsive.inputPadding * 0.4),
                        decoration: BoxDecoration(
                          color: (_isEmailValid ? Colors.green : colorScheme.error).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _isEmailValid
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          color: _isEmailValid
                              ? Colors.green[600]
                              : colorScheme.error,
                          size: responsive.smallIconSize,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _emailError != null ? null : 0,
          child: _emailError != null
              ? Padding(
                  padding: EdgeInsets.only(top: responsive.verticalSpacing * 0.4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: responsive.smallIconSize,
                        color: colorScheme.error,
                      ),
                      SizedBox(width: responsive.horizontalSpacing * 0.5),
                      Expanded(
                        child: Text(
                          _emailError!,
                          style: TextStyle(
                            fontSize: responsive.captionSize,
                            color: colorScheme.error,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ],
    );
  }

  Widget _buildSubmitButton(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return ScaleTransition(
      scale: _buttonScale,
      child: SizedBox(
        width: double.infinity,
        height: responsive.buttonHeight,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: ElevatedButton(
            onPressed: _isLoading || !_canResend ? null : () async {
              _buttonController.forward().then((_) {
                _buttonController.reverse();
              });
              await _sendResetEmail();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isLoading 
                  ? colorScheme.primary.withOpacity(0.7)
                  : colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: _isLoading ? 0 : (responsive.isDesktop ? 16 : 12),
              shadowColor: colorScheme.primary.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(responsive.inputRadius),
              ),
              padding: EdgeInsets.zero,
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: _isLoading
                  ? Row(
                      key: const ValueKey('loading'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: responsive.loadingSize,
                          height: responsive.loadingSize,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ),
                        SizedBox(width: responsive.horizontalSpacing * 0.75),
                        Text(
                          "Enviando código...",
                          style: TextStyle(
                            fontSize: responsive.buttonTextSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      key: const ValueKey('send'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send_rounded,
                          size: responsive.iconSize,
                          color: Colors.white,
                        ),
                        SizedBox(width: responsive.horizontalSpacing * 0.625),
                        Text(
                          "Enviar código",
                          style: TextStyle(
                            fontSize: responsive.buttonTextSize,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendInfo(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.inputPadding),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            size: responsive.iconSize,
            color: colorScheme.primary,
          ),
          SizedBox(width: responsive.horizontalSpacing * 0.625),
          Expanded(
            child: Text(
              "Podrás solicitar un nuevo código en ${_resendCountdown}s",
              style: TextStyle(
                fontSize: responsive.captionSize,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(_AppColorScheme colorScheme, _ResponsiveHelper responsive) {
    return TextButton.icon(
      onPressed: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      icon: Icon(
        Icons.arrow_back_rounded,
        color: colorScheme.onSurfaceVariant,
        size: responsive.iconSize,
      ),
      label: Text(
        "Volver al inicio de sesión",
        style: TextStyle(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
          fontSize: responsive.labelSize,
          letterSpacing: 0.1,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.inputPadding,
          vertical: responsive.inputPadding * 0.7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
        ),
      ),
    );
  }
}

// Helper para responsive design
class _ResponsiveHelper {
  final Size size;
  
  _ResponsiveHelper(this.size);
  
  // Breakpoints
  bool get isMobile => size.width < 600;
  bool get isTablet => size.width >= 600 && size.width < 1024;
  bool get isDesktop => size.width >= 1024;
  
  // Dimensiones adaptativas
  double get padding => isMobile ? 24 : (isTablet ? 32 : 40);
  double get cardPadding => isMobile ? 24 : (isTablet ? 32 : 40);
  double get verticalSpacing => isMobile ? 20 : (isTablet ? 24 : 28);
  double get horizontalSpacing => isMobile ? 16 : (isTablet ? 20 : 24);
  
  // Tamaños de fuente
  double get titleSize => isMobile ? 28 : (isTablet ? 32 : 36);
  double get bodySize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get labelSize => isMobile ? 15 : (isTablet ? 16 : 17);
  double get buttonTextSize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get inputTextSize => isMobile ? 16 : (isTablet ? 17 : 18);
  double get captionSize => isMobile ? 13 : (isTablet ? 14 : 15);
  
  // Tamaños de iconos
  double get iconSize => isMobile ? 20 : (isTablet ? 22 : 24);
  double get smallIconSize => isMobile ? 16 : (isTablet ? 18 : 20);
  double get loadingSize => isMobile ? 18 : (isTablet ? 20 : 22);
  
  // Dimensiones de componentes
  double get buttonHeight => isMobile ? 54 : (isTablet ? 58 : 62);
  double get inputPadding => isMobile ? 18 : (isTablet ? 20 : 22);
  double get borderRadius => isMobile ? 16 : (isTablet ? 18 : 20);
  double get inputRadius => isMobile ? 14 : (isTablet ? 16 : 18);
  
  // Hero illustration
  double get heroSize => isMobile ? size.width * 0.45 : (isTablet ? 200 : 240);
  double get heroIconSize => isMobile ? size.width * 0.18 : (isTablet ? 80 : 96);
  
  // Sombras
  double get shadowBlur => isMobile ? 20 : (isTablet ? 25 : 30);
  
  // Ancho máximo para desktop
  double get maxCardWidth => isDesktop ? 480 : double.infinity;
}

// Sistema de colores mejorado
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

  IconData get iconData {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final responsive = _ResponsiveHelper(size);
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: responsive.padding * 0.8,
      right: responsive.padding * 0.8,
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
                  padding: EdgeInsets.all(responsive.inputPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.3),
                        blurRadius: responsive.shadowBlur,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: responsive.shadowBlur * 2,
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
                            padding: EdgeInsets.all(responsive.horizontalSpacing * 0.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: responsive.iconSize,
                            ),
                          ),
                          SizedBox(width: responsive.horizontalSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: responsive.bodySize,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  SizedBox(height: responsive.verticalSpacing * 0.2),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: responsive.captionSize,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: responsive.horizontalSpacing * 0.5),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: EdgeInsets.all(responsive.horizontalSpacing * 0.25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(responsive.horizontalSpacing * 0.5),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: responsive.smallIconSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Barra de progreso para mostrar tiempo restante
                      SizedBox(height: responsive.verticalSpacing * 0.6),
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