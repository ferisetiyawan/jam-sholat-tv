import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EventScreen extends StatefulWidget {
  final List<Map<String, String>> images;
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

  Widget _buildSmartImage(Map<String, String> imageData) {
    final String path = imageData['url'] ?? '';
    final String type = imageData['type']?.toUpperCase() ?? 'IMAGE';

    final bool isNetwork = path.startsWith('http');
    final bool isSvg = type == 'SVG' || path.toLowerCase().endsWith('.svg');

    if (isNetwork) {
      if (isSvg) {
        return SvgPicture.network(
          path,
          fit: BoxFit.cover,
          placeholderBuilder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      } else {
        return CachedNetworkImage(
          imageUrl: path,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image, size: 50),
        );
      }
    } else {
      if (isSvg) {
        return SvgPicture.asset(path, fit: BoxFit.cover);
      } else {
        return Image.asset(path, fit: BoxFit.cover);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) return const SizedBox.shrink();

    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return _buildSmartImage(widget.images[index]);
      },
    );
  }
}
