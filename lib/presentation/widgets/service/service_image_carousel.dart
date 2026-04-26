
// service_image_carousel.dart
// Full-featured image carousel for service detail screens.

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class ServiceImageCarousel extends StatefulWidget {
  const ServiceImageCarousel({
    super.key,
    required this.imageUrls,
    this.heroTagPrefix,
    this.height = 260.0,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final String? heroTagPrefix;
  final double height;
  final ValueChanged<int>? onImageTap;

  @override
  State<ServiceImageCarousel> createState() => _ServiceImageCarouselState();
}

class _ServiceImageCarouselState extends State<ServiceImageCarousel> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return _PlaceholderImage(height: widget.height);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final url = widget.imageUrls[index];
              final heroTag = widget.heroTagPrefix != null
                  ? '${widget.heroTagPrefix}_img_$index'
                  : null;
              return GestureDetector(
                onTap: widget.onImageTap != null ? () => widget.onImageTap!(index) : null,
                child: heroTag != null
                    ? Hero(tag: heroTag, child: _CarouselImage(url: url))
                    : _CarouselImage(url: url),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: 12,
            child: _DotIndicator(
              count: widget.imageUrls.length,
              currentIndex: _currentIndex,
            ),
          ),
        if (widget.imageUrls.length > 1)
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class _CarouselImage extends StatelessWidget {
  const _CarouselImage({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: AppColors.grey200,
          child: Center(
            child: CircularProgressIndicator(
              value: progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null,
              color: AppColors.primary,
              strokeWidth: 2,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => Container(
        color: AppColors.surfaceVariant,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image_outlined, size: 40, color: AppColors.grey400),
            const SizedBox(height: 8),
            Text(
              'Image unavailable',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.grey400),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final isActive = index == currentIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 2,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      color: AppColors.surfaceVariant,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.home_repair_service_outlined,
            size: 52,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 12),
          Text(
            'No images added',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.grey400),
          ),
        ],
      ),
    );
  }
}

