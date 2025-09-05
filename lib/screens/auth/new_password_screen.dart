import 'package:flutter/material.dart';
import '../../services/password_service.dart';

class NewPasswordScreen extends StatefulWidget {
  final String token;
  final String email;

  const NewPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen>
    with TickerProviderStateMixin {
  final PasswordService _passwordService = PasswordService();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _validLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_validatePassword);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    if (_animationController != null) {
      _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
      );
      _animationController!.forward();
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Función para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.8;
    } else if (screenWidth > 500) {
      return baseSize * 1.2;
    }
    return baseSize;
  }

  // Función para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return const EdgeInsets.all(16);
    } else if (screenWidth > 500) {
      return const EdgeInsets.all(32);
    }
    return const EdgeInsets.all(24);
  }

  void _validatePassword() {
    final pass = _passwordCtrl.text;
    setState(() {
      _validLength = pass.length >= 8;
      _hasUpper = pass.contains(RegExp(r'[A-Z]'));
      _hasLower = pass.contains(RegExp(r'[a-z]'));
      _hasDigit = pass.contains(RegExp(r'\d'));
      _hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  bool get _isPasswordValid =>
      _validLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  // Getter para validar mayúscula O número
  bool get _hasUpperOrDigit => _hasUpper && _hasLower && _hasDigit;

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
    return 'Excelente';
  }

  Future<void> _guardarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!_isPasswordValid) {
      _mostrarMensaje("La contraseña no cumple con todos los requisitos.", false);
      return;
    }

    if (password != confirm) {
      _mostrarMensaje("Las contraseñas no coinciden", false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _passwordService.resetPassword(
        widget.email,
        widget.token,
        password,
      );

      final msg = _passwordService.message;

      if (success) {
        _mostrarMensaje(msg ?? "¡Contraseña cambiada exitosamente!", true);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
      } else {
        _mostrarMensaje(msg ?? "Error al cambiar la contraseña", false);
      }
    } catch (e) {
      _mostrarMensaje("Error de conexión. Intenta nuevamente.", false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarMensaje(String msg, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: _getResponsiveSize(context, 20),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Text(
                msg, 
                style: TextStyle(fontSize: _getResponsiveSize(context, 14))
              )
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isSuccess ? Colors.green[600] : Colors.red[600],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(_getResponsiveSize(context, 16)),
        duration: Duration(seconds: isSuccess ? 3 : 4),
      ),
    );
  }

  // Widget para chips compactos de requisitos
  Widget _buildCompactChip(String text, bool isValid) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, 8),
        vertical: _getResponsiveSize(context, 4),
      ),
      decoration: BoxDecoration(
        color: isValid ? Colors.green[50] : Colors.grey[100],
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
        border: Border.all(
          color: isValid ? Colors.green[300]! : Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            color: isValid ? Colors.green[600] : Colors.grey[400],
            size: _getResponsiveSize(context, 14),
          ),
          SizedBox(width: _getResponsiveSize(context, 6)),
          Text(
            text,
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 12),
              fontWeight: FontWeight.w500,
              color: isValid ? Colors.green[700] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Seguridad de la contraseña',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 14),
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            Text(
              _strengthText,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 14),
                fontWeight: FontWeight.w600,
                color: _strengthColor,
              ),
            ),
          ],
        ),
        SizedBox(height: _getResponsiveSize(context, 8)),
        ClipRRect(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 10)),
          child: LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            minHeight: _getResponsiveSize(context, 6),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      style: TextStyle(fontSize: _getResponsiveSize(context, 16)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey[600],
          fontSize: _getResponsiveSize(context, 14),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: _getResponsiveSize(context, 16),
          vertical: _getResponsiveSize(context, 16),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
          borderSide: const BorderSide(color: Color(0xFFBE0C0C), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey[600],
            size: _getResponsiveSize(context, 20),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFBE0C0C);
    const bgColor = Color(0xFFF8F9FA);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Nueva Contraseña',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: _getResponsiveSize(context, 18),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryColor,
        elevation: 0,
        shadowColor: Colors.black12,
        scrolledUnderElevation: 1,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation?.value ?? 1.0,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: _getResponsivePadding(context),
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 600 : double.infinity,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(_getResponsiveSize(context, 20)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                                    ),
                                    child: Icon(
                                      Icons.lock_reset,
                                      color: primaryColor,
                                      size: _getResponsiveSize(context, 24),
                                    ),
                                  ),
                                  SizedBox(width: _getResponsiveSize(context, 16)),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Crear nueva contraseña',
                                          style: TextStyle(
                                            fontSize: _getResponsiveSize(context, 20),
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        SizedBox(height: _getResponsiveSize(context, 4)),
                                        Text(
                                          'Tu contraseña debe cumplir con los siguientes requisitos',
                                          style: TextStyle(
                                            fontSize: _getResponsiveSize(context, 14),
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: _getResponsiveSize(context, 24)),

                        // Chips de requisitos compactos - Solo cuando hay texto
                        if (_passwordCtrl.text.isNotEmpty) ...[
                          Container(
                            padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
                            margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                              border: Border.all(color: Colors.grey[200]!, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: _getResponsiveSize(context, 16),
                                      color: Colors.grey[600],
                                    ),
                                    SizedBox(width: _getResponsiveSize(context, 8)),
                                    Text(
                                      'Requisitos',
                                      style: TextStyle(
                                        fontSize: _getResponsiveSize(context, 14),
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${[_validLength, _hasUpperOrDigit, _hasSpecial].where((e) => e).length}/3',
                                      style: TextStyle(
                                        fontSize: _getResponsiveSize(context, 12),
                                        fontWeight: FontWeight.w500,
                                        color: _isPasswordValid ? Colors.green[600] : Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: _getResponsiveSize(context, 12)),
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
                          ),
                        ],

                        // Password Input
                        Container(
                          padding: EdgeInsets.all(_getResponsiveSize(context, 20)),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildTextField(
                                controller: _passwordCtrl,
                                label: "Nueva contraseña",
                                obscureText: _obscurePass,
                                onToggleVisibility: () => setState(() => _obscurePass = !_obscurePass),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Campo requerido';
                                  if (!_isPasswordValid) return 'No cumple con los requisitos';
                                  return null;
                                },
                              ),
                              SizedBox(height: _getResponsiveSize(context, 16)),
                              if (_passwordCtrl.text.isNotEmpty) ...[
                                _buildPasswordStrengthIndicator(),
                                SizedBox(height: _getResponsiveSize(context, 16)),
                              ],
                              _buildTextField(
                                controller: _confirmCtrl,
                                label: "Confirmar contraseña",
                                obscureText: _obscureConfirm,
                                onToggleVisibility: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                validator: (value) {
                                  if (value?.isEmpty ?? true) return 'Campo requerido';
                                  if (value != _passwordCtrl.text) return 'Las contraseñas no coinciden';
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: _getResponsiveSize(context, 32)),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: _getResponsiveSize(context, 54),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarPassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(_getResponsiveSize(context, 16)),
                              ),
                              elevation: 0,
                              shadowColor: primaryColor.withOpacity(0.3),
                            ),
                            child: _isLoading
                                ? SizedBox(
                                    width: _getResponsiveSize(context, 24),
                                    height: _getResponsiveSize(context, 24),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    "GUARDAR CONTRASEÑA",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: _getResponsiveSize(context, 16),
                                      letterSpacing: 0.5,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        SizedBox(height: _getResponsiveSize(context, 16)),

                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            icon: Icon(Icons.arrow_back, size: _getResponsiveSize(context, 18)),
                            label: Text(
                              "Volver al inicio de sesión",
                              style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveSize(context, 16),
                                vertical: _getResponsiveSize(context, 8),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: _getResponsiveSize(context, 20)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}