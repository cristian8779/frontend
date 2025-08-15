import 'package:flutter/material.dart';
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

  bool _validLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  bool? _emailExiste;
  bool _checkingEmail = false;
  String? _emailError;
  int _emailCheckRetries = 0;
  static const int maxEmailRetries = 2;

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _shakeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _passCtrl.addListener(_validatePasswordLive);
    _emailCtrl.addListener(_verificarEmailTiempoReal);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1, 0),
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

    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _emailFocus.dispose();
    _nameFocus.dispose();
    _passFocus.dispose();
    _confirmFocus.dispose();
    _pageController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _validatePasswordLive() {
    final pass = _passCtrl.text;
    setState(() {
      _validLength = pass.length >= 8;
      _hasUpper = pass.contains(RegExp(r'[A-Z]'));
      _hasLower = pass.contains(RegExp(r'[a-z]'));
      _hasDigit = pass.contains(RegExp(r'\d'));
      _hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _verificarEmailTiempoReal() async {
    final email = _emailCtrl.text.trim();

    if (email.length < 6 || !email.contains('@')) {
      setState(() {
        _emailExiste = null;
        _emailError = null;
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

  bool get _isPasswordValid =>
      _validLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  double get _passwordStrength {
    int score = 0;
    if (_validLength) score++;
    if (_hasUpper) score++;
    if (_hasLower) score++;
    if (_hasDigit) score++;
    if (_hasSpecial) score++;
    return score / 5.0;
  }

  Color get _strengthColor {
    if (_passwordStrength < 0.4) return Colors.red;
    if (_passwordStrength < 0.6) return Colors.orange;
    if (_passwordStrength < 0.8) return Colors.yellow[700]!;
    return Colors.green;
  }

  String get _strengthText {
    if (_passwordStrength < 0.4) return 'Débil';
    if (_passwordStrength < 0.6) return 'Regular';
    if (_passwordStrength < 0.8) return 'Buena';
    return 'Fuerte';
  }

  void _nextStep() {
    if (_formKey.currentState?.validate() != true) {
      if (!MediaQuery.of(context).disableAnimations) {
        _shakeController.forward().then((_) => _shakeController.reset());
      }
      _showMessage('Por favor, completa los campos correctamente', false);
      return;
    }

    if (_currentPage == 0 && _emailExiste == true) {
      _showMessage('🤔 Este correo ya está en uso. ¿Quizás quieras iniciar sesión?', false);
      if (!MediaQuery.of(context).disableAnimations) {
        _shakeController.forward().then((_) => _shakeController.reset());
      }
      return;
    }

    if (_currentPage == 2) {
      if (!_isPasswordValid) {
        _showMessage('🔐 Tu contraseña necesita ser un poco más fuerte', false);
        if (!MediaQuery.of(context).disableAnimations) {
          _shakeController.forward().then((_) => _shakeController.reset());
        }
        return;
      }
      if (_passCtrl.text != _confirmCtrl.text) {
        _showMessage('🤷‍♀️ Las contraseñas no coinciden. Inténtalo de nuevo', false);
        if (!MediaQuery.of(context).disableAnimations) {
          _shakeController.forward().then((_) => _shakeController.reset());
        }
        return;
      }
    }

    if (_currentPage == 3) {
      _submit();
      return;
    }

    _slideController.forward().then((_) {
      setState(() => _currentPage++);
      _slideController.reset();
      switch (_currentPage) {
        case 1:
          _nameFocus.requestFocus();
          break;
        case 2:
          _passFocus.requestFocus();
          break;
        case 3:
          FocusScope.of(context).nextFocus();
          break;
      }
    });
  }

  void _backStep() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
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
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    setState(() => _isLoading = true);

    try {
      final success = await _authService.register(
        _userCtrl.text.trim(),
        _emailCtrl.text.trim(),
        _passCtrl.text.trim(),
      );

      if (success) {
        _showMessage('🎉 ¡Bienvenido a bordo! Tu cuenta ha sido creada exitosamente', true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        final mensaje = _getErrorMessage(_authService.message);
        _showMessage(mensaje, false);
      }
    } catch (e) {
      _showMessage(_getConnectionErrorMessage(), false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String? originalMessage) {
    if (originalMessage == null) return '🤖 Algo salió mal. ¿Podrías intentarlo de nuevo?';

    final message = originalMessage.toLowerCase();

    if (message.contains('email') && message.contains('exist')) {
      return '📧 Este correo ya tiene una cuenta. ¿Quizás quieras iniciar sesión?';
    }
    if (message.contains('password') || message.contains('contraseña')) {
      return '🔑 Hay un problema con tu contraseña. Verifica que cumpla con los requisitos';
    }
    if (message.contains('network') || message.contains('connection')) {
      return _getConnectionErrorMessage();
    }
    if (message.contains('server') || message.contains('500')) {
      return '⚙️ Estamos teniendo problemas técnicos. Inténtalo en unos minutos';
    }
    if (message.contains('timeout')) {
      return '⏰ La conexión está un poco lenta. ¿Podrías intentar de nuevo?';
    }

    return '🤔 $originalMessage';
  }

  String _getConnectionErrorMessage() {
    final messages = [
      '📶 Parece que no hay conexión a internet. Verifica tu conexión y prueba de nuevo',
      '🌐 No pudimos conectar con nuestros servidores. ¿Podrías revisar tu internet?',
      '📡 Tu conexión parece estar intermitente. Inténtalo cuando tengas mejor señal',
    ];
    return messages[DateTime.now().millisecond % messages.length];
  }

  void _showMessage(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 22,
                semanticLabel: isSuccess ? 'Éxito' : 'Información',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: isSuccess ? Colors.green[600] : Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: isSuccess ? 2 : 4),
        action: !isSuccess
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    Widget? suffixIcon,
  }) {
    return Semantics(
      label: label,
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(
              MediaQuery.of(context).disableAnimations
                  ? 0
                  : _shakeAnimation.value * 10 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 100) / 100),
              0,
            ),
            child: child,
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              validator: validator,
              textInputAction: textInputAction,
              onFieldSubmitted: onFieldSubmitted,
              style: const TextStyle(fontSize: 16),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
                labelText: label,
                hintText: 'Ingresa tu $label',
                suffixIcon: isPassword
                    ? Semantics(
                        button: true,
                        label: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
                        child: IconButton(
                          icon: Icon(
                            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            color: Colors.grey[600],
                            semanticLabel: obscureText ? 'Mostrar contraseña' : 'Ocultar contraseña',
                          ),
                          onPressed: onToggleVisibility,
                        ),
                      )
                    : suffixIcon,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Nueva versión compacta de los requisitos de contraseña
  Widget _buildCompactPasswordValidation() {
    if (_passCtrl.text.isEmpty) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de fortaleza compacta
          Row(
            children: [
              Icon(
                Icons.security_rounded, 
                size: 16, 
                color: _strengthColor,
                semanticLabel: 'Nivel de seguridad',
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Seguridad: $_strengthText',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _strengthColor,
                          ),
                        ),
                        Text(
                          '${(_passwordStrength * 100).toInt()}%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                      minHeight: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Indicadores compactos en dos filas
          Wrap(
            runSpacing: 6,
            spacing: 16,
            children: [
              _buildCompactRequirement('8+ chars', _validLength),
              _buildCompactRequirement('A-Z', _hasUpper),
              _buildCompactRequirement('a-z', _hasLower),
              _buildCompactRequirement('0-9', _hasDigit),
              _buildCompactRequirement('!@#', _hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRequirement(String text, bool isValid) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isValid ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isValid ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
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
              size: 12,
              color: isValid ? Colors.green[600] : Colors.grey[400],
              semanticLabel: isValid ? 'Cumple' : 'No cumple',
            ),
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
              color: isValid ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Semantics(
      label: 'Progreso del registro, paso ${_currentPage + 1} de 4',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        child: Row(
          children: List.generate(4, (index) {
            final isActive = index <= _currentPage;
            final isCurrent = index == _currentPage;

            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 6,
                margin: EdgeInsets.only(right: index < 3 ? 8 : 0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: isActive
                      ? (isCurrent ? Colors.redAccent : Colors.green[600])
                      : Colors.grey[300],
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: (isCurrent ? Colors.redAccent : Colors.green[600]!).withOpacity(0.3),
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
      'Necesitamos tu email para mantenerte conectado 📧',
      '¿Cómo te gusta que te llamen? 😊',
      'Crea una contraseña fuerte para proteger tu cuenta 🔐',
      'Revisa que todo esté perfecto antes de continuar ✨'
    ];

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            [Icons.email_rounded, Icons.person_rounded, Icons.lock_rounded, Icons.check_circle_rounded][_currentPage],
            color: Colors.redAccent,
            size: 28,
            semanticLabel: titles[_currentPage],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            titles[_currentPage],
            key: ValueKey(_currentPage),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            subtitles[_currentPage],
            key: ValueKey('subtitle_$_currentPage'),
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
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
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.wifi_off_rounded, size: 16, color: Colors.orange[700], semanticLabel: 'Sin conexión'),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _emailError!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange[800],
                ),
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
        duration: const Duration(milliseconds: 300),
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
            _buildTextField(
              label: 'Correo electrónico',
              controller: _emailCtrl,
              focusNode: _emailFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              suffixIcon: _checkingEmail
                  ? Semantics(
                      label: 'Verificando disponibilidad del correo',
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : (_emailExiste == true
                      ? const Icon(Icons.error_rounded, color: Colors.red, semanticLabel: 'Correo ya registrado')
                      : _emailExiste == false
                          ? const Icon(Icons.check_circle_rounded, color: Colors.green, semanticLabel: 'Correo disponible')
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
            _buildTextField(
              label: 'Nombre completo',
              controller: _userCtrl,
              focusNode: _nameFocus,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _nextStep(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'El nombre es obligatorio';
                if (value!.length < 2) return 'El nombre debe tener al menos 2 caracteres';
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
            _buildTextField(
              label: 'Contraseña',
              controller: _passCtrl,
              focusNode: _passFocus,
              isPassword: true,
              obscureText: _obscurePass,
              onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _confirmFocus.requestFocus(),
              validator: (value) {
                if (value?.isEmpty ?? true) return 'La contraseña es obligatoria';
                if (!_isPasswordValid) return 'No cumple con los requisitos de seguridad';
                return null;
              },
            ),
            // Nueva validación compacta
            _buildCompactPasswordValidation(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Confirmar contraseña',
              controller: _confirmCtrl,
              focusNode: _confirmFocus,
              isPassword: true,
              obscureText: _obscureConfirm,
              onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _nextStep(),
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    size: 48,
                    color: Colors.green[600],
                    semanticLabel: 'Resumen completo',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '¡Todo listo!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Revisa tu información antes de crear tu cuenta',
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 20),
                  _buildSummaryItem(Icons.email_rounded, 'Correo', _emailCtrl.text),
                  _buildSummaryItem(Icons.person_rounded, 'Nombre', _userCtrl.text),
                  _buildSummaryItem(Icons.lock_rounded, 'Contraseña', '•' * _passCtrl.text.length),
                  const SizedBox(height: 16),
                  Semantics(
                    button: true,
                    label: 'Editar información registrada',
                    child: TextButton.icon(
                      onPressed: () {
                        setState(() => _currentPage = 0);
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                        _emailFocus.requestFocus();
                      },
                      icon: const Icon(Icons.edit_rounded),
                      label: const Text('Editar información'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600], semanticLabel: label),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isLast = _currentPage == 3;

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        children: [
          if (_currentPage > 0)
            Semantics(
              button: true,
              label: 'Volver al paso anterior',
              child: TextButton.icon(
                onPressed: _backStep,
                icon: const Icon(Icons.arrow_back_rounded, size: 18, semanticLabel: 'Atrás'),
                label: const Text('Atrás'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          const Spacer(),
          Semantics(
            button: true,
            label: isLast ? 'Crear cuenta' : 'Continuar al siguiente paso',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  elevation: _isLoading ? 0 : 2,
                ),
                child: _isLoading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              semanticsLabel: 'Procesando',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            isLast ? 'Creando cuenta...' : 'Procesando...',
                            style: const TextStyle(
                              fontSize: 16,
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
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                            size: 20,
                            semanticLabel: isLast ? 'Confirmar creación' : 'Siguiente',
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOfflineIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 20, color: Colors.orange[700], semanticLabel: 'Sin conexión'),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Conexión limitada',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                Text(
                  'Puedes continuar, verificaremos tu información cuando se restablezca la conexión',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildProgressIndicator(),
                        const SizedBox(height: 20),
                        _buildStepHeader(),
                        const SizedBox(height: 32),
                        if (_emailCheckRetries > maxEmailRetries) _buildOfflineIndicator(),
                        _buildStepContent(),
                        _buildActionButtons(),
                        const SizedBox(height: 20),
                      ],
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