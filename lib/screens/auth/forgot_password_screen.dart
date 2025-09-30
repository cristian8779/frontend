import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/password_service.dart';
import '../../theme/forgot_password/responsive_helper.dart';
import '../../theme/forgot_password/color_scheme.dart';
import '../../theme/forgot_password/notification_widget.dart';
import '../../theme/forgot_password/widget_styles.dart';

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
      builder: (_) => NotificationWidget(
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
    
    // Sistema de colores y responsive
    final colorScheme = AppColorScheme.of(context, isDark);
    final responsive = ResponsiveHelper(size);

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
  Widget _buildMobileLayout(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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
  Widget _buildDesktopLayout(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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

  PreferredSizeWidget _buildAppBar(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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

  Widget _buildHeroIllustration(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return Hero(
      tag: 'password_illustration',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        width: responsive.heroSize,
        height: responsive.heroSize,
        decoration: ForgotPasswordStyles.heroDecoration(colorScheme, responsive),
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

  Widget _buildMainCard(AppColorScheme colorScheme, ResponsiveHelper responsive, {bool isInsideCard = false}) {
    return AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        final shake = _shakeAnimation.value * 10;
        return Transform.translate(
          offset: Offset(shake, 0),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.cardPadding),
            decoration: isInsideCard ? null : ForgotPasswordStyles.mainCardDecoration(colorScheme, responsive),
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

  Widget _buildTitle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: "Recuperar ",
            style: ForgotPasswordStyles.titleStyle(colorScheme, responsive),
          ),
          TextSpan(
            text: "contraseña",
            style: ForgotPasswordStyles.titlePrimaryStyle(colorScheme, responsive),
          ),
        ],
      ),
    );
  }

  Widget _buildSubtitle(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return Text(
      "Te enviaremos un código de verificación seguro para restablecer tu contraseña.",
      style: ForgotPasswordStyles.subtitleStyle(colorScheme, responsive),
    );
  }

  Widget _buildEmailField(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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
              style: ForgotPasswordStyles.labelStyle(colorScheme, responsive),
            ),
          ],
        ),
        SizedBox(height: responsive.verticalSpacing * 0.5),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: ForgotPasswordStyles.inputFieldDecoration(
            colorScheme, 
            responsive,
            hasError: _emailError != null,
            hasFocus: emailFocusNode.hasFocus,
            isValid: _isEmailValid,
          ),
          child: TextFormField(
            controller: emailController,
            focusNode: emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _sendResetEmail(),
            style: ForgotPasswordStyles.inputTextStyle(colorScheme, responsive),
            decoration: ForgotPasswordStyles.inputDecoration(
              colorScheme, 
              responsive,
              hintText: 'ejemplo@correo.com',
              prefixIcon: Icons.alternate_email_rounded,
            ).copyWith(
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
                        decoration: ForgotPasswordStyles.emailValidityDecoration(_isEmailValid, responsive),
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
                          style: ForgotPasswordStyles.errorTextStyle(colorScheme, responsive),
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

  Widget _buildSubmitButton(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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
            style: ForgotPasswordStyles.primaryButtonStyle(colorScheme, responsive, isLoading: _isLoading),
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
                          style: ForgotPasswordStyles.buttonTextStyle(colorScheme, responsive).copyWith(
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
                          style: ForgotPasswordStyles.buttonTextStyle(colorScheme, responsive),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendInfo(AppColorScheme colorScheme, ResponsiveHelper responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.inputPadding),
      decoration: ForgotPasswordStyles.resendInfoDecoration(colorScheme, responsive),
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
              style: ForgotPasswordStyles.resendInfoStyle(colorScheme, responsive),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton(AppColorScheme colorScheme, ResponsiveHelper responsive) {
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
        style: ForgotPasswordStyles.backButtonTextStyle(colorScheme, responsive),
      ),
      style: ForgotPasswordStyles.backButtonButtonStyle(colorScheme, responsive),
    );
  }
}