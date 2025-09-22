// IMPORTACIONES
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/producto_admin_provider.dart';
import 'gestionar_variaciones_screen.dart';

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

    // Extraer solo los números
    String numbersOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (numbersOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Convertir a entero para formatear
    int value = int.parse(numbersOnly);
    
    // Formatear con puntos como separadores de miles
    String formatted = _formatCurrency(value);
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCurrency(int value) {
    // Formatear el número con puntos como separadores de miles
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
  final String? categoryId; // Parameter to accept category ID

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
    
    // Solo inicializar si no hay categorías cargadas
    if (provider.categorias.isEmpty) {
      await provider.inicializar();
    }

    // Preseleccionar categoría si se pasó como parámetro
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

  // Función para extraer el valor numérico del precio formateado
  double _extractPriceValue(String formattedPrice) {
    if (formattedPrice.isEmpty) return 0.0;
    
    // Remover el símbolo de peso, espacios y puntos
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
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53E3E) : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
          
          // Pequeña pausa para mostrar el mensaje de éxito
          await Future.delayed(const Duration(milliseconds: 1500));
          
          // Redirigir a la pantalla de gestión de productos
          if (mounted) {
            Navigator.of(context).pushReplacementNamed('/gestion-productos');
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
      margin: const EdgeInsets.only(top: 32, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF6366F1),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.3),
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
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              if (obligatorio)
                const Text(
                  ' *',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: tipo,
            maxLines: maxLines,
            inputFormatters: inputFormatters,
            validator: (value) {
              if (obligatorio && (value == null || value.trim().isEmpty)) {
                return 'Este campo es obligatorio';
              }
              // Validación especial para el precio
              if (label == 'Precio' && value != null && value.isNotEmpty) {
                double precio = _extractPriceValue(value);
                if (precio <= 0) {
                  return 'El precio debe ser mayor a 0';
                }
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444)),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
              ),
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
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              if (obligatorio)
                const Text(
                  ' *',
                  style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            validator: (val) => obligatorio && val == null ? 'Campo obligatorio' : null,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 16, right: 12),
                      child: Icon(icon, color: const Color(0xFF9CA3AF), size: 20),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: const Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageUploader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Imagen del producto',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: seleccionarImagen,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: imagenSeleccionada != null ? const Color(0xFF6366F1) : const Color(0xFFE5E7EB),
                  width: imagenSeleccionada != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: imagenSeleccionada != null
                  ? Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.file(
                            imagenSeleccionada!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
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
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: const Color(0xFF6366F1),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Seleccionar imagen',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PNG, JPG hasta 5MB\n📸 Foto clara y bien iluminada',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF6B7280),
                          ),
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
          margin: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Categoría',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const Text(
                    ' *',
                    style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: provider.isLoading && provider.categorias.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(20),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 16),
                            Text('Cargando categorías...'),
                          ],
                        ),
                      )
                    : provider.hasError && provider.categorias.isEmpty
                        ? Container(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(provider.errorMessage ?? 'Error al cargar categorías')
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                            decoration: InputDecoration(
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 16, right: 12),
                                child: Icon(Icons.category_outlined, color: Color(0xFF9CA3AF), size: 20),
                              ),
                              hintText: 'Seleccionar categoría',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              filled: true,
                              fillColor: Colors.white,
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
          margin: const EdgeInsets.only(top: 32, bottom: 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: provider.isCreating ? null : guardarProducto,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9CA3AF),
                elevation: provider.isCreating ? 0 : 8,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: provider.isCreating
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Creando producto...',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_circle_outline, size: 22),
                        const SizedBox(width: 12),
                        const Text(
                          'Crear Producto',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Nuevo Producto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE5E7EB),
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
                hint: 'Describe las características del producto...',
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
              label: const Text(
                'Añadir Variaciones',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              icon: const Icon(Icons.tune),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              elevation: 8,
            )
          : null,
    );
  }
}