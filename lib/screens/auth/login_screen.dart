// lib/screens/auth/login_screen.dart
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../screens/auth/register_screen.dart';
import 'package:crud/screens/usuario/bienvenida_usuario_screen.dart';
import 'package:crud/theme/login/app_theme.dart';
import 'package:crud/screens/auth/privacy_policy_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _wasDisconnected = false;
  bool _hasShownSuccessMessage = false;

  @override
  void initState() {
    super.initState();
    // Mostrar mensaje después de que el widget se construya
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSuccessMessage();
    });
  }

  void _checkForSuccessMessage() {
    if (_hasShownSuccessMessage || !mounted) return;
    
    final args = ModalRoute.of(context)?.settings.arguments;
    
    if (args != null && args is Map) {
      final showMessage = args['showSuccessMessage'] as bool?;
      final message = args['message'] as String?;
      
      if (showMessage == true && message != null) {
        _hasShownSuccessMessage = true;
        
        // Esperar a que la UI esté completamente estable
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          
          try {
            final snackBar = SnackBarStyles.buildSnackBar(
              context,
              message,
              backgroundColor: AppColors.success,
            );
            ScaffoldMessenger.of(context).showSnackBar(snackBar);
          } catch (e) {
            debugPrint('Error mostrando mensaje de éxito: $e');
          }
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {Color backgroundColor = AppColors.primary}) {
    if (!mounted) return;

    try {
      final snackBar = SnackBarStyles.buildSnackBar(
        context,
        msg,
        backgroundColor: backgroundColor,
        action: _getSnackBarAction(backgroundColor),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      debugPrint('Error mostrando SnackBar: $e');
      // No propagar el error, solo loguearlo
    }
  }

  SnackBarAction? _getSnackBarAction(Color backgroundColor) {
    if (backgroundColor == AppColors.warning) {
      return SnackBarAction(
        label: 'Verificar',
        textColor: AppColors.textOnPrimary,
        onPressed: () async => await _checkConnectivity(),
      );
    } else if (backgroundColor == AppColors.error) {
      return SnackBarAction(
        label: 'Reintentar',
        textColor: AppColors.textOnPrimary,
        onPressed: _login,
      );
    }
    return null;
  }

  Future<bool> _checkConnectivity({bool showSuccessMessage = false}) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _wasDisconnected = true;
        _showMessage(
          "Sin conexión a internet\nVerifica tu WiFi o datos móviles y vuelve a intentarlo.",
          backgroundColor: AppColors.warning,
        );
        return false;
      }
      
      if (_wasDisconnected || showSuccessMessage) {
        _wasDisconnected = false;
        _showConnectivityRestored(connectivityResult);
      }
      
      return true;
    } catch (e) {
      _showMessage(
        "Error al verificar la conexión\nPor favor, revisa tu configuración de red.",
        backgroundColor: AppColors.errorAccent,
      );
      return false;
    }
  }

  void _showConnectivityRestored(ConnectivityResult connectivityResult) {
    final connectivityType = connectivityResult == ConnectivityResult.wifi
        ? ConnectivityType.wifi
        : ConnectivityType.mobile;
        
    final snackBar = SnackBarStyles.buildConnectivitySnackBar(
      context,
      connectivityType,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    if (!await _checkConnectivity()) return;

    // Capturar la referencia al ScaffoldMessenger ANTES de operaciones async
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      if (success) {
        // Login exitoso - navegar inmediatamente sin mostrar mensaje
        debugPrint('Login exitoso con AuthProvider');
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          _navegarSegunRol(authProvider.rol);
        }
      } else {
        // Login fallido - actualizar estado y mostrar error
        if (mounted) {
          setState(() => _isLoading = false);
        }
        
        // Construir y mostrar el SnackBar usando la referencia capturada
        try {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: const Text("Correo o contraseña incorrectos."),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _login,
              ),
            ),
          );
        } catch (e) {
          debugPrint('Error mostrando SnackBar: $e');
        }
      }
    } catch (e) {
      debugPrint('Error en login: $e');
      
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Mostrar mensaje de error usando la referencia capturada
      try {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text("Error inesperado al iniciar sesión\nIntenta nuevamente."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Reintentar',
              textColor: Colors.white,
              onPressed: _login,
            ),
          ),
        );
      } catch (e) {
        debugPrint('Error mostrando SnackBar de error: $e');
      }
    }
  }

  Future<void> _loginConGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!await _checkConnectivity()) return;

    // Capturar la referencia al ScaffoldMessenger ANTES de operaciones async
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Primer intento sin términos aceptados
      final success = await authProvider.loginConGoogle(terminosAceptados: false);

      if (!mounted) {
        debugPrint('Widget desmontado después de loginConGoogle');
        return;
      }

      // Si requiere términos, navegar a la pantalla de términos
      if (!success && authProvider.mensaje == "requiere_terminos") {
        setState(() => _isLoading = false);
        
        debugPrint('Navegando a pantalla de términos');
        
        // Navegar y esperar resultado
        final terminosAceptados = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => const PrivacyPolicyScreen(),
          ),
        );

        if (!mounted) {
          debugPrint('Widget desmontado después de navegar a términos');
          return;
        }

        if (terminosAceptados == true) {
          // El usuario aceptó los términos
          debugPrint('Términos aceptados, creando cuenta...');
          setState(() => _isLoading = true);
          
          // Llamar al método que acepta los términos con los datos ya guardados
          final successConTerminos = await authProvider.aceptarTerminosYCrearCuenta();
          
          if (!mounted) {
            debugPrint('Widget desmontado después de crear cuenta');
            return;
          }
          
          await _handleLoginResult(successConTerminos, authProvider.rol, isGoogle: true);
        } else {
          // El usuario canceló o rechazó los términos
          debugPrint('Términos rechazados o cancelados');
          
          // Limpiar datos pendientes de Google
          authProvider.limpiarDatosGooglePendientes();
          
          if (mounted) {
            setState(() => _isLoading = false);
            
            try {
              scaffoldMessenger.showSnackBar(
                const SnackBar(
                  content: Text("Debes aceptar los términos para crear una cuenta."),
                  backgroundColor: AppColors.warning,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } catch (e) {
              debugPrint('Error mostrando SnackBar de términos: $e');
            }
          }
        }
      } else if (success) {
        // Usuario existente - login exitoso
        debugPrint('Login con Google exitoso (usuario existente)');
        await _handleLoginResult(true, authProvider.rol, isGoogle: true);
      } else {
        // Error diferente
        debugPrint('Error en Google login: ${authProvider.mensaje}');
        
        String errorMessage = authProvider.mensaje ?? "Error al iniciar sesión con Google";
        
        // Personalizar mensaje según el error
        if (errorMessage.contains("configuración del servidor")) {
          errorMessage = "Error de configuración del servidor\nContacta al soporte técnico.";
        } else if (errorMessage.contains("sin_conexion")) {
          errorMessage = "Sin conexión a internet";
        } else if (errorMessage.contains("timeout")) {
          errorMessage = "Tiempo de espera agotado\nIntenta nuevamente.";
        } else if (errorMessage != "Inicio de sesion cancelado") {
          errorMessage = "Error al iniciar sesión con Google\n$errorMessage";
        }
        
        if (mounted) {
          setState(() => _isLoading = false);
          
          try {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          } catch (e) {
            debugPrint('Error mostrando SnackBar de error Google: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error inesperado en Google login: $e');
      debugPrint('Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() => _isLoading = false);
        
        try {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text("Error inesperado con Google Login\nIntenta nuevamente."),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          debugPrint('Error mostrando SnackBar de error inesperado: $e');
        }
      }
    }
  }

  Future<void> _handleLoginResult(bool success, String? rol, {bool isGoogle = false}) async {
    if (success) {
      debugPrint('Login exitoso ${isGoogle ? "con Google " : ""}con AuthProvider');
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        _navegarSegunRol(rol);
      }
    } else {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final mensaje = authProvider.mensaje;
      
      String errorMessage;
      
      if (isGoogle) {
        if (mensaje?.contains("configuración") ?? false) {
          errorMessage = "Error de configuración del servidor\nContacta al soporte.";
        } else if (mensaje == "Inicio de sesion cancelado") {
          // No mostrar mensaje si el usuario canceló
          return;
        } else {
          errorMessage = "Error al iniciar sesión con Google\nIntenta nuevamente.";
        }
      } else {
        errorMessage = "Correo o contraseña incorrectos.";
      }
      
      _showMessage(errorMessage, backgroundColor: AppColors.error);
    }
  }

  void _navegarSegunRol(String? rol) {
    debugPrint('Navegando según rol: $rol');
    
    if (rol == 'admin' || rol == 'superAdmin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bienvenida-admin',
        (route) => false,
        arguments: {'rol': rol},
      );
    } else if (rol == 'usuario') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bienvenida-usuario',
        (route) => false,
      );
    } else {
      _showMessage(
        "Rol no válido.\nContacta al administrador.", 
        backgroundColor: AppColors.error
      );
    }
  }

  Widget _buildTopSection(BuildContext context) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    
    return Column(
      children: [
        SizedBox(height: ThemeUtils.getResponsiveTopSafeArea(context)),
        
        // Back arrow
        Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: EdgeInsets.only(left: isSmallScreen ? 12 : 16),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios, 
                color: AppColors.textSecondary, 
                size: isSmallScreen ? AppDimensions.iconSmall : AppDimensions.iconMedium
              ),
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BienvenidaUsuarioScreen(),
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: isSmallScreen ? 10 : 20),
        
        // Logo
        Center(
          child: ThemeUtils.buildLogoHero(context),
        ),
      ],
    );
  }

  Widget _buildFormContainer(BuildContext context) {
    final containerHeight = AppDimensions.getResponsiveContainerHeight(context);
    final horizontalPadding = AppDimensions.getResponsivePadding(context);
    
    return Container(
      height: containerHeight,
      width: double.infinity,
      decoration: ThemeUtils.getMainContainerDecoration(context),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: _buildForm(context),
        ),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              top: AppDimensions.isSmallScreen(context) ? 20 : 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 
                      (AppDimensions.isSmallScreen(context) ? 20 : 24),
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: _buildFormFields(context),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormFields(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Title
        Center(
          child: Text(
            "Iniciar Sesión",
            style: AppTextStyles.getResponsiveHeading(context),
          ),
        ),
        ThemeUtils.getResponsiveVerticalSpace(context, smallScreenSpace: 16, normalScreenSpace: 20),
        
        // Email field
        _buildEmailField(),
        ThemeUtils.getResponsiveVerticalSpace(context, smallScreenSpace: 12, normalScreenSpace: 16),
        
        // Password field  
        _buildPasswordField(),
        ThemeUtils.getResponsiveVerticalSpace(context, smallScreenSpace: 20, normalScreenSpace: 24),
        
        // Login buttons
        _buildLoginButton(),
        ThemeUtils.getResponsiveVerticalSpace(context, smallScreenSpace: 12, normalScreenSpace: 16),
        
        _buildGoogleLoginButton(),
        ThemeUtils.getResponsiveVerticalSpace(context, smallScreenSpace: 16, normalScreenSpace: 20),
        
        // Links
        _buildForgotPasswordLink(),
        SizedBox(height: AppDimensions.isSmallScreen(context) ? 10 : 14),
        
        _buildRegisterLink(),
        SizedBox(height: AppDimensions.isSmallScreen(context) ? AppDimensions.spaceSmall : 10),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: emailController,
      keyboardType: TextInputType.emailAddress,
      style: AppTextStyles.getResponsiveInput(context),
      decoration: InputDecorations.getFieldDecoration("Correo electrónico", context),
      validator: ThemeUtils.validateEmail,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: passwordController,
      obscureText: _obscurePassword,
      style: AppTextStyles.getResponsiveInput(context),
      decoration: InputDecorations.getPasswordFieldDecoration(
        "Contraseña",
        context,
        _obscurePassword,
        () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (value) => ThemeUtils.validateRequired(value, 'contraseña'),
      onFieldSubmitted: (_) => _login(),
    );
  }

  Widget _buildLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isProviderLoading = authProvider.cargando;
        final isButtonLoading = _isLoading || isProviderLoading;
        
        return ElevatedButton(
          onPressed: isButtonLoading ? null : _login,
          style: ButtonStyles.getPrimaryButtonStyle(context),
          child: isButtonLoading
              ? ButtonStyles.getLoadingIndicator(context)
              : Text(
                  "INICIAR SESIÓN",
                  style: AppTextStyles.getResponsiveButton(context),
                ),
        );
      },
    );
  }

  Widget _buildGoogleLoginButton() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isProviderLoading = authProvider.cargando;
        final isButtonLoading = _isLoading || isProviderLoading;
        
        return OutlinedButton(
          onPressed: isButtonLoading ? null : _loginConGoogle,
          style: ButtonStyles.getOutlinedButtonStyle(context),
          child: ButtonStyles.getGoogleButtonContent(context),
        );
      },
    );
  }

  Widget _buildForgotPasswordLink() {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/forgot'),
        child: Text(
          "¿Olvidaste tu contraseña?",
          style: AppTextStyles.getResponsiveLink(context),
        ),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "¿No tienes cuenta? ",
            style: AppTextStyles.getResponsiveText(context),
          ),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const RegisterStepScreen(),
              ),
            ),
            child: Text(
              "Registrarse",
              style: AppTextStyles.getResponsiveLink(context),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top section with logo
          _buildTopSection(context),

          // Bottom form container
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildFormContainer(context),
          ),
        ],
      ),
    );
  }
}