import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colores.dart';
import '../../widgets/color_selector.dart';
import '../../widgets/selector_talla_widget.dart';
import '../../models/variacion.dart';
import '../../services/variacion_service.dart';

class CrearVariacionScreen extends StatefulWidget {
  final String productId;

  const CrearVariacionScreen({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  State<CrearVariacionScreen> createState() => _CrearVariacionScreenState();
}

class _CrearVariacionScreenState extends State<CrearVariacionScreen> {
  final VariacionService _variacionService = VariacionService();
  final _formKey = GlobalKey<FormState>();

  // Modo de creación: individual o por lotes
  bool _modoLotes = false;

  // Selecciones múltiples para modo lotes
  List<String> _coloresSeleccionados = [];
  List<String> _tallasSeleccionadas = [];
  Map<String, String> _coloresNombres = {};

  // Selecciones individuales (modo individual)
  String? _selectedColorHex;
  String? _selectedColorName;
  String? _tallaLetra;
  String? _tallaNumero;

  // Imágenes
  File? _imagenPrincipal;
  Map<String, File> _imagenesPorColor = {};
  final ImagePicker _picker = ImagePicker();

  // Controladores de texto
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  Map<String, TextEditingController> _stockControllersPorVariacion = {};
  Map<String, TextEditingController> _precioControllersPorVariacion = {};

  bool _isLoading = false;
  String _currencySymbol = '\$'; // Símbolo para pesos colombianos (COP)
  double _saveProgress = 0.0; // Progreso para el diálogo de guardado

  @override
  void initState() {
    super.initState();
    _stockController.addListener(_validateForm);
    _precioController.addListener(_validateForm);
  }

  @override
  void dispose() {
    _stockController.dispose();
    _precioController.dispose();
    for (var ctrl in _stockControllersPorVariacion.values) {
      ctrl.dispose();
    }
    for (var ctrl in _precioControllersPorVariacion.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _cambiarModo(bool esLotes) {
    setState(() {
      _modoLotes = esLotes;
      _limpiarSelecciones();
    });
  }

  void _limpiarSelecciones() {
    setState(() {
      _coloresSeleccionados.clear();
      _tallasSeleccionadas.clear();
      _coloresNombres.clear();
      _selectedColorHex = null;
      _selectedColorName = null;
      _tallaLetra = null;
      _tallaNumero = null;
      _stockController.clear();
      _precioController.clear();
      _imagenPrincipal = null;
      _imagenesPorColor.clear();
      _stockControllersPorVariacion.clear();
      _precioControllersPorVariacion.clear();
    });
    _formKey.currentState?.reset();
  }

  Future<void> _seleccionarImagen([String? colorHex]) async {
    if (_isLoading) return;

    try {
      final pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        final imageFile = File(pickedFile.path);
        final imageSize = await imageFile.length();

        if (imageSize > 5 * 1024 * 1024) {
          _mostrarMensaje('La imagen no puede superar los 5MB.', isError: true);
          return;
        }

        setState(() {
          if (_modoLotes && colorHex != null) {
            _imagenesPorColor[colorHex] = imageFile;
          } else {
            _imagenPrincipal = imageFile;
          }
        });
      }
    } catch (e) {
      _mostrarMensaje('Error al seleccionar la imagen: $e', isError: true);
    }
  }

  void _mostrarMensaje(String mensaje, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String? _validarStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'El stock es requerido';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock <= 0) {
      return 'Ingresa un stock válido';
    }
    return null;
  }

  String? _validarPrecio(String? value) {
    if (value == null || value.isEmpty) {
      return 'El precio es requerido';
    }
    final precio = double.tryParse(value.replaceAll(',', '.'));
    if (precio == null || precio <= 0) {
      return 'Ingresa un precio válido';
    }
    return null;
  }

  String _getVariacionKey(String colorHex, String talla) {
    return '${colorHex}_$talla';
  }

  void _actualizarControllers() {
    List<String> newKeys = [];
    for (var colorHex in _coloresSeleccionados) {
      for (var talla in _tallasSeleccionadas) {
        final key = _getVariacionKey(colorHex, talla);
        newKeys.add(key);
        _stockControllersPorVariacion.putIfAbsent(
          key,
          () => TextEditingController()..addListener(_validateForm),
        );
        _precioControllersPorVariacion.putIfAbsent(
          key,
          () => TextEditingController()..addListener(_validateForm),
        );
      }
    }

    var keysToRemove = _stockControllersPorVariacion.keys
        .where((k) => !newKeys.contains(k))
        .toList();
    for (var key in keysToRemove) {
      _stockControllersPorVariacion[key]?.dispose();
      _stockControllersPorVariacion.remove(key);
    }

    keysToRemove = _precioControllersPorVariacion.keys
        .where((k) => !newKeys.contains(k))
        .toList();
    for (var key in keysToRemove) {
      _precioControllersPorVariacion[key]?.dispose();
      _precioControllersPorVariacion.remove(key);
    }
  }

  bool _isFormValid() {
    if (_modoLotes) {
      for (var colorHex in _coloresSeleccionados) {
        for (var talla in _tallasSeleccionadas) {
          final key = _getVariacionKey(colorHex, talla);
          final stockController = _stockControllersPorVariacion[key];
          final precioController = _precioControllersPorVariacion[key];
          if (stockController == null || precioController == null) return false;
          final stockValid = _validarStock(stockController.text) == null;
          final precioValid = _validarPrecio(precioController.text) == null;
          if (!stockValid || !precioValid) return false;
        }
      }
      return _coloresSeleccionados.isNotEmpty && _tallasSeleccionadas.isNotEmpty;
    } else {
      return _formKey.currentState != null &&
          _formKey.currentState!.validate() &&
          _selectedColorHex != null &&
          (_tallaLetra != null || _tallaNumero != null) &&
          _imagenPrincipal != null;
    }
  }

  void _validateForm() {
    setState(() {}); // Actualizar UI para reflejar estado del botón de guardar
  }

  List<Variacion> _generarVariacionesLote() {
    List<Variacion> variaciones = [];

    for (String colorHex in _coloresSeleccionados) {
      for (String talla in _tallasSeleccionadas) {
        final key = _getVariacionKey(colorHex, talla);
        final stockText = _stockControllersPorVariacion[key]?.text.trim();
        final precioText =
            _precioControllersPorVariacion[key]?.text.trim().replaceAll(',', '.');

        if (stockText == null || stockText.isEmpty || precioText == null || precioText.isEmpty) {
          continue;
        }

        final stock = int.parse(stockText);
        final precio = double.parse(precioText).toStringAsFixed(2);
        final esNumerico = RegExp(r'^\d+$').hasMatch(talla);
        final imagenColor = _imagenesPorColor[colorHex] ?? _imagenPrincipal;

        if (imagenColor == null) continue;

        final variacion = Variacion(
          productoId: widget.productId,
          colorHex: colorHex,
          colorNombre: _coloresNombres[colorHex] ?? '',
          tallaLetra: esNumerico ? null : talla,
          tallaNumero: esNumerico ? talla : null,
          stock: stock,
          precio: double.parse(precio),
          imagenes: [
            ImagenVariacion(isLocal: true, localFile: imagenColor),
          ],
        );

        variaciones.add(variacion);
      }
    }

    return variaciones;
  }

  Future<void> _guardarVariaciones() async {
    if (!_isFormValid()) {
      _mostrarMensaje('Por favor, completa todos los campos requeridos.', isError: true);
      return;
    }

    if (_modoLotes) {
      await _guardarVariacionesLote();
    } else {
      await _guardarVariacionIndividual();
    }
  }

  Future<void> _guardarVariacionesLote() async {
    if (_coloresSeleccionados.isEmpty) {
      _mostrarMensaje('Selecciona al menos un color.', isError: true);
      return;
    }
    if (_tallasSeleccionadas.isEmpty) {
      _mostrarMensaje('Selecciona al menos una talla.', isError: true);
      return;
    }

    final variacionesSinImagen =
        _coloresSeleccionados.where((colorHex) => !_imagenesPorColor.containsKey(colorHex)).toList();
    if (variacionesSinImagen.isNotEmpty && _imagenPrincipal == null) {
      _mostrarMensaje('Faltan imágenes para algunos colores y no hay imagen principal.',
          isError: true);
      return;
    }

    final variaciones = _generarVariacionesLote();
    if (variaciones.isEmpty) {
      _mostrarMensaje('No se pueden generar variaciones sin datos completos.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final confirmar = await _mostrarPreviewLotes(variaciones);
      if (!confirmar) {
        setState(() => _isLoading = false);
        return;
      }

      // Mostrar diálogo de progreso
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Guardando variaciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _saveProgress),
              const SizedBox(height: 16),
              Text('Guardando ${_saveProgress * variaciones.length ~/ 1}/${variaciones.length}...'),
            ],
          ),
        ),
      );

