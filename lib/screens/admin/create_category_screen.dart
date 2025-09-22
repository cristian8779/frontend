import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../providers/categoria_admin_provider.dart';
import '../../providers/auth_provider.dart';

class CreateCategoryScreen extends StatefulWidget {
  const CreateCategoryScreen({super.key});

  @override
  State<CreateCategoryScreen> createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  final _nombreController = TextEditingController();
  String? _errorNombre;

  File? _imagenLocal;

  final Color _colorPrimario = const Color(0xFF4A4A4A);
  final Color _appBarColor = const Color(0xFFFDFDFD);
  final Color _fondoClaro = const Color(0xFFF8F8F8);

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

  Future<void> _seleccionarDesdeGaleria() async {
    final picker = ImagePicker();
    final seleccion = await picker.pickImage(source: ImageSource.gallery);
    if (seleccion != null) {
      setState(() {
        _imagenLocal = File(seleccion.path);
      });
    }
  }

  Widget _buildContenedorImagen() {
    return GestureDetector(
      onTap: _seleccionarDesdeGaleria,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: _imagenLocal != null
              ? Image.file(_imagenLocal!, fit: BoxFit.contain)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 60, color: Colors.grey[400]),
                    const SizedBox(height: 10),
                    Text(
                      'Toca para agregar imagen',
                      style: TextStyle(color: Colors.grey[600]),
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

    // 🎯 USAR EL PROVIDER EN LUGAR DEL SERVICE DIRECTO
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
            Navigator.pop(context); // Cierra el diálogo
            Navigator.pop(context, true); // Devuelve "true"
          },
        );
      } else {
        // El error ya está manejado en el provider
        final errorMessage = categoriasProvider.errorMessage ?? 'Error desconocido';
        _mostrarErrorToast("❌ $errorMessage");
      }
    } catch (e) {
      _mostrarErrorToast("❌ Ocurrió un error inesperado: ${e.toString()}");
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
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
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
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Lottie.asset(
              tipoAnimacion ?? 'assets/animations/Success.json',
              width: 100,
              height: 100,
              fit: BoxFit.fill,
            ),
            Text(mensaje),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        // 🎯 USAR EL ESTADO DEL PROVIDER PARA MOSTRAR LOADING
        final isCreating = categoriasProvider.isCreating;

        return Scaffold(
          backgroundColor: _fondoClaro,
          appBar: AppBar(
            title: const Text(
              'Crear Categoría',
              style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
            ),
            centerTitle: true,
            backgroundColor: _appBarColor,
            iconTheme: const IconThemeData(color: Colors.black87),
            elevation: 1,
          ),
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Imagen de la categoría',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    _buildContenedorImagen(),
                    const SizedBox(height: 30),
                    TextField(
                      controller: _nombreController,
                      enabled: !isCreating, // 🎯 DESHABILITAR DURANTE CREACIÓN
                      decoration: _inputDecoration('Nombre de la categoría', Icons.category)
                          .copyWith(errorText: _errorNombre),
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: isCreating
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          isCreating ? 'Creando...' : 'Crear Categoría',
                          style: const TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _colorPrimario,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isCreating ? null : _crearCategoria,
                      ),
                    ),
                  ],
                ),
              ),
              
              // 🎯 OVERLAY DE LOADING OPCIONAL (si quieres bloquear toda la pantalla)
              if (isCreating)
                Container(
                  color: Colors.black26,
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Creando categoría...'),
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

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}