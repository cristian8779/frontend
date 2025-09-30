import 'package:flutter/material.dart';
import 'favorito_theme.dart';
import 'favorito_colors.dart';
import 'favorito_text_styles.dart';
import 'favorito_decorations.dart';
import 'favorito_dimensions.dart';

/// Widgets reutilizables específicos para la pantalla de favoritos
class FavoritoWidgets {
  /// Widget de icono pulsante para estados de carga
  static Widget pulseIcon({
    required Animation<double> animation,
    required IconData icon,
    required bool isTablet,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: animation.value,
          child: Container(
            padding: EdgeInsets.all(isTablet ? 48 : 40),
            decoration: FavoritoDecorations.pulseIconDecoration(isTablet),
            child: Icon(
              icon,
              size: FavoritoDimensions.favoriteIconSize(isTablet),
              color: FavoritoColors.favoriteColor,
            ),
          ),
        );
      },
    );
  }
  
  /// Indicador de progreso circular personalizado
  static Widget circularProgress({bool isLarge = false}) {
    return SizedBox(
      width: isLarge ? 48 : 40,
      height: isLarge ? 48 : 40,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(FavoritoColors.primaryColor),
        strokeWidth: FavoritoDimensions.circularProgressStrokeWidth,
        backgroundColor: FavoritoColors.accentColor.withOpacity(0.2),
      ),
    );
  }
  
  /// Contenedor de imagen con placeholder
  static Widget imageContainer({
    String? imageUrl,
    required double width,
    required double height,
    BorderRadius? borderRadius,
    BoxFit? fit,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(FavoritoDimensions.imageBorderRadius),
      child: Container(
        width: width,
        height: height,
        decoration: FavoritoDecorations.imageContainerDecoration,
        child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: fit ?? BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                          loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: FavoritoDimensions.shimmerProgressStrokeWidth,
                    valueColor: AlwaysStoppedAnimation<Color>(FavoritoColors.primaryColor),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.image_not_supported_outlined,
                color: FavoritoColors.subtextColor,
                size: width * 0.4,
              ),
            )
          : Icon(
              Icons.image_outlined,
              color: FavoritoColors.subtextColor,
              size: width * 0.4,
            ),
      ),
    );
  }
  
  /// Botón de acción con icono personalizado
  static Widget actionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color backgroundColor,
    required Color iconColor,
    String? tooltip,
    double? size,
    bool isGradient = false,
    Gradient? gradient,
    List<BoxShadow>? boxShadow,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isGradient ? null : backgroundColor,
        gradient: isGradient ? gradient : null,
        borderRadius: BorderRadius.circular(FavoritoDimensions.smallBorderRadius),
        boxShadow: boxShadow,
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: iconColor,
        iconSize: size ?? FavoritoDimensions.buttonIconSize,
        padding: const EdgeInsets.all(12),
        tooltip: tooltip,
      ),
    );
  }
  
  /// Botón de eliminar personalizado
  static Widget deleteButton({
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      decoration: FavoritoDecorations.deleteButtonDecoration,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.delete_outline_rounded),
        color: FavoritoColors.subtextColor,
        tooltip: tooltip ?? 'Eliminar de favoritos',
        padding: const EdgeInsets.all(8),
        iconSize: FavoritoDimensions.deleteIconSize,
      ),
    );
  }
  
  /// Botón para agregar al carrito
  static Widget cartButton({
    required VoidCallback? onPressed,
    required bool disponible,
    String? tooltip,
  }) {
    return Container(
      decoration: FavoritoDecorations.cartButtonDecoration(disponible),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          disponible 
            ? Icons.add_shopping_cart_outlined
            : Icons.remove_shopping_cart_outlined,
        ),
        color: disponible ? Colors.white : FavoritoColors.subtextColor,
        tooltip: tooltip ?? (disponible ? 'Agregar al carrito' : 'Producto agotado'),
        padding: const EdgeInsets.all(8),
        iconSize: FavoritoDimensions.cartIconSize,
      ),
    );
  }
  
  /// Botón de cerrar en cards
  static Widget closeButton({
    required VoidCallback onPressed,
    String? tooltip,
  }) {
    return Container(
      decoration: FavoritoDecorations.whiteButtonDecoration,
      child: IconButton(
        onPressed: onPressed,
        icon: const Icon(Icons.close_rounded),
        color: FavoritoColors.subtextColor,
        iconSize: FavoritoDimensions.smallIconSize,
        padding: const EdgeInsets.all(8),
        tooltip: tooltip ?? 'Eliminar de favoritos',
      ),
    );
  }
  
  /// Badge de descuento reutilizable
  static Widget discountBadge({
    required int discount,
    bool isSmall = false,
  }) {
    return FavoritoTheme.discountBadge(
      discount: discount,
      isSmall: isSmall,
    );
  }
  
  /// Contador de favoritos para AppBar
  static Widget favoriteCounter({
    required int count,
    required bool isTablet,
  }) {
    return FavoritoTheme.favoriteCounterWidget(
      count: count,
      isTablet: isTablet,
    );
  }
  
  /// Widget de estado vacío personalizable
  static Widget emptyState({
    required IconData icon,
    required String title,
    required String description,
    required String buttonText,
    required VoidCallback onButtonPressed,
    required bool isTablet,
    String? secondaryButtonText,
    VoidCallback? onSecondaryButtonPressed,
  }) {
    return Center(
      child: Padding(
        padding: FavoritoDimensions.screenPadding(isTablet),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.8, end: 1.05),
              duration: FavoritoDimensions.longAnimationDuration,
              curve: Curves.easeInOut,
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    padding: EdgeInsets.all(isTablet ? 48 : 40),
                    decoration: FavoritoDecorations.emptyStateIconDecoration(isTablet),
                    child: Icon(
                      icon,
                      size: FavoritoDimensions.emptyStateIconSize(isTablet),
                      color: FavoritoColors.favoriteColor,
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: isTablet ? 40 : 32),
            
            Text(
              title,
              style: FavoritoTextStyles.emptyStateTitle(isTablet),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            
            Text(
              description,
              textAlign: TextAlign.center,
              style: FavoritoTextStyles.emptyStateDescription(isTablet),
            ),
            SizedBox(height: isTablet ? 48 : 40),
            
            SizedBox(
              width: isTablet ? 320 : double.infinity,
              height: FavoritoDimensions.buttonHeight(isTablet),
              child: ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.explore_outlined),
                label: Text(
                  buttonText,
                  style: FavoritoTextStyles.buttonText(isTablet),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF8E9AAF),
                  foregroundColor: Colors.white,
                  shape: FavoritoDecorations.buttonShape(isTablet),
                  elevation: FavoritoDimensions.buttonElevation,
                ),
              ),
            ),
            
            if (secondaryButtonText != null && onSecondaryButtonPressed != null) ...[
              SizedBox(height: isTablet ? 24 : 16),
              TextButton.icon(
                onPressed: onSecondaryButtonPressed,
                icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                label: Text(secondaryButtonText),
                style: TextButton.styleFrom(
                  foregroundColor: FavoritoColors.subtextColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 20 : 16, 
                    vertical: 12
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Widget de error personalizable
  static Widget errorState({
    required String title,
    required String message,
    required String primaryButtonText,
    required VoidCallback onPrimaryPressed,
    required bool isTablet,
    String? secondaryButtonText,
    VoidCallback? onSecondaryPressed,
    IconData? icon,
  }) {
    return Center(
      child: Padding(
        padding: FavoritoDimensions.screenPadding(isTablet),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isTablet ? 32 : 24),
              decoration: FavoritoDecorations.errorIconDecoration,
              child: Icon(
                icon ?? Icons.error_outline_rounded,
                size: FavoritoDimensions.errorIconSize(isTablet),
                color: FavoritoColors.errorColor,
              ),
            ),
            SizedBox(height: isTablet ? 32 : 24),
            
            Text(
              title,
              style: FavoritoTextStyles.errorTitle(isTablet),
            ),
            SizedBox(height: isTablet ? 16 : 12),
            
            Container(
              padding: EdgeInsets.all(isTablet ? 20 : 16),
              decoration: FavoritoDecorations.errorMessageDecoration,
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: FavoritoTextStyles.errorMessage(isTablet),
              ),
            ),
            SizedBox(height: isTablet ? 40 : 32),
            
            if (isTablet && secondaryButtonText != null && onSecondaryPressed != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 160,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: onSecondaryPressed,
                      icon: const Icon(Icons.home_outlined),
                      label: Text(secondaryButtonText),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: FavoritoColors.subtextColor,
                        side: BorderSide(color: FavoritoColors.subtextColor),
                        shape: FavoritoDecorations.buttonShape(isTablet),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 160,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryPressed,
                      icon: Icon(_getErrorButtonIcon(primaryButtonText)),
                      label: Text(primaryButtonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FavoritoColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: FavoritoDecorations.buttonShape(isTablet),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: onPrimaryPressed,
                      icon: Icon(_getErrorButtonIcon(primaryButtonText)),
                      label: Text(primaryButtonText),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FavoritoColors.primaryColor,
                        foregroundColor: Colors.white,
                        shape: FavoritoDecorations.buttonShape(isTablet),
                      ),
                    ),
                  ),
                  if (secondaryButtonText != null && onSecondaryPressed != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: onSecondaryPressed,
                        icon: const Icon(Icons.home_outlined),
                        label: Text(secondaryButtonText),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: FavoritoColors.subtextColor,
                          side: BorderSide(color: FavoritoColors.subtextColor),
                          shape: FavoritoDecorations.buttonShape(isTablet),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  /// Helper para obtener icono del botón de error
  static IconData _getErrorButtonIcon(String buttonText) {
    if (buttonText.toLowerCase().contains('iniciar') || buttonText.toLowerCase().contains('login')) {
      return Icons.login_rounded;
    } else if (buttonText.toLowerCase().contains('reintentar')) {
      return Icons.refresh_rounded;
    }
    return Icons.refresh_rounded;
  }
}