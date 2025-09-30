// bienvenida_admin_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles/bienvenidad_admin/bienvenida_admin_styles.dart'; // Import de los estilos

class BienvenidaAdminScreen extends StatefulWidget {
  final String rol;

  const BienvenidaAdminScreen({
    super.key,
    required this.rol,
  });

  @override
  State<BienvenidaAdminScreen> createState() => _BienvenidaAdminScreenState();
}

class _BienvenidaAdminScreenState extends State<BienvenidaAdminScreen>
    with TickerProviderStateMixin {
  // Controllers de animación
  late AnimationController _controller;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  
  // Animaciones
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _buttonBounceAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startAnimationSequence();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: BienvenidaAdminAnimations.mainDuration,
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: BienvenidaAdminAnimations.slideDuration,
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: BienvenidaAdminAnimations.fadeDuration,
      vsync: this,
    );

    _scaleAnimation = BienvenidaAdminAnimations.getScaleTween().animate(
      CurvedAnimation(
        parent: _controller,
        curve: BienvenidaAdminAnimations.elasticCurve,
      ),
    );

    _slideAnimation = BienvenidaAdminAnimations.getSlideTween().animate(
      CurvedAnimation(
        parent: _slideController,
        curve: BienvenidaAdminAnimations.slideEaseCurve,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: BienvenidaAdminAnimations.fadeEaseCurve,
    );

    _buttonBounceAnimation = BienvenidaAdminAnimations.getBounceTween().animate(
      CurvedAnimation(
        parent: _controller,
        curve: BienvenidaAdminAnimations.elasticCurve,
      ),
    );
  }

  void _startAnimationSequence() {
    Future.delayed(BienvenidaAdminAnimations.slideDelay, () {
      _slideController.forward();
    });
    
    Future.delayed(BienvenidaAdminAnimations.fadeDelay, () {
      _fadeController.forward();
    });
    
    Future.delayed(BienvenidaAdminAnimations.scaleDelay, () {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dimensions = BienvenidaAdminDimensions.getResponsiveDimensions(context);
        final media = MediaQuery.of(context);
        final isSmall = BienvenidaAdminDimensions.isSmallHeight(context);

        return Scaffold(
          body: Container(
            decoration: BienvenidaAdminDecorations.getBackgroundDecoration(),
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
                        _RoleIndicator(
                          rol: widget.rol,
                          slideAnimation: _slideAnimation,
                          fadeAnimation: _fadeAnimation,
                        ),
                        
                        const SizedBox(height: BienvenidaAdminDimensions.roleIndicatorSpacing),
                        
                        _MainContent(
                          dimensions: dimensions,
                          media: media,
                          constraints: constraints,
                          isSmall: isSmall,
                          slideAnimation: _slideAnimation,
                          fadeAnimation: _fadeAnimation,
                        ),
                        
                        SizedBox(height: dimensions['bottomSpacing']!),
                        
                        _ContinueButton(
                          dimensions: dimensions,
                          buttonBounceAnimation: _buttonBounceAnimation,
                          fadeAnimation: _fadeAnimation,
                          onTap: _onTap,
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

  void _onTap() async {
    HapticFeedback.lightImpact();
    
    await _controller.reverse();
    await Future.delayed(BienvenidaAdminAnimations.tapDelay);
    await _controller.forward();

    await Future.delayed(BienvenidaAdminAnimations.navigationDelay);
    
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        BienvenidaAdminConstants.controlPanelRoute,
        arguments: {'rol': widget.rol},
      );
    }
  }
}

class _RoleIndicator extends StatelessWidget {
  final String rol;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const _RoleIndicator({
    required this.rol,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final isSuper = rol.toLowerCase() == BienvenidaAdminConstants.superAdminRoleKey;
    
    return FadeTransition(
      opacity: fadeAnimation,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          padding: BienvenidaAdminLayout.roleIndicatorPadding,
          decoration: BienvenidaAdminDecorations.getRoleIndicatorDecoration(
            isSuper: isSuper,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSuper 
                  ? BienvenidaAdminTheme.superAdminIcon 
                  : BienvenidaAdminTheme.adminIcon,
                size: BienvenidaAdminDimensions.roleIconSize,
                color: isSuper 
                  ? BienvenidaAdminTheme.superAdminTextColor 
                  : BienvenidaAdminTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                isSuper 
                  ? BienvenidaAdminConstants.superAdminRole 
                  : BienvenidaAdminConstants.adminRole,
                style: BienvenidaAdminTextStyles.roleTextStyle.copyWith(
                  color: isSuper 
                    ? BienvenidaAdminTheme.superAdminTextColor 
                    : BienvenidaAdminTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainContent extends StatelessWidget {
  final Map<String, double> dimensions;
  final MediaQueryData media;
  final BoxConstraints constraints;
  final bool isSmall;
  final Animation<Offset> slideAnimation;
  final Animation<double> fadeAnimation;

  const _MainContent({
    required this.dimensions,
    required this.media,
    required this.constraints,
    required this.isSmall,
    required this.slideAnimation,
    required this.fadeAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SlideTransition(
        position: slideAnimation,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Card(
            elevation: BienvenidaAdminDimensions.cardElevation,
            shadowColor: BienvenidaAdminTheme.cardShadowColor,
            shape: BienvenidaAdminConstants.getCardShape(),
            child: Container(
              padding: EdgeInsets.all(dimensions['cardPadding']!),
              decoration: BienvenidaAdminDecorations.getCardDecoration(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TitleSection(dimensions: dimensions, isSmall: isSmall),
                  _FloatingImage(
                    dimensions: dimensions,
                    media: media,
                    constraints: constraints,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final Map<String, double> dimensions;
  final bool isSmall;

  const _TitleSection({
    required this.dimensions,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          BienvenidaAdminConstants.welcomeTitle,
          style: BienvenidaAdminTextStyles.getTitleStyle(dimensions),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(
          height: isSmall 
            ? BienvenidaAdminDimensions.titleSubtitleSpacing
            : BienvenidaAdminDimensions.titleSubtitleSpacingLarge,
        ),
        
        Text(
          BienvenidaAdminConstants.adminPanelSubtitle,
          style: BienvenidaAdminTextStyles.getSubtitleStyle(dimensions),
          textAlign: TextAlign.center,
        ),
        
        SizedBox(
          height: isSmall 
            ? BienvenidaAdminDimensions.contentImageSpacing
            : BienvenidaAdminDimensions.contentImageSpacingLarge,
        ),
      ],
    );
  }
}

class _FloatingImage extends StatelessWidget {
  final Map<String, double> dimensions;
  final MediaQueryData media;
  final BoxConstraints constraints;

  const _FloatingImage({
    required this.dimensions,
    required this.media,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        constraints: BienvenidaAdminLayout.getImageConstraints(
          maxWidth: media.size.width,
          maxHeight: constraints.maxHeight,
          widthRatio: dimensions['imageWidthRatio']!,
        ),
        child: TweenAnimationBuilder<double>(
          duration: BienvenidaAdminAnimations.floatingDuration,
          tween: BienvenidaAdminAnimations.getFloatingTween(),
          builder: (context, value, child) {
            return Transform.translate(
              offset: BienvenidaAdminLayout.getFloatingOffset(value),
              child: Image.asset(
                BienvenidaAdminConstants.welcomeImagePath,
                fit: BoxFit.contain,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final Map<String, double> dimensions;
  final Animation<double> buttonBounceAnimation;
  final Animation<double> fadeAnimation;
  final VoidCallback onTap;

  const _ContinueButton({
    required this.dimensions,
    required this.buttonBounceAnimation,
    required this.fadeAnimation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ScaleTransition(
          scale: buttonBounceAnimation,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              width: dimensions['buttonSize']!,
              height: dimensions['buttonSize']!,
              decoration: BienvenidaAdminDecorations.getButtonDecoration(),
              child: Icon(
                BienvenidaAdminTheme.continueIcon,
                color: BienvenidaAdminTheme.buttonIconColor,
                size: dimensions['iconSize']!,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: BienvenidaAdminDimensions.buttonTextSpacing),
        
        FadeTransition(
          opacity: fadeAnimation,
          child: Text(
            BienvenidaAdminConstants.continueText,
            style: BienvenidaAdminTextStyles.getButtonTextStyle(dimensions),
          ),
        ),
      ],
    );
  }
}