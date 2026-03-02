import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';

class BackgroundImage extends StatelessWidget {
  final String imagePath;
  final double opacity;
  final Color? overlayColor;

  const BackgroundImage({
    super.key,
    this.imagePath = AppConstants.backgroundImage,
    this.opacity = 1.0,
    this.overlayColor,
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
          colorFilter: overlayColor != null
              ? ColorFilter.mode(overlayColor!, BlendMode.darken)
              : null,
        ),
      ),
    );
  }
}
