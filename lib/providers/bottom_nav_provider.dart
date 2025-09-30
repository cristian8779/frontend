// 1. Primero, modifica tu BottomNavProvider para manejar mejor el estado
import 'package:flutter/material.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  
  int get currentIndex => _currentIndex;
  
  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
  
  void resetToHome() {
    _currentIndex = 0;
    notifyListeners();
  }
}