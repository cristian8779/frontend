// Archivo: lib/screens/variaciones/actualizar_variacion_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../utils/colores.dart';
import '../../widgets/color_selector.dart';
import '../../widgets/selector_talla_widget.dart';
import '../../models/variacion.dart';
import '../../services/variacion_service.dart';

// Formateador para precios en COP (reutilizado de crear_variacion_screen)
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Eliminar todos los caracteres que no sean números
    String numbersOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    // Convertir a número para validar
    final number = int.tryParse(numbersOnly);
    if (number == null) {
      return oldValue;
    }

    // Formatear con separadores de miles
    String formatted = _formatWithThousands(numbersOnly);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithThousands(String number) {
    // Agregar puntos cada tres dígitos desde la derecha
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

class ActualizarVariacionScreen extends StatefulWidget {
  final Variacion variacionToEdit;
  
  const ActualizarVariacionScreen({
    Key? key,
    required this.variacionToEdit,
  }) : super(key: key);

  @override
  State<ActualizarVariacionScreen> createState() => _ActualizarVariacionScreenState();
}

class _ActualizarVariacionScreenState extends State<ActualizarVariacionScreen> {
  final VariacionService _variacionService = VariacionService();
  final _formKey = GlobalKey<FormState>();

  // Selecciones individuales
  String? _selectedColorHex;
  String? _selectedColorName;
  String? _tallaLetra;
  String? _tallaNumero;

  // Imagen
  File? _imagenSeleccionada;
  String? _imageUrl; // Para la imagen existente
  final ImagePicker _picker = ImagePicker();

  // Controladores de texto
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  bool _isLoading = false;
  String _currencySymbol = '\$'; // Símbolo para pesos colombianos

  @override
  void initState() {
    super.initState();
    _initializeFromVariacion();
    _stockController.addListener(_validateForm);
    _precioController.addListener(_validateForm);
  }

  void _initializeFromVariacion() {
    final variacion = widget.variacionToEdit;
    _selectedColorHex = variacion.colorHex;
    _selectedColorName = variacion.colorNombre;
    _tallaLetra = variacion.tallaLetra;
    _tallaNumero = variacion.tallaNumero;
    _stockController.text = variacion.stock.toString();
    
    // Formatear el precio usando el mismo sistema que crear_variacion_screen
    final precioInt = variacion.precio.toInt();
    final formatter = CurrencyInputFormatter();
    _precioController.text = formatter._formatWithThousands(precioInt.toString());
    
    if (variacion.imagenes.isNotEmpty && variacion.imagenes.first.url != null) {
      _imageUrl = variacion.imagenes.first.url;
    }
  }

  @override
  void dispose() {
    _stockController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen() async {
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
          _imagenSeleccionada = imageFile;
          _imageUrl = null; // Borra la URL existente si se selecciona una nueva imagen
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
    
    // Usar parseCurrency para obtener el valor numérico
    final precio = parseCurrency(value);
    if (precio <= 0) {
      return 'Ingresa un precio válido';
    }
    return null;
  }

  bool _isFormValid() {
    return _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        _selectedColorHex != null &&
        (_tallaLetra != null || _tallaNumero != null) &&
        (_imagenSeleccionada != null || _imageUrl != null);
  }

  void _validateForm() {
    setState(() {}); // Actualizar UI para reflejar estado del botón de guardar
  }

  Future<void> _actualizarVariacion() async {
    if (!_isFormValid()) {
      _mostrarMensaje('Por favor, completa todos los campos requeridos.', isError: true);
      return;
    }

    if (_selectedColorHex == null) {
      _mostrarMensaje('Selecciona un color.', isError: true);
      return;
    }
    if (_tallaLetra == null && _tallaNumero == null) {
      _mostrarMensaje('Selecciona una talla.', isError: true);
      return;
    }
    if (_imagenSeleccionada == null && _imageUrl == null) {
      _mostrarMensaje('Selecciona una imagen.', isError: true);
      return;
    }
    
    final stock = int.parse(_stockController.text.trim());
    // Usar parseCurrency en lugar de double.parse
    final precioValue = parseCurrency(_precioController.text.trim());
    final precio = precioValue.toStringAsFixed(2);
    
    final updatedVariacion = Variacion(
      id: widget.variacionToEdit.id,
      productoId: widget.variacionToEdit.productoId,
      colorHex: _selectedColorHex!,
      colorNombre: _selectedColorName ?? '',
      tallaLetra: _tallaLetra,
      tallaNumero: _tallaNumero,
      stock: stock,
      precio: double.parse(precio),
      imagenes: _imagenSeleccionada != null
        ? [ImagenVariacion(isLocal: true, localFile: _imagenSeleccionada)]
        : [ImagenVariacion(url: _imageUrl)],
    );
    
    setState(() => _isLoading = true);
    
    try {
      await _variacionService.actualizarVariacionDesdeModelo(updatedVariacion);
      _mostrarMensaje('Variación actualizada exitosamente');
      Navigator.of(context).pop(true); // Cierra la pantalla y regresa
    } catch (e) {
      final mensajeError = e.toString().replaceAll('Exception: ', '');
      if (e is FormatException) {
        _mostrarMensaje('Error del servidor. Verifica tu conexión e inténtalo de nuevo.', isError: true);
      } else {
        _mostrarMensaje(mensajeError, isError: true);
      }
      debugPrint('Error al actualizar variación: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
    bool isPrice = false,
  }) {
    List<TextInputFormatter> formatters = [];
    
    if (isPrice) {
      // Usar el formateador de moneda para campos de precio
      formatters = [CurrencyInputFormatter()];
    } else if (inputType == TextInputType.number) {
      // Para campos numéricos que no son precio (como stock)
      formatters = [FilteringTextInputFormatter.digitsOnly];
    }

    return TextFormField(
      controller: controller,
      keyboardType: inputType,
      validator: validator,
      inputFormatters: formatters,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imagen del producto', icon: Icons.image_outlined),
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Semantics(
              label: 'Seleccionar imagen del producto',
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_imagenSeleccionada != null || _imageUrl != null) 
                      ? const Color(0xFF3A86FF) 
                      : Colors.grey.shade300,
                    width: (_imagenSeleccionada != null || _imageUrl != null) ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: _imagenSeleccionada != null
                    ? Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.file(
                              _imagenSeleccionada!,
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
                    : _imageUrl != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: Colors.grey.shade100,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: Colors.grey.shade400,
                                      size: 32,
                                    ),
                                  ),
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

  Widget _buildColorPreview() {
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
          const Icon(
            Icons.check_circle,
            color: Color(0xFF3A86FF),
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildTallaPreview() {
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
            const Icon(
              Icons.check_circle,
              color: Color(0xFF3A86FF),
              size: 16,
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildUpdateButton() {
    return Container(
      width: double.infinity,
      height: 56,
      margin: const EdgeInsets.only(top: 8),
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid() ? null : _actualizarVariacion,
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
                    'Actualizando...',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Actualizar Variación',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
          'Actualizar Variación',
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
              // Sección Color
              _buildSectionTitle('Color', icon: Icons.palette_outlined),
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
                      coloresSeleccionados: _selectedColorHex != null ? [_selectedColorHex!] : [],
                      onSelectionChanged: (seleccionados) {
                        setState(() {
                          _selectedColorHex = seleccionados.isNotEmpty ? seleccionados.first : null;
                          _selectedColorName = _selectedColorHex != null 
                              ? Colores.getNombreColor(_selectedColorHex!) 
                              : null;
                        });
                      },
                      coloresAgrupados: Colores.coloresAgrupados,
                      multiSelection: false, // Solo un color en modo edición
                    ),
                    _buildColorPreview(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección Talla
              _buildSectionTitle('Talla', icon: Icons.straighten_outlined),
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
                        });
                      },
                      multiSelection: false, // Solo una talla en modo edición
                      tallasSeleccionadas: _tallaNumero != null
                          ? [_tallaNumero!]
                          : _tallaLetra != null
                              ? [_tallaLetra!]
                              : [],
                    ),
                    _buildTallaPreview(),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección Inventario
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
                      inputType: TextInputType.number,
                      validator: _validarPrecio,
                      prefix: _currencySymbol,
                      isPrice: true,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sección Imagen
              _buildImageSelector(),
              
              const SizedBox(height: 32),
              
              // Botón de actualización
              _buildUpdateButton(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}