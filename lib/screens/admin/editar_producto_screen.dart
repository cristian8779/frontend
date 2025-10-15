import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/producto_service.dart';
import '../../providers/producto_admin_provider.dart';
import 'styles/editar_producto/editar_producto_styles.dart';
import 'styles/editar_producto/editar_producto_widgets.dart';

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

  // Focus nodes
  final nombreFocus = FocusNode();
  final descripcionFocus = FocusNode();
  final precioFocus = FocusNode();
  final stockFocus = FocusNode();

  // Estado
  File? imagenSeleccionada;
  Map<String, dynamic>? categoriaSeleccionada;
  String? subcategoriaSeleccionada;
  String? estadoSeleccionado = 'activo';
  bool disponible = true;

  final List<String> subcategorias = ['Adulto', 'Niño'];
  final List<String> estados = ['activo', 'inactivo'];

  bool _isUpdating = false;
  bool _isLoadingProduct = true;
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
      duration: EditarProductoStyles.longAnimationDuration,
      vsync: this,
    );
    _slideController = AnimationController(
      duration: EditarProductoStyles.mediumAnimationDuration,
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
            shape: EditarProductoStyles.dialogShape,
            title: Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange[600],
                  size: 28,
                ),
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
                style: EditarProductoStyles.dangerButtonStyle,
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
    });

    try {
      final provider = Provider.of<ProductoProvider>(context, listen: false);
      final prod = await provider.obtenerProductoPorId(widget.productId);

      if (provider.categorias.isEmpty) {
        await provider.inicializar();
      }

      if (prod == null) {
        throw Exception('No se pudo cargar el producto');
      }

      setState(() {
        producto = prod;
        _originalData = Map.from(prod);

        nombreController.text = producto?['nombre'] ?? '';
        descripcionController.text = producto?['descripcion'] ?? '';
        precioController.text = (producto?['precio'] ?? '').toString();
        stockController.text = (producto?['stock'] ?? '').toString();

        subcategoriaSeleccionada =
            producto?['subcategoria']?.toString().toLowerCase();
        estadoSeleccionado = producto?['estado'] ?? 'activo';
        disponible = producto?['disponible'] ?? true;

        final categorias = provider.categorias;
        categoriaSeleccionada = categorias.firstWhere(
          (cat) => cat['_id'] == producto?['categoria'],
          orElse: () => categorias.isNotEmpty ? categorias[0] : {},
        );

        _isLoadingProduct = false;
        _hasUnsavedChanges = false;
      });

      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) _slideController.forward();
    } catch (e) {
      setState(() => _isLoadingProduct = false);
      if (mounted) {
        _showSnackBar('Error cargando producto: $e', isError: true);
      }
    }
  }

  // ✅ CORREGIDO: Método mejorado para mostrar SnackBar
  void _showSnackBar(String message, {bool isError = false, Duration? duration}) {
    if (!mounted) return;
    
    // ✅ Usar WidgetsBinding para asegurar que el contexto está listo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      try {
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
                ? EditarProductoStyles.snackBarErrorColor
                : EditarProductoStyles.snackBarSuccessColor,
            behavior: SnackBarBehavior.floating,
            shape: EditarProductoStyles.snackBarShape,
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
      } catch (e) {
        debugPrint('❌ Error mostrando SnackBar: $e');
      }
    });
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

  // ✅ CORREGIDO: Método de actualización sin SnackBar al éxito
  Future<void> actualizarProducto() async {
    if (!_formKey.currentState!.validate() || categoriaSeleccionada == null) {
      _showSnackBar('Por favor, completa todos los campos requeridos.',
          isError: true);
      if (nombreController.text.isEmpty) {
        nombreFocus.requestFocus();
      }
      return;
    }

    setState(() => _isUpdating = true);
    _pulseController.repeat(reverse: true);
    HapticFeedback.lightImpact();

    try {
      final provider = Provider.of<ProductoProvider>(context, listen: false);

      final success = await provider.actualizarProducto(
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

      // ✅ CORRECCIÓN: Guardar el NavigatorState antes de operaciones asíncronas
      final navigator = Navigator.of(context);
      
      if (success) {
        HapticFeedback.mediumImpact();
        setState(() => _hasUnsavedChanges = false);
        
        // ✅ Navegar inmediatamente sin mostrar SnackBar
        // El mensaje se mostrará en la pantalla anterior
        navigator.pop(true);
      } else {
        // ✅ Solo mostrar error si falla
        if (mounted) {
          HapticFeedback.heavyImpact();
          _showSnackBar(
            'Error al actualizar producto: ${provider.errorMessage ?? 'Error desconocido'}',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSnackBar('Error al actualizar producto: $e', isError: true);
      }
    } finally {
      if (mounted) {
        _pulseController.stop();
        _pulseController.reset();
        setState(() => _isUpdating = false);
      }
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

  Widget _buildCategorySelector() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        final categorias = provider.categorias;
        final isLoadingCategories = provider.isLoading && categorias.isEmpty;
        final hasError = provider.hasError && categorias.isEmpty;

        return Container(
          margin: EdgeInsets.only(
            bottom: EditarProductoStyles.getResponsiveSize(context, 20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Categoría',
                      style: EditarProductoStyles.fieldLabel(context),
                    ),
                  ),
                  Text(' *', style: EditarProductoStyles.requiredMark(context)),
                ],
              ),
              SizedBox(height: EditarProductoStyles.smallSpacing(context)),
              Container(
                decoration: EditarProductoStyles.cardDecoration,
                child: isLoadingCategories
                    ? Container(
                        padding: EdgeInsets.all(
                          EditarProductoStyles.mediumSpacing(context),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: EditarProductoStyles.primaryColor,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Flexible(child: Text('Cargando categorías...')),
                          ],
                        ),
                      )
                    : hasError
                        ? Container(
                            padding: EdgeInsets.all(
                              EditarProductoStyles.mediumSpacing(context),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: EditarProductoStyles.errorColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        provider.errorMessage ??
                                            'Error cargando categorías',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: () => provider.inicializar(),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Reintentar'),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            value: categoriaSeleccionada,
                            style: EditarProductoStyles.fieldText(context)
                                .copyWith(color: Colors.black),
                            decoration: EditarProductoStyles.dropdownDecoration(
                              context: context,
                              hintText: 'Seleccionar categoría',
                              prefixIcon: Icons.category_outlined,
                            ),
                            items: categorias.map((cat) {
                              return DropdownMenuItem<Map<String, dynamic>>(
                                value: cat,
                                child: Text(cat['nombre']),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() {
                                categoriaSeleccionada = val;
                                _hasUnsavedChanges = true;
                              });
                            },
                            validator: (val) =>
                                val == null ? 'Campo obligatorio' : null,
                            isExpanded: true,
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

 
  Widget _buildImageSelector() {
    // ✅ Altura fija más razonable para la imagen
    final imageHeight = _showPreview ? 250.0 : 180.0;

    return Container(
      margin: EdgeInsets.only(
        bottom: EditarProductoStyles.getResponsiveSize(context, 20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Imagen del producto',
                  style: EditarProductoStyles.fieldLabel(context),
                ),
              ),
              if (imagenSeleccionada != null || producto?['imagen'] != null)
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showPreview = !_showPreview);
                  },
                  icon: Icon(
                    _showPreview ? Icons.visibility_off : Icons.visibility,
                    size: EditarProductoStyles.smallIconSize(context),
                  ),
                  label: Text(
                    _showPreview ? 'Ocultar' : 'Vista previa',
                    style: TextStyle(
                      fontSize: EditarProductoStyles.getResponsiveSize(context, 12),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: EditarProductoStyles.primaryColor,
                  ),
                ),
            ],
          ),
          SizedBox(height: EditarProductoStyles.smallSpacing(context)),
          GestureDetector(
            onTap: seleccionarImagen,
            child: AnimatedContainer(
              duration: EditarProductoStyles.mediumAnimationDuration,
              height: imageHeight,
              width: double.infinity,
              decoration: EditarProductoStyles.imageContainerDecoration(
                hasImage: imagenSeleccionada != null || producto?['imagen'] != null,
              ),
              child: imagenSeleccionada != null
                  ? EditarProductoWidgets.buildImagePreview(
                      context: context,
                      image: Image.file(imagenSeleccionada!, fit: BoxFit.cover),
                      onEdit: seleccionarImagen,
                      onDelete: () {
                        setState(() {
                          imagenSeleccionada = null;
                          _hasUnsavedChanges = true;
                        });
                        HapticFeedback.lightImpact();
                      },
                      showPreview: _showPreview,
                      isNewImage: true,
                    )
                  : (producto?['imagen'] != null
                      ? EditarProductoWidgets.buildImagePreview(
                          context: context,
                          image: Image.network(
                            producto!['imagen'],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 40,
                                      color: EditarProductoStyles.errorColor,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text('Error cargando imagen'),
                                  ],
                                ),
                              );
                            },
                          ),
                          onEdit: seleccionarImagen,
                          onDelete: () {
                            setState(() {
                              imagenSeleccionada = null;
                              _hasUnsavedChanges = true;
                            });
                            HapticFeedback.lightImpact();
                          },
                          showPreview: _showPreview,
                          isNewImage: false,
                        )
                      : EditarProductoWidgets.buildImagePlaceholder(context)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Consumer<ProductoProvider>(
      builder: (context, provider, child) {
        final isProviderUpdating = provider.isUpdating;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(
                top: EditarProductoStyles.mediumSpacing(context),
                bottom: EditarProductoStyles.mediumSpacing(context) / 1.5,
              ),
              child: SizedBox(
                width: double.infinity,
                height: EditarProductoStyles.getResponsiveSize(context, 56),
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: (_isUpdating || isProviderUpdating)
                          ? _pulseAnimation.value
                          : 1.0,
                      child: ElevatedButton(
                        onPressed: (_isUpdating || isProviderUpdating)
                            ? null
                            : actualizarProducto,
                        style: EditarProductoStyles.primaryButtonStyle(
                          context,
                          isLoading: _isUpdating || isProviderUpdating,
                        ),
                        child: (_isUpdating || isProviderUpdating)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Actualizando producto...',
                                    style:
                                        EditarProductoStyles.buttonText(context),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.save_outlined,
                                    size: EditarProductoStyles.largeIconSize(
                                        context),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Actualizar Producto',
                                    style:
                                        EditarProductoStyles.buttonText(context),
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
                  onPressed: (_isUpdating || isProviderUpdating)
                      ? null
                      : () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: EditarProductoStyles.dialogShape,
                              title: const Text('¿Descartar cambios?'),
                              content: const Text(
                                  'Se perderán todos los cambios no guardados.'),
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
                    size: EditarProductoStyles.smallIconSize(context),
                  ),
                  label: const Text('Descartar cambios'),
                  style: EditarProductoStyles.secondaryButtonStyle(context),
                ),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProduct) {
      return Scaffold(
        backgroundColor: EditarProductoStyles.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Editar Producto',
            style: EditarProductoStyles.appBarTitle(context),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: EditarProductoStyles.textPrimaryColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: EditarProductoStyles.borderColor),
          ),
        ),
        body: SafeArea(
          child: EditarProductoWidgets.buildLoadingScreen(context),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: EditarProductoStyles.backgroundColor,
        appBar: AppBar(
          title: Text(
            'Editar Producto',
            style: EditarProductoStyles.appBarTitle(context),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: EditarProductoStyles.textPrimaryColor,
          elevation: 0,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: EditarProductoStyles.borderColor),
          ),
          actions: [
            if (_hasUnsavedChanges)
              EditarProductoWidgets.buildUnsavedChangesBadge(context),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: EditarProductoStyles.dialogShape,
                    title: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          color: EditarProductoStyles.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Flexible(child: Text('Ayuda')),
                      ],
                    ),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• Todos los campos marcados con * son obligatorios',
                          style: EditarProductoStyles.helpText(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• La imagen es opcional pero recomendada',
                          style: EditarProductoStyles.helpText(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• El precio debe ser mayor a 0',
                          style: EditarProductoStyles.helpText(context),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Los cambios se detectan automáticamente',
                          style: EditarProductoStyles.helpText(context),
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
                size: EditarProductoStyles.largeIconSize(context),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EditarProductoStyles.getResponsivePadding(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EditarProductoWidgets.buildSectionHeader(
                    context,
                    'Información Básica',
                    Icons.info_outline,
                    _slideAnimation,
                  ),
                  _buildImageSelector(),
                  EditarProductoWidgets.buildTextField(
                    context: context,
                    label: 'Nombre del producto',
                    controller: nombreController,
                    focusNode: nombreFocus,
                    onChanged: () => setState(() {}),
                    icon: Icons.inventory_2_outlined,
                    hint: 'Ej: Camiseta básica de algodón',
                    nextFocus: descripcionFocus,
                    validator: _validateField,
                  ),
                  EditarProductoWidgets.buildTextField(
                    context: context,
                    label: 'Descripción',
                    controller: descripcionController,
                    focusNode: descripcionFocus,
                    onChanged: () => setState(() {}),
                    icon: Icons.description_outlined,
                    maxLines: 3,
                    hint: 'Describe las características, materiales, etc...',
                    nextFocus: precioFocus,
                    validator: _validateField,
                  ),
                  _buildCategorySelector(),
                  EditarProductoWidgets.buildDropdownField<String>(
                    context: context,
                    label: 'Subcategoría',
                    value: subcategoriaSeleccionada,
                    items: subcategorias
                        .map((sub) => DropdownMenuItem<String>(
                              value: sub.toLowerCase(),
                              child: Text(sub),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => subcategoriaSeleccionada = val),
                    icon: Icons.category,
                    hint: 'Seleccionar subcategoría',
                  ),
                  EditarProductoWidgets.buildSectionHeader(
                    context,
                    'Información Comercial',
                    Icons.attach_money_outlined,
                    _slideAnimation,
                  ),
                  EditarProductoWidgets.buildTextField(
                    context: context,
                    label: 'Precio',
                    controller: precioController,
                    focusNode: precioFocus,
                    onChanged: () => setState(() {}),
                    icon: Icons.payments_outlined,
                    tipo: TextInputType.number,
                    hint: 'Ej: 25000',
                    nextFocus: stockFocus,
                    validator: _validateField,
                  ),
                  EditarProductoWidgets.buildTextField(
                    context: context,
                    label: 'Stock disponible',
                    controller: stockController,
                    focusNode: stockFocus,
                    onChanged: () => setState(() {}),
                    icon: Icons.inventory_outlined,
                    tipo: TextInputType.number,
                    obligatorio: false,
                    hint: 'Cantidad disponible (opcional)',
                    validator: _validateField,
                  ),
                  EditarProductoWidgets.buildSectionHeader(
                    context,
                    'Configuración',
                    Icons.settings_outlined,
                    _slideAnimation,
                  ),
                  EditarProductoWidgets.buildQuickStats(
                    context: context,
                    estadoSeleccionado: estadoSeleccionado,
                    disponible: disponible,
                    stock: stockController.text.isEmpty ? '0' : stockController.text,
                  ),
                  EditarProductoWidgets.buildStatusSwitch(
                    context: context,
                    disponible: disponible,
                    onChanged: (val) {
                      setState(() {
                        disponible = val;
                        _hasUnsavedChanges = true;
                      });
                    },
                  ),
                  EditarProductoWidgets.buildDropdownField<String>(
                    context: context,
                    label: 'Estado del producto',
                    value: estadoSeleccionado,
                    items: estados
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Row(
                                children: [
                                  Container(
                                    width: EditarProductoStyles.smallSpacing(context),
                                    height: EditarProductoStyles.smallSpacing(context),
                                    decoration: BoxDecoration(
                                      color: EditarProductoStyles.getStatusColor(e),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  SizedBox(width: EditarProductoStyles.smallSpacing(context)),
                                  Text(e.toUpperCase()),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        estadoSeleccionado = val;
                        _hasUnsavedChanges = true;
                      });
                    },
                    icon: Icons.toggle_on_outlined,
                    hint: 'Seleccionar estado',
                  ),
                  _buildActionButtons(),
                  SizedBox(height: EditarProductoStyles.mediumSpacing(context)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}