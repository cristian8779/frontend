import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  final Color primaryColor = const Color(0xFFBE0C0C);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTap() async {
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 50));
    await _controller.forward();

    Navigator.pushReplacementNamed(
      context,
      '/control-panel',
      arguments: {
        'rol': widget.rol, // ✅ Reenvía el rol que recibió
      },
    );
  }

  // Función para obtener dimensiones responsivas
  Map<String, double> _getResponsiveDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    final isSmallHeight = screenHeight < 600;
    
    if (isDesktop) {
      return {
        'titleFontSize': isSmallHeight ? 28.0 : 36.0,
        'horizontalPadding': 80.0,
        'verticalPadding': 40.0,
        'buttonSize': 80.0,
        'iconSize': 36.0,
        'buttonTextSize': 18.0,
        'imageWidthRatio': 0.5,
        'maxWidth': 900.0,
        'bottomSpacing': 24.0,
      };
    } else if (isTablet) {
      return {
        'titleFontSize': isSmallHeight ? 26.0 : 32.0,
        'horizontalPadding': 48.0,
        'verticalPadding': 32.0,
        'buttonSize': 72.0,
        'iconSize': 32.0,
        'buttonTextSize': 17.0,
        'imageWidthRatio': 0.6,
        'maxWidth': 700.0,
        'bottomSpacing': 20.0,
      };
    } else {
      return {
        'titleFontSize': isSmallHeight ? 24.0 : 30.0,
        'horizontalPadding': 32.0,
        'verticalPadding': 24.0,
        'buttonSize': 64.0,
        'iconSize': 28.0,
        'buttonTextSize': 16.0,
        'imageWidthRatio': 0.7,
        'maxWidth': double.infinity,
        'bottomSpacing': 16.0,
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = _getResponsiveDimensions(context);
        final media = MediaQuery.of(context);
        final isSmall = constraints.maxHeight < 600;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
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
                      const SizedBox(height: 8),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Bienvenido al panel de administración",
                              style: TextStyle(
                                fontSize: dimensions['titleFontSize']!,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmall ? 20 : 28),
                            Expanded(
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: media.size.width * dimensions['imageWidthRatio']!,
                                  maxHeight: constraints.maxHeight * 0.5,
                                ),
                                child: Image.asset(
                                  'assets/bienvenida.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: _onTap,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: dimensions['buttonSize']!,
                            height: dimensions['buttonSize']!,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
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
                      SizedBox(height: dimensions['bottomSpacing']!),
                      Text(
                        "Continuar",
                        style: TextStyle(
                          fontSize: dimensions['buttonTextSize']!,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
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