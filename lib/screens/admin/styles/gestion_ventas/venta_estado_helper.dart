import 'package:flutter/material.dart';
import 'app_colors.dart';

class VentaEstadoHelper {
  static String getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'pending':
        return 'Pendiente';
      case 'approved':
        return 'Aprobado';
      case 'failed':
        return 'Fallido';
      default:
        return 'Todos';
    }
  }

  static Color getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'approved':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  static IconData getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'failed':
        return Icons.cancel;
      default:
        return Icons.schedule;
    }
  }

  static Map<String, dynamic> getEstadoInfo(String estado) {
    return {
      'label': getEstadoLabel(estado),
      'color': getEstadoColor(estado),
      'icon': getEstadoIcon(estado),
    };
  }
}