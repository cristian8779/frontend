// IMPORTACIONES
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/producto_admin_provider.dart';
import 'gestionar_variaciones_screen.dart';

// Importar estilos
import 'styles/crear_producto/colors.dart';
import 'styles/crear_producto/text_styles.dart';
import 'styles/crear_producto/decorations.dart';
import 'styles/crear_producto/dimensions.dart';

// Clase para formatear el precio en pesos colombianos
class ColombiaCurrencyInputFormatter extends TextInputFormatter {
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
      return const TextEditingValue(text: '');
    }

    int value = int.parse(numbersOnly);
    String formatted = _formatCurrency(value);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCurrency(int value) {
    String valueStr = value.toString();
    String result = '';
    
    for (int i = 0; i < valueStr.length; i++) {
      if (i > 0 && (valueStr.length - i) % 3 == 0) {
        result += '.';
      }
      result += valueStr[i];
    }
    
    return '\$ $result';
  }
}

class CrearProductoScreen extends StatefulWidget {
  final String? categoryId;

  const CrearProductoScreen({super.key, this.categoryId});

  @override
  State<CrearProductoScreen> createState() => _CrearProductoScreenState();
}

class _CrearProductoScreenState extends State<CrearProductoScreen> {
  final _formKey = GlobalKey<FormState>();
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();

  Map<String, dynamic>? categoriaSeleccionada;
  String? subcategoriaSeleccionada;
  bool disponible = true;
  File? imagenSeleccionada;

  final List<String> subcategorias = ['Adulto', 'Niño'];
  final ColombiaCurrencyInputFormatter _currencyFormatter = ColombiaCurrencyInputFormatter();

