import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class EventScreen extends StatefulWidget {
  final List<String> images;
  final int currentIndex;
  final String currentTime;

  const EventScreen({
    super.key,
    required this.images,
    required this.currentIndex,
    required this.currentTime,
  });

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.currentIndex);
  }

  @override
  void didUpdateWidget(EventScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _pageController.animateToPage(
        widget.currentIndex,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Fungsi "Sakti" untuk merender segala jenis gambar (Local/Network & SVG/Bitmap)
  Widget _buildSmartImage(String path) {
    final bool isNetwork = path.startsWith('http');
    final bool isSvg = path.toLowerCase().endsWith('.svg');

    if (isNetwork) {
      if (isSvg) {
        return SvgPicture.network(
          path,
          fit: BoxFit.cover,
          placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
        );
      } else {
        return CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.cover,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50),
        );
      }
    } else {
      // Logic untuk Local Asset
      if (isSvg) {
        return SvgPicture.asset(path, fit: BoxFit.cover);
      } else {
        return Image.asset(path, fit: BoxFit.cover);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.images.length,
          itemBuilder: (context, index) {
            return _buildSmartImage(widget.images[index]);
          },
        ),
      ],
    );
  }
}