      List<String> errores = [];
      for (var i = 0; i < variaciones.length; i++) {
        try {
          await _variacionService.crearVariacionDesdeModelo(variaciones[i]);
          setState(() => _saveProgress = (i + 1) / variaciones.length);
        } catch (e) {
          errores.add(
              'Error al guardar ${variaciones[i].colorNombre} - Talla ${variaciones[i].tallaLetra ?? variaciones[i].tallaNumero}: $e');
        }
      }

      Navigator.pop(context); // Cerrar diálogo de progreso

      if (errores.isNotEmpty) {
        _mostrarMensaje('Algunas variaciones no se guardaron: ${errores.join(', ')}',
            isError: true);
      } else {
        _mostrarMensaje('${variaciones.length} variaciones creadas exitosamente');
      }
      _resetForm();
    } catch (e) {
      _mostrarMensaje('Error general al guardar variaciones: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarVariacionIndividual() async {
    final stock = int.parse(_stockController.text.trim());
    final precio = double.parse(_precioController.text.trim().replaceAll(',', '.')).toStringAsFixed(2);

    final variacion = Variacion(
      productoId: widget.productId,
      colorHex: _selectedColorHex!,
      colorNombre: _selectedColorName ?? '',
      tallaLetra: _tallaLetra,
      tallaNumero: _tallaNumero,
      stock: stock,
      precio: double.parse(precio),
      imagenes: [
        ImagenVariacion(isLocal: true, localFile: _imagenPrincipal),
      ],
    );

    setState(() => _isLoading = true);

    try {
      await _variacionService.crearVariacionDesdeModelo(variacion);
      _mostrarMensaje('Variación creada exitosamente');
      _resetForm();
    } catch (e) {
      _mostrarMensaje('Error al guardar variación: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _mostrarPreviewLotes(List<Variacion> variaciones) async {
    final variacionesConImagenPrincipal =
        variaciones.where((v) => !_imagenesPorColor.containsKey(v.colorHex)).toList();

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar creación por lotes'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Se crearán ${variaciones.length} variaciones:'),
                  const SizedBox(height: 12),
                  Text('• ${_coloresSeleccionados.length} colores'),
                  Text('• ${_tallasSeleccionadas.length} tallas'),
                  if (variacionesConImagenPrincipal.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Nota: ${variacionesConImagenPrincipal.length} variaciones usarán la imagen principal.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Text('Detalles:'),
                  ...variaciones.map((v) => Text(
                        '• ${v.colorNombre} - Talla ${v.tallaLetra ?? v.tallaNumero}: ${v.stock} unidades, $_currencySymbol${v.precio}',
                        style: const TextStyle(fontSize: 12),
                      )),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _resetForm() {
    setState(() {
      _coloresSeleccionados.clear();
      _tallasSeleccionadas.clear();
      _coloresNombres.clear();
      _selectedColorHex = null;
      _selectedColorName = null;
      _tallaLetra = null;
      _tallaNumero = null;
      _stockController.clear();
      _precioController.clear();
      _imagenPrincipal = null;
      _imagenesPorColor.clear();
      _stockControllersPorVariacion.clear();
      _precioControllersPorVariacion.clear();
      _saveProgress = 0.0;
    });
    _formKey.currentState?.reset();
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _cambiarModo(false),
              child: Semantics(
                label: 'Seleccionar modo individual',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_modoLotes ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: !_modoLotes
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    'Individual',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: !_modoLotes ? const Color(0xFF3A86FF) : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _cambiarModo(true),
              child: Semantics(
                label: 'Seleccionar modo por lotes',
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _modoLotes ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: _modoLotes
                        ? [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Text(
                    'Por lotes',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _modoLotes ? const Color(0xFF3A86FF) : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: const Color(0xFF3A86FF)),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required TextInputType inputType,
    String? Function(String?)? validator,
    String? prefix,
    String? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      inputFormatters: inputType == const TextInputType.numberWithOptions(decimal: true)
          ? [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*[,.]?\d{0,2}')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text.isEmpty) return newValue;
                final parsed = double.tryParse(newValue.text.replaceAll(',', '.'));
                if (parsed == null) return oldValue;
                return newValue.copyWith(text: parsed.toStringAsFixed(2));
              }),
            ]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        suffixText: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3A86FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
      ),
    );
  }

  Widget _buildImageSelector() {
    if (_modoLotes) {
      return _buildImageSelectorLotes();
    } else {
      return _buildImageSelectorIndividual();
    }
  }

  Widget _buildImageSelectorIndividual() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imagen del producto', icon: Icons.image_outlined),
          GestureDetector(
            onTap: () => _seleccionarImagen(),
            child: Semantics(
              label: 'Seleccionar imagen del producto',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _imagenPrincipal != null ? const Color(0xFF3A86FF) : Colors.grey.shade300,
                    width: _imagenPrincipal != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _imagenPrincipal != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _imagenPrincipal!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A86FF).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: Color(0xFF3A86FF),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Toca para seleccionar imagen',
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Máximo 5MB',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelectorLotes() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imágenes por color', icon: Icons.image_outlined),
          GestureDetector(
            onTap: () => _seleccionarImagen(),
            child: Semantics(
              label: 'Seleccionar imagen principal',
              child: Container(
                height: 120,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _imagenPrincipal != null ? const Color(0xFF3A86FF) : Colors.grey.shade300,
                  ),
                ),
                child: _imagenPrincipal != null
                    ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              bottomLeft: Radius.circular(11),
                            ),
                            child: Image.file(
                              _imagenPrincipal!,
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Imagen principal',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Se usará para colores sin imagen específica',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Imagen principal (opcional)',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          if (_coloresSeleccionados.isNotEmpty) ...[
            const Text(
              'Imágenes por color específico:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: _coloresSeleccionados.length,
              itemBuilder: (context, index) {
                final colorHex = _coloresSeleccionados[index];
                final colorName = _coloresNombres[colorHex] ?? 'Sin nombre';
                final tieneImagen = _imagenesPorColor.containsKey(colorHex);

                return GestureDetector(
                  onTap: () => _seleccionarImagen(colorHex),
                  child: Semantics(
                    label: 'Seleccionar imagen para color $colorName',
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: tieneImagen ? const Color(0xFF3A86FF) : Colors.grey.shade300,
                        ),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: tieneImagen
                                ? ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                    child: Image.file(
                                      _imagenesPorColor[colorHex]!,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        Icons.add_photo_alternate_outlined,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    colorName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildColorPreview() {
    if (_modoLotes) {
      if (_coloresSeleccionados.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A86FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A86FF).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colores seleccionados (${_coloresSeleccionados.length}):',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coloresSeleccionados.map((colorHex) {
                final colorName = _coloresNombres[colorHex] ?? 'Sin nombre';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        colorName,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      if (_selectedColorHex == null) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A86FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A86FF).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${_selectedColorHex!.substring(1)}')),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Color: ${_selectedColorName ?? 'Sin nombre'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF2D3748),
                ),
              ),
            ),
            Icon(
              Icons.check_circle,
              color: const Color(0xFF3A86FF),
              size: 16,
            ),
          ],
        ),
      );
    }
  }

  Widget _buildTallaPreview() {
    if (_modoLotes) {
      if (_tallasSeleccionadas.isEmpty) return const SizedBox.shrink();

      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A86FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF3A86FF).withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tallas seleccionadas (${_tallasSeleccionadas.length}):',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tallasSeleccionadas.map((talla) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    talla,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else {
      if (_tallaLetra != null || _tallaNumero != null) {
        return Container(
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3A86FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3A86FF).withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Talla: ${_tallaLetra ?? _tallaNumero ?? 'Sin talla'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
              ),
              Icon(
                Icons.check_circle,
                color: const Color(0xFF3A86FF),
                size: 16,
              ),
            ],
          ),
        );
      }
      return const SizedBox.shrink();
    }
  }

  Widget _buildResumenLotes() {
    if (!_modoLotes || _coloresSeleccionados.isEmpty || _tallasSeleccionadas.isEmpty) {
      return const SizedBox.shrink();
    }

    final totalVariaciones = _coloresSeleccionados.length * _tallasSeleccionadas.length;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange.shade600,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se crearán $totalVariaciones variaciones',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${_coloresSeleccionados.length} colores × ${_tallasSeleccionadas.length} tallas',
                  style: TextStyle(
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    String buttonText;
    if (_modoLotes) {
      final totalVariaciones = _coloresSeleccionados.length * _tallasSeleccionadas.length;
      buttonText = totalVariaciones > 0 ? 'Crear $totalVariaciones Variaciones' : 'Crear Variaciones';
    } else {
      buttonText = 'Crear Variación';
    }

    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid() ? null : _guardarVariaciones,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3A86FF),
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          elevation: _isLoading ? 0 : 2,
          shadowColor: const Color(0xFF3A86FF).withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Guardando...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modoLotes ? Icons.save_alt_outlined : Icons.save_outlined,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        onPressed: _isLoading ? null : _resetForm,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.grey.shade400),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.clear,
              size: 20,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              'Limpiar formulario',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFC),
      appBar: AppBar(
        title: const Text(
          'Crear Variaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF2D3748),
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade200,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeToggle(),
              _buildSectionTitle('Color${_modoLotes ? 'es' : ''}', icon: Icons.palette_outlined),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    ColorSelector(
                      coloresSeleccionados: _modoLotes
                          ? _coloresSeleccionados
                          : (_selectedColorHex != null ? [_selectedColorHex!] : []),
                      onSelectionChanged: (seleccionados) {
                        setState(() {
                          if (_modoLotes) {
                            _coloresSeleccionados = seleccionados;
                            _coloresNombres.clear();
                            for (String colorHex in seleccionados) {
                              _coloresNombres[colorHex] = Colores.getNombreColor(colorHex);
                            }
                          } else {
                            _selectedColorHex = seleccionados.isNotEmpty ? seleccionados.first : null;
                            _selectedColorName =
                                _selectedColorHex != null ? Colores.getNombreColor(_selectedColorHex!) : null;
                          }
                          _actualizarControllers();
                        });
                      },
                      coloresAgrupados: Colores.coloresAgrupados,
                      multiSelection: _modoLotes,
                    ),
                    _buildColorPreview(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Talla${_modoLotes ? 's' : ''}', icon: Icons.straighten_outlined),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    SelectorTalla(
                      onSeleccion: (List<String> seleccionados) {
                        setState(() {
                          if (_modoLotes) {
                            _tallasSeleccionadas = seleccionados;
                          } else {
                            _tallaLetra = null;
                            _tallaNumero = null;
                            if (seleccionados.isNotEmpty) {
                              String valor = seleccionados.first;
                              if (RegExp(r'^\d+$').hasMatch(valor)) {
                                _tallaNumero = valor;
                              } else {
                                _tallaLetra = valor;
                              }
                            }
                          }
                          _actualizarControllers();
                        });
                      },
                      multiSelection: _modoLotes,
                      tallasSeleccionadas: _modoLotes
                          ? _tallasSeleccionadas
                          : (_tallaNumero != null
                              ? [_tallaNumero!]
                              : _tallaLetra != null
                                  ? [_tallaLetra!]
                                  : []),
                    ),
                    _buildTallaPreview(),
                  ],
                ),
              ),
              _buildResumenLotes(),
              const SizedBox(height: 24),
              _buildSectionTitle('Inventario y Precio', icon: Icons.inventory_outlined),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (!_modoLotes) ...[
                      _buildTextField(
                        label: 'Stock disponible',
                        controller: _stockController,
                        inputType: TextInputType.number,
                        validator: _validarStock,
                        suffix: 'unidades',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        label: 'Precio',
                        controller: _precioController,
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        validator: _validarPrecio,
                        prefix: _currencySymbol,
                      ),
                    ] else ...[
                      if (_coloresSeleccionados.isEmpty || _tallasSeleccionadas.isEmpty)
                        const Text(
                          'Selecciona colores y tallas para configurar el inventario y precio de cada variación.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else ...[
                        ..._coloresSeleccionados.map((colorHex) {
                          final colorName = _coloresNombres[colorHex] ?? 'Sin nombre';
                          return ExpansionTile(
                            title: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  colorName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            children: _tallasSeleccionadas.map((talla) {
                              final key = _getVariacionKey(colorHex, talla);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text('Talla $talla'),
                                    ),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Stock',
                                        controller: _stockControllersPorVariacion[key]!,
                                        inputType: TextInputType.number,
                                        validator: _validarStock,
                                        suffix: null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Precio',
                                        controller: _precioControllersPorVariacion[key]!,
                                        inputType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: _validarPrecio,
                                        prefix: _currencySymbol,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        }),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildImageSelector(),
              const SizedBox(height: 32),
              _buildSaveButton(),
              _buildClearButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}