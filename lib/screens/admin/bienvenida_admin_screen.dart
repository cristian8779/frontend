import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BienvenidaAdminScreen extends StatefulWidget {
  final String rol; // admin o superAdmin

  const BienvenidaAdminScreen({
    super.key,
    required this.rol,
  });

  @override
  State<BienvenidaAdminScreen> createState() => _BienvenidaAdminScreenState();
}

class _BienvenidaAdminScreenState extends State<BienvenidaAdminScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonBounceAnimation;
  
  final Color primaryColor = const Color(0xFFBE0C0C);
  final Color accentColor = const Color(0xFFE8F4FD);
  final Color gradientStart = const Color(0xFFFAFAFA);
  final Color gradientEnd = const Color(0xFFE3F2FD);

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    // Animación principal del botón
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Animación de deslizamiento para el contenido
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    // Animación de fade para elementos
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    _buttonBounceAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));
  }

  void _startAnimationSequence() {
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _onTap() async {
    // Feedback háptico
    HapticFeedback.lightImpact();
    
    // Animación de tap
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 100));
    await _controller.forward();

    // Navegación con delay para mejor UX
    await Future.delayed(const Duration(milliseconds: 200));
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/control-panel',
        arguments: {
          'rol': widget.rol,
        },
      );
    }
  }

  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isSmallHeight = screenHeight < 700;
    
    if (isDesktop) {
      return {
        'titleFontSize': isSmallHeight ? 32.0 : 42.0,
        'subtitleFontSize': 18.0,
        'horizontalPadding': 80.0,
        'verticalPadding': 40.0,
        'buttonSize': 88.0,
        'iconSize': 40.0,
        'buttonTextSize': 18.0,
        'imageWidthRatio': 0.45,
        'maxWidth': 1000.0,
        'bottomSpacing': 32.0,
        'cardPadding': 40.0,
      };
    } else if (isTablet) {
      return {
        'titleFontSize': isSmallHeight ? 28.0 : 36.0,
        'subtitleFontSize': 16.0,
        'horizontalPadding': 48.0,
        'verticalPadding': 32.0,
        'buttonSize': 80.0,
        'iconSize': 36.0,
        'buttonTextSize': 17.0,
        'imageWidthRatio': 0.55,
        'maxWidth': 750.0,
        'bottomSpacing': 28.0,
        'cardPadding': 32.0,
      };
    } else {
      return {
        'titleFontSize': isSmallHeight ? 26.0 : 32.0,
        'subtitleFontSize': 15.0,
        'horizontalPadding': 28.0,
        'verticalPadding': 24.0,
        'buttonSize': 72.0,
        'iconSize': 32.0,
        'buttonTextSize': 16.0,
        'imageWidthRatio': 0.65,
        'maxWidth': double.infinity,
        'bottomSpacing': 24.0,
        'cardPadding': 24.0,
      };
    }
  }

  Widget _buildRoleIndicator() {
    final isSuper = widget.rol.toLowerCase() == 'superadmin';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSuper ? const Color(0xFFFFD700).withOpacity(0.2) : primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSuper ? const Color(0xFFFFD700) : primaryColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuper ? Icons.admin_panel_settings : Icons.shield,
            size: 18,
            color: isSuper ? const Color(0xFFB8860B) : primaryColor,
          ),
          const SizedBox(width: 8),
          Text(
            isSuper ? 'Super Admin' : 'Admin',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSuper ? const Color(0xFFB8860B) : primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _getResponsiveDimensions(context);
        final media = MediaQuery.of(context);
        final isSmall = constraints.maxHeight < 700;

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [gradientStart, gradientEnd],
                stops: const [0.0, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: dimensions['maxWidth']!),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: dimensions['horizontalPadding']!,
                      vertical: dimensions['verticalPadding']!,
                    ),
                    child: Column(
                      children: [
                        // Indicador de rol
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: _buildRoleIndicator(),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Contenido principal
                        Expanded(
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: FadeTransition(
                              opacity: _fadeAnimation,
                              child: Card(
                                elevation: 12,
                                shadowColor: Colors.black.withOpacity(0.1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Container(
                                  padding: EdgeInsets.all(dimensions['cardPadding']!),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.white,
                                        Colors.white.withOpacity(0.95),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Título principal
                                      Text(
                                        "¡Bienvenido!",
                                        style: TextStyle(
                                          fontSize: dimensions['titleFontSize']!,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                          letterSpacing: -0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      
                                      SizedBox(height: isSmall ? 8 : 12),
                                      
                                      // Subtítulo
                                      Text(
                                        "Panel de Administración",
                                        style: TextStyle(
                                          fontSize: dimensions['subtitleFontSize']!,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black54,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      
                                      SizedBox(height: isSmall ? 20 : 32),
                                      
                                      // Imagen con animación flotante
                                      Expanded(
                                        child: Container(
                                          constraints: BoxConstraints(
                                            maxWidth: media.size.width * dimensions['imageWidthRatio']!,
                                            maxHeight: constraints.maxHeight * 0.4,
                                          ),
                                          child: TweenAnimationBuilder<double>(
                                            duration: const Duration(seconds: 3),
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            builder: (context, value, child) {
                                              return Transform.translate(
                                                offset: Offset(0, 8 * (0.5 - (value % 1.0 - 0.5).abs())),
                                                child: Image.asset(
                                                  'assets/bienvenida.png',
                                                  fit: BoxFit.contain,
                                                ),
                                              );
                                            },
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
                        
                        SizedBox(height: dimensions['bottomSpacing']!),
                        
                        // Botón de continuar mejorado
                        ScaleTransition(
                          scale: _buttonBounceAnimation,
                          child: GestureDetector(
                            onTap: _onTap,
                            child: Container(
                              width: dimensions['buttonSize']!,
                              height: dimensions['buttonSize']!,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    primaryColor,
                                    primaryColor.withOpacity(0.8),
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withOpacity(0.4),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                    spreadRadius: 0,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withOpacity(0.8),
                                    blurRadius: 10,
                                    offset: const Offset(-5, -5),
                                    spreadRadius: 0,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: dimensions['iconSize']!,
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Texto de continuar
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            "Toca para continuar",
                            style: TextStyle(
                              fontSize: dimensions['buttonTextSize']!,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                              letterSpacing: 0.3,
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
        );
      },
    );
  }
}