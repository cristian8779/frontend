import 'package:flutter/material.dart';

class ColorUtil {
  // Mapa HEX → Nombre
  static final Map<String, String> coloresMap = {
    // Rojos
    '#FF0000': 'Rojo',
    '#DC143C': 'Carmesí',
    '#B22222': 'Ladrillo',
    '#8B0000': 'Rojo oscuro',
    '#CD5C5C': 'Rojo indio',
    '#F08080': 'Coral claro',
    '#FA8072': 'Salmón claro',
    '#E9967A': 'Salmón oscuro',
    '#FFA07A': 'Salmón',
    '#FF6347': 'Tomate',
    '#FF4500': 'Naranja rojizo',
    '#FF69B4': 'Rosa fuerte',
    '#FF1493': 'Rosa profundo',
    '#C71585': 'Medio púrpura violeta',
    
    // Naranjas
    '#FFA500': 'Naranja',
    '#FF8C00': 'Naranja oscuro',
    '#FF7F50': 'Coral',
    '#FF6347': 'Tomate',
    '#FFE4B5': 'Mocasín',
    '#FFDAB9': 'Melocotón',
    '#FFB6C1': 'Rosa claro',
    
    // Amarillos
    '#FFFF00': 'Amarillo',
    '#FFD700': 'Dorado',
    '#FFF8DC': 'Blanco maíz',
    '#FFFFE0': 'Amarillo claro',
    '#FFFACD': 'Amarillo limón',
    '#F0E68C': 'Caqui',
    '#EEE8AA': 'Vara de oro pálido',
    '#BDB76B': 'Caqui oscuro',
    '#FAFAD2': 'Vara de oro claro',
    
    // Verdes
    '#00FF00': 'Verde lima',
    '#32CD32': 'Verde lima',
    '#00FF7F': 'Verde primavera',
    '#00FA9A': 'Verde primavera medio',
    '#90EE90': 'Verde claro',
    '#98FB98': 'Verde pálido',
    '#8FBC8F': 'Verde mar oscuro',
    '#3CB371': 'Verde mar medio',
    '#2E8B57': 'Verde mar',
    '#228B22': 'Verde bosque',
    '#008000': 'Verde',
    '#006400': 'Verde oscuro',
    '#9ACD32': 'Amarillo verde',
    '#6B8E23': 'Oliva oscuro',
    '#808000': 'Oliva',
    '#556B2F': 'Oliva oscuro',
    '#66CDAA': 'Aguamarina medio',
    '#7FFF00': 'Chartreuse',
    '#7CFC00': 'Verde césped',
    '#ADFF2F': 'Verde amarillo',
    
    // Azules
    '#0000FF': 'Azul',
    '#0000CD': 'Azul medio',
    '#00008B': 'Azul oscuro',
    '#000080': 'Azul marino',
    '#191970': 'Azul medianoche',
    '#4169E1': 'Azul real',
    '#6495ED': 'Azul aciano',
    '#4682B4': 'Azul acero',
    '#5F9EA0': 'Azul cadete',
    '#1E90FF': 'Azul dodger',
    '#00BFFF': 'Azul cielo profundo',
    '#87CEEB': 'Azul cielo',
    '#87CEFA': 'Azul cielo claro',
    '#ADD8E6': 'Azul claro',
    '#B0C4DE': 'Azul acero claro',
    '#B0E0E6': 'Azul polvo',
    '#AFEEEE': 'Turquesa pálido',
    '#00CED1': 'Turquesa oscuro',
    '#48D1CC': 'Turquesa medio',
    '#40E0D0': 'Turquesa',
    '#00FFFF': 'Cyan',
    '#E0FFFF': 'Cyan claro',
    '#00FFFF': 'Aqua',
    
    // Púrpuras y Violetas
    '#800080': 'Púrpura',
    '#8B008B': 'Magenta oscuro',
    '#9370DB': 'Púrpura medio',
    '#9932CC': 'Orquídea oscuro',
    '#BA55D3': 'Orquídea medio',
    '#DA70D6': 'Orquídea',
    '#DDA0DD': 'Ciruela',
    '#EE82EE': 'Violeta',
    '#FF00FF': 'Magenta',
    '#FF00FF': 'Fucsia',
    '#D8BFD8': 'Cardo',
    '#E6E6FA': 'Lavanda',
    '#8A2BE2': 'Azul violeta',
    '#9400D3': 'Violeta oscuro',
    '#9932CC': 'Orquídea oscuro',
    '#4B0082': 'Índigo',
    '#6A5ACD': 'Azul pizarra',
    '#7B68EE': 'Azul pizarra medio',
    
    // Rosas
    '#FFC0CB': 'Rosa',
    '#FFB6C1': 'Rosa claro',
    '#FF69B4': 'Rosa fuerte',
    '#FF1493': 'Rosa profundo',
    '#DB7093': 'Violeta rojo pálido',
    '#FFE4E1': 'Rosa lavanda',
    '#FFF0F5': 'Rubor lavanda',
    '#FFDAB9': 'Melocotón',
    
    // Marrones
    '#A52A2A': 'Marrón',
    '#8B4513': 'Marrón silla de montar',
    '#D2691E': 'Chocolate',
    '#CD853F': 'Marrón Perú',
    '#F4A460': 'Marrón arena',
    '#DEB887': 'Madera',
    '#D2B48C': 'Bronceado',
    '#BC8F8F': 'Marrón rosado',
    '#FFE4C4': 'Bisque',
    '#FFDEAD': 'Navajo blanco',
    '#F5DEB3': 'Trigo',
    '#FFF8DC': 'Blanco maíz',
    '#FFFAF0': 'Blanco floral',
    '#FAF0E6': 'Lino',
    '#FDF5E6': 'Blanco antiguo',
    '#FFEFD5': 'Blanco papaya',
    '#FFEBCD': 'Almendra blanqueada',
    '#800000': 'Marrón',
    
    // Grises
    '#808080': 'Gris',
    '#A9A9A9': 'Gris oscuro',
    '#C0C0C0': 'Plata',
    '#D3D3D3': 'Gris claro',
    '#DCDCDC': 'Gainsboro',
    '#F5F5F5': 'Blanco humo',
    '#696969': 'Gris tenue',
    '#708090': 'Gris pizarra',
    '#778899': 'Gris pizarra claro',
    '#2F4F4F': 'Gris pizarra oscuro',
    
    // Blancos
    '#FFFFFF': 'Blanco',
    '#FFFAFA': 'Blanco nieve',
    '#F0FFF0': 'Rocío de miel',
    '#F5FFFA': 'Crema de menta',
    '#F0FFFF': 'Azure',
    '#F0F8FF': 'Azul Alicia',
    '#F8F8FF': 'Blanco fantasma',
    '#FFFFF0': 'Marfil',
    '#FFFAF0': 'Blanco floral',
    '#FFF5EE': 'Concha marina',
    '#FAF0E6': 'Lino',
    '#FFF0F5': 'Rubor lavanda',
    '#FFE4E1': 'Rosa lavanda',
    
    // Negros
    '#000000': 'Negro',
    
    // Verdes azulados
    '#008080': 'Verde azulado',
    '#008B8B': 'Cyan oscuro',
    '#20B2AA': 'Verde mar claro',
    '#2F4F4F': 'Gris pizarra oscuro',
    '#00CED1': 'Turquesa oscuro',
    '#5F9EA0': 'Azul cadete',
  };

