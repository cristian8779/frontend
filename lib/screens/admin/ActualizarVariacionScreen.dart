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
// Importar estilos
import 'styles/Actualizar_variacion/colors.dart';
import 'styles/Actualizar_variacion/text_styles.dart';
import 'styles/Actualizar_variacion/dimensions.dart';
import 'styles/Actualizar_variacion/decorations.dart';


// Formateador para precios en COP
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
  final _formKey = GlobalKey<FormState>();

  // Selecciones individuales
  String? _selectedColorHex;
  String? _selectedColorName;
  String? _tallaLetra;
  String? _tallaNumero;

  // Imagen
  File? _imagenSeleccionada;
  String? _imageUrl;
  final ImagePicker _picker = ImagePicker();

  // Controladores de texto
  final TextEditingController _stockController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();

  bool _isLoading = false;
  String _currencySymbol = '\$';

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
          _imageUrl = null;
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
              size: ActualizarVariacionDimensions.iconSizeNormal,
            ),
            const SizedBox(width: ActualizarVariacionDimensions.paddingSmall),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: isError 
            ? ActualizarVariacionColors.error 
            : ActualizarVariacionColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            ActualizarVariacionDimensions.borderRadiusSnackBar,
          ),
        ),
        margin: const EdgeInsets.all(ActualizarVariacionDimensions.marginSnackBar),
      ),
    );
  }

  String? _validarStock(String? value) {
    if (value == null || value.isEmpty) {
      return 'El stock es requerido';
    }
    final stock = int.tryParse(value);
    if (stock == null || stock < 0) {
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

  bool _isFormValid() {
    return _formKey.currentState != null &&
        _formKey.currentState!.validate() &&
        _selectedColorHex != null &&
        (_tallaLetra != null || _tallaNumero != null) &&
        (_imagenSeleccionada != null || _imageUrl != null);
  }

  void _validateForm() {
    setState(() {});
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
      final provider = Provider.of<VariacionProvider>(context, listen: false);
      final exito = await provider.actualizarVariacion(updatedVariacion);
      
      if (exito) {
        _mostrarMensaje('Variación actualizada exitosamente');
        Navigator.of(context).pop(true);
      } else {
        _mostrarMensaje('Error al actualizar: ${provider.error}', isError: true);
      }
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
      padding: const EdgeInsets.only(bottom: ActualizarVariacionDimensions.paddingMedium),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: ActualizarVariacionDimensions.iconSizeNormal, 
              color: ActualizarVariacionColors.primary,
            ),
            const SizedBox(width: ActualizarVariacionDimensions.paddingSmall),
          ],
          Text(title, style: ActualizarVariacionTextStyles.sectionTitle),
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
      decoration: ActualizarVariacionDecorations.textFieldDecoration(
        label: label,
        prefix: prefix,
        suffix: suffix,
      ),
    );
  }

  Widget _buildImageSelector() {
    final hasImage = _imagenSeleccionada != null || _imageUrl != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: ActualizarVariacionDimensions.marginVerticalCard,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Imagen del producto', icon: Icons.image_outlined),
          GestureDetector(
            onTap: _seleccionarImagen,
            child: Semantics(
              label: 'Seleccionar imagen del producto',
              child: Container(
                height: ActualizarVariacionDimensions.imageHeight,
                width: double.infinity,
                decoration: ActualizarVariacionDecorations.imageContainerDecoration(
                  hasImage: hasImage,
                ),
                child: _imagenSeleccionada != null
                    ? _buildLocalImage()
                    : _imageUrl != null
                        ? _buildNetworkImage()
                        : _buildImagePlaceholder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocalImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            ActualizarVariacionDimensions.borderRadiusImageInner,
          ),
          child: Image.file(
            _imagenSeleccionada!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
        _buildEditIcon(),
      ],
    );
  }

  Widget _buildNetworkImage() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(
            ActualizarVariacionDimensions.borderRadiusImageInner,
          ),
          child: Image.network(
            _imageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => Container(
              color: ActualizarVariacionColors.imageBackground,
              child: Icon(
                Icons.broken_image_outlined,
                color: ActualizarVariacionColors.placeholderIcon,
                size: ActualizarVariacionDimensions.iconSizeLarge,
              ),
            ),
          ),
        ),
        _buildEditIcon(),
      ],
    );
  }

  Widget _buildEditIcon() {
    return Positioned(
      top: ActualizarVariacionDimensions.paddingSmall,
      right: ActualizarVariacionDimensions.paddingSmall,
      child: Container(
        padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingSmall),
        decoration: ActualizarVariacionDecorations.editIconDecoration,
        child: const Icon(
          Icons.edit,
          color: Colors.white,
          size: ActualizarVariacionDimensions.iconSizeSmall,
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingLarge),
          decoration: ActualizarVariacionDecorations.iconBackgroundDecoration,
          child: const Icon(
            Icons.add_photo_alternate_outlined,
            size: ActualizarVariacionDimensions.iconSizeLarge,
            color: ActualizarVariacionColors.primary,
          ),
        ),
        const SizedBox(height: ActualizarVariacionDimensions.paddingMedium),
        Text(
          'Toca para seleccionar imagen',
          style: ActualizarVariacionTextStyles.imagePlaceholder,
        ),
        const SizedBox(height: 4),
        Text(
          'Máximo 5MB',
          style: ActualizarVariacionTextStyles.imagePlaceholderSecondary,
        ),
      ],
    );
  }

  Widget _buildColorPreview() {
    if (_selectedColorHex == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: ActualizarVariacionDimensions.paddingSmall),
      padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingMedium),
      decoration: ActualizarVariacionDecorations.previewDecoration,
      child: Row(
        children: [
          Container(
            width: ActualizarVariacionDimensions.colorPreviewSize,
            height: ActualizarVariacionDimensions.colorPreviewSize,
            decoration: ActualizarVariacionDecorations.colorPreviewDecoration(
              _selectedColorHex!,
            ),
          ),
          const SizedBox(width: ActualizarVariacionDimensions.paddingMedium),
          Expanded(
            child: Text(
              'Color: ${_selectedColorName ?? 'Sin nombre'}',
              style: ActualizarVariacionTextStyles.previewText,
            ),
          ),
          const Icon(
            Icons.check_circle,
            color: ActualizarVariacionColors.primary,
            size: ActualizarVariacionDimensions.iconSizeSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildTallaPreview() {
    if (_tallaLetra != null || _tallaNumero != null) {
      return Container(
        margin: const EdgeInsets.only(top: ActualizarVariacionDimensions.paddingSmall),
        padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingMedium),
        decoration: ActualizarVariacionDecorations.previewDecoration,
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Talla: ${_tallaLetra ?? _tallaNumero ?? 'Sin talla'}',
                style: ActualizarVariacionTextStyles.previewText,
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: ActualizarVariacionColors.primary,
              size: ActualizarVariacionDimensions.iconSizeSmall,
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
      height: ActualizarVariacionDimensions.buttonHeight,
      margin: const EdgeInsets.only(top: ActualizarVariacionDimensions.paddingSmall),
      child: ElevatedButton(
        onPressed: _isLoading || !_isFormValid() ? null : _actualizarVariacion,
        style: ActualizarVariacionDecorations.buttonStyle(isLoading: _isLoading),
        child: _isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: ActualizarVariacionDimensions.loaderSize,
                    height: ActualizarVariacionDimensions.loaderSize,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: ActualizarVariacionDimensions.paddingMedium),
                  Text(
                    'Actualizando...',
                    style: ActualizarVariacionTextStyles.buttonText,
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.save_outlined, 
                    size: ActualizarVariacionDimensions.iconSizeNormal,
                  ),
                  const SizedBox(width: ActualizarVariacionDimensions.paddingSmall),
                  Text(
                    'Actualizar Variación',
                    style: ActualizarVariacionTextStyles.buttonText,
                  ),
                ],
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ActualizarVariacionColors.background,
      appBar: AppBar(
        title: Text(
          'Actualizar Variación',
          style: ActualizarVariacionTextStyles.appBarTitle,
        ),
        backgroundColor: Colors.white,
        foregroundColor: ActualizarVariacionColors.textPrimary,
        centerTitle: true,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: ActualizarVariacionColors.borderLight,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingScreen),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sección de Color
              _buildSectionTitle('Color', icon: Icons.palette_outlined),
              Container(
                padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingCard),
                decoration: ActualizarVariacionDecorations.cardDecoration,
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
                      multiSelection: false,
                    ),
                    _buildColorPreview(),
                  ],
                ),
              ),
              
              const SizedBox(height: ActualizarVariacionDimensions.marginSection),
              
              // Sección de Talla
              _buildSectionTitle('Talla', icon: Icons.straighten_outlined),
              Container(
                padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingCard),
                decoration: ActualizarVariacionDecorations.cardDecoration,
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
                      multiSelection: false,
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
              
              const SizedBox(height: ActualizarVariacionDimensions.marginSection),
              
              // Sección de Inventario y Precio
              _buildSectionTitle('Inventario y Precio', icon: Icons.inventory_outlined),
              Container(
                padding: const EdgeInsets.all(ActualizarVariacionDimensions.paddingCard),
                decoration: ActualizarVariacionDecorations.cardDecoration,
                child: Column(
                  children: [
                    _buildTextField(
                      label: 'Stock disponible',
                      controller: _stockController,
                      inputType: TextInputType.number,
                      validator: _validarStock,
                      suffix: 'unidades',
                    ),
                    const SizedBox(height: ActualizarVariacionDimensions.paddingLarge),
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
              
              const SizedBox(height: ActualizarVariacionDimensions.marginSection),
              
              // Selector de Imagen
              _buildImageSelector(),
              
              const SizedBox(height: ActualizarVariacionDimensions.marginTop),
              
              // Botón de Actualizar
              _buildUpdateButton(),
              
              const SizedBox(height: ActualizarVariacionDimensions.marginBottom),
            ],
          ),
        ),
      ),
    );
  }
}