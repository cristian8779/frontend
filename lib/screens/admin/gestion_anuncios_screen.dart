import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/anuncio_service.dart';
import '../../services/auth_service.dart';
import 'selector_visual_screen.dart';

class GestionAnunciosScreen extends StatefulWidget {
  const GestionAnunciosScreen({super.key});

  @override
  State<GestionAnunciosScreen> createState() => _GestionAnunciosScreenState();
}

class _GestionAnunciosScreenState extends State<GestionAnunciosScreen> {
  final _formKey = GlobalKey<FormState>();
  final AnuncioService _anuncioService = AnuncioService();

  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  String _tipo = 'producto';
  String? _idSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  File? _imagen;
  bool _isLoading = false;

  List<Map<String, dynamic>> _productos = [];
  List<Map<String, dynamic>> _categorias = [];
  bool _cargandoListas = true;

  final Color rojo = const Color(0xFFBE0C0C);

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    setState(() => _cargandoListas = true);
    try {
      final productos = await _anuncioService.obtenerProductos();
      final categorias = await _anuncioService.obtenerCategorias();
      setState(() {
        _productos = productos;
        _categorias = categorias;
        _cargandoListas = false;
      });
    } catch (e) {
      _mostrarToast("❌ Error al cargar datos: $e");
      setState(() => _cargandoListas = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _imagen = File(image.path));
  }

  Future<void> _seleccionarFecha(bool esInicio) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          _fechaInicioController.text = _formatearFecha(picked);
        } else {
          _fechaFin = picked;
          _fechaFinController.text = _formatearFecha(picked);
        }
      });
    }
  }

  String _formatearFecha(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// Ajusta la fecha para que sea medianoche en hora Colombia (UTC-5)
  DateTime ajustarColombia(DateTime date) {
    final fechaSolo = DateTime(date.year, date.month, date.day);
    return fechaSolo.subtract(const Duration(hours: 5));
  }

  Future<void> _abrirSelectorVisual() async {
    final seleccionado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SelectorVisualScreen(esProducto: _tipo == 'producto'),
      ),
    );

    if (seleccionado != null && seleccionado is Map<String, dynamic>) {
      setState(() => _idSeleccionado = seleccionado['_id'] ?? seleccionado['id']);
    }
  }

  Future<void> _crearAnuncio() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagen == null || _fechaInicio == null || _fechaFin == null || _idSeleccionado == null) {
      _mostrarToast('❗Todos los campos son obligatorios.');
      return;
    }

    setState(() => _isLoading = true);
    final accessToken = await AuthService().getAccessToken();

    if (accessToken == null) {
      _mostrarToast('❌ No se encontró token.');
      setState(() => _isLoading = false);
      return;
    }

    final exito = await _anuncioService.crearAnuncio(
      imagenPath: _imagen!.path,
      fechaInicio: ajustarColombia(_fechaInicio!).toIso8601String(),
      fechaFin: ajustarColombia(_fechaFin!).toIso8601String(),
      productoId: _tipo == 'producto' ? _idSeleccionado : null,
      categoriaId: _tipo == 'categoria' ? _idSeleccionado : null,
    );

    setState(() => _isLoading = false);

    if (exito) {
      _mostrarToast("✅ Anuncio creado");
      _resetForm();
    } else {
      _mostrarToast("❌ ${_anuncioService.message ?? 'Error al crear anuncio'}");
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    setState(() {
      _idSeleccionado = null;
      _imagen = null;
      _fechaInicio = null;
      _fechaFin = null;
      _fechaInicioController.clear();
      _fechaFinController.clear();
    });
  }

  void _mostrarToast(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
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

  @override
  Widget build(BuildContext context) {
    final lista = _tipo == 'producto' ? _productos : _categorias;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Crear anuncio"),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: _cargandoListas
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Imagen del anuncio',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _imagen != null
                              ? Image.file(_imagen!, fit: BoxFit.cover)
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image_outlined, size: 60, color: Colors.grey),
                                      Text('Seleccionar imagen', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _tipo,
                      items: const [
                        DropdownMenuItem(value: 'producto', child: Text("Producto")),
                        DropdownMenuItem(value: 'categoria', child: Text("Categoría")),
                      ],
                      onChanged: (v) => setState(() {
                        _tipo = v!;
                        _idSeleccionado = null;
                      }),
                      decoration: _inputDecoration("Tipo", Icons.list),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: _abrirSelectorVisual,
                      child: AbsorbPointer(
                        child: TextFormField(
                          readOnly: true,
                          validator: (_) => _idSeleccionado == null ? 'Selecciona una opción' : null,
                          controller: TextEditingController(
                            text: (() {
                              final item = lista.firstWhere(
                                (e) => (e['_id'] ?? e['id']) == _idSeleccionado,
                                orElse: () => {},
                              );
                              return item['nombre'] ?? item['name'] ?? '';
                            })(),
                          ),
                          decoration: _inputDecoration(
                            _tipo == 'producto' ? 'Producto' : 'Categoría',
                            Icons.label,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      controller: _fechaInicioController,
                      onTap: () => _seleccionarFecha(true),
                      decoration: _inputDecoration("Fecha de inicio", Icons.calendar_today),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      readOnly: true,
                      controller: _fechaFinController,
                      onTap: () => _seleccionarFecha(false),
                      decoration: _inputDecoration("Fecha de fin", Icons.event),
                    ),
                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline),
                        label: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Crear anuncio",
                                style: TextStyle(color: Colors.white),
                              ),
                        onPressed: _isLoading ? null : _crearAnuncio,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: rojo,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
