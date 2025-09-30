// lib/theme/more/more_widgets.dart
import 'package:flutter/material.dart';
import 'more_styles.dart';

class MoreWidgets {
  /// Widget para crear el header del usuario con manejo de estado de conexión
  static Widget buildUserHeader({
    required BuildContext context,
    required String nombre,
    String? imagenUrl,
    bool isLoggedIn = false,
    bool isLoadingPerfil = false,
    bool hasConnectionError = false, // Nuevo parámetro
    VoidCallback? onProfileTap,
    VoidCallback? onLoginTap,
  }) {
    final isTablet = MoreStyles.isTablet(MediaQuery.of(context).size.width);
    
    return Container(
      width: double.infinity,
      decoration: MoreStyles.userHeaderDecoration,
      padding: MoreStyles.userHeaderPadding(isTablet),
      child: Row(
        children: [
          GestureDetector(
            onTap: isLoggedIn ? onProfileTap : null,
            child: Stack(
              children: [
                Container(
                  width: MoreStyles.getAvatarSize(isTablet),
                  height: MoreStyles.getAvatarSize(isTablet),
                  decoration: MoreStyles.avatarDecoration(isTablet).copyWith(
                    // Cambiar borde si hay error de conexión
                    border: hasConnectionError && isLoggedIn 
                        ? Border.all(color: Colors.orange.withOpacity(0.7), width: 2)
                        : MoreStyles.avatarDecoration(isTablet).border,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
                    child: _buildAvatarContent(
                      nombre: nombre,
                      imagenUrl: imagenUrl,
                      isLoggedIn: isLoggedIn,
                      isLoadingPerfil: isLoadingPerfil,
                      hasConnectionError: hasConnectionError,
                      isTablet: isTablet,
                    ),
                  ),
                ),
                if (isLoggedIn && !isLoadingPerfil && !hasConnectionError) ...[
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: isTablet ? 28 : 20,
                      height: isTablet ? 28 : 20,
                      decoration: MoreStyles.editButtonDecoration(isTablet),
                      child: Icon(
                        Icons.edit,
                        size: isTablet ? 16 : 12,
                        color: MoreStyles.primaryColor,
                      ),
                    ),
                  ),
                ],
                // Mostrar ícono de conexión en lugar del botón editar cuando hay error
                if (hasConnectionError && isLoggedIn && !isLoadingPerfil) ...[
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: isTablet ? 28 : 20,
                      height: isTablet ? 28 : 20,
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.refresh,
                        size: isTablet ? 14 : 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
                if (isLoadingPerfil && isLoggedIn) ...[
                  Container(
                    width: MoreStyles.getAvatarSize(isTablet),
                    height: MoreStyles.getAvatarSize(isTablet),
                    decoration: MoreStyles.loadingOverlayDecoration.copyWith(
                      borderRadius: BorderRadius.circular(isTablet ? 40 : 32),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: isTablet ? 24 : 20,
                        height: isTablet ? 24 : 20,
                        child: const CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          MoreStyles.horizontalSpacing(isTablet, isTablet ? 24 : 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "¡Hola!",
                        style: MoreStyles.greetingTextStyle(isTablet),
                      ),
                    ),
                    // Indicador de conexión en el saludo
                    if (hasConnectionError && isLoggedIn) ...[
                      Icon(
                        Icons.wifi_off_rounded,
                        size: isTablet ? 20 : 16,
                        color: Colors.orange,
                      ),
                    ],
                  ],
                ),
                MoreStyles.verticalSpacing(isTablet, isTablet ? 6 : 4),
                Text(
                  nombre,
                  style: MoreStyles.userNameTextStyle(isTablet),
                ),
                MoreStyles.verticalSpacing(isTablet, isTablet ? 8 : 6),
                // Texto de estado adaptativo
                Text(
                  _getStatusText(isLoggedIn, hasConnectionError, isLoadingPerfil),
                  style: MoreStyles.menuItemSubtitleStyle(isTablet).copyWith(
                    color: hasConnectionError ? Colors.orange : null,
                  ),
                ),
                if (!isLoggedIn) ...[
                  MoreStyles.verticalSpacing(isTablet, isTablet ? 8 : 6),
                  GestureDetector(
                    onTap: onLoginTap,
                    child: Text(
                      "Ingresá a tu cuenta",
                      style: MoreStyles.loginLinkStyle(isTablet),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construir el contenido del avatar según el estado
  static Widget _buildAvatarContent({
    required String nombre,
    String? imagenUrl,
    required bool isLoggedIn,
    required bool isLoadingPerfil,
    required bool hasConnectionError,
    required bool isTablet,
  }) {
    // Si está cargando, no mostrar contenido (el overlay se encarga)
    if (isLoadingPerfil) {
      return buildAvatarFallback(nombre, isTablet);
    }

    // Si hay error de conexión y está loggeado, mostrar ícono de sin conexión
    if (hasConnectionError && isLoggedIn) {
      return Container(
        color: Colors.orange.withOpacity(0.1),
        child: Center(
          child: Icon(
            Icons.wifi_off_rounded,
            color: Colors.orange,
            size: isTablet ? 32 : 24,
          ),
        ),
      );
    }

    // Si no está loggeado, mostrar fallback normal
    if (!isLoggedIn) {
      return buildAvatarFallback(nombre, isTablet);
    }

    // Si tiene imagen y no hay error de conexión, mostrarla
    if (imagenUrl != null && imagenUrl != 'connection_error') {
      return Image.network(
        imagenUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => 
            buildAvatarFallback(nombre, isTablet),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: MoreStyles.backgroundColor,
            child: Center(
              child: SizedBox(
                width: isTablet ? 20 : 16,
                height: isTablet ? 20 : 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: MoreStyles.primaryColor,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / 
                        loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            ),
          );
        },
      );
    }

    // Por defecto, mostrar fallback
    return buildAvatarFallback(nombre, isTablet);
  }

  /// Obtener texto de estado según la situación
  static String _getStatusText(bool isLoggedIn, bool hasConnectionError, bool isLoadingPerfil) {
    if (isLoadingPerfil) {
      return 'Cargando perfil...';
    }
    
    if (hasConnectionError && isLoggedIn) {
      return 'Sin conexión • Toca para reintentar';
    }
    
    if (!isLoggedIn) {
      return 'Toca para iniciar sesión';
    }
    
    return 'Toca para ver opciones de perfil';
  }

  /// Widget fallback para el avatar cuando no hay imagen
  static Widget buildAvatarFallback(String nombre, bool isTablet) {
    return Center(
      child: Text(
        nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
        style: MoreStyles.avatarTextStyle(isTablet),
      ),
    );
  }

  /// Widget para mostrar errores (ya no se usa para conexión, pero se mantiene por compatibilidad)
  static Widget buildErrorCard({
    required BuildContext context,
    required String? errorMessage,
    VoidCallback? onRetry,
  }) {
    final isTablet = MoreStyles.isTablet(MediaQuery.of(context).size.width);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MoreStyles.getCardMargin(isTablet)),
      padding: MoreStyles.errorCardPadding(isTablet),
      decoration: MoreStyles.errorCardDecoration,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: MoreStyles.destructiveTextColor,
            size: isTablet ? 24 : 20,
          ),
          MoreStyles.horizontalSpacing(isTablet, isTablet ? 16 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error al cargar datos',
                  style: MoreStyles.errorTitleStyle(isTablet),
                ),
                const SizedBox(height: 4),
                Text(
                  errorMessage ?? 'Error desconocido',
                  style: MoreStyles.errorMessageStyle(isTablet),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            IconButton(
              onPressed: onRetry,
              icon: Icon(
                Icons.refresh,
                color: MoreStyles.destructiveTextColor,
                size: isTablet ? 24 : 20,
              ),
            ),
        ],
      ),
    );
  }

  /// Widget para crear una sección con título y elementos
  static Widget buildSectionCard({
    required BuildContext context,
    required String title,
    required List<MenuItem> items,
  }) {
    final isTablet = MoreStyles.isTablet(MediaQuery.of(context).size.width);
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: MoreStyles.getCardMargin(isTablet)),
      decoration: MoreStyles.cardDecoration(isTablet),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: MoreStyles.sectionTitlePadding(isTablet),
            child: Text(
              title,
              style: MoreStyles.sectionTitleStyle(isTablet),
            ),
          ),
          ...items.map((item) => buildMenuItem(context, item)).toList(),
        ],
      ),
    );
  }

  /// Widget para crear un elemento de menú con soporte para estado deshabilitado
  static Widget buildMenuItem(BuildContext context, MenuItem item) {
    final isTablet = MoreStyles.isTablet(MediaQuery.of(context).size.width);
    final isDisabled = item.disabled || item.onTap == null;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : item.onTap,
        borderRadius: BorderRadius.circular(isTablet ? 12 : 8),
        child: Container(
          padding: MoreStyles.menuItemPadding(isTablet),
          child: Row(
            children: [
              Container(
                width: isTablet ? 56 : 40,
                height: isTablet ? 56 : 40,
                decoration: MoreStyles.menuIconDecoration(
                  isTablet: isTablet,
                  highlighted: item.highlighted && !isDisabled,
                  isDestructive: item.isDestructive && !isDisabled,
                ).copyWith(
                  color: isDisabled 
                      ? Colors.grey.withOpacity(0.2) 
                      : null,
                ),
                child: Icon(
                  item.icon,
                  size: MoreStyles.getIconSize(isTablet),
                  color: isDisabled
                      ? Colors.grey
                      : MoreStyles.getMenuIconColor(
                          highlighted: item.highlighted,
                          isDestructive: item.isDestructive,
                        ),
                ),
              ),
              MoreStyles.horizontalSpacing(isTablet, isTablet ? 24 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: MoreStyles.menuItemTitleStyle(
                        isTablet: isTablet,
                        isDestructive: item.isDestructive && !isDisabled,
                      ).copyWith(
                        color: isDisabled 
                            ? Colors.grey 
                            : item.isDestructive 
                                ? MoreStyles.destructiveTextColor
                                : null,
                      ),
                    ),
                    if (item.subtitle != null) ...[
                      MoreStyles.verticalSpacing(isTablet, isTablet ? 4 : 2),
                      Text(
                        item.subtitle!,
                        style: MoreStyles.menuItemSubtitleStyle(isTablet).copyWith(
                          color: isDisabled 
                              ? Colors.grey.withOpacity(0.7) 
                              : null,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isDisabled) ...[
                Icon(
                  Icons.chevron_right,
                  color: MoreStyles.tertiaryTextColor,
                  size: MoreStyles.getIconSize(isTablet),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar modal bottom sheet de opciones
  static void showOptionsBottomSheet({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption> options,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: MoreStyles.modalDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: MoreStyles.modalHandleDecoration,
            ),
            const SizedBox(height: 16),
            Text(title, style: MoreStyles.modalTitleStyle),
            const SizedBox(height: 16),
            ...options.map((option) => buildBottomSheetOption(option)).toList(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Widget para crear una opción del bottom sheet
  static Widget buildBottomSheetOption(BottomSheetOption option) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: option.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: option.isDestructive 
                      ? Colors.red.withOpacity(0.1)
                      : MoreStyles.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  option.icon,
                  color: option.isDestructive 
                      ? Colors.red 
                      : MoreStyles.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  option.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: option.isDestructive ? Colors.red : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para mostrar diálogo de carga
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        ),
      ),
    );
  }

  /// Widget para layout de escritorio (2 columnas)
  static Widget buildDesktopLayout({
    required BuildContext context,
    required List<Widget> leftColumnChildren,
    required List<Widget> rightColumnChildren,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(children: leftColumnChildren),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(children: rightColumnChildren),
        ),
      ],
    );
  }
}

/// Clase para definir elementos de menú con soporte para estado deshabilitado
class MenuItem {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap; // Cambiado a nullable
  final bool highlighted;
  final bool isDestructive;
  final bool disabled; // Nueva propiedad

  MenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.highlighted = false,
    this.isDestructive = false,
    this.disabled = false, // Valor por defecto
  });
}

/// Clase para opciones del bottom sheet
class BottomSheetOption {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  BottomSheetOption({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });
}