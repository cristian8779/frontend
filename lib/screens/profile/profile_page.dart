import '../../screens/usuario/bienvenida_usuario_screen.dart';
import '../../widgets/settings_button.dart';
import '../../theme/profile/profile_theme.dart';

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../services/perfilService.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final PerfilService _perfilService = PerfilService();
  final ImagePicker _picker = ImagePicker();
  
  // Controllers para los campos de texto - SIN BARRIO
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _departamentoController = TextEditingController();
  final TextEditingController _municipioController = TextEditingController();
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasProfile = false;
  bool _isUploadingImage = false;
  bool _hasConnectionError = false; // NUEVO: Estado para error de conexión
  Map<String, dynamic>? _profileData;
  File? _selectedImage;
  String? _currentImageUrl;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _departamentoController.dispose();
    _municipioController.dispose();
    _calleController.dispose();
    _codigoPostalController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Función para manejar logout
  void _handleLogout() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (Route<dynamic> route) => false,
    );
  }

  // -------------------------------
  // HELPERS PARA MANEJO DE DIRECCIÓN - FORMATO MERCADOLIBRE
  // -------------------------------
  String _formatearDireccionCompleta() {
    final calle = _calleController.text.trim();
    final municipio = _municipioController.text.trim();
    final departamento = _departamentoController.text.trim();
    final codigoPostal = _codigoPostalController.text.trim();
    
    // Formato estilo MercadoLibre: "Carrera 45 #67-89, Medellín, Antioquia 050001"
    List<String> partes = [];
    
    if (calle.isNotEmpty) partes.add(calle);
    if (municipio.isNotEmpty) partes.add(municipio);
    
    // Departamento y código postal juntos al final (sin duplicar departamento)
    if (departamento.isNotEmpty && codigoPostal.isNotEmpty) {
      partes.add('$departamento $codigoPostal');
    } else if (departamento.isNotEmpty) {
      partes.add(departamento);
    } else if (codigoPostal.isNotEmpty) {
      partes.add(codigoPostal);
    }
    
    return partes.join(', ');
  }

  // FORMATO ESPECIAL PARA MOSTRAR EN EL PERFIL (estilo MercadoLibre)
  String _formatearDireccionParaPerfil() {
    final calle = _calleController.text.trim();
    final municipio = _municipioController.text.trim();
    final departamento = _departamentoController.text.trim();
    final codigoPostal = _codigoPostalController.text.trim();
    
    if (calle.isEmpty && municipio.isEmpty && departamento.isEmpty && codigoPostal.isEmpty) {
      return "";
    }
    
    // Línea principal con dirección
    String lineaPrincipal = "";
    if (calle.isNotEmpty) {
      lineaPrincipal = calle;
    }
    
    // Línea secundaria con ubicación
    List<String> ubicacion = [];
    if (municipio.isNotEmpty) ubicacion.add(municipio);
    if (departamento.isNotEmpty) ubicacion.add(departamento);
    if (codigoPostal.isNotEmpty) ubicacion.add(codigoPostal);
    
    String lineaSecundaria = ubicacion.join(', ');
    
    // Combinar las líneas
    if (lineaPrincipal.isNotEmpty && lineaSecundaria.isNotEmpty) {
      return '$lineaPrincipal\n$lineaSecundaria';
    } else if (lineaPrincipal.isNotEmpty) {
      return lineaPrincipal;
    } else {
      return lineaSecundaria;
    }
  }

  void _llenarControllersDireccion(dynamic direccionData) {
    if (direccionData is Map<String, dynamic>) {
      _departamentoController.text = direccionData['departamento']?.toString() ?? '';
      _municipioController.text = direccionData['municipio']?.toString() ?? '';
      _calleController.text = direccionData['calle']?.toString() ?? '';
      _codigoPostalController.text = direccionData['codigoPostal']?.toString() ?? '';
    } else if (direccionData is String) {
      // Fallback para direcciones que aún vengan como string
      _calleController.text = direccionData;
      _departamentoController.text = '';
      _municipioController.text = '';
      _codigoPostalController.text = '';
    }
  }

  // MÉTODO SIN BARRIO - Estructura limpia
  Map<String, String> _construirObjetoDireccion() {
    return {
      'departamento': _departamentoController.text.trim(),
      'municipio': _municipioController.text.trim(),
      'calle': _calleController.text.trim(),
      'codigoPostal': _codigoPostalController.text.trim(),
    };
  }

  // -------------------------------
  // CARGAR PERFIL EXISTENTE - MEJORADO PARA MANEJAR SIN CONEXIÓN
  // -------------------------------
  Future<void> _cargarPerfil() async {
    setState(() {
      _isLoading = true;
      _hasConnectionError = false; // Reset del estado de error
    });
    
    try {
      final perfil = await _perfilService.obtenerPerfil();
      
      if (perfil != null) {
        print("Datos del perfil recibidos: $perfil");
        setState(() {
          _hasProfile = true;
          _hasConnectionError = false;
          _profileData = perfil;
          _nombreController.text = perfil['nombre']?.toString() ?? '';
          _telefonoController.text = perfil['telefono']?.toString() ?? '';
          _currentImageUrl = perfil['imagenPerfil']?.toString();
          
          // Manejo especial para la dirección
          _llenarControllersDireccion(perfil['direccion']);
        });
      } else {
        if (_perfilService.message == "sin_conexion") {
          setState(() {
            _hasConnectionError = true;
            _hasProfile = false;
          });
          _mostrarToast("Sin conexión a internet", isError: true);
        } else {
          setState(() {
            _hasProfile = false;
            _hasConnectionError = false;
          });
        }
      }
    } catch (e) {
      print("Error al cargar perfil: $e");
      setState(() {
        _hasConnectionError = true;
        _hasProfile = false;
      });
      _mostrarToast("Error al cargar perfil: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // CREAR NUEVO PERFIL - CORREGIDO
  // -------------------------------
  Future<void> _crearPerfil() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarToast("El nombre es obligatorio", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // CORREGIDO: El método crearPerfil del service solo acepta nombre, credenciales e imagenPerfil
      // No acepta otros parámetros como direccionData o telefono
      
      // Primer paso: crear el perfil básico
      final success = await _perfilService.crearPerfil(
        _nombreController.text.trim(),
        "user_credentials", // Este parámetro puede necesitar ser dinámico según tu lógica
        imagenPerfil: _selectedImage?.path,
      );

      if (success) {
        // Segundo paso: actualizar con datos adicionales si es necesario
        final direccionData = _construirObjetoDireccion();
        final hasAdditionalData = _telefonoController.text.trim().isNotEmpty ||
            direccionData.values.any((value) => value.isNotEmpty);

        if (hasAdditionalData) {
          final updateSuccess = await _perfilService.actualizarPerfil(
            telefono: _telefonoController.text.trim().isNotEmpty 
                ? _telefonoController.text.trim() : null,
            direccion: direccionData.values.any((value) => value.isNotEmpty) 
                ? direccionData : null,
          );

          if (!updateSuccess) {
            _mostrarToast("Perfil creado, pero no se pudieron actualizar algunos datos", isError: true);
          }
        }

        _mostrarToast("Perfil creado exitosamente");
        _cargarPerfil();
      } else {
        final mensaje = _perfilService.message ?? "Error desconocido";
        _mostrarToast(_obtenerMensajeError(mensaje), isError: true);
      }
    } catch (e) {
      _mostrarToast("Error al crear perfil: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // ACTUALIZAR PERFIL EXISTENTE - CORREGIDO
  // -------------------------------
  Future<void> _actualizarPerfil() async {
    setState(() => _isLoading = true);

    try {
      // CORREGIDO: Usar los parámetros correctos del service
      final direccionData = _construirObjetoDireccion();
      
      final success = await _perfilService.actualizarPerfil(
        nombre: _nombreController.text.trim().isNotEmpty 
            ? _nombreController.text.trim() : null,
        // CORREGIDO: El parámetro es 'direccion' y espera un Map<String, dynamic>
        direccion: direccionData.values.any((value) => value.isNotEmpty) 
            ? direccionData.cast<String, dynamic>() : null,
        telefono: _telefonoController.text.trim().isNotEmpty 
            ? _telefonoController.text.trim() : null,
      );

      if (success) {
        _mostrarToast("Perfil actualizado exitosamente");
        setState(() => _isEditing = false);
        _cargarPerfil();
      } else {
        final mensaje = _perfilService.message ?? "Error desconocido";
        _mostrarToast(_obtenerMensajeError(mensaje), isError: true);
      }
    } catch (e) {
      _mostrarToast("Error al actualizar perfil: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // GESTIÓN DE IMAGEN MEJORADA
  // -------------------------------
  void _mostrarOpcionesImagen() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: ProfileDecorations.getModalDecoration(),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: ProfileDecorations.getModalHandleDecoration(),
              ),
              SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
              Text(
                "Opciones de imagen",
                style: ProfileTextStyles.getSectionTitleStyle(context),
              ),
              SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: ProfileDimensions.getSmallSpacing(context),
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: ProfileDecorations.getIconContainerDecoration(ProfileColors.primary),
                  child: Icon(Icons.photo_library, color: ProfileColors.primary),
                ),
                title: Text(
                  "Seleccionar desde galería",
                  style: ProfileTextStyles.getLabelStyle(context),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen();
                },
              ),
              if (_selectedImage != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ProfileDimensions.getSmallSpacing(context),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: ProfileDecorations.getIconContainerDecoration(ProfileColors.green),
                    child: Icon(Icons.cloud_upload, color: ProfileColors.green),
                  ),
                  title: Text(
                    "Subir imagen seleccionada",
                    style: ProfileTextStyles.getLabelStyle(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _actualizarImagenPerfil();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ProfileDimensions.getSmallSpacing(context),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: ProfileDecorations.getIconContainerDecoration(ProfileColors.textSecondary),
                    child: Icon(Icons.cancel, color: ProfileColors.textSecondary),
                  ),
                  title: Text(
                    "Cancelar selección",
                    style: ProfileTextStyles.getLabelStyle(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedImage = null);
                  },
                ),
              ],
              if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) ...[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: ProfileDimensions.getSmallSpacing(context),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: ProfileDecorations.getIconContainerDecoration(ProfileColors.red),
                    child: Icon(Icons.delete, color: ProfileColors.red),
                  ),
                  title: Text(
                    "Eliminar imagen actual",
                    style: ProfileTextStyles.getLabelStyle(context),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarImagenPerfil();
                  },
                ),
              ],
              SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarImagen() async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 70,
    );

    if (imagen != null) {
      setState(() {
        _selectedImage = File(imagen.path);
      });
    }
  }

  // -------------------------------
  // ACTUALIZAR IMAGEN DE PERFIL
  // -------------------------------
  Future<void> _actualizarImagenPerfil() async {
    if (_selectedImage == null) {
      _mostrarToast("Selecciona una imagen primero", isError: true);
      return;
    }

    setState(() => _isUploadingImage = true);

    try {
      final success = await _perfilService.actualizarImagenPerfil(_selectedImage!.path);

      if (success) {
        _mostrarToast("Imagen actualizada exitosamente");
        setState(() => _selectedImage = null);
        _cargarPerfil();
      } else {
        final mensaje = _perfilService.message ?? "Error desconocido";
        _mostrarToast(_obtenerMensajeError(mensaje), isError: true);
      }
    } catch (e) {
      _mostrarToast("Error al actualizar imagen: $e", isError: true);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // -------------------------------
  // ELIMINAR IMAGEN DE PERFIL
  // -------------------------------
  Future<void> _eliminarImagenPerfil() async {
    final confirm = await _mostrarDialogoConfirmacion(
      "¿Eliminar imagen?",
      "¿Estás seguro de que quieres eliminar tu imagen de perfil?"
    );

    if (!confirm) return;

    setState(() => _isUploadingImage = true);

    try {
      final success = await _perfilService.eliminarImagenPerfil();

      if (success) {
        _mostrarToast("Imagen eliminada exitosamente");
        setState(() {
          _currentImageUrl = null;
          _selectedImage = null;
        });
        _cargarPerfil();
      } else {
        final mensaje = _perfilService.message ?? "Error desconocido";
        _mostrarToast(_obtenerMensajeError(mensaje), isError: true);
      }
    } catch (e) {
      _mostrarToast("Error al eliminar imagen: $e", isError: true);
    } finally {
      setState(() => _isUploadingImage = false);
    }
  }

  // -------------------------------
  // NUEVO WIDGET PARA SIN CONEXIÓN
  // -------------------------------
  Widget _buildNoConnectionWidget() {
    return Center(
      child: Container(
        padding: ProfileDimensions.getContentPadding(context),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono de sin WiFi con diseño atractivo
            Container(
              padding: EdgeInsets.all(ProfileDimensions.getLargeSpacing(context)),
              decoration: BoxDecoration(
                color: ProfileColors.surfaceContainer,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: ProfileDimensions.getFontSize(context, 60, 80, 100),
                color: ProfileColors.textSecondary,
              ),
            ),
            
            SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
            
            // Título principal
            Text(
              "Sin conexión",
              style: ProfileTextStyles.getMainTitleStyle(context).copyWith(
                color: ProfileColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
            
            // Mensaje descriptivo
            Text(
              "Verifica tu conexión a internet\npara cargar tu perfil",
              style: ProfileTextStyles.getSubtitleStyle(context),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: ProfileDimensions.getLargeSpacing(context) * 1.5),
            
            // Botón de reintento
            Container(
              width: ProfileDimensions.getSpacing(context, 200, 250, 300),
              height: ProfileDimensions.getButtonHeight(context),
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _cargarPerfil,
                style: ProfileButtonStyles.getPrimaryButtonStyle(),
                icon: _isLoading 
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: ProfileDimensions.iconSizeMedium,
                    ),
                label: Text(
                  _isLoading ? "Reintentando..." : "Reintentar",
                  style: ProfileTextStyles.getButtonTextStyle(context),
                ),
              ),
            ),
            
            SizedBox(height: ProfileDimensions.getMediumSpacing(context)),
            
            // Botón secundario para ir atrás
            TextButton(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const BienvenidaUsuarioScreen()),
                  (Route<dynamic> route) => false,
                );
              },
              style: ProfileButtonStyles.getTextButtonStyle(),
              child: Text(
                "Volver al inicio",
                style: ProfileTextStyles.getActionButtonStyle(
                  context, 
                  color: ProfileColors.primary
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // HELPERS
  // -------------------------------
  String _obtenerMensajeError(String mensaje) {
    switch (mensaje) {
      case "sin_conexion":
        return "Sin conexión a internet";
      case "no_autorizado":
        return "Sesión expirada. Por favor inicia sesión nuevamente";
      case "timeout":
        return "La operación tomó demasiado tiempo. Inténtalo de nuevo";
      default:
        return mensaje;
    }
  }

  void _mostrarToast(String mensaje, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: mensaje,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: isError ? ProfileColors.red : ProfileColors.green,
      textColor: Colors.white,
      fontSize: ProfileTextStyles.getToastFontSize(context),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion(String titulo, String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: ProfileDecorations.getDialogShape(),
        title: Text(
          titulo,
          style: ProfileTextStyles.getDialogTitleStyle(context),
        ),
        content: Text(
          mensaje,
          style: ProfileTextStyles.getDialogContentStyle(context),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: ProfileButtonStyles.getTextButtonStyle(),
            child: Text(
              "Cancelar",
              style: ProfileTextStyles.getDialogActionStyle(context),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ProfileButtonStyles.getCancelTextButtonStyle(),
            child: Text(
              "Eliminar",
              style: ProfileTextStyles.getDialogActionStyle(context),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // -------------------------------
  // WIDGETS DE LA INTERFAZ
  // -------------------------------
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: ProfileDimensions.getContentPadding(context),
      decoration: ProfileDecorations.getHeaderDecoration(),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: ProfileDecorations.getAvatarBorderDecoration(),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: ProfileDimensions.getAvatarRadius(context),
                      backgroundColor: ProfileColors.surfaceContainer,
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                              ? NetworkImage(_currentImageUrl!)
                              : null,
                      child: (_selectedImage == null && 
                             (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                          ? Icon(
                              Icons.person, 
                              size: ProfileDimensions.getAvatarIconSize(context), 
                              color: ProfileColors.textHint
                            )
                          : null,
                    ),
                    if (_isUploadingImage)
                      ProfileButtonStyles.getImageLoadingOverlay(),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _mostrarOpcionesImagen,
                  child: Container(
                    padding: EdgeInsets.all(ProfileDimensions.getCameraIconPadding(context)),
                    decoration: BoxDecoration(
                      gradient: _selectedImage != null 
                          ? ProfileColors.orangeGradient
                          : ProfileColors.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: _selectedImage != null 
                          ? ProfileColors.orangeShadow 
                          : ProfileColors.blueShadow,
                    ),
                    child: Icon(
                      _selectedImage != null ? Icons.photo : Icons.camera_alt,
                      color: Colors.white,
                      size: ProfileDimensions.getCameraIconSize(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ProfileDimensions.getMediumSpacing(context)),
          Text(
            _nombreController.text.isNotEmpty ? _nombreController.text : "Usuario",
            style: ProfileTextStyles.getMainTitleStyle(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: ProfileDimensions.getBadgePadding(context),
            decoration: ProfileDecorations.getBadgeDecoration(),
            child: Text(
              "Mi Perfil",
              style: ProfileTextStyles.getBadgeStyle(context),
            ),
          ),
          if (_selectedImage != null) ...[
            SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
            Container(
              padding: ProfileDimensions.getNotificationPadding(context),
              decoration: ProfileDecorations.getNotificationDecoration(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: ProfileColors.orange, size: ProfileDimensions.iconSizeSmall),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Imagen seleccionada - Toca el ícono para subir",
                      style: ProfileTextStyles.getNotificationStyle(context),
                      textAlign: TextAlign.center,
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

  // INPUT FIELD MEJORADO - ESTILO MERCADOLIBRE
  Widget _buildModernInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
    int maxLines = 1,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ProfileDimensions.getFieldSpacing(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label con icono
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: ProfileDimensions.iconSizeMedium,
                  color: ProfileColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: ProfileTextStyles.getLabelStyle(context),
                ),
                if (isRequired) ...[
                  const SizedBox(width: 4),
                  Text(
                    '*',
                    style: ProfileTextStyles.getRequiredLabelStyle(),
                  ),
                ],
              ],
            ),
          ),
          // Campo de texto
          Container(
            decoration: ProfileDecorations.getInputFieldDecoration(),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines,
              style: ProfileTextStyles.getInputStyle(context),
              decoration: InputDecoration(
                hintText: hint ?? "Ingresa tu $label",
                hintStyle: ProfileTextStyles.getHintStyle(context),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: ProfileDimensions.getInputContentPadding(context),
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET DE INFORMACIÓN EN MODO VISTA
  Widget _buildInfoDisplayCard({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: ProfileDimensions.getCardSpacing(context)),
      padding: ProfileDimensions.getCardPadding(context),
      decoration: ProfileDecorations.getCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: ProfileDecorations.getLargeIconContainerDecoration(
                  iconColor ?? ProfileColors.primary
                ),
                child: Icon(
                  icon,
                  color: iconColor ?? ProfileColors.primary,
                  size: ProfileDimensions.iconSizeLarge,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: ProfileTextStyles.getLabelStyle(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 42),
            child: Text(
              value.isEmpty ? "No especificado" : value,
              style: value.isEmpty 
                  ? ProfileTextStyles.getEmptyValueStyle(context)
                  : ProfileTextStyles.getDisplayValueStyle(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    if (_isEditing || !_hasProfile) {
      return _buildModernInputField(
        controller: controller,
        label: label,
        icon: icon,
        keyboardType: keyboardType,
        isRequired: isRequired,
      );
    } else {
      return _buildInfoDisplayCard(
        icon: icon,
        label: label,
        value: value,
      );
    }
  }

  // WIDGET MEJORADO PARA LA DIRECCIÓN
  Widget _buildDireccionCard() {
    final direccionCompleta = _formatearDireccionCompleta();
    
    if (_isEditing || !_hasProfile) {
      return Container(
        margin: EdgeInsets.only(bottom: ProfileDimensions.getFieldSpacing(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header de la sección
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: ProfileDecorations.getLargeIconContainerDecoration(ProfileColors.green),
                    child: Icon(
                      Icons.location_on,
                      color: ProfileColors.green,
                      size: ProfileDimensions.iconSizeLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "Dirección",
                    style: ProfileTextStyles.getSectionTitleStyle(context),
                  ),
                ],
              ),
            ),
            // Campos de dirección
            Container(
              padding: ProfileDimensions.getCardPadding(context),
              decoration: ProfileDecorations.getAddressContainerDecoration(),
              child: Column(
                children: [
                  // Fila superior: Departamento y Ciudad
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernInputField(
                          controller: _departamentoController,
                          label: "Departamento",
                          icon: Icons.map,
                          hint: "Ej: Antioquia",
                        ),
                      ),
                      SizedBox(width: ProfileDimensions.getSpacing(context, 12, 16, 20)),
                      Expanded(
                        child: _buildModernInputField(
                          controller: _municipioController,
                          label: "Ciudad",
                          icon: Icons.location_city,
                          hint: "Ej: Medellín",
                        ),
                      ),
                    ],
                  ),
                  // Dirección completa
                  _buildModernInputField(
                    controller: _calleController,
                    label: "Dirección",
                    icon: Icons.home,
                    hint: "Ej: Carrera 45 #67-89",
                  ),
                  // Código postal
                  _buildModernInputField(
                    controller: _codigoPostalController,
                    label: "Código Postal",
                    icon: Icons.markunread_mailbox,
                    hint: "Ej: 050001",
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return _buildInfoDisplayCard(
        icon: Icons.location_on,
        label: "Dirección",
        value: direccionCompleta,
        iconColor: ProfileColors.green,
      );
    }
  }

  Widget _buildCreateProfileForm() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ProfileDimensions.getMaxWidth(context)),
        child: Column(
          children: [
            Container(
              padding: ProfileDimensions.getContentPadding(context),
              child: Column(
                children: [
                  Text(
                    "Crear Perfil",
                    style: ProfileTextStyles.getCreateTitleStyle(context),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: ProfileDimensions.getFontSize(context, 8, 12, 16)),
                  Text(
                    "Completa tu información personal",
                    style: ProfileTextStyles.getSubtitleStyle(context),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildProfileHeader(),
            SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
            Padding(
              padding: ProfileDimensions.getHorizontalPadding(context),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    label: "Nombre completo",
                    value: _nombreController.text,
                    controller: _nombreController,
                    isRequired: true,
                  ),
                  _buildDireccionCard(),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: "Teléfono",
                    value: _telefonoController.text,
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
                  SizedBox(
                    width: double.infinity,
                    height: ProfileDimensions.getButtonHeight(context),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _crearPerfil,
                      style: ProfileButtonStyles.getPrimaryButtonStyle(),
                      child: _isLoading
                          ? ProfileButtonStyles.getButtonProgressIndicator(context)
                          : Text(
                              "Crear Perfil",
                              style: ProfileTextStyles.getButtonTextStyle(context),
                            ),
                    ),
                  ),
                  SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewProfileForm() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: ProfileDimensions.getMaxWidth(context)),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
            Padding(
              padding: ProfileDimensions.getHorizontalPadding(context),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    label: "Nombre completo",
                    value: _nombreController.text,
                    controller: _nombreController,
                    isRequired: true,
                  ),
                  _buildDireccionCard(),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: "Teléfono",
                    value: _telefonoController.text,
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                  ),
                  if (_isEditing) ...[
                    SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
                    _buildEditButtons(),
                  ],
                  SizedBox(height: ProfileDimensions.getLargeSpacing(context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    if (ProfileDimensions.isDesktop(context) || ProfileDimensions.isTablet(context)) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: ProfileDimensions.getButtonHeight(context),
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: ProfileButtonStyles.getSecondaryButtonStyle(),
                child: Text(
                  "Cancelar",
                  style: ProfileTextStyles.getSecondaryButtonTextStyle(context),
                ),
              ),
            ),
          ),
          SizedBox(width: ProfileDimensions.getSmallSpacing(context)),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: ProfileDimensions.getButtonHeight(context),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _actualizarPerfil,
                style: ProfileButtonStyles.getPrimaryButtonStyle(),
                child: _isLoading
                    ? ProfileButtonStyles.getButtonProgressIndicator(context)
                    : Text(
                        "Guardar Cambios",
                        style: ProfileTextStyles.getButtonTextStyle(context),
                      ),
              ),
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: ProfileDimensions.getButtonHeight(context),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _actualizarPerfil,
              style: ProfileButtonStyles.getPrimaryButtonStyle(),
              child: _isLoading
                  ? ProfileButtonStyles.getButtonProgressIndicator(context)
                  : Text(
                      "Guardar Cambios",
                      style: ProfileTextStyles.getButtonTextStyle(context),
                    ),
            ),
          ),
          SizedBox(height: ProfileDimensions.getSmallSpacing(context)),
          SizedBox(
            width: double.infinity,
            height: ProfileDimensions.getButtonHeight(context),
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: ProfileButtonStyles.getSecondaryButtonStyle(),
              child: Text(
                "Cancelar",
                style: ProfileTextStyles.getSecondaryButtonTextStyle(context),
              ),
            ),
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfileColors.surfaceVariant,
      appBar: AppBar(
        backgroundColor: ProfileColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const BienvenidaUsuarioScreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        title: Text(
          _hasConnectionError 
              ? "Perfil" 
              : (_hasProfile ? "Mi Perfil" : "Crear Perfil"),
          style: ProfileTextStyles.getAppBarTitleStyle(context),
        ),
        centerTitle: true,
        actions: [
          // Solo mostrar acciones si no hay error de conexión y se ha cargado el perfil
          if (_hasProfile && !_hasConnectionError) ...[
            if (!_isEditing) ...[
              const SettingsButton(),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              style: _isEditing 
                  ? ProfileButtonStyles.getCancelTextButtonStyle()
                  : ProfileButtonStyles.getTextButtonStyle(),
              child: Text(
                _isEditing ? "Cancelar" : "Editar",
                style: ProfileTextStyles.getActionButtonStyle(
                  context, 
                  color: _isEditing ? Colors.red : ProfileColors.primary
                ),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading && _profileData == null
          ? ProfileButtonStyles.getModalProgressIndicator()
          : _hasConnectionError
              ? _buildNoConnectionWidget() // Mostrar widget de sin conexión
              : SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: _hasProfile 
                      ? _buildViewProfileForm() 
                      : _buildCreateProfileForm(),
                ),
    );
  }
}