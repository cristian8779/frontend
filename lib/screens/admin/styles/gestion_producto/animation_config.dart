class AnimationConfig {
  // Duraciones
  static const Duration fadeAnimationDuration = Duration(milliseconds: 800);
  static const Duration listAnimationDuration = Duration(milliseconds: 600);
  static const Duration staggeredAnimationDuration = Duration(milliseconds: 1500);
  static const Duration scaleAnimationDuration = Duration(milliseconds: 200);
  static const Duration snackBarDuration = Duration(seconds: 4);
  static const Duration delayAfterLoading = Duration(milliseconds: 100);
  
  // Valores de animación
  static const double scaleAnimationBegin = 1.0;
  static const double scaleAnimationEnd = 0.98;
  static const double fadeAnimationBegin = 0.0;
  static const double fadeAnimationEnd = 1.0;
  
  // Valores de transformación
  static const double shimmerScaleBegin = 0.95;
  static const double shimmerScaleEnd = 0.05;
  static const double productCardScaleBegin = 0.5;
  static const double productCardScaleEnd = 0.5;
  
  // Delays normalizados
  static double getNormalizedDelay(int index) {
    return index * 0.1;
  }
  
  static double getAdjustedProgress(double animationProgress, double normalizedDelay) {
    return ((animationProgress - normalizedDelay) / (1.0 - normalizedDelay))
        .clamp(0.0, 1.0);
  }
  
  static double getItemDelay(int index) {
    return (index * 0.1).clamp(0.0, 0.8);
  }
  
  static double getAnimationValue(double animationProgress, double itemDelay) {
    return ((animationProgress - itemDelay) / (1.0 - itemDelay))
        .clamp(0.0, 1.0);
  }
}