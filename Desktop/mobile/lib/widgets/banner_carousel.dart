import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner.dart' as banner_model;
import '../utils/app_colors.dart';

class BannerCarousel extends StatefulWidget {
  final List<banner_model.PromoBanner> banners;

  const BannerCarousel({
    super.key,
    required this.banners,
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.95);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      print('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _BannerCard(
                  banner: banner,
                  onTap: () => _launchUrl(banner.buttonLink),
                ),
              );
            },
          ),
        ),
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.banners.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentIndex == index
                        ? AppColors.primary
                        : AppColors.primary.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final banner_model.PromoBanner banner;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.onTap,
  });

  Color _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return AppColors.primary;
    }
    
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _parseColor(banner.backgroundColor);
    final textColor = _parseColor(banner.textColor ?? '#FFFFFF');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgColor,
              bgColor.withOpacity(0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background image if exists
            if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
              Positioned.fill(
                child: Image.network(
                  banner.imageUrl!,
                  fit: BoxFit.cover,
                  opacity: const AlwaysStoppedAnimation(0.3),
                  errorBuilder: (context, error, stackTrace) {
                    return const SizedBox.shrink();
                  },
                ),
              ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              banner.title,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (banner.subtitle != null &&
                                banner.subtitle!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                banner.subtitle!,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                        if (banner.buttonText != null &&
                            banner.buttonText!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              banner.buttonText!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: bgColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (banner.imageUrl != null && banner.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          banner.imageUrl!,
                          width: 80,
                          height: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 120,
                              color: textColor.withOpacity(0.1),
                              child: Icon(
                                Icons.image_not_supported,
                                color: textColor.withOpacity(0.3),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
