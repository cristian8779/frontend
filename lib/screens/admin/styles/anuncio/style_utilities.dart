// 🔧 UTILIDADES PARA ESTILOS Y ANIMACIONES
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_styles.dart';

class StyleUtilities {
  // 🎯 UTILIDADES DE ANIMACIÓN

  /// Crea un controller de animación con duración estándar
  static AnimationController createStandardController({
    required TickerProvider vsync,
    Duration? duration,
  }) {
    return AnimationController(
      duration: duration ?? AppStyles.normalAnimation,
      vsync: vsync,
    );
  }

  /// Crea una animación de fade estándar
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Crea una animación de slide estándar
  static Animation<Offset> createSlideAnimation(
    AnimationController controller, {
    Offset begin = const Offset(0, 0.3),
    Offset end = Offset.zero,
  }) {
    return Tween<Offset>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeOutCubic,
    ));
  }

  /// Crea una animación de escala para efectos bounce
  static Animation<double> createScaleAnimation(
    AnimationController controller, {
    double begin = 0.8,
    double end = 1.0,
  }) {
    return Tween<double>(
      begin: begin,
      end: end,
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut,
    ));
  }

  // 🎯 UTILIDADES PARA FEEDBACK HÁPTICO

  /// Feedback ligero para interacciones suaves
  static void lightHaptic() {
    HapticFeedback.lightImpact();
  }

  /// Feedback medio para acciones importantes
  static void mediumHaptic() {
    HapticFeedback.mediumImpact();
  }

  /// Feedback fuerte para acciones críticas
  static void heavyHaptic() {
    HapticFeedback.heavyImpact();
  }

  /// Feedback de selección para navegación
  static void selectionHaptic() {
    HapticFeedback.selectionClick();
  }

  // 🎯 UTILIDADES PARA MENSAJES DE ERROR

  /// Determina el mensaje de error apropiado basado en la excepción
  static String determineErrorMessage(dynamic error) {
    String errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || 
        errorStr.contains('network') || 
        errorStr.contains('connection')) {
      return "Sin conexión a internet";
    } else if (errorStr.contains('timeout') || 
               errorStr.contains('time out')) {
      return "Tiempo de espera agotado";
    } else if (errorStr.contains('server') || 
               errorStr.contains('502') || 
               errorStr.contains('503') || 
               errorStr.contains('500')) {
      return "Servidor no disponible";
    } else if (errorStr.contains('404')) {
      return "Recurso no encontrado";
    } else {
      return "Error de conexión";
    }
  }

  // 🎯 UTILIDADES PARA TRANSICIONES DE PÁGINA

  /// Transición de slide hacia la derecha
  static PageRouteBuilder slideRightTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: child,
        );
      },
      transitionDuration: AppStyles.normalAnimation,
    );
  }

  /// Transición de slide hacia arriba
  static PageRouteBuilder slideUpTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position: animation.drive(
            Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: AppStyles.normalAnimation,
    );
  }

  /// Transición de fade simple
  static PageRouteBuilder fadeTransition(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation.drive(
            CurveTween(curve: Curves.easeInOut),
          ),
          child: child,
        );
      },
      transitionDuration: AppStyles.normalAnimation,
    );
  }

  // 🎯 UTILIDADES PARA TOAST/SNACKBAR

  /// Muestra un SnackBar con estilo consistente
  static void showStyledSnackBar(
    BuildContext context,
    String message, {
    required bool isSuccess,
    Duration? duration,
    VoidCallback? onAction,
    String? actionLabel,
  }) {
    final color = isSuccess ? AppStyles.successColor : AppStyles.errorColor;
    final icon = isSuccess ? Icons.check_circle_rounded : Icons.error_rounded;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: const EdgeInsets.symmetric(vertical: AppStyles.spacingSmall),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppStyles.spacingXSmall),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppStyles.spacingMedium),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.radiusMedium),
        ),
        duration: duration ?? AppStyles.toastDuration,
        elevation: AppStyles.elevationLarge,
        margin: const EdgeInsets.all(AppStyles.spacingMedium),
        action: onAction != null
            ? SnackBarAction(
                label: actionLabel ?? 'OK',
                textColor: Colors.white,
                onPressed: onAction,
              )
            : SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
              ),
      ),
    );
  }

  // 🎯 UTILIDADES PARA RESPONSIVE DESIGN

  /// Determina si es una pantalla pequeña
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 600;
  }

  /// Determina si es una tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 600 && width < 1024;
  }

  /// Determina si es una pantalla grande (desktop)
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= 1024;
  }

  /// Obtiene padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(AppStyles.spacingXLarge);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(AppStyles.spacingLarge);
    } else {
      return const EdgeInsets.all(AppStyles.spacingMedium);
    }
  }

  /// Obtiene tamaño de fuente responsivo
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context) && desktop != null) {
      return desktop;
    } else if (isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }

  // 🎯 UTILIDADES PARA COLORES

  /// Obtiene un color con opacidad ajustada
  static Color getColorWithOpacity(Color color, double opacity) {
    return color.withOpacity(opacity.clamp(0.0, 1.0));
  }

  /// Obtiene un color más claro
  static Color lightenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return hslLight.toColor();
  }

  /// Obtiene un color más oscuro
  static Color darkenColor(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  // 🎯 UTILIDADES DE VALIDACIÓN

  /// Valida si una URL es válida para imágenes
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Formatea fechas de manera consistente
  static String formatDate(DateTime date, {String locale = 'es'}) {
    // Implementar formateo de fecha según locale
    // Este es un ejemplo básico, se puede extender con intl
    final months = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // 🎯 UTILIDADES PARA ESPACIADO

  /// Obtiene espaciado vertical responsivo
  static Widget getVerticalSpace(BuildContext context, {double multiplier = 1.0}) {
    final baseHeight = isDesktop(context) 
        ? AppStyles.spacingXLarge 
        : isTablet(context)
            ? AppStyles.spacingLarge
            : AppStyles.spacingMedium;
    
    return SizedBox(height: baseHeight * multiplier);
  }

  /// Obtiene espaciado horizontal responsivo
  static Widget getHorizontalSpace(BuildContext context, {double multiplier = 1.0}) {
    final baseWidth = isDesktop(context) 
        ? AppStyles.spacingXLarge 
        : isTablet(context)
            ? AppStyles.spacingLarge
            : AppStyles.spacingMedium;
    
    return SizedBox(width: baseWidth * multiplier);
  }
}