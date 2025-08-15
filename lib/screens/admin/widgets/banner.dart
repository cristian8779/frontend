import 'package:flutter/material.dart';

class BannerWidget extends StatelessWidget {
  final MediaQueryData media;
  
  const BannerWidget({super.key, required this.media});
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFBE0C0C);
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth > 600;
        final isLargeTablet = constraints.maxWidth > 900;
        final isMobile = constraints.maxWidth <= 600;
        
        // Responsive values
        final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
        final verticalPadding = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);
        final borderRadius = isTablet ? 20.0 : 16.0;
        
        // Typography
        final titleFontSize = isLargeTablet ? 28.0 : (isTablet ? 24.0 : 20.0);
        final subtitleFontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : 14.0);
        
        // Spacing
        final titleSpacing = isTablet ? 12.0 : 8.0;
        final contentSpacing = isTablet ? 20.0 : 12.0;
        
        // Image sizing
        final imageHeight = isLargeTablet 
            ? media.size.height * 0.16 
            : (isTablet ? media.size.height * 0.14 : media.size.height * 0.12);
        
        // Layout orientation for very small screens
        final useVerticalLayout = isMobile && constraints.maxWidth < 360;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(borderRadius),
            // Add subtle shadow for tablets
            boxShadow: isTablet ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ] : null,
          ),
          child: useVerticalLayout 
              ? _buildVerticalLayout(
                  titleFontSize, 
                  subtitleFontSize, 
                  titleSpacing, 
                  imageHeight,
                  contentSpacing,
                )
              : _buildHorizontalLayout(
                  titleFontSize, 
                  subtitleFontSize, 
                  titleSpacing, 
                  imageHeight,
                  contentSpacing,
                  isTablet,
                ),
        );
      },
    );
  }
  
  Widget _buildHorizontalLayout(
    double titleFontSize,
    double subtitleFontSize,
    double titleSpacing,
    double imageHeight,
    double contentSpacing,
    bool isTablet,
  ) {
    return Row(
      children: [
        Expanded(
          flex: isTablet ? 3 : 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Centro de Control",
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: isTablet ? 0.5 : 0,
                ),
              ),
              SizedBox(height: titleSpacing),
              Text(
                "Bienvenido, aquí podrás gestionar tu negocio.",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: subtitleFontSize,
                  height: 1.4,
                ),
                maxLines: isTablet ? 3 : 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: contentSpacing),
        Flexible(
          flex: 1,
          child: Image.asset(
            'assets/control.png',
            height: imageHeight,
            fit: BoxFit.contain,
            // Add error handling
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: imageHeight,
                width: imageHeight * 0.8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.dashboard_outlined,
                  color: Colors.white70,
                  size: imageHeight * 0.4,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildVerticalLayout(
    double titleFontSize,
    double subtitleFontSize,
    double titleSpacing,
    double imageHeight,
    double contentSpacing,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Centro de Control",
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: titleSpacing),
                  Text(
                    "Bienvenido, aquí podrás gestionar tu negocio.",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: subtitleFontSize,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Image.asset(
              'assets/control.png',
              height: imageHeight * 0.8,
              fit: BoxFit.contain,
              // Add error handling
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: imageHeight * 0.8,
                  width: imageHeight * 0.6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.dashboard_outlined,
                    color: Colors.white70,
                    size: imageHeight * 0.3,
                  ),
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}