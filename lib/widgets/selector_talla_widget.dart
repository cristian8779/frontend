import 'package:flutter/material.dart';

class SelectorTalla extends StatefulWidget {
  final void Function(List<String>) onSeleccion; // Cambiado a List<String>
  final bool multiSelection; // Nuevo parámetro
  final List<String> tallasSeleccionadas; // Nueva lista para las tallas seleccionadas

  const SelectorTalla({
    Key? key,
    required this.onSeleccion,
    this.multiSelection = false, // Por defecto, selección única
    required this.tallasSeleccionadas, // Lista inicial de tallas seleccionadas
  }) : super(key: key);

  @override
  State<SelectorTalla> createState() => _SelectorTallaState();
}

class _SelectorTallaState extends State<SelectorTalla> {
  String tipoSeleccionado = 'numerica';

  // Adulto - Numéricas (sin ordenar)
  final List<String> tallasNumericas = [
    '28', '29', '30', '31', '32', '33', '34', '35',
    '36', '37', '38', '39', '40', '41', '42', '43', '44', '45'
  ];

  // Adulto - Letras
  final List<String> tallasLetra = [
    'XXXS', 'XXS', 'XS', 'S', 'M', 'L', 'XL', 'XXL', 'XXXL', 'XXXXL'
  ];

  // Getter que devuelve las tallas numéricas ordenadas al vuelo
  List<String> get tallasNumericasOrdenadas {
    final sorted = List<String>.from(tallasNumericas);
    sorted.sort((a, b) => int.parse(a).compareTo(int.parse(b)));
    return sorted;
  }

  List<String> get tallasActuales =>
      tipoSeleccionado == 'numerica' ? tallasNumericasOrdenadas : tallasLetra;

  void cambiarTipo(String tipo) {
    if (tipoSeleccionado == tipo) return; // Evitar rebuilds inútiles

    setState(() {
      tipoSeleccionado = tipo;
      // Limpiar las selecciones al cambiar de tipo
      widget.onSeleccion([]);
    });
  }

  void seleccionarTalla(String talla) {
    final nuevosSeleccionados = List<String>.from(widget.tallasSeleccionadas);

    if (widget.multiSelection) {
      // Modo selección múltiple
      if (nuevosSeleccionados.contains(talla)) {
        nuevosSeleccionados.remove(talla);
      } else {
        nuevosSeleccionados.add(talla);
      }
    } else {
      // Modo selección única
      if (nuevosSeleccionados.contains(talla)) {
        nuevosSeleccionados.clear();
      } else {
        nuevosSeleccionados.clear();
        nuevosSeleccionados.add(talla);
      }
    }

    setState(() {
      // Actualizamos el estado para reflejar los cambios en la UI
    });
    widget.onSeleccion(nuevosSeleccionados);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Talla:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Numérica'),
              selected: tipoSeleccionado == 'numerica',
              onSelected: (_) => cambiarTipo('numerica'),
            ),
            ChoiceChip(
              label: const Text('Letra'),
              selected: tipoSeleccionado == 'letra',
              onSelected: (_) => cambiarTipo('letra'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tallasActuales.map((talla) {
            return ChoiceChip(
              label: Text(talla),
              selected: widget.tallasSeleccionadas.contains(talla),
              onSelected: (_) => seleccionarTalla(talla),
            );
          }).toList(),
        ),
      ],
    );
  }
}