import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../widgets/custom_image_widget.dart';
import '../../../theme/app_theme.dart';

class _BannerData {
  final String imageUrl;
  final String tag;
  final String title;
  final String subtitle;
  final Color gradientStart;
  final Color gradientEnd;
  final String semanticLabel;

  const _BannerData({
    required this.imageUrl,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.gradientStart,
    required this.gradientEnd,
    required this.semanticLabel,
  });
}

class HomeBannerWidget extends StatefulWidget {
  const HomeBannerWidget({super.key});

  @override
  State<HomeBannerWidget> createState() => _HomeBannerWidgetState();
}

class _HomeBannerWidgetState extends State<HomeBannerWidget> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_BannerData> _banners = [
    _BannerData(
      imageUrl:
          'https://images.pexels.com/photos/1640777/pexels-photo-1640777.jpeg',
      tag: '🎉 Limited Time',
      title: '50% OFF on\nFirst Order',
      subtitle: 'Use code: MENAKA50',
      gradientStart: const Color(0xFF2A5E32),
      gradientEnd: const Color(0xFF3A7D44),
      semanticLabel:
          'Colorful healthy meal bowl with fresh vegetables, avocado, and grains on wooden table',
    ),
    _BannerData(
      imageUrl:
          'https://images.pexels.com/photos/958545/pexels-photo-958545.jpeg',
      tag: '🍛 New Menu',
      title: "Amma's Special\nThali is Back!",
      subtitle: 'Full meal for just ₹149',
      gradientStart: const Color(0xFF5C4A1E),
      gradientEnd: const Color(0xFF8B7355),
      semanticLabel:
          'Traditional Indian thali with multiple small bowls of curry, rice, and bread',
    ),
    _BannerData(
      imageUrl:
          'https://images.pexels.com/photos/1640772/pexels-photo-1640772.jpeg',
      tag: '⚡ Flash Deal',
      title: 'Free Delivery\nAll Weekend',
      subtitle: 'No minimum order value',
      gradientStart: const Color(0xFF1E4526),
      gradientEnd: const Color(0xFF3A7D44),
      semanticLabel:
          'Fresh green salad bowl with colorful vegetables and dressing on white background',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final nextPage = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return _BannerCard(banner: banner);
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index
                    ? AppTheme.primary
                    : AppTheme.primary.withAlpha(64),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final _BannerData banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomImageWidget(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                semanticLabel: banner.semanticLabel,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      banner.gradientStart.withAlpha(224),
                      banner.gradientEnd.withAlpha(102),
                      Colors.transparent,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
              ),
              Positioned(
                left: 20,
                top: 16,
                bottom: 16,
                right: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(64),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        banner.tag,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      banner.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        banner.subtitle,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: banner.gradientStart,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
