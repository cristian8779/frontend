import 'package:flutter/material.dart';

class PantallaFiltros extends StatefulWidget {
  final Map<String, dynamic> filtrosDisponibles;
  final String? subcategoriaSeleccionada;
  final List<String> coloresSeleccionados;
  final List<String> tallasSeleccionadas;
  final double? precioMin;
  final double? precioMax;
  final Function(Map<String, dynamic>) onFiltrosChanged;

  const PantallaFiltros({
    Key? key,
    required this.filtrosDisponibles,
    this.subcategoriaSeleccionada,
    required this.coloresSeleccionados,
    required this.tallasSeleccionadas,
    this.precioMin,
    this.precioMax,
    required this.onFiltrosChanged,
  }) : super(key: key);

  @override
  State<PantallaFiltros> createState() => _PantallaFiltrosState();
}

class _PantallaFiltrosState extends State<PantallaFiltros> {
  late String? _subcategoriaSeleccionada;
  late List<String> _coloresSeleccionados;
  late List<String> _tallasSeleccionadas;
  late TextEditingController _precioMinController;
  late TextEditingController _precioMaxController;

  // Paleta de colores pastel
  static const Color _primaryPastel = Color(0xFFE8F4FD);
  static const Color _accentPastel = Color(0xFFF0F8E8);
  static const Color _rosePastel = Color(0xFFFDF2F8);
  static const Color _lavenderPastel = Color(0xFFF3F0FF);
  static const Color _peachPastel = Color(0xFFFFF7ED);

  @override
  void initState() {
    super.initState();
    _subcategoriaSeleccionada = widget.subcategoriaSeleccionada;
    _coloresSeleccionados = List.from(widget.coloresSeleccionados);
    _tallasSeleccionadas = List.from(widget.tallasSeleccionadas);

    _precioMinController = TextEditingController(
      text: widget.precioMin?.toString() ?? '',
    );
    _precioMaxController = TextEditingController(
      text: widget.precioMax?.toString() ?? '',
    );

    // DEBUG: Mostrar filtros disponibles al inicializar
    print('🔍 Filtros disponibles recibidos en PantallaFiltros: ${widget.filtrosDisponibles}');
  }

  @override
  void dispose() {
    _precioMinController.dispose();
    _precioMaxController.dispose();
    super.dispose();
  }

  void _aplicarFiltros() {
    double? min = _precioMinController.text.isNotEmpty
        ? double.tryParse(_precioMinController.text)
        : null;
    double? max = _precioMaxController.text.isNotEmpty
        ? double.tryParse(_precioMaxController.text)
        : null;

    if (min != null && max != null && min > max) {
      // Intercambiar si min > max
      final temp = min;
      min = max;
      max = temp;
    }

    // 🔥 CORREGIDO: No convertir a lowercase, mantener las tallas como están
    final filtros = {
      'subcategoria': _subcategoriaSeleccionada,
      'colores': _coloresSeleccionados.isNotEmpty ? _coloresSeleccionados : null,
      'tallas': _tallasSeleccionadas.isNotEmpty ? _tallasSeleccionadas : null, // Sin toLowerCase()
      'precioMin': min,
      'precioMax': max,
    };

    // DEBUG: Mostrar filtros que se van a enviar
    print('🔍 Filtros enviados desde PantallaFiltros:');
    print('  - Subcategoria: ${filtros['subcategoria']}');
    print('  - Colores: ${filtros['colores']}');
    print('  - Tallas: ${filtros['tallas']}');
    print('  - PrecioMin: ${filtros['precioMin']}');
    print('  - PrecioMax: ${filtros['precioMax']}');

    // Remover keys con valores null para limpiar el mapa
    filtros.removeWhere((key, value) => value == null);
    
    print('🔍 Filtros finales (después de remover nulls): $filtros');

    widget.onFiltrosChanged(filtros);
    Navigator.pop(context);
  }

  void _limpiarFiltros() {
    setState(() {
      _subcategoriaSeleccionada = null;
      _coloresSeleccionados.clear();
      _tallasSeleccionadas.clear();
      _precioMinController.clear();
      _precioMaxController.clear();
    });
    
    print('🔍 Filtros limpiados en PantallaFiltros');
  }

