import 'package:flutter/material.dart';
import '/utils/colores.dart';

class ColorSelector extends StatelessWidget {
  final List<Map<String, String>>? coloresDisponibles;
  final List<String> coloresSeleccionados;
  final Function(List<String>) onSelectionChanged;
  final Map<String, List<Map<String, String>>>? coloresAgrupados;
  final bool multiSelection; // Nuevo parámetro añadido

  ColorSelector({
    super.key,
    this.coloresDisponibles,
    required this.coloresSeleccionados,
    required this.onSelectionChanged,
    this.coloresAgrupados,
    this.multiSelection = false, // Valor por defecto: selección única
  }) : assert(
          coloresDisponibles != null ||
              (coloresAgrupados != null && coloresAgrupados.isNotEmpty),
          'Debe proporcionar coloresDisponibles o coloresAgrupados',
        );

  @override
  Widget build(BuildContext context) {
    // Unifica todos los colores en una sola lista
    final todosLosColores = coloresAgrupados != null
        ? coloresAgrupados!.values.expand((lista) => lista).toList()
        : coloresDisponibles ?? [];

    return _buildColorScroll(todosLosColores);
  }

  Widget _buildColorScroll(List<Map<String, String>> colores) {
    return SizedBox(
      height: 80,
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black,
              Colors.black,
              Colors.transparent,
            ],
            stops: [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: colores.map((colorData) {
              final hex = colorData['hex']!;
              final nombre = colorData['nombre']!;
              final color = Colores.hexToColor(hex);
              final seleccionado = coloresSeleccionados.contains(hex);
              final isDark = ThemeData.estimateBrightnessForColor(color) == Brightness.dark;

              return GestureDetector(
                onTap: () {
                  final nuevosSeleccionados = List<String>.from(coloresSeleccionados);
                  if (multiSelection) {
                    // Modo selección múltiple
                    if (seleccionado) {
                      nuevosSeleccionados.remove(hex);
                    } else {
                      nuevosSeleccionados.add(hex);
                    }
                  } else {
                    // Modo selección única
                    if (seleccionado) {
                      nuevosSeleccionados.clear();
                    } else {
                      nuevosSeleccionados.clear();
                      nuevosSeleccionados.add(hex);
                    }
                  }
                  onSelectionChanged(nuevosSeleccionados);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: const Offset(1, 2),
                            ),
                          ],
                          border: Border.all(
                            color: seleccionado ? Colors.brown.shade800 : Colors.grey.shade300,
                            width: seleccionado ? 3 : 1,
                          ),
                        ),
                        child: seleccionado
                            ? Icon(Icons.check, size: 20, color: isDark ? Colors.white : Colors.black)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nombre,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: seleccionado ? FontWeight.bold : FontWeight.normal,
                          color: seleccionado ? Colors.brown.shade800 : Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}