import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// Importa el servicio de conectividad
import '../../services/connectivity_service.dart';
import '../../providers/anuncio_admin_provider.dart';
import '../../services/auth_service.dart';
import 'selector_visual_screen.dart';
import 'anuncios_screen.dart';

// Importar estilos
import 'styles/gestion_anuncio/colors.dart';
import 'styles/gestion_anuncio/decorations.dart';
import 'styles/gestion_anuncio/text_styles.dart';
import 'styles/gestion_anuncio/dimensions.dart';

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

  @override
  void onConnectivityChanged(bool isConnected) {
    super.onConnectivityChanged(isConnected);
    
    if (!isConnected) {
      debugPrint('GestionAnuncios: Conexión perdida');
    } else {
      debugPrint('GestionAnuncios: Conexión restaurada');
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
              primary: GestionAnunciosColors.rojo,
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
    final success = await ConnectivityUtils.executeWithConnectivity(
      context,
      () async {
        await _performCreateAnuncio(context);
      },
      noConnectionMessage: 'Sin conexión. No se puede crear el anuncio.',
    );

    if (!success) return;
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

  // ✅ Verificar que el widget aún está montado antes de usar el context
  if (!mounted) return;

  if (exito) {
    _mostrarToast("Anuncio creado exitosamente", isError: false);

    // Esperar un momento para que se vea el SnackBar antes de navegar
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AnunciosScreen()),
    );
  } else {
    _mostrarToast(provider.errorMessage ?? 'Error al crear anuncio', isError: true);
  }
}

