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
    _pageController = PageController(viewportFraction: 1.0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _launchUrl(String? url) async {
    if (url == null || url.trim().isEmpty) return;
    var trimmed = url.trim();
    var uri = Uri.tryParse(trimmed);
    if (uri == null) return;
    if (!uri.hasScheme) {
      uri = Uri.tryParse('https://$trimmed');
    }
    if (uri == null || !uri.hasScheme) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentBanner = widget.banners[_currentIndex];
    final currentHasImage = currentBanner.imageUrl != null && currentBanner.imageUrl!.trim().isNotEmpty;
    final hasSubtitle = currentBanner.subtitle != null && currentBanner.subtitle!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 135, // Proportional height to match standard banner aspect ratio
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: widget.banners.length,
                itemBuilder: (context, index) {
                  final banner = widget.banners[index];
                  return _BannerCard(
                    banner: banner,
                    onTap: () {
                      final link = banner.buttonLink?.trim();
                      if (link != null && link.isNotEmpty) {
                        _launchUrl(link);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
        // Only show subtitle below if it is a custom subtitle OR if the banner has no image (text-only fallback)
        if (hasSubtitle || !currentHasImage) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              hasSubtitle
                  ? currentBanner.subtitle!
                  : 'Your success, our mission. Discover exclusive career coaching and placement services.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.start,
            ),
          ),
        ],
        if (widget.banners.length > 1) ...[
          const SizedBox(height: 10),
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
                  width: 7,
                  height: 7,
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
    final textTheme = Theme.of(context).textTheme;
    final isSuperSale = banner.title.toUpperCase().contains('SUPER SALE');
    final hasImage = banner.imageUrl != null && banner.imageUrl!.trim().isNotEmpty;
    final bgColor = _parseColor(banner.backgroundColor);
    final textColor = _parseColor(banner.textColor ?? '#FFFFFF');
    final fgColor = hasImage ? Colors.white : textColor;
    final hasLink = banner.buttonLink != null && banner.buttonLink!.trim().isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: hasLink ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (isSuperSale)
                _buildSuperSaleDesign()
              else if (hasImage)
                Image.network(
                  banner.imageUrl!.trim(),
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) => ColoredBox(color: bgColor),
                )
              else
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bgColor, bgColor.withOpacity(0.85)],
                    ),
                  ),
                ),
              if (!isSuperSale && !hasImage)
                Builder(
                  builder: (context) {
                    final cleanTitle = banner.title.trim().toLowerCase();
                    final isPlaceholderTitle = cleanTitle == 'jobs' || cleanTitle == 'banner' || cleanTitle.isEmpty;
                    final showOverlay = !isPlaceholderTitle;
                    
                    if (!showOverlay && (banner.subtitle == null || banner.subtitle!.trim().isEmpty)) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: hasImage ? MainAxisAlignment.end : MainAxisAlignment.center,
                        children: [
                          if (showOverlay)
                            Text(
                              banner.title,
                              style: textTheme.titleLarge?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: fgColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (banner.subtitle?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            Text(
                              banner.subtitle!,
                              style: TextStyle(
                                fontSize: 13,
                                color: fgColor.withOpacity(0.9),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                      if (banner.buttonText?.isNotEmpty == true) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            banner.buttonText!,
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: bgColor),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperSaleDesign() {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFF1E293B)),
      child: Stack(
        children: [
          Positioned(
            right: -50, top: -20, bottom: -20, width: 260,
            child: Transform.rotate(
              angle: -0.15,
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFACC15),
                  borderRadius: BorderRadius.horizontal(left: Radius.circular(100)),
                ),
              ),
            ),
          ),
          Positioned(
            right: 30, top: 0, bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('END OF YEAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2)),
                const Text('SUPER', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, height: 1)),
                const Text('SALE', style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Color(0xFF1E293B), height: 1)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: const Text('UP TO 50% OFF', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          ),
          Positioned(
            left: 24, top: 40,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.flash_on_rounded, color: Color(0xFFFACC15), size: 40),
            ),
          ),
        ],
      ),
    );
  }
}
