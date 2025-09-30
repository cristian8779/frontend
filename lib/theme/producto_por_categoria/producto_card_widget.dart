import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'producto_por_categoria_theme.dart';

class ProductoCardWidget extends StatelessWidget {
  final String id;
  final String nombre;
  final String imagenUrl;
  final double precio;

  const ProductoCardWidget({
    Key? key,
    required this.id,
    required this.nombre,
    required this.imagenUrl,
    required this.precio,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ProductoPorCategoriaTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen del producto
          Expanded(
            flex: 7,
            child: Container(
              padding: ProductoPorCategoriaTheme.cardPaddingInsets,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: ProductoPorCategoriaTheme.imageTopBorderRadius,
                child: Image.network(
                  imagenUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ProductoPorCategoriaTheme.noImageIcon,
                        ProductoPorCategoriaTheme.noImageSpacing,
                        Text(
                          'Sin imagen',
                          style: ProductoPorCategoriaTheme.noImageTextStyle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Información con precio destacado
          Padding(
            padding: ProductoPorCategoriaTheme.contentPaddingInsets,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Precio más prominente
                Container(
                  padding: ProductoPorCategoriaTheme.pricePaddingInsets,
                  decoration: ProductoPorCategoriaTheme.priceDecoration,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProductoPorCategoriaTheme.priceIcon,
                      Text(
                        NumberFormat('#,###', 'es_CO').format(precio),
                        style: ProductoPorCategoriaTheme.priceTextStyle,
                      ),
                    ],
                  ),
                ),
                ProductoPorCategoriaTheme.priceSpacing,
                Text(
                  nombre,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ProductoPorCategoriaTheme.productNameTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}