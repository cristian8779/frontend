import 'package:flutter/material.dart';

class ColorOption {
  final String nombre;
  final Color color;

  ColorOption(this.nombre, this.color);

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'color': '#${color.value.toRadixString(16).padLeft(8, '0')}',
    };
  }

  factory ColorOption.fromJson(Map<String, dynamic> json) {
    return ColorOption(
      json['nombre'],
      Color(int.parse(json['color'].substring(1), radix: 16)),
    );
  }
}
