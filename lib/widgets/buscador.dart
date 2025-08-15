import 'package:flutter/material.dart';

class BuscadorProductos extends StatelessWidget {
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const BuscadorProductos({
    Key? key,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onTap,
    this.onClear,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool tieneTexto = busqueda.isNotEmpty;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: Colors.amber.shade700, size: 26),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onTap: onTap,
              onChanged: onBusquedaChanged,
              controller: TextEditingController(text: busqueda),
              decoration: InputDecoration(
                hintText: 'Buscar productos, marcas y más...',
                hintStyle: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 16),
              cursorColor: Colors.amber.shade700,
            ),
          ),
          if (tieneTexto && onClear != null)
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
            ),
        ],
      ),
    );
  }
}
