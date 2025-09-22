import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// Importa el servicio de conectividad
import '../../services/connectivity_service.dart'; // Ajusta la ruta según tu estructura
import '../../providers/anuncio_admin_provider.dart';
import '../../services/auth_service.dart';
import 'selector_visual_screen.dart';
import 'anuncios_screen.dart';

class GestionAnunciosScreen extends StatefulWidget {
  const GestionAnunciosScreen({super.key});

  @override
  State<GestionAnunciosScreen> createState() => _GestionAnunciosScreenState();
}

class _GestionAnunciosScreenState extends State<GestionAnunciosScreen> 
    with ConnectivityMixin {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _fechaInicioController = TextEditingController();
  final TextEditingController _fechaFinController = TextEditingController();

  String _tipo = 'producto';
  String? _idSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  File? _imagen;

  final Color rojo = const Color(0xFFBE0C0C);
  final Color verdePrimario = const Color(0xFF4CAF50);
  final Color azulPrimario = const Color(0xFF2196F3);

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<AnunciosProvider>(context, listen: false).inicializar());
  }

  @override
  void dispose() {
    _fechaInicioController.dispose();
    _fechaFinController.dispose();
    super.dispose();
  }

  // Override del método del mixin para personalizar el comportamiento
  @override
  void onConnectivityChanged(bool isConnected) {
    // Llamar al comportamiento base (mostrar toast)
    super.onConnectivityChanged(isConnected);
    
    // Comportamiento adicional específico de esta pantalla
    if (!isConnected) {
      debugPrint('GestionAnuncios: Conexión perdida');
    } else {
      debugPrint('GestionAnuncios: Conexión restaurada');
      // Cuando se restaure la conexión, resetear y reinicializar los datos
      final provider = Provider.of<AnunciosProvider>(context, listen: false);
      provider.resetInitialization();
      provider.inicializar();
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
      locale: const Locale('es', 'ES'),
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: rojo,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (esInicio) {
          _fechaInicio = picked;
          _fechaInicioController.text = _formatearFechaElegante(picked);
        } else {
          _fechaFin = picked;
          _fechaFinController.text = _formatearFechaElegante(picked);
        }
      });
    }
  }

  String _formatearFecha(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  String _formatearFechaElegante(DateTime date) {
    final formatter = DateFormat('EEEE, d MMMM yyyy', 'es');
    return formatter.format(date);
  }

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

  Future<void> _crearAnuncio(BuildContext context) async {
    // Usar el utility para verificar conectividad antes de proceder
    final success = await ConnectivityUtils.executeWithConnectivity(
      context,
      () async {
        await _performCreateAnuncio(context);
      },
      noConnectionMessage: 'Sin conexión. No se puede crear el anuncio.',
    );

    if (!success) return; // Si no hay conexión, no continuar
  }

  Future<void> _performCreateAnuncio(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    if (_imagen == null || _fechaInicio == null || _fechaFin == null || _idSeleccionado == null) {
      _mostrarToast('Todos los campos son obligatorios.', isError: true);
      return;
    }

    final accessToken = await AuthService().getAccessToken();
    if (accessToken == null) {
      _mostrarToast('No se encontró token.', isError: true);
      return;
    }

    final provider = Provider.of<AnunciosProvider>(context, listen: false);

    final exito = await provider.crearAnuncio(
      fechaInicio: ajustarColombia(_fechaInicio!).toIso8601String(),
      fechaFin: ajustarColombia(_fechaFin!).toIso8601String(),
      productoId: _tipo == 'producto' ? _idSeleccionado : null,
      categoriaId: _tipo == 'categoria' ? _idSeleccionado : null,
      imagenPath: _imagen!.path,
    );

    if (exito) {
      _mostrarToast("Anuncio creado exitosamente", isError: false);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AnunciosScreen()),
      );
    } else {
      _mostrarToast(provider.errorMessage ?? 'Error al crear anuncio', isError: true);
    }
  }

  void _mostrarToast(String mensaje, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error : Icons.check_circle,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje, 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)
              ),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.redAccent : verdePrimario,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, {bool hasValue = false}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(
        icon, 
        color: hasValue ? rojo : Colors.grey[600],
      ),
      filled: true,
      fillColor: Colors.white,
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
        borderSide: BorderSide(color: rojo, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      suffixIcon: hasValue 
        ? Icon(Icons.check_circle, color: verdePrimario, size: 20) 
        : null,
    );
  }

  Widget _buildTipoSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.category, color: rojo),
                const SizedBox(width: 8),
                const Text(
                  'Tipo de anuncio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildTipoOpcion('producto', 'Producto', Icons.shopping_bag),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTipoOpcion('categoria', 'Categoría', Icons.folder),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTipoOpcion(String valor, String texto, IconData icono) {
    final isSelected = _tipo == valor;
    return GestureDetector(
      onTap: () => setState(() {
        _tipo = valor;
        _idSeleccionado = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? rojo.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? rojo : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: isSelected ? rojo : Colors.grey[600],
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              texto,
              style: TextStyle(
                color: isSelected ? rojo : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorItem() {
    final provider = Provider.of<AnunciosProvider>(context);
    final lista = _tipo == 'producto' ? provider.productos : provider.categorias;
    final itemSeleccionado = lista.isNotEmpty 
        ? lista.firstWhere(
            (e) => (e['_id'] ?? e['id']) == _idSeleccionado,
            orElse: () => {},
          )
        : {};
    
    final tieneSeleccion = _idSeleccionado != null && itemSeleccionado.isNotEmpty;
    final nombreItem = itemSeleccionado['nombre'] ?? itemSeleccionado['name'] ?? '';

    // Si no hay conexión, mostrar estado deshabilitado
    if (!isConnected) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _tipo == 'producto' ? Icons.shopping_bag : Icons.folder,
                  color: Colors.grey[500],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sin conexión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Requiere conexión a Internet',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.wifi_off,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _abrirSelectorVisual,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tieneSeleccion ? rojo : Colors.grey[300]!,
            width: tieneSeleccion ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (tieneSeleccion ? rojo : Colors.grey[400])!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _tipo == 'producto' ? Icons.shopping_bag : Icons.folder,
                  color: tieneSeleccion ? rojo : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tieneSeleccion 
                          ? nombreItem
                          : 'Seleccionar ${_tipo == 'producto' ? 'producto' : 'categoría'}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: tieneSeleccion ? FontWeight.w600 : FontWeight.w500,
                        color: tieneSeleccion ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tieneSeleccion 
                          ? '${_tipo.capitalize()} seleccionado'
                          : 'Toca para elegir una opción',
                      style: TextStyle(
                        fontSize: 12,
                        color: tieneSeleccion ? verdePrimario : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                tieneSeleccion ? Icons.check_circle : Icons.arrow_forward_ios,
                color: tieneSeleccion ? verdePrimario : Colors.grey[400],
                size: tieneSeleccion ? 24 : 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFechaSelector(String titulo, String subtitulo, IconData icono, 
      TextEditingController controller, bool esInicio, DateTime? fecha) {
    final tieneFecha = fecha != null;
    
    return GestureDetector(
      onTap: () => _seleccionarFecha(esInicio),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: tieneFecha ? rojo : Colors.grey[300]!,
            width: tieneFecha ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (tieneFecha ? rojo : Colors.grey[400])!.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icono,
                  color: tieneFecha ? rojo : Colors.grey[600],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tieneFecha ? controller.text : subtitulo,
                      style: TextStyle(
                        fontSize: 12,
                        color: tieneFecha ? verdePrimario : Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                tieneFecha ? Icons.check_circle : Icons.calendar_today,
                color: tieneFecha ? verdePrimario : Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoConnectionState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.orange[600],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin conexión a Internet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'No es posible crear anuncios sin conexión.\nVerifica tu conexión a Internet e intenta nuevamente.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Intentar reconectar y recargar datos
                  final connectivityService = ConnectivityService();
                  final isConnected = await connectivityService.checkConnectivity();
                  if (isConnected) {
                    Provider.of<AnunciosProvider>(context, listen: false).inicializar();
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Intentar nuevamente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AnunciosProvider>(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Crear Anuncio",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        actions: [
          if (!isConnected)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(Icons.wifi_off, color: Colors.red[400]),
            ),
        ],
      ),
      body: !isConnected && provider.hasInitialized
          ? _buildNoConnectionState()
          : provider.isLoading && !provider.hasInitialized
              ? const Center(child: CircularProgressIndicator())
              : !isConnected && !provider.hasData
                  ? _buildNoConnectionState()
                  : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de conectividad más compacto
                    if (!isConnected)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange[100],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.orange[700], size: 14),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Sin conexión a Internet',
                                style: TextStyle(
                                  color: Colors.orange[700],
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Imagen del anuncio
                    Row(
                      children: [
                        Icon(Icons.image, color: rojo, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Imagen del anuncio',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _imagen != null ? rojo : Colors.grey[300]!,
                            width: _imagen != null ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _imagen != null
                              ? Stack(
                                  children: [
                                    Image.file(_imagen!, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: verdePrimario,
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey[600]),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Toca para seleccionar imagen',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Formatos: JPG, PNG',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Selector de tipo
                    _buildTipoSelector(),

                    const SizedBox(height: 24),

                    // Selector de producto/categoría
                    Row(
                      children: [
                        Icon(Icons.label, color: rojo, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Selección',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSelectorItem(),

                    const SizedBox(height: 24),

                    // Fechas
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: rojo, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Período del anuncio',
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildFechaSelector(
                      'Fecha de inicio',
                      'Selecciona cuándo inicia el anuncio',
                      Icons.play_circle_outline,
                      _fechaInicioController,
                      true,
                      _fechaInicio,
                    ),
                    const SizedBox(height: 16),
                    _buildFechaSelector(
                      'Fecha de fin',
                      'Selecciona cuándo termina el anuncio',
                      Icons.stop_circle_outlined,
                      _fechaFinController,
                      false,
                      _fechaFin,
                    ),

                    const SizedBox(height: 40),

                    // Botón crear - solo mostrar si hay conexión
                    if (isConnected) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: provider.isCreating 
                              ? null 
                              : () => _crearAnuncio(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: rojo,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                            shadowColor: rojo.withOpacity(0.3),
                          ),
                          child: provider.isCreating
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.rocket_launch, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text(
                                      "Crear Anuncio",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else ...[
                      // Mensaje cuando no hay conexión en lugar del botón
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12), // Reducido de 16 a 12
                        decoration: BoxDecoration(
                          color: Colors.orange[50],
                          borderRadius: BorderRadius.circular(8), // Reducido de 12 a 8
                          border: Border.all(color: Colors.orange[200]!),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.wifi_off, color: Colors.orange[600], size: 20), // Reducido de 24 a 20
                            const SizedBox(height: 6), // Reducido de 8 a 6
                            Text(
                              'Sin conexión',
                              style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                                fontSize: 14, // Reducido de 16 a 14
                              ),
                            ),
                            const SizedBox(height: 2), // Reducido de 4 a 2
                            Text(
                              'Conecta a Internet para crear anuncios',
                              style: TextStyle(
                                color: Colors.orange[700],
                                fontSize: 12, // Reducido de 14 a 12
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}