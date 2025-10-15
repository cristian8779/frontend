
import 'package:flutter/material.dart';
import '../../services/ResenaService.dart';

class ResenaWidget extends StatefulWidget {
  final String productoId;
  final String nombreProducto;

  const ResenaWidget({
    Key? key,
    required this.productoId,
    required this.nombreProducto,
  }) : super(key: key);

  @override
  State<ResenaWidget> createState() => _ResenaWidgetState();
}

class _ResenaWidgetState extends State<ResenaWidget> {
  final ResenaService _resenaService = ResenaService();
  List<Map<String, dynamic>> _resenas = [];
  bool _isLoading = false;
  bool _estaAutenticado = false;
  String? _usuarioId;
  String? _usuarioNombre;
  String? _error;

  @override
  void initState() {
    super.initState();
    _verificarAutenticacion();
    _cargarResenas();
  }

  Future<void> _verificarAutenticacion() async {
    final autenticado = await _resenaService.estaAutenticado();
    final userId = await _resenaService.obtenerIdUsuarioActual();
    final userName = await _resenaService.obtenerNombreUsuarioActual();
    setState(() {
      _estaAutenticado = autenticado;
      _usuarioId = userId;
      _usuarioNombre = userName;
    });
  }

  Future<void> _cargarResenas() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resenas = await _resenaService.obtenerResenasPorProducto(widget.productoId);
      setState(() {
        _resenas = resenas;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _esPropietarioResena(Map<String, dynamic> resena) {
    if (!_estaAutenticado) {
      return false;
    }
    
    // Método 1: Comparar por userId si está disponible
    if (_usuarioId != null && _usuarioId!.isNotEmpty) {
      // Verificar si el campo 'usuario' es directamente el ID (string)
      final usuarioField = resena['usuario'];
      if (usuarioField is String) {
        final esPropio = usuarioField == _usuarioId;
        if (esPropio) print('✅ Coincidencia por usuario String');
        return esPropio;
      }
      
      // Verificar si hay un usuarioId directo
      final usuarioId = resena['usuarioId']?.toString();
      if (usuarioId != null) {
        final esPropio = usuarioId == _usuarioId;
        if (esPropio) print('✅ Coincidencia por usuarioId');
        return esPropio;
      }
    }
    
    // Método 2: Comparar por nombre de usuario (fallback)
    if (_usuarioNombre != null && _usuarioNombre!.isNotEmpty) {
      final usuarioNombre = resena['usuarioNombre']?.toString();
      if (usuarioNombre != null) {
        final esPropio = usuarioNombre.trim().toLowerCase() == _usuarioNombre!.trim().toLowerCase();
        print('🔍 Comparando: "$usuarioNombre" == "$_usuarioNombre" = $esPropio');
        return esPropio;
      }
      
      // También revisar dentro del objeto usuario
      final usuarioData = resena['usuario'];
      if (usuarioData is Map) {
        final nombre = usuarioData['nombre']?.toString();
        if (nombre != null) {
          final esPropio = nombre.trim().toLowerCase() == _usuarioNombre!.trim().toLowerCase();
          print('🔍 Comparando nombre en Map: "$nombre" == "$_usuarioNombre" = $esPropio');
          return esPropio;
        }
      }
    }
    
    print('❌ No se pudo determinar propiedad - userId: $_usuarioId, userName: $_usuarioNombre');
    print('   Reseña usuario: ${resena['usuario']}, usuarioNombre: ${resena['usuarioNombre']}');
    return false;
  }

  Future<void> _mostrarDialogoCrearResena() async {
    if (!_estaAutenticado) {
      _mostrarMensajeRequiereLogin('crear una reseña');
      return;
    }

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CrearResenaDialog(
        onResenaCreada: () async {
          await _cargarResenas();
          return true;
        },
        productoId: widget.productoId,
        resenaService: _resenaService,
        nombreProducto: widget.nombreProducto,
      ),
    );

    if (resultado == true) {
      _mostrarSnackBar(
        '¡Tu opinión ha sido publicada!',
        Colors.green.shade600,
        Icons.check_circle,
      );
    }
  }

  Future<void> _editarResena(Map<String, dynamic> resena) async {
    if (!_esPropietarioResena(resena)) {
      _mostrarSnackBar(
        'No tienes permiso para editar esta reseña',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final resultado = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditarResenaDialog(
        resena: resena,
        onResenaActualizada: () async {
          await _cargarResenas();
          return true;
        },
        resenaService: _resenaService,
      ),
    );

    if (resultado == true) {
      _mostrarSnackBar(
        'Opinión actualizada exitosamente',
        Colors.green.shade600,
        Icons.check_circle,
      );
    }
  }

  Future<void> _eliminarResena(String resenaId, Map<String, dynamic> resena) async {
    if (!_esPropietarioResena(resena)) {
      _mostrarSnackBar(
        'No tienes permiso para eliminar esta reseña',
        Colors.orange,
        Icons.warning,
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Eliminar reseña'),
        content: const Text('¿Estás seguro de que quieres eliminar esta reseña? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _resenaService.eliminarResena(
          id: resenaId,
          productoId: widget.productoId,
        );
        
        setState(() {
          _resenas.removeWhere((r) => r['_id'] == resenaId);
        });
        
        _mostrarSnackBar(
          'Reseña eliminada exitosamente',
          Colors.green.shade600,
          Icons.check_circle,
        );
      } catch (e) {
        _mostrarSnackBar(
          'Error al eliminar: $e',
          Colors.red,
          Icons.error_outline,
        );
      }
    }
  }

  void _mostrarSnackBar(String mensaje, Color backgroundColor, IconData icon) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                mensaje,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _mostrarMensajeRequiereLogin(String accion) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.login, size: 48, color: Color(0xFF3483FA)),
        title: const Text('Inicio de sesión requerido'),
        content: Text('Debes iniciar sesión para $accion.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.nombreProducto),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF333333),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFEEEEEE),
            height: 1,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeaderEstadisticas(),
          Expanded(child: _buildContenido()),
        ],
      ),
      floatingActionButton: _estaAutenticado
          ? FloatingActionButton.extended(
              onPressed: _mostrarDialogoCrearResena,
              backgroundColor: const Color(0xFF3483FA),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: Text(
                _getResponsiveText(context),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            )
          : null,
    );
  }

  String _getResponsiveText(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 360 ? 'Escribir' : 'Escribir reseña';
  }

  Widget _buildHeaderEstadisticas() {
    final promedio = _calcularPromedioCalificacion();
    final distribucion = _calcularDistribucionEstrellas();
    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
        ),
      ),
      child: Column(
        children: [
          // Layout responsive para móvil vs tablet/desktop
          if (isSmallScreen)
            Column(
              children: [
                _buildPromedioSeccion(promedio, isSmallScreen),
                const SizedBox(height: 20),
                _buildDistribucionSeccion(distribucion, isSmallScreen),
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPromedioSeccion(promedio, isSmallScreen),
                const SizedBox(width: 32),
                Expanded(child: _buildDistribucionSeccion(distribucion, isSmallScreen)),
              ],
            ),
          if (_resenas.isNotEmpty) ...[
            SizedBox(height: isSmallScreen ? 12 : 16),
            _buildEstadisticasInferiores(isSmallScreen),
          ],
        ],
      ),
    );
  }

  Widget _buildPromedioSeccion(double promedio, bool isSmallScreen) {
    return Column(
      children: [
        Text(
          promedio.toStringAsFixed(1),
          style: TextStyle(
            fontSize: isSmallScreen ? 48 : 56,
            fontWeight: FontWeight.w300,
            color: const Color(0xFF333333),
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < promedio.round() ? Icons.star : Icons.star_border,
              color: const Color(0xFFFFB800),
              size: isSmallScreen ? 16 : 18,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${_resenas.length} opinión${_resenas.length != 1 ? 'es' : ''}',
          style: TextStyle(
            fontSize: isSmallScreen ? 12 : 13,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildDistribucionSeccion(Map<int, int> distribucion, bool isSmallScreen) {
    return Column(
      children: List.generate(5, (index) {
        final stars = 5 - index;
        final count = distribucion[stars] ?? 0;
        final percentage = _resenas.isEmpty ? 0.0 : (count / _resenas.length);
        
        return Padding(
          padding: EdgeInsets.only(bottom: isSmallScreen ? 4 : 6),
          child: Row(
            children: [
              Text(
                '$stars',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: isSmallScreen ? 12 : 14,
                color: Colors.grey.shade400,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFFFFB800),
                    ),
                    minHeight: isSmallScreen ? 5 : 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 24,
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildEstadisticasInferiores(bool isSmallScreen) {
    final promedio = _calcularPromedioCalificacion();
    
    return Wrap(
      spacing: isSmallScreen ? 8 : 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceEvenly,
      children: [
        _buildIconoEstadistica(
          Icons.thumb_up_outlined,
          '${(_calcularPorcentajePositivo()).toStringAsFixed(0)}%',
          'Recomiendan',
          isSmallScreen,
        ),
        if (!isSmallScreen)
          Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
        _buildIconoEstadistica(
          Icons.verified_outlined,
          '${_resenas.length}',
          'Verificadas',
          isSmallScreen,
        ),
        if (!isSmallScreen)
          Container(width: 1, height: 40, color: const Color(0xFFEEEEEE)),
        _buildIconoEstadistica(
          Icons.trending_up,
          promedio >= 4 ? 'Alta' : promedio >= 3 ? 'Media' : 'Baja',
          'Calidad',
          isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildIconoEstadistica(IconData icon, String valor, String label, bool isSmallScreen) {
    return Column(
      children: [
        Icon(icon, size: isSmallScreen ? 20 : 24, color: const Color(0xFF3483FA)),
        const SizedBox(height: 4),
        Text(
          valor,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF333333),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 11 : 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF3483FA),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Error al cargar reseñas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargarResenas,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3483FA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_resenas.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Aún no hay opiniones',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _estaAutenticado
                    ? 'Sé el primero en compartir tu experiencia con este producto'
                    : 'Nadie ha opinado sobre este producto todavía',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarResenas,
      color: const Color(0xFF3483FA),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _resenas.length,
        itemBuilder: (context, index) {
          final resena = _resenas[index];
          final esPropietario = _esPropietarioResena(resena);
          
          return ResenaCard(
            resena: resena,
            mostrarAcciones: esPropietario,
            onEditar: () => _editarResena(resena),
            onEliminar: () => _eliminarResena(resena['_id'], resena),
          );
        },
      ),
    );
  }

  double _calcularPromedioCalificacion() {
    if (_resenas.isEmpty) return 0.0;
    final suma = _resenas.fold<double>(
      0.0,
      (sum, resena) => sum + (resena['calificacion']?.toDouble() ?? 0.0),
    );
    return suma / _resenas.length;
  }

  Map<int, int> _calcularDistribucionEstrellas() {
    final distribucion = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var resena in _resenas) {
      final cal = resena['calificacion'] ?? 0;
      if (cal >= 1 && cal <= 5) {
        distribucion[cal] = (distribucion[cal] ?? 0) + 1;
      }
    }
    return distribucion;
  }

  double _calcularPorcentajePositivo() {
    if (_resenas.isEmpty) return 0.0;
    final positivas = _resenas.where((r) => (r['calificacion'] ?? 0) >= 4).length;
    return (positivas / _resenas.length) * 100;
  }
}

class ResenaCard extends StatelessWidget {
  final Map<String, dynamic> resena;
  final bool mostrarAcciones;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const ResenaCard({
    Key? key,
    required this.resena,
    this.mostrarAcciones = false,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calificacion = resena['calificacion'] ?? 0;
    final comentario = resena['comentario'] ?? '';
    final fecha = resena['fecha'] ?? resena['fechaCreacion'] ?? resena['createdAt'] ?? '';
    
    final usuarioData = resena['usuario'];
    final usuario = usuarioData is Map ? (usuarioData['nombre'] ?? 'Usuario anónimo') : 'Usuario anónimo';
    final imagenPerfil = usuarioData is Map ? (usuarioData['imagenPerfil'] ?? '') : '';

    final width = MediaQuery.of(context).size.width;
    final isSmallScreen = width < 600;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 12 : 16,
        vertical: isSmallScreen ? 4 : 6,
      ),
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              imagenPerfil.isNotEmpty
                  ? CircleAvatar(
                      radius: isSmallScreen ? 18 : 22,
                      backgroundImage: NetworkImage(imagenPerfil),
                      backgroundColor: const Color(0xFFF5F5F5),
                    )
                  : CircleAvatar(
                      radius: isSmallScreen ? 18 : 22,
                      backgroundColor: const Color(0xFFE3F2FD),
                      child: Text(
                        usuario.isNotEmpty ? usuario[0].toUpperCase() : 'U',
                        style: TextStyle(
                          color: const Color(0xFF3483FA),
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 16 : 18,
                        ),
                      ),
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      usuario,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isSmallScreen ? 14 : 15,
                        color: const Color(0xFF333333),
                      ),
                    ),
                    if (fecha.isNotEmpty)
                      Text(
                        _formatearFecha(fecha),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                  ],
                ),
              ),
              if (mostrarAcciones)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Colors.grey.shade600, size: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  onSelected: (value) {
                    if (value == 'editar') {
                      onEditar();
                    } else if (value == 'eliminar') {
                      onEliminar();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'editar',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 20, color: Color(0xFF333333)),
                          SizedBox(width: 12),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < calificacion ? Icons.star : Icons.star_border,
                    color: const Color(0xFFFFB800),
                    size: isSmallScreen ? 16 : 18,
                  );
                }),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: calificacion >= 4
                      ? Colors.green.shade50
                      : calificacion >= 3
                          ? Colors.orange.shade50
                          : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  calificacion >= 4
                      ? 'Excelente'
                      : calificacion >= 3
                          ? 'Bueno'
                          : 'Regular',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    color: calificacion >= 4
                        ? Colors.green.shade700
                        : calificacion >= 3
                            ? Colors.orange.shade700
                            : Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          if (comentario.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comentario,
              style: TextStyle(
                fontSize: isSmallScreen ? 13 : 14,
                height: 1.5,
                color: Colors.grey.shade800,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.check_circle, size: isSmallScreen ? 12 : 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                'Compra verificada',
                style: TextStyle(
                  fontSize: isSmallScreen ? 11 : 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        return 'Hoy';
      } else if (difference.inDays == 1) {
        return 'Ayer';
      } else if (difference.inDays < 30) {
        return 'Hace ${difference.inDays} días';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return fecha;
    }
  }
}

// Los diálogos CrearResenaDialog y EditarResenaDialog permanecen igual...

class CrearResenaDialog extends StatefulWidget {
  final Future<bool> Function() onResenaCreada;
  final String productoId;
  final ResenaService resenaService;
  final String nombreProducto;

  const CrearResenaDialog({
    Key? key,
    required this.onResenaCreada,
    required this.productoId,
    required this.resenaService,
    required this.nombreProducto,
  }) : super(key: key);

  @override
  State<CrearResenaDialog> createState() => _CrearResenaDialogState();
}

class _CrearResenaDialogState extends State<CrearResenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  int _calificacion = 0;
  bool _isLoading = false;
  final _comentarioFocus = FocusNode();

  @override
  void dispose() {
    _comentarioController.dispose();
    _comentarioFocus.dispose();
    super.dispose();
  }

  Future<void> _crearResena() async {
    if (_calificacion == 0) {
      _mostrarSnackBarLocal(
        'Por favor selecciona una calificación',
        Colors.orange,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.resenaService.crearResena(
        productoId: widget.productoId,
        comentario: _comentarioController.text.trim(),
        calificacion: _calificacion,
      );

      if (!mounted) return;
      
      await widget.onResenaCreada();
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      if (!mounted) return;
      
      _mostrarSnackBarLocal(
        'Error: $e',
        Colors.red,
      );
      
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBarLocal(String mensaje, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Escribir opinión',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.nombreProducto,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Calificación con iconos grandes
                      const Text(
                        '¿Cómo calificarías este producto?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          spacing: 8,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _calificacion = index + 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: index < _calificacion
                                      ? const Color(0xFFFFF9E6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  index < _calificacion ? Icons.star : Icons.star_border,
                                  color: index < _calificacion
                                      ? const Color(0xFFFFB800)
                                      : Colors.grey.shade400,
                                  size: 44,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (_calificacion > 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _obtenerTextoCalificacion(_calificacion),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _obtenerColorCalificacion(_calificacion),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      // Comentario
                      const Text(
                        'Cuéntanos más sobre tu experiencia',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _comentarioController,
                        focusNode: _comentarioFocus,
                        decoration: InputDecoration(
                          hintText: '¿Qué te gustó o qué no te gustó? ¿Para quién es este producto?',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF3483FA), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 6,
                        maxLength: 500,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor escribe tu opinión';
                          }
                          if (value.trim().length < 10) {
                            return 'Tu opinión debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Tips
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.blue.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Tips para una buena opinión',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '• Describe tu experiencia con el producto\n'
                                    '• Menciona lo que te gustó y lo que mejorarías\n'
                                    '• Sé específico y honesto',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade800,
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Footer con botones
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _crearResena,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3483FA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Publicar opinión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  String _obtenerTextoCalificacion(int calificacion) {
    switch (calificacion) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  Color _obtenerColorCalificacion(int calificacion) {
    if (calificacion >= 4) return Colors.green.shade700;
    if (calificacion >= 3) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

class EditarResenaDialog extends StatefulWidget {
  final Map<String, dynamic> resena;
  final Future<bool> Function() onResenaActualizada;
  final ResenaService resenaService;

  const EditarResenaDialog({
    Key? key,
    required this.resena,
    required this.onResenaActualizada,
    required this.resenaService,
  }) : super(key: key);

  @override
  State<EditarResenaDialog> createState() => _EditarResenaDialogState();
}

class _EditarResenaDialogState extends State<EditarResenaDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _comentarioController;
  late int _calificacion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _comentarioController = TextEditingController(
      text: widget.resena['comentario'] ?? '',
    );
    _calificacion = widget.resena['calificacion'] ?? 5;
  }

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _actualizarResena() async {
    if (_calificacion == 0) {
      _mostrarSnackBarLocal(
        'Por favor selecciona una calificación',
        Colors.orange,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await widget.resenaService.actualizarResena(
        id: widget.resena['_id'],
        comentario: _comentarioController.text.trim(),
        calificacion: _calificacion,
      );

      if (!mounted) return;
      
      await widget.onResenaActualizada();
      
      if (mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      if (!mounted) return;
      
      _mostrarSnackBarLocal(
        'Error: $e',
        Colors.red,
      );
      
      setState(() => _isLoading = false);
    }
  }

  void _mostrarSnackBarLocal(String mensaje, Color backgroundColor) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Editar opinión',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    children: [
                      const Text(
                        'Calificación',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Wrap(
                          spacing: 8,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () => setState(() => _calificacion = index + 1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: index < _calificacion
                                      ? const Color(0xFFFFF9E6)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  index < _calificacion ? Icons.star : Icons.star_border,
                                  color: index < _calificacion
                                      ? const Color(0xFFFFB800)
                                      : Colors.grey.shade400,
                                  size: 44,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      if (_calificacion > 0) ...[
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            _obtenerTextoCalificacion(_calificacion),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _obtenerColorCalificacion(_calificacion),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      const Text(
                        'Tu opinión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _comentarioController,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu opinión aquí...',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: Color(0xFF3483FA), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        maxLines: 6,
                        maxLength: 500,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor escribe tu opinión';
                          }
                          if (value.trim().length < 10) {
                            return 'Tu opinión debe tener al menos 10 caracteres';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              // Footer
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200),
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _actualizarResena,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3483FA),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Guardar cambios',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
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

  String _obtenerTextoCalificacion(int calificacion) {
    switch (calificacion) {
      case 1:
        return 'Muy malo';
      case 2:
        return 'Malo';
      case 3:
        return 'Regular';
      case 4:
        return 'Bueno';
      case 5:
        return 'Excelente';
      default:
        return '';
    }
  }

  Color _obtenerColorCalificacion(int calificacion) {
    if (calificacion >= 4) return Colors.green.shade700;
    if (calificacion >= 3) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}