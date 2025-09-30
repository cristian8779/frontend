// banner_widget.dart
import 'package:flutter/material.dart';
import '../styles/banner/banner_styles.dart';

class BannerWidget extends StatelessWidget {
  final MediaQueryData media;
  
  const BannerWidget({super.key, required this.media});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        
        return Container(
          padding: EdgeInsets.symmetric(
            horizontal: BannerDimensions.getHorizontalPadding(maxWidth),
            vertical: BannerDimensions.getVerticalPadding(maxWidth),
          ),
          decoration: BannerDecorations.getContainerDecoration(maxWidth),
          child: BannerDimensions.useVerticalLayout(maxWidth)
              ? _buildVerticalLayout(maxWidth)
              : _buildHorizontalLayout(maxWidth),
        );
      },
    );
  }
  
  Widget _buildHorizontalLayout(double maxWidth) {
    final isTablet = BannerDimensions.isTablet(maxWidth);
    final imageHeight = BannerDimensions.getImageHeight(maxWidth, media.size);
    final contentSpacing = BannerDimensions.getContentSpacing(maxWidth);
    
    return Row(
      children: [
        Expanded(
          flex: isTablet ? 3 : 2,
          child: _buildTextContent(maxWidth, isTablet),
        ),
        SizedBox(width: contentSpacing),
        Flexible(
          flex: 1,
          child: _buildImage(imageHeight, imageHeight * 0.8),
        ),
      ],
    );
  }
  
  Widget _buildVerticalLayout(double maxWidth) {
    final imageHeight = BannerDimensions.getImageHeight(maxWidth, media.size);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextContent(maxWidth, false),
            ),
            const SizedBox(width: 8),
            _buildImage(imageHeight * 0.8, imageHeight * 0.6),
          ],
        ),
      ],
    );
  }
  
  Widget _buildTextContent(double maxWidth, bool isTablet) {
    final titleSpacing = BannerDimensions.getTitleSpacing(maxWidth);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Centro de Control",
          style: BannerTextStyles.getTitleStyle(maxWidth),
        ),
        SizedBox(height: titleSpacing),
        Text(
          "Bienvenido, aquí podrás gestionar tu negocio.",
          style: BannerTextStyles.getSubtitleStyle(maxWidth),
          maxLines: isTablet ? 3 : 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
  
  Widget _buildImage(double height, double width) {
    return Image.asset(
      'assets/control.png',
      height: height,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          decoration: BannerDecorations.getErrorContainerDecoration(),
          child: Icon(
            BannerTheme.fallbackIcon,
            color: BannerTheme.subtextColor,
            size: height * 0.4,
          ),
        );
      },
    );
  }
}