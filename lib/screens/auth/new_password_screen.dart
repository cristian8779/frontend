import 'package:flutter/material.dart';
import '../../services/password_service.dart';
import '../../theme/new_password/new_password_colors.dart';
import '../../theme/new_password/new_password_dimensions.dart';
import '../../theme/new_password/new_password_styles.dart';
import '../../theme/new_password/new_password_animations.dart';

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
  bool _showRequirements = false;

  bool _validLength = false;
  bool _hasUpper = false;
  bool _hasLower = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;

  late NewPasswordAnimationManager _animationManager;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_validatePassword);
    _animationManager = NewPasswordAnimationManager(vsync: this);
    _animationManager.startMainAnimation();
  }

  @override
  void dispose() {
    _animationManager.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final pass = _passwordCtrl.text;
    final shouldShowRequirements = pass.isNotEmpty;
    
    setState(() {
      _validLength = pass.length >= 8;
      _hasUpper = pass.contains(RegExp(r'[A-Z]'));
      _hasLower = pass.contains(RegExp(r'[a-z]'));
      _hasDigit = pass.contains(RegExp(r'\d'));
      _hasSpecial = pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });

    // Controlar la animación de los requisitos
    if (shouldShowRequirements && !_showRequirements) {
      setState(() => _showRequirements = true);
      _animationManager.startRequirementsAnimation();
    } else if (!shouldShowRequirements && _showRequirements) {
      _animationManager.reverseRequirementsAnimation();
      Future.delayed(NewPasswordAnimations.slowDuration, () {
        if (mounted) setState(() => _showRequirements = false);
      });
    }
  }

  bool get _isPasswordValid =>
      _validLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

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
    if (_passwordStrength < 0.4) return NewPasswordColors.strengthWeak;
    if (_passwordStrength < 0.6) return NewPasswordColors.strengthFair;
    if (_passwordStrength < 0.8) return NewPasswordColors.strengthGood;
    return NewPasswordColors.strengthStrong;
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
      NewPasswordStyles.getSnackBar(context, msg, isSuccess),
    );
  }

  Widget _buildCompactChip(String text, bool isValid, int index) {
    return NewPasswordAnimations.createScaleAnimation(
      index: index,
      child: NewPasswordAnimations.createAnimatedContainer(
        duration: NewPasswordAnimations.fastDuration,
        decoration: NewPasswordStyles.getChipDecoration(context, isValid),
        padding: EdgeInsets.symmetric(
          horizontal: NewPasswordDimensions.getResponsiveSize(context, 10),
          vertical: NewPasswordDimensions.getResponsiveSize(context, 6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NewPasswordAnimations.createIconSwitcher(
              child: Icon(
                isValid ? Icons.check_circle : Icons.radio_button_unchecked,
                key: ValueKey(isValid),
                color: isValid ? NewPasswordColors.requirementValid : NewPasswordColors.requirementInvalid,
                size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconMedium),
              ),
            ),
            SizedBox(width: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium)),
            Text(
              text,
              style: NewPasswordStyles.getChipTextStyle(context, isValid),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator() {
    return NewPasswordAnimations.createAnimatedContainer(
      duration: NewPasswordAnimations.mediumDuration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Seguridad de la contraseña',
                style: NewPasswordStyles.getPasswordStrengthLabelStyle(context),
              ),
              NewPasswordAnimations.createIconSwitcher(
                child: Text(
                  _strengthText,
                  key: ValueKey(_strengthText),
                  style: NewPasswordStyles.getPasswordStrengthValueStyle(context, _strengthColor),
                ),
              ),
            ],
          ),
          SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium)),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.radiusMedium)
            ),
            child: NewPasswordAnimations.createProgressAnimation(
              value: _passwordStrength,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  backgroundColor: NewPasswordColors.surfaceTint,
                  valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                  minHeight: NewPasswordDimensions.getResponsiveSize(context, 8),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementsSection() {
    if (!_showRequirements) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _animationManager.requirementsFadeAnimation,
        _animationManager.requirementsSlideAnimation
      ]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animationManager.requirementsSlideAnimation.value),
          child: Opacity(
            opacity: _animationManager.requirementsFadeAnimation.value,
            child: Container(
              padding: EdgeInsets.all(
                NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXXLarge)
              ),
              margin: EdgeInsets.only(
                bottom: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)
              ),
              decoration: NewPasswordStyles.getRequirementsCardDecoration(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(
                          NewPasswordDimensions.getResponsiveSize(context, 6)
                        ),
                        decoration: NewPasswordStyles.getIconContainerDecoration(
                          context, 
                          NewPasswordColors.primaryWithOpacity(0.1)
                        ),
                        child: Icon(
                          Icons.security,
                          size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconLarge),
                          color: NewPasswordColors.iconPrimary,
                        ),
                      ),
                      SizedBox(width: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceLarge)),
                      Text(
                        'Requisitos de seguridad',
                        style: NewPasswordStyles.getSectionTitleStyle(context),
                      ),
                      const Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium),
                          vertical: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXSmall),
                        ),
                        decoration: NewPasswordStyles.getChipCountDecoration(context, _isPasswordValid),
                        child: Text(
                          '${[_validLength, _hasUpperOrDigit, _hasSpecial].where((e) => e).length}/3',
                          style: NewPasswordStyles.getChipCountStyle(context, _isPasswordValid),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),
                  Wrap(
                    spacing: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium),
                    runSpacing: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceMedium),
                    children: [
                      _buildCompactChip('8+ caracteres', _validLength, 0),
                      _buildCompactChip('Mayús + minús + número', _hasUpperOrDigit, 1),
                      _buildCompactChip('Símbolo especial', _hasSpecial, 2),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
      style: NewPasswordStyles.getBodyStyle(context),
      decoration: NewPasswordStyles.getTextFieldDecoration(context, label).copyWith(
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: NewPasswordColors.iconSecondary,
            size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconXLarge),
          ),
          onPressed: onToggleVisibility,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NewPasswordColors.background,
      appBar: AppBar(
        title: Text(
          'Nueva Contraseña',
          style: NewPasswordStyles.getAppBarTitleStyle(context),
        ),
        backgroundColor: NewPasswordColors.surface,
        foregroundColor: NewPasswordColors.primary,
        elevation: NewPasswordDimensions.elevationNone,
        shadowColor: NewPasswordColors.shadowDark,
        scrolledUnderElevation: 1,
      ),
      body: AnimatedBuilder(
        animation: _animationManager.fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _animationManager.fadeAnimation.value,
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: NewPasswordDimensions.getResponsivePadding(context),
                physics: const BouncingScrollPhysics(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: NewPasswordDimensions.getContentConstraints(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Container(
                          padding: EdgeInsets.all(
                            NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXXLarge)
                          ),
                          decoration: NewPasswordStyles.getCardDecoration(context),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(
                                  NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceLarge)
                                ),
                                decoration: NewPasswordStyles.getIconContainerDecoration(
                                  context,
                                  NewPasswordColors.primaryWithOpacity(0.1),
                                ),
                                child: Icon(
                                  Icons.lock_reset,
                                  color: NewPasswordColors.primary,
                                  size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconXXLarge),
                                ),
                              ),
                              SizedBox(width: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Crear nueva contraseña',
                                      style: NewPasswordStyles.getHeadingStyle(context),
                                    ),
                                    SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXSmall)),
                                    Text(
                                      'Tu contraseña debe ser segura y fácil de recordar',
                                      style: NewPasswordStyles.getSubheadingStyle(context),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXXXLarge)),

                        // Sección de requisitos animada
                        _buildRequirementsSection(),

                        // Password Input
                        Container(
                          padding: EdgeInsets.all(
                            NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXXLarge)
                          ),
                          decoration: NewPasswordStyles.getCardDecoration(context),
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
                              SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),
                              if (_passwordCtrl.text.isNotEmpty) ...[
                                _buildPasswordStrengthIndicator(),
                                SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),
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

                        SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceGiant)),

                        // Action Buttons
                        SizedBox(
                          width: double.infinity,
                          height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.buttonHeight),
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _guardarPassword,
                            style: NewPasswordStyles.getPrimaryButtonStyle(context),
                            child: _isLoading
                                ? SizedBox(
                                    width: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconXXLarge),
                                    height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconXXLarge),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    "GUARDAR CONTRASEÑA",
                                    style: NewPasswordStyles.getButtonTextStyle(context),
                                  ),
                          ),
                        ),

                        SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXLarge)),

                        Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                            icon: Icon(
                              Icons.arrow_back, 
                              size: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.iconLarge)
                            ),
                            label: Text(
                              "Volver al inicio de sesión",
                              style: TextStyle(
                                fontSize: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.fontMedium)
                              ),
                            ),
                            style: NewPasswordStyles.getSecondaryButtonStyle(context),
                          ),
                        ),

                        SizedBox(height: NewPasswordDimensions.getResponsiveSize(context, NewPasswordDimensions.spaceXXLarge)),
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