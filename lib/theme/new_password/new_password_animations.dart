import 'package:flutter/material.dart';

class NewPasswordAnimations {
  // Duraciones de animaciones
  static const Duration fastDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration slowDuration = Duration(milliseconds: 400);
  static const Duration mainFadeDuration = Duration(milliseconds: 800);
  static const Duration chipAnimationDuration = Duration(milliseconds: 500);
  
  // Curvas de animación
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve elasticCurve = Curves.elasticOut;
  static const Curve backCurve = Curves.easeOutBack;
  
  // Configuración para animaciones escalonadas
  static const int chipAnimationDelay = 100; // milisegundos
  static const int baseChipDelay = 300; // milisegundos
  
  // Factory methods para crear animaciones comunes
  static AnimationController createFadeController({
    required TickerProvider vsync,
    Duration duration = mediumDuration,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }
  
  static Animation<double> createFadeAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: defaultCurve),
    );
  }
  
  static Animation<double> createSlideAnimation(AnimationController controller) {
    return Tween<double>(begin: -20.0, end: 0.0).animate(
      CurvedAnimation(parent: controller, curve: backCurve),
    );
  }
  
  // Método para crear animación de chip escalonada
  static Duration getChipAnimationDuration(int index) {
    return Duration(milliseconds: baseChipDelay + (index * chipAnimationDelay));
  }
  
  // Método para crear animación de fortaleza de contraseña
  static TweenAnimationBuilder<double> createProgressAnimation({
    required double value,
    required Widget Function(BuildContext, double, Widget?) builder,
  }) {
    return TweenAnimationBuilder<double>(
      duration: chipAnimationDuration,
      tween: Tween<double>(begin: 0.0, end: value),
      curve: defaultCurve,
      builder: builder,
    );
  }
  
  // Método para crear animación de escala para chips
  static TweenAnimationBuilder<double> createScaleAnimation({
    required int index,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      duration: getChipAnimationDuration(index),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      curve: elasticCurve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: child,
        );
      },
      child: child,
    );
  }
  
  // Método para crear AnimatedSwitcher personalizado
  static AnimatedSwitcher createIconSwitcher({
    required Widget child,
    Duration duration = fastDuration,
  }) {
    return AnimatedSwitcher(
      duration: duration,
      child: child,
    );
  }
  
  // Método para crear AnimatedContainer personalizado
  static AnimatedContainer createAnimatedContainer({
    required Widget child,
    Duration duration = mediumDuration,
    BoxDecoration? decoration,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    return AnimatedContainer(
      duration: duration,
      decoration: decoration,
      padding: padding,
      margin: margin,
      child: child,
    );
  }
  
  // Configuración de transiciones para rutas
  static PageRouteBuilder<T> createSlideTransition<T>({
    required Widget page,
    RouteSettings? settings,
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        
        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );
        
        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
    );
  }
  
  // Configuración para Hero animations
  static Widget createHeroWrapper({
    required String tag,
    required Widget child,
  }) {
    return Hero(
      tag: tag,
      child: child,
    );
  }
}

// Clase para manejar múltiples controladores de animación
class NewPasswordAnimationManager {
  late AnimationController _mainController;
  late AnimationController _requirementsController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _requirementsFadeAnimation;
  late Animation<double> _requirementsSlideAnimation;
  
  NewPasswordAnimationManager({required TickerProvider vsync}) {
    _mainController = NewPasswordAnimations.createFadeController(
      vsync: vsync,
      duration: NewPasswordAnimations.mainFadeDuration,
    );
    
    _requirementsController = NewPasswordAnimations.createFadeController(
      vsync: vsync,
      duration: NewPasswordAnimations.slowDuration,
    );
    
    _fadeAnimation = NewPasswordAnimations.createFadeAnimation(_mainController);
    _requirementsFadeAnimation = NewPasswordAnimations.createFadeAnimation(_requirementsController);
    _requirementsSlideAnimation = NewPasswordAnimations.createSlideAnimation(_requirementsController);
  }
  
  // Getters
  Animation<double> get fadeAnimation => _fadeAnimation;
  Animation<double> get requirementsFadeAnimation => _requirementsFadeAnimation;
  Animation<double> get requirementsSlideAnimation => _requirementsSlideAnimation;
  
  // Métodos de control
  void startMainAnimation() => _mainController.forward();
  void startRequirementsAnimation() => _requirementsController.forward();
  void reverseRequirementsAnimation() => _requirementsController.reverse();
  
  void dispose() {
    _mainController.dispose();
    _requirementsController.dispose();
  }
}