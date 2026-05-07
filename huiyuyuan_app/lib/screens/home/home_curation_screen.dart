/// HomeCurationScreen — 珠宝鉴赏策展首屏
///
/// This screen replaces the plain product-list as Tab 0 for customers.
/// Design goal: the user should immediately recognise this as a "jewellery
/// connoisseurship + trading platform", not a generic e-commerce grid.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n_provider.dart';
import '../../models/product_model.dart';
import '../../providers/app_settings_provider.dart';
import '../../providers/product_catalog_provider.dart';
import '../../themes/colors.dart';
import '../../widgets/image/product_image_view.dart';
import '../chat/ai_assistant_screen.dart';
import '../trade/product_detail_screen.dart';
import '../trade/product_list_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeCurationScreen extends ConsumerStatefulWidget {
  const HomeCurationScreen({super.key});

  @override
  ConsumerState<HomeCurationScreen> createState() => _HomeCurationScreenState();
}

class _HomeCurationScreenState extends ConsumerState<HomeCurationScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productCatalogProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appSettingsProvider).language;
    final catalogState = ref.watch(productCatalogProvider);
    final products = catalogState.products;

    final hotProducts =
        products.where((p) => p.isHot).take(6).toList();
    final newProducts =
        products.where((p) => p.isNew).take(8).toList();

    return Scaffold(
      backgroundColor: JewelryColors.jadeBlack,
      body: Stack(
        children: [
          const _HomeBackdrop(),
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ────────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 140,
                pinned: true,
                backgroundColor: Colors.transparent,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: _HeroBanner(lang: lang),
                  collapseMode: CollapseMode.parallax,
                ),
              ),

              // ── Material navigation chips ───────────────────────────────
              SliverToBoxAdapter(
                child: _MaterialChipsRow(lang: lang, products: products),
              ),

              // ── AI Concierge Banner ─────────────────────────────────────
              SliverToBoxAdapter(
                child: _AIConciergeBanner(lang: lang),
              ),

              // ── Today's Picks ───────────────────────────────────────────
              if (hotProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: _sectionTitle(lang, 'home_section_hot', '今日甄选', 'Today\'s Picks', '今日甄選'),
                    onMore: () => _openAllProducts(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HotProductsHorizontal(
                    products: hotProducts,
                    lang: lang,
                    onTap: (p) => _openDetail(context, p),
                  ),
                ),
              ],

              // ── New Arrivals ────────────────────────────────────────────
              if (newProducts.isNotEmpty) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(
                    title: _sectionTitle(lang, 'home_section_new', '新品上架', 'New Arrivals', '新品上架'),
                    onMore: () => _openAllProducts(context),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _NewArrivalsList(
                    products: newProducts,
                    lang: lang,
                    onTap: (p) => _openDetail(context, p),
                  ),
                ),
              ],

              // ── All products shortcut ───────────────────────────────────
              SliverToBoxAdapter(
                child: _BrowseAllBanner(onTap: () => _openAllProducts(context)),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ],
      ),
    );
  }

  String _sectionTitle(
    AppLanguage lang,
    String key,
    String zhCn,
    String en,
    String zhTw,
  ) {
    if (lang == AppLanguage.en) return en;
    if (lang == AppLanguage.zhTW) return zhTw;
    return zhCn;
  }

  void _openDetail(BuildContext context, ProductModel product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product),
      ),
    );
  }

  void _openAllProducts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductListScreen()),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Backdrop
// ─────────────────────────────────────────────────────────────────────────────

