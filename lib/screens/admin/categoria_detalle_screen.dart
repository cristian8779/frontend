import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/categoria_service.dart';
import '../../models/categoria.dart';

class CategoriaDetalleScreen extends StatefulWidget {
  final Categoria categoria;

  const CategoriaDetalleScreen({
    super.key,
    required this.categoria,
  });

  @override
  State<CategoriaDetalleScreen> createState() => _CategoriaDetalleScreenState();
}

class _CategoriaDetalleScreenState extends State<CategoriaDetalleScreen>
    with TickerProviderStateMixin {
  late TextEditingController nombreController;
  late TextEditingController descripcionController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  bool habilitarEdicion = false;
  bool procesando = false;
  bool _hasChanges = false;

  File? _imagenLocal;
  String? _imagenInternet;

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.categoria.nombre);
    descripcionController = TextEditingController(text: widget.categoria.descripcion);
    _imagenInternet = widget.categoria.imagen;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _animationController.forward();
    
    // Listeners para detectar cambios
    nombreController.addListener(_checkForChanges);
    descripcionController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    nombreController.dispose();
    descripcionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasTextChanges = nombreController.text != widget.categoria.nombre ||
        descripcionController.text != widget.categoria.descripcion;
    final hasImageChanges = _imagenLocal != null;
    
    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  Future<void> eliminarCategoria() async {
    final confirmed = await _showConfirmationDialog(
      title: '¿Eliminar categoría?',
      content: 'Esta acción no se puede deshacer. Todos los datos de "${widget.categoria.nombre}" se perderán permanentemente.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      isDestructive: true,
    );

    if (confirmed == true) {
      setState(() => procesando = true);
      final service = CategoriaService();

      try {
        final ok = await service.eliminarCategoria(widget.categoria.id);
        setState(() => procesando = false);

        if (ok) {
          await _showSuccessDialog(
            title: "¡Categoría eliminada!",
            message: "La categoría ha sido eliminada exitosamente.",
            icon: Icons.check_circle_outline,
          );
          if (mounted) Navigator.of(context).pop(true);
        } else {
          _showErrorDialog("No se pudo eliminar la categoría. Inténtalo de nuevo.");
        }
      } catch (e) {
        setState(() => procesando = false);
        _showErrorDialog("Error: ${e.toString()}");
      }
    }
  }

  Future<void> actualizarCategoria() async {
    if (!_validateInputs()) return;
    
    setState(() => procesando = true);
    final service = CategoriaService();

    try {
      final updated = await service.actualizarCategoria(
        id: widget.categoria.id,
        nombre: nombreController.text,
        descripcion: descripcionController.text,
        imagenLocal: _imagenLocal,
      );

      setState(() => procesando = false);

      if (updated.isNotEmpty) {
        setState(() {
          habilitarEdicion = false;
          _hasChanges = false;
          if (_imagenLocal != null) {
            _imagenInternet = null;
          }
        });
        
        await _showSuccessDialog(
          title: "¡Categoría actualizada!",
          message: "Los cambios se han guardado exitosamente.",
          icon: Icons.check_circle_outline,
        );
      } else {
        throw Exception("No se recibió respuesta del servidor");
      }
    } catch (e) {
      setState(() => procesando = false);
      _showErrorDialog("Error al actualizar: ${e.toString()}");
    }
  }

  bool _validateInputs() {
    if (nombreController.text.trim().isEmpty) {
      _showErrorDialog("El nombre de la categoría es obligatorio");
      return false;
    }
    return true;
  }

  Future<bool?> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    required String cancelText,
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              isDestructive ? Icons.warning_amber : Icons.help_outline,
              color: isDestructive ? Colors.orange : Colors.blue,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(color: Colors.grey[700], height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Error',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('Aceptar'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    // Mostrar loader mientras se abre la galería
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      // Cerrar loader
      Navigator.of(context).pop();

      if (pickedFile != null) {
        setState(() {
          _imagenLocal = File(pickedFile.path);
          _imagenInternet = null;
        });
        _checkForChanges();
        
        // Mostrar confirmación visual
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Imagen seleccionada correctamente'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Cerrar loader si hay error
      Navigator.of(context).pop();
      _showErrorDialog("Error al seleccionar imagen: ${e.toString()}");
    }
  }

  Future<bool> _onWillPop() async {
    if (habilitarEdicion && _hasChanges) {
      final shouldDiscard = await _showConfirmationDialog(
        title: '¿Descartar cambios?',
        content: 'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
        confirmText: 'Descartar',
        cancelText: 'Continuar editando',
        isDestructive: true,
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
                  onPressed: () async {
                    if (await _onWillPop()) {
                      Navigator.pop(context);
                    }
                  },
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    habilitarEdicion ? 'Editando categoría' : 'Detalle de categoría',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  centerTitle: true,
                ),
                actions: [
                  if (habilitarEdicion && _hasChanges)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.save, color: Colors.orange, size: 20),
                        ),
                        onPressed: procesando ? null : actualizarCategoria,
                      ),
                    ),
                  IconButton(
                    icon: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: habilitarEdicion
                            ? Colors.green.withOpacity(0.1)
                            : Colors.blue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        habilitarEdicion ? Icons.check : Icons.edit,
                        color: habilitarEdicion ? Colors.green : Colors.blue,
                        size: 20,
                      ),
                    ),
                    onPressed: procesando
                        ? null
                        : () async {
                            if (habilitarEdicion && _hasChanges) {
                              final shouldSave = await _showConfirmationDialog(
                                title: '¿Guardar cambios?',
                                content: 'Tienes cambios sin guardar. ¿Quieres guardarlos antes de salir del modo edición?',
                                confirmText: 'Guardar',
                                cancelText: 'Descartar',
                              );
                              if (shouldSave == true) {
                                await actualizarCategoria();
                              } else {
                                setState(() {
                                  habilitarEdicion = false;
                                  _hasChanges = false;
                                  nombreController.text = widget.categoria.nombre;
                                  descripcionController.text = widget.categoria.descripcion;
                                  _imagenLocal = null;
                                  _imagenInternet = widget.categoria.imagen;
                                });
                              }
                            } else {
                              setState(() {
                                habilitarEdicion = !habilitarEdicion;
                              });
                            }
                          },
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.black87),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            SizedBox(width: 8),
                            Text('Eliminar categoría'),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        eliminarCategoria();
                      }
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildImageSection(),
                      const SizedBox(height: 32),
                      _buildFormSection(),
                      const SizedBox(height: 32),
                      if (procesando) _buildLoadingSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.image, color: Colors.blue, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Imagen de la categoría',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: habilitarEdicion ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                habilitarEdicion ? 'Toca para cambiar' : 'Solo lectura',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: habilitarEdicion ? Colors.orange : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: habilitarEdicion ? seleccionarImagen : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: habilitarEdicion
                  ? Border.all(color: Colors.blue.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _imagenLocal != null
                      ? Image.file(
                          _imagenLocal!,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : _imagenInternet != null && _imagenInternet!.isNotEmpty
                          ? Image.network(
                              _imagenInternet!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return const Center(child: CircularProgressIndicator());
                              },
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                ),
                if (habilitarEdicion)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withOpacity(0.05),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.photo_library, color: Colors.blue, size: 24),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Toca para cambiar',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[100]!,
            Colors.grey[200]!,
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 12),
          Text(
            'Sin imagen',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (habilitarEdicion) ...[
            const SizedBox(height: 8),
            Text(
              'Toca para seleccionar',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Información de la categoría',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: nombreController,
            label: 'Nombre de la categoría',
            icon: Icons.category_outlined,
            enabled: habilitarEdicion,
            validator: (value) => value?.isEmpty ?? true ? 'Campo obligatorio' : null,
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: descripcionController,
            label: 'Descripción (opcional)',
            icon: Icons.description_outlined,
            enabled: habilitarEdicion,
            maxLines: 3,
          ),
          if (habilitarEdicion && _hasChanges) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tienes cambios sin guardar. No olvides presionar "Guardar cambios".',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: TextStyle(
          color: enabled ? Colors.black87 : Colors.grey[600],
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.blue : Colors.grey[500],
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.blue : Colors.grey[400],
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          suffixIcon: enabled && controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[400], size: 20),
                onPressed: () {
                  controller.clear();
                  _checkForChanges();
                },
              )
            : null,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: (_hasChanges && !procesando) ? actualizarCategoria : null,
        icon: procesando 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save),
        label: Text(
          procesando ? 'Guardando...' : 'Guardar cambios',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: _hasChanges ? Colors.blue : Colors.grey[300],
          foregroundColor: _hasChanges ? Colors.white : Colors.grey[600],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: _hasChanges ? 4 : 0,
          shadowColor: Colors.blue.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildLoadingSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Procesando...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}