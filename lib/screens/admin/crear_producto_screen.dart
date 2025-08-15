// IMPORTACIONES
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/producto_service.dart';
import 'gestionar_variaciones_screen.dart';

class CrearProductoScreen extends StatefulWidget {
  final String? categoryId; // Added parameter to accept category ID

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

  List<Map<String, dynamic>> categorias = [];
  final List<String> subcategorias = ['Adulto', 'Niño'];

  final productoService = ProductoService();

  bool _showFab = false;
  String? _createdProductId;
  bool _isLoadingCategories = true;
  bool _isCreating = false;
  String? _categoryError;

  @override
  void initState() {
    super.initState();
    cargarCategorias();
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    stockController.dispose();
    super.dispose();
  }

  Future<void> cargarCategorias() async {
    setState(() {
      _isLoadingCategories = true;
      _categoryError = null;
    });
    try {
     final data = await productoService.obtenerCategorias();
setState(() {
  categorias = data;
  _isLoadingCategories = false;

  if (widget.categoryId != null) {
    try {
      categoriaSeleccionada = categorias.firstWhere((cat) => cat['_id'] == widget.categoryId);
    } catch (e) {
      categoriaSeleccionada = categorias.isNotEmpty ? categorias.first : null;
    }
  }
});
    } catch (e) {
      setState(() {
        _categoryError = 'Error al cargar categorías: ${e.toString().replaceAll('Exception:', '')}';
        _isLoadingCategories = false;
      });
      if (mounted) {
        _showSnackBar(_categoryError!, isError: true);
      }
    }
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

    setState(() => _isCreating = true);

    final int? stockGeneral = int.tryParse(stockController.text.trim());

    try {
      final nuevoProducto = await productoService.crearProducto(
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        precio: double.parse(precioController.text.trim()),
        stock: stockGeneral ?? 0,
        categoria: categoriaSeleccionada!['_id'],
        subcategoria: subcategoriaSeleccionada ?? '',
        disponible: disponible,
        estado: 'activo', // Valor por defecto
        imagenLocal: imagenSeleccionada!,
      );

      if (mounted) {
        _showSnackBar('¡Producto creado exitosamente! 🎉');
        setState(() {
          _showFab = true;
          _createdProductId = nuevoProducto['_id']?.toString();
        });

        // Limpiar formularios
        _resetForm();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al crear producto: ${e.toString()}', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
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
            validator: (value) {
              if (obligatorio && (value == null || value.trim().isEmpty)) {
                return 'Este campo es obligatorio';
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
                          'PNG, JPG hasta 5MB',
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

  Widget _buildActionButton() {
    return Container(
      margin: const EdgeInsets.only(top: 32, bottom: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _isCreating ? null : guardarProducto,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFF9CA3AF),
            elevation: _isCreating ? 0 : 8,
            shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isCreating
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
              // Categoría con loading state
              Container(
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
                      child: _isLoadingCategories
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
                          : _categoryError != null
                              ? Container(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.error_outline, color: Color(0xFFEF4444)),
                                          const SizedBox(width: 12),
                                          Expanded(child: Text(_categoryError!)),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: TextButton(
                                          onPressed: cargarCategorias,
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
                                  items: categorias.map((cat) {
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
              ),
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
                hint: 'Ej: 10000',
              ),
              _buildTextField(
                label: 'Stock inicial',
                controller: stockController,
                icon: Icons.inventory_outlined,
                tipo: TextInputType.number,
                obligatorio: false,
                hint: 'Cantidad disponible',
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