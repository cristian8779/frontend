import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';
import 'package:crud/theme/registre/app_theme.dart';
import 'package:crud/theme/registre/register_styles.dart';
import 'package:crud/widgets/style_widgets.dart';
import 'privacy_policy_screen.dart'; // Importar la pantalla de política de privacidad

class RegisterStepScreen extends StatefulWidget {
  const RegisterStepScreen({super.key});

  @override
  State<RegisterStepScreen> createState() => _RegisterStepScreenState();
}

class _RegisterStepScreenState extends State<RegisterStepScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  final _emailCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _nameFocus = FocusNode();
  final _passFocus = FocusNode();
  final _confirmFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Variables para términos y condiciones
  bool _acceptedTerms = false;
  bool _showTermsError = false;

  // Validaciones de contraseña mejoradas
  bool _validLength = false;
  bool _hasUpperOrDigit = false;
  bool _hasSpecial = false;

  // Verificación de email mejorada
  bool? _emailExiste;
  bool _checkingEmail = false;
  String? _emailError;
  int _emailCheckRetries = 0;
  static const int maxEmailRetries = 3;
  bool _hasUnsavedChanges = false;

  // Animaciones mejoradas
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late AnimationController _progressController;

  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _progressAnimation;

  // Constantes de contenido actualizadas para incluir paso de términos
  static const titles = [
    'Tu correo electrónico',
    'Tu nombre completo',
    'Contraseña segura',
    'Términos y condiciones',
    'Confirmar registro'
  ];

  static const subtitles = [
    'Necesitamos tu email para mantenerte conectado',
    '¿Cómo te gusta que te llamen?',
    'Crea una contraseña para proteger tu cuenta',
    'Acepta nuestros términos para continuar',
    'Revisa que todo esté perfecto antes de continuar'
  ];

  static const icons = [
    Icons.email_rounded,
    Icons.person_rounded,
    Icons.lock_rounded,
    Icons.description_rounded,
    Icons.check_circle_rounded
  ];

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _initializeAnimations();
  }

  void _setupControllers() {
    _passCtrl.addListener(_validatePasswordLive);
    _emailCtrl.addListener(_verificarEmailTiempoReal);
    _userCtrl.addListener(() => setState(() => _hasUnsavedChanges = true));
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));

    _fadeController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _disposeControllers();
    _disposeAnimations();
    super.dispose();
  }

  void _disposeControllers() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _pageController.dispose();
  }

  void _disposeAnimations() {
    _slideController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    _pulseController.dispose();
    _progressController.dispose();
  }

  void _validatePasswordLive() {
    final pass = _passCtrl.text;
    setState(() {
      _validLength = pass.length >= 8;
      _hasUpperOrDigit = pass.contains(RegExp(r'[A-Z]')) && pass.contains(RegExp(r'\d'));
      _hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
      _hasUnsavedChanges = true;
    });
  }

  void _verificarEmailTiempoReal() async {
    final email = _emailCtrl.text.trim();

    if (email.length < 6 || !email.contains('@')) {
      setState(() {
        _emailExiste = null;
        _emailError = null;
        _hasUnsavedChanges = true;
      });
      return;
    }

    setState(() {
      _checkingEmail = true;
      _emailError = null;
    });

    try {
      final existe = await _authService.verificarEmailExiste(email);
      if (mounted) {
        setState(() {
          _checkingEmail = false;
          _emailExiste = existe;
          _emailCheckRetries = 0;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _checkingEmail = false;
          _emailCheckRetries++;

          if (_emailCheckRetries <= maxEmailRetries) {
            _emailError = 'Verificando disponibilidad... Reintentando';
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && _emailCtrl.text.trim() == email) {
                _verificarEmailTiempoReal();
              }
            });
          } else {
            _emailError = 'No se pudo verificar el correo. Continúa, lo revisaremos después.';
            _emailExiste = null;
          }
        });
      }
    }
  }

  bool get _isPasswordValid => _validLength && _hasUpperOrDigit && _hasSpecial;

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.largeRadius)),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: AppTheme.warningColor,
                  size: RegisterStyles.getResponsiveSize(context, 28),
                ),
                SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
                const Flexible(child: Text('¿Cancelar registro?')),
              ],
            ),
            content: const Text(
              'Perderás todos los datos ingresados. ¿Estás seguro de que quieres salir?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Continuar registro'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Salir'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _nextStep() {
    // Validar el formulario actual
    if (_currentPage != 3 && !_formKey.currentState!.validate()) {
      _shakeController.forward().then((_) => _shakeController.reset());
      _showSnackBar('Por favor, completa los campos correctamente', isError: true);
      HapticFeedback.heavyImpact();
      return;
    }

    if (_currentPage == 0 && _emailExiste == true) {
      _showSnackBar('Este correo ya está en uso. ¿Quizás quieras iniciar sesión?', isError: true);
      _shakeController.forward().then((_) => _shakeController.reset());
      HapticFeedback.heavyImpact();
      return;
    }

    if (_currentPage == 2) {
      if (!_isPasswordValid) {
        _showSnackBar('Tu contraseña necesita ser más fuerte', isError: true);
        _shakeController.forward().then((_) => _shakeController.reset());
        HapticFeedback.heavyImpact();
        return;
      }
      if (_passCtrl.text != _confirmCtrl.text) {
        _showSnackBar('Las contraseñas no coinciden', isError: true);
        _shakeController.forward().then((_) => _shakeController.reset());
        HapticFeedback.heavyImpact();
        return;
      }
    }

    // Validar términos y condiciones en el paso 3
    if (_currentPage == 3) {
      if (!_acceptedTerms) {
        setState(() => _showTermsError = true);
        _shakeController.forward().then((_) => _shakeController.reset());
        _showSnackBar('Debes aceptar los términos y condiciones para continuar', isError: true);
        HapticFeedback.heavyImpact();
        return;
      }
    }

    if (_currentPage == 4) {
      _submit();
      return;
    }

    HapticFeedback.selectionClick();
    _slideController.forward().then((_) {
      setState(() => _currentPage++);
      _slideController.reset();
      _focusNextField();
    });
  }

  void _focusNextField() {
    switch (_currentPage) {
      case 1:
        _nameFocus.requestFocus();
        break;
      case 2:
        _passFocus.requestFocus();
        break;
      case 3:
      case 4:
        FocusScope.of(context).unfocus();
        break;
    }
  }

  void _backStep() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
      _focusPreviousField();
      HapticFeedback.selectionClick();
    } else {
      Navigator.pop(context);
    }
  }

  void _focusPreviousField() {
    switch (_currentPage) {
      case 0:
        _emailFocus.requestFocus();
        break;
      case 1:
        _nameFocus.requestFocus();
        break;
      case 2:
        _passFocus.requestFocus();
        break;
      case 3:
        FocusScope.of(context).unfocus();
        break;
    }
  }

  // Función para mostrar la política de privacidad
  Future<void> _showPrivacyPolicy() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const PrivacyPolicyScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _acceptedTerms = true;
        _showTermsError = false;
        _hasUnsavedChanges = true;
      });
      HapticFeedback.mediumImpact();
      _showSnackBar('Términos y condiciones aceptados');
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.lightImpact();

    try {
      final success = await _authService.register(
        _userCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (success) {
        HapticFeedback.mediumImpact();
        _showSnackBar('¡Cuenta creada! Ahora puedes iniciar sesión 🎉');
        setState(() => _hasUnsavedChanges = false);
        
        await Future.delayed(const Duration(milliseconds: 1500));
        
        if (mounted) {
          // Redirigir al login y limpiar el stack de navegación
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login', // Ruta del login
            (route) => false, // Esto elimina todas las rutas anteriores
          );
          
          // Si no usas rutas nombradas, usa esto en su lugar:
          // Navigator.of(context).pushAndRemoveUntil(
          //   MaterialPageRoute(builder: (context) => const LoginScreen()),
          //   (route) => false,
          // );
        }
      } else {
        final mensaje = _getErrorMessage(_authService.message);
        _showSnackBar(mensaje, isError: true);
        HapticFeedback.heavyImpact();
      }
    } catch (e) {
      _showSnackBar(_getConnectionErrorMessage(), isError: true);
      HapticFeedback.heavyImpact();
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String? originalMessage) {
    if (originalMessage == null) return 'Algo salió mal. ¿Podrías intentarlo de nuevo?';

    final message = originalMessage.toLowerCase();

    if (message.contains('email') && message.contains('exist')) {
      return 'Este correo ya tiene una cuenta. ¿Quizás quieras iniciar sesión?';
    }
    if (message.contains('password') || message.contains('contraseña')) {
      return 'Hay un problema con tu contraseña. Verifica que cumpla con los requisitos';
    }
    if (message.contains('network') || message.contains('connection')) {
      return _getConnectionErrorMessage();
    }
    if (message.contains('server') || message.contains('500')) {
      return 'Estamos teniendo problemas técnicos. Inténtalo en unos minutos';
    }
    if (message.contains('timeout')) {
      return 'La conexión está un poco lenta. ¿Podrías intentar de nuevo?';
    }

    return originalMessage;
  }

  String _getConnectionErrorMessage() {
    final messages = [
      'Parece que no hay conexión a internet. Verifica tu conexión',
      'No pudimos conectar con nuestros servidores. ¿Podrías revisar tu internet?',
      'Tu conexión parece estar intermitente. Inténtalo cuando tengas mejor señal',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  void _showSnackBar(String message, {bool isError = false, Duration? duration}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: RegisterStyles.mediumIcon(context),
            ),
            SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: RegisterStyles.getResponsiveSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.mediumRadius)),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        elevation: 8,
        duration: duration ?? Duration(seconds: isError ? 4 : 3),
        action: isError
            ? SnackBarAction(
                label: 'Entendido',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (_emailError != null && _emailCheckRetries > 0) {
      return Container(
        margin: EdgeInsets.only(top: RegisterStyles.getResponsiveSize(context, 12)),
        padding: RegisterStyles.defaultPadding(context),
        decoration: RegisterStyles.connectionStatusDecoration(),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: RegisterStyles.mediumIcon(context),
              color: AppTheme.warningColor,
            ),
            SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conexión limitada',
                    style: TextStyle(
                      fontSize: RegisterStyles.getResponsiveSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  Text(
                    _emailError!,
                    style: TextStyle(
                      fontSize: RegisterStyles.getResponsiveSize(context, 12),
                      color: const Color(0xFFA16207),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildStepContent() {
    return Form(
      key: _formKey,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _getStepContent(),
      ),
    );
  }

  Widget _getStepContent() {
    switch (_currentPage) {
      case 0:
        return Column(
          key: const ValueKey(0),
          children: [
            const StyledSectionHeader(
              title: 'Información de contacto',
              icon: Icons.email_outlined,
            ),
            StyledTextField(
              label: 'Correo electrónico',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              icon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              hint: 'ejemplo@correo.com',
              suffixIcon: _checkingEmail
                  ? Padding(
                      padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 16)),
                      child: SizedBox(
                        width: RegisterStyles.mediumIcon(context),
                        height: RegisterStyles.mediumIcon(context),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    )
                  : (_emailExiste == true
                      ? const Icon(Icons.error_rounded, color: AppTheme.errorColor)
                      : _emailExiste == false
                          ? const Icon(Icons.check_circle_rounded, color: AppTheme.secondaryColor)
                          : null),
              onChanged: () => setState(() => _hasUnsavedChanges = true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El correo es obligatorio';
                final regex = RegExp(r"^[\w\.-]+@([\w-]+\.)+[\w-]{2,4}$");
                if (!regex.hasMatch(value!)) return 'Formato de correo inválido';
                if (_emailExiste == true) return 'Este correo ya está registrado';
                return null;
              },
            ),
            _buildConnectionStatus(),
          ],
        );

      case 1:
        return Column(
          key: const ValueKey(1),
          children: [
            const StyledSectionHeader(
              title: 'Información personal',
              icon: Icons.person_outlined,
            ),
            StyledTextField(
              label: 'Nombre completo',
              controller: _userCtrl,
              focusNode: _nameFocus,
              icon: Icons.person_outlined,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              hint: 'Tu nombre y apellido',
              onChanged: () => setState(() => _hasUnsavedChanges = true),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El nombre es obligatorio';
                if (value!.length < 2) return 'El nombre debe tener al menos 2 caracteres';
                if (value.length > 50) return 'El nombre es demasiado largo';
                return null;
              },
            ),
          ],
        );

      case 2:
        return Column(
          key: const ValueKey(2),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StyledSectionHeader(
              title: 'Seguridad de la cuenta',
              icon: Icons.security_outlined,
            ),
            StyledTextField(
              label: 'Contraseña',
              controller: _passCtrl,
              focusNode: _passFocus,
              icon: Icons.lock_outlined,
              isPassword: true,
              obscureText: _obscurePass,
              onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              hint: 'Crea una contraseña segura',
              onChanged: () => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La contraseña es obligatoria';
                if (!_isPasswordValid) return 'No cumple con los requisitos de seguridad';
                return null;
              },
            ),
            StyledPasswordValidation(
              password: _passCtrl.text,
              validLength: _validLength,
              hasUpperOrDigit: _hasUpperOrDigit,
              hasSpecial: _hasSpecial,
            ),
            SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
            StyledTextField(
              label: 'Confirmar contraseña',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              icon: Icons.lock_outlined,
              isPassword: true,
              obscureText: _obscureConfirm,
              onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _nextStep(),
              hint: 'Repite tu contraseña',
              onChanged: () => setState(() {}),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Confirma tu contraseña';
                if (value != _passCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ],
        );

      // NUEVO PASO: Términos y condiciones
      case 3:
        return Column(
          key: const ValueKey(3),
          children: [
            const StyledSectionHeader(
              title: 'Términos y Condiciones',
              icon: Icons.description_outlined,
            ),
            Container(
              padding: RegisterStyles.largePadding(context),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.05),
                    AppTheme.secondaryColor.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(AppTheme.largeRadius),
                border: Border.all(
                  color: _showTermsError 
                      ? AppTheme.errorColor.withOpacity(0.3)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  width: _showTermsError ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.description_rounded,
                    size: RegisterStyles.getResponsiveSize(context, 48),
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
                  Text(
                    'Términos y Condiciones',
                    style: TextStyle(
                      fontSize: RegisterStyles.getResponsiveSize(context, 22),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 12)),
                  Text(
                    'Para completar tu registro necesitamos que leas y aceptes nuestros términos y condiciones de uso.',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: RegisterStyles.getResponsiveSize(context, 15),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 24)),
                  
                  // Botón para leer términos
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _showPrivacyPolicy,
                      icon: Icon(
                        Icons.article_outlined,
                        size: RegisterStyles.mediumIcon(context),
                      ),
                      label: Text(
                        'Leer Términos y Condiciones',
                        style: TextStyle(
                          fontSize: RegisterStyles.getResponsiveSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side: BorderSide(
                          color: AppTheme.primaryColor,
                          width: 1.5,
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: RegisterStyles.getResponsiveSize(context, 16),
                          horizontal: RegisterStyles.getResponsiveSize(context, 24),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
                  
                  // Checkbox de aceptación
                  Container(
                    padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 16)),
                    decoration: BoxDecoration(
                      color: _acceptedTerms 
                          ? AppTheme.secondaryColor.withOpacity(0.1)
                          : _showTermsError
                              ? AppTheme.errorColor.withOpacity(0.1)
                              : AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(AppTheme.mediumRadius),
                      border: Border.all(
                        color: _acceptedTerms
                            ? AppTheme.secondaryColor
                            : _showTermsError
                                ? AppTheme.errorColor
                                : AppTheme.borderColor,
                      ),
                    ),
                    child: Row(
                      children: [
                        Transform.scale(
                          scale: 1.2,
                          child: Checkbox(
                            value: _acceptedTerms,
                            onChanged: (value) {
                              setState(() {
                                _acceptedTerms = value ?? false;
                                _showTermsError = false;
                                _hasUnsavedChanges = true;
                              });
                              HapticFeedback.selectionClick();
                            },
                            activeColor: AppTheme.secondaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                        SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _acceptedTerms = !_acceptedTerms;
                                _showTermsError = false;
                                _hasUnsavedChanges = true;
                              });
                              HapticFeedback.selectionClick();
                            },
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  fontSize: RegisterStyles.getResponsiveSize(context, 14),
                                  color: _showTermsError 
                                      ? AppTheme.errorColor 
                                      : AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                                children: [
                                  const TextSpan(text: 'He leído y acepto los '),
                                  TextSpan(
                                    text: 'términos y condiciones',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' y autorizo el tratamiento de mis datos personales.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_showTermsError) ...[
                    SizedBox(height: RegisterStyles.getResponsiveSize(context, 12)),
                    Container(
                      padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 12)),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        border: Border.all(
                          color: AppTheme.errorColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: AppTheme.errorColor,
                            size: RegisterStyles.getResponsiveSize(context, 18),
                          ),
                          SizedBox(width: RegisterStyles.getResponsiveSize(context, 8)),
                          Expanded(
                            child: Text(
                              'Debes aceptar los términos y condiciones para continuar',
                              style: TextStyle(
                                fontSize: RegisterStyles.getResponsiveSize(context, 13),
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (_acceptedTerms) ...[
                    SizedBox(height: RegisterStyles.getResponsiveSize(context, 12)),
                    Container(
                      padding: EdgeInsets.all(RegisterStyles.getResponsiveSize(context, 12)),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.smallRadius),
                        border: Border.all(
                          color: AppTheme.secondaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: AppTheme.secondaryColor,
                            size: RegisterStyles.getResponsiveSize(context, 18),
                          ),
                          SizedBox(width: RegisterStyles.getResponsiveSize(context, 8)),
                          Expanded(
                            child: Text(
                              'Términos y condiciones aceptados',
                              style: TextStyle(
                                fontSize: RegisterStyles.getResponsiveSize(context, 13),
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case 4:
        return Column(
          key: const ValueKey(4),
          children: [
            const StyledSectionHeader(
              title: 'Resumen del registro',
              icon: Icons.summarize_outlined,
            ),
            Container(
              padding: RegisterStyles.largePadding(context),
              decoration: RegisterStyles.summaryContainerDecoration(),
              child: Column(
                children: [
                  Container(
                    width: RegisterStyles.getResponsiveSize(context, 64),
                    height: RegisterStyles.getResponsiveSize(context, 64),
                    decoration: RegisterStyles.summaryIconContainerDecoration(context),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: RegisterStyles.getResponsiveSize(context, 32),
                      color: AppTheme.secondaryColor,
                    ),
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
                  Text(
                    '¡Todo listo!',
                    style: TextStyle(
                      fontSize: RegisterStyles.getResponsiveSize(context, 24),
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
                  Text(
                    'Revisa tu información antes de crear tu cuenta',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: RegisterStyles.getResponsiveSize(context, 14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 24)),
                  StyledSummaryItem(
                    icon: Icons.email_rounded,
                    label: 'Correo',
                    value: _emailCtrl.text,
                  ),
                  StyledSummaryItem(
                    icon: Icons.person_rounded,
                    label: 'Nombre',
                    value: _userCtrl.text,
                  ),
                  StyledSummaryItem(
                    icon: Icons.lock_rounded,
                    label: 'Contraseña',
                    value: '•' * _passCtrl.text.length,
                  ),
                  StyledSummaryItem(
                    icon: Icons.verified_user_rounded,
                    label: 'Términos',
                    value: _acceptedTerms ? 'Aceptados' : 'No aceptados',
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _currentPage = 0);
                        _emailFocus.requestFocus();
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        size: RegisterStyles.smallIcon(context),
                      ),
                      label: Text(
                        'Editar información',
                        style: RegisterStyles.smallButtonTextStyle(context),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        padding: EdgeInsets.symmetric(
                          horizontal: RegisterStyles.getResponsiveSize(context, 20),
                          vertical: RegisterStyles.getResponsiveSize(context, 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

      default:
        return const SizedBox();
    }
  }

  Widget _buildActionButtons() {
    final isLast = _currentPage == 4;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(top: RegisterStyles.getResponsiveSize(context, 32)),
      child: screenWidth < 400
          ? Column(
              children: [
                if (_currentPage > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: RegisterStyles.getResponsiveSize(context, 48),
                    child: _buildBackButton(),
                  ),
                  SizedBox(height: RegisterStyles.getResponsiveSize(context, 12)),
                ],
                SizedBox(
                  width: double.infinity,
                  height: RegisterStyles.getResponsiveSize(context, 56),
                  child: _buildNextButton(isLast),
                ),
              ],
            )
          : Row(
              children: [
                if (_currentPage > 0) _buildBackButton(),
                const Spacer(),
                _buildNextButton(isLast),
              ],
            ),
    );
  }

  Widget _buildBackButton() {
    return TextButton.icon(
      onPressed: _backStep,
      icon: Icon(
        Icons.arrow_back_rounded,
        size: RegisterStyles.mediumIcon(context),
      ),
      label: Text('Atrás', style: RegisterStyles.smallButtonTextStyle(context)),
      style: RegisterStyles.backButtonStyle(context),
    );
  }

  Widget _buildNextButton(bool isLast) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? _pulseAnimation.value : 1.0,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _nextStep,
            style: RegisterStyles.nextButtonStyle(context),
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: RegisterStyles.mediumIcon(context),
                        height: RegisterStyles.mediumIcon(context),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: RegisterStyles.getResponsiveSize(context, 16)),
                      Text(
                        isLast ? 'Creando cuenta...' : 'Procesando...',
                        style: RegisterStyles.buttonTextStyle(context),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Crear cuenta' : 'Continuar',
                        style: RegisterStyles.buttonTextStyle(context),
                      ),
                      SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
                      Icon(
                        isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        size: RegisterStyles.mediumIcon(context),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Theme(
          data: AppTheme.lightTheme,
          child: Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            appBar: AppBar(
              title: Text(
                'Crear Cuenta',
                style: AppTheme.lightTheme.appBarTheme.titleTextStyle,
              ),
              centerTitle: true,
              backgroundColor: AppTheme.surfaceColor,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(
                  height: 1,
                  color: AppTheme.borderColor,
                ),
              ),
              actions: [
                if (_hasUnsavedChanges)
                  Container(
                    margin: EdgeInsets.only(right: RegisterStyles.getResponsiveSize(context, 8)),
                    padding: EdgeInsets.symmetric(
                      horizontal: RegisterStyles.getResponsiveSize(context, 8),
                      vertical: RegisterStyles.getResponsiveSize(context, 4),
                    ),
                    decoration: RegisterStyles.unsavedChangesDecoration(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: AppTheme.warningColor,
                          size: RegisterStyles.getResponsiveSize(context, 8),
                        ),
                        SizedBox(width: RegisterStyles.getResponsiveSize(context, 4)),
                        Text(
                          'Sin guardar',
                          style: RegisterStyles.unsavedChangesTextStyle(context),
                        ),
                      ],
                    ),
                  ),
                IconButton(
                  onPressed: () => _showHelpDialog(),
                  icon: Icon(
                    Icons.help_outline,
                    size: RegisterStyles.getResponsiveSize(context, 24),
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  // Handle superior
                  Container(
                    width: RegisterStyles.getResponsiveSize(context, 40),
                    height: RegisterStyles.getResponsiveSize(context, 4),
                    margin: EdgeInsets.symmetric(vertical: RegisterStyles.getResponsiveSize(context, 12)),
                    decoration: RegisterStyles.handleDecoration(context),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: RegisterStyles.getResponsivePadding(context),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 600),
                        child: Column(
                          children: [
                            StyledProgressIndicator(
                              currentPage: _currentPage,
                              totalPages: 5, // Actualizado a 5 pasos
                            ),
                            SizedBox(height: RegisterStyles.getResponsiveSize(context, 24)),
                            StyledStepHeader(
                              currentPage: _currentPage,
                              titles: titles,
                              subtitles: subtitles,
                              icons: icons,
                            ),
                            SizedBox(height: RegisterStyles.getResponsiveSize(context, 32)),
                            _buildStepContent(),
                            _buildActionButtons(),
                            SizedBox(height: RegisterStyles.getResponsiveSize(context, 32)),
                          ],
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
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.largeRadius)),
        title: Row(
          children: [
            Icon(
              Icons.help_outline,
              color: AppTheme.primaryColor,
              size: RegisterStyles.getResponsiveSize(context, 24),
            ),
            SizedBox(width: RegisterStyles.getResponsiveSize(context, 12)),
            const Flexible(child: Text('Ayuda')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '• Todos los campos son obligatorios',
              style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
            ),
            SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
            Text(
              '• Tu email debe ser válido y único',
              style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
            ),
            SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
            Text(
              '• La contraseña debe cumplir todos los requisitos',
              style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
            ),
            SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
            Text(
              '• Debes aceptar los términos y condiciones',
              style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
            ),
            SizedBox(height: RegisterStyles.getResponsiveSize(context, 8)),
            Text(
              '• Puedes navegar entre pasos para editar',
              style: TextStyle(fontSize: RegisterStyles.getResponsiveSize(context, 14)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}