import '../../screens/usuario/bienvenida_usuario_screen.dart';
import '../../widgets/settings_button.dart';
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
  
  // Controllers para los campos de texto
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  
  // Estados
  bool _isLoading = false;
  bool _isEditing = false;
  bool _hasProfile = false;
  bool _isUploadingImage = false;
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
    _direccionController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  // Enhanced responsive helper methods
  double _getScreenWidth(BuildContext context) => MediaQuery.of(context).size.width;
  double _getScreenHeight(BuildContext context) => MediaQuery.of(context).size.height;
  
  bool _isMobile(BuildContext context) => _getScreenWidth(context) < 600;
  bool _isTablet(BuildContext context) => _getScreenWidth(context) >= 600 && _getScreenWidth(context) < 900;
  bool _isDesktop(BuildContext context) => _getScreenWidth(context) >= 900;
  
  double _getMaxWidth(BuildContext context) {
    if (_isDesktop(context)) return 700;
    if (_isTablet(context)) return 600;
    return double.infinity;
  }

  EdgeInsets _getHorizontalPadding(BuildContext context) {
    if (_isDesktop(context)) return const EdgeInsets.symmetric(horizontal: 48);
    if (_isTablet(context)) return const EdgeInsets.symmetric(horizontal: 32);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  EdgeInsets _getContentPadding(BuildContext context) {
    if (_isDesktop(context)) return const EdgeInsets.all(32);
    if (_isTablet(context)) return const EdgeInsets.all(24);
    return const EdgeInsets.all(16);
  }

  double _getAvatarRadius(BuildContext context) {
    if (_isDesktop(context)) return 70;
    if (_isTablet(context)) return 60;
    return 50;
  }

  double _getFontSize(BuildContext context, double mobile, double tablet, double desktop) {
    if (_isDesktop(context)) return desktop;
    if (_isTablet(context)) return tablet;
    return mobile;
  }

  double _getSpacing(BuildContext context, double mobile, double tablet, double desktop) {
    if (_isDesktop(context)) return desktop;
    if (_isTablet(context)) return tablet;
    return mobile;
  }

  // Función para manejar logout
  void _handleLogout() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login', // Asume que tienes una ruta de login definida
      (Route<dynamic> route) => false,
    );
  }

  // -------------------------------
  // CARGAR PERFIL EXISTENTE
  // -------------------------------
  Future<void> _cargarPerfil() async {
    setState(() => _isLoading = true);
    
    try {
      final perfil = await _perfilService.obtenerPerfil();
      
      if (perfil != null) {
        print("Datos del perfil recibidos: $perfil");
        setState(() {
          _hasProfile = true;
          _profileData = perfil;
          _nombreController.text = perfil['nombre']?.toString() ?? '';
          _direccionController.text = perfil['direccion']?.toString() ?? '';
          _telefonoController.text = perfil['telefono']?.toString() ?? '';
          _currentImageUrl = perfil['imagenPerfil']?.toString();
        });
      } else {
        if (_perfilService.message == "sin_conexion") {
          _mostrarToast("Sin conexión a internet", isError: true);
        } else {
          setState(() => _hasProfile = false);
        }
      }
    } catch (e) {
      print("Error al cargar perfil: $e");
      _mostrarToast("Error al cargar perfil: $e", isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------------------
  // CREAR NUEVO PERFIL
  // -------------------------------
  Future<void> _crearPerfil() async {
    if (_nombreController.text.trim().isEmpty) {
      _mostrarToast("El nombre es obligatorio", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imagenPath;
      if (_selectedImage != null) {
        imagenPath = _selectedImage!.path;
      }

      final success = await _perfilService.crearPerfil(
        _nombreController.text.trim(),
        "user_credentials",
        imagenPerfil: imagenPath,
      );

      if (success) {
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
  // ACTUALIZAR PERFIL EXISTENTE
  // -------------------------------
  Future<void> _actualizarPerfil() async {
    setState(() => _isLoading = true);

    try {
      final success = await _perfilService.actualizarPerfil(
        nombre: _nombreController.text.trim().isNotEmpty 
            ? _nombreController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty 
            ? _direccionController.text.trim() : null,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: _getSpacing(context, 16, 20, 24)),
              Text(
                "Opciones de imagen",
                style: TextStyle(
                  fontSize: _getFontSize(context, 16, 18, 20),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: _getSpacing(context, 16, 20, 24)),
              ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getSpacing(context, 16, 20, 24),
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.photo_library, color: Colors.blue[600]),
                ),
                title: Text(
                  "Seleccionar desde galería",
                  style: TextStyle(
                    fontSize: _getFontSize(context, 14, 16, 16),
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _seleccionarImagen();
                },
              ),
              if (_selectedImage != null) ...[
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _getSpacing(context, 16, 20, 24),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.cloud_upload, color: Colors.green[600]),
                  ),
                  title: Text(
                    "Subir imagen seleccionada",
                    style: TextStyle(
                      fontSize: _getFontSize(context, 14, 16, 16),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _actualizarImagenPerfil();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: _getSpacing(context, 16, 20, 24),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.cancel, color: Colors.grey[600]),
                  ),
                  title: Text(
                    "Cancelar selección",
                    style: TextStyle(
                      fontSize: _getFontSize(context, 14, 16, 16),
                    ),
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
                    horizontal: _getSpacing(context, 16, 20, 24),
                    vertical: 8,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.delete, color: Colors.red[600]),
                  ),
                  title: Text(
                    "Eliminar imagen actual",
                    style: TextStyle(
                      fontSize: _getFontSize(context, 14, 16, 16),
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _eliminarImagenPerfil();
                  },
                ),
              ],
              SizedBox(height: _getSpacing(context, 16, 20, 24)),
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
  // HELPERS
  // -------------------------------
  String _obtenerMensajeError(String mensaje) {
    switch (mensaje) {
      case "sin_conexion":
        return "Sin conexión a internet";
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
      backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      textColor: Colors.white,
      fontSize: _getFontSize(context, 14, 16, 16),
    );
  }

  Future<bool> _mostrarDialogoConfirmacion(String titulo, String mensaje) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          titulo,
          style: TextStyle(
            fontSize: _getFontSize(context, 16, 18, 20),
          ),
        ),
        content: Text(
          mensaje,
          style: TextStyle(
            fontSize: _getFontSize(context, 14, 16, 16),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              "Cancelar",
              style: TextStyle(
                fontSize: _getFontSize(context, 14, 16, 16),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(
              "Eliminar",
              style: TextStyle(
                fontSize: _getFontSize(context, 14, 16, 16),
              ),
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
      padding: _getContentPadding(context),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                ),
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: _getAvatarRadius(context),
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null
                          ? FileImage(_selectedImage!)
                          : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                              ? NetworkImage(_currentImageUrl!)
                              : null,
                      child: (_selectedImage == null && 
                             (_currentImageUrl == null || _currentImageUrl!.isEmpty))
                          ? Icon(
                              Icons.person, 
                              size: _getAvatarRadius(context) * 0.8, 
                              color: Colors.grey
                            )
                          : null,
                    ),
                    if (_isUploadingImage)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _mostrarOpcionesImagen,
                  child: Container(
                    padding: EdgeInsets.all(_isMobile(context) ? 8 : 10),
                    decoration: BoxDecoration(
                      color: _selectedImage != null ? Colors.orange : Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      _selectedImage != null ? Icons.photo : Icons.camera_alt,
                      color: Colors.white,
                      size: _isMobile(context) ? 18 : 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: _getSpacing(context, 16, 20, 24)),
          Text(
            _nombreController.text.isNotEmpty ? _nombreController.text : "Usuario",
            style: TextStyle(
              fontSize: _getFontSize(context, 24, 28, 32),
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: _getSpacing(context, 12, 16, 18),
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Mi Perfil",
              style: TextStyle(
                color: Colors.white,
                fontSize: _getFontSize(context, 12, 14, 14),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (_selectedImage != null) ...[
            SizedBox(height: _getSpacing(context, 12, 16, 20)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: _getSpacing(context, 16, 18, 20),
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "Imagen seleccionada - Toca el ícono para subir",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: _getFontSize(context, 11, 12, 13),
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: _getSpacing(context, 16, 20, 24)),
      padding: _getContentPadding(context).copyWith(
        top: _getSpacing(context, 16, 20, 24),
        bottom: _getSpacing(context, 16, 20, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.grey[600], size: 20),
              ),
              SizedBox(width: _getSpacing(context, 12, 14, 16)),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: _getFontSize(context, 14, 16, 18),
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              if (isRequired) ...[
                const SizedBox(width: 4),
                const Text(
                  '*',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          SizedBox(height: _getSpacing(context, 12, 16, 18)),
          if (_isEditing || !_hasProfile) ...[
            TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                fontSize: _getFontSize(context, 16, 18, 20),
                color: Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: value.isEmpty ? "Agregar $label" : null,
                hintStyle: TextStyle(
                  fontSize: _getFontSize(context, 16, 18, 20),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: _getSpacing(context, 12, 16, 18),
                  vertical: _getSpacing(context, 12, 16, 18),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ] else ...[
            Padding(
              padding: EdgeInsets.symmetric(vertical: _getSpacing(context, 8, 12, 14)),
              child: Text(
                value.isEmpty ? "Agregar $label" : value,
                style: TextStyle(
                  fontSize: _getFontSize(context, 16, 18, 20),
                  color: value.isEmpty ? Colors.grey[500] : Colors.black87,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreateProfileForm() {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
        child: Column(
          children: [
            Container(
              padding: _getContentPadding(context),
              child: Column(
                children: [
                  Text(
                    "Crear Perfil",
                    style: TextStyle(
                      fontSize: _getFontSize(context, 28, 32, 36),
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: _getSpacing(context, 8, 12, 16)),
                  Text(
                    "Completa tu información personal",
                    style: TextStyle(
                      fontSize: _getFontSize(context, 16, 18, 20),
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            _buildProfileHeader(),
            SizedBox(height: _getSpacing(context, 24, 32, 40)),
            Padding(
              padding: _getHorizontalPadding(context),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    label: "Nombre",
                    value: _nombreController.text,
                    controller: _nombreController,
                    isRequired: true,
                  ),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    label: "Dirección",
                    value: _direccionController.text,
                    controller: _direccionController,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: "Teléfono",
                    value: _telefonoController.text,
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: _getSpacing(context, 24, 32, 40)),
                  SizedBox(
                    width: double.infinity,
                    height: _getSpacing(context, 52, 60, 64),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _crearPerfil,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: _getSpacing(context, 20, 24, 26),
                              width: _getSpacing(context, 20, 24, 26),
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              "Crear Perfil",
                              style: TextStyle(
                                fontSize: _getFontSize(context, 16, 18, 20),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: _getSpacing(context, 24, 32, 40)),
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
        constraints: BoxConstraints(maxWidth: _getMaxWidth(context)),
        child: Column(
          children: [
            _buildProfileHeader(),
            SizedBox(height: _getSpacing(context, 24, 32, 40)),
            Padding(
              padding: _getHorizontalPadding(context),
              child: Column(
                children: [
                  _buildInfoCard(
                    icon: Icons.person,
                    label: "Nombre",
                    value: _nombreController.text,
                    controller: _nombreController,
                    isRequired: true,
                  ),
                  _buildInfoCard(
                    icon: Icons.location_on,
                    label: "Dirección",
                    value: _direccionController.text,
                    controller: _direccionController,
                  ),
                  _buildInfoCard(
                    icon: Icons.phone,
                    label: "Teléfono",
                    value: _telefonoController.text,
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                  ),
                  if (_isEditing) ...[
                    SizedBox(height: _getSpacing(context, 24, 32, 40)),
                    _buildEditButtons(),
                  ],
                  SizedBox(height: _getSpacing(context, 24, 32, 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButtons() {
    if (_isDesktop(context) || _isTablet(context)) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _getSpacing(context, 52, 60, 64),
              child: OutlinedButton(
                onPressed: () => setState(() => _isEditing = false),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey[400]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Cancelar",
                  style: TextStyle(
                    fontSize: _getFontSize(context, 16, 18, 20),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: _getSpacing(context, 16, 20, 24)),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: _getSpacing(context, 52, 60, 64),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _actualizarPerfil,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: _getSpacing(context, 20, 24, 26),
                        width: _getSpacing(context, 20, 24, 26),
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        "Guardar Cambios",
                        style: TextStyle(
                          fontSize: _getFontSize(context, 16, 18, 20),
                          fontWeight: FontWeight.w600,
                        ),
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
            height: _getSpacing(context, 52, 60, 64),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _actualizarPerfil,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                  ? SizedBox(
                      height: _getSpacing(context, 20, 24, 26),
                      width: _getSpacing(context, 20, 24, 26),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      "Guardar Cambios",
                      style: TextStyle(
                        fontSize: _getFontSize(context, 16, 18, 20),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: _getSpacing(context, 12, 16, 20)),
          SizedBox(
            width: double.infinity,
            height: _getSpacing(context, 52, 60, 64),
            child: OutlinedButton(
              onPressed: () => setState(() => _isEditing = false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Cancelar",
                style: TextStyle(
                  fontSize: _getFontSize(context, 16, 18, 20),
                  fontWeight: FontWeight.w600,
                ),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
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
          _hasProfile ? "Mi Perfil" : "Crear Perfil",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: _getFontSize(context, 18, 20, 22),
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasProfile) ...[
            if (!_isEditing) ...[
              SettingsButton(onLogout: _handleLogout),
              const SizedBox(width: 8),
            ],
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(
                _isEditing ? "Cancelar" : "Editar",
                style: TextStyle(
                  color: _isEditing ? Colors.red : Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: _getFontSize(context, 14, 16, 16),
                ),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading && _profileData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: _hasProfile 
                  ? _buildViewProfileForm() 
                  : _buildCreateProfileForm(),
            ),
    );
  }
}