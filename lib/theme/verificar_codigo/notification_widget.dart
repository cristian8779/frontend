import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'verificar_codigo_styles.dart';

enum NotificationType { success, error, warning, info }

class NotificationWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final NotificationType type;
  final IconData icon;
  final VoidCallback onDismiss;

  const NotificationWidget({
    super.key,
    required this.message,
    this.subtitle,
    required this.type,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: VerificarCodigoStyles.notificationAnimationDuration,
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _controller.forward();
  }

  Color get backgroundColor {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.successColor;
      case NotificationType.error:
        return AppColors.errorColor;
      case NotificationType.warning:
        return AppColors.warningColor;
      case NotificationType.info:
        return AppColors.infoColor;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + VerificarCodigoStyles.notificationTopOffset,
      left: VerificarCodigoStyles.notificationHorizontalPadding,
      right: VerificarCodigoStyles.notificationHorizontalPadding,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                onPanUpdate: (details) {
                  // Permitir deslizar para cerrar
                  if (details.delta.dy < -2) {
                    widget.onDismiss();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(VerificarCodigoStyles.spacingL),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(VerificarCodigoStyles.notificationBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(VerificarCodigoStyles.spacingXS),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: VerificarCodigoStyles.spacingM),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: VerificarCodigoStyles.spacingXS),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Barra de progreso para mostrar tiempo restante
                      const SizedBox(width: VerificarCodigoStyles.spacingS),
                      Container(
                        height: VerificarCodigoStyles.notificationProgressBarHeight,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: 0.0, // Se animará automáticamente
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}