import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/producto_service.dart';

class EditarProductoScreen extends StatefulWidget {
  final String productId;

  const EditarProductoScreen({super.key, required this.productId});

  @override
  State<EditarProductoScreen> createState() => _EditarProductoScreenState();
}

class _EditarProductoScreenState extends State<EditarProductoScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final productoService = ProductoService();

  // Controllers
  final nombreController = TextEditingController();
  final descripcionController = TextEditingController();
  final precioController = TextEditingController();
  final stockController = TextEditingController();

  // Focus nodes para navegación
  final nombreFocus = FocusNode();
  final descripcionFocus = FocusNode();
  final precioFocus = FocusNode();
  final stockFocus = FocusNode();

  // Variables de estado
  File? imagenSeleccionada;
  Map<String, dynamic>? categoriaSeleccionada;
  String? subcategoriaSeleccionada;
  String? estadoSeleccionado = 'activo';
  bool disponible = true;

  // Datos
  List<Map<String, dynamic>> categorias = [];
  final List<String> subcategorias = ['Adulto', 'Niño'];
  final List<String> estados = ['activo', 'inactivo'];

  // Estados de UI
  bool _isUpdating = false;
  bool _isLoadingProduct = true;
  bool _isLoadingCategories = false;
  String? _categoryError;
  bool _hasUnsavedChanges = false;
  bool _showPreview = false;

  // Animaciones
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  Map<String, dynamic>? producto;
  Map<String, dynamic>? _originalData;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupTextControllerListeners();
    _cargarProducto();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _slideController.forward();
  }

  void _setupTextControllerListeners() {
    nombreController.addListener(_onFieldChanged);
    descripcionController.addListener(_onFieldChanged);
    precioController.addListener(_onFieldChanged);
    stockController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasUnsavedChanges && _originalData != null) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    nombreController.dispose();
    descripcionController.dispose();
    precioController.dispose();
    stockController.dispose();
    nombreFocus.dispose();
    descripcionFocus.dispose();
    precioFocus.dispose();
    stockFocus.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange[600], size: 28),
                const SizedBox(width: 12),
                const Flexible(child: Text('¿Descartar cambios?')),
              ],
            ),
            content: const Text(
              'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _cargarProducto() async {
    setState(() {
      _isLoadingProduct = true;
      _isLoadingCategories = true;
    });

    try {
      final prod = await productoService.obtenerProductoPorId(widget.productId);
      final data = await productoService.obtenerCategorias();

      setState(() {
        producto = prod;
        categorias = data;

        // Guardar datos originales para comparar cambios
        _originalData = Map.from(prod);

        nombreController.text = producto?['nombre'] ?? '';
        descripcionController.text = producto?['descripcion'] ?? '';
        precioController.text = (producto?['precio'] ?? '').toString();
        stockController.text = (producto?['stock'] ?? '').toString();

        subcategoriaSeleccionada = producto?['subcategoria']?.toString().toLowerCase();
        estadoSeleccionado = producto?['estado'] ?? 'activo';
        disponible = producto?['disponible'] ?? true;

        categoriaSeleccionada = categorias.firstWhere(
          (cat) => cat['_id'] == producto?['categoria'],
          orElse: () => categorias.isNotEmpty ? categorias[0] : {},
        );

        _isLoadingProduct = false;
        _isLoadingCategories = false;
        _hasUnsavedChanges = false;
      });

      // Animación de entrada suave
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _slideController.forward();

    } catch (e) {
      setState(() {
        _isLoadingProduct = false;
        _isLoadingCategories = false;
        _categoryError = 'Error cargando datos: ${e.toString()}';
      });
      if (mounted) {
        _showSnackBar('Error cargando producto: $e', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false, Duration? duration}) {
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
        backgroundColor: isError
            ? const Color(0xFFE53E3E)
            : const Color(0xFF38A169),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        elevation: 8,
        duration: duration ?? Duration(seconds: isError ? 4 : 3),
        action: isError
            ? SnackBarAction(
                label: 'Reintentar',
                textColor: Colors.white,
                onPressed: _cargarProducto,
              )
            : null,
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    HapticFeedback.lightImpact();

    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          imagenSeleccionada = File(pickedFile.path);
          _hasUnsavedChanges = true;
        });
        HapticFeedback.mediumImpact();
      }
    } catch (e) {
      _showSnackBar('Error al seleccionar imagen: $e', isError: true);
    }
  }

  Future<void> actualizarProducto() async {
    if (!_formKey.currentState!.validate() || categoriaSeleccionada == null) {
      _showSnackBar('Por favor, completa todos los campos requeridos.', isError: true);
      // Enfocar el primer campo con error
      if (nombreController.text.isEmpty) {
        nombreFocus.requestFocus();
      }
      return;
    }

    setState(() => _isUpdating = true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.lightImpact();

    try {
      final actualizado = await productoService.actualizarProducto(
        id: widget.productId,
        nombre: nombreController.text.trim(),
        descripcion: descripcionController.text.trim(),
        precio: double.parse(precioController.text.trim()),
        categoria: categoriaSeleccionada!['_id'],
        subcategoria: subcategoriaSeleccionada ?? '',
        stock: int.tryParse(stockController.text.trim()) ?? 0,
        disponible: disponible,
        estado: estadoSeleccionado ?? 'activo',
        imagenLocal: imagenSeleccionada,
      );

      if (mounted) {
        HapticFeedback.mediumImpact();
        _showSnackBar('¡Producto actualizado exitosamente! 🎉');
        setState(() => _hasUnsavedChanges = false);
        
        // Pequeño delay para mostrar el éxito antes de cerrar
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          Navigator.pop(context, actualizado);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackBar('Error al actualizar producto: $e', isError: true);
      }
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      setState(() => _isUpdating = false);
    }
  }

  String? _validateField(String? value, String fieldName, {bool isNumeric = false}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName es obligatorio';
    }
    if (isNumeric && double.tryParse(value) == null) {
      return 'Ingresa un $fieldName válido';
    }
    if (fieldName == 'Precio' && double.parse(value) <= 0) {
      return 'El precio debe ser mayor a 0';
    }
    return null;
  }

  // Función helper para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return baseSize * 1.2; // Tablets
    if (screenWidth < 360) return baseSize * 0.9; // Pantallas pequeñas
    return baseSize;
  }

  // Función helper para obtener padding responsivo
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 600) return const EdgeInsets.all(32); // Tablets
    if (screenWidth < 360) return const EdgeInsets.all(12); // Pantallas pequeñas
    return const EdgeInsets.all(20); // Por defecto
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.only(top: 24, bottom: 16),
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
                size: _getResponsiveSize(context, 20),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 18),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                  letterSpacing: -0.5,
                ),
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, 12)),
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
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    IconData? icon,
    TextInputType tipo = TextInputType.text,
    bool obligatorio = true,
    int maxLines = 1,
    String? hint,
    FocusNode? nextFocus,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              if (obligatorio)
                Text(
                  ' *',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveSize(context, 14),
                  ),
                ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            keyboardType: tipo,
            maxLines: maxLines,
            textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done,
            onFieldSubmitted: (_) {
              if (nextFocus != null) {
                nextFocus.requestFocus();
              } else {
                focusNode.unfocus();
              }
            },
            onChanged: (value) {
              if (mounted) setState(() {});
            },
            validator: (value) => _validateField(
              value,
              label,
              isNumeric: tipo == TextInputType.number,
            ),
            style: TextStyle(fontSize: _getResponsiveSize(context, 16)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: _getResponsiveSize(context, 14)),
              prefixIcon: icon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: _getResponsiveSize(context, 16),
                        right: _getResponsiveSize(context, 12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF9CA3AF),
                        size: _getResponsiveSize(context, 20),
                      ),
                    )
                  : null,
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        size: _getResponsiveSize(context, 20),
                      ),
                      onPressed: () {
                        controller.clear();
                        _onFieldChanged();
                      },
                      color: const Color(0xFF9CA3AF),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, 16),
                vertical: _getResponsiveSize(context, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              if (obligatorio)
                Text(
                  ' *',
                  style: TextStyle(
                    color: const Color(0xFFEF4444),
                    fontWeight: FontWeight.w600,
                    fontSize: _getResponsiveSize(context, 14),
                  ),
                ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: (newValue) {
              onChanged(newValue);
              setState(() => _hasUnsavedChanges = true);
            },
            validator: (val) => obligatorio && val == null ? 'Campo obligatorio' : null,
            style: TextStyle(fontSize: _getResponsiveSize(context, 16), color: Colors.black),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(fontSize: _getResponsiveSize(context, 14)),
              prefixIcon: icon != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        left: _getResponsiveSize(context, 16),
                        right: _getResponsiveSize(context, 12),
                      ),
                      child: Icon(
                        icon,
                        color: const Color(0xFF9CA3AF),
                        size: _getResponsiveSize(context, 20),
                      ),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, 16),
                vertical: _getResponsiveSize(context, 16),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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

  Widget _buildCategorySelector() {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  'Categoría',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              Text(
                ' *',
                style: TextStyle(
                  color: const Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: _getResponsiveSize(context, 14),
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: _isLoadingCategories
                ? Container(
                    padding: EdgeInsets.all(_getResponsiveSize(context, 20)),
                    child: Row(
                      children: [
                        SizedBox(
                          width: _getResponsiveSize(context, 20),
                          height: _getResponsiveSize(context, 20),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                        SizedBox(width: _getResponsiveSize(context, 16)),
                        Flexible(
                          child: Text(
                            'Cargando categorías...',
                            style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                          ),
                        ),
                      ],
                    ),
                  )
                : _categoryError != null
                    ? Container(
                        padding: EdgeInsets.all(_getResponsiveSize(context, 20)),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: const Color(0xFFEF4444),
                                  size: _getResponsiveSize(context, 20),
                                ),
                                SizedBox(width: _getResponsiveSize(context, 12)),
                                Expanded(
                                  child: Text(
                                    _categoryError!,
                                    style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSize(context, 12)),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: _cargarProducto,
                                icon: Icon(
                                  Icons.refresh,
                                  size: _getResponsiveSize(context, 18),
                                ),
                                label: Text(
                                  'Reintentar',
                                  style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonFormField<Map<String, dynamic>>(
                        value: categoriaSeleccionada,
                        style: TextStyle(
                          fontSize: _getResponsiveSize(context, 16),
                          color: Colors.black,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(
                              left: _getResponsiveSize(context, 16),
                              right: _getResponsiveSize(context, 12),
                            ),
                            child: Icon(
                              Icons.category_outlined,
                              color: const Color(0xFF9CA3AF),
                              size: _getResponsiveSize(context, 20),
                            ),
                          ),
                          hintText: 'Seleccionar categoría',
                          hintStyle: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(context, 16),
                            vertical: _getResponsiveSize(context, 16),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: categorias.map((cat) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: cat,
                            child: Text(
                              cat['nombre'],
                              style: TextStyle(fontSize: _getResponsiveSize(context, 16)),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            categoriaSeleccionada = val;
                            _hasUnsavedChanges = true;
                          });
                        },
                        validator: (val) => val == null ? 'Campo obligatorio' : null,
                        isExpanded: true,
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSelector() {
    final screenHeight = MediaQuery.of(context).size.height;
    final imageHeight = _showPreview ? screenHeight * 0.3 : screenHeight * 0.2;
    
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Imagen del producto',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
              if (imagenSeleccionada != null || producto?['imagen'] != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showPreview = !_showPreview);
                  },
                  icon: Icon(
                    _showPreview ? Icons.visibility_off : Icons.visibility,
                    size: _getResponsiveSize(context, 18),
                  ),
                  label: Text(
                    _showPreview ? 'Ocultar' : 'Vista previa',
                    style: TextStyle(fontSize: _getResponsiveSize(context, 12)),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, 8)),
          GestureDetector(
            onTap: seleccionarImagen,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: imageHeight.clamp(150.0, 400.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: imagenSeleccionada != null || producto?['imagen'] != null
                      ? const Color(0xFF6366F1)
                      : const Color(0xFFE5E7EB),
                  width: imagenSeleccionada != null || producto?['imagen'] != null ? 2 : 1,
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
                  ? _buildImagePreview(Image.file(imagenSeleccionada!, fit: BoxFit.cover))
                  : (producto?['imagen'] != null
                      ? _buildImagePreview(
                          Image.network(
                            producto!['imagen'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: _getResponsiveSize(context, 40),
                                      color: const Color(0xFFEF4444),
                                    ),
                                    SizedBox(height: _getResponsiveSize(context, 8)),
                                    Text(
                                      'Error cargando imagen',
                                      style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        )
                      : _buildPlaceholder()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(Widget image) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: image,
          ),
        ),
        Positioned(
          top: _getResponsiveSize(context, 12),
          right: _getResponsiveSize(context, 12),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: _getResponsiveSize(context, 16),
                  ),
                  onPressed: seleccionarImagen,
                  constraints: BoxConstraints(
                    minWidth: _getResponsiveSize(context, 32),
                    minHeight: _getResponsiveSize(context, 32),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: _getResponsiveSize(context, 16),
                  ),
                  onPressed: () {
                    setState(() {
                      imagenSeleccionada = null;
                      _hasUnsavedChanges = true;
                    });
                    HapticFeedback.lightImpact();
                  },
                  constraints: BoxConstraints(
                    minWidth: _getResponsiveSize(context, 32),
                    minHeight: _getResponsiveSize(context, 32),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showPreview)
          Positioned(
            bottom: _getResponsiveSize(context, 12),
            left: _getResponsiveSize(context, 12),
            right: _getResponsiveSize(context, 12),
            child: Container(
              padding: EdgeInsets.all(_getResponsiveSize(context, 12)),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                imagenSeleccionada != null
                    ? 'Imagen nueva seleccionada'
                    : 'Imagen actual del producto',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _getResponsiveSize(context, 12),
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(_getResponsiveSize(context, 20)),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: _getResponsiveSize(context, 40),
            color: const Color(0xFF6366F1),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 16)),
        Text(
          'Seleccionar imagen',
          style: TextStyle(
            fontSize: _getResponsiveSize(context, 16),
            fontWeight: FontWeight.w600,
            color: const Color(0xFF374151),
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 4)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 16)),
          child: Text(
            'Toca para cambiar o seleccionar nueva imagen',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              color: const Color(0xFF6B7280),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, 8)),
        Text(
          'PNG, JPG hasta 5MB',
          style: TextStyle(
            fontSize: _getResponsiveSize(context, 12),
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusSwitch() {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 0,
        child: Container(
          padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(_getResponsiveSize(context, 8)),
                decoration: BoxDecoration(
                  color: (disponible ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  disponible ? Icons.check_circle_outline : Icons.cancel_outlined,
                  color: disponible ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  size: _getResponsiveSize(context, 24),
                ),
              ),
              SizedBox(width: _getResponsiveSize(context, 12)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Disponibilidad del producto',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 14),
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    Text(
                      disponible 
                          ? 'Producto disponible para venta' 
                          : 'Producto no disponible para venta',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 12),
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedScale(
                scale: disponible ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: Switch(
                  value: disponible,
                  onChanged: (val) {
                    setState(() {
                      disponible = val;
                      _hasUnsavedChanges = true;
                    });
                    HapticFeedback.selectionClick();
                  },
                  activeColor: const Color(0xFF10B981),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      margin: EdgeInsets.only(bottom: _getResponsiveSize(context, 20)),
      padding: EdgeInsets.all(_getResponsiveSize(context, 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen del producto',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 14),
              fontWeight: FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 12)),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 400) {
                return Row(
                  children: [
                    _buildStatItem(
                      'Estado',
                      estadoSeleccionado?.toUpperCase() ?? 'NO DEFINIDO',
                      estadoSeleccionado == 'activo' ? Colors.green : Colors.orange,
                    ),
                    SizedBox(width: _getResponsiveSize(context, 16)),
                    _buildStatItem(
                      'Disponible',
                      disponible ? 'SÍ' : 'NO',
                      disponible ? Colors.green : Colors.red,
                    ),
                    SizedBox(width: _getResponsiveSize(context, 16)),
                    _buildStatItem(
                      'Stock',
                      stockController.text.isEmpty ? '0' : stockController.text,
                      Colors.blue,
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    Row(
                      children: [
                        _buildStatItem(
                          'Estado',
                          estadoSeleccionado?.toUpperCase() ?? 'NO DEFINIDO',
                          estadoSeleccionado == 'activo' ? Colors.green : Colors.orange,
                        ),
                        SizedBox(width: _getResponsiveSize(context, 16)),
                        _buildStatItem(
                          'Disponible',
                          disponible ? 'SÍ' : 'NO',
                          disponible ? Colors.green : Colors.red,
                        ),
                      ],
                    ),
                    SizedBox(height: _getResponsiveSize(context, 12)),
                    Row(
                      children: [
                        _buildStatItem(
                          'Stock',
                          stockController.text.isEmpty ? '0' : stockController.text,
                          Colors.blue,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: _getResponsiveSize(context, 12),
              color: const Color(0xFF6B7280),
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, 4)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSize(context, 8),
              vertical: _getResponsiveSize(context, 4),
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 12),
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(
            top: _getResponsiveSize(context, 20),
            bottom: _getResponsiveSize(context, 12),
          ),
          child: SizedBox(
            width: double.infinity,
            height: _getResponsiveSize(context, 56),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _isUpdating ? _pulseAnimation.value : 1.0,
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : actualizarProducto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF9CA3AF),
                      elevation: _isUpdating ? 0 : 8,
                      shadowColor: const Color(0xFF6366F1).withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUpdating
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: _getResponsiveSize(context, 20),
                                height: _getResponsiveSize(context, 20),
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: _getResponsiveSize(context, 16)),
                              Text(
                                'Actualizando producto...',
                                style: TextStyle(
                                  fontSize: _getResponsiveSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.save_outlined,
                                size: _getResponsiveSize(context, 22),
                              ),
                              SizedBox(width: _getResponsiveSize(context, 12)),
                              Text(
                                'Actualizar Producto',
                                style: TextStyle(
                                  fontSize: _getResponsiveSize(context, 16),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
          ),
        ),
        if (_hasUnsavedChanges)
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: _isUpdating ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('¿Descartar cambios?'),
                    content: const Text('Se perderán todos los cambios no guardados.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Descartar'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true) {
                  _cargarProducto();
                }
              },
              icon: Icon(
                Icons.refresh_outlined,
                size: _getResponsiveSize(context, 18),
              ),
              label: Text(
                'Descartar cambios',
                style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
              ),
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange[600],
                padding: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 12)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Editar Producto',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: _getResponsiveSize(context, 20),
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
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: _getResponsiveSize(context, 80),
                height: _getResponsiveSize(context, 80),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF6366F1),
                    strokeWidth: _getResponsiveSize(context, 3),
                  ),
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 24)),
              Text(
                'Cargando producto...',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, 18),
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151),
                ),
              ),
              SizedBox(height: _getResponsiveSize(context, 8)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: _getResponsiveSize(context, 32)),
                child: Text(
                  'Obteniendo información del producto',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 14),
                    color: const Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return _buildLoadingScreen();
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: Text(
            'Editar Producto',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: _getResponsiveSize(context, 20),
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
          actions: [
            if (_hasUnsavedChanges)
              Container(
                margin: EdgeInsets.only(right: _getResponsiveSize(context, 8)),
                padding: EdgeInsets.symmetric(
                  horizontal: _getResponsiveSize(context, 8),
                  vertical: _getResponsiveSize(context, 4),
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      color: Colors.orange,
                      size: _getResponsiveSize(context, 8),
                    ),
                    SizedBox(width: _getResponsiveSize(context, 4)),
                    Text(
                      'Sin guardar',
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 12),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: const Color(0xFF6366F1),
                          size: _getResponsiveSize(context, 24),
                        ),
                        SizedBox(width: _getResponsiveSize(context, 12)),
                        const Flexible(child: Text('Ayuda')),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Todos los campos marcados con * son obligatorios',
                          style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 8)),
                        Text(
                          '• La imagen es opcional pero recomendada',
                          style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 8)),
                        Text(
                          '• El precio debe ser mayor a 0',
                          style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                        ),
                        SizedBox(height: _getResponsiveSize(context, 8)),
                        Text(
                          '• Los cambios se detectan automáticamente',
                          style: TextStyle(fontSize: _getResponsiveSize(context, 14)),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Entendido'),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(
                Icons.help_outline,
                size: _getResponsiveSize(context, 24),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: _getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Información Básica', Icons.info_outline),
                  
                  _buildImageSelector(),
                  
                  _buildTextField(
                    label: 'Nombre del producto',
                    controller: nombreController,
                    focusNode: nombreFocus,
                    icon: Icons.inventory_2_outlined,
                    hint: 'Ej: Camiseta básica de algodón',
                    nextFocus: descripcionFocus,
                  ),
                  
                  _buildTextField(
                    label: 'Descripción',
                    controller: descripcionController,
                    focusNode: descripcionFocus,
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    hint: 'Describe las características, materiales, etc...',
                    nextFocus: precioFocus,
                  ),
                  
                  _buildCategorySelector(),
                  
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
                    focusNode: precioFocus,
                    icon: Icons.payments_outlined,
                    tipo: TextInputType.number,
                    hint: 'Ej: 25000',
                    nextFocus: stockFocus,
                  ),
                  
                  _buildTextField(
                    label: 'Stock disponible',
                    controller: stockController,
                    focusNode: stockFocus,
                    icon: Icons.inventory_outlined,
                    tipo: TextInputType.number,
                    obligatorio: false,
                    hint: 'Cantidad disponible (opcional)',
                  ),
                  
                  _buildSectionHeader('Configuración', Icons.settings_outlined),
                  
                  _buildQuickStats(),
                  
                  _buildStatusSwitch(),
                  
                  _buildDropdownField<String>(
                    label: 'Estado del producto',
                    value: estadoSeleccionado,
                    items: estados
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Row(
                                children: [
                                  Container(
                                    width: _getResponsiveSize(context, 8),
                                    height: _getResponsiveSize(context, 8),
                                    decoration: BoxDecoration(
                                      color: e == 'activo' ? Colors.green : Colors.orange,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: _getResponsiveSize(context, 8)),
                                  Text(e.toUpperCase()),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => estadoSeleccionado = val),
                    icon: Icons.toggle_on_outlined,
                    hint: 'Seleccionar estado',
                  ),
                  
                  _buildActionButtons(),
                  
                  SizedBox(height: _getResponsiveSize(context, 20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
                                