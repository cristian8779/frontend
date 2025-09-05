import 'package:flutter/material.dart';

class FiltrosPanel extends StatefulWidget {
  final Map<String, dynamic> filtros;
  final void Function(Map<String, List<String>> filtrosSeleccionados)? onAplicar;

  const FiltrosPanel({Key? key, required this.filtros, this.onAplicar}) : super(key: key);

  @override
  State<FiltrosPanel> createState() => _FiltrosPanelState();
}

class _FiltrosPanelState extends State<FiltrosPanel> {
  late List<String> subcategorias;
  late List<String> tallasLetra;
  late List<Map<String, dynamic>> colores;
  late Map<String, dynamic> rangoPrecio;

  final Map<String, List<String>> seleccion = {
    'subcategorias': [],
    'tallasLetra': [],
    'colores': [],
  };

  @override
  void initState() {
    super.initState();
    subcategorias = List<String>.from(widget.filtros["subcategorias"] ?? []);
    tallasLetra = List<String>.from(widget.filtros["tallasLetra"] ?? []);
    colores = List<Map<String, dynamic>>.from(widget.filtros["colores"] ?? []);
    rangoPrecio = widget.filtros["rangoPrecio"] != null
        ? Map<String, dynamic>.from(widget.filtros["rangoPrecio"])
        : <String, dynamic>{};
  }

  void _toggleSeleccion(String key, String valor) {
    setState(() {
      if (seleccion[key]!.contains(valor)) {
        seleccion[key]!.remove(valor);
      } else {
        seleccion[key]!.add(valor);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subcategorias.isNotEmpty) _buildChips("Subcategorías", subcategorias, "subcategorias"),
                  if (tallasLetra.isNotEmpty) _buildChips("Tallas", tallasLetra, "tallasLetra"),
                  if (colores.isNotEmpty) _buildColores(colores),
                  if (rangoPrecio.isNotEmpty) _buildRangoPrecio(rangoPrecio),
                ],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (widget.onAplicar != null) widget.onAplicar!(seleccion);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.amber.shade700,
            ),
            child: const Text("Aplicar filtros", style: TextStyle(fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildChips(String titulo, List<String> items, String key) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: items.map((e) {
            final activo = seleccion[key]!.contains(e);
            return ChoiceChip(
              label: Text(e),
              selected: activo,
              onSelected: (_) => _toggleSeleccion(key, e),
              selectedColor: Colors.amber.shade700,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildColores(List<Map<String, dynamic>> colores) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Colores", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: colores.map((c) {
            final hex = c["hex"] ?? "#FFFFFF";
            final nombre = c["nombre"] ?? "Desconocido";
            Color color;
            try {
              color = Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
            } catch (_) {
              color = Colors.grey;
            }
            final activo = seleccion["colores"]!.contains(nombre);
            return ChoiceChip(
              avatar: CircleAvatar(backgroundColor: color),
              label: Text(nombre),
              selected: activo,
              selectedColor: Colors.amber.shade700,
              onSelected: (_) => _toggleSeleccion("colores", nombre),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRangoPrecio(Map<String, dynamic> rango) {
    final min = rango["min"] ?? 0;
    final max = rango["max"] ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Rango de Precio", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text("\$$min - \$$max", style: const TextStyle(fontSize: 14)),
        const SizedBox(height: 16),
      ],
    );
  }
}
