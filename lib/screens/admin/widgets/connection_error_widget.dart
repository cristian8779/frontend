import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:io';

class ConnectionErrorWidget extends StatefulWidget {
  final String errorMessage;
  final VoidCallback onRetry;

  const ConnectionErrorWidget({
    super.key,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  State<ConnectionErrorWidget> createState() => _ConnectionErrorWidgetState();
}

class _ConnectionErrorWidgetState extends State<ConnectionErrorWidget> {
  bool _isCheckingConnection = false;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    _checkConnectionStatus();
  }

  Future<void> _checkConnectionStatus() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasInternet = await _hasInternetConnection();
      
      setState(() {
        if (connectivityResult == ConnectivityResult.none) {
          _connectionStatus = 'Sin conexión de red';
        } else if (!hasInternet) {
          _connectionStatus = 'Conectado pero sin internet';
        } else {
          _connectionStatus = 'Conexión OK';
        }
      });
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error verificando conexión';
      });
    }
  }

  Future<bool> _hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Función mejorada para determinar el tipo de error
  Map<String, dynamic> _getErrorData() {
    final error = widget.errorMessage;
    final errorLower = error.toLowerCase();
    
    // Si no hay conexión real, usar datos de conectividad
    if (_connectionStatus == 'Sin conexión de red') {
      return {
        'title': 'No hay conexión a internet',
        'subtitle': 'Activá tu WiFi o datos móviles para continuar.',
        'illustration': '📵',
      };
    } else if (_connectionStatus == 'Conectado pero sin internet') {
      return {
        'title': 'Problemas con tu conexión',
        'subtitle': 'Estás conectado pero no podés acceder a internet. Verificá tu conexión.',
        'illustration': '📶',
      };
    }
    
    // Errores de conexión de red - Detección ampliada
    if (error.contains('SocketException') || 
        error.contains('NetworkException') ||
        error.contains('ClientException') ||
        error.contains('HttpException') ||
        errorLower.contains('connection') ||
        errorLower.contains('network') ||
        errorLower.contains('internet') ||
        errorLower.contains('failed to connect') ||
        errorLower.contains('unreachable') ||
        errorLower.contains('connection refused') ||
        errorLower.contains('host lookup failed')) {
      return {
        'title': 'Sin conexión a internet',
        'subtitle': 'Revisá tu conexión wifi o los datos móviles e intentá de nuevo.',
        'illustration': '📶',
      };
    } 
    // Errores de timeout
    else if (error.contains('TimeoutException') || 
               errorLower.contains('timeout') ||
               errorLower.contains('timed out')) {
      return {
        'title': 'La conexión tardó demasiado',
        'subtitle': 'Verificá tu conexión a internet e intentá nuevamente.',
        'illustration': '⏱️',
      };
    } 
    // Errores de servidor
    else if (error.contains('500') || 
               error.contains('502') || 
               error.contains('503') ||
               error.contains('504') ||
               errorLower.contains('server') ||
               errorLower.contains('servidor')) {
      return {
        'title': 'Hay un problema con nuestros servidores',
        'subtitle': 'Estamos trabajando para solucionarlo. Intentá nuevamente en unos minutos.',
        'illustration': '🔧',
      };
    } 
    // Errores de autenticación
    else if (error.contains('Token expirado') ||
               error.contains('401') ||
               errorLower.contains('unauthorized') ||
               errorLower.contains('token')) {
      return {
        'title': 'Tu sesión expiró',
        'subtitle': 'Por tu seguridad, necesitás iniciar sesión nuevamente.',
        'illustration': '🔐',
      };
    } 
    // Errores de permisos
    else if (error.contains('403') || 
               errorLower.contains('forbidden') ||
               errorLower.contains('access denied')) {
      return {
        'title': 'Sin permisos',
        'subtitle': 'No tenés permisos para realizar esta acción.',
        'illustration': '🚫',
      };
    }
    // Errores 404
    else if (error.contains('404') || 
               errorLower.contains('not found')) {
      return {
        'title': 'No encontrado',
        'subtitle': 'No pudimos encontrar lo que buscás.',
        'illustration': '🔍',
      };
    }
    // Error genérico
    else {
      return {
        'title': 'Algo salió mal',
        'subtitle': 'Ocurrió un error inesperado. Intentá nuevamente.',
        'illustration': '⚠️',
      };
    }
  }

  // Función para obtener dimensiones responsivas
  Map<String, double> _getDimensions(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 768;
    final isDesktop = screenWidth >= 1024;
    
    if (isDesktop) {
      return {
        'titleFontSize': 18.0,
        'subtitleFontSize': 14.0,
        'buttonFontSize': 14.0,
        'horizontalMargin': 40.0,
        'verticalPadding': 32.0,
        'horizontalPadding': 32.0,
        'buttonPadding': 12.0,
        'spacing': 16.0,
        'illustrationSize': 80.0,
      };
    } else if (isTablet) {
      return {
        'titleFontSize': 17.0,
        'subtitleFontSize': 13.5,
        'buttonFontSize': 14.0,
        'horizontalMargin': 32.0,
        'verticalPadding': 28.0,
        'horizontalPadding': 28.0,
        'buttonPadding': 12.0,
        'spacing': 14.0,
        'illustrationSize': 72.0,
      };
    } else {
      return {
        'titleFontSize': 16.0,
        'subtitleFontSize': 13.0,
        'buttonFontSize': 14.0,
        'horizontalMargin': 20.0,
        'verticalPadding': 24.0,
        'horizontalPadding': 24.0,
        'buttonPadding': 12.0,
        'spacing': 12.0,
        'illustrationSize': 64.0,
      };
    }
  }

  Future<void> _handleRetry() async {
    setState(() {
      _isCheckingConnection = true;
    });

    await _checkConnectionStatus();
    
    setState(() {
      _isCheckingConnection = false;
    });

    widget.onRetry();
  }

  @override
  Widget build(BuildContext context) {
    final errorData = _getErrorData();
    final dimensions = _getDimensions(context);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: dimensions['horizontalMargin']!),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: dimensions['verticalPadding']!,
          horizontal: dimensions['horizontalPadding']!,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFFE6E6E6),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ilustración con icono mejorado
            Container(
              width: dimensions['illustrationSize']!,
              height: dimensions['illustrationSize']!,
              decoration: BoxDecoration(
                color: (errorData['iconColor'] as Color? ?? const Color(0xFF757575)).withOpacity(0.08),
                borderRadius: BorderRadius.circular(dimensions['illustrationSize']! / 2),
              ),
              child: Center(
                child: Icon(
                  errorData['icon'] as IconData? ?? Icons.error_outline_rounded,
                  size: dimensions['illustrationSize']! * 0.5,
                  color: errorData['iconColor'] as Color? ?? const Color(0xFF757575),
                ),
              ),
            ),
            
            SizedBox(height: dimensions['spacing']! * 1.5),
            
            // Título
            Text(
              errorData['title'] as String,
              style: TextStyle(
                fontSize: dimensions['titleFontSize']!,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF333333),
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: dimensions['spacing']! * 0.5),
            
            // Subtítulo
            Text(
              errorData['subtitle'] as String,
              style: TextStyle(
                fontSize: dimensions['subtitleFontSize']!,
                color: const Color(0xFF666666),
                height: 1.4,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),

            // Mostrar estado de conexión si está disponible
            if (_connectionStatus != null) ...[
              SizedBox(height: dimensions['spacing']!),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Estado: $_connectionStatus',
                  style: TextStyle(
                    fontSize: 11,
                    color: const Color(0xFF888888),
                  ),
                ),
              ),
            ],
            
            SizedBox(height: dimensions['spacing']! * 2),
            
            // Botón de reintentar - estilo Mercado Libre
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCheckingConnection ? null : _handleRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3483FA), // Azul ML
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    vertical: dimensions['buttonPadding']!,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: _isCheckingConnection 
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Intentar nuevamente",
                      style: TextStyle(
                        fontSize: dimensions['buttonFontSize']!,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.1,
                      ),
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget simplificado para usar en lugar de ErrorMessage
class ImprovedErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ImprovedErrorMessage({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ConnectionErrorWidget(
        errorMessage: message,
        onRetry: onRetry ?? () {},
      ),
    );
  }
}