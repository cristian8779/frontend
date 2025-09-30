// lib/theme/snackbar_styles.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';
import 'app_text_styles.dart';

class SnackBarStyles {
  static SnackBar buildSnackBar(
    BuildContext context,
    String message, {
    Color backgroundColor = AppColors.primary,
    IconData? icon,
    SnackBarAction? action,
    Duration? duration,
  }) {
    final isSmallScreen = AppDimensions.isSmallScreen(context);
    
    // Determinar el icono basado en el color de fondo
    IconData defaultIcon;
    if (backgroundColor == AppColors.warning) {
      defaultIcon = Icons.wifi_off_rounded;
    } else if (backgroundColor == AppColors.error) {
      defaultIcon = Icons.error_outline;
    } else if (backgroundColor == AppColors.success) {
      defaultIcon = Icons.check_circle_outline;
    } else {
      defaultIcon = Icons.info_outline;
    }
    
    return SnackBar(
      content: Row(
        children: [
          Icon(
            icon ?? defaultIcon,
            color: AppColors.textOnPrimary,
            size: isSmallScreen ? AppDimensions.iconSmall : AppDimensions.iconMedium,
          ),
          SizedBox(width: isSmallScreen ? 6 : AppDimensions.spaceSmall),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.getResponsiveSnackBar(context),
            ),
          ),
        ],
      ),
      behavior: SnackBarBehavior.floating,
      backgroundColor: backgroundColor,
      duration: duration ?? 
        (backgroundColor == AppColors.warning 
          ? const Duration(seconds: 6) 
          : const Duration(seconds: 4)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          isSmallScreen ? AppDimensions.radiusMedium : AppDimensions.radiusLarge,
        ),
      ),
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : AppDimensions.spaceMedium,
        vertical: isSmallScreen ? 6 : AppDimensions.spaceSmall,
      ),
      action: action,
    );
  }
  
  static SnackBar buildSuccessSnackBar(
    BuildContext context,
    String message, {
    IconData? icon,
  }) {
    return buildSnackBar(
      context,
      message,
      backgroundColor: AppColors.success,
      icon: icon,
      duration: const Duration(seconds: 3),
    );
  }
  
  static SnackBar buildErrorSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onRetry,
  }) {
    return buildSnackBar(
      context,
      message,
      backgroundColor: AppColors.error,
      action: onRetry != null 
        ? SnackBarAction(
            label: 'Reintentar',
            textColor: AppColors.textOnPrimary,
            onPressed: onRetry,
          )
        : null,
    );
  }
  
  static SnackBar buildWarningSnackBar(
    BuildContext context,
    String message, {
    VoidCallback? onAction,
    String actionLabel = 'Verificar',
  }) {
    return buildSnackBar(
      context,
      message,
      backgroundColor: AppColors.warning,
      duration: const Duration(seconds: 6),
      action: onAction != null 
        ? SnackBarAction(
            label: actionLabel,
            textColor: AppColors.textOnPrimary,
            onPressed: onAction,
          )
        : null,
    );
  }
  
  static SnackBar buildConnectivitySnackBar(
    BuildContext context,
    ConnectivityType type,
  ) {
    String message;
    IconData icon;
    
    switch (type) {
      case ConnectivityType.wifi:
        message = "✅ Conexión WiFi recuperada";
        icon = Icons.wifi;
        break;
      case ConnectivityType.mobile:
        message = "📶 Conexión de datos móviles recuperada";
        icon = Icons.signal_cellular_alt;
        break;
    }
    
    return SnackBar(
      content: Row(
        children: [
          Icon(icon, color: AppColors.textOnPrimary),
          const SizedBox(width: AppDimensions.spaceSmall),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textOnPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.success,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
    );
  }
}

enum ConnectivityType {
  wifi,
  mobile,
}