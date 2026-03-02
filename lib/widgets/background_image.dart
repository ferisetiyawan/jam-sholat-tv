import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class BackgroundImage extends StatelessWidget {
  final String imagePath;
  final double overlayOpacity;

  const BackgroundImage({
    super.key,
    this.imagePath = AppConstants.backgroundImage,
    this.overlayOpacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: overlayOpacity),
            BlendMode.srcOver,
          ),
        ),
      ),
    );
  }
}
