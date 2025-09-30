// show_settings_modal.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/admin/styles/configuracion/configuracion_styles.dart';

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
        var tween = Tween(
          begin: ConfiguracionConstants.slideTransitionBegin, 
          end: ConfiguracionConstants.slideTransitionEnd
        ).chain(CurveTween(curve: ConfiguracionConstants.transitionCurve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: ConfiguracionConstants.transitionDuration,
    ),
  );
}

class ConfiguracionScreen extends StatelessWidget {
  final String rol;

  const ConfiguracionScreen({Key? key, required this.rol}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String rolNormalizado = rol.trim();

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = ConfiguracionDimensions.getResponsiveDimensions(context);
        
        return Scaffold(
          backgroundColor: ConfiguracionTheme.backgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                _AppBar(dimensions: dimensions),
                Expanded(
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: dimensions['maxWidth']!),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: dimensions['horizontalPadding']!),
                        child: _ConfiguracionContent(
                          rol: rolNormalizado,
                          dimensions: dimensions,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AppBar extends StatelessWidget {
  final Map<String, double> dimensions;

  const _AppBar({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ConfiguracionLayout.appBarPadding,
      decoration: ConfiguracionDecorations.getAppBarDecoration(),
      child: Row(
        children: [
          _BackButton(dimensions: dimensions),
          SizedBox(width: ConfiguracionLayout.appBarIconSpacing),
          Expanded(
            child: Text(
              ConfiguracionConstants.appBarTitle,
              style: ConfiguracionTextStyles.getAppBarTitleStyle(dimensions),
            ),
          ),
          _AppBarIcon(),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  final Map<String, double> dimensions;

  const _BackButton({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ConfiguracionDecorations.getBackButtonDecoration(),
      child: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          ConfiguracionTheme.backIcon,
          color: ConfiguracionTheme.backButtonIconColor,
          size: dimensions['appBarIconSize']!,
        ),
        padding: ConfiguracionLayout.backButtonPadding,
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ConfiguracionLayout.backButtonPadding,
      decoration: ConfiguracionDecorations.getAppBarIconDecoration(),
      child: const Icon(
        ConfiguracionTheme.settingsIcon,
        color: ConfiguracionTheme.primaryColor,
        size: 24,
      ),
    );
  }
}

class _ConfiguracionContent extends StatelessWidget {
  final String rol;
  final Map<String, double> dimensions;

  const _ConfiguracionContent({
    required this.rol,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: ConfiguracionDimensions.largeSpacing),
        _Header(dimensions: dimensions),
        SizedBox(height: ConfiguracionDimensions.sectionSpacing),
        
        // Sección de cuenta
        _SectionHeader(
          title: ConfiguracionConstants.accountSectionTitle,
          dimensions: dimensions,
        ),
        SizedBox(height: ConfiguracionDimensions.mediumSpacing),
        
        if (_isAdminOrSuperAdmin(rol))
          _PasswordOption(dimensions: dimensions),

        // Opciones avanzadas solo para superAdmin
        if (rol == ConfiguracionConstants.superAdminRole) ...[
          SizedBox(height: ConfiguracionDimensions.extraLargeSpacing),
          _SectionHeader(
            title: ConfiguracionConstants.controlPanelSectionTitle,
            dimensions: dimensions,
          ),
          SizedBox(height: ConfiguracionDimensions.mediumSpacing),
          _AdvancedOptions(dimensions: dimensions),
        ],

        SizedBox(height: ConfiguracionDimensions.extraLargeSpacing),
        
        // Sección de sesión
        _SectionHeader(
          title: ConfiguracionConstants.sessionSectionTitle,
          dimensions: dimensions,
        ),
        SizedBox(height: ConfiguracionDimensions.mediumSpacing),
        
        if (_isAdminOrSuperAdmin(rol))
          _LogoutOption(dimensions: dimensions),

        SizedBox(height: ConfiguracionDimensions.sectionSpacing),
        _VersionInfo(dimensions: dimensions),
        SizedBox(height: ConfiguracionDimensions.largeSpacing),
      ],
    );
  }

  bool _isAdminOrSuperAdmin(String rol) {
    return rol == ConfiguracionConstants.adminRole || 
           rol == ConfiguracionConstants.superAdminRole;
  }
}

class _Header extends StatelessWidget {
  final Map<String, double> dimensions;

  const _Header({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: ConfiguracionLayout.headerPadding,
      decoration: ConfiguracionDecorations.getHeaderDecoration(),
      child: Column(
        children: [
          Container(
            padding: ConfiguracionLayout.headerIconPadding,
            decoration: ConfiguracionDecorations.getHeaderIconDecoration(),
            child: Icon(
              ConfiguracionTheme.headerIcon,
              size: dimensions['headerIconSize']!,
              color: ConfiguracionTheme.primaryColor,
            ),
          ),
          SizedBox(height: ConfiguracionLayout.headerSpacing),
          Text(
            ConfiguracionConstants.headerTitle,
            style: ConfiguracionTextStyles.getHeaderTitleStyle(dimensions),
          ),
          SizedBox(height: ConfiguracionDimensions.defaultSpacing),
          Text(
            ConfiguracionConstants.headerSubtitle,
            style: ConfiguracionTextStyles.getHeaderSubtitleStyle(dimensions),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Map<String, double> dimensions;

  const _SectionHeader({
    required this.title,
    required this.dimensions,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: ConfiguracionLayout.sectionHeaderPadding,
      child: Row(
        children: [
          Container(
            width: ConfiguracionLayout.sectionIndicatorWidth,
            height: ConfiguracionLayout.sectionIndicatorHeight,
            decoration: ConfiguracionDecorations.getSectionIndicatorDecoration(),
          ),
          SizedBox(width: ConfiguracionLayout.sectionIndicatorSpacing),
          Text(
            title.toUpperCase(),
            style: ConfiguracionTextStyles.getSectionTitleStyle(dimensions),
          ),
        ],
      ),
    );
  }
}

class _PasswordOption extends StatelessWidget {
  final Map<String, double> dimensions;

  const _PasswordOption({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return _ModernOption(
      icon: ConfiguracionTheme.passwordIcon,
      iconColor: ConfiguracionTheme.passwordOptionColor,
      iconBg: ConfiguracionTheme.passwordOptionColor.withOpacity(
        ConfiguracionTheme.optionIconOpacity
      ),
      title: ConfiguracionConstants.changePasswordTitle,
      subtitle: ConfiguracionConstants.changePasswordSubtitle,
      dimensions: dimensions,
      onTap: () => Navigator.pushNamed(context, ConfiguracionConstants.forgotPasswordRoute),
    );
  }
}

class _AdvancedOptions extends StatelessWidget {
  final Map<String, double> dimensions;

  const _AdvancedOptions({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ModernOption(
          icon: ConfiguracionTheme.adminIcon,
          iconColor: ConfiguracionTheme.adminOptionColor,
          iconBg: ConfiguracionTheme.adminOptionColor.withOpacity(
            ConfiguracionTheme.optionIconOpacity
          ),
          title: ConfiguracionConstants.viewAdminsTitle,
          subtitle: ConfiguracionConstants.viewAdminsSubtitle,
          dimensions: dimensions,
          onTap: () => Navigator.pushNamed(context, ConfiguracionConstants.viewAdminsRoute),
        ),
        SizedBox(height: ConfiguracionDimensions.mediumSpacing - 4),
        _ModernOption(
          icon: ConfiguracionTheme.inviteIcon,
          iconColor: ConfiguracionTheme.inviteOptionColor,
          iconBg: ConfiguracionTheme.inviteOptionColor.withOpacity(
            ConfiguracionTheme.optionIconOpacity
          ),
          title: ConfiguracionConstants.inviteUsersTitle,
          subtitle: ConfiguracionConstants.inviteUsersSubtitle,
          dimensions: dimensions,
          onTap: () => Navigator.pushNamed(context, ConfiguracionConstants.invitationsRoute),
        ),
      ],
    );
  }
}

class _LogoutOption extends StatelessWidget {
  final Map<String, double> dimensions;

  const _LogoutOption({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return _ModernOption(
      icon: ConfiguracionTheme.logoutIcon,
      iconColor: ConfiguracionTheme.logoutOptionColor,
      iconBg: ConfiguracionTheme.logoutOptionColor.withOpacity(
        ConfiguracionTheme.optionIconOpacity
      ),
      title: ConfiguracionConstants.logoutTitle,
      subtitle: ConfiguracionConstants.logoutSubtitle,
      isDangerous: true,
      dimensions: dimensions,
      onTap: () => _handleLogout(context, dimensions),
    );
  }

  Future<void> _handleLogout(BuildContext context, Map<String, double> dimensions) async {
    final shouldLogout = await _LogoutConfirmationDialog.show(context, dimensions);

    if (shouldLogout == true) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.cerrarSesion();

      Navigator.pushNamedAndRemoveUntil(
        context,
        ConfiguracionConstants.welcomeRoute,
        (route) => false,
      );
    }
  }
}

class _VersionInfo extends StatelessWidget {
  final Map<String, double> dimensions;

  const _VersionInfo({required this.dimensions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: ConfiguracionLayout.versionInfoPadding,
        decoration: ConfiguracionDecorations.getVersionInfoDecoration(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: ConfiguracionLayout.versionIconPadding,
              decoration: ConfiguracionDecorations.getVersionIconDecoration(),
              child: Icon(
                ConfiguracionTheme.versionIcon,
                size: ConfiguracionLayout.versionIconSize,
                color: ConfiguracionTheme.textSecondary,
              ),
            ),
            SizedBox(width: ConfiguracionLayout.versionInfoSpacing),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ConfiguracionConstants.versionText,
                  style: ConfiguracionTextStyles.getVersionTitleStyle(dimensions),
                ),
                Text(
                  ConfiguracionConstants.buildText,
                  style: ConfiguracionTextStyles.getVersionSubtitleStyle(dimensions),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ModernOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Map<String, double> dimensions;
  final bool isDangerous;
  final VoidCallback onTap;

  const _ModernOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.dimensions,
    this.isDangerous = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(ConfiguracionDimensions.extraLargeBorderRadius),
        splashColor: iconColor.withOpacity(ConfiguracionTheme.splashOpacity),
        highlightColor: iconColor.withOpacity(ConfiguracionTheme.highlightOpacity),
        child: AnimatedContainer(
          duration: ConfiguracionConstants.animationDuration,
          padding: ConfiguracionLayout.optionCardPadding,
          decoration: ConfiguracionDecorations.getOptionCardDecoration(isDangerous: isDangerous),
          child: Row(
            children: [
              Container(
                padding: ConfiguracionLayout.optionIconPadding,
                decoration: ConfiguracionDecorations.getOptionIconDecoration(iconBg),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: ConfiguracionLayout.optionIconSize,
                ),
              ),
              SizedBox(width: ConfiguracionLayout.optionSpacing),
              Expanded(child: _OptionContent()),
              SizedBox(width: ConfiguracionLayout.optionArrowSpacing),
              _ArrowIcon(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _OptionContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: ConfiguracionTextStyles.getOptionTitleStyle(dimensions),
        ),
        SizedBox(height: ConfiguracionLayout.optionTitleSpacing),
        Text(
          subtitle,
          style: ConfiguracionTextStyles.getOptionSubtitleStyle(dimensions),
        ),
      ],
    );
  }

  Widget _ArrowIcon() {
    return Container(
      padding: ConfiguracionLayout.arrowIconPadding,
      decoration: ConfiguracionDecorations.getOptionArrowDecoration(),
      child: const Icon(
        ConfiguracionTheme.arrowForwardIcon,
        color: ConfiguracionTheme.textSecondary,
        size: ConfiguracionLayout.arrowIconSize,
      ),
    );
  }
}

class _LogoutConfirmationDialog {
  static Future<bool?> show(BuildContext context, Map<String, double> dimensions) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ConfiguracionDimensions.extraLargeBorderRadius)
        ),
        elevation: 8,
        backgroundColor: ConfiguracionTheme.surfaceColor,
        title: Row(
          children: [
            Container(
              padding: ConfiguracionLayout.backButtonPadding,
              decoration: ConfiguracionDecorations.getDialogIconDecoration(),
              child: const Icon(
                ConfiguracionTheme.logoutIcon,
                color: ConfiguracionTheme.logoutOptionColor,
                size: ConfiguracionLayout.dialogIconSize,
              ),
            ),
            SizedBox(width: ConfiguracionLayout.versionInfoSpacing),
            Flexible(
              child: Text(
                ConfiguracionConstants.logoutDialogTitle,
                style: ConfiguracionTextStyles.getDialogTitleStyle(dimensions),
              ),
            ),
          ],
        ),
        content: Text(
          ConfiguracionConstants.logoutDialogContent,
          style: ConfiguracionTextStyles.getDialogContentStyle(dimensions),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: ConfiguracionLayout.dialogButtonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)
              ),
            ),
            child: Text(
              ConfiguracionConstants.cancelButtonText,
              style: ConfiguracionTextStyles.getDialogButtonStyle(dimensions).copyWith(
                color: ConfiguracionTheme.textSecondary,
              ),
            ),
          ),
          SizedBox(width: ConfiguracionLayout.dialogActionSpacing),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ConfiguracionTheme.logoutOptionColor,
              foregroundColor: ConfiguracionTheme.surfaceColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
              padding: ConfiguracionLayout.dialogButtonPadding,
            ),
            child: Text(
              ConfiguracionConstants.logoutButtonText,
              style: ConfiguracionTextStyles.getDialogButtonStyle(dimensions),
            ),
          ),
        ],
      ),
    );
  }
}