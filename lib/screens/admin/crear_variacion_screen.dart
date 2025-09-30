import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../utils/colores.dart';
import '../../widgets/color_selector.dart';
import '../../widgets/selector_talla_widget.dart';
import '../../models/variacion.dart';
import '../../providers/variacion_admin_provider.dart';
import 'styles/crear_variacion/crear_variacion_styles.dart';

// Formatteador para precios en COP
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    String numbersOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    final number = int.tryParse(numbersOnly);
    if (number == null) {
      return oldValue;
    }

    String formatted = _formatWithThousands(numbersOnly);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithThousands(String number) {
    String reversed = number.split('').reversed.join('');
    String formatted = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        formatted += '.';
      }
      formatted += reversed[i];
    }
    
    return formatted.split('').reversed.join('');
  }
}

// Función auxiliar para convertir el texto formateado de vuelta a número
int parseCurrency(String formattedText) {
  return int.tryParse(formattedText.replaceAll('.', '')) ?? 0;
}

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
  String _currencySymbol = '\$';
  double _saveProgress = 0.0;

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
              size: CrearVariacionStyles.infoIconSize,
            ),
            CrearVariacionStyles.smallHorizontalSpacing,
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
    
    final precio = parseCurrency(value);
    if (precio <= 0) {
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
        if (!_imagenesPorColor.containsKey(colorHex)) {
          return false;
        }
      }
      
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
    setState(() {});
  }

  List<Variacion> _generarVariacionesLote() {
    List<Variacion> variaciones = [];

    for (String colorHex in _coloresSeleccionados) {
      for (String talla in _tallasSeleccionadas) {
        final key = _getVariacionKey(colorHex, talla);
        final stockText = _stockControllersPorVariacion[key]?.text.trim();
        final precioText = _precioControllersPorVariacion[key]?.text.trim();

        if (stockText == null || stockText.isEmpty || precioText == null || precioText.isEmpty) {
          continue;
        }

        final stock = int.parse(stockText);
        final precioValue = parseCurrency(precioText);
        final precio = precioValue.toStringAsFixed(2);
        final esNumerico = RegExp(r'^\d+$').hasMatch(talla);
        final imagenColor = _imagenesPorColor[colorHex];

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

    final coloresSinImagen = _coloresSeleccionados.where((colorHex) => !_imagenesPorColor.containsKey(colorHex)).toList();
    if (coloresSinImagen.isNotEmpty) {
      final coloresNombres = coloresSinImagen.map((color) => _coloresNombres[color] ?? 'Sin nombre').join(', ');
      _mostrarMensaje('Faltan imágenes para los colores: $coloresNombres', isError: true);
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

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Guardando variaciones'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: _saveProgress),
              CrearVariacionStyles.mediumSpacing,
              Text('Guardando ${(_saveProgress * variaciones.length).toInt()}/${variaciones.length}...'),
            ],
          ),
        ),
      );

      final provider = Provider.of<VariacionProvider>(context, listen: false);
      List<String> errores = [];
      
      for (var i = 0; i < variaciones.length; i++) {
        final exito = await provider.crearVariacion(variaciones[i]);
        if (!exito) {
          errores.add(
            'Error al guardar ${variaciones[i].colorNombre} - Talla ${variaciones[i].tallaLetra ?? variaciones[i].tallaNumero}');
        }
        setState(() => _saveProgress = (i + 1) / variaciones.length);
      }

      Navigator.pop(context);

      if (errores.isNotEmpty) {
        _mostrarMensaje('Algunas variaciones no se guardaron: ${errores.join(', ')}',
            isError: true);
      } else {
        _mostrarMensaje('${variaciones.length} variaciones creadas exitosamente');
        Navigator.pop(context);
      }
      _resetForm();
    } catch (e) {
      Navigator.pop(context);
      _mostrarMensaje('Error general al guardar variaciones: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarVariacionIndividual() async {
    final stock = int.parse(_stockController.text.trim());
    final precioValue = parseCurrency(_precioController.text.trim());
    final precio = precioValue.toStringAsFixed(2);

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
      final provider = Provider.of<VariacionProvider>(context, listen: false);
      final exito = await provider.crearVariacion(variacion);
      
      if (exito) {
        _mostrarMensaje('Variación creada exitosamente');
        Navigator.pop(context);
      } else {
        _mostrarMensaje('Error al guardar variación: ${provider.error}', isError: true);
      }
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
                  CrearVariacionStyles.mediumSpacing,
                  Text('• ${_coloresSeleccionados.length} colores'),
                  Text('• ${_tallasSeleccionadas.length} tallas'),
                  CrearVariacionStyles.mediumSpacing,
                  const Text('Detalles:'),
                  ...variaciones.map((v) => Text(
                        '• ${v.colorNombre} - Talla ${v.tallaLetra ?? v.tallaNumero}: ${v.stock} unidades, $_currencySymbol${_formatPriceForDisplay(v.precio)} COP',
                        style: CrearVariacionStyles.previewDetailStyle,
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

  String _formatPriceForDisplay(double price) {
    final intPrice = price.toInt();
    final formatter = CurrencyInputFormatter();
    return formatter._formatWithThousands(intPrice.toString());
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
      margin: CrearVariacionStyles.modeToggleMargin,
      padding: CrearVariacionStyles.modeTogglePadding,
      decoration: CrearVariacionStyles.modeToggleDecoration,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _cambiarModo(false),
              child: Semantics(
                label: 'Seleccionar modo individual',
                child: Container(
                  padding: CrearVariacionStyles.modeButtonPadding,
                  decoration: !_modoLotes ? CrearVariacionStyles.modeActiveDecoration : null,
                  child: Text(
                    'Individual',
                    textAlign: TextAlign.center,
                    style: CrearVariacionStyles.modeTextStyle(!_modoLotes),
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
                  padding: CrearVariacionStyles.modeButtonPadding,
                  decoration: _modoLotes ? CrearVariacionStyles.modeActiveDecoration : null,
                  child: Text(
                    'Por lotes',
                    textAlign: TextAlign.center,
                    style: CrearVariacionStyles.modeTextStyle(_modoLotes),
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
      padding: CrearVariacionStyles.sectionPadding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: CrearVariacionStyles.sectionIconSize, color: CrearVariacionStyles.primaryIconColor),
            CrearVariacionStyles.smallHorizontalSpacing,
          ],
          Text(title, style: CrearVariacionStyles.sectionTitleStyle),
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
    bool isPrice = false,
  }) {
    List<TextInputFormatter> formatters = [];
    
    if (isPrice) {
      formatters = [CurrencyInputFormatter()];
    } else if (inputType == TextInputType.number) {
      formatters = [FilteringTextInputFormatter.digitsOnly];
    }

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      inputFormatters: formatters,
      decoration: CrearVariacionStyles.textFieldDecoration(
        label: label,
        prefix: prefix,
        suffix: suffix,
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
      margin: CrearVariacionStyles.containerMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imagen del producto', icon: Icons.image_outlined),
          GestureDetector(
            onTap: () => _seleccionarImagen(),
            child: Semantics(
              label: 'Seleccionar imagen del producto',
              child: Container(
                height: CrearVariacionStyles.imageContainerHeight,
                width: double.infinity,
                decoration: CrearVariacionStyles.imageContainerDecoration(_imagenPrincipal != null),
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
                              decoration: CrearVariacionStyles.editBadgeDecoration,
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: CrearVariacionStyles.editIconSize,
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
                            decoration: CrearVariacionStyles.photoPlaceholderDecoration,
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: CrearVariacionStyles.photoIconSize,
                              color: CrearVariacionStyles.primaryBlue,
                            ),
                          ),
                          CrearVariacionStyles.mediumSpacing,
                          const Text(
                            'Toca para seleccionar imagen',
                            style: CrearVariacionStyles.photoPlaceholderTextStyle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Máximo 5MB',
                            style: CrearVariacionStyles.photoSizeTextStyle,
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
      margin: CrearVariacionStyles.containerMargin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imágenes por color', icon: Icons.image_outlined),
          if (_coloresSeleccionados.isNotEmpty) ...[
            const Text(
              'Selecciona una imagen para cada color:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: CrearVariacionStyles.textDark,
              ),
            ),
            CrearVariacionStyles.mediumSpacing,
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
                      decoration: CrearVariacionStyles.imageContainerDecoration(tieneImagen),
                      child: Column(
                        children: [
                          Expanded(
                            child: tieneImagen
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                                        child: Image.file(
                                          _imagenesPorColor[colorHex]!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: CrearVariacionStyles.editBadgeDecoration,
                                          child: const Icon(
                                            Icons.edit,
                                            color: Colors.white,
                                            size: CrearVariacionStyles.smallEditIconSize,
                                          ),
                                        ),
                                      ),
                                    ],
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
                                  width: CrearVariacionStyles.smallColorCircleSize,
                                  height: CrearVariacionStyles.smallColorCircleSize,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                  ),
                                ),
                                CrearVariacionStyles.smallHorizontalSpacing,
                                Expanded(
                                  child: Text(
                                    colorName,
                                    style: CrearVariacionStyles.smallTextStyle,
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
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: CrearVariacionStyles.infoContainerDecoration,
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: CrearVariacionStyles.infoIconColor,
                    size: CrearVariacionStyles.infoIconSize,
                  ),
                  CrearVariacionStyles.mediumHorizontalSpacing,
                  Expanded(
                    child: Text(
                      'Selecciona colores para poder agregar sus imágenes',
                      style: CrearVariacionStyles.infoTextStyle,
                    ),
                  ),
                ],
              ),
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
        decoration: CrearVariacionStyles.previewContainerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Colores seleccionados (${_coloresSeleccionados.length}):',
              style: CrearVariacionStyles.previewTitleStyle,
            ),
            CrearVariacionStyles.smallSpacing,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _coloresSeleccionados.map((colorHex) {
                final colorName = _coloresNombres[colorHex] ?? 'Sin nombre';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: CrearVariacionStyles.colorChipDecoration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: CrearVariacionStyles.smallColorCircleSize,
                        height: CrearVariacionStyles.smallColorCircleSize,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        colorName,
                        style: CrearVariacionStyles.smallTextStyle,
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
        decoration: CrearVariacionStyles.previewContainerDecoration,
        child: Row(
          children: [
            Container(
              width: CrearVariacionStyles.colorCircleSize,
              height: CrearVariacionStyles.colorCircleSize,
              decoration: CrearVariacionStyles.colorCircleDecoration(_selectedColorHex!),
            ),
            CrearVariacionStyles.mediumHorizontalSpacing,
            Expanded(
              child: Text(
                'Color: ${_selectedColorName ?? 'Sin nombre'}',
                style: CrearVariacionStyles.colorNameStyle,
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: CrearVariacionStyles.primaryBlue,
              size: CrearVariacionStyles.checkIconSize,
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
        decoration: CrearVariacionStyles.previewContainerDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tallas seleccionadas (${_tallasSeleccionadas.length}):',
              style: CrearVariacionStyles.previewTitleStyle,
            ),
            CrearVariacionStyles.smallSpacing,
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _tallasSeleccionadas.map((talla) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: CrearVariacionStyles.colorChipDecoration,
                  child: Text(
                    talla,
                    style: CrearVariacionStyles.smallTextStyle,
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
          decoration: CrearVariacionStyles.previewContainerDecoration,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Talla: ${_tallaLetra ?? _tallaNumero ?? 'Sin talla'}',
                  style: CrearVariacionStyles.colorNameStyle,
                ),
              ),
              const Icon(
                Icons.check_circle,
                color: CrearVariacionStyles.primaryBlue,
                size: CrearVariacionStyles.checkIconSize,
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
      decoration: CrearVariacionStyles.resumenLotesDecoration,
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: CrearVariacionStyles.orangeIconColor,
            size: CrearVariacionStyles.infoIconSize,
          ),
          CrearVariacionStyles.mediumHorizontalSpacing,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Se crearán $totalVariaciones variaciones',
                  style: CrearVariacionStyles.resumenTitleStyle,
                ),
                Text(
                  '${_coloresSeleccionados.length} colores × ${_tallasSeleccionadas.length} tallas',
                  style: CrearVariacionStyles.resumenSubtitleStyle,
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
      height: CrearVariacionStyles.buttonHeight,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid() ? null : _guardarVariaciones,
        style: CrearVariacionStyles.primaryButtonStyle(isEnabled: !_isLoading && _isFormValid()),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  CrearVariacionStyles.mediumHorizontalSpacing,
                  const Text(
                    'Guardando...',
                    style: CrearVariacionStyles.buttonTextStyle,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _modoLotes ? Icons.save_alt_outlined : Icons.save_outlined,
                    size: CrearVariacionStyles.buttonIconSize,
                  ),
                  CrearVariacionStyles.smallHorizontalSpacing,
                  Text(
                    buttonText,
                    style: CrearVariacionStyles.buttonTextStyle,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      width: double.infinity,
      height: CrearVariacionStyles.buttonHeight,
      margin: const EdgeInsets.only(top: 8),
      child: OutlinedButton(
        onPressed: _isLoading ? null : _resetForm,
        style: CrearVariacionStyles.outlinedButtonStyle,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.clear,
              size: CrearVariacionStyles.buttonIconSize,
              color: CrearVariacionStyles.grayIconColor,
            ),
            CrearVariacionStyles.smallHorizontalSpacing,
            Text(
              'Limpiar formulario',
              style: CrearVariacionStyles.clearButtonTextStyle,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrearVariacionStyles.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Crear Variaciones',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: CrearVariacionStyles.textDark,
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
          padding: CrearVariacionStyles.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModeToggle(),
              _buildSectionTitle('Color${_modoLotes ? 'es' : ''}', icon: Icons.palette_outlined),
              Container(
                padding: CrearVariacionStyles.cardPadding,
                decoration: CrearVariacionStyles.whiteCardDecoration,
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
              CrearVariacionStyles.largeSpacing,
              _buildSectionTitle('Talla${_modoLotes ? 's' : ''}', icon: Icons.straighten_outlined),
              Container(
                padding: CrearVariacionStyles.cardPadding,
                decoration: CrearVariacionStyles.whiteCardDecoration,
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
                              if (RegExp(r'^\d+').hasMatch(valor)) {
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
              CrearVariacionStyles.largeSpacing,
              _buildSectionTitle('Inventario y Precio', icon: Icons.inventory_outlined),
              Container(
                padding: CrearVariacionStyles.cardPadding,
                decoration: CrearVariacionStyles.whiteCardDecoration,
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
                      CrearVariacionStyles.mediumSpacing,
                      _buildTextField(
                        label: 'Precio',
                        controller: _precioController,
                        inputType: TextInputType.number,
                        validator: _validarPrecio,
                        prefix: _currencySymbol,
                        isPrice: true,
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
                                  width: CrearVariacionStyles.colorCircleSize,
                                  height: CrearVariacionStyles.colorCircleSize,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                CrearVariacionStyles.smallHorizontalSpacing,
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
                                    CrearVariacionStyles.mediumHorizontalSpacing,
                                    Expanded(
                                      child: _buildTextField(
                                        label: 'Precio',
                                        controller: _precioControllersPorVariacion[key]!,
                                        inputType: TextInputType.number,
                                        validator: _validarPrecio,
                                        prefix: _currencySymbol,
                                        isPrice: true,
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
              CrearVariacionStyles.largeSpacing,
              _buildImageSelector(),
              CrearVariacionStyles.xlargeSpacing,
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