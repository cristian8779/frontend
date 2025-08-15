import 'package:flutter/material.dart';

class BuscadorProductos extends StatelessWidget {
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final VoidCallback onTap;

  const BuscadorProductos({
    Key? key,
    required this.busqueda,
    required this.onBusquedaChanged,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        onTap: onTap,
        onChanged: onBusquedaChanged,
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Busca un producto',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
