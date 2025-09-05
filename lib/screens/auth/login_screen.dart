import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Agregado
import '../../providers/auth_provider.dart'; // ✅ Agregado
import '../../screens/auth/register_screen.dart';
import 'package:crud/screens/usuario/bienvenida_usuario_screen.dart';

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
  bool _wasDisconnected = false; // Variable para rastrear el estado anterior

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {Color backgroundColor = Colors.blue}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              backgroundColor == Colors.orange 
                ? Icons.wifi_off_rounded 
                : backgroundColor == Colors.red 
                  ? Icons.error_outline 
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: isSmallScreen ? 20 : 24,
            ),
            SizedBox(width: isSmallScreen ? 6 : 8),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: backgroundColor == Colors.orange 
          ? const Duration(seconds: 6) 
          : const Duration(seconds: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20)
        ),
        margin: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16, 
          vertical: isSmallScreen ? 6 : 8
        ),
        action: backgroundColor == Colors.orange 
          ? SnackBarAction(
              label: 'Verificar',
              textColor: Colors.white,
              onPressed: () async {
                await _checkConnectivity();
              },
            )
          : backgroundColor == Colors.red
            ? SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: () => _login(),
              )
            : null,
      ),
    );
  }

  Future<bool> _checkConnectivity({bool showSuccessMessage = false}) async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      
      if (connectivityResult == ConnectivityResult.none) {
        _wasDisconnected = true; // Marcamos que estuvimos desconectados
        _showMessage(
          " Sin conexión a internet\nVerifica tu WiFi o datos móviles y vuelve a intentarlo.",
          backgroundColor: Colors.orange,
        );
        return false;
      }
      
      // Solo mostrar mensaje de conexión recuperada si:
      // 1. Estuvimos previamente desconectados (_wasDisconnected = true)
      // 2. O si se solicita explícitamente (showSuccessMessage = true)
      if (_wasDisconnected || showSuccessMessage) {
        _wasDisconnected = false; // Resetear el estado
        
        if (connectivityResult == ConnectivityResult.wifi) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.wifi, color: Colors.white),
                  SizedBox(width: 8),
                  Text("✅ Conexión WiFi recuperada", 
                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        } else if (connectivityResult == ConnectivityResult.mobile) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: const [
                  Icon(Icons.signal_cellular_alt, color: Colors.white),
                  SizedBox(width: 8),
                  Text("📶 Conexión de datos móviles recuperada", 
                       style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }
      }
      
      return true;
    } catch (e) {
      _showMessage(
        "⚠️ Error al verificar la conexión\nPor favor, revisa tu configuración de red.",
        backgroundColor: Colors.redAccent,
      );
      return false;
    }
  }

  // ✅ MÉTODO CORREGIDO: Usar AuthProvider en lugar de AuthService directamente
  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    bool isConnected = await _checkConnectivity();
    if (!isConnected) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Usar AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (success) {
        debugPrint('✅ Login exitoso con AuthProvider');
        
        // ✅ Esperar un momento para que el estado se actualice
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          final rol = authProvider.rol;
          _navegarSegunRol(rol);
        }
      } else {
        // ✅ Manejo de errores mejorado
        String errorMessage = "❌ Correo o contraseña incorrectos.";
        _showMessage(errorMessage, backgroundColor: Colors.red);
      }
    } catch (e) {
      debugPrint('❌ Error en login: $e');
      _showMessage(
        "❌ Error inesperado al iniciar sesión\nIntenta nuevamente.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ MÉTODO CORREGIDO: Usar AuthProvider para Google Login
  Future<void> _loginConGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    bool isConnected = await _checkConnectivity();
    if (!isConnected) return;

    setState(() => _isLoading = true);

    try {
      // ✅ Usar AuthProvider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final success = await authProvider.loginConGoogle();

      if (success) {
        debugPrint('✅ Login con Google exitoso con AuthProvider');
        
        // ✅ Esperar un momento para que el estado se actualice
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          final rol = authProvider.rol;
          _navegarSegunRol(rol);
        }
      } else {
        // ✅ Manejo de errores para Google Login
        String errorMessage = "🔐 Error al iniciar sesión con Google\nIntenta nuevamente.";
        _showMessage(errorMessage, backgroundColor: Colors.red);
      }
    } catch (e) {
      debugPrint('❌ Error en Google login: $e');
      _showMessage(
        "❌ Error inesperado con Google Login\nIntenta nuevamente.",
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // ✅ MÉTODO CORREGIDO: Navegación mejorada
  void _navegarSegunRol(String? rol) {
    debugPrint('🔍 Navegando según rol: $rol');
    
    if (rol == 'admin' || rol == 'superAdmin') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bienvenida-admin',
        (route) => false, // ✅ Limpiar stack de navegación
        arguments: {'rol': rol},
      );
    } else if (rol == 'usuario') {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/bienvenida-usuario',
        (route) => false, // ✅ Limpiar stack de navegación
      );
    } else {
      _showMessage(
        "⚠️ Rol no válido.\nContacta al administrador.", 
        backgroundColor: Colors.red
      );
    }
  }

  InputDecoration _fieldDecoration(String label) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: const Color(0xFF212121),
        fontSize: isSmallScreen ? 14 : 16,
      ),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16, 
        vertical: isSmallScreen ? 12 : 14
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final screenWidth = media.size.width;
    final screenHeight = media.size.height;
    final isSmallScreen = screenWidth < 360;
    final isTablet = screenWidth > 768;
    
    final primaryColor = const Color(0xFFD32F2F);
    final secondaryColor = const Color(0xFF212121);
    final backgroundColor = const Color(0xFFF5F5F5);

    // Responsive dimensions
    final logoSize = isTablet 
      ? screenWidth * 0.25 
      : isSmallScreen 
        ? screenWidth * 0.35 
        : screenWidth * 0.45;
    
    final containerHeight = isTablet 
      ? screenHeight * 0.5 
      : isSmallScreen 
        ? screenHeight * 0.65 
        : screenHeight * 0.6;
    
    final horizontalPadding = isTablet 
      ? screenWidth * 0.15 
      : isSmallScreen 
        ? screenWidth * 0.04 
        : screenWidth * 0.06;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Top section with logo
          Column(
            children: [
              SizedBox(height: media.padding.top + (isSmallScreen ? 20 : 40)),

              // Back arrow
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: isSmallScreen ? 12 : 16),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios, 
                      color: Colors.black87, 
                      size: isSmallScreen ? 20 : 24
                    ),
                    onPressed: () {
                      // Navegar a BienvenidaUsuarioScreen en lugar de hacer pop
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BienvenidaUsuarioScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),

              SizedBox(height: isSmallScreen ? 10 : 20),

              // Logo with Hero animation
              Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/bola.png',
                    width: logoSize,
                    height: logoSize,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),

          // Bottom form container
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: containerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(isSmallScreen ? 40 : 50)
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            top: isSmallScreen ? 20 : 24,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 
                                    (isSmallScreen ? 20 : 24),
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Title
                                  Center(
                                    child: Text(
                                      "Iniciar Sesión",
                                      style: TextStyle(
                                        fontSize: isTablet 
                                          ? 36 
                                          : isSmallScreen 
                                            ? 22 
                                            : screenWidth < 400 ? 24 : 30,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  // Email field
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    decoration: _fieldDecoration("Correo electrónico"),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Ingrese su correo';
                                      }
                                      final reg = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
                                      if (!reg.hasMatch(value)) {
                                        return 'Correo no válido';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // Password field
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: _obscurePassword,
                                    style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                                    decoration: _fieldDecoration("Contraseña").copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: secondaryColor,
                                          size: isSmallScreen ? 20 : 24,
                                        ),
                                        onPressed: () {
                                          setState(() =>
                                              _obscurePassword = !_obscurePassword);
                                        },
                                      ),
                                    ),
                                    validator: (value) =>
                                        value == null || value.isEmpty
                                            ? 'Ingrese su contraseña'
                                            : null,
                                    onFieldSubmitted: (_) => _login(),
                                  ),
                                  SizedBox(height: isSmallScreen ? 20 : 24),
                                  
                                  // ✅ LOGIN BUTTON CON CONSUMER PARA MOSTRAR ESTADO DE CARGA
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      final isProviderLoading = authProvider.cargando;
                                      final isButtonLoading = _isLoading || isProviderLoading;
                                      
                                      return ElevatedButton(
                                        onPressed: isButtonLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          elevation: 2,
                                          shadowColor: primaryColor.withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                          ),
                                          minimumSize: Size.fromHeight(isSmallScreen ? 45 : 50),
                                        ),
                                        child: isButtonLoading
                                            ? SizedBox(
                                                height: isSmallScreen ? 20 : 24,
                                                width: isSmallScreen ? 20 : 24,
                                                child: const CircularProgressIndicator(
                                                  strokeWidth: 2.5,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              )
                                            : Text(
                                                "INICIAR SESIÓN",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 16 : 18,
                                                  color: Colors.white,
                                                ),
                                              ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: isSmallScreen ? 12 : 16),
                                  
                                  // ✅ GOOGLE LOGIN BUTTON CON CONSUMER
                                  Consumer<AuthProvider>(
                                    builder: (context, authProvider, child) {
                                      final isProviderLoading = authProvider.cargando;
                                      final isButtonLoading = _isLoading || isProviderLoading;
                                      
                                      return OutlinedButton(
                                        onPressed: isButtonLoading ? null : _loginConGoogle,
                                        style: OutlinedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          side: BorderSide(color: secondaryColor),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                          ),
                                          minimumSize: Size.fromHeight(isSmallScreen ? 45 : 50),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Image.asset(
                                              'assets/google.png', 
                                              height: isSmallScreen ? 20 : 24, 
                                              width: isSmallScreen ? 20 : 24
                                            ),
                                            SizedBox(width: isSmallScreen ? 8 : 12),
                                            Text(
                                              "Iniciar con Google",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: isSmallScreen ? 14 : 16,
                                                color: secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  SizedBox(height: isSmallScreen ? 16 : 20),
                                  
                                  // Forgot password link
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/forgot'),
                                      child: Text(
                                        "¿Olvidaste tu contraseña?",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: isSmallScreen ? 13 : 15,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 10 : 14),
                                  
                                  // Register link
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "¿No tienes cuenta? ",
                                          style: TextStyle(
                                            fontSize: isSmallScreen ? 13 : 15,
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const RegisterStepScreen(),
                                              ),
                                            );
                                          },
                                          child: Text(
                                            "Registrarse",
                                            style: TextStyle(
                                              color: primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: isSmallScreen ? 13 : 15,
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 8 : 10),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}