import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/auth_service.dart';

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

  // Función helper para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return baseSize * 1.2; // Tablets
    if (screenWidth < 360) return baseSize * 0.9; // Pantallas pequeñas
    return baseSize;
  }

  // Función helper para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return const EdgeInsets.all(32); // Tablets
    if (screenWidth < 360) return const EdgeInsets.all(12); // Pantallas pequeñas
    return const EdgeInsets.all(20); // Por defecto
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

  double get _passwordStrength {
    int score = 0;
    if (_validLength) score++;
    if (_hasUpperOrDigit) score += 2;
    if (_hasSpecial) score++;
    return score / 4.0;
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.3) return const Color(0xFFEF4444);
    if (_passwordStrength < 0.6) return const Color(0xFFF59E0B);
    if (_passwordStrength < 0.8) return const Color(0xFF10B981);
    return const Color(0xFF059669);
  }

  String get _strengthText {
    if (_passwordStrength < 0.3) return 'Muy débil';
    if (_passwordStrength < 0.6) return 'Débil';
    if (_passwordStrength < 0.8) return 'Buena';
    return 'Muy fuerte';
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: const Color(0xFFF59E0B),
                  size: _getResponsiveSize(context, 28),
                ),
                SizedBox(width: _getResponsiveSize(context, 12)),
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
                  backgroundColor: const Color(0xFFEF4444),
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
    if (!_formKey.currentState!.validate()) {
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

    if (_currentPage == 3) {
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
        _showSnackBar('¡Bienvenido! Tu cuenta ha sido creada exitosamente 🎉');
        setState(() => _hasUnsavedChanges = false);
        
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
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
              size: _getResponsiveSize(context, 20),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 14),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: EdgeInsets.only(
          top: _getResponsiveSize(context, 24),
          bottom: _getResponsiveSize(context, 16),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 8)),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6366F1),
                size: _getResponsiveSize(context, 20),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
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
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String? Function(String?) validator,
    IconData? icon,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? hint,
    Widget? suffixIcon,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveSize(context, 14),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          AnimatedBuilder(
            animation: _shakeAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _shakeAnimation.value * 10 * 
                  (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100),
                  0,
                ),
                child: child,
              );
            },
            child: TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              validator: validator,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              onChanged: (value) {
                if (mounted) setState(() {});
              },
              style: TextStyle(fontSize: _getResponsiveSize(context, 16)),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                prefixIcon: icon != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          left: _getResponsiveSize(context, 16),
                          right: _getResponsiveSize(context, 12),
                        ),
                        child: Icon(
                          icon,
                          color: const Color(0xFF9CA3AF),
                          size: _getResponsiveSize(context, 20),
                        ),
                      )
                    : null,
                suffixIcon: isPassword
                    ? IconButton(
                        icon: Icon(
                          obscureText 
                              ? Icons.visibility_off_rounded 
                              : Icons.visibility_rounded,
                          color: const Color(0xFF9CA3AF),
                          size: _getResponsiveSize(context, 20),
                        ),
                        onPressed: onToggleVisibility,
                      )
                    : suffixIcon ?? (controller.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              size: _getResponsiveSize(context, 20),
                            ),
                            onPressed: () {
                              controller.clear();
                              setState(() => _hasUnsavedChanges = true);
                            },
                            color: const Color(0xFF9CA3AF),
                          )
                        : null),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 16),
                  vertical: _getResponsiveSize(context, 16),
                ),
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
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // FUNCIÓN MODIFICADA - Validación con chips compactos
  Widget _buildPasswordValidation() {
    if (_passCtrl.text.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(top: _getResponsiveSize(context, 12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de fortaleza compacta
          Row(
            children: [
              Icon(
                Icons.security_rounded,
                size: _getResponsiveSize(context, 18),
                color: _strengthColor,
              ),
              SizedBox(width: _getResponsiveSize(context, 8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _strengthText,
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 13),
                            fontWeight: FontWeight.w600,
                            color: _strengthColor,
                          ),
                        ),
                        Text(
                          '${(_passwordStrength * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, 12),
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveSize(context, 4)),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: _passwordStrength,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                        minHeight: _getResponsiveSize(context, 3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: _getResponsiveSize(context, 10)),
          
          // Chips de requisitos compactos
          Wrap(
            spacing: _getResponsiveSize(context, 6),
            runSpacing: _getResponsiveSize(context, 6),
            children: [
              _buildCompactChip('8+ caracteres', _validLength),
              _buildCompactChip('Mayús + número', _hasUpperOrDigit),
              _buildCompactChip('Símbolo especial', _hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  // FUNCIÓN NUEVA - Chips compactos
  Widget _buildCompactChip(String text, bool isValid) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 8),
        vertical: _getResponsiveSize(context, 4),
      ),
      decoration: BoxDecoration(
        color: isValid 
            ? const Color(0xFF10B981).withOpacity(0.1) 
            : const Color(0xFF9CA3AF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isValid 
              ? const Color(0xFF10B981).withOpacity(0.3) 
              : const Color(0xFF9CA3AF).withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isValid ? Icons.check_circle : Icons.radio_button_unchecked,
              key: ValueKey(isValid),
              size: _getResponsiveSize(context, 14),
              color: isValid 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFF9CA3AF),
            ),
          ),
          SizedBox(width: _getResponsiveSize(context, 4)),
          Text(
            text,
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 12),
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              color: isValid 
                  ? const Color(0xFF059669) 
                  : const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 24)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Paso ${_currentPage + 1} de 4',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
              Text(
                '${((_currentPage + 1) / 4 * 100).toInt()}%',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 14),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          Row(
            children: List.generate(4, (index) {
              final isActive = index <= _currentPage;
              final isCurrent = index == _currentPage;

              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  height: _getResponsiveSize(context, 6),
                  margin: EdgeInsets.only(
                    right: index < 3 ? _getResponsiveSize(context, 8) : 0
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    color: isActive
                        ? (isCurrent 
                            ? const Color(0xFF6366F1) 
                            : const Color(0xFF10B981))
                        : const Color(0xFFE5E7EB),
                    boxShadow: isActive && isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF6366F1).withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepHeader() {
    const titles = [
      'Tu correo electrónico',
      'Tu nombre completo',
      'Contraseña segura',
      'Confirmar registro'
    ];

    const subtitles = [
      'Necesitamos tu email para mantenerte conectado',
      '¿Cómo te gusta que te llamen?',
      'Crea una contraseña para proteger tu cuenta',
      'Revisa que todo esté perfecto antes de continuar'
    ];

    const icons = [
      Icons.email_rounded,
      Icons.person_rounded,
      Icons.lock_rounded,
      Icons.check_circle_rounded
    ];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: _getResponsiveSize(context, 80),
          height: _getResponsiveSize(context, 80),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 40)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icons[_currentPage],
            color: const Color(0xFF6366F1),
            size: _getResponsiveSize(context, 40),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 20)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            titles[_currentPage],
            key: ValueKey(_currentPage),
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 28),
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 12)),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: Text(
            subtitles[_currentPage],
            key: ValueKey('subtitle_$_currentPage'),
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 16),
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionStatus() {
    if (_emailError != null && _emailCheckRetries > 0) {
      return Container(
        margin: EdgeInsets.only(top: _getResponsiveSize(context, 12)),
        padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: _getResponsiveSize(context, 20),
              color: const Color(0xFFF59E0B),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Conexión limitada',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 14),
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFD97706),
                    ),
                  ),
                  Text(
                    _emailError!,
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 12),
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
            _buildSectionHeader('Información de contacto', Icons.email_outlined),
            _buildTextField(
              label: 'Correo electrónico',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              icon: Icons.email_outlined,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              hint: 'ejemplo@correo.com',
              suffixIcon: _checkingEmail
                  ? Padding(
                      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
                      child: SizedBox(
                        width: _getResponsiveSize(context, 20),
                        height: _getResponsiveSize(context, 20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF6366F1),
                        ),
                      ),
                    )
                  : (_emailExiste == true
                      ? const Icon(Icons.error_rounded, color: Color(0xFFEF4444))
                      : _emailExiste == false
                          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981))
                          : null),
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
            _buildSectionHeader('Información personal', Icons.person_outlined),
            _buildTextField(
              label: 'Nombre completo',
              controller: _userCtrl,
              focusNode: _nameFocus,
              icon: Icons.person_outlined,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              hint: 'Tu nombre y apellido',
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
            _buildSectionHeader('Seguridad de la cuenta', Icons.security_outlined),
            _buildTextField(
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
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La contraseña es obligatoria';
                if (!_isPasswordValid) return 'No cumple con los requisitos de seguridad';
                return null;
              },
            ),
            _buildPasswordValidation(),
            SizedBox(height: _getResponsiveSize(context, 20)),
            _buildTextField(
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
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Confirma tu contraseña';
                if (value != _passCtrl.text) return 'Las contraseñas no coinciden';
                return null;
              },
            ),
          ],
        );

      case 3:
        return Column(
          key: const ValueKey(3),
          children: [
            _buildSectionHeader('Resumen del registro', Icons.summarize_outlined),
            Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 24)),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Container(
                    width: _getResponsiveSize(context, 64),
                    height: _getResponsiveSize(context, 64),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      size: _getResponsiveSize(context, 32),
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 20)),
                  Text(
                    '¡Todo listo!',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, 24),
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 8)),
                  Text(
                    'Revisa tu información antes de crear tu cuenta',
                    style: TextStyle(
                      color: const Color(0xFF6B7280),
                      fontSize: _getResponsiveSize(context, 14),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _getResponsiveSize(context, 24)),
                  _buildSummaryItem(Icons.email_rounded, 'Correo', _emailCtrl.text),
                  _buildSummaryItem(Icons.person_rounded, 'Nombre', _userCtrl.text),
                  _buildSummaryItem(
                    Icons.lock_rounded, 
                    'Contraseña', 
                    '•' * _passCtrl.text.length
                  ),
                  SizedBox(height: _getResponsiveSize(context, 20)),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _currentPage = 0);
                        _emailFocus.requestFocus();
                      },
                      icon: Icon(
                        Icons.edit_rounded,
                        size: _getResponsiveSize(context, 18),
                      ),
                      label: Text(
                        'Editar información',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 14),
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(context, 20),
                          vertical: _getResponsiveSize(context, 12),
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

  Widget _buildSummaryItem(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 12)),
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(_getResponsiveSize(context, 8)),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: _getResponsiveSize(context, 20),
              color: const Color(0xFF6366F1),
            ),
          ),
          SizedBox(width: _getResponsiveSize(context, 16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 12),
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: _getResponsiveSize(context, 2)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 16),
                    color: const Color(0xFF1F2937),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isLast = _currentPage == 3;
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.only(top: _getResponsiveSize(context, 32)),
      child: screenWidth < 400
          ? Column(
              children: [
                if (_currentPage > 0) ...[
                  SizedBox(
                    width: double.infinity,
                    height: _getResponsiveSize(context, 48),
                    child: _buildBackButton(),
                  ),
                  SizedBox(height: _getResponsiveSize(context, 12)),
                ],
                SizedBox(
                  width: double.infinity,
                  height: _getResponsiveSize(context, 56),
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
        size: _getResponsiveSize(context, 20),
      ),
      label: Text(
        'Atrás',
        style: TextStyle(
          fontSize: _getResponsiveSize(context, 14),
        ),
      ),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF6B7280),
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSize(context, 20),
          vertical: _getResponsiveSize(context, 12),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
      ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF9CA3AF),
              elevation: _isLoading ? 0 : 8,
              shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, 32),
                vertical: _getResponsiveSize(context, 16),
              ),
            ),
            child: _isLoading
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: _getResponsiveSize(context, 20),
                        height: _getResponsiveSize(context, 20),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: _getResponsiveSize(context, 16)),
                      Text(
                        isLast ? 'Creando cuenta...' : 'Procesando...',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Crear cuenta' : 'Continuar',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: _getResponsiveSize(context, 12)),
                      Icon(
                        isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        size: _getResponsiveSize(context, 20),
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
    return WillPopScope(
      onWillPop: _onWillPop,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            title: Text(
              'Crear Cuenta',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: _getResponsiveSize(context, 20),
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
              if (_hasUnsavedChanges)
                Container(
                  margin: EdgeInsets.only(right: _getResponsiveSize(context, 8)),
                  padding: EdgeInsets.symmetric(
                    horizontal: _getResponsiveSize(context, 8),
                    vertical: _getResponsiveSize(context, 4),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        color: const Color(0xFFF59E0B),
                        size: _getResponsiveSize(context, 8),
                      ),
                      SizedBox(width: _getResponsiveSize(context, 4)),
                      Text(
                        'Sin guardar',
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 12),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Row(
                        children: [
                          Icon(
                            Icons.help_outline,
                            color: const Color(0xFF6366F1),
                            size: _getResponsiveSize(context, 24),
                          ),
                          SizedBox(width: _getResponsiveSize(context, 12)),
                          const Flexible(child: Text('Ayuda')),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• Todos los campos son obligatorios',
                            style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 8)),
                          Text(
                            '• Tu email debe ser válido y único',
                            style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 8)),
                          Text(
                            '• La contraseña debe cumplir todos los requisitos',
                            style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                          ),
                          SizedBox(height: _getResponsiveSize(context, 8)),
                          Text(
                            '• Puedes navegar entre pasos para editar',
                            style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
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
                },
                icon: Icon(
                  Icons.help_outline,
                  size: _getResponsiveSize(context, 24),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // Handle superior
                Container(
                  width: _getResponsiveSize(context, 40),
                  height: _getResponsiveSize(context, 4),
                  margin: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 12)),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: _getResponsivePadding(context),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: Column(
                        children: [
                          _buildProgressIndicator(),
                          SizedBox(height: _getResponsiveSize(context, 24)),
                          _buildStepHeader(),
                          SizedBox(height: _getResponsiveSize(context, 32)),
                          _buildStepContent(),
                          _buildActionButtons(),
                          SizedBox(height: _getResponsiveSize(context, 32)),
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
    );
  }
}
  