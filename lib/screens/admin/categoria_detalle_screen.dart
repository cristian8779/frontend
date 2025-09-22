import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_admin_provider.dart';
import '../../models/categoria.dart';
import '../../providers/auth_provider.dart';

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
  late AnimationController _animationController;
  late AnimationController _loadingAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _loadingScaleAnimation;
  
  bool habilitarEdicion = false;
  bool _hasChanges = false;

  File? _imagenLocal;
  String? _imagenInternet;

  bool get _isTablet => MediaQuery.of(context).size.width > 600;
  bool get _isDesktop => MediaQuery.of(context).size.width > 1200;
  bool get _isSmallScreen => MediaQuery.of(context).size.width < 360;
  double get _screenWidth => MediaQuery.of(context).size.width;

  double get _maxContentWidth {
    if (_isDesktop) return 800;
    if (_isTablet) return 600;
    return _screenWidth;
  }

  EdgeInsets get _responsivePadding {
    if (_isDesktop) return const EdgeInsets.all(32);
    if (_isTablet) return const EdgeInsets.all(24);
    if (_isSmallScreen) return const EdgeInsets.all(12);
    return const EdgeInsets.all(16);
  }

  double get _imageHeight {
    if (_isDesktop) return 300;
    if (_isTablet) return 250;
    if (_isSmallScreen) return 180;
    return 220;
  }

  double get _responsiveFontSize {
    if (_isTablet) return 20;
    if (_isSmallScreen) return 16;
    return 18;
  }

  double get _responsiveIconSize {
    if (_isTablet) return 28;
    if (_isSmallScreen) return 20;
    return 24;
  }

  @override
  void initState() {
    super.initState();
    nombreController = TextEditingController(text: widget.categoria.nombre);
    _imagenInternet = widget.categoria.imagen;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadingScaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _loadingAnimationController, curve: Curves.elasticOut),
    );
    
    _animationController.forward();
    nombreController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    nombreController.dispose();
    _animationController.dispose();
    _loadingAnimationController.dispose();
    super.dispose();
  }

  void _checkForChanges() {
    final hasTextChanges = nombreController.text != widget.categoria.nombre;
    final hasImageChanges = _imagenLocal != null;
    
    setState(() {
      _hasChanges = hasTextChanges || hasImageChanges;
    });
  }

  void _volverAControlPanel() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final rol = authProvider.rol ?? 'admin';
    
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/control-panel',
      (route) => false,
      arguments: {'rol': rol},
    );
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
      final categoriasProvider = Provider.of<CategoriasProvider>(context, listen: false);

      try {
        final success = await categoriasProvider.eliminarCategoria(widget.categoria.id);

        if (success) {
          await _showSuccessDialog(
            title: "¡Categoría eliminada!",
            message: "La categoría ha sido eliminada exitosamente.",
            icon: Icons.check_circle_outline,
            onAccept: () {
              Navigator.pop(context);
              _volverAControlPanel();
            }
          );
        } else {
          final errorMessage = categoriasProvider.errorMessage ?? 'Error desconocido al eliminar la categoría';
          // Si el mensaje ya tiene el emoji ❌, no lo agregamos de nuevo
          final mensajeFinal = errorMessage.startsWith('❌') ? errorMessage : '❌ $errorMessage';
          _showErrorDialog(mensajeFinal);
        }
      } catch (e) {
        _showErrorDialog("Error: ${e.toString()}");
      }
    }
  }

  Future<void> actualizarCategoria() async {
    if (!_validateInputs()) return;
    
    final categoriasProvider = Provider.of<CategoriasProvider>(context, listen: false);

    try {
      final success = await categoriasProvider.actualizarCategoria(
        id: widget.categoria.id,
        nombre: nombreController.text.trim(),
        imagenLocal: _imagenLocal,
      );

      if (success) {
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
          onAccept: () {
            Navigator.pop(context);
            _volverAControlPanel();
          }
        );
      } else {
        final errorMessage = categoriasProvider.errorMessage ?? 'Error desconocido';
        _showErrorDialog("Error al actualizar: $errorMessage");
      }
    } catch (e) {
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
              size: _responsiveIconSize + 4,
            ),
            SizedBox(width: _isTablet ? 16 : (_isSmallScreen ? 8 : 12)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: _responsiveFontSize + 2, 
                  fontWeight: FontWeight.w600
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(
            color: Colors.grey[700], 
            height: 1.4,
            fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? Colors.red : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: EdgeInsets.symmetric(
                horizontal: _isSmallScreen ? 12 : (_isTablet ? 24 : 16),
                vertical: _isSmallScreen ? 8 : (_isTablet ? 16 : 12),
              ),
            ),
            child: Text(
              confirmText,
              style: TextStyle(fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSuccessDialog({
    required String title,
    required String message,
    required IconData icon,
    VoidCallback? onAccept,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.green, size: _isSmallScreen ? 40 : (_isTablet ? 56 : 48)),
            ),
            SizedBox(height: _isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            Text(
              title,
              style: TextStyle(
                fontSize: _responsiveFontSize + 2, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600], 
                height: 1.4,
                fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: onAccept ?? () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                padding: EdgeInsets.symmetric(
                  horizontal: _isSmallScreen ? 24 : (_isTablet ? 40 : 32), 
                  vertical: _isSmallScreen ? 8 : (_isTablet ? 16 : 12)
                ),
              ),
              child: Text(
                'Aceptar',
                style: TextStyle(fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14)),
              ),
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
              padding: EdgeInsets.all(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: Colors.red, size: _isSmallScreen ? 40 : (_isTablet ? 56 : 48)),
            ),
            SizedBox(height: _isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            Text(
              'Error',
              style: TextStyle(
                fontSize: _responsiveFontSize + 2, 
                fontWeight: FontWeight.bold
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
            Text(
              message,
              style: TextStyle(
                color: Colors.grey[600], 
                height: 1.4,
                fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
              ),
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
                padding: EdgeInsets.symmetric(
                  horizontal: _isSmallScreen ? 24 : (_isTablet ? 40 : 32), 
                  vertical: _isSmallScreen ? 8 : (_isTablet ? 16 : 12)
                ),
              ),
              child: Text(
                'Aceptar',
                style: TextStyle(fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> seleccionarImagen() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imagenLocal = File(pickedFile.path);
          _imagenInternet = null;
        });
        _checkForChanges();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: _responsiveIconSize),
                SizedBox(width: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
                Flexible(
                  child: Text(
                    'Imagen seleccionada correctamente',
                    style: TextStyle(fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14)),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: EdgeInsets.all(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
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
    return Consumer<CategoriasProvider>(
      builder: (context, categoriasProvider, child) {
        final isProcessing = categoriasProvider.isUpdating || categoriasProvider.isDeleting;
        final loadingMessage = categoriasProvider.isUpdating 
            ? 'Guardando cambios...' 
            : categoriasProvider.isDeleting 
                ? 'Eliminando categoría...' 
                : '';

        return WillPopScope(
          onWillPop: _onWillPop,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8F9FA),
            body: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        expandedHeight: _isSmallScreen ? 100 : (_isTablet ? 140 : 120),
                        floating: false,
                        pinned: true,
                        backgroundColor: Colors.white,
                        elevation: 0,
                        leading: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios, 
                            color: Colors.black87,
                            size: _responsiveIconSize,
                          ),
                          onPressed: isProcessing ? null : () async {
                            if (await _onWillPop()) {
                              Navigator.pop(context, true);
                            }
                          },
                        ),
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            habilitarEdicion ? 'Editando categoría' : 'Detalle categoría',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: _isSmallScreen ? 14 : (_screenWidth < 350 ? 16 : (_isTablet ? 20 : 18)),
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                          centerTitle: true,
                        ),
                        actions: [
                          if (habilitarEdicion && _hasChanges)
                            Container(
                              margin: EdgeInsets.only(right: _isSmallScreen ? 4 : (_isTablet ? 12 : 8)),
                              child: IconButton(
                                icon: Container(
                                  padding: EdgeInsets.all(_isSmallScreen ? 4 : (_isTablet ? 8 : 6)),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.save, 
                                    color: Colors.orange, 
                                    size: _responsiveIconSize
                                  ),
                                ),
                                onPressed: isProcessing ? null : actualizarCategoria,
                              ),
                            ),
                          IconButton(
                            icon: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(_isSmallScreen ? 4 : (_isTablet ? 8 : 6)),
                              decoration: BoxDecoration(
                                color: habilitarEdicion
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                habilitarEdicion ? Icons.check : Icons.edit,
                                color: habilitarEdicion ? Colors.green : Colors.blue,
                                size: _responsiveIconSize,
                              ),
                            ),
                            onPressed: isProcessing
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
                            icon: Icon(
                              Icons.more_vert, 
                              color: Colors.black87,
                              size: _responsiveIconSize,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            enabled: !isProcessing,
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.delete_outline, 
                                      color: Colors.red, 
                                      size: _responsiveIconSize
                                    ),
                                    SizedBox(width: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
                                    Flexible(
                                      child: Text(
                                        'Eliminar categoría',
                                        style: TextStyle(fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14)),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
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
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: _maxContentWidth),
                            child: Padding(
                              padding: _responsivePadding,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageSection(isProcessing),
                                  SizedBox(height: _isSmallScreen ? 24 : (_isTablet ? 40 : 32)),
                                  _buildFormSection(isProcessing),
                                  SizedBox(height: _isSmallScreen ? 24 : (_isTablet ? 40 : 32)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildLoadingOverlay(isProcessing, loadingMessage),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay(bool isProcessing, String loadingMessage) {
    return Visibility(
      visible: isProcessing,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(_isSmallScreen ? 20 : (_isTablet ? 32 : 24)),
            margin: EdgeInsets.symmetric(horizontal: _isSmallScreen ? 24 : (_isTablet ? 40 : 32)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(_isSmallScreen ? 12 : (_isTablet ? 16 : 14)),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: _isSmallScreen ? 40 : (_isTablet ? 56 : 48),
                    height: _isSmallScreen ? 40 : (_isTablet ? 56 : 48),
                    child: CircularProgressIndicator(
                      strokeWidth: _isSmallScreen ? 3 : (_isTablet ? 5 : 4),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
                ),
                SizedBox(height: _isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
                Text(
                  loadingMessage.isNotEmpty ? loadingMessage : 'Procesando...',
                  style: TextStyle(
                    fontSize: _responsiveFontSize,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: _isSmallScreen ? 8 : (_isTablet ? 12 : 10)),
                Text(
                  'Por favor espera un momento...',
                  style: TextStyle(
                    fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection(bool isProcessing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.image, color: Colors.blue, size: _responsiveIconSize),
                SizedBox(width: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
                Flexible(
                  child: Text(
                    'Imagen de la categoría',
                    style: TextStyle(
                      fontSize: _responsiveFontSize, 
                      fontWeight: FontWeight.w600
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: _isSmallScreen ? 8 : 0),
            if (_isSmallScreen)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: habilitarEdicion ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  habilitarEdicion ? 'Toca para cambiar' : 'Solo lectura',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: habilitarEdicion ? Colors.orange : Colors.grey[600],
                  ),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(width: _responsiveIconSize + (_isTablet ? 12 : 8)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isTablet ? 12 : 8, 
                      vertical: _isTablet ? 6 : 4
                    ),
                    decoration: BoxDecoration(
                      color: habilitarEdicion ? Colors.orange.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      habilitarEdicion ? 'Toca para cambiar' : 'Solo lectura',
                      style: TextStyle(
                        fontSize: _isTablet ? 14 : 12,
                        fontWeight: FontWeight.w500,
                        color: habilitarEdicion ? Colors.orange : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        SizedBox(height: _isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
        GestureDetector(
          onTap: (habilitarEdicion && !isProcessing) ? seleccionarImagen : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _imageHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: _isSmallScreen ? 8 : (_isTablet ? 12 : 10),
                  offset: Offset(0, _isSmallScreen ? 3 : (_isTablet ? 6 : 4)),
                ),
              ],
              border: habilitarEdicion
                  ? Border.all(color: Colors.blue.withOpacity(0.3), width: 2)
                  : null,
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
                  child: _imagenLocal != null
                      ? Image.file(
                          _imagenLocal!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        )
                      : _imagenInternet != null && _imagenInternet!.isNotEmpty
                          ? Image.network(
                              _imagenInternet!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: SizedBox(
                                    width: _isSmallScreen ? 40 : (_isTablet ? 60 : 50),
                                    height: _isSmallScreen ? 40 : (_isTablet ? 60 : 50),
                                    child: const CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                ),
                if (habilitarEdicion && !isProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
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
                            padding: EdgeInsets.all(_isSmallScreen ? 10 : (_isTablet ? 16 : 12)),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(_isSmallScreen ? 20 : (_isTablet ? 30 : 25)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: _isSmallScreen ? 6 : (_isTablet ? 10 : 8),
                                  offset: Offset(0, _isSmallScreen ? 2 : (_isTablet ? 3 : 2)),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.photo_library, 
                              color: Colors.blue, 
                              size: _responsiveIconSize
                            ),
                          ),
                          SizedBox(height: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: _isSmallScreen ? 8 : (_isTablet ? 16 : 12), 
                              vertical: _isSmallScreen ? 4 : (_isTablet ? 8 : 6)
                            ),
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
                            child: Text(
                              'Toca para cambiar',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: _isSmallScreen ? 11 : (_isTablet ? 14 : 12),
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
            size: _isSmallScreen ? 48 : (_isTablet ? 80 : 64),
            color: Colors.grey[400],
          ),
          SizedBox(height: _isSmallScreen ? 8 : (_isTablet ? 16 : 12)),
          Text(
            'Sin imagen',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: _isSmallScreen ? 14 : (_isTablet ? 18 : 16),
              fontWeight: FontWeight.w500,
            ),
          ),
          if (habilitarEdicion) ...[
            SizedBox(height: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
            Text(
              'Toca para seleccionar',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: _isSmallScreen ? 12 : (_isTablet ? 16 : 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isProcessing) {
    return Container(
      padding: EdgeInsets.all(_isSmallScreen ? 16 : (_isTablet ? 28 : 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_isSmallScreen ? 16 : (_isTablet ? 24 : 20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: _isSmallScreen ? 8 : (_isTablet ? 12 : 10),
            offset: Offset(0, _isSmallScreen ? 3 : (_isTablet ? 6 : 4)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: Colors.blue, size: _responsiveIconSize),
              SizedBox(width: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
              Flexible(
                child: Text(
                  'Información de la categoría',
                  style: TextStyle(
                    fontSize: _responsiveFontSize, 
                    fontWeight: FontWeight.w600
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: _isSmallScreen ? 16 : (_isTablet ? 28 : 24)),
          _buildTextField(
            controller: nombreController,
            label: 'Nombre de la categoría',
            icon: Icons.category_outlined,
            enabled: habilitarEdicion && !isProcessing,
            validator: (value) => value?.isEmpty ?? true ? 'Campo obligatorio' : null,
          ),
          if (habilitarEdicion && _hasChanges && !isProcessing) ...[
            SizedBox(height: _isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            Container(
              padding: EdgeInsets.all(_isSmallScreen ? 8 : (_isTablet ? 16 : 12)),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(_isSmallScreen ? 12 : (_isTablet ? 16 : 12)),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: _responsiveIconSize),
                  SizedBox(width: _isSmallScreen ? 6 : (_isTablet ? 12 : 8)),
                  Expanded(
                    child: Text(
                      'Tienes cambios sin guardar. No olvides presionar "Guardar cambios".',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: _isSmallScreen ? 12 : (_isTablet ? 15 : 13),
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
          fontSize: _isSmallScreen ? 14 : (_isTablet ? 18 : 16),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: enabled ? Colors.blue : Colors.grey[500],
            fontSize: _isSmallScreen ? 13 : (_isTablet ? 16 : 14),
          ),
          prefixIcon: Icon(
            icon,
            color: enabled ? Colors.blue : Colors.grey[400],
            size: _responsiveIconSize,
          ),
          filled: true,
          fillColor: enabled ? Colors.white : Colors.grey[50],
          contentPadding: EdgeInsets.symmetric(
            horizontal: _isSmallScreen ? 12 : (_isTablet ? 20 : 16), 
            vertical: _isSmallScreen ? 14 : (_isTablet ? 22 : 18)
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_isSmallScreen ? 12 : (_isTablet ? 20 : 16)),
            borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
          ),
          suffixIcon: enabled && controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear, 
                  color: Colors.grey[400], 
                  size: _responsiveIconSize
                ),
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
}