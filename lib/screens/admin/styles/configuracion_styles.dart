// configuracion_styles.dart
import 'package:flutter/material.dart';

class ConfiguracionTheme {
  // Colores principales de la app
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color primaryColor = Color(0xFFBE0C0C);
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Colores específicos de la UI
  static const Color appBarBackgroundColor = Colors.white;
  static const Color backButtonColor = Color(0xFFF3F4F6);
  static const Color backButtonIconColor = Color(0xFF374151);
  static const Color headerGradientStart = Colors.white;
  static const Color headerGradientEnd = Color(0xFFF8F9FA);
  static const Color borderColor = Color(0xFFE5E7EB);
  
  // Colores de opciones
  static const Color passwordOptionColor = Color(0xFF3B82F6);
  static const Color adminOptionColor = Color(0xFF8B5CF6);
  static const Color inviteOptionColor = Color(0xFF10B981);
  static const Color transferOptionColor = Color(0xFFFF6B35); // Nuevo color para transferencia
  static const Color logoutOptionColor = Color(0xFFEF4444);
  static const Color newBadgeColor = Color(0xFF10B981);
  static const Color versionInfoBackgroundColor = Color(0xFFF3F4F6);
  
  // Iconos
  static const IconData backIcon = Icons.arrow_back_ios_new_rounded;
  static const IconData settingsIcon = Icons.settings_outlined;
  static const IconData headerIcon = Icons.manage_accounts_outlined;
  static const IconData passwordIcon = Icons.lock_outline_rounded;
  static const IconData adminIcon = Icons.group_outlined;
  static const IconData inviteIcon = Icons.person_add_alt_1_outlined;
  static const IconData transferIcon = Icons.swap_horiz_rounded; // Nuevo icono para transferencia
  static const IconData logoutIcon = Icons.logout_rounded;
  static const IconData versionIcon = Icons.info_outline_rounded;
  static const IconData arrowForwardIcon = Icons.arrow_forward_ios_rounded;
  
  // Opacidades
  static const double shadowOpacity = 0.05;
  static const double primaryOpacity = 0.1;
  static const double borderOpacity = 0.2;
  static const double optionIconOpacity = 0.12;
  static const double splashOpacity = 0.1;
  static const double highlightOpacity = 0.05;
}

class ConfiguracionDimensions {
  // Breakpoints
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
  
  // Espaciado estándar
  static const double defaultSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  static const double sectionSpacing = 40.0;
  
  // Border radius
  static const double smallBorderRadius = 8.0;
  static const double mediumBorderRadius = 12.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 20.0;
  static const double headerBorderRadius = 24.0;
  
  // Padding estándar
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 20.0;
  static const double extraLargePadding = 28.0;
  
  // Función para obtener dimensiones responsivas
  static Map<String, double> getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= tabletBreakpoint;
    final isDesktop = screenWidth >= desktopBreakpoint;
    
    if (isDesktop) {
      return {
        'horizontalPadding': 32.0,
        'maxWidth': 800.0,
        'headerIconSize': 48.0,
        'headerTitleSize': 28.0,
        'headerSubtitleSize': 17.0,
        'sectionTitleSize': 15.0,
        'optionTitleSize': 19.0,
        'optionSubtitleSize': 16.0,
        'appBarTitleSize': 22.0,
        'appBarIconSize': 22.0,
      };
    } else if (isTablet) {
      return {
        'horizontalPadding': 28.0,
        'maxWidth': 600.0,
        'headerIconSize': 44.0,
        'headerTitleSize': 26.0,
        'headerSubtitleSize': 16.0,
        'sectionTitleSize': 14.0,
        'optionTitleSize': 18.0,
        'optionSubtitleSize': 15.0,
        'appBarTitleSize': 21.0,
        'appBarIconSize': 21.0,
      };
    } else {
      return {
        'horizontalPadding': 24.0,
        'maxWidth': double.infinity,
        'headerIconSize': 40.0,
        'headerTitleSize': 24.0,
        'headerSubtitleSize': 15.0,
        'sectionTitleSize': 13.0,
        'optionTitleSize': 17.0,
        'optionSubtitleSize': 14.0,
        'appBarTitleSize': 20.0,
        'appBarIconSize': 20.0,
      };
    }
  }
  
  // Helpers de breakpoints
  static bool isTablet(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
}

