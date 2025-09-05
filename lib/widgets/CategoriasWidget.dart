import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/categoria_service.dart';
import '../screens/usuario/todas_categorias_screen.dart';

class CategoriasWidget extends StatefulWidget {
  final VoidCallback onVerMas;
  final Function(String) onCategoriaSeleccionada;

  const CategoriasWidget({
    Key? key,
    required this.onVerMas,
    required this.onCategoriaSeleccionada,
  }) : super(key: key);

  @override
  State<CategoriasWidget> createState() => _CategoriasWidgetState();
}

class _CategoriasWidgetState extends State<CategoriasWidget> {
  final CategoriaService _categoriaService = CategoriaService();
  List<Map<String, dynamic>> categorias = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  Future<void> _cargarCategorias() async {
    try {
      final data = await _categoriaService.obtenerCategorias();
      setState(() {
        categorias = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double avatarSize = size.width * 0.15; // 15% del ancho de pantalla
    final double fontSize = size.width * 0.03; // texto escalable
    final double iconSize = size.width * 0.12;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.wifi_off,
                size: size.width * 0.2, // icono grande y responsivo
                color: Colors.redAccent,
              ),
              SizedBox(height: size.height * 0.02),
              Text(
                "Sin conexión a internet",
                style: TextStyle(
                  fontSize: fontSize * 1.2,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: size.height * 0.01),
              Text(
                "Por favor revisa tu conexión\ne intenta nuevamente",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: fontSize, color: Colors.grey[600]),
              ),
              SizedBox(height: size.height * 0.02),
              ElevatedButton.icon(
                onPressed: _cargarCategorias,
                icon: const Icon(Icons.refresh),
                label: Text("Reintentar", style: TextStyle(fontSize: fontSize)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: size.width * 0.08,
                    vertical: size.height * 0.015,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final categoriasLimitadas = categorias.take(10).toList();

    return SizedBox(
      height: avatarSize * 2,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categoriasLimitadas.length + 1,
        itemBuilder: (context, index) {
          if (index == categoriasLimitadas.length) {
            // 👉 Item "Ver más"
            return GestureDetector(
              onTap: () {
                widget.onVerMas();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TodasCategoriasScreen(
                      onCategoriaSeleccionada: widget.onCategoriaSeleccionada,
                    ),
                  ),
                );
              },
              child: Container(
                width: avatarSize + 30,
                margin: EdgeInsets.all(size.width * 0.02),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: avatarSize / 2,
                      backgroundColor: Colors.grey.shade200,
                      child: Icon(Icons.more_horiz,
                          size: iconSize, color: Colors.black54),
                    ),
                    SizedBox(height: size.height * 0.008),
                    Text(
                      "Ver más",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }

          final categoria = categoriasLimitadas[index];
          return GestureDetector(
            onTap: () => widget.onCategoriaSeleccionada(categoria['_id']),
            child: Container(
              width: avatarSize + 30,
              margin: EdgeInsets.all(size.width * 0.02),
              child: Column(
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: categoria['imagen'] ?? '',
                      width: avatarSize,
                      height: avatarSize,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          const CircularProgressIndicator(strokeWidth: 2),
                      errorWidget: (context, url, error) => Icon(
                        Icons.category,
                        size: iconSize,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.008),
                  Text(
                    categoria['nombre'] ?? 'Sin nombre',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: fontSize),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
