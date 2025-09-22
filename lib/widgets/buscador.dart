import 'package:flutter/material.dart';

class BuscadorProductos extends StatelessWidget {
  final String busqueda;
  final ValueChanged<String> onBusquedaChanged;
  final VoidCallback? onTap; // ✅ opcional
  final VoidCallback? onClear; // ✅ opcional
  final TextEditingController controller;

  const BuscadorProductos({
    Key? key,
    required this.busqueda,
    required this.onBusquedaChanged,
    this.onTap,
    this.onClear,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final tieneTexto = controller.text.isNotEmpty;

    return Container(
      height: 40, // 🔥 más delgado
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // 🔥 bordes más compactos
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        autofocus: false,
        onTap: () {
          debugPrint("[BuscadorProductos] onTap disparado");
          onTap?.call();
        },
        onChanged: (value) {
          debugPrint("[BuscadorProductos] onChanged: '$value'");
          onBusquedaChanged(value);
        },
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search,
              color: Colors.amber.shade700, size: 22), // 🔥 ícono más pequeño
          hintText: 'Buscar productos',
          hintStyle: TextStyle(
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w400,
            fontSize: 14, // 🔥 texto más pequeño
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.only(top: 8), // 🔥 ajusta altura
          suffixIcon: tieneTexto && onClear != null
              ? GestureDetector(
                  onTap: () {
                    debugPrint("[BuscadorProductos] onClear disparado");
                    controller.clear();
                    onClear?.call();
                    onBusquedaChanged('');
                  },
                  child: Icon(Icons.clear,
                      color: Colors.grey.shade500, size: 18), // 🔥 más pequeño
                )
              : null,
        ),
        style: const TextStyle(fontSize: 14), // 🔥 fuente más compacta
        cursorColor: Colors.amber.shade700,
      ),
    );
  }
}