  bool _showFab = false;
  String? _createdProductId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _inicializarProvider();
    });
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> _inicializarProvider() async {
    final provider = context.read<ProductoProvider>();
    
    if (provider.categorias.isEmpty) {
      await provider.inicializar();
    }

    if (widget.categoryId != null && provider.categorias.isNotEmpty) {
      try {
        categoriaSeleccionada = provider.categorias.firstWhere(
          (cat) => cat['_id'] == widget.categoryId
        );
      } catch (e) {
        categoriaSeleccionada = provider.categorias.isNotEmpty ? provider.categorias.first : null;
      }
      if (mounted) setState(() {});
    }
  }

  double _extractPriceValue(String formattedPrice) {
    if (formattedPrice.isEmpty) return 0.0;
    
    String numbersOnly = formattedPrice
        .replaceAll('\$', '')
        .replaceAll(' ', '')
        .replaceAll('.', '');
    
    if (numbersOnly.isEmpty) return 0.0;
    
    return double.tryParse(numbersOnly) ?? 0.0;
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (pickedFile != null) {
      setState(() {
        imagenSeleccionada = File(pickedFile.path);
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: CrearProductoDimensions.iconMedium,
            ),
            SizedBox(width: CrearProductoDimensions.spacingMedium),
            Expanded(
              child: Text(message, style: CrearProductoTextStyles.snackBar),
            ),
          ],
        ),
        backgroundColor: isError ? CrearProductoColors.errorDark : CrearProductoColors.success,
        behavior: SnackBarBehavior.floating,
        shape: CrearProductoDecorations.snackBarShape,
        margin: CrearProductoDimensions.snackBarMargin,
        elevation: 8,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  Future<void> guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    if (imagenSeleccionada == null || categoriaSeleccionada == null) {
      _showSnackBar('Por favor, completa todos los campos requeridos.', isError: true);
      return;
    }

    final provider = context.read<ProductoProvider>();
    final int? stockGeneral = int.tryParse(stockController.text.trim());
    final double precioValue = _extractPriceValue(precioController.text);

    try {
      final exito = await provider.crearProducto(
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        precio: precioValue,
        categoria: categoriaSeleccionada!['_id'],
        subcategoria: subcategoriaSeleccionada ?? '',
        stock: stockGeneral ?? 0,
        disponible: disponible,
        estado: 'activo',
        imagenLocal: imagenSeleccionada!,
      );

      if (mounted) {
        if (exito) {
          _showSnackBar('¡Producto creado exitosamente!');
          
          debugPrint('🔄 Refrescando provider después de crear producto');
          await provider.refrescar();
          
          await Future.delayed(const Duration(milliseconds: 1500));
          
          if (mounted) {
            debugPrint('✅ Producto creado exitosamente, regresando con resultado true');
            Navigator.of(context).pop(true);
          }
        } else {
          _showSnackBar(
            provider.errorMessage ?? 'Error al crear producto',
            isError: true
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al crear producto: ${e.toString()}', isError: true);
      }
    }
  }

  void _resetForm() {
    nombreController.clear();
    descripcionController.clear();
    precioController.clear();
    stockController.clear();
    setState(() {
      imagenSeleccionada = null;
      categoriaSeleccionada = widget.categoryId != null ? categoriaSeleccionada : null;
      subcategoriaSeleccionada = null;
      disponible = true;
    });
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      margin: CrearProductoDimensions.sectionHeaderMargin,
      child: Row(
        children: [
          Container(
            padding: CrearProductoDimensions.iconPadding,
            decoration: CrearProductoDecorations.sectionIconContainer,
            child: Icon(
              icon,
              color: CrearProductoColors.primary,
              size: CrearProductoDimensions.iconMedium,
            ),
          ),
          SizedBox(width: CrearProductoDimensions.spacingMedium),
          Text(title, style: CrearProductoTextStyles.sectionHeader),
          SizedBox(width: CrearProductoDimensions.spacingMedium),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    CrearProductoColors.primaryOpacity(0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType tipo = TextInputType.text,
    bool obligatorio = true,
    int maxLines = 1,
    String? hint,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: CrearProductoDimensions.fieldMarginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: CrearProductoTextStyles.label),
              if (obligatorio)
                Text(' *', style: CrearProductoTextStyles.labelRequired),
            ],
          ),
          SizedBox(height: CrearProductoDimensions.spacingSmall),
          TextFormField(
            controller: controller,
            keyboardType: tipo,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            validator: (value) {
              if (obligatorio && (value == null || value.trim().isEmpty)) {
                return 'Este campo es obligatorio';
              }
              if (label == 'Precio' && value != null && value.isNotEmpty) {
                double precio = _extractPriceValue(value);
                if (precio <= 0) {
                  return 'El precio debe ser mayor a 0';
                }
              }
              return null;
            },
            decoration: CrearProductoDecorations.inputDecoration(
              hintText: hint,
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    bool obligatorio = true,
    IconData? icon,
    String? hint,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: CrearProductoDimensions.fieldMarginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(label, style: CrearProductoTextStyles.label),
              if (obligatorio)
                Text(' *', style: CrearProductoTextStyles.labelRequired),
            ],
          ),
          SizedBox(height: CrearProductoDimensions.spacingSmall),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: (val) => obligatorio && val == null ? 'Campo obligatorio' : null,
            decoration: CrearProductoDecorations.inputDecoration(
              hintText: hint,
              icon: icon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return Container(
      margin: EdgeInsets.only(bottom: CrearProductoDimensions.fieldMarginBottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Imagen del producto', style: CrearProductoTextStyles.label),
              Text(' *', style: CrearProductoTextStyles.labelRequired),
            ],
          ),
          SizedBox(height: CrearProductoDimensions.spacingSmall),
          GestureDetector(
            onTap: seleccionarImagen,
            child: Container(
              height: CrearProductoDimensions.imageUploadHeight,
              width: double.infinity,
              decoration: CrearProductoDecorations.imageContainer(
                hasImage: imagenSeleccionada != null,
              ),
              child: imagenSeleccionada != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(CrearProductoDimensions.radiusLarge - 1),
                          child: Image.file(
                            imagenSeleccionada!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: CrearProductoDimensions.imageEditButtonTop,
                          right: CrearProductoDimensions.imageEditButtonRight,
                          child: Container(
                            padding: CrearProductoDimensions.iconPadding,
                            decoration: CrearProductoDecorations.imageEditButton,
                            child: Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: CrearProductoDimensions.iconSmall,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: CrearProductoDimensions.iconPaddingLarge,
                          decoration: CrearProductoDecorations.uploadCircle,
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: CrearProductoDimensions.iconXLarge,
                            color: CrearProductoColors.primary,
                          ),
                        ),
                        SizedBox(height: CrearProductoDimensions.spacingLarge),
                        Text('Seleccionar imagen', style: CrearProductoTextStyles.imageUploadTitle),
                        SizedBox(height: CrearProductoDimensions.spacingXSmall),
                        Text(
                          'PNG, JPG hasta 5MB\n📸 Foto clara y bien iluminada',
                          textAlign: TextAlign.center,
                          style: CrearProductoTextStyles.imageUploadHint,
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaDropdown() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: EdgeInsets.only(bottom: CrearProductoDimensions.fieldMarginBottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Categoría', style: CrearProductoTextStyles.label),
                  Text(' *', style: CrearProductoTextStyles.labelRequired),
                ],
              ),
              SizedBox(height: CrearProductoDimensions.spacingSmall),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(CrearProductoDimensions.radiusMedium),
                  border: Border.all(color: CrearProductoColors.border),
                ),
                child: provider.isLoading && provider.categorias.isEmpty
                    ? Container(
                        padding: EdgeInsets.all(CrearProductoDimensions.spacingXLarge),
                        child: Row(
                          children: [
                            SizedBox(
                              width: CrearProductoDimensions.progressIndicatorSize,
                              height: CrearProductoDimensions.progressIndicatorSize,
                              child: CircularProgressIndicator(
                                strokeWidth: CrearProductoDimensions.progressIndicatorStroke,
                              ),
                            ),
                            SizedBox(width: CrearProductoDimensions.spacingLarge),
                            const Text('Cargando categorías...'),
                          ],
                        ),
                      )
                    : provider.hasError && provider.categorias.isEmpty
                        ? Container(
                            padding: EdgeInsets.all(CrearProductoDimensions.spacingXLarge),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: CrearProductoColors.error),
                                    SizedBox(width: CrearProductoDimensions.spacingMedium),
                                    Expanded(
                                      child: Text(provider.errorMessage ?? 'Error al cargar categorías')
                                    ),
                                  ],
                                ),
                                SizedBox(height: CrearProductoDimensions.spacingMedium),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton(
                                    onPressed: () => provider.reintentar(),
                                    child: const Text('Reintentar'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            value: categoriaSeleccionada,
                            decoration: CrearProductoDecorations.inputDecoration(
                              hintText: 'Seleccionar categoría',
                              icon: Icons.category_outlined,
                            ).copyWith(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(CrearProductoDimensions.radiusMedium),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: provider.categorias.map((cat) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: cat,
                                child: Text(cat['nombre']),
                              );
                            }).toList(),
                            onChanged: widget.categoryId != null
                                ? null
                                : (val) => setState(() => categoriaSeleccionada = val),
                            validator: (val) => val == null ? 'Campo obligatorio' : null,
                            isExpanded: true,
                            disabledHint: widget.categoryId != null && categoriaSeleccionada != null
                                ? Text(categoriaSeleccionada!['nombre'])
                                : null,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        return Container(
          margin: CrearProductoDimensions.buttonMargin,
          child: SizedBox(
            width: double.infinity,
            height: CrearProductoDimensions.buttonHeight,
            child: ElevatedButton(
              onPressed: provider.isCreating ? null : guardarProducto,
              style: CrearProductoDecorations.primaryButton(isLoading: provider.isCreating),
              child: provider.isCreating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: CrearProductoDimensions.progressIndicatorSize,
                          height: CrearProductoDimensions.progressIndicatorSize,
                          child: CircularProgressIndicator(
                            strokeWidth: CrearProductoDimensions.progressIndicatorStrokeButton,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: CrearProductoDimensions.spacingLarge),
                        Text('Creando producto...', style: CrearProductoTextStyles.buttonLoading),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: CrearProductoDimensions.iconLarge),
                        SizedBox(width: CrearProductoDimensions.spacingMedium),
                        Text('Crear Producto', style: CrearProductoTextStyles.button),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CrearProductoColors.background,
      appBar: AppBar(
        title: Text('Nuevo Producto', style: CrearProductoTextStyles.appBarTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: CrearProductoColors.textPrimary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(CrearProductoDimensions.appBarBorderHeight),
          child: Container(
            height: CrearProductoDimensions.appBarBorderHeight,
            color: CrearProductoColors.border,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(CrearProductoDimensions.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Información Básica', Icons.info_outline),
              _buildImageUploader(),
              _buildTextField(
                label: 'Nombre del producto',
                controller: nombreController,
                icon: Icons.inventory_2_outlined,
                hint: 'Ej: Camiseta básica',
              ),
              _buildTextField(
                label: 'Descripción',
                controller: descripcionController,
                icon: Icons.description_outlined,
                maxLines: 3,
                hint: 'Debes ingresar una descripción del producto de al menos 15 caracteres.',
              ),
              _buildCategoriaDropdown(),
              _buildDropdownField<String>(
                label: 'Subcategoría',
                value: subcategoriaSeleccionada,
                items: subcategorias
                    .map((sub) => DropdownMenuItem<String>(
                          value: sub.toLowerCase(),
                          child: Text(sub),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => subcategoriaSeleccionada = val),
                icon: Icons.category,
                hint: 'Seleccionar subcategoría',
              ),
              _buildSectionHeader('Información Comercial', Icons.attach_money_outlined),
              _buildTextField(
                label: 'Precio',
                controller: precioController,
                icon: Icons.payments_outlined,
                tipo: TextInputType.number,
                hint: 'Ej: \$ 10.000',
                inputFormatters: [_currencyFormatter],
              ),
              _buildTextField(
                label: 'Stock inicial',
                controller: stockController,
                icon: Icons.inventory_outlined,
                tipo: TextInputType.number,
                obligatorio: false,
                hint: 'Cantidad disponible',
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              _buildActionButton(),
            ],
          ),
        ),
      ),
      floatingActionButton: _showFab && _createdProductId != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GestionarVariacionesScreen(productId: _createdProductId!),
                  ),
                );
              },
              label: Text('Añadir Variaciones', style: CrearProductoTextStyles.button),
              icon: const Icon(Icons.tune),
              backgroundColor: CrearProductoColors.successAlt,
              foregroundColor: Colors.white,
              elevation: 8,
            )
          : null,
    );
  }
}