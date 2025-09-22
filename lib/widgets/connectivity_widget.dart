// 📶 WIDGET DE ESTADO DE CONECTIVIDAD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../styles/styles_index.dart';
import '../services/connectivity_service.dart';

class ConnectivityWidget extends StatelessWidget {
  final Widget child;
  final bool showBanner;
  final VoidCallback? onRetry;
  
  const ConnectivityWidget({
    super.key,
    required this.child,
    this.showBanner = true,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        if (!connectivityService.isInitialized) {
          return _buildLoadingState();
        }

        if (connectivityService.isDisconnected && showBanner) {
          return _buildDisconnectedState(context);
        }

        return child;
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppStyles.primaryColor,
            ),
            const SizedBox(height: AppStyles.spacingLarge),
            Text(
              'Verificando conexión...',
              style: WidgetStyles.subtitleStyle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisconnectedState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.backgroundColor,
      body: Column(
        children: [
          // Banner de desconexión
          _buildConnectionBanner(context),
          // Contenido principal atenuado
          Expanded(
            child: Stack(
              children: [
                // Contenido original con overlay
                child,
                // Overlay semi-transparente
                Container(
                  color: AppStyles.backgroundColor.withOpacity(0.8),
                  child: _buildNoConnectionMessage(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBanner(BuildContext context) {
    return AnimatedContainer(
      duration: AppStyles.fastAnimation,
      width: double.infinity,
      padding: const EdgeInsets.all(AppStyles.spacingMedium),
      decoration: BoxDecoration(
        color: AppStyles.errorColor,
        boxShadow: [
          BoxShadow(
            color: AppStyles.errorColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingXSmall),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppStyles.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sin conexión a internet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Verifica tu conexión WiFi o datos móviles',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onRetry != null)
              IconButton(
                onPressed: onRetry,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoConnectionMessage(BuildContext context) {
    return Center(
      child: Padding(
        padding: StyleUtilities.getResponsivePadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono animado
            TweenAnimationBuilder(
              duration: AppStyles.slowAnimation,
              tween: Tween<double>(begin: 0.8, end: 1.0),
              builder: (context, scale, child) {
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppStyles.errorColor.withOpacity(0.1),
                          AppStyles.errorColor.withOpacity(0.2),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.cloud_off_rounded,
                      color: AppStyles.errorColor,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            
            StyleUtilities.getVerticalSpace(context, multiplier: 2),
            
            Text(
              "Sin conexión a internet",
              style: TextStyle(
                fontSize: StyleUtilities.getResponsiveFontSize(
                  context, 
                  mobile: 24, 
                  tablet: 28, 
                  desktop: 32
                ),
                fontWeight: FontWeight.bold,
                color: AppStyles.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppStyles.spacingMedium),
            
            Text(
              "Para crear y gestionar anuncios necesitas una conexión a internet activa.",
              style: WidgetStyles.bodyTextStyle.copyWith(
                fontSize: StyleUtilities.getResponsiveFontSize(
                  context,
                  mobile: 16,
                  tablet: 18,
                )
              ),
              textAlign: TextAlign.center,
            ),
            
            StyleUtilities.getVerticalSpace(context, multiplier: 2),
            
            // Botón de reintento
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppStyles.radiusMax),
                boxShadow: [
                  BoxShadow(
                    color: AppStyles.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded, size: 24),
                label: const Text("Verificar conexión"),
                onPressed: () async {
                  StyleUtilities.lightHaptic();
                  final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
                  await connectivityService.checkConnectivity();
                  if (onRetry != null) onRetry!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppStyles.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppStyles.spacingXLarge,
                    vertical: AppStyles.spacingLarge,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppStyles.radiusMax),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppStyles.spacingLarge),

            // Consejos de conectividad
            Container(
              padding: const EdgeInsets.all(AppStyles.spacingLarge),
              decoration: WidgetStyles.infoCardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppStyles.infoColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppStyles.spacingSmall),
                      Text(
                        'Consejos para conectarse:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppStyles.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppStyles.spacingMedium),
                  ...[
                    '• Verifica que el WiFi esté activado',
                    '• Revisa los datos móviles si no tienes WiFi',
                    '• Acércate al router WiFi',
                    '• Reinicia tu conexión de red'
                  ].map((tip) => Padding(
                    padding: const EdgeInsets.only(bottom: AppStyles.spacingXSmall),
                    child: Text(
                      tip,
                      style: TextStyle(
                        color: AppStyles.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget simple para mostrar estado de conexión en AppBar
class ConnectivityIndicator extends StatelessWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        if (!connectivityService.isInitialized || connectivityService.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(right: AppStyles.spacingMedium),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingSmall,
            vertical: AppStyles.spacingXSmall,
          ),
          decoration: BoxDecoration(
            color: AppStyles.errorColor,
            borderRadius: BorderRadius.circular(AppStyles.radiusMax),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: AppStyles.spacingXSmall),
              Text(
                'Sin internet',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Widget para banner flotante de conectividad
class ConnectivityBanner extends StatefulWidget {
  const ConnectivityBanner({super.key});

  @override
  State<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends State<ConnectivityBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = StyleUtilities.createStandardController(vsync: this);
    _slideAnimation = StyleUtilities.createSlideAnimation(
      _animationController,
      begin: const Offset(0, -1),
      end: Offset.zero,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivityService, _) {
        if (!connectivityService.isInitialized) {
          return const SizedBox.shrink();
        }

        if (connectivityService.isDisconnected) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }

        return SlideTransition(
          position: _slideAnimation,
          child: Material(
            elevation: AppStyles.elevationLarge,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppStyles.spacingMedium),
              decoration: BoxDecoration(
                color: AppStyles.errorColor,
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppStyles.spacingMedium),
                    Expanded(
                      child: Text(
                        'Sin conexión a internet. Algunas funciones pueden no estar disponibles.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}