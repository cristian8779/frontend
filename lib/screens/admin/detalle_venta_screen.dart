import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'styles/gestion_ventas/app_colors.dart';
import 'styles/gestion_ventas/app_styles.dart';
import 'styles/gestion_ventas/producto_card_widget.dart';

class DetalleVentaScreen extends StatelessWidget {
  final Map<String, dynamic> venta;
  final String nombreUsuario;
  final VoidCallback onUpdate;
  final bool isAdmin;
  final Function(String, String) onActualizarEstado;
  final Future<bool> Function(String) onEliminar; // ✅ CAMBIO AQUÍ

  const DetalleVentaScreen({
    super.key,
    required this.venta,
    required this.nombreUsuario,
    required this.onUpdate,
    required this.isAdmin,
    required this.onActualizarEstado,
    required this.onEliminar,
  });

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      case 'pending':
        return AppColors.warning;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoTexto(String estado) {
    switch (estado.toLowerCase()) {
      case 'approved':
        return 'PAGADO';
      case 'failed':
        return 'RECHAZADO';
      case 'pending':
        return 'PENDIENTE';
      default:
        return 'DESCONOCIDO';
    }
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'approved':
        return Icons.check_circle_rounded;
      case 'failed':
        return Icons.cancel_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final isDesktop = size.width > 1200;
    
    final productos = (venta['productos'] as List?) ?? [];
    final total = (venta['total'] ?? 0).toDouble();
    final ventaId = venta['_id'] ?? venta['id'] ?? 'sin-id';
    final estado = venta['estadoPago']?.toString() ?? 'pending';
    final fecha = venta['fecha'] != null 
        ? DateTime.tryParse(venta['fecha'].toString()) 
        : DateTime.now();

    // Padding responsive
    final horizontalPadding = isDesktop ? 40.0 : (isTablet ? 30.0 : 20.0);
    final maxWidth = isDesktop ? 900.0 : double.infinity;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalle de Venta',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: isTablet ? 20 : 18,
          ),
        ),
        actions: [
          if (isAdmin && ventaId != 'sin-id' && estado.toLowerCase() != 'pending')
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Eliminar venta',
              onPressed: () async {
                // ✅ CAMBIO AQUÍ - Ahora espera el resultado
                final eliminada = await onEliminar(ventaId);
                if (eliminada && context.mounted) {
                  // Muestra el mensaje de éxito
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Venta eliminada correctamente'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  // Navega de vuelta
                  Navigator.pop(context);
                }
              },
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                children: [
                  _buildEstadoBadge(estado, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                  _buildTicket(context, productos, total, ventaId, estado, fecha, isTablet),
                  const SizedBox(height: 16),
                  if (isAdmin && ventaId != 'sin-id' && estado.toLowerCase() == 'pending')
                    _buildAccionesPendiente(context, ventaId, isTablet),
                  SizedBox(height: isTablet ? 24 : 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEstadoBadge(String estado, bool isTablet) {
    final estadoColor = _getEstadoColor(estado);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 24 : 20, 
        vertical: isTablet ? 14 : 12,
      ),
      decoration: BoxDecoration(
        color: estadoColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estadoColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getEstadoIcon(estado),
            color: estadoColor,
            size: isTablet ? 22 : 20,
          ),
          const SizedBox(width: 8),
          Text(
            _getEstadoTexto(estado),
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
              fontWeight: FontWeight.w700,
              color: estadoColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicket(
    BuildContext context,
    List productos,
    double total,
    String ventaId,
    String estado,
    DateTime? fecha,
    bool isTablet,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTicketHeader(fecha, isTablet),
          Padding(
            padding: EdgeInsets.all(isTablet ? 24 : 20),
            child: Column(
              children: [
                _buildProductosList(productos, isTablet),
                SizedBox(height: isTablet ? 24 : 20),
                _buildDivider(),
                SizedBox(height: isTablet ? 24 : 20),
                _buildTotales(productos, total, isTablet),
                SizedBox(height: isTablet ? 24 : 20),
                _buildDivider(),
                SizedBox(height: isTablet ? 20 : 16),
                _buildTransactionId(ventaId, isTablet),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(DateTime? fecha, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 24 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isTablet ? 12 : 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.person_outline_rounded,
              size: isTablet ? 28 : 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombreUsuario,
                  style: TextStyle(
                    fontSize: isTablet ? 18 : 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fecha != null 
                      ? DateFormat('dd MMMM yyyy • HH:mm', 'es').format(fecha)
                      : 'Sin fecha',
                  style: TextStyle(
                    fontSize: isTablet ? 14 : 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.grey[300]!,
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildProductosList(List productos, bool isTablet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_bag_outlined, 
              size: isTablet ? 20 : 18, 
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              'Productos (${productos.length})',
              style: TextStyle(
                fontSize: isTablet ? 15 : 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        SizedBox(height: isTablet ? 18 : 16),
        ...productos.asMap().entries.map((entry) {
          final index = entry.key;
          final producto = entry.value;

          return Padding(
            padding: EdgeInsets.only(bottom: index < productos.length - 1 ? 12 : 0),
            child: ProductoCardWidget(producto: producto),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTotales(List productos, double total, bool isTablet) {
    final cantidadItems = productos.fold<int>(
      0, 
      (sum, p) => sum + ((p['cantidad'] ?? 1) as int),
    );

    return Column(
      children: [
        _buildTotalRow(
          'Subtotal',
          '\$${NumberFormat('#,##0', 'es_CO').format(total)}',
          false,
          isTablet,
        ),
        const SizedBox(height: 10),
        _buildTotalRow(
          'Cantidad de items',
          '$cantidadItems',
          false,
          isTablet,
        ),
        SizedBox(height: isTablet ? 24 : 20),
        Container(
          padding: EdgeInsets.all(isTablet ? 20 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.success.withOpacity(0.1),
                AppColors.success.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    color: AppColors.success,
                    size: isTablet ? 22 : 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: isTablet ? 18 : 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${NumberFormat('#,##0', 'es_CO').format(total)}',
                style: TextStyle(
                  fontSize: isTablet ? 28 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String value, bool isTotal, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTablet ? 15 : 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionId(String ventaId, bool isTablet) {
    return Container(
      padding: EdgeInsets.all(isTablet ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tag_rounded,
            size: isTablet ? 18 : 16,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ID de Transacción',
                  style: TextStyle(
                    fontSize: isTablet ? 12 : 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[500],
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ventaId,
                  style: TextStyle(
                    fontSize: isTablet ? 13 : 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                    fontFamily: 'monospace',
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccionesPendiente(BuildContext context, String ventaId, bool isTablet) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: EdgeInsets.all(isTablet ? 20 : 16),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              label: 'Aprobar',
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              isTablet: isTablet,
              onTap: () => _showConfirmDialog(
                context,
                'Aprobar Venta',
                '¿Confirmar la aprobación de esta venta?',
                () async {
                  await onActualizarEstado(ventaId, 'approved');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              label: 'Rechazar',
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              isTablet: isTablet,
              onTap: () => _showConfirmDialog(
                context,
                'Rechazar Venta',
                '¿Confirmar el rechazo de esta venta?',
                () async {
                  await onActualizarEstado(ventaId, 'failed');
                  if (context.mounted) Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required bool isTablet,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: isTablet ? 20 : 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 15 : 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[700],
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancelar',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: const Text(
              'Confirmar',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}