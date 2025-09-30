import 'package:flutter/material.dart';
import 'responsive_helper.dart';

enum NotificationType { success, error, warning, info }

class NotificationWidget extends StatefulWidget {
  final String message;
  final String? subtitle;
  final NotificationType type;
  final IconData icon;
  final VoidCallback onDismiss;

  const NotificationWidget({
    Key? key,
    required this.message,
    this.subtitle,
    required this.type,
    required this.icon,
    required this.onDismiss,
  }) : super(key: key);

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
      duration: const Duration(milliseconds: 600),
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
        return const Color(0xFF10B981);
      case NotificationType.error:
        return const Color(0xFFEF4444);
      case NotificationType.warning:
        return const Color(0xFFF59E0B);
      case NotificationType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData get iconData {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle_outline;
      case NotificationType.error:
        return Icons.error_outline;
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.info:
        return Icons.info_outline;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final responsive = ResponsiveHelper(size);
    
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: responsive.padding * 0.8,
      right: responsive.padding * 0.8,
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
                  padding: EdgeInsets.all(responsive.inputPadding),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        backgroundColor,
                        backgroundColor.withOpacity(0.9),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(responsive.borderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: backgroundColor.withOpacity(0.3),
                        blurRadius: responsive.shadowBlur,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: responsive.shadowBlur * 2,
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
                            padding: EdgeInsets.all(responsive.horizontalSpacing * 0.5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(responsive.inputRadius * 0.75),
                            ),
                            child: Icon(
                              widget.icon,
                              color: Colors.white,
                              size: responsive.iconSize,
                            ),
                          ),
                          SizedBox(width: responsive.horizontalSpacing),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: responsive.bodySize,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.1,
                                  ),
                                ),
                                if (widget.subtitle != null) ...[
                                  SizedBox(height: responsive.verticalSpacing * 0.2),
                                  Text(
                                    widget.subtitle!,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: responsive.captionSize,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.1,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: responsive.horizontalSpacing * 0.5),
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Container(
                              padding: EdgeInsets.all(responsive.horizontalSpacing * 0.25),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(responsive.horizontalSpacing * 0.5),
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white.withOpacity(0.9),
                                size: responsive.smallIconSize,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Barra de progreso para mostrar tiempo restante
                      SizedBox(height: responsive.verticalSpacing * 0.6),
                      Container(
                        height: 3,
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