import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_colors.dart';
import 'app_styles.dart';
import 'responsive_utils.dart';

class ProductoCardWidget extends StatelessWidget {
  final Map<String, dynamic> producto;

  const ProductoCardWidget({
    super.key,
    required this.producto,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = ResponsiveUtils.isMobile(context);
        final imageSize = ResponsiveUtils.getImageSize(context);

        return Container(
          margin: EdgeInsets.only(bottom: ResponsiveUtils.getCardMargin(context)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: ResponsiveUtils.getCardPadding(context),
              child: isMobile
                  ? _buildMobileLayout(imageSize)
                  : _buildDesktopLayout(imageSize),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(double imageSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProductImage(imageSize),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductTitle(true),
                  const SizedBox(height: 10),
                  _buildProductVariants(true),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildPriceSection(true),
      ],
    );
  }

  Widget _buildDesktopLayout(double imageSize) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildProductImage(imageSize),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildProductTitle(false),
              const SizedBox(height: 12),
              _buildProductVariants(false),
            ],
          ),
        ),
        const SizedBox(width: 24),
        _buildPriceSection(false),
      ],
    );
  }

  Widget _buildProductImage(double size) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.grey100, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: producto['imagen'] != null
            ? Image.network(
                producto['imagen'],
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[400]!,
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholder(false);
                },
              )
            : _buildPlaceholder(true),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDefault) {
    return Center(
      child: Icon(
        isDefault ? Icons.shopping_bag_outlined : Icons.broken_image_outlined,
        color: AppColors.grey300,
        size: 36,
      ),
    );
  }

  Widget _buildProductTitle(bool isMobile) {
    final nombreProducto = producto['nombreProducto'] ?? 'Producto';
    return Text(
      nombreProducto,
      style: TextStyle(
        fontSize: isMobile ? 15 : 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textGreyDark,
        height: 1.4,
        letterSpacing: -0.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildProductVariants(bool isMobile) {
    final talla = producto['talla'];
    final color = producto['color'];

    String colorNombre = '';
    if (color != null) {
      if (color is Map && color['nombre'] != null) {
        colorNombre = color['nombre'];
      } else if (color is String) {
        colorNombre = color;
      }
    }

    final hasVariants = talla != null || colorNombre.isNotEmpty;
    if (!hasVariants) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (talla != null)
          _buildVariantChip(
            icon: Icons.straighten_outlined,
            label: 'Talla $talla',
            isMobile: isMobile,
          ),
        if (colorNombre.isNotEmpty)
          _buildVariantChip(
            icon: Icons.palette_outlined,
            label: colorNombre,
            isMobile: isMobile,
          ),
      ],
    );
  }

  Widget _buildVariantChip({
    required IconData icon,
    required String label,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 10 : 12,
        vertical: isMobile ? 6 : 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isMobile ? 14 : 15, color: AppColors.grey400),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textGrey,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSection(bool isMobile) {
    final cantidad = producto['cantidad'] ?? 0;
    final precio = (producto['precioUnitario'] ?? producto['precio'] ?? 0).toDouble();
    final subtotal = precio * cantidad;

    return isMobile
        ? _buildMobilePriceSection(cantidad, precio, subtotal)
        : _buildDesktopPriceSection(cantidad, precio, subtotal);
  }

  Widget _buildMobilePriceSection(int cantidad, double precio, double subtotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.inputBackground,
            AppColors.grey50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100, width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Cantidad',
                  value: '$cantidad',
                  isMobile: true,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.divider,
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  icon: Icons.attach_money_rounded,
                  label: 'Precio Unit.',
                  value: '\$${NumberFormat('#,##0', 'es_CO').format(precio)}',
                  isMobile: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
                Text(
                  '\$${NumberFormat('#,##0', 'es_CO').format(subtotal)}',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopPriceSection(int cantidad, double precio, double subtotal) {
    return Container(
      constraints: const BoxConstraints(minWidth: 260),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.inputBackground,
            AppColors.grey50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.grey100, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoItem(
            icon: Icons.inventory_2_outlined,
            label: 'Cantidad',
            value: '$cantidad',
            isMobile: false,
          ),
          const SizedBox(height: 14),
          _buildInfoItem(
            icon: Icons.attach_money_rounded,
            label: 'Precio Unitario',
            value: '\$${NumberFormat('#,##0', 'es_CO').format(precio)}',
            isMobile: false,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.primary.withOpacity(0.2), width: 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Subtotal',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textGrey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${NumberFormat('#,##0', 'es_CO').format(subtotal)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required bool isMobile,
  }) {
    return Column(
      crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: isMobile ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              icon,
              size: 16,
              color: AppColors.grey400,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textGrey,
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 16 : 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textGreyDark,
            letterSpacing: -0.3,
          ),
          textAlign: isMobile ? TextAlign.center : TextAlign.left,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}