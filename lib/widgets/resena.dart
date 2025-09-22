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
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarResenas();
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

  Future<void> _mostrarDialogoCrearResena() async {
    await showDialog(
      context: context,
      builder: (context) => CrearResenaDialog(
        onResenaCreada: (nuevaResena) {
          setState(() {
            _resenas.insert(0, nuevaResena);
          });
        },
        productoId: widget.productoId,
        resenaService: _resenaService,
      ),
    );
  }

  Future<void> _editarResena(Map<String, dynamic> resena) async {
    await showDialog(
      context: context,
      builder: (context) => EditarResenaDialog(
        resena: resena,
        onResenaActualizada: (resenaActualizada) {
          setState(() {
            final index = _resenas.indexWhere((r) => r['_id'] == resenaActualizada['_id']);
            if (index != -1) {
              _resenas[index] = resenaActualizada;
            }
          });
        },
        resenaService: _resenaService,
      ),
    );
  }

  Future<void> _eliminarResena(String resenaId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Estás seguro de que quieres eliminar esta reseña?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _resenaService.eliminarResena(resenaId);
        setState(() {
          _resenas.removeWhere((r) => r['_id'] == resenaId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reseña eliminada exitosamente')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reseñas - ${widget.nombreProducto}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header con estadísticas
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade600, Colors.blue.shade400],
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${_resenas.length} reseña${_resenas.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_resenas.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        _calcularPromedioCalificacion().toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: _buildContenido(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarDialogoCrearResena,
        backgroundColor: Colors.blue.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildContenido() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _cargarResenas,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_resenas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.rate_review_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay reseñas aún',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Sé el primero en escribir una reseña',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarResenas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _resenas.length,
        itemBuilder: (context, index) {
          final resena = _resenas[index];
          return ResenaCard(
            resena: resena,
            onEditar: () => _editarResena(resena),
            onEliminar: () => _eliminarResena(resena['_id']),
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
}

class ResenaCard extends StatelessWidget {
  final Map<String, dynamic> resena;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  const ResenaCard({
    Key? key,
    required this.resena,
    required this.onEditar,
    required this.onEliminar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final calificacion = resena['calificacion'] ?? 0;
    final comentario = resena['comentario'] ?? '';
    final fecha = resena['fechaCreacion'] ?? resena['createdAt'] ?? '';
    final usuario = resena['usuario']?['nombre'] ?? 'Usuario anónimo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          usuario.isNotEmpty ? usuario[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.bold,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (fecha.isNotEmpty)
                              Text(
                                _formatearFecha(fecha),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
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
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'eliminar',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: List.generate(5, (index) {
                return Icon(
                  index < calificacion ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 20,
                );
              }),
            ),
            if (comentario.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comentario,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatearFecha(String fecha) {
    try {
      final dateTime = DateTime.parse(fecha);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return fecha;
    }
  }
}

class CrearResenaDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onResenaCreada;
  final String productoId;
  final ResenaService resenaService;

  const CrearResenaDialog({
    Key? key,
    required this.onResenaCreada,
    required this.productoId,
    required this.resenaService,
  }) : super(key: key);

  @override
  State<CrearResenaDialog> createState() => _CrearResenaDialogState();
}

class _CrearResenaDialogState extends State<CrearResenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _comentarioController = TextEditingController();
  int _calificacion = 5;
  bool _isLoading = false;

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  Future<void> _crearResena() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final nuevaResena = await widget.resenaService.crearResena(
        productoId: widget.productoId,
        comentario: _comentarioController.text.trim(),
        calificacion: _calificacion,
      );

      widget.onResenaCreada(nuevaResena);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña creada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Escribir reseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calificación:'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _calificacion = index + 1),
                  child: Icon(
                    index < _calificacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                hintText: 'Comparte tu experiencia...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El comentario es requerido';
                }
                if (value.trim().length < 10) {
                  return 'El comentario debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _crearResena,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publicar'),
        ),
      ],
    );
  }
}

class EditarResenaDialog extends StatefulWidget {
  final Map<String, dynamic> resena;
  final Function(Map<String, dynamic>) onResenaActualizada;
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final resenaActualizada = await widget.resenaService.actualizarResena(
        id: widget.resena['_id'],
        comentario: _comentarioController.text.trim(),
        calificacion: _calificacion,
      );

      widget.onResenaActualizada(resenaActualizada);
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reseña actualizada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar reseña'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Calificación:'),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _calificacion = index + 1),
                  child: Icon(
                    index < _calificacion ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 30,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _comentarioController,
              decoration: const InputDecoration(
                labelText: 'Comentario',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El comentario es requerido';
                }
                if (value.trim().length < 10) {
                  return 'El comentario debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _actualizarResena,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar'),
        ),
      ],
    );
  }
}