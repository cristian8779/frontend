import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../screens/auth/register_screen.dart';
import 'package:crud/screens/usuario/bienvenida_usuario_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String msg, {Color backgroundColor = Colors.blue}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  Future<bool> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      _showMessage(
        "¡Ups! Parece que no tienes conexión a internet.",
        backgroundColor: Colors.orange,
      );
      return false;
    }
    return true;
  }

  Future<void> _login() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    bool isConnected = await _checkConnectivity();
    if (!isConnected) return;

    setState(() => _isLoading = true);

    final success = await authService.login(
      emailController.text.trim(),
      passwordController.text.trim(),
    );

    if (success) {
      final rol = await authService.getRol();
      _navegarSegunRol(rol);
    } else {
      String errorMessage = authService.message ?? "Correo o contraseña incorrectos.";
      if (authService.message?.contains("522") ?? false) {
        errorMessage = "¡Vaya! Algo salió mal. Intenta nuevamente.";
      }
      _showMessage(errorMessage, backgroundColor: Colors.red);
    }

    setState(() => _isLoading = false);
  }

  Future<void> _loginConGoogle() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    bool isConnected = await _checkConnectivity();
    if (!isConnected) return;

    setState(() => _isLoading = true);

    final success = await authService.loginConGoogle();

    if (success) {
      final rol = await authService.getRol();
      _navegarSegunRol(rol);
    } else {
      if (authService.message != null &&
          authService.message != "No se completó el inicio de sesión con Google.") {
        _showMessage(authService.message ?? "Error al iniciar sesión con Google.",
            backgroundColor: Colors.redAccent);
      }
    }

    setState(() => _isLoading = false);
  }

  void _navegarSegunRol(String? rol) {
    if (rol == 'admin' || rol == 'superAdmin') {
      Navigator.pushReplacementNamed(
        context,
        '/bienvenida-admin',
        arguments: {'rol': rol},
      );
    } else if (rol == 'usuario') {
      Navigator.pushReplacementNamed(context, '/bienvenida-usuario');
    } else {
      _showMessage("Rol no válido.", backgroundColor: Colors.red);
    }
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF212121)),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final primaryColor = const Color(0xFFD32F2F);
    final secondaryColor = const Color(0xFF212121);
    final backgroundColor = const Color(0xFFF5F5F5);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 40),

              // ✅ Flechita para volver
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BienvenidaUsuarioScreen()),
                    );
                  },
                ),
              ),

              Center(
                child: Hero(
                  tag: 'logo',
                  child: Image.asset(
                    'assets/bola.png',
                    width: media.size.width * 0.45,
                    height: media.size.width * 0.45,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: media.size.height * 0.6,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: media.size.width * 0.06),
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.only(
                            top: 24,
                            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: IntrinsicHeight(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Center(
                                    child: Text(
                                      "Iniciar Sesión",
                                      style: TextStyle(
                                        fontSize: media.size.width < 400 ? 24 : 30,
                                        fontWeight: FontWeight.bold,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  TextFormField(
                                    controller: emailController,
                                    keyboardType: TextInputType.emailAddress,
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
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: passwordController,
                                    obscureText: _obscurePassword,
                                    decoration: _fieldDecoration("Contraseña").copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off
                                              : Icons.visibility,
                                          color: secondaryColor,
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
                                  const SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                    child: _isLoading
                                        ? const CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          )
                                        : const Text(
                                            "INICIAR",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  const SizedBox(height: 16),
                                  OutlinedButton(
                                    onPressed: _isLoading ? null : _loginConGoogle,
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: BorderSide(color: secondaryColor),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      minimumSize: const Size.fromHeight(50),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/google.png', height: 24, width: 24),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Iniciar con Google",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: secondaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Center(
                                    child: GestureDetector(
                                      onTap: () => Navigator.pushNamed(context, '/forgot'),
                                      child: Text(
                                        "¿Olvidaste tu contraseña?",
                                        style: TextStyle(
                                          color: primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Text("¿No tienes cuenta? "),
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
                                              decoration: TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
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