// También actualiza _mostrarToast para que sea más seguro
void _mostrarToast(String mensaje, {required bool isError}) {
  // ✅ Verificar que el widget está montado antes de mostrar el SnackBar
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            color: Colors.white,
          ),
          SizedBox(width: GestionAnunciosDimensions.spacingSmall),
          Expanded(
            child: Text(mensaje, style: GestionAnunciosTextStyles.toast),
          ),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : GestionAnunciosColors.verdePrimario,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GestionAnunciosDimensions.radiusLarge)
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}

  Widget _buildTipoSelector() {
    return Container(
      decoration: GestionAnunciosDecorations.containerWithShadow(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(GestionAnunciosDimensions.paddingCard),
            child: Row(
              children: [
                Icon(Icons.category, color: GestionAnunciosColors.rojo),
                SizedBox(width: GestionAnunciosDimensions.spacingSmall),
                const Text('Tipo de anuncio', style: GestionAnunciosTextStyles.cardTitle),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: GestionAnunciosDimensions.paddingCard),
            child: Row(
              children: [
                Expanded(
                  child: _buildTipoOpcion('producto', 'Producto', Icons.shopping_bag),
                ),
                SizedBox(width: GestionAnunciosDimensions.spacingMedium),
                Expanded(
                  child: _buildTipoOpcion('categoria', 'Categoría', Icons.folder),
                ),
              ],
            ),
          ),
          SizedBox(height: GestionAnunciosDimensions.spacingLarge),
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
        padding: EdgeInsets.symmetric(
          vertical: GestionAnunciosDimensions.spacingMedium,
          horizontal: GestionAnunciosDimensions.paddingCard,
        ),
        decoration: GestionAnunciosDecorations.tipoOpcionDecoration(isSelected: isSelected),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              color: isSelected ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris600,
              size: GestionAnunciosDimensions.iconLarge,
            ),
            SizedBox(width: GestionAnunciosDimensions.spacingSmall),
            Text(texto, style: GestionAnunciosTextStyles.opcionTexto(isSelected: isSelected)),
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

    if (!isConnected) {
      return Container(
        decoration: GestionAnunciosDecorations.containerWithShadow(
          color: GestionAnunciosColors.gris100,
          borderColor: GestionAnunciosColors.gris300,
        ),
        child: Padding(
          padding: EdgeInsets.all(GestionAnunciosDimensions.paddingCard),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(GestionAnunciosDimensions.paddingSmall - 2),
                decoration: GestionAnunciosDecorations.iconContainerDecoration(isActive: false),
                child: Icon(
                  _tipo == 'producto' ? Icons.shopping_bag : Icons.folder,
                  color: GestionAnunciosColors.gris500,
                  size: GestionAnunciosDimensions.iconXLarge,
                ),
              ),
              SizedBox(width: GestionAnunciosDimensions.spacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sin conexión', style: GestionAnunciosTextStyles.selectorDeshabilitadoTitulo),
                    SizedBox(height: GestionAnunciosDimensions.spacingXSmall),
                    Text('Requiere conexión a Internet', 
                      style: GestionAnunciosTextStyles.selectorDeshabilitadoSubtitulo),
                  ],
                ),
              ),
              Icon(Icons.wifi_off, color: GestionAnunciosColors.gris400, 
                size: GestionAnunciosDimensions.iconLarge),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _abrirSelectorVisual,
      child: Container(
        decoration: GestionAnunciosDecorations.containerWithShadow(
          borderColor: tieneSeleccion ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris300,
          borderWidth: tieneSeleccion ? 2 : 1,
        ),
        child: Padding(
          padding: EdgeInsets.all(GestionAnunciosDimensions.paddingCard),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(GestionAnunciosDimensions.paddingSmall - 2),
                decoration: GestionAnunciosDecorations.iconContainerDecoration(isActive: tieneSeleccion),
                child: Icon(
                  _tipo == 'producto' ? Icons.shopping_bag : Icons.folder,
                  color: tieneSeleccion ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris600,
                  size: GestionAnunciosDimensions.iconXLarge,
                ),
              ),
              SizedBox(width: GestionAnunciosDimensions.spacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tieneSeleccion 
                          ? nombreItem
                          : 'Seleccionar ${_tipo == 'producto' ? 'producto' : 'categoría'}',
                      style: GestionAnunciosTextStyles.itemNombre(seleccionado: tieneSeleccion),
                    ),
                    SizedBox(height: GestionAnunciosDimensions.spacingXSmall),
                    Text(
                      tieneSeleccion 
                          ? '${_tipo.capitalize()} seleccionado'
                          : 'Toca para elegir una opción',
                      style: GestionAnunciosTextStyles.cardSubtitle(
                        color: tieneSeleccion 
                            ? GestionAnunciosColors.verdePrimario 
                            : GestionAnunciosColors.gris500
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                tieneSeleccion ? Icons.check_circle : Icons.arrow_forward_ios,
                color: tieneSeleccion ? GestionAnunciosColors.verdePrimario : GestionAnunciosColors.gris400,
                size: tieneSeleccion ? GestionAnunciosDimensions.iconXLarge : GestionAnunciosDimensions.iconMedium,
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
        decoration: GestionAnunciosDecorations.containerWithShadow(
          borderColor: tieneFecha ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris300,
          borderWidth: tieneFecha ? 2 : 1,
        ),
        child: Padding(
          padding: EdgeInsets.all(GestionAnunciosDimensions.paddingCard),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(GestionAnunciosDimensions.paddingSmall - 2),
                decoration: GestionAnunciosDecorations.iconContainerDecoration(isActive: tieneFecha),
                child: Icon(
                  icono,
                  color: tieneFecha ? GestionAnunciosColors.rojo : GestionAnunciosColors.gris600,
                  size: GestionAnunciosDimensions.iconXLarge,
                ),
              ),
              SizedBox(width: GestionAnunciosDimensions.spacingLarge),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: GestionAnunciosTextStyles.fechaTitulo),
                    SizedBox(height: GestionAnunciosDimensions.spacingXSmall),
                    Text(
                      tieneFecha ? controller.text : subtitulo,
                      style: GestionAnunciosTextStyles.cardSubtitle(
                        color: tieneFecha 
                            ? GestionAnunciosColors.verdePrimario 
                            : GestionAnunciosColors.gris500
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                tieneFecha ? Icons.check_circle : Icons.calendar_today,
                color: tieneFecha ? GestionAnunciosColors.verdePrimario : GestionAnunciosColors.gris400,
                size: GestionAnunciosDimensions.iconLarge,
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
        padding: EdgeInsets.all(GestionAnunciosDimensions.spacingHuge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(GestionAnunciosDimensions.paddingScreen),
              decoration: GestionAnunciosDecorations.noConnectionIconContainerDecoration(),
              child: Icon(
                Icons.wifi_off,
                size: GestionAnunciosDimensions.iconHuge,
                color: GestionAnunciosColors.naranja600,
              ),
            ),
            SizedBox(height: GestionAnunciosDimensions.spacingXLarge),
            Text(
              'Sin conexión a Internet',
              style: GestionAnunciosTextStyles.sinConexionTitulo,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: GestionAnunciosDimensions.spacingMedium),
            Text(
              'No es posible crear anuncios sin conexión.\nVerifica tu conexión a Internet e intenta nuevamente.',
              style: GestionAnunciosTextStyles.sinConexionDescripcion,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: GestionAnunciosDimensions.spacingXXLarge),
            SizedBox(
              width: double.infinity,
              height: GestionAnunciosDimensions.botonMediumHeight,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final connectivityService = ConnectivityService();
                  final isConnected = await connectivityService.checkConnectivity();
                  if (isConnected) {
                    Provider.of<AnunciosProvider>(context, listen: false).inicializar();
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Intentar nuevamente',
                  style: GestionAnunciosTextStyles.botonPrimario,
                ),
                style: GestionAnunciosDecorations.retryButtonStyle(),
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
      backgroundColor: GestionAnunciosColors.gris50,
      appBar: AppBar(
        title: const Text("Crear Anuncio", style: GestionAnunciosTextStyles.appBarTitle),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: GestionAnunciosDimensions.elevationLow,
        actions: [
          if (!isConnected)
            Padding(
              padding: EdgeInsets.only(right: GestionAnunciosDimensions.paddingCard),
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
              padding: EdgeInsets.all(GestionAnunciosDimensions.paddingScreen),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Indicador de conectividad compacto
                    if (!isConnected)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          vertical: GestionAnunciosDimensions.spacingSmall - 2,
                          horizontal: GestionAnunciosDimensions.spacingMedium,
                        ),
                        margin: EdgeInsets.only(bottom: GestionAnunciosDimensions.spacingMedium),
                        decoration: GestionAnunciosDecorations.noConnectionCompactDecoration(),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: GestionAnunciosColors.naranja700,
                              size: GestionAnunciosDimensions.iconSmall,
                            ),
                            SizedBox(width: GestionAnunciosDimensions.spacingSmall - 2),
                            Expanded(
                              child: Text(
                                'Sin conexión a Internet',
                                style: GestionAnunciosTextStyles.sinConexionCompacto,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Imagen del anuncio
                    Row(
                      children: [
                        Icon(Icons.image, color: GestionAnunciosColors.rojo, 
                          size: GestionAnunciosDimensions.iconLarge),
                        SizedBox(width: GestionAnunciosDimensions.spacingSmall),
                        const Text('Imagen del anuncio', style: GestionAnunciosTextStyles.seccionTitulo),
                      ],
                    ),
                    SizedBox(height: GestionAnunciosDimensions.spacingSmall),
                    
                    // Información sobre dimensiones de la imagen
                    Container(
                      padding: EdgeInsets.all(GestionAnunciosDimensions.spacingMedium),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFBAE6FD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(GestionAnunciosDimensions.spacingSmall),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: const Color(0xFF0284C7),
                              size: GestionAnunciosDimensions.iconMedium,
                            ),
                          ),
                          SizedBox(width: GestionAnunciosDimensions.spacingMedium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Dimensiones recomendadas',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0369A1),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '984 × 450 píxeles (ancho × alto)',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF0284C7),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: GestionAnunciosDimensions.spacingMedium),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: GestionAnunciosDimensions.imagenAnuncioHeight,
                        width: double.infinity,
                        decoration: GestionAnunciosDecorations.imagenAnuncioDecoration(
                          tieneImagen: _imagen != null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: _imagen != null
                              ? Stack(
                                  children: [
                                    Image.file(
                                      _imagen!,
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    Positioned(
                                      top: GestionAnunciosDimensions.spacingMedium,
                                      right: GestionAnunciosDimensions.spacingMedium,
                                      child: Container(
                                        padding: EdgeInsets.all(GestionAnunciosDimensions.spacingSmall),
                                        decoration: GestionAnunciosDecorations.successBadgeDecoration(),
                                        child: Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: GestionAnunciosDimensions.iconMedium,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(GestionAnunciosDimensions.paddingCard),
                                      decoration: GestionAnunciosDecorations.imagePlaceholderIconDecoration(),
                                      child: Icon(
                                        Icons.add_photo_alternate,
                                        size: GestionAnunciosDimensions.iconXXLarge,
                                        color: GestionAnunciosColors.gris600,
                                      ),
                                    ),
                                    SizedBox(height: GestionAnunciosDimensions.spacingMedium),
                                    Text(
                                      'Toca para seleccionar imagen',
                                      style: GestionAnunciosTextStyles.placeholder,
                                    ),
                                    SizedBox(height: GestionAnunciosDimensions.spacingXSmall),
                                    Text(
                                      'Formatos: JPG, PNG,WEBP',
                                      style: GestionAnunciosTextStyles.placeholderSubtitle,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    SizedBox(height: GestionAnunciosDimensions.spacingXXLarge),

                    // Selector de tipo
                    _buildTipoSelector(),

                    SizedBox(height: GestionAnunciosDimensions.spacingXLarge),

                    // Selector de producto/categoría
                    Row(
                      children: [
                        Icon(Icons.label, color: GestionAnunciosColors.rojo, 
                          size: GestionAnunciosDimensions.iconLarge),
                        SizedBox(width: GestionAnunciosDimensions.spacingSmall),
                        const Text('Selección', style: GestionAnunciosTextStyles.seccionTitulo),
                      ],
                    ),
                    SizedBox(height: GestionAnunciosDimensions.spacingMedium),
                    _buildSelectorItem(),

                    SizedBox(height: GestionAnunciosDimensions.spacingXLarge),

                    // Fechas
                    Row(
                      children: [
                        Icon(Icons.calendar_month, color: GestionAnunciosColors.rojo, 
                          size: GestionAnunciosDimensions.iconLarge),
                        SizedBox(width: GestionAnunciosDimensions.spacingSmall),
                        const Text('Período del anuncio', style: GestionAnunciosTextStyles.seccionTitulo),
                      ],
                    ),
                    SizedBox(height: GestionAnunciosDimensions.spacingMedium),
                    _buildFechaSelector(
                      'Fecha de inicio',
                      'Selecciona cuándo inicia el anuncio',
                      Icons.play_circle_outline,
                      _fechaInicioController,
                      true,
                      _fechaInicio,
                    ),
                    SizedBox(height: GestionAnunciosDimensions.spacingLarge),
                    _buildFechaSelector(
                      'Fecha de fin',
                      'Selecciona cuándo termina el anuncio',
                      Icons.stop_circle_outlined,
                      _fechaFinController,
                      false,
                      _fechaFin,
                    ),

                    SizedBox(height: GestionAnunciosDimensions.spacingHuge),

                    // Botón crear - solo mostrar si hay conexión
                    if (isConnected) ...[
                      SizedBox(
                        width: double.infinity,
                        height: GestionAnunciosDimensions.botonHeight,
                        child: ElevatedButton(
                          onPressed: provider.isCreating 
                              ? null 
                              : () => _crearAnuncio(context),
                          style: GestionAnunciosDecorations.primaryButtonStyle(),
                          child: provider.isCreating
                              ? SizedBox(
                                  height: GestionAnunciosDimensions.loadingIndicatorSize,
                                  width: GestionAnunciosDimensions.loadingIndicatorSize,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: GestionAnunciosDimensions.loadingIndicatorStrokeWidth,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.rocket_launch, color: Colors.white),
                                    SizedBox(width: GestionAnunciosDimensions.spacingMedium),
                                    const Text("Crear Anuncio", style: GestionAnunciosTextStyles.botonPrimario),
                                  ],
                                ),
                        ),
                      ),
                      SizedBox(height: GestionAnunciosDimensions.paddingScreen),
                    ] else ...[
                      // Mensaje cuando no hay conexión
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(GestionAnunciosDimensions.spacingMedium),
                        decoration: GestionAnunciosDecorations.noConnectionMessageDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off,
                              color: GestionAnunciosColors.naranja600,
                              size: GestionAnunciosDimensions.iconLarge,
                            ),
                            SizedBox(height: GestionAnunciosDimensions.spacingSmall - 2),
                            Text('Sin conexión', style: GestionAnunciosTextStyles.sinConexionMensaje),
                            const SizedBox(height: 2),
                            Text(
                              'Conecta a Internet para crear anuncios',
                              style: GestionAnunciosTextStyles.sinConexionSubmensaje,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: GestionAnunciosDimensions.paddingScreen),
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