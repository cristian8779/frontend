import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_admin_provider.dart';
import '../../models/categoria.dart';
import '../../providers/auth_provider.dart';
import 'styles/categoria_detalle/categoria_detalle_styles.dart';

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
              color: isDestructive ? CategoriaDetalleStyles.warningColor : CategoriaDetalleStyles.primaryColor,
              size: CategoriaDetalleStyles.iconSize(context) + 4,
            ),
            CategoriaDetalleStyles.horizontalSpaceMedium(context),
            Expanded(
              child: Text(
                title,
                style: CategoriaDetalleStyles.dialogTitleStyle(context),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: CategoriaDetalleStyles.bodyTextStyle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              cancelText,
              style: CategoriaDetalleStyles.buttonTextStyle(context).copyWith(
                color: CategoriaDetalleStyles.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive 
              ? CategoriaDetalleStyles.destructiveButtonStyle(context)
              : CategoriaDetalleStyles.primaryButtonStyle(context),
            child: Text(
              confirmText,
              style: CategoriaDetalleStyles.buttonTextStyle(context),
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
              padding: CategoriaDetalleStyles.dialogPadding(context),
              decoration: CategoriaDetalleStyles.circleBadgeDecoration(
                CategoriaDetalleStyles.successColor
              ),
              child: Icon(
                icon,
                color: CategoriaDetalleStyles.successColor,
                size: CategoriaDetalleStyles.loadingIndicatorSize(context),
              ),
            ),
            CategoriaDetalleStyles.verticalSpaceMedium(context),
            Text(
              title,
              style: CategoriaDetalleStyles.dialogTitleStyle(context),
              textAlign: TextAlign.center,
            ),
            CategoriaDetalleStyles.verticalSpaceSmall(context),
            Text(
              message,
              style: CategoriaDetalleStyles.bodyTextStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: onAccept ?? () => Navigator.pop(context),
              style: CategoriaDetalleStyles.successButtonStyle(context),
              child: Text(
                'Aceptar',
                style: CategoriaDetalleStyles.buttonTextStyle(context),
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
              padding: CategoriaDetalleStyles.dialogPadding(context),
              decoration: CategoriaDetalleStyles.circleBadgeDecoration(
                CategoriaDetalleStyles.errorColor
              ),
              child: Icon(
                Icons.error_outline,
                color: CategoriaDetalleStyles.errorColor,
                size: CategoriaDetalleStyles.loadingIndicatorSize(context),
              ),
            ),
            CategoriaDetalleStyles.verticalSpaceMedium(context),
            Text(
              'Error',
              style: CategoriaDetalleStyles.dialogTitleStyle(context),
              textAlign: TextAlign.center,
            ),
            CategoriaDetalleStyles.verticalSpaceSmall(context),
            Text(
              message,
              style: CategoriaDetalleStyles.bodyTextStyle(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: CategoriaDetalleStyles.errorButtonStyle(context),
              child: Text(
                'Aceptar',
                style: CategoriaDetalleStyles.buttonTextStyle(context),
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
                Icon(
                  Icons.check_circle,
                  color: CategoriaDetalleStyles.whiteColor,
                  size: CategoriaDetalleStyles.iconSize(context),
                ),
                CategoriaDetalleStyles.horizontalSpaceSmall(context),
                Flexible(
                  child: Text(
                    'Imagen seleccionada correctamente',
                    style: CategoriaDetalleStyles.buttonTextStyle(context),
                  ),
                ),
              ],
            ),
            backgroundColor: CategoriaDetalleStyles.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: CategoriaDetalleStyles.snackBarMargin(context),
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
            backgroundColor: CategoriaDetalleStyles.backgroundColor,
            body: Stack(
              children: [
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(isProcessing),
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: CategoriaDetalleStyles.maxContentWidth(context)
                            ),
                            child: Padding(
                              padding: CategoriaDetalleStyles.responsivePadding(context),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildImageSection(isProcessing),
                                  CategoriaDetalleStyles.verticalSpaceLarge(context),
                                  _buildFormSection(isProcessing),
                                  CategoriaDetalleStyles.verticalSpaceLarge(context),
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

  Widget _buildAppBar(bool isProcessing) {
    return SliverAppBar(
      expandedHeight: CategoriaDetalleStyles.appBarExpandedHeight(context),
      floating: false,
      pinned: true,
      backgroundColor: CategoriaDetalleStyles.whiteColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: CategoriaDetalleStyles.textPrimary,
          size: CategoriaDetalleStyles.iconSize(context),
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
          style: CategoriaDetalleStyles.appBarTitleStyle(context),
          overflow: TextOverflow.fade,
          softWrap: false,
        ),
        centerTitle: true,
      ),
      actions: [
        if (habilitarEdicion && _hasChanges)
          Container(
            margin: EdgeInsets.only(
              right: CategoriaDetalleStyles.isSmallScreen(context) ? 4 : 
                    (CategoriaDetalleStyles.isTablet(context) ? 12 : 8)
            ),
            child: IconButton(
              icon: Container(
                padding: CategoriaDetalleStyles.buttonIconPadding(context),
                decoration: CategoriaDetalleStyles.circleBadgeDecoration(
                  CategoriaDetalleStyles.warningColor
                ),
                child: Icon(
                  Icons.save,
                  color: CategoriaDetalleStyles.warningColor,
                  size: CategoriaDetalleStyles.iconSize(context),
                ),
              ),
              onPressed: isProcessing ? null : actualizarCategoria,
            ),
          ),
        IconButton(
          icon: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: CategoriaDetalleStyles.buttonIconPadding(context),
            decoration: CategoriaDetalleStyles.circleBadgeDecoration(
              habilitarEdicion 
                ? CategoriaDetalleStyles.successColor 
                : CategoriaDetalleStyles.primaryColor
            ),
            child: Icon(
              habilitarEdicion ? Icons.check : Icons.edit,
              color: habilitarEdicion 
                ? CategoriaDetalleStyles.successColor 
                : CategoriaDetalleStyles.primaryColor,
              size: CategoriaDetalleStyles.iconSize(context),
            ),
          ),
          onPressed: isProcessing ? null : () async {
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
            color: CategoriaDetalleStyles.textPrimary,
            size: CategoriaDetalleStyles.iconSize(context),
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
                    color: CategoriaDetalleStyles.errorColor,
                    size: CategoriaDetalleStyles.iconSize(context),
                  ),
                  CategoriaDetalleStyles.horizontalSpaceSmall(context),
                  Flexible(
                    child: Text(
                      'Eliminar categoría',
                      style: CategoriaDetalleStyles.buttonTextStyle(context),
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
    );
  }

  Widget _buildLoadingOverlay(bool isProcessing, String loadingMessage) {
    return Visibility(
      visible: isProcessing,
      child: Container(
        color: Colors.black.withOpacity(0.6),
        child: Center(
          child: Container(
            padding: CategoriaDetalleStyles.loadingOverlayPadding(context),
            margin: CategoriaDetalleStyles.loadingOverlayMargin(context),
            decoration: CategoriaDetalleStyles.loadingOverlayDecoration(context),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    CategoriaDetalleStyles.isSmallScreen(context) ? 12 : 
                    (CategoriaDetalleStyles.isTablet(context) ? 16 : 14)
                  ),
                  decoration: CategoriaDetalleStyles.circleBadgeDecoration(
                    CategoriaDetalleStyles.primaryColor
                  ),
                  child: SizedBox(
                    width: CategoriaDetalleStyles.loadingIndicatorSize(context),
                    height: CategoriaDetalleStyles.loadingIndicatorSize(context),
                    child: CircularProgressIndicator(
                      strokeWidth: CategoriaDetalleStyles.loadingIndicatorStrokeWidth(context),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        CategoriaDetalleStyles.primaryColor
                      ),
                    ),
                  ),
                ),
                CategoriaDetalleStyles.verticalSpaceMedium(context),
                Text(
                  loadingMessage.isNotEmpty ? loadingMessage : 'Procesando...',
                  style: CategoriaDetalleStyles.titleStyle(context),
                  textAlign: TextAlign.center,
                ),
                SizedBox(
                  height: CategoriaDetalleStyles.isSmallScreen(context) ? 8 : 
                         (CategoriaDetalleStyles.isTablet(context) ? 12 : 10)
                ),
                Text(
                  'Por favor espera un momento...',
                  style: CategoriaDetalleStyles.bodyTextStyle(context),
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
                Icon(
                  Icons.image,
                  color: CategoriaDetalleStyles.primaryColor,
                  size: CategoriaDetalleStyles.iconSize(context),
                ),
                CategoriaDetalleStyles.horizontalSpaceSmall(context),
                Flexible(
                  child: Text(
                    'Imagen de la categoría',
                    style: CategoriaDetalleStyles.titleStyle(context),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            CategoriaDetalleStyles.isSmallScreen(context)
              ? CategoriaDetalleStyles.verticalSpaceSmall(context)
              : const SizedBox.shrink(),
            if (CategoriaDetalleStyles.isSmallScreen(context))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: CategoriaDetalleStyles.badgeDecoration(
                  context,
                  habilitarEdicion 
                    ? CategoriaDetalleStyles.warningColor 
                    : Colors.grey
                ),
                child: Text(
                  habilitarEdicion ? 'Toca para cambiar' : 'Solo lectura',
                  style: CategoriaDetalleStyles.smallBadgeTextStyle(
                    context,
                    color: habilitarEdicion 
                      ? CategoriaDetalleStyles.warningColor 
                      : CategoriaDetalleStyles.textSecondary,
                  ),
                ),
              )
            else
              Row(
                children: [
                  SizedBox(
                    width: CategoriaDetalleStyles.iconSize(context) + 
                          (CategoriaDetalleStyles.isTablet(context) ? 12 : 8)
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: CategoriaDetalleStyles.isTablet(context) ? 12 : 8,
                      vertical: CategoriaDetalleStyles.isTablet(context) ? 6 : 4,
                    ),
                    decoration: CategoriaDetalleStyles.badgeDecoration(
                      context,
                      habilitarEdicion 
                        ? CategoriaDetalleStyles.warningColor 
                        : Colors.grey
                    ),
                    child: Text(
                      habilitarEdicion ? 'Toca para cambiar' : 'Solo lectura',
                      style: CategoriaDetalleStyles.badgeTextStyle(
                        context,
                        color: habilitarEdicion 
                          ? CategoriaDetalleStyles.warningColor 
                          : CategoriaDetalleStyles.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
        CategoriaDetalleStyles.verticalSpaceMedium(context),
      GestureDetector(
          onTap: (habilitarEdicion && !isProcessing) ? seleccionarImagen : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: CategoriaDetalleStyles.imageHeight(context),
            width: double.infinity,
            decoration: CategoriaDetalleStyles.imageContainerDecoration(
              context,
              habilitarEdicion
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(
                    CategoriaDetalleStyles.cardBorderRadius(context)
                  ),
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
                                return Center(
                                  child: SizedBox(
                                    width: CategoriaDetalleStyles.loadingIndicatorSize(context),
                                    height: CategoriaDetalleStyles.loadingIndicatorSize(context),
                                    child: const CircularProgressIndicator(),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) => 
                                _buildImagePlaceholder(),
                            )
                          : _buildImagePlaceholder(),
                ),
                if (habilitarEdicion && !isProcessing)
                  Positioned.fill(
                    child: Container(
                      decoration: CategoriaDetalleStyles.imageOverlayDecoration(context),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: CategoriaDetalleStyles.iconCirclePadding(context),
                            decoration: CategoriaDetalleStyles.iconCircleDecoration(context),
                            child: Icon(
                              Icons.photo_library,
                              color: CategoriaDetalleStyles.primaryColor,
                              size: CategoriaDetalleStyles.iconSize(context),
                            ),
                          ),
                          CategoriaDetalleStyles.verticalSpaceSmall(context),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: CategoriaDetalleStyles.isSmallScreen(context) ? 8 :
                                        (CategoriaDetalleStyles.isTablet(context) ? 16 : 12),
                              vertical: CategoriaDetalleStyles.isSmallScreen(context) ? 4 :
                                        (CategoriaDetalleStyles.isTablet(context) ? 8 : 6),
                            ),
                            decoration: BoxDecoration(
                              color: CategoriaDetalleStyles.whiteColor.withOpacity(0.95),
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
                                color: CategoriaDetalleStyles.primaryColor,
                                fontSize: CategoriaDetalleStyles.isSmallScreen(context) ? 11 :
                                         (CategoriaDetalleStyles.isTablet(context) ? 14 : 12),
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
        gradient: CategoriaDetalleStyles.placeholderGradient(),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_outlined,
            size: CategoriaDetalleStyles.placeholderIconSize(context),
            color: Colors.grey[400],
          ),
          CategoriaDetalleStyles.verticalSpaceSmall(context),
          Text(
            'Sin imagen',
            style: CategoriaDetalleStyles.placeholderTextStyle(context),
          ),
          if (habilitarEdicion) ...[
            CategoriaDetalleStyles.verticalSpaceSmall(context),
            Text(
              'Toca para seleccionar',
              style: CategoriaDetalleStyles.placeholderSubtitleStyle(context),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isProcessing) {
    return Container(
      padding: CategoriaDetalleStyles.cardPadding(context),
      decoration: CategoriaDetalleStyles.cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.edit_note,
                color: CategoriaDetalleStyles.primaryColor,
                size: CategoriaDetalleStyles.iconSize(context),
              ),
              CategoriaDetalleStyles.horizontalSpaceSmall(context),
              Flexible(
                child: Text(
                  'Información de la categoría',
                  style: CategoriaDetalleStyles.titleStyle(context),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(
            height: CategoriaDetalleStyles.isSmallScreen(context) ? 16 :
                   (CategoriaDetalleStyles.isTablet(context) ? 28 : 24)
          ),
          _buildTextField(
            controller: nombreController,
            label: 'Nombre de la categoría',
            icon: Icons.category_outlined,
            enabled: habilitarEdicion && !isProcessing,
          ),
          if (habilitarEdicion && _hasChanges && !isProcessing) ...[
            CategoriaDetalleStyles.verticalSpaceMedium(context),
            Container(
              padding: EdgeInsets.all(
                CategoriaDetalleStyles.isSmallScreen(context) ? 8 :
                (CategoriaDetalleStyles.isTablet(context) ? 16 : 12)
              ),
              decoration: BoxDecoration(
                color: CategoriaDetalleStyles.warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  CategoriaDetalleStyles.smallBorderRadius(context)
                ),
                border: Border.all(
                  color: CategoriaDetalleStyles.warningColor.withOpacity(0.3)
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: CategoriaDetalleStyles.warningColor,
                    size: CategoriaDetalleStyles.iconSize(context),
                  ),
                  CategoriaDetalleStyles.horizontalSpaceSmall(context),
                  Expanded(
                    child: Text(
                      'Tienes cambios sin guardar. No olvides presionar "Guardar cambios".',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: CategoriaDetalleStyles.isSmallScreen(context) ? 12 :
                                 (CategoriaDetalleStyles.isTablet(context) ? 15 : 13),
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
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        style: CategoriaDetalleStyles.textFieldStyle(context, enabled),
        decoration: CategoriaDetalleStyles.textFieldDecoration(
          context,
          label: label,
          icon: icon,
          enabled: enabled,
          suffixIcon: enabled && controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey[400],
                  size: CategoriaDetalleStyles.iconSize(context),
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