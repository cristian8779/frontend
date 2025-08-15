import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../providers/auth_provider.dart';

// Definir colores de la app de manera global
final Color backgroundColor = const Color(0xFFF8F9FA);
final Color primaryColor = const Color(0xFFBE0C0C);
final Color surfaceColor = const Color(0xFFFFFFFF);
final Color textPrimary = const Color(0xFF1A1A1A);
final Color textSecondary = const Color(0xFF6B7280);

void mostrarOpcionesDeConfiguracion({
  required BuildContext context,
  required String rol,
}) {
  Navigator.push(
    context,
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => 
          ConfiguracionScreen(rol: rol),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ),
  );
}

class ConfiguracionScreen extends StatelessWidget {
  final String rol;

  const ConfiguracionScreen({Key? key, required this.rol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String rolNormalizado = rol.trim();

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    _buildHeader(),
                    const SizedBox(height: 40),
                    
                    // Sección de cuenta
                    _buildSectionHeader("Mi Cuenta"),
                    const SizedBox(height: 16),
                    
                    if (rolNormalizado == "admin" || rolNormalizado == "superAdmin")
                      _buildPasswordOption(context),

                    // Opciones avanzadas solo para superAdmin
                    if (rolNormalizado == "superAdmin") ...[
                      const SizedBox(height: 32),
                      _buildSectionHeader("Panel de Control"),
                      const SizedBox(height: 16),
                      _buildAdvancedOptions(context),
                    ],

                    const SizedBox(height: 32),
                    
                    // Sección de sesión
                    _buildSectionHeader("Sesión"),
                    const SizedBox(height: 16),
                    
                    if (rolNormalizado == "admin" || rolNormalizado == "superAdmin")
                      _buildLogoutOption(context),

                    const SizedBox(height: 40),
                    _buildVersionInfo(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildAppBar(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF374151),
            ),
            iconSize: 20,
            padding: const EdgeInsets.all(8),
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Text(
            'Configuración',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.settings_outlined,
            color: primaryColor,
            size: 24,
          ),
        ),
      ],
    ),
  );
}

Widget _buildHeader() {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          const Color(0xFFF8F9FA),
        ],
      ),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: const Color(0xFFE5E7EB),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryColor.withOpacity(0.15),
                primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.manage_accounts_outlined,
            size: 40,
            color: primaryColor,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Centro de Control',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Administra tu cuenta y las configuraciones del sistema',
          style: TextStyle(
            fontSize: 15,
            color: textSecondary,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildSectionHeader(String title) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    child: Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            color: textPrimary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    ),
  );
}

Widget _buildPasswordOption(BuildContext context) {
  return _buildModernOption(
    icon: Icons.lock_outline_rounded,
    iconColor: const Color(0xFF3B82F6),
    iconBg: const Color(0xFF3B82F6).withOpacity(0.12),
    title: "Cambiar contraseña",
    subtitle: "Actualiza tu contraseña de acceso",
    hasNewBadge: false,
    onTap: () {
      Navigator.pushNamed(context, '/forgot');
    },
  );
}

Widget _buildAdvancedOptions(BuildContext context) {
  return Column(
    children: [
      _buildModernOption(
        icon: Icons.group_outlined,
        iconColor: const Color(0xFF8B5CF6),
        iconBg: const Color(0xFF8B5CF6).withOpacity(0.12),
        title: "Ver administradores",
        subtitle: "Gestionar usuarios administrativos",
        hasNewBadge: false,
        onTap: () {
          Navigator.pushNamed(context, '/ver-admins');
        },
      ),
      const SizedBox(height: 12),
      _buildModernOption(
        icon: Icons.person_add_alt_1_outlined,
        iconColor: const Color(0xFF10B981),
        iconBg: const Color(0xFF10B981).withOpacity(0.12),
        title: "Invitar usuarios",
        subtitle: "Enviar invitaciones a nuevos miembros",
        hasNewBadge: true,
        onTap: () {
          Navigator.pushNamed(context, '/invitaciones');
        },
      ),
    ],
  );
}

Widget _buildLogoutOption(BuildContext context) {
  return _buildModernOption(
    icon: Icons.logout_rounded,
    iconColor: const Color(0xFFEF4444),
    iconBg: const Color(0xFFEF4444).withOpacity(0.12),
    title: "Cerrar sesión",
    subtitle: "Salir de tu cuenta actual",
    hasNewBadge: false,
    isDangerous: true,
    onTap: () async {
      final shouldLogout = await _showLogoutConfirmation(context);

      if (shouldLogout == true) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.cerrarSesion();

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/bienvenida-usuario',
          (route) => false,
        );
      }
    },
  );
}

Future<bool?> _showLogoutConfirmation(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: Colors.white,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.logout_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '¿Cerrar sesión?',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
      content: const Text(
        'Tu sesión actual será cerrada y deberás iniciar sesión nuevamente para acceder al sistema.',
        style: TextStyle(
          fontSize: 15,
          color: Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            'Cancelar',
            style: TextStyle(
              color: textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF4444),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text(
            'Cerrar sesión',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildVersionInfo() {
  return Center(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Versión 1.0.0",
                style: TextStyle(
                  fontSize: 14,
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                "Build 2024.08",
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildModernOption({
  required IconData icon,
  required Color iconColor,
  required Color iconBg,
  required String title,
  required String subtitle,
  required bool hasNewBadge,
  bool isDangerous = false,
  required VoidCallback onTap,
}) {
  return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: iconColor.withOpacity(0.1),
      highlightColor: iconColor.withOpacity(0.05),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDangerous 
              ? const Color(0xFFEF4444).withOpacity(0.2)
              : const Color(0xFFE5E7EB), 
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 26,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (hasNewBadge) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Nuevo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                color: textSecondary,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}