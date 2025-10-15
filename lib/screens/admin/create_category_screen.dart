import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../providers/categoria_admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'styles/crear_categoria/create_category_colors.dart';
import 'styles/crear_categoria/create_category_text_styles.dart';
import 'styles/crear_categoria/create_category_decorations.dart';
import 'styles/crear_categoria/create_category_dimensions.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _nombreController = TextEditingController();
  String? _errorNombre;
  File? _imagenLocal;

  @override
  void initState() {
    super.initState();

    _nombreController.addListener(() {
      setState(() {
        _errorNombre = _nombreController.text.trim().isEmpty
            ? '⚠️ Este campo es obligatorio'
            : null;
      });
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

 Future<File?> _compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,
    "${file.parent.path}/temp_${file.uri.pathSegments.last}",
    quality: 70,
  );

  if (result == null) return null;

  // 🔄 Convertir XFile a File
  return File(result.path);
}


  Future<void> _seleccionarDesdeGaleria() async {
    final picker = ImagePicker();
    final seleccion = await picker.pickImage(source: ImageSource.gallery);
    if (seleccion != null) {
      File original = File(seleccion.path);
      File? comprimida = await _compressImage(original);
      setState(() {
        _imagenLocal = comprimida ?? original;
      });
    }
  }

  Widget _buildContenedorImagen() {
    return GestureDetector(
      onTap: _seleccionarDesdeGaleria,
      child: Container(
        height: CreateCategoryDimensions.imageContainerHeight,
        width: double.infinity,
        decoration: CreateCategoryDecorations.imageContainer,
        child: ClipRRect(
          borderRadius: CreateCategoryDecorations.imageBorderRadius,
          child: _imagenLocal != null
              ? Image.file(_imagenLocal!, fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: CreateCategoryDimensions.iconSize,
                      color: CreateCategoryColors.gris400,
                    ),
                    CreateCategoryDimensions.spacingSmall,
                    Text(
                      'Toca para agregar imagen',
                      style: CreateCategoryTextStyles.imagePlaceholder,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _crearCategoria() async {
    setState(() {
      _errorNombre = _nombreController.text.trim().isEmpty
          ? '⚠️ Este campo es obligatorio'
          : null;
    });

    final camposValidos = _errorNombre == null;
    final imagenValida = _imagenLocal != null;

    if (!camposValidos || !imagenValida) {
      _mostrarErrorToast("❌ Por favor completa todos los campos y sube una imagen.");
      return;
    }

    final categoriasProvider = Provider.of<CategoriasProvider>(context, listen: false);

    try {
      final success = await categoriasProvider.crearCategoria(
        nombre: _nombreController.text.trim(),
        imagenLocal: _imagenLocal!,
      );

      if (success) {
        _mostrarDialogoConAnimacion(
          titulo: "¡Éxito!",
          mensaje: "Categoría creada correctamente.",
          tipoAnimacion: 'assets/animations/Success.json',
          onAceptar: () {
            Navigator.pop(context);
            Navigator.pop(context, true);
          },
        );
      } else {
        final errorMessage = categoriasProvider.errorMessage ?? 'Error desconocido';
        if (errorMessage.contains("413")) {
          _mostrarErrorToast("⚠️ La imagen es demasiado grande. Intenta con una más liviana.");
        } else {
          _mostrarErrorToast("❌ $errorMessage");
        }
      }
    } catch (e) {
      final msg = e.toString();
      if (msg.contains("413") || msg.contains("Request Entity Too Large")) {
        _mostrarErrorToast("⚠️ La imagen supera el tamaño permitido por el servidor. Comprime o usa una imagen más pequeña.");
      } else {
        _mostrarErrorToast("❌ Ocurrió un error inesperado: $msg");
      }
    }
  }

  Future<bool> _intentarRenovarToken() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final refreshToken = authProvider.refreshToken;

    if (refreshToken != null) {
      final tokenRenovado = await authProvider.renovarToken();
      if (tokenRenovado) {
        final nuevoToken = authProvider.token ?? '';
        if (nuevoToken.isNotEmpty) {
          setState(() {});
          return true;
        }
      } else {
        setState(() {
          _errorNombre = "❌ No se pudo renovar el token. Por favor, inicia sesión.";
        });
      }
    } else {
      setState(() {
        _errorNombre = "❌ No hay refresh token disponible. Por favor, inicia sesión.";
      });
    }

    return false;
  }

  void _mostrarErrorToast(String mensaje) {
    Fluttertoast.showToast(
      msg: mensaje,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: CreateCategoryColors.rojo,
      textColor: CreateCategoryColors.blanco,
      fontSize: CreateCategoryDimensions.fontSizeToast,
    );
  }

  void _mostrarDialogoConAnimacion({
    required String titulo,
    required String mensaje,
    String? tipoAnimacion,
    required VoidCallback onAceptar,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo, style: CreateCategoryTextStyles.dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              tipoAnimacion ?? 'assets/animations/Success.json',
              width: CreateCategoryDimensions.lottieSize,
              height: CreateCategoryDimensions.lottieSize,
              fit: BoxFit.fill,
            ),
            Text(mensaje),
          ],
        ),
        shape: CreateCategoryDecorations.dialogShape,
        actions: [
          TextButton(
            onPressed: onAceptar,
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CategoriasProvider>(
      builder: (context, categoriasProvider, child) {
        final isCreating = categoriasProvider.isCreating;

        return Scaffold(
          backgroundColor: CreateCategoryColors.fondoClaro,
          appBar: AppBar(
            title: Text(
              'Crear Categoría',
              style: CreateCategoryTextStyles.appBarTitle,
            ),
            centerTitle: true,
            backgroundColor: CreateCategoryColors.appBarColor,
            iconTheme: const IconThemeData(color: CreateCategoryColors.negro87),
            elevation: CreateCategoryDimensions.appBarElevation,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: CreateCategoryDimensions.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Imagen de la categoría',
                      style: CreateCategoryTextStyles.sectionTitle,
                    ),
                    CreateCategoryDimensions.spacingSmall,
                    _buildContenedorImagen(),
                    CreateCategoryDimensions.spacingLarge,
                    TextField(
                      controller: _nombreController,
                      enabled: !isCreating,
                      decoration: CreateCategoryDecorations.inputDecoration(
                        'Nombre de la categoría',
                        Icons.category,
                      ).copyWith(errorText: _errorNombre),
                    ),
                    CreateCategoryDimensions.spacingXLarge,
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isCreating
                            ? SizedBox(
                                width: CreateCategoryDimensions.loadingIndicatorSize,
                                height: CreateCategoryDimensions.loadingIndicatorSize,
                                child: const CircularProgressIndicator(
                                  color: CreateCategoryColors.blanco,
                                  strokeWidth: CreateCategoryDimensions.loadingStrokeWidth,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isCreating ? 'Creando...' : 'Crear Categoría',
                          style: CreateCategoryTextStyles.buttonText,
                        ),
                        style: CreateCategoryDecorations.primaryButtonStyle,
                        onPressed: isCreating ? null : _crearCategoria,
                      ),
                    ),
                  ],
                ),
              ),
              
              if (isCreating)
                Container(
                  color: CreateCategoryColors.negro26,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: CreateCategoryDimensions.cardPadding,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            CreateCategoryDimensions.spacingMedium,
                            Text(
                              'Creando categoría...',
                              style: CreateCategoryTextStyles.loadingText,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
