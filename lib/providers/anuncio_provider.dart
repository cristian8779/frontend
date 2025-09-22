import 'package:flutter/material.dart';
import '../services/anuncio_service.dart';

enum AnuncioState { loading, loaded, error, empty }

class AnuncioProvider extends ChangeNotifier {
  final AnuncioService _anuncioService = AnuncioService();

  List<Map<String, String>> _anuncios = [];
  AnuncioState _state = AnuncioState.loading;
  int _currentIndex = 0;
  String? _error;

  // Getters
  List<Map<String, String>> get anuncios => _anuncios;
  AnuncioState get state => _state;
  int get currentIndex => _currentIndex;
  String? get error => _error;
  
  bool get isLoading => _state == AnuncioState.loading;
  bool get hasError => _state == AnuncioState.error;
  bool get isEmpty => _state == AnuncioState.empty;
  bool get hasData => _state == AnuncioState.loaded && _anuncios.isNotEmpty;

  /// 🔹 Cargar anuncios
  /// mostrarLoading: si es false, no cambia el estado del provider (para refresh)
  Future<void> loadAnuncios({bool mostrarLoading = true}) async {
    if (mostrarLoading) {
      _setState(AnuncioState.loading);
      _error = null;
    }

    try {
      final anuncios = await _anuncioService.obtenerAnunciosActivos();
      
      _anuncios = anuncios;
      
      if (anuncios.isEmpty) {
        if (mostrarLoading) _setState(AnuncioState.empty);
      } else {
        if (mostrarLoading) _setState(AnuncioState.loaded);
      }
    } catch (e) {
      _error = e.toString();
      if (mostrarLoading) _setState(AnuncioState.error);
    }

    // 🔹 Si no se muestra loading, se notifica solo para actualizar datos
    if (!mostrarLoading) notifyListeners();
  }

  // Cambiar índice actual del carousel
  void setCurrentIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }

  // Método para prefetch de imágenes (opcional, se puede llamar desde el widget)
  Future<void> prefetchImages(BuildContext context, {int maxImages = 3}) async {
    for (int i = 0; i < _anuncios.length && i < maxImages; i++) {
      final url = _anuncios[i]['imagen'];
      if (url != null && url.isNotEmpty) {
        try {
          await precacheImage(
            NetworkImage(url),
            context,
          );
        } catch (_) {
          // Ignorar errores de precarga
        }
      }
    }
  }

  // Navegación por deeplink
  void navigateToDeeplink(BuildContext context, String? deeplink) {
    if (deeplink != null && deeplink.isNotEmpty) {
      Navigator.pushNamed(context, deeplink);
    }
  }

  // Método privado para cambiar estado
  void _setState(AnuncioState newState) {
    _state = newState;
    notifyListeners();
  }

  // Reset del provider
  void reset() {
    _anuncios = [];
    _state = AnuncioState.loading;
    _currentIndex = 0;
    _error = null;
    notifyListeners();
  }
}