class ConfiguracionTextStyles {
  static TextStyle getAppBarTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['appBarTitleSize']!,
      fontWeight: FontWeight.w700,
      color: ConfiguracionTheme.textPrimary,
      letterSpacing: -0.5,
    );
  }
  
  static TextStyle getHeaderTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['headerTitleSize']!,
      fontWeight: FontWeight.w800,
      color: ConfiguracionTheme.textPrimary,
      letterSpacing: -0.8,
    );
  }
  
  static TextStyle getHeaderSubtitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['headerSubtitleSize']!,
      color: ConfiguracionTheme.textSecondary,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
  }
  
  static TextStyle getSectionTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['sectionTitleSize']!,
      color: ConfiguracionTheme.textPrimary,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    );
  }
  
  static TextStyle getOptionTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['optionTitleSize']!,
      fontWeight: FontWeight.w700,
      color: ConfiguracionTheme.textPrimary,
      letterSpacing: -0.3,
    );
  }
  
  static TextStyle getOptionSubtitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['optionSubtitleSize']!,
      color: ConfiguracionTheme.textSecondary,
      fontWeight: FontWeight.w500,
      height: 1.3,
    );
  }
  
  static TextStyle getVersionTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['optionSubtitleSize']!,
      color: ConfiguracionTheme.textPrimary,
      fontWeight: FontWeight.w700,
    );
  }
  
  static TextStyle getVersionSubtitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['optionSubtitleSize']! - 2,
      color: ConfiguracionTheme.textSecondary,
      fontWeight: FontWeight.w500,
    );
  }
  
  static TextStyle getDialogTitleStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: dimensions['optionTitleSize']! - 1,
      color: ConfiguracionTheme.textPrimary,
    );
  }
  
  static TextStyle getDialogContentStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontSize: dimensions['optionSubtitleSize']! + 1,
      color: ConfiguracionTheme.textSecondary,
      height: 1.5,
    );
  }
  
  static TextStyle getDialogButtonStyle(Map<String, double> dimensions) {
    return TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: dimensions['optionSubtitleSize']! + 1,
    );
  }
  
  // Estilo para el badge "Nuevo"
  static const TextStyle newBadgeStyle = TextStyle(
    color: Colors.white,
    fontSize: 10,
    fontWeight: FontWeight.w700,
  );
}

class ConfiguracionDecorations {
  // AppBar
  static BoxDecoration getAppBarDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.appBarBackgroundColor,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(ConfiguracionTheme.shadowOpacity),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getBackButtonDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.backButtonColor,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.mediumBorderRadius),
    );
  }
  
  static BoxDecoration getAppBarIconDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.primaryColor.withOpacity(ConfiguracionTheme.primaryOpacity),
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.mediumBorderRadius),
    );
  }
  
  // Header
  static BoxDecoration getHeaderDecoration() {
    return BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ConfiguracionTheme.headerGradientStart,
          ConfiguracionTheme.headerGradientEnd,
        ],
      ),
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.headerBorderRadius),
      border: Border.all(
        color: ConfiguracionTheme.borderColor,
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getHeaderIconDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          ConfiguracionTheme.primaryColor.withOpacity(0.15),
          ConfiguracionTheme.primaryColor.withOpacity(0.08),
        ],
      ),
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.largeBorderRadius + 4),
      border: Border.all(
        color: ConfiguracionTheme.primaryColor.withOpacity(ConfiguracionTheme.borderOpacity),
        width: 1,
      ),
    );
  }
  
  // Section header
  static BoxDecoration getSectionIndicatorDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.primaryColor,
      borderRadius: BorderRadius.circular(2),
    );
  }
  
  // Option cards
  static BoxDecoration getOptionCardDecoration({bool isDangerous = false}) {
    return BoxDecoration(
      color: ConfiguracionTheme.surfaceColor,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.extraLargeBorderRadius),
      border: Border.all(
        color: isDangerous 
          ? ConfiguracionTheme.logoutOptionColor.withOpacity(ConfiguracionTheme.borderOpacity)
          : ConfiguracionTheme.borderColor,
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getOptionIconDecoration(Color iconBg) {
    return BoxDecoration(
      color: iconBg,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.largeBorderRadius),
    );
  }
  
  static BoxDecoration getOptionArrowDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.backButtonColor,
      borderRadius: BorderRadius.circular(10),
    );
  }
  
  static BoxDecoration getNewBadgeDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.newBadgeColor,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.smallBorderRadius),
    );
  }
  
  // Version info
  static BoxDecoration getVersionInfoDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.surfaceColor,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.largeBorderRadius),
      border: Border.all(color: ConfiguracionTheme.borderColor, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
  
  static BoxDecoration getVersionIconDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.versionInfoBackgroundColor,
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.smallBorderRadius),
    );
  }
  
  // Dialog
  static BoxDecoration getDialogDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.extraLargeBorderRadius),
    );
  }
  
  static BoxDecoration getDialogIconDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.logoutOptionColor.withOpacity(ConfiguracionTheme.primaryOpacity),
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.smallBorderRadius),
    );
  }
  
  // Dialog de transferencia
  static BoxDecoration getTransferDialogIconDecoration() {
    return BoxDecoration(
      color: ConfiguracionTheme.transferOptionColor.withOpacity(ConfiguracionTheme.primaryOpacity),
      borderRadius: BorderRadius.circular(ConfiguracionDimensions.smallBorderRadius),
    );
  }
}

