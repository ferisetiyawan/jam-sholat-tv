import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/providers/config_provider.dart';

class BackgroundImage extends StatelessWidget {
  final String? imagePath;
  final double overlayOpacity;

  const BackgroundImage({super.key, this.imagePath, this.overlayOpacity = 0.5});

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final String finalPath = imagePath ?? config.backgroundImage;

    ImageProvider imageProvider;
    if (finalPath.startsWith('http')) {
      imageProvider = NetworkImage(finalPath);
    } else {
      imageProvider = AssetImage(finalPath);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: imageProvider,
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