class _HomeBackdrop extends StatelessWidget {
  const _HomeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF040B08),
            Color(0xFF071410),
            Color(0xFF040B08),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        children: [
          // Subtle jade glow top-left
          Positioned(
            top: -120,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    JewelryColors.emeraldLuster.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Gold glow bottom-right
          Positioned(
            bottom: 80,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    JewelryColors.champagneGold.withOpacity(0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────

class _HeroBanner extends ConsumerWidget {
  const _HeroBanner({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subtitle = lang == AppLanguage.en
        ? 'Gemstone Connoisseurship · Authentic Origin'
        : lang == AppLanguage.zhTW
            ? '珠寶鑑賞 · 溯源正品'
            : '珠宝鉴赏 · 溯源正品';
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF071410), Color(0xFF0A1F18)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: JewelryColors.emeraldLusterGradient,
                  boxShadow: [
                    BoxShadow(
                      color: JewelryColors.emeraldGlow.withOpacity(0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.diamond_outlined,
                  color: JewelryColors.jadeBlack,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                ref.tr('app_name'),
                style: const TextStyle(
                  color: JewelryColors.champagneGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: JewelryColors.jadeMist.withOpacity(0.6),
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Material Chips Row
// ─────────────────────────────────────────────────────────────────────────────

class _MaterialChipsRow extends ConsumerWidget {
  const _MaterialChipsRow({required this.lang, required this.products});
  final AppLanguage lang;
  final List<ProductModel> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Collect unique materials with product counts
    final materialCounts = <String, int>{};
    for (final p in products) {
      final mat = p.localizedMaterialFor(lang);
      materialCounts[mat] = (materialCounts[mat] ?? 0) + 1;
    }
    final materials = materialCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Material → colour mapping for the chips
    final colorForMaterial = _materialColor;

    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        itemCount: materials.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final entry = materials[index];
          final color = colorForMaterial(entry.key);
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: color.withOpacity(0.12),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.2),
                      border: Border.all(color: color.withOpacity(0.5)),
                    ),
                    child: Icon(
                      _materialIcon(entry.key),
                      color: color,
                      size: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entry.key,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Color _materialColor(String material) {
    if (material.contains('翡翠') || material.contains('Jadeite') || material.contains('翡')) {
      return JewelryColors.jadeite;
    }
    if (material.contains('和田') || material.contains('Hetian')) {
      return JewelryColors.hetianYu;
    }
    if (material.contains('南红') || material.contains('Agate') || material.contains('瑪瑙')) {
      return JewelryColors.nanHong;
    }
    if (material.contains('紫') || material.contains('Amethyst')) {
      return JewelryColors.amethyst;
    }
    if (material.contains('金') || material.contains('Gold')) {
      return JewelryColors.champagneGold;
    }
    if (material.contains('宝石') || material.contains('Ruby') || material.contains('Sapphire')) {
      return JewelryColors.nanHong;
    }
    return JewelryColors.jadeMist;
  }

  IconData _materialIcon(String material) {
    if (material.contains('翡翠') || material.contains('Jadeite')) return Icons.spa_outlined;
    if (material.contains('和田') || material.contains('Hetian')) return Icons.circle_outlined;
    if (material.contains('南红') || material.contains('玛瑙')) return Icons.grain;
    if (material.contains('紫') || material.contains('Amethyst')) return Icons.auto_awesome;
    if (material.contains('金') || material.contains('Gold')) return Icons.star_outline;
    if (material.contains('珍珠') || material.contains('Pearl')) return Icons.lens_outlined;
    return Icons.diamond_outlined;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AI Concierge Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AIConciergeBanner extends ConsumerWidget {
  const _AIConciergeBanner({required this.lang});
  final AppLanguage lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = lang == AppLanguage.en
        ? 'AI Jewellery Concierge'
        : lang == AppLanguage.zhTW
            ? 'AI 珠寶顧問'
            : 'AI 珠宝顾问';
    final subtitle = lang == AppLanguage.en
        ? 'Ask about quality, origin, appraisal or pricing'
        : lang == AppLanguage.zhTW
            ? '詢問品質、產地、鑑定或定價'
            : '询问品质、产地、鉴定或定价';
    final cta = lang == AppLanguage.en
        ? 'Chat Now'
        : lang == AppLanguage.zhTW
            ? '立即咨詢'
            : '立即咨询';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF064E3B), Color(0xFF0A2E22)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: JewelryColors.emeraldGlow.withOpacity(0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: JewelryColors.emeraldLuster.withOpacity(0.12),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: JewelryColors.emeraldLusterGradient,
                boxShadow: [
                  BoxShadow(
                    color: JewelryColors.emeraldGlow.withOpacity(0.4),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: JewelryColors.jadeBlack,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: JewelryColors.champagneGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: JewelryColors.jadeMist.withOpacity(0.65),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: JewelryColors.emeraldLusterGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                cta,
                style: const TextStyle(
                  color: JewelryColors.jadeBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onMore});
  final String title;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              gradient: JewelryColors.emeraldLusterGradient,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              color: JewelryColors.champagneGold,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          if (onMore != null)
            GestureDetector(
              onTap: onMore,
              child: Text(
                '查看全部',
                style: TextStyle(
                  color: JewelryColors.emeraldGlow.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hot Products Horizontal Scroll
// ─────────────────────────────────────────────────────────────────────────────

class _HotProductsHorizontal extends StatelessWidget {
  const _HotProductsHorizontal({
    required this.products,
    required this.lang,
    required this.onTap,
  });
  final List<ProductModel> products;
  final AppLanguage lang;
  final void Function(ProductModel) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final product = products[index];
          return _HotProductCard(
            product: product,
            lang: lang,
            onTap: () => onTap(product),
          );
        },
      ),
    );
  }
}

class _HotProductCard extends StatelessWidget {
  const _HotProductCard({
    required this.product,
    required this.lang,
    required this.onTap,
  });
  final ProductModel product;
  final AppLanguage lang;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = product.localizedTitleFor(lang);
    final material = product.localizedMaterialFor(lang);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: JewelryColors.jadeSurface,
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              SizedBox(
                height: 140,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ProductImageView(
                      product: product,
                      fit: BoxFit.cover,
                    ),
                    // "Hot" badge
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: JewelryColors.emeraldLusterGradient,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '热门',
                          style: TextStyle(
                            color: JewelryColors.jadeBlack,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: JewelryColors.jadeMist,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '¥${product.price.toInt()}',
                          style: const TextStyle(
                            color: JewelryColors.champagneGold,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          material,
                          style: TextStyle(
                            color: JewelryColors.emeraldGlow.withOpacity(0.8),
                            fontSize: 10,
                          ),
                        ),
                      ],
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

// ─────────────────────────────────────────────────────────────────────────────
// New Arrivals List
// ─────────────────────────────────────────────────────────────────────────────

class _NewArrivalsList extends StatelessWidget {
  const _NewArrivalsList({
    required this.products,
    required this.lang,
    required this.onTap,
  });
  final List<ProductModel> products;
  final AppLanguage lang;
  final void Function(ProductModel) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: products.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final product = products[index];
          final title = product.localizedTitleFor(lang);
          return GestureDetector(
            onTap: () => onTap(product),
            child: Container(
              width: 230,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: JewelryColors.jadeSurface,
                border: Border.all(
                  color: JewelryColors.emeraldLuster.withOpacity(0.15),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: ProductImageView(
                        product: product,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color:
                                    JewelryColors.emeraldLuster.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'NEW',
                                style: TextStyle(
                                  color: JewelryColors.emeraldGlow,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: JewelryColors.jadeMist,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '¥${product.price.toInt()}',
                              style: const TextStyle(
                                color: JewelryColors.champagneGold,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Browse All Banner
// ─────────────────────────────────────────────────────────────────────────────

class _BrowseAllBanner extends ConsumerWidget {
  const _BrowseAllBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: JewelryColors.champagneGold.withOpacity(0.2),
          ),
          color: JewelryColors.jadeSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              color: JewelryColors.champagneGold.withOpacity(0.8),
              size: 20,
            ),
            const SizedBox(width: 10),
            Text(
              ref.tr('nav_products'),
              style: const TextStyle(
                color: JewelryColors.champagneGold,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.arrow_forward_ios,
              color: JewelryColors.champagneGold.withOpacity(0.5),
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
