import 'package:flutter/material.dart';

class ColorUtil {
  // Mapa HEX → Nombre
  static final Map<String, String> coloresMap = {
    '#FF0000': 'Rojo',
    '#00FF00': 'Verde',
    '#0000FF': 'Azul',
    '#FFFF00': 'Amarillo',
    '#FF00FF': 'Magenta',
    '#00FFFF': 'Cyan',
    '#000000': 'Negro',
    '#FFFFFF': 'Blanco',
    '#800000': 'Marrón oscuro',
    '#808000': 'Oliva',
    '#008000': 'Verde oscuro',
    '#800080': 'Púrpura',
    '#008080': 'Verde azulado',
    '#000080': 'Azul marino',
    '#FFA500': 'Naranja',
    '#A52A2A': 'Marrón',
    '#FFC0CB': 'Rosa',
    '#FFD700': 'Dorado',
    '#C0C0C0': 'Plata',
    '#ADD8E6': 'Azul claro',
    '#90EE90': 'Verde claro',
    '#FFB6C1': 'Rosa claro',
    '#FFA07A': 'Salmón',
    '#20B2AA': 'Aguamarina',
    '#87CEFA': 'Azul cielo',
    '#778899': 'Gris pizarra claro',
    '#B0C4DE': 'Azul acero claro',
    '#FFFFE0': 'Amarillo claro',
    '#00FA9A': 'Primavera medio',
    '#48D1CC': 'Turquesa medio',
    '#C71585': 'Medio púrpura violeta',
    '#191970': 'Azul medianoche',
    '#F5FFFA': 'Menta',
    '#FFE4E1': 'Rosa lavanda',
    '#FFE4B5': 'Mocasín',
    '#FFDEAD': 'Navajo blanco',
    '#FA8072': 'Salmón claro',
    '#E9967A': 'Salmón oscuro',
    '#F0E68C': 'Caqui',
    '#D3D3D3': 'Gris claro',
    '#FF6347': 'Tomate',
    '#40E0D0': 'Turquesa',
    '#EE82EE': 'Violeta',
    '#F5DEB3': 'Trigo',
    '#D2691E': 'Chocolate',
    '#2F4F4F': 'Gris oscuro azulado',
    '#696969': 'Gris oscuro',
    '#708090': 'Gris pizarra',
    '#B22222': 'Ladrillo',
    '#FF4500': 'Naranja rojizo',
    '#DA70D6': 'Orquídea',
    '#7FFF00': 'Chartreuse',
  };

  // Mapa inverso: nombre → color
  static final Map<String, Color> nombreToColor = {
    for (var entry in coloresMap.entries) entry.value: _hexToColor(entry.key),
  };

  // Grupos organizados por categoría
  static final Map<String, List<Map<String, String>>> coloresAgrupados = {
    'Rojos': [
      {'hex': '#FF0000', 'nombre': 'Rojo'},
      {'hex': '#FF6347', 'nombre': 'Tomate'},
      {'hex': '#B22222', 'nombre': 'Ladrillo'},
      {'hex': '#FF4500', 'nombre': 'Naranja rojizo'},
    ],
    'Verdes': [
      {'hex': '#00FF00', 'nombre': 'Verde'},
      {'hex': '#90EE90', 'nombre': 'Verde claro'},
      {'hex': '#7FFF00', 'nombre': 'Chartreuse'},
      {'hex': '#008000', 'nombre': 'Verde oscuro'},
      {'hex': '#00FA9A', 'nombre': 'Primavera medio'},
    ],
    'Azules': [
      {'hex': '#0000FF', 'nombre': 'Azul'},
      {'hex': '#ADD8E6', 'nombre': 'Azul claro'},
      {'hex': '#87CEFA', 'nombre': 'Azul cielo'},
      {'hex': '#000080', 'nombre': 'Azul marino'},
      {'hex': '#191970', 'nombre': 'Azul medianoche'},
      {'hex': '#B0C4DE', 'nombre': 'Azul acero claro'},
    ],
    'Amarillos y Naranjas': [
      {'hex': '#FFFF00', 'nombre': 'Amarillo'},
      {'hex': '#FFD700', 'nombre': 'Dorado'},
      {'hex': '#FFA500', 'nombre': 'Naranja'},
      {'hex': '#FFFFE0', 'nombre': 'Amarillo claro'},
    ],
    'Rosados y Violetas': [
      {'hex': '#FFC0CB', 'nombre': 'Rosa'},
      {'hex': '#FFB6C1', 'nombre': 'Rosa claro'},
      {'hex': '#FFE4E1', 'nombre': 'Rosa lavanda'},
      {'hex': '#EE82EE', 'nombre': 'Violeta'},
      {'hex': '#C71585', 'nombre': 'Medio púrpura violeta'},
      {'hex': '#DA70D6', 'nombre': 'Orquídea'},
    ],
    'Tonos Tierra': [
      {'hex': '#A52A2A', 'nombre': 'Marrón'},
      {'hex': '#800000', 'nombre': 'Marrón oscuro'},
      {'hex': '#FFE4B5', 'nombre': 'Mocasín'},
      {'hex': '#FFDEAD', 'nombre': 'Navajo blanco'},
      {'hex': '#F5DEB3', 'nombre': 'Trigo'},
      {'hex': '#D2691E', 'nombre': 'Chocolate'},
    ],
    'Grises y Neutros': [
      {'hex': '#C0C0C0', 'nombre': 'Plata'},
      {'hex': '#D3D3D3', 'nombre': 'Gris claro'},
      {'hex': '#708090', 'nombre': 'Gris pizarra'},
      {'hex': '#778899', 'nombre': 'Gris pizarra claro'},
      {'hex': '#696969', 'nombre': 'Gris oscuro'},
      {'hex': '#2F4F4F', 'nombre': 'Gris oscuro azulado'},
    ],
    'Otros': [
      {'hex': '#00FFFF', 'nombre': 'Cyan'},
      {'hex': '#F5FFFA', 'nombre': 'Menta'},
      {'hex': '#008080', 'nombre': 'Verde azulado'},
      {'hex': '#40E0D0', 'nombre': 'Turquesa'},
      {'hex': '#48D1CC', 'nombre': 'Turquesa medio'},
      {'hex': '#800080', 'nombre': 'Púrpura'},
    ],
  };

  // Convertir HEX a Color con opacidad
  static Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // Añadir opacidad
    return Color(int.parse(hex, radix: 16));
  }
}

class Colores {
  // Lista completa de colores disponibles
  static List<Map<String, String>> get coloresDisponibles {
    return ColorUtil.coloresMap.entries
        .map((e) => {"nombre": e.value, "hex": e.key})
        .toList();
  }

  // Colores agrupados por categorías
  static Map<String, List<Map<String, String>>> get coloresAgrupados {
    return ColorUtil.coloresAgrupados;
  }

  // Obtener nombre por hex
  static String getNombreColor(String hex) {
    return ColorUtil.coloresMap[hex.toUpperCase()] ?? hex.toUpperCase();
  }

  // Convertir hex a objeto Color
  static Color hexToColor(String hex) {
    return ColorUtil._hexToColor(hex);
  }

  // Obtener color desde nombre
  static Map<String, Color> get nombreToColor {
    return ColorUtil.nombreToColor;
  }
}