class ConfiguracionLayout {
  // Padding constants
  static const EdgeInsets appBarPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const EdgeInsets backButtonPadding = EdgeInsets.all(8);
  static const EdgeInsets headerPadding = EdgeInsets.all(28);
  static const EdgeInsets headerIconPadding = EdgeInsets.all(20);
  static const EdgeInsets sectionHeaderPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 8);
  static const EdgeInsets optionCardPadding = EdgeInsets.all(20);
  static const EdgeInsets optionIconPadding = EdgeInsets.all(16);
  static const EdgeInsets versionInfoPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
  static const EdgeInsets versionIconPadding = EdgeInsets.all(8);
  static const EdgeInsets dialogButtonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 12);
  static const EdgeInsets newBadgePadding = EdgeInsets.symmetric(horizontal: 8, vertical: 3);
  static const EdgeInsets arrowIconPadding = EdgeInsets.all(6);
  
  // Specific spacing
  static const double appBarIconSpacing = 16.0;
  static const double headerSpacing = 20.0;
  static const double sectionIndicatorSpacing = 12.0;
  static const double optionSpacing = 20.0;
  static const double optionTitleSpacing = 6.0;
  static const double optionBadgeSpacing = 12.0;
  static const double optionArrowSpacing = 16.0;
  static const double versionInfoSpacing = 12.0;
  static const double dialogActionSpacing = 8.0;
  
  // Sizes
  static const double sectionIndicatorWidth = 4.0;
  static const double sectionIndicatorHeight = 20.0;
  static const double optionIconSize = 26.0;
  static const double arrowIconSize = 16.0;
  static const double versionIconSize = 18.0;
  static const double dialogIconSize = 20.0;
}

class ConfiguracionConstants {
  // Textos de la UI
  static const String appBarTitle = 'Configuración';
  static const String headerTitle = 'Centro de Control';
  static const String headerSubtitle = 'Administra tu cuenta y las configuraciones del sistema';
  static const String accountSectionTitle = 'Mi Cuenta';
  static const String controlPanelSectionTitle = 'Panel de Control';
  static const String sessionSectionTitle = 'Sesión';
  
  // Opciones
  static const String changePasswordTitle = 'Cambiar contraseña';
  static const String changePasswordSubtitle = 'Actualiza tu contraseña de acceso';
  static const String viewAdminsTitle = 'Ver administradores';
  static const String viewAdminsSubtitle = 'Gestionar usuarios administrativos';
  static const String inviteUsersTitle = 'Invitar usuarios';
  static const String inviteUsersSubtitle = 'Enviar invitaciones a nuevos miembros';
  
  // Nueva opción de transferencia
  static const String transferRoleTitle = 'Transferir rol SuperAdmin';
  static const String transferRoleSubtitle = 'Transferir privilegios de SuperAdmin a otro usuario';
  
  static const String logoutTitle = 'Cerrar sesión';
  static const String logoutSubtitle = 'Salir de tu cuenta actual';
  
  // Dialogs
  static const String logoutDialogTitle = '¿Cerrar sesión?';
  static const String logoutDialogContent = 'Tu sesión actual será cerrada y deberás iniciar sesión nuevamente para acceder al sistema.';
  
  // Dialog de transferencia
  static const String transferDialogTitle = 'Transferir SuperAdmin';
  static const String transferDialogContent = 'Esta acción transferirá todos tus privilegios de SuperAdmin a otro usuario. Una vez confirmada, perderás el acceso completo al sistema.\n\n¿Estás completamente seguro de continuar?';
  static const String transferButtonText = 'Continuar con Transferencia';
  
  static const String cancelButtonText = 'Cancelar';
  static const String logoutButtonText = 'Cerrar sesión';
  
  // Version info
  static const String versionText = 'Versión 1.0.0';
  static const String buildText = 'Build 2024.08';
  
  // Badge
  static const String newBadgeText = 'Nuevo';
  
  // Routes
  static const String forgotPasswordRoute = '/forgot';
  static const String viewAdminsRoute = '/ver-admins';
  static const String invitationsRoute = '/invitaciones';
  static const String transferRoleRoute = '/transferir'; 
  static const String welcomeRoute = '/bienvenida-usuario';
  
  // Roles
  static const String adminRole = 'admin';
  static const String superAdminRole = 'superAdmin';
  
  // Animation
  static const Duration transitionDuration = Duration(milliseconds: 300);
  static const Duration animationDuration = Duration(milliseconds: 200);
  static const Curve transitionCurve = Curves.easeInOutCubic;
  
  // Transition
  static const Offset slideTransitionBegin = Offset(0.0, 1.0);
  static const Offset slideTransitionEnd = Offset.zero;
}