  // Mapa inverso: nombre → color
  static final Map<String, Color> nombreToColor = {
    for (var entry in coloresMap.entries) entry.value: _hexToColor(entry.key),
  };

  // Grupos organizados por categoría
  static final Map<String, List<Map<String, String>>> coloresAgrupados = {
    'Rojos': [
      {'hex': '#FF0000', 'nombre': 'Rojo'},
      {'hex': '#DC143C', 'nombre': 'Carmesí'},
      {'hex': '#B22222', 'nombre': 'Ladrillo'},
      {'hex': '#8B0000', 'nombre': 'Rojo oscuro'},
      {'hex': '#CD5C5C', 'nombre': 'Rojo indio'},
      {'hex': '#FF6347', 'nombre': 'Tomate'},
      {'hex': '#FF4500', 'nombre': 'Naranja rojizo'},
    ],
    'Rosas': [
      {'hex': '#FFC0CB', 'nombre': 'Rosa'},
      {'hex': '#FFB6C1', 'nombre': 'Rosa claro'},
      {'hex': '#FF69B4', 'nombre': 'Rosa fuerte'},
      {'hex': '#FF1493', 'nombre': 'Rosa profundo'},
      {'hex': '#FFE4E1', 'nombre': 'Rosa lavanda'},
      {'hex': '#FFDAB9', 'nombre': 'Melocotón'},
    ],
    'Naranjas': [
      {'hex': '#FFA500', 'nombre': 'Naranja'},
      {'hex': '#FF8C00', 'nombre': 'Naranja oscuro'},
      {'hex': '#FF7F50', 'nombre': 'Coral'},
      {'hex': '#FFA07A', 'nombre': 'Salmón'},
      {'hex': '#FA8072', 'nombre': 'Salmón claro'},
    ],
    'Amarillos': [
      {'hex': '#FFFF00', 'nombre': 'Amarillo'},
      {'hex': '#FFD700', 'nombre': 'Dorado'},
      {'hex': '#FFFFE0', 'nombre': 'Amarillo claro'},
      {'hex': '#FFFACD', 'nombre': 'Amarillo limón'},
      {'hex': '#F0E68C', 'nombre': 'Caqui'},
      {'hex': '#FAFAD2', 'nombre': 'Vara de oro claro'},
    ],
    'Verdes': [
      {'hex': '#00FF00', 'nombre': 'Verde lima'},
      {'hex': '#32CD32', 'nombre': 'Verde lima'},
      {'hex': '#00FF7F', 'nombre': 'Verde primavera'},
      {'hex': '#90EE90', 'nombre': 'Verde claro'},
      {'hex': '#008000', 'nombre': 'Verde'},
      {'hex': '#006400', 'nombre': 'Verde oscuro'},
      {'hex': '#228B22', 'nombre': 'Verde bosque'},
      {'hex': '#2E8B57', 'nombre': 'Verde mar'},
      {'hex': '#7FFF00', 'nombre': 'Chartreuse'},
      {'hex': '#7CFC00', 'nombre': 'Verde césped'},
      {'hex': '#ADFF2F', 'nombre': 'Verde amarillo'},
    ],
    'Azules': [
      {'hex': '#0000FF', 'nombre': 'Azul'},
      {'hex': '#0000CD', 'nombre': 'Azul medio'},
      {'hex': '#00008B', 'nombre': 'Azul oscuro'},
      {'hex': '#000080', 'nombre': 'Azul marino'},
      {'hex': '#191970', 'nombre': 'Azul medianoche'},
      {'hex': '#4169E1', 'nombre': 'Azul real'},
      {'hex': '#1E90FF', 'nombre': 'Azul dodger'},
      {'hex': '#00BFFF', 'nombre': 'Azul cielo profundo'},
      {'hex': '#87CEEB', 'nombre': 'Azul cielo'},
      {'hex': '#ADD8E6', 'nombre': 'Azul claro'},
      {'hex': '#B0C4DE', 'nombre': 'Azul acero claro'},
    ],
    'Púrpuras y Violetas': [
      {'hex': '#800080', 'nombre': 'Púrpura'},
      {'hex': '#8B008B', 'nombre': 'Magenta oscuro'},
      {'hex': '#9370DB', 'nombre': 'Púrpura medio'},
      {'hex': '#BA55D3', 'nombre': 'Orquídea medio'},
      {'hex': '#DA70D6', 'nombre': 'Orquídea'},
      {'hex': '#EE82EE', 'nombre': 'Violeta'},
      {'hex': '#FF00FF', 'nombre': 'Magenta'},
      {'hex': '#8A2BE2', 'nombre': 'Azul violeta'},
      {'hex': '#9400D3', 'nombre': 'Violeta oscuro'},
      {'hex': '#4B0082', 'nombre': 'Índigo'},
      {'hex': '#C71585', 'nombre': 'Medio púrpura violeta'},
    ],
    'Marrones': [
      {'hex': '#A52A2A', 'nombre': 'Marrón'},
      {'hex': '#8B4513', 'nombre': 'Marrón silla de montar'},
      {'hex': '#D2691E', 'nombre': 'Chocolate'},
      {'hex': '#CD853F', 'nombre': 'Marrón Perú'},
      {'hex': '#F4A460', 'nombre': 'Marrón arena'},
      {'hex': '#DEB887', 'nombre': 'Madera'},
      {'hex': '#D2B48C', 'nombre': 'Bronceado'},
      {'hex': '#F5DEB3', 'nombre': 'Trigo'},
      {'hex': '#800000', 'nombre': 'Marrón'},
    ],
    'Grises': [
      {'hex': '#808080', 'nombre': 'Gris'},
      {'hex': '#A9A9A9', 'nombre': 'Gris oscuro'},
      {'hex': '#C0C0C0', 'nombre': 'Plata'},
      {'hex': '#D3D3D3', 'nombre': 'Gris claro'},
      {'hex': '#DCDCDC', 'nombre': 'Gainsboro'},
      {'hex': '#696969', 'nombre': 'Gris tenue'},
      {'hex': '#708090', 'nombre': 'Gris pizarra'},
      {'hex': '#778899', 'nombre': 'Gris pizarra claro'},
      {'hex': '#2F4F4F', 'nombre': 'Gris pizarra oscuro'},
    ],
    'Cianes y Turquesas': [
      {'hex': '#00FFFF', 'nombre': 'Cyan'},
      {'hex': '#00FFFF', 'nombre': 'Aqua'},
      {'hex': '#00CED1', 'nombre': 'Turquesa oscuro'},
      {'hex': '#40E0D0', 'nombre': 'Turquesa'},
      {'hex': '#48D1CC', 'nombre': 'Turquesa medio'},
      {'hex': '#AFEEEE', 'nombre': 'Turquesa pálido'},
      {'hex': '#008080', 'nombre': 'Verde azulado'},
      {'hex': '#20B2AA', 'nombre': 'Verde mar claro'},
      {'hex': '#5F9EA0', 'nombre': 'Azul cadete'},
    ],
    'Blancos y Cremas': [
      {'hex': '#FFFFFF', 'nombre': 'Blanco'},
      {'hex': '#FFFAFA', 'nombre': 'Blanco nieve'},
      {'hex': '#F5FFFA', 'nombre': 'Crema de menta'},
      {'hex': '#F0F8FF', 'nombre': 'Azul Alicia'},
      {'hex': '#FFFFF0', 'nombre': 'Marfil'},
      {'hex': '#FFF5EE', 'nombre': 'Concha marina'},
      {'hex': '#FFEBCD', 'nombre': 'Almendra blanqueada'},
      {'hex': '#FFE4C4', 'nombre': 'Bisque'},
    ],
    'Negro': [
      {'hex': '#000000', 'nombre': 'Negro'},
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