  Color _hexToColor(String hexString) {
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildSeccionSubcategoria(),
                    const SizedBox(height: 20),
                    _buildSeccionColores(),
                    const SizedBox(height: 20),
                    _buildSeccionTallas(),
                    const SizedBox(height: 20),
                    _buildSeccionPrecio(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
              _buildBotonesAccion(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'Filtros',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade800,
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: _limpiarFiltros,
            child: Text(
              'Limpiar todo',
              style: TextStyle(
                color: Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close_rounded,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeccionSubcategoria() {
    final subcategorias =
        widget.filtrosDisponibles['subcategorias'] as List<dynamic>? ?? [];

    if (subcategorias.isEmpty) return const SizedBox.shrink();

    print('🔍 Subcategorías disponibles: $subcategorias'); // DEBUG

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subcategoría',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: subcategorias.map<Widget>((subcategoria) {
            final subcategoriaStr = subcategoria.toString();
            final isSelected = _subcategoriaSeleccionada == subcategoriaStr;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _subcategoriaSeleccionada = isSelected ? null : subcategoriaStr;
                });
                print('🔍 Subcategoría seleccionada: $_subcategoriaSeleccionada');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accentPastel : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.green.shade300 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Text(
                  subcategoriaStr,
                  style: TextStyle(
                    color: isSelected ? Colors.green.shade600 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeccionColores() {
    final colores = widget.filtrosDisponibles['colores'] as List<dynamic>? ?? [];

    if (colores.isEmpty) return const SizedBox.shrink();

    print('🔍 Colores disponibles: $colores'); // DEBUG

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Colores',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colores.map<Widget>((colorItem) {
            String colorNombre;
            String? colorHex;

            if (colorItem is Map<String, dynamic>) {
              colorNombre = colorItem['nombre']?.toString() ?? '';
              colorHex = colorItem['hex']?.toString();
            } else {
              colorNombre = colorItem.toString();
            }

            final isSelected = _coloresSeleccionados.contains(colorNombre);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _coloresSeleccionados.remove(colorNombre);
                  } else {
                    _coloresSeleccionados.add(colorNombre);
                  }
                });
                print('🔍 Colores seleccionados: $_coloresSeleccionados');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _lavenderPastel : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? Colors.purple.shade300 : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (colorHex != null) ...[
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: _hexToColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (isSelected) ...[
                      Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Colors.purple.shade600,
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      colorNombre,
                      style: TextStyle(
                        color: isSelected ? Colors.purple.shade600 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSeccionTallas() {
    final tallasLetra = widget.filtrosDisponibles['tallasLetra'] as List<dynamic>? ?? [];
    final tallasNumero = widget.filtrosDisponibles['tallasNumero'] as List<dynamic>? ?? [];

    if (tallasLetra.isEmpty && tallasNumero.isEmpty) return const SizedBox.shrink();

    print('🔍 Tallas letra disponibles: $tallasLetra'); // DEBUG
    print('🔍 Tallas numero disponibles: $tallasNumero'); // DEBUG

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tallas',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 12),
        if (tallasLetra.isNotEmpty) ...[
          Text(
            'Tallas por letra',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tallasLetra.map<Widget>((talla) {
              final tallaStr = talla.toString();
              final isSelected = _tallasSeleccionadas.contains(tallaStr);
              return _buildTallaChip(tallaStr, isSelected);
            }).toList(),
          ),
        ],
        if (tallasLetra.isNotEmpty && tallasNumero.isNotEmpty)
          const SizedBox(height: 12),
        if (tallasNumero.isNotEmpty) ...[
          Text(
            'Tallas numéricas',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: tallasNumero.map<Widget>((talla) {
              final tallaStr = talla.toString();
              final isSelected = _tallasSeleccionadas.contains(tallaStr);
              return _buildTallaChip(tallaStr, isSelected);
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildTallaChip(String talla, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _tallasSeleccionadas.remove(talla);
          } else {
            _tallasSeleccionadas.add(talla);
          }
        });
        print('🔍 Tallas seleccionadas: $_tallasSeleccionadas');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _peachPastel : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.orange.shade300 : Colors.grey.shade300,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              Icon(
                Icons.check_circle_rounded,
                size: 16,
                color: Colors.orange.shade600,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              talla,
              style: TextStyle(
                color: isSelected ? Colors.orange.shade600 : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionPrecio() {
    final rangoPrecio = widget.filtrosDisponibles['rangoPrecioVariaciones']
            as Map<String, dynamic>? ??
        widget.filtrosDisponibles['rangoPrecio'] as Map<String, dynamic>?;

    print('🔍 Rango de precio disponible: $rangoPrecio'); // DEBUG

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rango de precio',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        if (rangoPrecio != null) ...[
          const SizedBox(height: 4),
          Text(
            'Rango disponible: \$${rangoPrecio['min']} - \$${rangoPrecio['max']}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _precioMinController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: rangoPrecio != null
                      ? rangoPrecio['min'].toString()
                      : 'Precio mín',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  print('🔍 Precio mínimo cambiado: $value');
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _precioMaxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: rangoPrecio != null
                      ? rangoPrecio['max'].toString()
                      : 'Precio máx',
                  prefixText: '\$ ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue.shade400),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onChanged: (value) {
                  print('🔍 Precio máximo cambiado: $value');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotonesAccion() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                print('🔍 Cancelando filtros');
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Text(
                'Cancelar',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _aplicarFiltros,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Aplicar filtros',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}