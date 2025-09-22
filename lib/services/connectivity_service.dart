import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Servicio para manejar la conectividad de red de forma global
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  // Stream controller para notificar cambios de conectividad
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Inicializa el servicio de conectividad
  Future<void> initialize() async {
    await _checkInitialConnectivity();
    _startListening();
  }

  /// Verifica la conectividad inicial
  Future<void> _checkInitialConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
      _isConnected = false;
    }
  }

  /// Inicia la escucha de cambios de conectividad
  void _startListening() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _updateConnectionStatus,
      onError: (error) {
        debugPrint('Connectivity stream error: $error');
      },
    );
  }

  /// Actualiza el estado de conexión
  void _updateConnectionStatus(ConnectivityResult result) {
    final wasConnected = _isConnected;
    _isConnected = result != ConnectivityResult.none;
    
    // Solo notificar si hay un cambio real en el estado
    if (wasConnected != _isConnected) {
      _connectivityController.add(_isConnected);
    }
  }

  /// Verifica manualmente el estado de la conexión
  Future<bool> checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _updateConnectionStatus(result);
      return _isConnected;
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Libera recursos
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }
}

/// Mixin para usar conectividad en StatefulWidgets
mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  /// Inicializa la conectividad
  void _initConnectivity() {
    _connectivityService.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isConnected = _connectivityService.isConnected;
        });
      }
    });

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
          onConnectivityChanged(isConnected);
        }
      },
    );
  }

  /// Callback cuando cambia la conectividad - override en las clases que usen el mixin
  void onConnectivityChanged(bool isConnected) {
    _showConnectivityToast(isConnected);
  }

  /// Muestra un toast sobre el estado de conectividad
  void _showConnectivityToast(bool isConnected) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              isConnected ? 'Conexión restaurada' : 'Sin conexión a Internet',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: isConnected ? 2 : 4),
      ),
    );
  }
}

/// Widget para mostrar el indicador de conectividad
class ConnectivityIndicator extends StatelessWidget {
  final bool isConnected;
  final EdgeInsetsGeometry? margin;
  final String? customMessage;

  const ConnectivityIndicator({
    super.key,
    required this.isConnected,
    this.margin,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (isConnected) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange[700], size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              customMessage ?? 'Sin conexión a Internet',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget Builder que reacciona a cambios de conectividad
class ConnectivityBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, bool isConnected) builder;
  final Widget? offlineChild;

  const ConnectivityBuilder({
    super.key,
    required this.builder,
    this.offlineChild,
  });

  @override
  State<ConnectivityBuilder> createState() => _ConnectivityBuilderState();
}

class _ConnectivityBuilderState extends State<ConnectivityBuilder> {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initConnectivity() {
    _connectivityService.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isConnected = _connectivityService.isConnected;
        });
      }
    });

    _connectivitySubscription = _connectivityService.connectivityStream.listen(
      (isConnected) {
        if (mounted) {
          setState(() {
            _isConnected = isConnected;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isConnected && widget.offlineChild != null) {
      return widget.offlineChild!;
    }
    
    return widget.builder(context, _isConnected);
  }
}

/// Utilidades para conectividad
class ConnectivityUtils {
  /// Muestra un toast personalizado de conectividad
  static void showConnectivityToast(
    BuildContext context, {
    required bool isConnected,
    String? customMessage,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isConnected ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              customMessage ?? 
              (isConnected ? 'Conexión restaurada' : 'Sin conexión a Internet'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        backgroundColor: isConnected ? Colors.green : Colors.orange[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: duration ?? Duration(seconds: isConnected ? 2 : 4),
      ),
    );
  }

  /// Verifica si hay conectividad antes de ejecutar una acción
  static Future<bool> executeWithConnectivity(
    BuildContext context,
    Future<void> Function() action, {
    String? noConnectionMessage,
  }) async {
    final connectivityService = ConnectivityService();
    final isConnected = await connectivityService.checkConnectivity();
    
    if (!isConnected) {
      showConnectivityToast(
        context,
        isConnected: false,
        customMessage: noConnectionMessage ?? 'Sin conexión. Verifica tu conexión a Internet.',
      );
      return false;
    }
    
    await action();
    return true;
  }
}