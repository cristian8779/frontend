import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../services/perfilService.dart';

class BoldPaymentPage extends StatefulWidget {
  final double totalPrice;
  final int totalItems;

  const BoldPaymentPage({
    Key? key,
    required this.totalPrice,
    required this.totalItems,
  }) : super(key: key);

  @override
  State<BoldPaymentPage> createState() => _BoldPaymentPageState();
}

class _BoldPaymentPageState extends State<BoldPaymentPage> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isEditingShipping = false;
  bool _hasShippingData = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  // Service y controladores para datos de envío
  final PerfilService _perfilService = PerfilService();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();

  static const String _netlifyPaymentUrl = 'https://mellow-pasca-a7bd11.netlify.app/';

 final NumberFormat _currencyFormat = NumberFormat.currency(
  locale: 'es_CO',
  symbol: '\$',
  decimalDigits: 0,
  customPattern: '\u00A4#,##0', // coloca el símbolo $ al inicio
);


  // Breakpoints responsivos
  static const double _tabletBreakpoint = 768.0;
  static const double _desktopBreakpoint = 1024.0;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _slideController.forward();
    _cargarDatosEnvio();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _departamentoController.dispose();
    _municipioController.dispose();
    _calleController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Responsive helpers
  bool get _isMobile => MediaQuery.of(context).size.width < _tabletBreakpoint;
  bool get _isTablet => MediaQuery.of(context).size.width >= _tabletBreakpoint && 
                       MediaQuery.of(context).size.width < _desktopBreakpoint;
  bool get _isDesktop => MediaQuery.of(context).size.width >= _desktopBreakpoint;

  double get _contentMaxWidth {
    if (_isDesktop) return 600.0;
    if (_isTablet) return double.infinity;
    return double.infinity;
  }

  EdgeInsetsGeometry get _screenPadding {
    if (_isDesktop) return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    if (_isTablet) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  double get _cardPadding {
    if (_isDesktop) return 32.0;
    if (_isTablet) return 24.0;
    return 20.0;
  }

  double get _fontSize {
    if (_isDesktop) return 16.0;
    if (_isTablet) return 15.0;
    return 14.0;
  }

  double get _titleFontSize {
    if (_isDesktop) return 20.0;
    if (_isTablet) return 18.0;
    return 16.0;
  }

  // Cargar datos de envío del perfil
  Future<void> _cargarDatosEnvio() async {
    try {
      final perfil = await _perfilService.obtenerPerfil();
      if (perfil != null && mounted) {
        setState(() {
          _telefonoController.text = perfil['telefono']?.toString() ?? '';
          
          // Manejar dirección
          final direccion = perfil['direccion'];
          if (direccion is Map<String, dynamic>) {
            _departamentoController.text = direccion['departamento']?.toString() ?? '';
            _municipioController.text = direccion['municipio']?.toString() ?? '';
            _calleController.text = direccion['calle']?.toString() ?? '';
            _codigoPostalController.text = direccion['codigoPostal']?.toString() ?? '';
          }
          
          // Verificar si tiene datos completos de envío
          _hasShippingData = _telefonoController.text.isNotEmpty && 
                            _calleController.text.isNotEmpty &&
                            _municipioController.text.isNotEmpty &&
                            _departamentoController.text.isNotEmpty;
        });
      }
    } catch (e) {
      print('Error cargando datos de envío: $e');
    }
  }

  // Actualizar datos de envío
  Future<void> _actualizarDatosEnvio() async {
    if (_calleController.text.trim().isEmpty || 
        _municipioController.text.trim().isEmpty || 
        _departamentoController.text.trim().isEmpty) {
      _mostrarError('Todos los campos de dirección son obligatorios');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final direccionData = {
        'departamento': _departamentoController.text.trim(),
        'municipio': _municipioController.text.trim(),
        'calle': _calleController.text.trim(),
        'codigoPostal': _codigoPostalController.text.trim(),
      };

      final success = await _perfilService.actualizarPerfil(
        direccion: direccionData,
        telefono: _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() : null,
      );

      if (success) {
        setState(() {
          _hasShippingData = true;
          _isEditingShipping = false;
        });
        _mostrarExito('Datos de envío actualizados correctamente');
      } else {
        _mostrarError(_perfilService.message ?? 'Error al actualizar datos');
      }
    } catch (e) {
      _mostrarError('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _mostrarError(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: const Color(0xFFE53E3E),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(_isMobile ? 16 : 24),
        ),
      );
    }
  }

  void _mostrarExito(String mensaje) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje, style: const TextStyle(fontSize: 14))),
            ],
          ),
          backgroundColor: const Color(0xFF00A650),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(_isMobile ? 16 : 24),
        ),
      );
    }
  }

  // Formatear dirección para mostrar
  String _formatearDireccion() {
    final calle = _calleController.text.trim();
    final municipio = _municipioController.text.trim();
    final departamento = _departamentoController.text.trim();
    final codigoPostal = _codigoPostalController.text.trim();
    
    List<String> partes = [];
    if (calle.isNotEmpty) partes.add(calle);
    if (municipio.isNotEmpty) partes.add(municipio);
    if (departamento.isNotEmpty && codigoPostal.isNotEmpty) {
      partes.add('$departamento $codigoPostal');
    } else if (departamento.isNotEmpty) {
      partes.add(departamento);
    }
    
    return partes.join(', ');
  }

  Future<void> _processPayment() async {
    // Validar que tenga datos de envío completos
    if (!_hasShippingData || _calleController.text.trim().isEmpty) {
      _mostrarError('Debes completar tu dirección de envío antes de continuar');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.userId ?? '';
      final token = authProvider.token ?? ''; // Obtener el token del provider
      
      // Construir URL con userId y token
      final paymentUrl = Uri.parse('$_netlifyPaymentUrl?userId=$userId&token=$token');
      
      await launchUrl(
        paymentUrl,
        mode: LaunchMode.inAppBrowserView,
        browserConfiguration: const BrowserConfiguration(showTitle: true),
        webViewConfiguration: const WebViewConfiguration(
          enableJavaScript: true,
          enableDomStorage: true,
        ),
      );

    } catch (e) {
      if (mounted) {
        _mostrarError('No pudimos procesar el pago. Intenta nuevamente.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildCard({required Widget child, bool noPadding = false}) {
    return Container(
      width: double.infinity,
      padding: noPadding ? null : EdgeInsets.all(_cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  // Widget para mostrar datos de envío
  Widget _buildShippingInfoWidget() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00A650),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_shipping,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Envío',
                    style: TextStyle(
                      fontSize: _titleFontSize,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              if (_hasShippingData && !_isEditingShipping)
                TextButton(
                  onPressed: () => setState(() => _isEditingShipping = true),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: _isMobile ? 8 : 12, 
                      vertical: _isMobile ? 4 : 8
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Cambiar',
                    style: TextStyle(
                      color: const Color(0xFF3483FA),
                      fontWeight: FontWeight.w500,
                      fontSize: _fontSize,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(height: _isMobile ? 16 : 20),
          
          if (!_hasShippingData || _isEditingShipping) ...[
            // Formulario de edición
            _buildEditForm(),
          ] else ...[
            // Vista de datos
            _buildDataView(),
          ],
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        // Dirección
        Container(
          padding: EdgeInsets.all(_isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFFE5E5E5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined, 
                    color: const Color(0xFF666666), 
                    size: _isMobile ? 16 : 18
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Dirección de entrega',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF333333),
                    ),
                  ),
                ],
              ),
              SizedBox(height: _isMobile ? 16 : 20),
              
              // Departamento y Ciudad en una fila para tablet/desktop
              if (_isTablet || _isDesktop) ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _departamentoController,
                        label: 'Departamento',
                        hint: 'Ej: Antioquia',
                        isRequired: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInputField(
                        controller: _municipioController,
                        label: 'Ciudad',
                        hint: 'Ej: Medellín',
                        isRequired: true,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // En móvil, uno debajo del otro
                _buildInputField(
                  controller: _departamentoController,
                  label: 'Departamento',
                  hint: 'Ej: Antioquia',
                  isRequired: true,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _municipioController,
                  label: 'Ciudad',
                  hint: 'Ej: Medellín',
                  isRequired: true,
                ),
              ],
              
              const SizedBox(height: 16),
              
              // Dirección
              _buildInputField(
                controller: _calleController,
                label: 'Dirección completa',
                hint: 'Ej: Carrera 45 #67-89',
                isRequired: true,
              ),
              
              const SizedBox(height: 16),
              
              // Código postal
              _buildInputField(
                controller: _codigoPostalController,
                label: 'Código Postal',
                hint: 'Ej: 050001',
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Teléfono
        _buildInputField(
          controller: _telefonoController,
          label: 'Teléfono de contacto',
          hint: 'Ej: 300 123 4567',
          keyboardType: TextInputType.phone,
          icon: Icons.phone_outlined,
        ),
        
        SizedBox(height: _isMobile ? 20 : 24),
        
        // Botones
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (_isMobile) {
      // En móvil, botones en columna
      return Column(
        children: [
          if (_hasShippingData) ...[
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditingShipping = false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3483FA)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                ),
                child: Text(
                  'Cancelar',
                  style: TextStyle(
                    color: const Color(0xFF3483FA),
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _actualizarDatosEnvio,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3483FA),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                disabledBackgroundColor: const Color(0xFFB0B0B0),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      _hasShippingData ? 'Actualizar' : 'Guardar dirección',
                      style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
                    ),
            ),
          ),
        ],
      );
    } else {
      // En tablet/desktop, botones en fila
      return Row(
        children: [
          if (_hasShippingData) ...[
            Expanded(
              child: SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => setState(() => _isEditingShipping = false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF3483FA)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: const Color(0xFF3483FA),
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _actualizarDatosEnvio,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3483FA),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  disabledBackgroundColor: const Color(0xFFB0B0B0),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        _hasShippingData ? 'Actualizar' : 'Guardar dirección',
                        style: TextStyle(fontSize: _fontSize, fontWeight: FontWeight.w500),
                      ),
              ),
            ),
          ),
        ],
      );
    }
  }

  Widget _buildDataView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dirección
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(_isMobile ? 16 : 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F8F0),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF00A650).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: const Color(0xFF00A650),
                    size: _isMobile ? 16 : 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Llega a tu dirección',
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF00A650),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _formatearDireccion(),
                style: TextStyle(
                  fontSize: _fontSize + 1,
                  color: const Color(0xFF333333),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
        
        if (_telefonoController.text.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E5E5)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.phone_outlined,
                  color: const Color(0xFF666666),
                  size: _isMobile ? 16 : 18,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Teléfono de contacto',
                      style: TextStyle(
                        fontSize: _fontSize - 1,
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _telefonoController.text,
                      style: TextStyle(
                        fontSize: _fontSize,
                        color: const Color(0xFF333333),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    bool isRequired = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: const Color(0xFF666666), size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              '$label${isRequired ? ' *' : ''}',
              style: TextStyle(
                fontSize: _fontSize - 1,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: _fontSize, color: const Color(0xFF333333)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: const Color(0xFF999999), 
              fontSize: _fontSize
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFF3483FA), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFE53E3E)),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _isMobile ? 12 : 16, 
              vertical: _isMobile ? 12 : 14
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
        ),
        title: Text(
          'Finalizar compra',
          style: TextStyle(
            color: const Color(0xFF333333),
            fontSize: _titleFontSize + 2,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Center(
          child: Container(
            constraints: BoxConstraints(maxWidth: _contentMaxWidth),
            child: SingleChildScrollView(
              padding: _screenPadding,
              child: Column(
                children: [
                  // Resumen de compra
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Resumen de compra',
                          style: TextStyle(
                            fontSize: _titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                        SizedBox(height: _isMobile ? 16 : 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.totalItems} ${widget.totalItems == 1 ? 'producto' : 'productos'}',
                              style: TextStyle(
                                fontSize: _fontSize,
                                color: const Color(0xFF666666),
                              ),
                            ),
                            Text(
                              _currencyFormat.format(widget.totalPrice),
                              style: TextStyle(
                                fontSize: _titleFontSize + 4,
                                fontWeight: FontWeight.w300,
                                color: const Color(0xFF333333),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: _isMobile ? 16 : 24),

                  // Widget de datos de envío
                  _buildShippingInfoWidget(),

                  SizedBox(height: _isMobile ? 16 : 24),



                  SizedBox(height: _isMobile ? 32 : 40),
                ],
              ),
            ),
          ),
        ),
      ),
      
      // Bottom bar con total y botón de pago
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: const Color(0xFFE5E5E5), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            constraints: BoxConstraints(maxWidth: _contentMaxWidth),
            margin: _isDesktop ? const EdgeInsets.symmetric(horizontal: 32) : null,
            padding: EdgeInsets.all(_isMobile ? 16 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: _titleFontSize,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    Text(
                      _currencyFormat.format(widget.totalPrice),
                      style: TextStyle(
                        fontSize: _titleFontSize + 8,
                        fontWeight: FontWeight.w300,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: _isMobile ? 16 : 20),
                
                // Botón de pago
                SizedBox(
                  width: double.infinity,
                  height: _isMobile ? 48 : 52,
                  child: ElevatedButton(
                    onPressed: (_isLoading || !_hasShippingData || _calleController.text.trim().isEmpty) 
                        ? null 
                        : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_hasShippingData && _calleController.text.trim().isNotEmpty) 
                          ? const Color(0xFF3483FA) 
                          : const Color(0xFFCCCCCC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      disabledBackgroundColor: const Color(0xFFCCCCCC),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: _isMobile ? 20 : 24,
                            height: _isMobile ? 20 : 24,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            (_hasShippingData && _calleController.text.trim().isNotEmpty) 
                                ? 'Continuar' 
                                : 'Completa tu dirección',
                            style: TextStyle(
                              fontSize: _fontSize + 1,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                  ),
                ),
                
                // Mensaje de ayuda
                if (!_hasShippingData || _calleController.text.trim().isEmpty) ...[
                  SizedBox(height: _isMobile ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: const Color(0xFF666666),
                        size: _isMobile ? 14 : 16,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Necesitas completar tu dirección de envío',
                          style: TextStyle(
                            fontSize: _fontSize - 2,
                            color: const Color(0xFF666666),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ] else if (_hasShippingData && _calleController.text.trim().isNotEmpty) ...[
                  SizedBox(height: _isMobile ? 8 : 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.security,
                        color: const Color(0xFF00A650),
                        size: _isMobile ? 14 : 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pago 100% seguro',
                        style: TextStyle(
                          fontSize: _fontSize - 2,
                          color: const Color(0xFF00A650),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}