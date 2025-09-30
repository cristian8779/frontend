import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class TodasCategoriasTheme {
  // Colores principales
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color appBarBackgroundColor = Color(0xFFF8F8F8);
  static const Color primaryColor = Color(0xFF3498DB);
  static const Color errorColor = Color(0xFFE74C3C);
  static const Color cardBackgroundColor = Colors.white;
  static const Color placeholderColor = Colors.grey;
  static const Color textPrimaryColor = Colors.black87;
  static const Color textSecondaryColor = Colors.grey;

  // AppBar Theme
  static PreferredSizeWidget buildAppBar() {
    return AppBar(
      backgroundColor: appBarBackgroundColor,
      foregroundColor: Colors.black,
      title: const Text(
        "Categorías",
        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
      ),
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    );
  }

  // Loading Indicator
  static Widget buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: primaryColor),
    );
  }

  // No Connection State
  static Widget buildNoConnectionState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.orange.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.wifi_off_rounded,
              size: 64,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(20),
            decoration: _getCardDecoration(),
            child: const Column(
              children: [
                Text(
                  "Sin conexión a internet",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 8),
                Text(
                  "Verifica tu conexión y vuelve a intentarlo",
                  style: TextStyle(fontSize: 14, color: textSecondaryColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Error State
  static Widget buildErrorState(String? errorMessage, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: errorColor.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: errorColor,
            ),
          ),
          const SizedBox(height: 24),
          if (errorMessage != null && errorMessage.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(20),
              decoration: _getCardDecoration(),
              child: Text(
                errorMessage,
                style: const TextStyle(fontSize: 14, color: errorColor),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            style: _getRetryButtonStyle(),
            icon: const Icon(Icons.refresh_rounded, size: 20),
            label: const Text(
              "Reintentar",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // Empty Categories State
  static Widget buildEmptyCategoriesState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.category_rounded,
              size: 64,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No hay categorías disponibles",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            "Intenta recargar la página",
            style: TextStyle(fontSize: 14, color: textSecondaryColor),
          ),
        ],
      ),
    );
  }

  // Refresh Indicator
  static RefreshIndicator buildRefreshIndicator({
    required Widget child,
    required Future<void> Function() onRefresh,
  }) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: primaryColor,
      child: child,
    );
  }

  // Grid Delegate
  static SliverGridDelegateWithFixedCrossAxisCount getGridDelegate({
    required int crossAxisCount,
    required double childAspectRatio,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
  }

  // Grid Padding
  static EdgeInsets getGridPadding() => const EdgeInsets.all(12);

  // Categoria Card
  static Widget buildCategoriaCard({
    required String nombre,
    required String? imagenUrl,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: _getCategoriaCardDecoration(),
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildCategoriaImage(imagenUrl),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Text(
                  nombre,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimaryColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers privados
  static BoxDecoration _getCardDecoration() {
    return BoxDecoration(
      color: cardBackgroundColor,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration _getCategoriaCardDecoration() {
    return BoxDecoration(
      color: cardBackgroundColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 8,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ],
      border: Border.all(
        color: Colors.grey.withOpacity(0.1),
        width: 1,
      ),
    );
  }

  static ButtonStyle _getRetryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      elevation: 4,
      shadowColor: primaryColor.withOpacity(0.3),
    );
  }

  static Widget _buildCategoriaImage(String? imagenUrl) {
    if (imagenUrl != null && imagenUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imagenUrl,
        fit: BoxFit.contain,
        placeholder: (context, url) => _getImagePlaceholder(isLoading: true),
        errorWidget: (context, url, error) => _getImagePlaceholder(isLoading: false),
      );
    }
    return _getImagePlaceholder(isLoading: false);
  }

  static Widget _getImagePlaceholder({required bool isLoading}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: isLoading
            ? const CircularProgressIndicator(strokeWidth: 2)
            : const Icon(
                Icons.category_rounded,
                size: 48,
                color: placeholderColor,
              ),
      ),
    );
  }

  // Responsive helpers
  static int getCrossAxisCount(double width) {
    if (width > 1200) return 6;
    if (width > 900) return 5;
    if (width > 600) return 4;
    if (width > 400) return 3;
    return 2;
  }

  static double getChildAspectRatio(double width) => 0.9;
}