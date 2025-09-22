import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bottom_nav_provider.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final Function(int)? onTap; // 🔹 Función que llama la pantalla al tocar

  const CustomBottomNavigationBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final bottomNavProvider = context.watch<BottomNavProvider>();

    final isUserLoggedIn = authProvider.isAuthenticated;
    final currentIndex = bottomNavProvider.currentIndex;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final dimensions = _calculateDimensions(screenWidth, screenHeight);

    return Container(
      height: dimensions.containerHeight + MediaQuery.of(context).padding.bottom,
      decoration: _buildContainerDecoration(dimensions),
      child: SafeArea(
        top: false,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: dimensions.horizontalPadding,
            vertical: dimensions.verticalPadding,
          ),
          child: Stack(
            children: [
              _buildNavigationRow(context, dimensions, isUserLoggedIn, currentIndex),
              _buildCenterButton(context, dimensions, currentIndex),
            ],
          ),
        ),
      ),
    );
  }

  NavigationDimensions _calculateDimensions(double screenWidth, double screenHeight) {
    final isSmallScreen = screenWidth < 360;
    final isMediumScreen = screenWidth >= 360 && screenWidth < 480;
    final isLargeScreen = screenWidth >= 480 && screenWidth < 768;
    final isTablet = screenWidth >= 768;
    final isShortScreen = screenHeight < 700;

    if (isTablet) {
      return NavigationDimensions(
        containerHeight: isShortScreen ? 70.0 : 75.0,
        horizontalPadding: screenWidth * 0.08,
        verticalPadding: 10.0,
        iconSize: 24.0,
        activeIconSize: 26.0,
        buttonSize: 56.0,
        borderRadius: 25.0,
        fontSize: 11.0,
        activeFontSize: 11.0,
        itemPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemBorderRadius: 16.0,
        spaceBetween: 4.0,
        isSmallScreen: false,
        isTablet: true,
      );
    } else if (isLargeScreen) {
      return NavigationDimensions(
        containerHeight: isShortScreen ? 65.0 : 70.0,
        horizontalPadding: screenWidth * 0.06,
        verticalPadding: 6.0,
        iconSize: 22.0,
        activeIconSize: 24.0,
        buttonSize: 52.0,
        borderRadius: 22.0,
        fontSize: 10.0,
        activeFontSize: 10.0,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemBorderRadius: 12.0,
        spaceBetween: 2.0,
        isSmallScreen: false,
        isTablet: false,
      );
    } else if (isMediumScreen) {
      return NavigationDimensions(
        containerHeight: isShortScreen ? 60.0 : 65.0,
        horizontalPadding: screenWidth * 0.05,
        verticalPadding: 6.0,
        iconSize: 20.0,
        activeIconSize: 22.0,
        buttonSize: 48.0,
        borderRadius: 20.0,
        fontSize: 10.0,
        activeFontSize: 10.0,
        itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemBorderRadius: 12.0,
        spaceBetween: 2.0,
        isSmallScreen: false,
        isTablet: false,
      );
    } else {
      return NavigationDimensions(
        containerHeight: isShortScreen ? 55.0 : 60.0,
        horizontalPadding: screenWidth * 0.04,
        verticalPadding: 4.0,
        iconSize: 18.0,
        activeIconSize: 20.0,
        buttonSize: 44.0,
        borderRadius: 18.0,
        fontSize: 9.0,
        activeFontSize: 9.0,
        itemPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        itemBorderRadius: 10.0,
        spaceBetween: 1.0,
        isSmallScreen: true,
        isTablet: false,
      );
    }
  }

  BoxDecoration _buildContainerDecoration(NavigationDimensions dimensions) {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(dimensions.borderRadius)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: dimensions.isTablet ? 20 : 15,
          offset: const Offset(0, -3),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: dimensions.isTablet ? 30 : 25,
          offset: const Offset(0, -8),
        ),
      ],
    );
  }

  Widget _buildNavigationRow(BuildContext context, NavigationDimensions dimensions, bool isUserLoggedIn, int currentIndex) {
    final leftItems = _getLeftNavigationItems(isUserLoggedIn);
    final rightItems = _getRightNavigationItems(isUserLoggedIn);

    return Row(
      children: [
        Expanded(
          flex: isUserLoggedIn ? 2 : 1,
          child: Row(
            mainAxisAlignment: isUserLoggedIn ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
            children: leftItems.map((item) => _buildNavItem(context: context, item: item, dimensions: dimensions, currentIndex: currentIndex)).toList(),
          ),
        ),
        SizedBox(width: dimensions.buttonSize + 16),
        Expanded(
          flex: isUserLoggedIn ? 2 : 1,
          child: Row(
            mainAxisAlignment: isUserLoggedIn ? MainAxisAlignment.spaceEvenly : MainAxisAlignment.center,
            children: rightItems.map((item) => _buildNavItem(context: context, item: item, dimensions: dimensions, currentIndex: currentIndex)).toList(),
          ),
        ),
      ],
    );
  }

  List<NavigationItem> _getLeftNavigationItems(bool isUserLoggedIn) {
    List<NavigationItem> items = [
      NavigationItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        index: 0,
        label: 'Inicio',
      ),
    ];

    if (isUserLoggedIn) {
      items.add(NavigationItem(
        icon: Icons.favorite_border_rounded,
        activeIcon: Icons.favorite_rounded,
        index: 1,
        label: 'Favoritos',
      ));
    }

    return items;
  }

  List<NavigationItem> _getRightNavigationItems(bool isUserLoggedIn) {
    List<NavigationItem> items = [];

    if (isUserLoggedIn) {
      items.add(NavigationItem(
        icon: Icons.person_outline_rounded,
        activeIcon: Icons.person_rounded,
        index: 3,
        label: 'Perfil',
      ));
    }

    items.add(NavigationItem(
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_rounded,
      index: 4,
      label: 'Más',
    ));

    return items;
  }

  Widget _buildCenterButton(BuildContext context, NavigationDimensions dimensions, int currentIndex) {
    final bottomNavProvider = context.read<BottomNavProvider>();
    final isActive = currentIndex == 2;

    return Positioned.fill(
      child: Center(
        child: GestureDetector(
          onTap: () {
            bottomNavProvider.setIndex(2);
            if (onTap != null) onTap!(2); // 🔹 Llama a la pantalla
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            width: dimensions.buttonSize,
            height: dimensions.buttonSize,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE53E3E), Color(0xFFD53F41)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53E3E).withOpacity(0.3),
                  blurRadius: dimensions.isTablet ? 12 : 10,
                  offset: Offset(0, dimensions.isTablet ? 4 : 3),
                ),
                BoxShadow(
                  color: const Color(0xFFE53E3E).withOpacity(0.15),
                  blurRadius: dimensions.isTablet ? 20 : 16,
                  offset: Offset(0, dimensions.isTablet ? 6 : 5),
                ),
              ],
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 150),
              scale: isActive ? 1.05 : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.shopping_cart_rounded,
                  color: Colors.white,
                  size: dimensions.activeIconSize * 0.85,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required NavigationItem item,
    required NavigationDimensions dimensions,
    required int currentIndex,
  }) {
    final bottomNavProvider = context.read<BottomNavProvider>();
    final isActive = item.index == currentIndex;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          bottomNavProvider.setIndex(item.index);
          if (onTap != null) onTap!(item.index); // 🔹 Llama a la pantalla
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: dimensions.itemPadding,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFE53E3E).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(dimensions.itemBorderRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? const Color(0xFFE53E3E) : const Color(0xFF757575),
                size: isActive ? dimensions.activeIconSize : dimensions.iconSize,
              ),
              SizedBox(height: dimensions.spaceBetween),
              Text(
                item.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isActive ? dimensions.activeFontSize : dimensions.fontSize,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? const Color(0xFFE53E3E) : const Color(0xFF757575),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================
// Clases auxiliares
// ==================

class NavigationDimensions {
  final double containerHeight;
  final double horizontalPadding;
  final double verticalPadding;
  final double iconSize;
  final double activeIconSize;
  final double buttonSize;
  final double borderRadius;
  final double fontSize;
  final double activeFontSize;
  final EdgeInsets itemPadding;
  final double itemBorderRadius;
  final double spaceBetween;
  final bool isSmallScreen;
  final bool isTablet;

  NavigationDimensions({
    required this.containerHeight,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.iconSize,
    required this.activeIconSize,
    required this.buttonSize,
    required this.borderRadius,
    required this.fontSize,
    required this.activeFontSize,
    required this.itemPadding,
    required this.itemBorderRadius,
    required this.spaceBetween,
    required this.isSmallScreen,
    required this.isTablet,
  });
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final String label;

  NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.label,
  });
}
