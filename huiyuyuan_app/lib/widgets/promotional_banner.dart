/// HuiYuYuan auto-playing promotional banner.
///
/// Features:
/// - multi-banner autoplay on a four-second interval
/// - page indicators
/// - manual swipe with autoplay resume
/// - differentiated gradients and decorative accents
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/l10n_provider.dart';
import '../themes/colors.dart';

/// Promotional banner metadata.
class _BannerData {
  final String tag;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final IconData icon;

  const _BannerData({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.icon,
  });
}

/// Promotional banner widget.
class PromotionalBanner extends ConsumerStatefulWidget {
  const PromotionalBanner({super.key});

  @override
  ConsumerState<PromotionalBanner> createState() => _PromotionalBannerState();
}

class _PromotionalBannerState extends ConsumerState<PromotionalBanner> {
  List<_BannerData> get _banners => [
        _BannerData(
          tag: ref.tr('promo_tag_limited'),
          title: ref.tr('promo_banner_welfare'),
          subtitle: ref.tr('promo_banner_welfare_desc'),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF2E8B57),
              Color(0xFF3CB371),
              Color(0xFF50C878),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.diamond_outlined,
        ),
        _BannerData(
          tag: ref.tr('home_new'),
          title: ref.tr('promo_banner_jade'),
          subtitle: ref.tr('promo_banner_jade_desc'),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFDAA520),
              Color(0xFFFFD700),
              Color(0xFFFFC107),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.auto_awesome_outlined,
        ),
        _BannerData(
          tag: ref.tr('promo_tag_ai'),
          title: ref.tr('promo_banner_ai'),
          subtitle: ref.tr('promo_banner_ai_desc'),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF17A2B8),
              Color(0xFF20C997),
              Color(0xFF6EDCD9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.camera_enhance_outlined,
        ),
        _BannerData(
          tag: ref.tr('promo_tag_member'),
          title: ref.tr('promo_banner_member'),
          subtitle: ref.tr('promo_banner_member_desc'),
          gradient: const LinearGradient(
            colors: [
              Color(0xFFE53935),
              Color(0xFFFF6B6B),
              Color(0xFFFF8A80),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          icon: Icons.card_giftcard_outlined,
        ),
      ];
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _autoTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 1.0);
    _startAutoPlay();
  }

  @override
  void dispose() {
    _stopAutoPlay();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final next = (_currentPage + 1) % _banners.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  void _stopAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 160,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollStartNotification) _stopAutoPlay();
                    if (n is ScrollEndNotification) _startAutoPlay();
                    return false;
                  },
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _banners.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (_, i) => _BannerPage(data: _banners[i]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Page indicators.
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_banners.length, (i) {
                final active = i == _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: active ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active
                        ? JewelryColors.primary
                        : JewelryColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

/// Single banner page.
class _BannerPage extends ConsumerWidget {
  final _BannerData data;
  const _BannerPage({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        gradient: data.gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: data.gradient.colors.first.withOpacity(0.35),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles.
          Positioned(
            right: -30,
            bottom: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 20,
            top: -20,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          // Mid-right icon.
          Positioned(
            right: 24,
            top: 0,
            bottom: 0,
            child: Center(
              child: Icon(data.icon,
                  size: 56, color: Colors.white.withOpacity(0.18)),
            ),
          ),
          // Copy block.
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: JewelryColors.gold,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data.tag,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
